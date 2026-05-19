#!/usr/bin/env bash
# Build + test via app/build.sh.
set -euo pipefail

: "${CONFIGURATION:?CONFIGURATION is required}"
: "${TEST_CONFIGURATION:?TEST_CONFIGURATION is required}"
: "${DERIVED_DATA_PATH:?DERIVED_DATA_PATH is required}"

cd app && \
  PLATFORM_MODE=iphone \
  CONFIGURATION="$CONFIGURATION" \
  TEST_CONFIGURATION="$TEST_CONFIGURATION" \
  RUN_ANALYZE=false \
  RUN_SWIFT_FORMAT=false \
  RUN_TESTS=true \
  DERIVED_DATA_PATH="$DERIVED_DATA_PATH" \
  ./build.sh
