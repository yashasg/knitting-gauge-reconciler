#!/usr/bin/env bash
# Export BUILD_NUMBER, GIT_COMMIT_HASH, MARKETING_VERSION to GITHUB_ENV.
set -euo pipefail

: "${BUILD_NUMBER:?BUILD_NUMBER is required}"
: "${GITHUB_ENV:?GITHUB_ENV is required}"

COMMIT_HASH=$(git rev-parse --short HEAD)

# Locate the (single) xcodeproj under app/ so this workflow stays
# project-agnostic.
shopt -s nullglob
XCODEPROJ_MATCHES=(app/*.xcodeproj)
shopt -u nullglob
if (( ${#XCODEPROJ_MATCHES[@]} == 0 )); then
  echo "::error::No .xcodeproj found under app/"
  exit 1
fi
if (( ${#XCODEPROJ_MATCHES[@]} > 1 )); then
  echo "::error::Multiple .xcodeproj found under app/: ${XCODEPROJ_MATCHES[*]}"
  exit 1
fi
PBXPROJ="${XCODEPROJ_MATCHES[0]}/project.pbxproj"

MARKETING_VER=$(awk '/MARKETING_VERSION = /{gsub(/;/,""); print $NF; exit}' "$PBXPROJ")

{
  echo "BUILD_NUMBER=$BUILD_NUMBER"
  echo "GIT_COMMIT_HASH=$COMMIT_HASH"
  echo "MARKETING_VERSION=$MARKETING_VER"
} >> "$GITHUB_ENV"

echo "Version: marketing=${MARKETING_VER} build=${BUILD_NUMBER} commit=${COMMIT_HASH}"
