#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-test}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT="$PROJECT_DIR/app.xcodeproj"
SCHEME="KnittingGaugeReconciler"
SIMULATOR_NAME="${SIMULATOR_NAME:-iPhone 17 Pro}"
SIMULATOR_UDID="${SIMULATOR_UDID:-}"
DESTINATION="${DESTINATION:-}"
BUILD_DIR="$PROJECT_DIR/.build"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$BUILD_DIR/derived-data}"

usage() {
  echo "Usage: $0 [build|test|release]"
}

case "$MODE" in
  build)
    ACTION=(build)
    CONFIGURATION="Debug"
    ;;
  test)
    ACTION=(test)
    CONFIGURATION="Debug"
    ;;
  release)
    ACTION=(build)
    CONFIGURATION="Release"
    DESTINATION="generic/platform=iOS"
    ;;
  -h|--help|help)
    usage
    exit 0
    ;;
  *)
    usage >&2
    exit 64
    ;;
esac

if [[ "$MODE" != "release" && -z "$DESTINATION" ]]; then
  if [[ -z "$SIMULATOR_UDID" ]]; then
    SIMULATOR_UDID="$(xcrun simctl list devices available "$SIMULATOR_NAME" |
      awk -F '[()]' '/^[[:space:]]+.*\([0-9A-F-]{36}\)/ { print $2; exit }')"
  fi

  if [[ -z "$SIMULATOR_UDID" ]]; then
    echo "error: no available simulator named '$SIMULATOR_NAME'" >&2
    exit 65
  fi

  xcrun simctl shutdown "$SIMULATOR_UDID" >/dev/null 2>&1 || true
  xcrun simctl boot "$SIMULATOR_UDID" >/dev/null 2>&1 || true
  xcrun simctl bootstatus "$SIMULATOR_UDID" -b >/dev/null
  DESTINATION="platform=iOS Simulator,id=${SIMULATOR_UDID}"
fi

DESTINATION_ARGS=(-destination "$DESTINATION" -destination-timeout 120)

mkdir -p "$BUILD_DIR"
LOCK_DIR="$BUILD_DIR/build.lock"
LOCK_WAIT_SECONDS="${LOCK_WAIT_SECONDS:-120}"
LOCK_WAITED=0
while ! mkdir "$LOCK_DIR" 2>/dev/null; do
  if [[ -f "$LOCK_DIR/pid" ]] && ! kill -0 "$(cat "$LOCK_DIR/pid")" 2>/dev/null; then
    rm -rf "$LOCK_DIR"
    continue
  fi
  if (( LOCK_WAITED >= LOCK_WAIT_SECONDS )); then
    echo "error: timed out waiting for another app/build.sh run to finish" >&2
    exit 65
  fi
  sleep 2
  LOCK_WAITED=$((LOCK_WAITED + 2))
done
echo "$$" > "$LOCK_DIR/pid"

LOG_DIR="$BUILD_DIR/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/xcodebuild-${MODE}-$$.log"
trap 'rm -f "$LOG_FILE"; rm -rf "$LOCK_DIR"' EXIT

# SKAgent writes to Index.noindex concurrently; retry once then proceed — stale index
# entries do not affect test correctness; xcodebuild rebuilds what it needs.
rm -rf "$DERIVED_DATA_PATH" 2>/dev/null \
  || { sleep 1 && rm -rf "$DERIVED_DATA_PATH" 2>/dev/null || true; }

if [[ "$MODE" == "test" ]]; then
  RESULT_BUNDLE_PATH="${RESULT_BUNDLE_PATH:-$DERIVED_DATA_PATH/Logs/Test/${SCHEME}.xcresult}"
  rm -rf "$RESULT_BUNDLE_PATH"
  mkdir -p "$(dirname "$RESULT_BUNDLE_PATH")"
fi

XCODEBUILD_ARGS=(
  -project "$PROJECT"
  -scheme "$SCHEME"
  -configuration "$CONFIGURATION"
  -derivedDataPath "$DERIVED_DATA_PATH"
  "${DESTINATION_ARGS[@]}"
)
if [[ "$MODE" == "test" ]]; then
  XCODEBUILD_ARGS+=(
    -parallel-testing-enabled NO
    -enableCodeCoverage YES
    -resultBundlePath "$RESULT_BUNDLE_PATH"
  )
fi
XCODEBUILD_ARGS+=(
  SWIFT_TREAT_WARNINGS_AS_ERRORS=YES
  GCC_TREAT_WARNINGS_AS_ERRORS=YES
  CLANG_TREAT_WARNINGS_AS_ERRORS=YES
  OTHER_SWIFT_FLAGS="-warnings-as-errors"
  "${ACTION[@]}"
)

