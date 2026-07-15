# Squad Decisions — Active Ledger

## 2026-07-14T19:32:30.380-07:00 — INBOX MERGE: copilot-directive-20260714T191233-0700.md

### 2026-07-14T19:12:33.344-07:00: User directive
**By:** Tesla (Squad) (via Copilot)
**What:** Execute the complete Squad Work Loop without questions; use full Ponytail mode; use gpt-5.6-sol for every launched member including Ralph and Scribe; require all five app, UX, scenario, math-review, and zero-warning test goals to pass; use GitLab issues, pipelines, and green-before-merge; preserve unrelated work and use native/stdlib solutions with the smallest correct diff.
**Why:** User request — captured for team memory
---

## 2026-07-14T19:32:30.380-07:00 — INBOX MERGE: hopper-ci-credential-restored.md

# GitHub mirror credential gate restored

**Date:** 2026-07-14T19:32:30.380-07:00
**Author:** Hopper
**Status:** Resolved

GitHub Actions run `29374257138`, attempt 2, successfully cloned the private GitLab `main` branch, completed the existing Build & Test job, and posted a successful status to exact GitLab commit `41050a158b11fb240546958e708f4b7fd8e9b494`. The status links back to that run. SwiftLint reported 0 violations and all test suites passed.

No repository code or CI configuration change was needed. The existing native bridge worked after the repository secret was replaced by its human owner, so no credential fallback or additional tooling was added. The local `squad/20260714-work-loop` commit remains ungated until that branch is pushed and receives its own exact-commit run.
---

## 2026-07-14T19:32:30.380-07:00 — INBOX MERGE: tesla-work-loop-plan.md

### 2026-07-14T19:12:33.344-07:00: Work-loop design review
**By:** Tesla

## Current state

1. **Goal 1 — locally green.** `./app/build.sh test` exited 0 on an iPhone 17 Pro simulator running iOS 26.5. The xcresult reports 70 passing test runs, 0 failures/skips, and a successful build with 0 errors, compiler warnings, or analyzer warnings. SwiftLint reported 0 violations. The prototype harness separately reports 77 passed, 0 failed, 0 pending.
2. **Goal 2 — open as #77.** The present SwiftUI is not the previously approved byte set: it now uses Stitchwise branding, separate gauge cards, a unit toggle, wheel sheets, and a results sheet, while the prototype uses one gauge card and inline hero/verdict/results. Accessibility and Dynamic Type work is present, but `PatternInstructionsCard` still forces a one-line heading and broad audit suppressions remain. Ive must issue a fresh verdict; old sign-off cannot carry forward.
3. **Goal 3 — evidence complete, reviewer gate open as #78.** `GaugeMathTests` contains a direct `scenario1...scenario6` mapping to all six JS vectors. Mendel still needs to record the requested confirmation. The older UI-level six-scenario test no longer exists; that is not a blocker unless Mendel requires UI coverage.
4. **Goal 4 — blocked, open as #79.** `GaugeMath.compute` preserves the historical formulas and rounding, but the current `.squad/decisions/decisions.md` no longer contains the canonical math contract or six scenarios. They exist in git history at `93323af`. Restore that contract before Jacquard reviews; historical sign-off cannot validate a missing current ledger.
5. **Goal 5 — open as #80.** Tesla's local run proves the candidate gate is green, but Curie has not run the final post-merge command.

The external CI gate is red before checkout: both recent GitHub mirror runs fail GitLab authentication and status reporting. Existing P0 #76 correctly owns this; no application test ran in those jobs. GitLab has no open merge requests and no pipeline for the current branch.

## Smallest ordered queue

1. **Hopper — #76:** restore the secret-backed GitHub mirror checkout and exact-SHA GitLab status post. No source credential fallback.
2. **Validation safety — #65:** centralize finite/range validation before integer conversion; this is the only existing product issue that is a hard dependency of the zero-crash claim.
3. **Ada then Jacquard — #79:** Ada restores the canonical math contract from repository history without changing formulas; Jacquard independently approves or rejects the current Swift port.
4. **Parallel reviewer gates — #77 and #78:** Ive reviews current SwiftUI against the prototype; Mendel records the six-scenario map. Do not pre-implement the broader #72 design tracker. Only explicit Ive blockers enter this mandatory queue.
5. **Goal 1 branch gate:** push `squad/20260714-work-loop`, open an MR to `main`, and require the exact commit's mirror run and GitLab status to be green before merge.
6. **Curie — #80:** after all accepted changes are merged, run `./app/build.sh test`, inspect the xcresult, and confirm zero failures, crashes, warnings, analyzer warnings, skips, and lint violations.
7. **Tesla final review:** only after the mandatory queue and inbox are empty.

## Contracts to preserve

- Math: `patternStitches / yourStitches`, `yourRows / patternRows`, `patternRows / yourRows`, increase spacing multiplied by row scale, cast-on multiplied by `yourStitches / patternStitches`, nearest rounding, and the six named vectors.
- Validation must reject non-finite/out-of-range raw text before any `Double` to `Int` conversion; valid existing calculations remain byte-for-byte equivalent.
- Keep current accessibility identifiers, 44-point controls, VoiceOver semantics, uncapped Dynamic Type, and `ViewThatFits` reflow unless an approved UI revision explicitly supersedes them.
- The gate remains the native simulator command with Swift/GCC/Clang warnings as errors, serial UI tests, SwiftLint, and an inspectable xcresult.
- CI credentials stay only in secret/configuration stores; the green status must identify the exact GitLab commit.
- Reviewer rejection locks the original artifact author out of that revision cycle; a different specialist must revise.

## Branch decision and first batch

`squad/20260714-work-loop` is a valid **Goal 1 candidate**, two commits ahead of `origin/main`, and its local gate is green. It is not merge-ready or suitable as a shared specialist branch: it has no remote/upstream, contains an unrelated uncommitted `.squad/identity/now.md` update, and CI authentication is blocked. Preserve it; use isolated issue branches from `origin/main` for #65 and any reviewer-directed revisions.

Recommended first batch: Hopper on #76, Ada on the #79 ledger restoration, Mendel on #78, and Ive on #77. These scopes are independent; Jacquard waits only for Ada, and Curie waits for all merged work.
