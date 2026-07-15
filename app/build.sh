#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-test}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$PROJECT_DIR/.." && pwd)"
PROJECT="$PROJECT_DIR/app.xcodeproj"
SCHEME="KnittingGaugeReconciler"
SIMULATOR_NAME_OVERRIDE="${SIMULATOR_NAME:-}"
SIMULATOR_NAME="${SIMULATOR_NAME:-iPhone 17 Pro}"
SIMULATOR_UDID="${SIMULATOR_UDID:-}"
DESTINATION="${DESTINATION:-}"
BUILD_DIR="${BUILD_DIR:-$PROJECT_DIR/.build}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$BUILD_DIR/derived-data}"
COMPILER_INDEX_STORE_ENABLE="${COMPILER_INDEX_STORE_ENABLE:-YES}"

usage() {
  echo "Usage: $0 [build|test|release]"
  echo "  build   Build the Debug app for an available iPhone simulator"
  echo "  test    Run the scheme's tests on an available iPhone simulator"
  echo "  release Build the Release app for a generic iOS device"
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
    awk -F '[()]' -v requested="$name" '
      /^[[:space:]]+iPhone/ {
        device = $1
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", device)
        if (device == requested) {
          print $2
          exit
        }
      }'
}

resolve_simulator_name_by_udid() {
  local udid="$1"
  xcrun simctl list devices available |
    awk -F '[()]' -v requested="$udid" '
      /^[[:space:]]+iPhone/ && $2 == requested {
        device = $1
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", device)
        print device
        exit
      }'
}

resolve_first_iphone_udid() {
  xcrun simctl list devices available |
    awk -F '[()]' '/^[[:space:]]+iPhone/ { print $2; exit }'
}

resolve_simulator_context() {
  local destination_name=""
  local destination_udid=""
  local resolved_name=""

  if [[ -n "$DESTINATION" ]]; then
    [[ "$DESTINATION" == *"platform=iOS Simulator"* ]] ||
      fail "DESTINATION must target an iOS Simulator for $MODE: $DESTINATION"

    destination_udid="$(destination_value id)"
    destination_name="$(destination_value name)"
    if [[ -n "$destination_udid" ]]; then
      SIMULATOR_UDID="$destination_udid"
    elif [[ -n "$destination_name" ]]; then
      SIMULATOR_UDID="$(resolve_simulator_udid_by_name "$destination_name")"
      [[ -n "$SIMULATOR_UDID" ]] || fail "no available iPhone simulator named '$destination_name'"
      DESTINATION="platform=iOS Simulator,id=${SIMULATOR_UDID}"
    else
      fail "DESTINATION must identify an available iPhone simulator by id or name"
    fi
  elif [[ -z "$SIMULATOR_UDID" ]]; then
    SIMULATOR_UDID="$(resolve_simulator_udid_by_name "$SIMULATOR_NAME")"
    if [[ -z "$SIMULATOR_UDID" && -z "$SIMULATOR_NAME_OVERRIDE" ]]; then
      SIMULATOR_UDID="$(resolve_first_iphone_udid)"
    fi
    [[ -n "$SIMULATOR_UDID" ]] || fail "no available iPhone simulator named '$SIMULATOR_NAME'"
    DESTINATION="platform=iOS Simulator,id=${SIMULATOR_UDID}"
  else
    DESTINATION="platform=iOS Simulator,id=${SIMULATOR_UDID}"
  fi

  resolved_name="$(resolve_simulator_name_by_udid "$SIMULATOR_UDID")"
  [[ -n "$resolved_name" ]] || fail "iPhone simulator '$SIMULATOR_UDID' is not available"
}

acquire_build_lock() {
  mkdir -p "$BUILD_DIR"
  LOCK_DIR="$BUILD_DIR/build.lock"
  local waited=0
  local wait_seconds="${LOCK_WAIT_SECONDS:-120}"

  while ! mkdir "$LOCK_DIR" 2>/dev/null; do
    if [[ -f "$LOCK_DIR/pid" ]] && ! kill -0 "$(cat "$LOCK_DIR/pid")" 2>/dev/null; then
      rm -rf "$LOCK_DIR"
      continue
    fi
    if ((waited >= wait_seconds)); then
      fail "timed out waiting for another app/build.sh run to finish"
    fi
    sleep 2
    waited=$((waited + 2))
  done

  echo "$$" > "$LOCK_DIR/pid"
  trap 'rm -rf "$LOCK_DIR"' EXIT
}