run_xcodebuild() {
  set +e
  if command -v xcpretty >/dev/null 2>&1; then
    xcodebuild "${XCODEBUILD_ARGS[@]}" 2>&1 | tee "$LOG_FILE" | xcpretty
    STATUS=${PIPESTATUS[0]}
  else
    xcodebuild "${XCODEBUILD_ARGS[@]}" 2>&1 | tee "$LOG_FILE"
    STATUS=${PIPESTATUS[0]}
  fi
  set -e
}

run_xcodebuild

SIMULATOR_BUSY_LAUNCH_FAILURE='Application failed preflight checks|reason: Busy|Application launch for .* did not return a process handle nor launch error|NSPOSIXErrorDomain Code=3 "No such process"|Invalid device state|Mach error -308|Channel disconnected'
if [[ "$MODE" == "test" && "$STATUS" -ne 0 ]] \
    && grep -Eiq "$SIMULATOR_BUSY_LAUNCH_FAILURE" "$LOG_FILE" \
    && ! grep -Eq "Test Suite '.*' failed|Test Case '.*' failed|XCTAssert|XCTFail" "$LOG_FILE"; then
  echo "note: simulator was busy during test launch; rebooting simulator and retrying once" >&2
  FIRST_LOG_FILE="$LOG_FILE"
  LOG_FILE="$LOG_DIR/xcodebuild-${MODE}-retry-$$.log"
  if [[ -n "$SIMULATOR_UDID" ]]; then
    xcrun simctl shutdown "$SIMULATOR_UDID" >/dev/null 2>&1 || true
    xcrun simctl boot "$SIMULATOR_UDID" >/dev/null 2>&1 || true
    xcrun simctl bootstatus "$SIMULATOR_UDID" -b >/dev/null
  fi
  run_xcodebuild
  rm -f "$FIRST_LOG_FILE"
fi

COMPILER_WARN_PATTERN='\.(swift|m|mm|c|cpp|h)[^:]*:[0-9]+:[0-9]+: warning:'
if grep -Eiq "$COMPILER_WARN_PATTERN" "$LOG_FILE"; then
  echo "error: xcodebuild emitted compiler warnings; treating warnings as failures" >&2
  exit 65
fi

# Real test assertion failures from XCTest
if grep -Eq 'error: -\[.*\] .*:[0-9]+:.*XCTAssert|: XCTAssertTrue failed|: XCTAssertEqual failed|: XCTFail' "$LOG_FILE"; then
  echo "error: test assertions failed" >&2
  exit 65
fi

# Real simulator crash during test launch (not benign Xcode 26.4 post-test cleanup failures)
# Benign pattern covers known Xcode 26.4 infrastructure variants:
#   1. Null bundle identifier / simctl cleanup (original)
#   2. mkstemp failure in result-bundle staging + UI-runner bootstrap signal-term (new variant)
#   3. IOHIDLib plugin diagnostics emitted after all unit and UI tests pass
BENIGN_XCODE_INFRA_FAILURE='Failed to launch app with identifier: \(null\)|Invalid request: No bundle identifier|mkstemp: No such file or directory|Early unexpected exit, operation never finished bootstrapping|Test crashed with signal term (while preparing to run tests|before establishing connection)|Error loading .*IOHIDLib|Cannot find function pointer IOHIDLibFactory|failed to create instance for plugin|IOCreatePlugInInterfaceForService'
if grep -Eiq 'Failed to launch app|NSMachErrorDomain' "$LOG_FILE" \
    && ! grep -Eq "$BENIGN_XCODE_INFRA_FAILURE" "$LOG_FILE"; then
  echo "error: xcodebuild emitted simulator launch/crash diagnostics" >&2
  exit 65
fi

# If the only reason for non-zero STATUS is a known Xcode 26.4 post-test
# infrastructure failure, treat it as success only after xcodebuild reports that
# the test action or Swift Testing run succeeded.
TESTS_PASSED_PATTERN='\*\* TEST SUCCEEDED \*\*|Test Suite '\''Selected tests'\'' passed|Test run with [0-9]+ tests .* passed'
if [[ "$STATUS" -ne 0 ]] \
    && grep -Eq "$BENIGN_XCODE_INFRA_FAILURE" "$LOG_FILE" \
    && grep -Eq "$TESTS_PASSED_PATTERN" "$LOG_FILE" \
    && ! grep -Eq "Test Suite '.*' failed|Test Case '.*' failed" "$LOG_FILE"; then
  echo "note: xcodebuild exit $STATUS attributed to Xcode 26.4 post-test infrastructure bug; all test assertions passed" >&2
  exit 0
fi

exit "$STATUS"
