#!/usr/bin/env bash
# Mirror the job status back to the GitLab commit as a pipeline status.
#
# Required env vars:
#   GITLAB_PAT
#   GITLAB_PROJECT_ID  — numeric GitLab project id (from client_payload.project_id)
#   GITLAB_SHA         — commit sha to attach the status to
#   JOB_STATUS         — value of ${{ job.status }}
#   TARGET_URL         — URL of the Actions run for the GitLab status link
set -euo pipefail

: "${GITLAB_PAT:?GITLAB_PAT is required}"
: "${GITLAB_PROJECT_ID:?GITLAB_PROJECT_ID is required}"
: "${GITLAB_SHA:?GITLAB_SHA is required}"
: "${JOB_STATUS:?JOB_STATUS is required}"
: "${TARGET_URL:?TARGET_URL is required}"

STATE=$([[ "$JOB_STATUS" == "success" ]] && echo "success" || echo "failed")

curl -X POST \
  -H "PRIVATE-TOKEN: ${GITLAB_PAT}" \
  "https://gitlab.com/api/v4/projects/${GITLAB_PROJECT_ID}/statuses/${GITLAB_SHA}" \
  -d "state=${STATE}" \
  -d "name=Build & Test" \
  -d "target_url=${TARGET_URL}"