run_swiftlint() {
  if command -v swiftlint >/dev/null 2>&1; then
    echo "→ SwiftLint (HIG rules)..."
    swiftlint lint --config "$REPO_ROOT/.swiftlint.yml" --reporter xcode
  else
    echo "⚠ SwiftLint not installed — skipping HIG lint (brew install swiftlint)"
  fi
}

telemetry_preflight() {
  local package_resolved="$PROJECT/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
  local telemetry_pattern='swift-metrics|firebase|sentry-cocoa|datadog|amplitude|mixpanel|segment|braze|newrelic|instana|bugsnag'

  if [[ -f "$package_resolved" ]] && grep -Eiq "$telemetry_pattern" "$package_resolved"; then
    fail "Package.resolved references a third-party telemetry SDK; only MetricKit (system framework) is permitted"
  fi
}

foreign_app_preflight() {
  local bundle_id=""
  local listapps_raw=""

  listapps_raw="$(xcrun simctl listapps "$SIMULATOR_UDID" 2>/dev/null || true)"
  [[ -n "$listapps_raw" ]] || return 0

  while IFS= read -r bundle_id; do
    [[ -n "$bundle_id" ]] || continue
    echo "→ foreign-app preflight: uninstall $bundle_id" >&2
    xcrun simctl uninstall "$SIMULATOR_UDID" "$bundle_id" >/dev/null 2>&1 || true
  done < <(
    printf '%s' "$listapps_raw" |
      /usr/bin/awk -F '"' '/CFBundleIdentifier =/ { print $2 }' |
      grep -E '^com\.yashasg(ujjar)?\.' |
      grep -v '^com\.yashasg\.KnittingGaugeReconciler' ||
      true
  )
}

format_xcodebuild() {
  local bundled_xcpretty=""

  if command -v xcpretty >/dev/null 2>&1; then
    xcpretty
  elif command -v bundle >/dev/null 2>&1 &&
    BUNDLE_GEMFILE="$PROJECT_DIR/Gemfile" bundle check >/dev/null 2>&1; then
    BUNDLE_GEMFILE="$PROJECT_DIR/Gemfile" bundle exec xcpretty
  elif command -v brew >/dev/null 2>&1; then
    bundled_xcpretty="$(brew --prefix fastlane 2>/dev/null)/libexec/bin/xcpretty" || true
    if [[ -x "$bundled_xcpretty" ]]; then
      "$bundled_xcpretty"
    else
      cat
    fi
  else
    cat
  fi
}

case "$MODE" in
  build)
    ACTION="build"
    CONFIGURATION="${CONFIGURATION:-Debug}"
    SDK="${SDK:-iphonesimulator}"
    ;;
  test)
    ACTION="test"
    CONFIGURATION="${CONFIGURATION:-Debug}"
    SDK="${SDK:-iphonesimulator}"
    ;;
  release)
    ACTION="build"
    CONFIGURATION="${CONFIGURATION:-Release}"
    SDK="${SDK:-iphoneos}"
    DESTINATION="${DESTINATION:-generic/platform=iOS}"
    ;;
  -h | --help | help)
    usage
    exit 0
    ;;
  *)
    usage >&2
    exit 64
    ;;
esac

[[ -d "$PROJECT" ]] || fail "Xcode project not found: $PROJECT"

acquire_build_lock
telemetry_preflight
run_swiftlint

if [[ "$MODE" != "release" ]]; then
  resolve_simulator_context
fi
if [[ "$MODE" == "test" ]]; then
  foreign_app_preflight
fi

xcodebuild_args=(
  -project "$PROJECT"
  -scheme "$SCHEME"
  -configuration "$CONFIGURATION"
  -sdk "$SDK"
  -destination "$DESTINATION"
  -destination-timeout 120
  -derivedDataPath "$DERIVED_DATA_PATH"
  -quiet
  "COMPILER_INDEX_STORE_ENABLE=${COMPILER_INDEX_STORE_ENABLE}"
  SWIFT_TREAT_WARNINGS_AS_ERRORS=YES
  GCC_TREAT_WARNINGS_AS_ERRORS=YES
  CLANG_TREAT_WARNINGS_AS_ERRORS=YES
  "OTHER_SWIFT_FLAGS=-warnings-as-errors"
  CODE_SIGNING_ALLOWED=NO
)

if [[ "$MODE" == "test" ]]; then
  xcodebuild_args+=(
    -parallel-testing-enabled NO
    -enableCodeCoverage YES
    -retry-tests-on-failure
    -test-iterations 2
    -test-timeouts-enabled YES
    -default-test-execution-time-allowance 30
  )
fi
xcodebuild_args+=("$ACTION")

xcodebuild "${xcodebuild_args[@]}" 2>&1 | format_xcodebuild
