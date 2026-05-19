#!/usr/bin/env bash
# Resolve CONFIGURATION/TEST_CONFIGURATION from event type.
# push-to-main → Release (gates whole-module opt + Release linker config, #544);
# everything else (MRs) → Debug to halve wall-clock. Tests always Debug so
# @testable + TCA transitive internals stay linkable on Xcode 26.
set -euo pipefail

: "${EVENT:?EVENT is required}"
: "${BRANCH:?BRANCH is required}"
: "${GITHUB_ENV:?GITHUB_ENV is required}"

if [[ "$EVENT" == "push" && "$BRANCH" == "main" ]]; then
  BUILD_CONFIGURATION="Release"
else
  BUILD_CONFIGURATION="Debug"
fi
TEST_CONFIGURATION_VALUE="Debug"

{
  echo "CONFIGURATION=$BUILD_CONFIGURATION"
  echo "TEST_CONFIGURATION=$TEST_CONFIGURATION_VALUE"
} >> "$GITHUB_ENV"

echo "Resolved build profile: event=$EVENT branch=$BRANCH CONFIGURATION=$BUILD_CONFIGURATION TEST_CONFIGURATION=$TEST_CONFIGURATION_VALUE"
