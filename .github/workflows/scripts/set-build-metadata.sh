#!/usr/bin/env bash
# Export BUILD_NUMBER, GIT_COMMIT_HASH, MARKETING_VERSION to GITHUB_ENV.
set -euo pipefail

: "${BUILD_NUMBER:?BUILD_NUMBER is required}"
: "${GITHUB_ENV:?GITHUB_ENV is required}"

COMMIT_HASH=$(git rev-parse --short HEAD)
MARKETING_VER=$(awk '/MARKETING_VERSION = /{gsub(/;/,""); print $NF; exit}' app/app.xcodeproj/project.pbxproj)

{
  echo "BUILD_NUMBER=$BUILD_NUMBER"
  echo "GIT_COMMIT_HASH=$COMMIT_HASH"
  echo "MARKETING_VERSION=$MARKETING_VER"
} >> "$GITHUB_ENV"

echo "Version: marketing=${MARKETING_VER} build=${BUILD_NUMBER} commit=${COMMIT_HASH}"
