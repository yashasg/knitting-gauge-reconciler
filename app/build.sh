#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-test}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$PROJECT_DIR/.." && pwd)"
SIMULATOR_NAME="${SIMULATOR_NAME:-iPhone 17 Pro}"
SIMULATOR_UDID="${SIMULATOR_UDID:-}"
DESTINATION="${DESTINATION:-}"
BUILD_DIR="${BUILD_DIR:-$PROJECT_DIR/.build}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$BUILD_DIR/derived-data}"
COMPILER_INDEX_STORE_ENABLE="${COMPILER_INDEX_STORE_ENABLE:-YES}"

usage() {
  echo "Usage: $0 [build|test|release]"
  echo "  build   Build via Fastlane without distribution"
  echo "  test    Run the unified Fastlane ci lane (lint + build + test)"
  echo "  release Build a Release configuration via Fastlane without distribution"
}

fail() {
  echo "error: $*" >&2
  exit 65
}

destination_value() {
  local key="$1"
  printf '%s\n' "$DESTINATION" |
    tr ',' '\n' |
    sed -n "s/^[[:space:]]*${key}=//p" |
    head -n 1
}

resolve_simulator_udid_by_name() {
  local name="$1"
  xcrun simctl list devices available |
    awk -F '[()]' -v name="$name" '
      /^[[:space:]]+.*\([0-9A-F-]{36}\)/ {
        candidate = $1
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", candidate)
        if (candidate == name) {
          print $2
          exit
        }
      }
    '
}

resolve_simulator_name_by_udid() {
  local udid="$1"
  xcrun simctl list devices available |
    awk -F '[()]' -v udid="$udid" '$0 ~ udid { gsub(/^[[:space:]]+/, "", $1); gsub(/[[:space:]]+$/, "", $1); print $1; exit }'
}

acquire_build_lock() {
  mkdir -p "$BUILD_DIR"
  # ponytail: repository-wide lock; split by simulator only if build throughput becomes a bottleneck.
  LOCK_DIR="$(git -C "$REPO_ROOT" rev-parse --path-format=absolute --git-common-dir)/app-build.lock"
  LOCK_WAIT_SECONDS="${LOCK_WAIT_SECONDS:-900}"
  LOCK_WAITED=0

  while ! mkdir "$LOCK_DIR" 2>/dev/null; do
    if [[ -f "$LOCK_DIR/pid" ]] && ! kill -0 "$(cat "$LOCK_DIR/pid")" 2>/dev/null; then
      rm -rf "$LOCK_DIR"
      continue
    fi
    if (( LOCK_WAITED >= LOCK_WAIT_SECONDS )); then
      fail "timed out waiting for another app/build.sh run to finish"
    fi
    sleep 2
    LOCK_WAITED=$((LOCK_WAITED + 2))
  done

  echo "$$" > "$LOCK_DIR/pid"
  trap 'rm -rf "$LOCK_DIR"' EXIT
}

run_swiftlint() {
  echo "→ SwiftLint (HIG rules)..."
  swiftlint lint --strict --config "$REPO_ROOT/.swiftlint.yml" --reporter xcode
}

telemetry_preflight() {
  local pkg_resolved="$PROJECT_DIR/app.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
  if [[ -f "$pkg_resolved" ]]; then
    local telemetry_pattern='swift-metrics|firebase|sentry-cocoa|datadog|amplitude|mixpanel|segment|braze|newrelic|instana|bugsnag'
    if grep -Eiq "$telemetry_pattern" "$pkg_resolved"; then
      fail "Package.resolved references a third-party telemetry SDK; only MetricKit (system framework) is permitted"
    fi
  fi
}

