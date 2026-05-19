#!/usr/bin/env bash
# Drop SDK-bound module caches from a restored DerivedData to avoid the
# SwiftShims mtime mismatch on first build.
set -euo pipefail

: "${DERIVED_DATA_PATH:?DERIVED_DATA_PATH is required}"

for SUBDIR in ModuleCache.noindex SDKStatCaches.noindex; do
  CACHE_PATH="${DERIVED_DATA_PATH}/${SUBDIR}"
  if [[ -d "$CACHE_PATH" ]]; then
    echo "Removing stale ${SUBDIR}"
    rm -rf "$CACHE_PATH"
  fi
done
