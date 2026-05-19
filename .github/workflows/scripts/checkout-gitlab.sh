#!/usr/bin/env bash
# Shallow-clone the GitLab project (GITLAB_BRANCH of GITLAB_PROJECT) into CWD.
set -euo pipefail

: "${GITLAB_PAT:?GITLAB_PAT is required}"
: "${GITLAB_BRANCH:?GITLAB_BRANCH is required}"
: "${GITLAB_PROJECT:?GITLAB_PROJECT is required}"

git clone --depth 1 \
  --branch "$GITLAB_BRANCH" \
  "https://gitlab-token:${GITLAB_PAT}@gitlab.com/${GITLAB_PROJECT}" \
  .