resolve_simulator_context() {
  local destination_udid=""
  local destination_name=""

  FASTLANE_TEST_DEVICE=""

  if [[ -n "$DESTINATION" ]]; then
    [[ "$DESTINATION" == *"platform=iOS Simulator"* ]] || \
      fail "DESTINATION must target an iOS Simulator for $MODE: $DESTINATION"

    destination_udid="$(destination_value id)"
    destination_name="$(destination_value name)"

    if [[ -n "$destination_udid" ]]; then
      SIMULATOR_UDID="$destination_udid"
      SIMULATOR_NAME="$(resolve_simulator_name_by_udid "$SIMULATOR_UDID")"
      [[ -n "$SIMULATOR_NAME" ]] || fail "no available simulator with UDID '$SIMULATOR_UDID'"
    elif [[ -n "$destination_name" ]]; then
      SIMULATOR_NAME="$destination_name"
      SIMULATOR_UDID="$(resolve_simulator_udid_by_name "$destination_name")"
      [[ -n "$SIMULATOR_UDID" ]] || fail "no available simulator named '$destination_name'"
    elif [[ "$MODE" == "test" ]]; then
      fail "DESTINATION must include an available simulator id or name for test"
    fi
  fi

  if [[ -z "$DESTINATION" ]]; then
    if [[ -z "$SIMULATOR_UDID" ]]; then
      SIMULATOR_UDID="$(resolve_simulator_udid_by_name "$SIMULATOR_NAME")"
    else
      SIMULATOR_NAME="$(resolve_simulator_name_by_udid "$SIMULATOR_UDID")"
    fi
    [[ -n "$SIMULATOR_UDID" && -n "$SIMULATOR_NAME" ]] || \
      fail "no available simulator matching SIMULATOR_NAME='$SIMULATOR_NAME' SIMULATOR_UDID='$SIMULATOR_UDID'"
    DESTINATION="platform=iOS Simulator,id=${SIMULATOR_UDID}"
  fi

  FASTLANE_TEST_DEVICE="$SIMULATOR_NAME"
}

simulator_test_preflight() {
  local model_identifier

  xcrun simctl bootstatus "$SIMULATOR_UDID" -b || \
    fail "simulator '$SIMULATOR_NAME' ($SIMULATOR_UDID) could not boot"
  model_identifier="$(xcrun simctl getenv "$SIMULATOR_UDID" SIMULATOR_MODEL_IDENTIFIER)" || \
    fail "could not inspect simulator '$SIMULATOR_NAME' ($SIMULATOR_UDID)"
  [[ "$model_identifier" == iPhone* ]] || \
    fail "simulator '$SIMULATOR_NAME' ($SIMULATOR_UDID) is not an iPhone"
}

foreign_app_preflight() {
  [[ -n "$SIMULATOR_UDID" ]] || return 0

  local listapps_raw foreign_bundle_ids
  listapps_raw="$(xcrun simctl listapps "$SIMULATOR_UDID" 2>/dev/null || true)"
  [[ -n "$listapps_raw" ]] || return 0

  foreign_bundle_ids="$(
    printf '%s' "$listapps_raw" \
      | /usr/bin/awk -F '"' '/CFBundleIdentifier =/ { print $2 }' \
      | grep -E '^com\.yashasg(ujjar)?\.' \
      | grep -v '^com\.yashasg\.knitting-guage-reconciler$' \
      || true
  )"
  [[ -n "$foreign_bundle_ids" ]] || return 0

  while IFS= read -r bundle_id; do
    [[ -n "$bundle_id" ]] || continue
    echo "→ foreign-app preflight: uninstall $bundle_id" >&2
    xcrun simctl uninstall "$SIMULATOR_UDID" "$bundle_id" >/dev/null 2>&1 || true
  done <<< "$foreign_bundle_ids"
}

run_fastlane() {
  command -v fastlane >/dev/null 2>&1 || fail "fastlane not found; install via: brew install fastlane"
  local lane="$1"
  shift
  (
    cd "$PROJECT_DIR"
    FASTLANE_XCODEBUILD_SETTINGS_TIMEOUT="${FASTLANE_XCODEBUILD_SETTINGS_TIMEOUT-120}" \
      SKIP_SLOW_FASTLANE_WARNING=1 FASTLANE_SKIP_UPDATE_CHECK=1 fastlane "$lane" "$@"
  )
}

