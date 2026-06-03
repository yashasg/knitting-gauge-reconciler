# CI Location: GitHub Actions Mirror

**Date:** 2026-06-02  
**Author:** Hopper  
**Status:** Resolved — fix applied

## Decision

The Stitchwise iOS project's CI pipeline runs on **GitHub Actions**, not GitLab CI. GitLab is the source-of-truth repository; a webhook mirrors pushes and merge requests to a public GitHub repo (`yashasg/knitting-gauge-reconciler`) and triggers `repository_dispatch` events that run the CI workflow.

## Context

MR !44 (consolidated gauge display #48/#49, unit toggle #50, Dynamic Type a11y, SwiftLint guard) was squash-merged as commit `adc87ce` without waiting for CI, based on an incorrect belief that there was no CI on GitLab. This session was opened to verify CI after the fact.

## Architecture

| Component | Detail |
|-----------|--------|
| GitLab repo | `yashasg/knitting-gauge-reconciler` (primary) |
| GitHub mirror | `yashasg/knitting-gauge-reconciler` (public, CI host) |
| Trigger | `repository_dispatch` types `gitlab_push`, `gitlab_mr` |
| CI workflow | `.github/workflows/ci.yml` (on GitHub only, NOT in GitLab worktree) |
| CD workflow | `.github/workflows/cd.yml` (local + GitHub, manual-only) |
| CI steps | Checkout from GitLab → build Release → test Debug via `fastlane ci` |
| Status reporting | CI posts back to GitLab Commits API at end of run |

## CI Run for main (post-!44-merge)

- **Run ID:** 26861282336  
- **Branch:** main  
- **Attempt 1:** `completed | failure` — 70 tests, 1 failure  
- **Attempt 2 (rerun):** `completed | failure` — 70 tests, 1 failure  

## Root Cause of "1 failure"

`Fastfile` `lane_test_options` sets:
```
-test-timeouts-enabled YES -default-test-execution-time-allowance 30
```

This applies a 30-second execution time limit globally to ALL tests. UI tests routinely take 30–120 seconds per test on CI simulators. When a test exceeds the allowance, xcodebuild records a "time exceeded" failure in the xcresult **even if the test's assertions all pass**. xcbeautify still shows ✔ for such tests. Fastlane reads the xcresult failure count → reports 1 failure → CI fails.

**Attempt 1 chain:** `testStepperFieldOpensWheelAndKeyboard` ran 89 s (59 s over limit) → xcresult time-exceeded marker → 1 failure. Three remaining UI tests deferred to xcodebuild's "Selected tests" retry, all passed.

**Attempt 2 chain:** App-launch stall caused all 10 KnittingGaugeReconcilerUITests to be deferred to "Selected tests" retry. In that retry, `testMismatchStatesKeepYourGaugeFieldsEqualWidth` ran 49 s (19 s over limit) → xcresult time-exceeded marker → 1 failure. All assertions passed.

No code defect. All merged workstreams are functionally correct.

## Fix Applied

Added `override var executionTimeAllowance: TimeInterval { 300 }` to both UI test classes:

- `KnittingGaugeReconcilerUITests` (`KnittingGaugeReconcilerUITests.swift`)
- `AccessibilityAuditTests` (`AccessibilityAuditTests.swift`)

This tells xcodebuild that each test in these classes may take up to 300 seconds, overriding the global 30-second default. The 30-second limit remains in force for unit tests (which all run in < 1 second each and benefit from the timeout guard).

Also fixed in this session:
- `ContentView.swift`: added `// swiftlint:disable:next type_body_length` (253 lines > 250 limit)
- `RequiredAdjustmentsCard.swift`: removed superfluous `// swiftlint:disable file_length` (338 lines, under 400-line threshold)

## Key Commands

```bash
# Check CI status for main
gh run list -R yashasg/knitting-gauge-reconciler --branch main --limit 10

# Poll run status
gh api "repos/yashasg/knitting-gauge-reconciler/actions/runs/<run-id>" \
  --jq '"\(.status) | \(.conclusion)"'

# View failure logs
gh run view <run-id> --log-failed -R yashasg/knitting-gauge-reconciler

# Rerun a failed run
gh run rerun <run-id> -R yashasg/knitting-gauge-reconciler
```

## Process Decision

**Never merge to main without waiting for the GitHub Actions CI run to complete green.** The run takes ~10 minutes. Use `gh run list -R yashasg/knitting-gauge-reconciler --branch main` to identify the run; the `display_title` (not `head_sha`) is the reliable identifier since `repository_dispatch` events don't expose the GitLab commit SHA in GitHub's `head_sha`.
