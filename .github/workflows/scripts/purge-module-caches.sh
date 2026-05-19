#!/usr/bin/env bash
# Remove SDK-bound module caches restored from the cache action so the
# Swift compiler does not detect a SwiftShims mtime mismatch on the
# first build of the run.
#
# Required env vars:
#   DERIVED_DATA_PATH
set -euo pipefail

: "${DERIVED_DATA_PATH:?DERIVED_DATA_PATH is required}"

for SUBDIR in ModuleCache.noindex SDKStatCaches.noindex; do
  CACHE_PATH="${DERIVED_DATA_PATH}/${SUBDIR}"
  if [[ -d "$CACHE_PATH" ]]; then
    echo "Removing stale ${SUBDIR} (would otherwise trigger SwiftShims mtime mismatch)"
    rm -rf "$CACHE_PATH"
  fi
done
