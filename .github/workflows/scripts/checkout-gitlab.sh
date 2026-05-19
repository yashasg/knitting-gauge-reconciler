#!/usr/bin/env bash
# Shallow-clone the GitLab source repo into the current working directory.
#
# Required env vars (passed via the workflow `env:` block):
#   GITLAB_PAT       — Personal access token with read_repository on the project
#   GITLAB_BRANCH    — Branch to check out (from client_payload.branch)
#   GITLAB_PROJECT   — Project path, e.g. "yashasg/value-compass"
set -euo pipefail

: "${GITLAB_PAT:?GITLAB_PAT is required}"
: "${GITLAB_BRANCH:?GITLAB_BRANCH is required}"
: "${GITLAB_PROJECT:?GITLAB_PROJECT is required}"

git clone --depth 1 \
  --branch "$GITLAB_BRANCH" \
  "https://gitlab-token:${GITLAB_PAT}@gitlab.com/${GITLAB_PROJECT}" \
  .
