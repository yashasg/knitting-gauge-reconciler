#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-test}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT="$PROJECT_DIR/app.xcodeproj"
SCHEME="KnittingGaugeReconciler"
SIMULATOR_NAME="${SIMULATOR_NAME:-iPhone 17 Pro}"
SIMULATOR_UDID="${SIMULATOR_UDID:-}"
DESTINATION="${DESTINATION:-}"
BUILD_DIR="${BUILD_DIR:-$PROJECT_DIR/.build}"
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

# Foreign-app preflight (#42): when other personal Xcode projects (e.g.
# com.yashasgujjar.uvburntimer) install their app bundles on the shared
# 'iPhone 17 Pro' simulator, they steal focus during UI tests and produce
# `Wait for com.yashasgujjar.<app> to idle` timeouts. Uninstall any
# com.yashasg* / com.yashasgujjar.* bundle that is not part of this
# project before we run our own tests. Best-effort; never fatal — we
# already hold the build.sh lock here so siblings of *this* project are
# guaranteed not to be racing us on the simulator.
if [[ "$MODE" != "release" && -n "$SIMULATOR_UDID" ]]; then
  _LISTAPPS_RAW="$(xcrun simctl listapps "$SIMULATOR_UDID" 2>/dev/null || true)"
  if [[ -n "$_LISTAPPS_RAW" ]]; then
    # `simctl listapps` returns a plist; bundle IDs appear as
    #     CFBundleIdentifier = "com.example.app";
    # Split on `"` and take the value field.
    printf '%s' "$_LISTAPPS_RAW" \
      | /usr/bin/awk -F '"' '/CFBundleIdentifier =/ { print $2 }' \
      | grep -E '^com\.yashasg(ujjar)?\.' \
      | grep -v '^com\.yashasg\.KnittingGaugeReconciler' \
      | while IFS= read -r _bid; do
          [[ -n "$_bid" ]] || continue
          echo "→ foreign-app preflight: uninstall $_bid" >&2
          xcrun simctl uninstall "$SIMULATOR_UDID" "$_bid" >/dev/null 2>&1 || true
        done
  fi
  unset _LISTAPPS_RAW
fi

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
  # UI tests under the single-simulator serial-UI constraint
  # (2026-05-20T06-25-04Z-serial-ui-tests.md) occasionally suffer
  # runner-level signal-term crashes during XCUIApplication cold
  # launches — xcodebuild then jumps to the *next* test instead of
  # re-running the crashed one, leaving a real Failed entry in the
  # xcresult bundle even though the test logic is sound. Xcode 13+'s
  # -retry-tests-on-failure / -test-iterations N reruns only failed
  # tests and accepts each as passing if any iteration passes — it
  # does not retry passing tests and does not mask deterministic
  # failures (a broken test still fails every iteration). Final
  # verify_xcresult_summary guard remains the source of truth.
  XCODEBUILD_ARGS+=(
    -parallel-testing-enabled NO
    -enableCodeCoverage YES
    -resultBundlePath "$RESULT_BUNDLE_PATH"
    -retry-tests-on-failure
    -test-iterations 2
  )
fi
XCODEBUILD_ARGS+=(
  SWIFT_TREAT_WARNINGS_AS_ERRORS=YES
  GCC_TREAT_WARNINGS_AS_ERRORS=YES
  CLANG_TREAT_WARNINGS_AS_ERRORS=YES
  OTHER_SWIFT_FLAGS="-warnings-as-errors"
  "${ACTION[@]}"
)

