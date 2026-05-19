#!/usr/bin/env bash
# Resolve CONFIGURATION / TEST_CONFIGURATION based on the GitLab event type.
#
# MRs run Debug-only to halve the wall clock (#544) — the audit
# showed Release build was ~7m and Debug build+test prep was
# ~12m, so dropping Release off the MR critical path is the
# single biggest lever. Push events on main still produce the
# Release build so whole-module optimization, Swift -O, and the
# Release-only linker config remain gated before any downstream
# tag/deploy. Tests always run in Debug.
#
# Required env vars:
#   EVENT   — client_payload.event ("push" or "merge_request")
#   BRANCH  — client_payload.branch
#   GITHUB_ENV — provided by GitHub Actions
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
