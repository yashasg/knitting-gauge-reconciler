#!/usr/bin/env bash
# Invoke app/build.sh with the resolved configuration for the iPhone 17
# Pro simulator. Tests always run in Debug; the build configuration is
# Debug for MRs and Release for push-to-main (see resolve-build-profile.sh).
#
# Required env vars:
#   CONFIGURATION
#   TEST_CONFIGURATION
#   DERIVED_DATA_PATH
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
