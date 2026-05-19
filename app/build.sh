#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-test}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT="$PROJECT_DIR/KnittingGaugeReconciler.xcodeproj"
SCHEME="KnittingGaugeReconciler"
SIMULATOR_NAME="${SIMULATOR_NAME:-iPhone 17 Pro Max}"
DESTINATION="${DESTINATION:-platform=iOS Simulator,name=${SIMULATOR_NAME}}"

usage() {
  echo "Usage: $0 [build|test|release]"
}

case "$MODE" in
  build)
    ACTION=(clean build)
    CONFIGURATION="Debug"
    DESTINATION_ARGS=(-destination "$DESTINATION")
    ;;
  test)
    ACTION=(clean test)
    CONFIGURATION="Debug"
    DESTINATION_ARGS=(-destination "$DESTINATION")
    ;;
  release)
    ACTION=(clean build)
    CONFIGURATION="Release"
    DESTINATION_ARGS=(-destination "generic/platform=iOS")
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

LOG_FILE="$(mktemp "${TMPDIR:-/tmp}/knitting-gauge-xcodebuild.XXXXXX.log")"
trap 'rm -f "$LOG_FILE"' EXIT

XCODEBUILD_ARGS=(
  -project "$PROJECT"
  -scheme "$SCHEME"
  -configuration "$CONFIGURATION"
  "${DESTINATION_ARGS[@]}"
  SWIFT_TREAT_WARNINGS_AS_ERRORS=YES
  GCC_TREAT_WARNINGS_AS_ERRORS=YES
  CLANG_TREAT_WARNINGS_AS_ERRORS=YES
  OTHER_SWIFT_FLAGS="-warnings-as-errors"
  "${ACTION[@]}"
)

set +e
if command -v xcpretty >/dev/null 2>&1; then
  xcodebuild "${XCODEBUILD_ARGS[@]}" 2>&1 | tee "$LOG_FILE" | xcpretty
  STATUS=${PIPESTATUS[0]}
else
  xcodebuild "${XCODEBUILD_ARGS[@]}" 2>&1 | tee "$LOG_FILE"
  STATUS=${PIPESTATUS[0]}
fi
set -e

if grep -Eiq '(^|[/:[:space:]])warning:' "$LOG_FILE"; then
  echo "error: xcodebuild emitted warnings; treating warnings as failures" >&2
  exit 65
fi

exit "$STATUS"