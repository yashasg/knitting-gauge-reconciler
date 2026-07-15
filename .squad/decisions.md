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

---

## 2026-07-14T20:12:26.685-07:00 — INBOX MERGE: tesla-work-loop-design-review.md

# Before-work design review — complete Squad Work Loop

**Date:** 2026-07-14T19:52:25.092-07:00  
**Author:** Tesla  
**Verdict:** APPROVED WITH ORDERED GATES

## Baseline and changed reality

- `./app/build.sh test` passes on iPhone 17 Pro / iOS 26.5: 70 passed, 0 failed, 0 skipped; SwiftLint, compiler, and analyzer warnings are all zero.
- The archival JavaScript harness passes 77/77 with no pending tests. It corroborates the formulas but is not the UI or scenario authority.
- GitHub mirror authentication is restored and GitLab #76 is closed. Main commit `41050a1` has a successful exact-commit GitLab pipeline.
- `squad/20260714-work-loop` is clean and three commits ahead of `origin/main`, but has no remote branch, MR, or exact-commit external gate.
- The prior queue is stale: #77 now reviews canonical design issues rather than `prototype/`; #78 and #79 now include omission semantics; #76 is resolved.
- The requested `app/KnittingGaugeReconciler.xcodeproj` path does not exist. The checked-in, scheme-valid project is `app/app.xcodeproj`; renaming it adds risk without user value.

## Contracts

- Keep the native `./app/build.sh` gate for local build/test/release-build work; Fastlane remains for signed distribution. Close #59 as superseded rather than reintroducing Fastlane into the local gate.
- Restore the canonical formulas and six scenarios from `93323af` to `.squad/decisions/decisions.md` before domain sign-off.
- Validation must produce typed required/optional values before `GaugeMath.compute`; no raw, non-finite, omitted, or out-of-range text may reach integer conversion. Valid calculations and rounding remain unchanged.
- Optional values stay absent through calculation, results, full math, sharing, persistence signatures, and VoiceOver. No layer may invent defaults.
- Prototype parity is forbidden. #72 and the current issue contracts are the design authority.
- Every implementation MR needs Curie evidence and its named reviewer. A rejection locks that artifact's author out of the next revision.

## Smallest dependency-aware queue

1. **Hopper → Tesla:** push the current work-loop branch, open an MR, obtain exact-SHA GitHub/GitLab green status; Tesla reviews and merges. Hopper then owns #57 → #58 and #63. No #59 implementation.
2. **Foundation, in isolated branches:** Ada owns #62 and the canonical math-ledger restoration; Curie owns #51 and #60; Edison owns #61 and #74. These are behavior-preserving cuts or missing test/status gates.
3. **P0 #65:** Ada owns the pure validation/conversion contract; Edison owns field integration and accessible error behavior; Curie owns the table/UI/a11y tests; Ive reviews. Merge only as one coherent contract.
4. **Locked StoreKit/Settings chain:** Edison is prohibited from #53–#56. A newly assigned SwiftUI/StoreKit specialist must own #53 and #54, then #55, then #56. #56 also waits for #65 and #68 despite its issue listing only #55. Curie tests; Ive reviews purchase and settings UX; Tesla reviews boundaries.
5. **Core P1 workflow:** Edison implements #68 → #66, then #73. Curie tests omission behavior; Ive reviews hierarchy/accessibility; Ada reviews typed model seams.
6. **P2 closure:** Edison implements #67 and #69, then #70, then #71; #75 follows #62 and #68. Preserve #74 if already merged. Curie restores audits before #71 can close.
7. **Independent final reviews:** Mendel performs #78 after #62/#65/#66/#68; Jacquard performs #79 after #62/#65/#68 and ledger restoration. Each must record APPROVED or REJECTED.
8. **Ive → Curie → Tesla:** Ive performs #77 only after its listed implementation dependencies are closed. Curie performs #80 on the exact final `main` SHA with matching GitHub and GitLab evidence. Tesla gives final integration approval only after all reviewer inboxes are resolved.

## Trade-off and blocker

This queue favors sequential shared-model/UI changes over maximum parallelism, reducing merge and contract drift at the cost of elapsed time. Work may proceed on steps 1–3 and independent foundation items now. The StoreKit/Settings chain cannot proceed until a non-Edison implementation specialist is assigned; bypassing that lockout is prohibited.
