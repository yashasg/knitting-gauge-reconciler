#!/usr/bin/env bash
# Fail the job if line coverage from the most recent .xcresult is below
# COVERAGE_FLOOR.
#
# Floor calibrated to today's measured iPhone-Debug coverage (~47.4%)
# with a small tolerance band, ratcheting up over time toward the 80%
# v1 target (#545). Update the COVERAGE_FLOOR knob (not the comparison)
# when bumping.
# TODO: ratchet +5pp/quarter until reaching 80% once v1 audit blockers
# close (20 open P0/P1 issues per .squad/decisions.md).
#
# Required env vars:
#   DERIVED_DATA_PATH
set -euo pipefail

: "${DERIVED_DATA_PATH:?DERIVED_DATA_PATH is required}"

COVERAGE_FLOOR=45

XCRESULT=$(find "${DERIVED_DATA_PATH}/Logs/Test" -name "*.xcresult" 2>/dev/null | head -1)
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
