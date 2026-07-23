#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_SCRIPT="$PROJECT_DIR/build.sh"
BUILD_ROOT_DIR="${BUILD_DIR:-$PROJECT_DIR/.build}"
RUN_BUILD_DIR="${RUN_BUILD_DIR:-$BUILD_ROOT_DIR/run-build}"
DERIVED_DATA_DIR="$RUN_BUILD_DIR/derived-data"
CONFIGURATION="${CONFIGURATION:-Debug}"
SDK="${SDK:-iphonesimulator}"
PROJECT="$PROJECT_DIR/app.xcodeproj"
SCHEME="KnittingGaugeReconciler"

DEFAULT_SIMULATOR_NAME="$(sed -n 's/^SIMULATOR_NAME="${SIMULATOR_NAME:-\(.*\)}"$/\1/p' "$BUILD_SCRIPT" | head -n 1)"
SIMULATOR_NAME="${SIMULATOR_NAME:-${DEFAULT_SIMULATOR_NAME:-iPhone 17 Pro}}"
SIMULATOR_UDID="${SIMULATOR_UDID:-}"
DESTINATION="${DESTINATION:-}"

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
  xcrun simctl list devices available "$name" |
    awk -F '[()]' '/^[[:space:]]+.*\([0-9A-F-]{36}\)/ { print $2; exit }'
}

resolve_simulator() {
  local destination_udid=""
  local destination_name=""

  if [[ -n "$DESTINATION" ]]; then
    [[ "$DESTINATION" == *"platform=iOS Simulator"* ]] || \
      fail "DESTINATION must target an iOS Simulator to run the app: $DESTINATION"

    destination_udid="$(destination_value id)"
    destination_name="$(destination_value name)"

    if [[ -n "$destination_udid" ]]; then
      SIMULATOR_UDID="$destination_udid"
    elif [[ -n "$destination_name" ]]; then
      SIMULATOR_UDID="$(resolve_simulator_udid_by_name "$destination_name")"
      [[ -n "$SIMULATOR_UDID" ]] || fail "no available simulator named '$destination_name'"
    fi
  fi

  if [[ -z "$SIMULATOR_UDID" ]]; then
    SIMULATOR_UDID="$(resolve_simulator_udid_by_name "$SIMULATOR_NAME")"
  fi

  [[ -n "$SIMULATOR_UDID" ]] || fail "no available simulator named '$SIMULATOR_NAME'"
}

resolve_app_bundle() {
  local settings target_build_dir wrapper_name
  settings="$(
    xcodebuild \
      -project "$PROJECT" \
      -scheme "$SCHEME" \
      -configuration "$CONFIGURATION" \
      -sdk "$SDK" \
      -destination "$BUILD_DESTINATION" \
      -derivedDataPath "$DERIVED_DATA_DIR" \
      CODE_SIGNING_ALLOWED=NO \
      COMPILER_INDEX_STORE_ENABLE=NO \
      -showBuildSettings
  )" || fail "could not resolve app build settings"

  target_build_dir="$(printf '%s\n' "$settings" | sed -n 's/^[[:space:]]*TARGET_BUILD_DIR = //p' | head -n 1)"
  wrapper_name="$(printf '%s\n' "$settings" | sed -n 's/^[[:space:]]*WRAPPER_NAME = //p' | head -n 1)"
  [[ -n "$target_build_dir" ]] || fail "TARGET_BUILD_DIR missing from Xcode build settings"
  [[ "$wrapper_name" == *.app ]] || fail "invalid WRAPPER_NAME from Xcode build settings: $wrapper_name"

  printf '%s/%s\n' "$target_build_dir" "$wrapper_name"
}

bundle_identifier() {
  local app_bundle="$1"
  local info_plist="$app_bundle/Info.plist"
  [[ -f "$info_plist" ]] || fail "Info.plist not found in built app: $app_bundle"
  /usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$info_plist"
}

simulator_state() {
  xcrun simctl list devices "$SIMULATOR_UDID" |
    awk -F '[()]' -v udid="$SIMULATOR_UDID" '$0 ~ udid { print $(NF - 1); exit }'
}

resolve_simulator

BUILD_DESTINATION="$DESTINATION"
if [[ -z "$BUILD_DESTINATION" ]]; then
  BUILD_DESTINATION="platform=iOS Simulator,id=${SIMULATOR_UDID}"
fi

if ! BUILD_DIR="$RUN_BUILD_DIR" CONFIGURATION="$CONFIGURATION" SDK="$SDK" COMPILER_INDEX_STORE_ENABLE=NO DESTINATION="$BUILD_DESTINATION" "$BUILD_SCRIPT" build; then
  fail "build failed"
fi

APP_BUNDLE="$(resolve_app_bundle)"
[[ -d "$APP_BUNDLE" ]] || fail "built app bundle not found: $APP_BUNDLE"

STAGED_DIR="$BUILD_ROOT_DIR/run"
STAGED_APP="$STAGED_DIR/$(basename "$APP_BUNDLE")"
rm -rf "$STAGED_DIR"
mkdir -p "$STAGED_DIR"
ditto "$APP_BUNDLE" "$STAGED_APP"

BUNDLE_ID="$(bundle_identifier "$STAGED_APP")"
[[ -n "$BUNDLE_ID" ]] || fail "could not determine bundle identifier from $STAGED_APP"

open -a Simulator >/dev/null 2>&1 || true
if [[ "$(simulator_state)" != "Booted" ]]; then
  xcrun simctl boot "$SIMULATOR_UDID" >/dev/null 2>&1 || true
fi
xcrun simctl bootstatus "$SIMULATOR_UDID" -b >/dev/null
xcrun simctl install "$SIMULATOR_UDID" "$STAGED_APP"
xcrun simctl launch "$SIMULATOR_UDID" "$BUNDLE_ID"