# ── MetricKit V3: no-third-party-telemetry gate (runs on every mode) ─────────
# Package.resolved must not reference known telemetry SDKs.
# MetricKit is a system framework — zero SPM entries expected.
_PKG_RESOLVED="$PROJECT_DIR/app.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
if [[ -f "$_PKG_RESOLVED" ]]; then
  _TELEMETRY_PATTERN='swift-metrics|firebase|sentry-cocoa|datadog|amplitude|mixpanel|segment|braze|newrelic|instana|bugsnag'
  if grep -Eiq "$_TELEMETRY_PATTERN" "$_PKG_RESOLVED"; then
    echo "error: Package.resolved references a third-party telemetry SDK; only MetricKit (system framework) is permitted" >&2
    exit 65
  fi
fi

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

# HIG compliance lint
if command -v swiftlint &>/dev/null; then
  echo "→ SwiftLint (HIG rules)..."
  swiftlint lint --config "$(dirname "$PROJECT_DIR")/.swiftlint.yml" --reporter xcode
else
  echo "⚠ SwiftLint not installed — skipping HIG lint (brew install swiftlint)"
fi

run_xcodebuild

SIMULATOR_BUSY_LAUNCH_FAILURE='Application failed preflight checks|reason: Busy|Application launch for .* did not return a process handle nor launch error|NSPOSIXErrorDomain Code=3 "No such process"|Invalid device state|Mach error -308|Channel disconnected'
if [[ "$MODE" == "test" && "$STATUS" -ne 0 ]] \
    && grep -Eiq "$SIMULATOR_BUSY_LAUNCH_FAILURE" "$LOG_FILE" \
    && ! grep -Eq "Test Suite '.*' failed|Test Case '.*' failed|XCTAssert|XCTFail" "$LOG_FILE"; then
  echo "note: simulator was busy during test launch; rebooting simulator and retrying once" >&2
  FIRST_LOG_FILE="$LOG_FILE"
  LOG_FILE="$LOG_DIR/xcodebuild-${MODE}-retry-$$.log"
  rm -rf "$RESULT_BUNDLE_PATH"
  mkdir -p "$(dirname "$RESULT_BUNDLE_PATH")"
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
#   4. Runner xctrunner install/launch failure where FBSApplicationLibrary
#      transiently returns nil for the runner bundle id during the
#      cold launch — recoverable by rerunning the UI target on a
#      fresh simulator.
BENIGN_XCODE_INFRA_FAILURE='Failed to launch app with identifier: \(null\)|Invalid request: No bundle identifier|mkstemp: No such file or directory|Early unexpected exit, operation never finished bootstrapping|Test crashed with signal term (while preparing to run tests|before establishing connection)|Error loading .*IOHIDLib|Cannot find function pointer IOHIDLibFactory|failed to create instance for plugin|IOCreatePlugInInterfaceForService|Failed to launch app with identifier: com\.yashasg\.KnittingGaugeReconcilerUITests\.xctrunner|Simulator device failed to launch com\.yashasg\.KnittingGaugeReconcilerUITests\.xctrunner|Failed to install or launch the test runner|Application info provider \(FBSApplicationLibrary\) returned nil'
if grep -Eiq 'Failed to launch app|NSMachErrorDomain' "$LOG_FILE" \
    && ! grep -Eq "$BENIGN_XCODE_INFRA_FAILURE" "$LOG_FILE"; then
  echo "error: xcodebuild emitted simulator launch/crash diagnostics" >&2
  exit 65
fi

