# Hopper — ASC auth file fallback

- **Date:** 2026-05-23T03:01:49-07:00
- **Author:** Hopper
- **Status:** Proposed

## Context

GitHub Actions CD writes `ASC_API_KEY_JSON` to `app/fastlane/asc_api_key.json` in one step, validates it, then runs `bundle exec fastlane` in a later step. Step-level `env:` does not carry forward automatically, so Fastlane cannot rely on `ENV["ASC_API_KEY_JSON"]` being present in the upload step.

## Decision

Keep `ASC_API_KEY_JSON` as the first-priority input for local/dev overrides, but fall back to reading `app/fastlane/asc_api_key.json` when the env var is absent.

## Rationale

- Matches the existing workflow contract: the JSON file is already written and validated before Fastlane runs.
- Preserves local development flows that export `ASC_API_KEY_JSON` directly.
- Avoids re-wiring secrets across multiple workflow steps when a stable on-disk artifact already exists.

## Consequence

Fastlane release lanes work in GitHub Actions even when `ASC_API_KEY_JSON` is scoped only to the write step, while local env-based invocation remains unchanged.