verify_fastlane_output() {
  local output_path="$1"
  local prohibited_pattern='IOHID|IOSurface|IOCreatePlugInInterfaceForService|(^|[^[:alnum:]_])plugin([^[:alnum:]_]|$).*(cannot|error|failed|failure)([^[:alnum:]_]|$)|(^|[^[:alnum:]_])(cannot|error|failed|failure)([^[:alnum:]_]|$).*plugin([^[:alnum:]_]|$)|fopen.*(cannot|error|failed|failure)([^[:alnum:]_]|$)|\[!\]|warning:|(^|[^[:alnum:]_])advisory([^[:alnum:]_]|$)|Found [1-9][0-9]* violations?|falling[[:space:]]+back|(^|[^[:alnum:]_])fallback([^[:alnum:]_]|$).*(failed|failure|error)([^[:alnum:]_]|$)|(^|[^[:alnum:]_])(failed|failure|error)([^[:alnum:]_]|$).*fallback([^[:alnum:]_]|$)|bootstrap.*(failed|failure|error|killed)([^[:alnum:]_]|$)|(^|[^[:alnum:]_])(failed|failure|error|killed)([^[:alnum:]_]|$).*bootstrap|((killed|terminated).*(signal|process))|signal[[:space:]]+(kill|term|[0-9]+)|SIG(KILL|TERM|ABRT|SEGV)|crashed|crash[[:space:]]+report[[:space:]]+found|unexpected(ly)?[[:space:]]+exit(ed)?|exit(ed)?[[:space:]]+unexpectedly'
  local grep_status

  if LC_ALL=C grep -aEinH "$prohibited_pattern" "$output_path" >&2; then
    grep_status=0
  else
    grep_status=$?
  fi

  case "$grep_status" in
    0) fail "prohibited warning, advisory, fallback, bootstrap, signal, or crash output detected" ;;
    1) ;;
    *) fail "could not scan Fastlane output for prohibited diagnostics" ;;
  esac
}

case "$MODE" in
  build)
    LANE="build"
    CONFIGURATION="${CONFIGURATION:-Debug}"
    SDK="${SDK:-iphonesimulator}"
    ;;
  test)
    LANE="ci"
    CONFIGURATION="${CONFIGURATION:-Debug}"
    SDK="${SDK:-iphonesimulator}"
    ;;
  release)
    LANE="build"
    CONFIGURATION="${CONFIGURATION:-Release}"
    SDK="${SDK:-iphoneos}"
    DESTINATION="${DESTINATION:-generic/platform=iOS}"
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

command -v swiftlint >/dev/null 2>&1 || fail "swiftlint not found; install via: brew install swiftlint"
acquire_build_lock
telemetry_preflight
if [[ "$MODE" != "test" ]]; then
  run_swiftlint
fi

if [[ "$MODE" != "release" ]]; then
  resolve_simulator_context
fi

if [[ "$MODE" == "test" ]]; then
  simulator_test_preflight
  foreign_app_preflight
fi

xcargs=(
  "-quiet"
  "COMPILER_INDEX_STORE_ENABLE=${COMPILER_INDEX_STORE_ENABLE}"
  "SWIFT_TREAT_WARNINGS_AS_ERRORS=YES"
  "GCC_TREAT_WARNINGS_AS_ERRORS=YES"
  "CLANG_TREAT_WARNINGS_AS_ERRORS=YES"
  "OTHER_SWIFT_FLAGS=-warnings-as-errors"
)

if [[ "$MODE" != "release" ]]; then
  xcargs=("CODE_SIGNING_ALLOWED=NO" "${xcargs[@]}")
fi

if [[ "$MODE" == "test" ]]; then
  xcargs+=(
    "-parallel-testing-enabled NO"
  )
fi

fastlane_args=(
  "configuration:${CONFIGURATION}"
  "derived_data_path:${DERIVED_DATA_PATH}"
  "xcargs:${xcargs[*]}"
)

if [[ "$LANE" == "build" || "$LANE" == "ci" ]]; then
  fastlane_args+=(
    "sdk:${SDK}"
    "destination:${DESTINATION}"
  )
fi

if [[ "$MODE" == "test" ]]; then
  fastlane_args+=(
    "device:${FASTLANE_TEST_DEVICE}"
    "output_directory:${BUILD_DIR}"
  )
fi

FASTLANE_OUTPUT="$BUILD_DIR/fastlane-output.log"
set +e
run_fastlane "$LANE" "${fastlane_args[@]}" 2>&1 | tee "$FASTLANE_OUTPUT"
FASTLANE_PIPE_STATUSES=("${PIPESTATUS[@]}")
set -e
FASTLANE_STATUS=${FASTLANE_PIPE_STATUSES[0]}
TEE_STATUS=${FASTLANE_PIPE_STATUSES[1]}
(( FASTLANE_STATUS == 0 )) || exit "$FASTLANE_STATUS"
(( TEE_STATUS == 0 )) || exit "$TEE_STATUS"
verify_fastlane_output "$FASTLANE_OUTPUT"