# Defense in depth: parse the xcresult bundle to verify that every test
# assertion actually passed. Heuristic regex matches above can legitimately
# fire on real failures (e.g. a test crashes mid-execution with signal term,
# or the unit test bundle bootstrap-crashes so no tests run at all). The
# xcresult bundle is xcodebuild's authoritative record — if it disagrees
# with the heuristics, the heuristics lose.
verify_xcresult_summary() {
  local bundle="$1"
  if [[ ! -d "$bundle" ]]; then
    echo "error: expected xcresult bundle at $bundle but it does not exist" >&2
    return 65
  fi
  local summary_json
  if ! summary_json=$(xcrun xcresulttool get test-results summary --path "$bundle" 2>/dev/null); then
    echo "error: could not read test-results summary from $bundle" >&2
    return 65
  fi
  local parsed
  if ! parsed=$(printf '%s' "$summary_json" | /usr/bin/python3 -c '
import json, sys
d = json.load(sys.stdin)
print(d.get("result", ""))
print(d.get("passedTests", -1))
print(d.get("failedTests", -1))
print(d.get("skippedTests", -1))
' 2>/dev/null); then
    echo "error: could not parse xcresult summary JSON at $bundle" >&2
    return 65
  fi
  local result passed failed skipped
  { read -r result; read -r passed; read -r failed; read -r skipped; } <<< "$parsed"
  if [[ "$result" != "Passed" ]] \
      || [[ "$failed" != "0" ]] \
      || [[ "$passed" == "-1" ]] \
      || [[ "$passed" == "0" ]]; then
    echo "error: xcresult summary disagrees with success heuristic — bundle reports result=$result passed=$passed failed=$failed skipped=$skipped" >&2
    return 65
  fi
  return 0
}

# Recover from three related classes of UI-runner flake under the
# single-simulator serial-UI constraint (2026-05-20T06-25-04Z-serial-ui-tests.md):
#
#   (a) Per-test signal-term: XCUIApplication launches occasionally hang
#       past xcodebuild's per-test watchdog, the runner is killed with
#       SIGTERM, xcodebuild *advances* to the next test rather than
#       retrying the crashed one, and the failure survives in the
#       xcresult bundle as a single failure entry whose failureText is
#       exactly "Test crashed with signal term." and whose
#       testIdentifierString is a "Target/test()" spec.
#       -retry-tests-on-failure does not catch this case because
#       xcodebuild never observes a structured failure callback — only a
#       post-mortem signal-term entry.
#
#   (b) Runner-bootstrap signal-term: the UI runner process itself is
#       killed with SIGTERM *before* it finishes bootstrapping (i.e.
#       before any test starts). xcodebuild reports "Early unexpected
#       exit, operation never finished bootstrapping - no restart will
#       be attempted." with underlying "Test crashed with signal term
#       while preparing to run tests.", and emits a single failure entry
#       whose testIdentifierString is "<Target>-Runner (<pid>) encountered
#       an error" (not a Target/test() spec). The whole UI suite is
#       wiped from the bundle and no individual tests can be re-targeted.
#
#   (c) Runner install/launch failure: FBSApplicationLibrary transiently
#       returns nil for the xctrunner bundle id during a cold launch and
#       SpringBoard refuses to open it ("Simulator device failed to
#       launch com.yashasg.KnittingGaugeReconcilerUITests.xctrunner" /
#       "Failed to install or launch the test runner"). Like (b) this
#       wipes the UI suite from the bundle and the failure entry has a
#       "<Target>-Runner (<pid>) encountered an error" identifier. May
#       appear alongside (a) when an earlier per-test signal-term left
#       the simulator in a rough state that prevents the next runner
#       cold launch.
#
#   (d) Runner connection-loss bootstrap: the UI runner process is
#       launched but xcodebuild's IDE side loses its IPC connection
#       before the runner finishes bootstrapping. xcodebuild reports
#       "Early unexpected exit, operation never finished bootstrapping
#       - no restart will be attempted." with underlying "Lost pending
#       connection to the test runner before launch." Same overall
#       shape as (b)/(c) — single "<Target>-Runner (<pid>) encountered
#       an error" entry, whole UI suite wiped — but the SIGTERM
#       wording is absent so the (b) matcher doesn't catch it.
#       Observed when the simulator was left in a degraded state by an
#       earlier per-test launch hang; a simple shutdown/boot pair
#       sometimes is not enough to clear it, so the whole-target rerun
#       escalates to `simctl erase` for a clean device state. See
#       GitLab issue #17.
#
# Behavior: only enter recovery if every failure is one of the four
# recognized variants. For (a) rerun the specific test method; for (b),
# (c), and (d) rerun the whole UI test target. The simulator is always
# erased (then booted) before the rerun — `simctl shutdown` + `boot`
# alone has been observed to leave the device in "Invalid device state"
# (Mach error -308) on the rerun, even when the original failure was
# per-test variant (a). The ~20s extra cost is acceptable on the rare
# recovery path. The rerun bundle replaces the canonical bundle (the
# original is preserved alongside as .signal-term-original.xcresult
# for triage). If the rerun bundle itself reports only recognized
# bootstrap-class variant (b)/(c)/(d) failures (i.e. the simulator was
# wedged badly enough that even erase+boot didn't clear it on the
# first rerun), the function escalates: shutdown all simulators (not
# just the target one), erase, boot, and try the same rerun once more
# (max two attempts total). Any real assertion failure or unrecognized
# failure shape refuses the recovery, preserving the original failure
# for the gate to fail on. Persistent flakes after both rerun attempts
# still fail the gate.
rerun_signal_term_failures() {
  local bundle="$1"
  if [[ ! -d "$bundle" ]]; then
    return 1
  fi
  local summary_json
  if ! summary_json=$(xcrun xcresulttool get test-results summary --path "$bundle" 2>/dev/null); then
    return 1
  fi
  local rerun_specs extract_status
  set +e
  rerun_specs=$(printf '%s' "$summary_json" | /usr/bin/python3 -c '
import json, sys
PER_TEST = "Test crashed with signal term."
RUNNER_BOOTSTRAP = "Test crashed with signal term while preparing to run tests"
RUNNER_INSTALL_FAILED = "Failed to install or launch the test runner"
RUNNER_LAUNCH_FAILED = "Simulator device failed to launch"
FBS_NIL = "Application info provider (FBSApplicationLibrary) returned nil"
# GitLab issue #17: variant (d) — runner launches but loses its IPC
# connection to xcodebuild before finishing bootstrap. Same fix shape
# as (b)/(c) (whole-target rerun) but reported without the SIGTERM
# wording, so it needs its own matcher.
RUNNER_LOST_CONNECTION = "Lost pending connection to the test runner before launch"
# Either of these openers means the runner never reported back; pair
# with one of the bootstrap qualifiers above to whitelist as variant
# (b) / (c) / (d).
RUNNER_BOOTSTRAP_OPENERS = (
    "Early unexpected exit, operation never finished bootstrapping",
    "Lost pending connection to the test runner before launch",
)
d = json.load(sys.stdin)
failures = d.get("testFailures") or []
if not failures:
    sys.exit(3)
target_level = set()
method_level = []
for f in failures:
    text = (f.get("failureText") or "").strip()
    tid = (f.get("testIdentifierString") or "").strip()
    target = (f.get("targetName") or "").strip()
    if not target:
        sys.exit(2)
    if text == PER_TEST:
        if not tid or "/" not in tid:
            sys.exit(2)
        method = tid.replace("()", "")
        method_level.append((target, f"{target}/{method}"))
    elif (RUNNER_BOOTSTRAP in text
          or RUNNER_INSTALL_FAILED in text
          or RUNNER_LAUNCH_FAILED in text
          or FBS_NIL in text
          or RUNNER_LOST_CONNECTION in text
          or any(opener in text for opener in RUNNER_BOOTSTRAP_OPENERS)):
        # Whole-target rerun: no method spec, just the target name. The
        # runner-level failure wipes out every test in the target (or
        # the runner never finishes bootstrapping) so we cannot narrow
        # further. Rerunning the whole target on a freshly erased
        # simulator (see escalation below) gives the transient
        # install/launch/connection flake a clean second attempt.
        target_level.add(target)
    else:
        sys.exit(2)
specs = []
seen = set()
for t in sorted(target_level):
    if t not in seen:
        seen.add(t)
        specs.append(t)
for (target, spec) in method_level:
    # If the whole target is already queued for rerun, the narrower
    # method spec is redundant; xcodebuild would still run the whole
    # target. Drop it to keep the rerun args tidy and the rerun_count
    # guard accurate.
    if target in target_level:
        continue
    if spec not in seen:
        seen.add(spec)
        specs.append(spec)
for s in specs:
    print(s)
' 2>/dev/null)
  extract_status=$?
  set -e
  if [[ "$extract_status" -ne 0 ]]; then
    return 1
  fi
  if [[ -z "$rerun_specs" ]]; then
    return 1
  fi
  local rerun_count
  rerun_count=$(printf '%s\n' "$rerun_specs" | grep -c '.')
  if [[ "$rerun_count" -gt 5 ]]; then
    echo "error: refusing to rerun $rerun_count signal-term failures; too many to be infra flake" >&2
    return 1
  fi
  # Recovery is last-resort: simctl shutdown + boot has been observed to
  # leave the simulator in "Invalid device state" (Mach error -308) on
  # the rerun, even when the original failure was per-test (variant a).
  # Always erase before the rerun to guarantee clean device state; the
  # ~20s extra cost is acceptable on the rare recovery path. This also
  # subsumes the variant-aware escalation needed for the (b)/(c)/(d)
  # whole-target reruns. See GitLab issue #17.
  echo "note: $rerun_count signal-term flake spec(s) detected; erasing and rebooting simulator before rerun: $(printf '%s' "$rerun_specs" | tr '\n' ' ')" >&2
  reset_sim_for_rerun() {
    if [[ -z "$SIMULATOR_UDID" ]]; then
      return 0
    fi
    if (( ${1:-0} )); then
      # Heavy reset: shut down ALL simulators (in case a stale
      # background sim is competing for CoreSimulator IPC), then erase
      # and boot only the target one. Used when the first rerun also
      # hit a recognized bootstrap-class infrastructure flake.
      xcrun simctl shutdown all >/dev/null 2>&1 || true
      sleep 2
    else
      xcrun simctl shutdown "$SIMULATOR_UDID" >/dev/null 2>&1 || true
    fi
    xcrun simctl erase "$SIMULATOR_UDID" >/dev/null 2>&1 || true
    xcrun simctl boot "$SIMULATOR_UDID" >/dev/null 2>&1 || true
    xcrun simctl bootstatus "$SIMULATOR_UDID" -b >/dev/null
  }
  reset_sim_for_rerun 0
  local rerun_bundle="${bundle%.xcresult}.flake-rerun.xcresult"
  rm -rf "$rerun_bundle"
  mkdir -p "$(dirname "$rerun_bundle")"
  local rerun_args=(
    -project "$PROJECT"
    -scheme "$SCHEME"
    -configuration "$CONFIGURATION"
    -derivedDataPath "$DERIVED_DATA_PATH"
    "${DESTINATION_ARGS[@]}"
    -parallel-testing-enabled NO
    -resultBundlePath "$rerun_bundle"
  )
  while IFS= read -r spec; do
    [[ -n "$spec" ]] && rerun_args+=(-only-testing:"$spec")
  done <<< "$rerun_specs"
  rerun_args+=(
    SWIFT_TREAT_WARNINGS_AS_ERRORS=YES
    GCC_TREAT_WARNINGS_AS_ERRORS=YES
    CLANG_TREAT_WARNINGS_AS_ERRORS=YES
    OTHER_SWIFT_FLAGS="-warnings-as-errors"
    test
  )
  local rerun_log="$LOG_DIR/xcodebuild-${MODE}-flake-rerun-$$.log"
  do_rerun() {
    set +e
    if command -v xcpretty >/dev/null 2>&1; then
      xcodebuild "${rerun_args[@]}" 2>&1 | tee "$rerun_log" | xcpretty
    else
      xcodebuild "${rerun_args[@]}" 2>&1 | tee "$rerun_log"
    fi
    set -e
  }
  do_rerun
  # Second-pass rerun: if the first rerun also hit a recognized
  # bootstrap-class variant (b/c/d) — i.e. the simulator was wedged
  # badly enough that erase+boot didn't clear it on the first pass —
  # do a heavier reset (shutdown all sims + erase + boot) and try the
  # same rerun once more. Only one extra attempt. The fixture is
  # narrow: every failure must be either a recognized whole-target
  # bootstrap variant or a bare per-test SIGTERM (the same string we
  # already classify as a flake on the first pass at line 332). We
  # explicitly do *not* escalate on unknown failures or real assertion
  # failures.
  bootstrap_only_rerun_failures() {
    local b="$1"
    if [[ ! -d "$b" ]]; then return 1; fi
    local sj
    if ! sj=$(xcrun xcresulttool get test-results summary --path "$b" 2>/dev/null); then
      return 1
    fi
    set +e
    printf '%s' "$sj" | /usr/bin/python3 -c '
import json, sys
PER_TEST = "Test crashed with signal term."
RUNNER_BOOTSTRAP = "Test crashed with signal term while preparing to run tests"
RUNNER_INSTALL_FAILED = "Failed to install or launch the test runner"
RUNNER_LAUNCH_FAILED = "Simulator device failed to launch"
FBS_NIL = "Application info provider (FBSApplicationLibrary) returned nil"
RUNNER_LOST_CONNECTION = "Lost pending connection to the test runner before launch"
INVALID_DEVICE_STATE = "Invalid device state"
MACH_SERVER_DIED = "Mach error -308"
BOOTSTRAP_OPENERS = (
    "Early unexpected exit, operation never finished bootstrapping",
    "Lost pending connection to the test runner before launch",
)
d = json.load(sys.stdin)
failures = d.get("testFailures") or []
if not failures:
    sys.exit(2)
for f in failures:
    text = (f.get("failureText") or "").strip()
    # PER_TEST is a substring of RUNNER_BOOTSTRAP, so gate it on exact
    # equality to mirror the first-pass matcher (build.sh:361) and
    # avoid accidentally accepting unrelated text that happens to
    # contain the bare SIGTERM phrase.
    if not (text == PER_TEST
            or RUNNER_BOOTSTRAP in text
            or RUNNER_INSTALL_FAILED in text
            or RUNNER_LAUNCH_FAILED in text
            or FBS_NIL in text
            or RUNNER_LOST_CONNECTION in text
            or INVALID_DEVICE_STATE in text
            or MACH_SERVER_DIED in text
            or any(o in text for o in BOOTSTRAP_OPENERS)):
        sys.exit(2)
sys.exit(0)
' >/dev/null 2>&1
    local rc=$?
    set -e
    return $rc
  }
  if ! verify_xcresult_summary "$rerun_bundle" \
      && bootstrap_only_rerun_failures "$rerun_bundle"; then
    echo "note: first rerun also hit a recognized bootstrap-class flake; doing heavy sim reset and rerunning once more" >&2
    rm -rf "$rerun_bundle"
    reset_sim_for_rerun 1
    do_rerun
  fi
  if ! verify_xcresult_summary "$rerun_bundle"; then
    echo "error: signal-term flake rerun did not pass cleanly; original failure stands" >&2
    rm -f "$rerun_log"
    return 1
  fi
  # Compiler warnings are gated globally already, but if the rerun somehow
  # introduced a new warning we still want the gate to fail.
  if grep -Eiq "$COMPILER_WARN_PATTERN" "$rerun_log"; then
    echo "error: signal-term flake rerun emitted compiler warnings" >&2
    rm -f "$rerun_log"
    return 1
  fi
  # Promote the rerun bundle into the canonical location for downstream
  # consumers (CI artifacts, coverage tooling) while preserving the
  # original failed bundle alongside for triage.
  local saved="${bundle%.xcresult}.signal-term-original.xcresult"
  rm -rf "$saved"
  mv "$bundle" "$saved"
  mv "$rerun_bundle" "$bundle"
  rm -f "$rerun_log"
  return 0
}

# If the only reason for non-zero STATUS is a known Xcode 26.4 post-test
# infrastructure failure, treat it as success only after xcodebuild reports that
# the test action or Swift Testing run succeeded AND the xcresult bundle agrees.
TESTS_PASSED_PATTERN='\*\* TEST SUCCEEDED \*\*|Test Suite '\''Selected tests'\'' passed|Test run with [0-9]+ tests .* passed'
if [[ "$STATUS" -ne 0 ]] \
    && grep -Eq "$BENIGN_XCODE_INFRA_FAILURE" "$LOG_FILE" \
    && grep -Eq "$TESTS_PASSED_PATTERN" "$LOG_FILE" \
    && ! grep -Eq "Test Suite '.*' failed|Test Case '.*' failed" "$LOG_FILE"; then
  if [[ "$MODE" == "test" ]]; then
    if ! verify_xcresult_summary "$RESULT_BUNDLE_PATH"; then
      if rerun_signal_term_failures "$RESULT_BUNDLE_PATH" \
          && verify_xcresult_summary "$RESULT_BUNDLE_PATH"; then
        echo "note: xcodebuild exit $STATUS attributed to Xcode 26.4 post-test infrastructure bug; signal-term flake(s) recovered on rerun" >&2
        exit 0
      fi
      echo "error: refusing to treat xcodebuild exit $STATUS as benign because the xcresult bundle reports real test failures" >&2
      exit 65
    fi
  fi
  echo "note: xcodebuild exit $STATUS attributed to Xcode 26.4 post-test infrastructure bug; all test assertions passed" >&2
  exit 0
fi

# Final guard for the test action: the xcresult bundle is authoritative. If
# the main run left any failures in the bundle — whether xcodebuild's own
# exit code agreed or not — first attempt to recover signal-term runner
# flakes by rerunning only those tests; otherwise fail.
if [[ "$MODE" == "test" ]]; then
  if ! verify_xcresult_summary "$RESULT_BUNDLE_PATH"; then
    if rerun_signal_term_failures "$RESULT_BUNDLE_PATH" \
        && verify_xcresult_summary "$RESULT_BUNDLE_PATH"; then
      echo "note: signal-term flake(s) recovered on rerun; all test assertions now pass" >&2
      exit 0
    fi
    if [[ "$STATUS" -eq 0 ]]; then
      echo "error: xcodebuild reported success but the xcresult bundle records test failures" >&2
    fi
    exit 65
  fi
fi

# ── MetricKit V3: release binary system-dylibs-only gate ─────────────────────
# Verify no non-system dylib is linked (Curie's linker check).
# Runs after a successful release build; passes silently for test/build modes.
if [[ "$MODE" == "release" && "$STATUS" -eq 0 ]]; then
  _RELEASE_BIN="$DERIVED_DATA_PATH/Build/Products/Release-iphoneos/${SCHEME}.app/${SCHEME}"
  if [[ -f "$_RELEASE_BIN" ]]; then
    _NON_SYS="$(otool -L "$_RELEASE_BIN" 2>/dev/null \
      | awk 'NR>1 {print $1}' \
      | grep -Ev '^(/usr/lib/|/System/Library/|@rpath/|@executable_path/|@loader_path/)' || true)"
    if [[ -n "$_NON_SYS" ]]; then
      echo "error: release binary links non-system dylibs (MetricKit V3 telemetry linker check):" >&2
      printf '%s\n' "$_NON_SYS" >&2
      exit 65
    fi
    echo "note: release binary passes telemetry linker check (system dylibs only)" >&2
  fi
fi

exit "$STATUS"
