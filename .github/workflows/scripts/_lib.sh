#!/usr/bin/env bash
# Shared helpers for ci.yml step scripts. Source, do not execute.

# Echo the path to the most recent .xcresult bundle under
# $DERIVED_DATA_PATH/Logs/Test, or empty string if none exist.
find_latest_xcresult() {
  : "${DERIVED_DATA_PATH:?DERIVED_DATA_PATH is required}"
  find "${DERIVED_DATA_PATH}/Logs/Test" -name "*.xcresult" 2>/dev/null | head -1
}
