#!/usr/bin/env bash
# Print a human-readable xccov coverage report for the most recent
# .xcresult bundle produced by the test step.
#
# Required env vars:
#   DERIVED_DATA_PATH
set -euo pipefail

: "${DERIVED_DATA_PATH:?DERIVED_DATA_PATH is required}"

XCRESULT=$(find "${DERIVED_DATA_PATH}/Logs/Test" -name "*.xcresult" 2>/dev/null | head -1)
if [[ -z "$XCRESULT" ]]; then
  echo "No .xcresult found — skipping coverage report"
  exit 0
fi
xcrun xccov view --report "$XCRESULT"
