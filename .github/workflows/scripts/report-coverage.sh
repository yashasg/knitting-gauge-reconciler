#!/usr/bin/env bash
# Print xccov coverage report for the latest .xcresult, or skip if none.
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=_lib.sh
source "$SCRIPT_DIR/_lib.sh"

XCRESULT=$(find_latest_xcresult)
if [[ -z "$XCRESULT" ]]; then
  echo "No .xcresult found — skipping coverage report"
  exit 0
fi
xcrun xccov view --report "$XCRESULT"
