#!/usr/bin/env bash
# Fail if line coverage from the latest .xcresult is below COVERAGE_FLOOR.
# Floor tracks today's iPhone-Debug measurement (~47.4%); ratchet toward
# 80% v1 target (#545) — bump COVERAGE_FLOOR, not the comparison.
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=_lib.sh
source "$SCRIPT_DIR/_lib.sh"

COVERAGE_FLOOR=45

XCRESULT=$(find_latest_xcresult)
if [[ -z "$XCRESULT" ]]; then
  echo "::error::No .xcresult found — tests may have crashed before producing results"
  exit 1
fi

COVERAGE=$(xcrun xccov view --report --json "$XCRESULT" | python3 -c "import json,sys; raw=sys.stdin.read(); raw.strip() or (print('::error::Coverage JSON was empty from xccov', file=sys.stderr) or sys.exit(1)); data=json.loads(raw); line_coverage=data.get('lineCoverage'); isinstance(line_coverage, (int, float)) or (print('::error::Coverage JSON missing numeric lineCoverage', file=sys.stderr) or sys.exit(1)); print(line_coverage * 100)")

if [[ ! "$COVERAGE" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  echo "::error::Computed coverage is not numeric: '$COVERAGE'"
  exit 1
fi

echo "Line coverage: ${COVERAGE}%"

if (( $(echo "$COVERAGE < $COVERAGE_FLOOR" | bc -l) )); then
  echo "::error::Coverage ${COVERAGE}% is below the minimum threshold (${COVERAGE_FLOOR}%)"
  exit 1
fi
