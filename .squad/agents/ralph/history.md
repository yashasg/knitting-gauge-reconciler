# Ralph — History

## Core Context

- **Project:** A knitting gauge reconciler that converts patterns between stitch/row gauges.
- **Role:** Work Monitor
- **Joined:** 2026-05-19T07:11:08.647Z

## Learnings

<!-- Append learnings below -->

### 2026-07-16T10:52:38.873-07:00 — Work-loop reconciliation

- `main` and `origin/main` agree at `68371960f65911ad94c3c6a1040568fec1086c6d`; exact GitLab pipeline `2682301311` and `Build & Test` status passed.
- No merge request is open. Issues #93–#97 shipped through MRs !61–!65. Open #1 is a tracker; #51, #52, #57, #60, #62, and #66 are all `follow-up`, with #66 dependent on #62, so no domain issue is runnable.
- Preserve 34 stashes, six safety refs, the closed-unmerged `ci-smoke-test` and `fix/asc-numeric-app-id` branches, legacy remote branches, and ignored Squad/scratch records. Their state is unshipped or ambiguous; no cleanup authority exists.
- `.squad/identity/now.md` is stale relative to GitLab: #82 and #83 are closed, and final-review work through #97 is shipped.

### 2026-07-16T11:52:52.060-07:00 — Issue #51 reconciliation

- GitLab #51 is the sole runnable domain issue. It is open, no MR exists, and its isolated branch has no commits beyond `origin/main`.
- The #51 worktree has four uncommitted files that re-enable the serial UI target, remove broad and in-test retries, and revise obsolete live-results UI contracts. These changes are unfinished and unshipped, so preserve and resume them.
- Local `main` is two Squad-record commits ahead of `origin/main` and has dirty Ada/Jacquard/Ralph histories. Preserve all of it, along with 34 stashes, six safety refs, closed-unmerged branches, ignored records, and legacy remotes.
- Goals #2 and #4 retain direct exact-main evidence. Goals #1, #3, and #5 require #51's complete 85-test gate, independent Curie approval, exact-current-MR green pipeline, merge, and safe cleanup.

## [2026-05-19 19:13:04Z] Canonical Xcode Project Path Update

⚠️ **All squad members:** The Xcode project has been renamed to **`app/app.xcodeproj`**. 

- **Previous path:** `app/KnittingGaugeReconciler.xcodeproj`
- **Current path:** `app/app.xcodeproj` (canonical reference)
- **App target & scheme:** `KnittingGaugeReconciler` (unchanged)
- **Build script:** `app/build.sh` updated and validated

Any references to the old project path should be updated. Use `app/app.xcodeproj` going forward.

---

### 2026-05-19 — corrected canonical Xcode project path

Correction to earlier path note: the project bundle must remain `app/KnittingGaugeReconciler.xcodeproj` per the explicit Tesla scaffold priority item. Route future build/project-path work to Hopper with the full project path.

## 2026-05-22T20:37:00-07:00 — Prototype-parity governance purge + auto-merge scope change

**Session:** scribe-orchestration-2026-05-22  

**Context:** Tesla retired the team-wide prototype-parity heuristic (2026-05-22T19:27:12-07:00). Ralph's auto-pickup queue must reject issues whose rationale is primarily a prototype diff. Visible UI changes are excluded from auto-merge; they pause for Tesla sign-off before implementation.

**New scope:** Ralph loop auto-pickup-eligible: backend, tooling, tests, accessibility fixes, warning cleanup, bug fixes that don't change visible layout. Excluded: visible UI/UX changes, hierarchy changes on primary screen, new prominent visual elements. These always wait for Tesla.

**Implication for Ralph:** Issues #44 (hero tiles) and #46 (information hierarchy) are invalidated as work items — they exist only as artifacts of the prototype-parity misframe, not as bugs to fix. Ralph should bounce or close such issues on receipt.

**New regime:** The app is the source of truth. `prototype/` is archival/sketch only, not a reference, spec, or test oracle. Drift audits are against `.squad/decisions.md` and Tesla directives, never against the prototype. Charter updated; see `.squad/agents/ralph/charter.md`.

### 2026-07-16T13:52:46.381-07:00 — Issue #51 queue refresh

- No merge request or remote #51 branch exists. Remote `main` remains `68371960f65911ad94c3c6a1040568fec1086c6d`; pipeline `2682301311` and `Build & Test` passed for that exact SHA.
- Issue #51 remains the sole runnable domain issue and must be resumed, not redispatched. Hopper owns its existing worktree; Tesla remains locked out by rejected commit `ae070e6`, and Curie remains reviewer-only.
- The unfinished candidate now spans the five issue-authorized files, including `app/fastlane/diagnostics_verifier.rb`. Its first canonical run executed 85/85 tests serially with no failures, skips, expected failures, or retry, but exited 1 on diagnostics classification. The issue now owns the exact environment-pinned verifier correction, two clean runs, Curie approval, and shipment.
- Open #1 is the tracker. #52, #57, #60, #62, and #66 remain follow-ups; #66 additionally declares dependency on open #62. GitLab link metadata contains no formal links, so descriptions are the dependency source.

### 2026-07-16T14:56:51-07:00 — Issue #51 publication gate

- Hopper's preserved five-file candidate completed two canonical runs with identical 85-test inventories (`bec00be1d36e76b30e664be11bde704e745c1dd9e372d59ce21900cd129e6ca3`) and no failure, retry, or skip markers.
- The candidate remains uncommitted at base `68371960f65911ad94c3c6a1040568fec1086c6d`; no remote issue branch or open MR exists. Hopper must publish this exact candidate next, without duplicate implementation, before Curie's independent review.
- Preserve root `main` at `3d1b464969f0e37ff0124dda7a3838d0d816eb5b` with six dirty Squad files, 34 stashes, six safety refs, the two closed-unmerged stray branches, legacy remotes, and ignored evidence/runtime records.

### 2026-07-16T15:32:50.977-07:00 — Read-only queue reconciliation

- Open board: #1 is the tracker; #51 is the sole runnable domain issue; #52, #57, #60, #62, and #66 are follow-ups. #66 remains blocked by open #62; #52's declared #65 dependency is closed.
- Hopper committed the clean five-file #51 candidate as `ea7ca64f2e72f3f0a55744cc3d7175db24854d38`, but it has no remote branch, MR, or exact-SHA pipeline. Hopper must push it and open the single issue-linked MR; Curie then reviews, and merge waits for that exact SHA's green pipeline.
- No other issue may run concurrently: the remaining file-disjoint candidates are excluded by their `follow-up` labels. No MR is open. Preserve 34 stashes, six safety refs, and stray closed-unmerged branches `ci-smoke-test`/!28 and `fix/asc-numeric-app-id`/!40.

### 2026-07-16T16:15:10-07:00 — MR !66 exact-SHA failure reconciliation

- GitLab has one open MR: !66 from `squad/51-restore-canonical-serial-ui-test-gate` at exact head `ea7ca64f2e72f3f0a55744cc3d7175db24854d38`. It is non-draft, conflict-free, discussion-free, and metadata-mergeable, but pipeline `2683184741` and exact-SHA `Build & Test` status failed; Curie's independent issue gate also remains unchecked. It is not immediately mergeable.
- The #51 worktree remains on that exact local/remote head but now has three uncommitted files: `AccessibilityAuditTests.swift`, `app/build.sh`, and `diagnostics_verifier.rb`. Preserve and resume this state on the same branch/MR before any fresh work; do not merge or dispatch another issue.
- Open board remains #1 tracker, #51 sole runnable domain work, and follow-ups #52, #57, #60, #62, #66. No formal GitLab issue links exist; description text says #52 is blocked by shipped #65 and #66 by shipped #65 plus open #62.
- Issues #59, #70, #82, #85, #88, #90, and #93–#97 are closed with merged MRs. Merged stash-source MRs are !12, !29, !36, and !45, but their residual stashes remain unattributed; preserve all 34 stashes and six safety refs. Preserve closed-unmerged `ci-smoke-test`/!28 and `fix/asc-numeric-app-id`/!40.

### 2026-07-16T17:52:29.681-07:00 — MR !66 current-head reconciliation

- MR !66 and its clean issue #51 worktree now agree with the remote branch at Hopper-authored `e387d2d758e23325d59277d3f6cf76d71169ea6d`; no implementation remains uncommitted.
- GitLab has no pipeline or commit status for exact current SHA `e387d2d7`. The MR's displayed head pipeline `2683264559` is stale and failed on superseded SHA `fd7d7af7`, so it is not merge evidence. Curie's independent issue gate remains unchecked.
- Keep the queue on issue #51 and the existing MR. Curie must independently rerun and approve the exact candidate; merge additionally requires a green exact-current-SHA status. Final review and all fresh work remain blocked.
- Open #1 is the tracker; #52, #57, #60, #62, and #66 are follow-ups. Description-only dependencies leave #52's #65 prerequisite shipped and #66 blocked by open #62; no formal issue links exist.
- Preserve root `main` five coordination commits ahead with six dirty Squad files, 34 unattributed stashes, seven safety refs, closed-unmerged local branches `ci-smoke-test`/!28 and `fix/asc-numeric-app-id`/!40, and legacy remotes. No local cleanup candidate is safely attributable and shipped.

### 2026-07-16T18:32:38.211-07:00 — MR !66 ownership and exact-head gate

- MR !66, its clean issue worktree, and the remote branch now agree at `1a2327f98bf9df19456255d6856c1c69a81d9ddf`. It is non-draft, conflict-free, discussion-free, and metadata-mergeable, but GitLab has no pipeline or commit status for that exact SHA; the displayed failed pipeline `2683337924` belongs to superseded `e387d2d7`.
- Canonical issue #51 records Curie's second rejection of `e387d2d7`, assigns the revision to Edison, and locks out Hopper. Edison then authored `4adaace`, but the current Hopper-authored `1a2327f` removes its 13-line accessibility-audit restoration. Preserve this ownership/acceptance ambiguity and do not merge or duplicate the work.
- The open board is unchanged: #1 tracker; #51 the sole runnable-but-in-progress domain issue through existing MR !66; #52, #57, #60, #62, and #66 follow-ups, with #66 description-blocked by open #62. Preserve 34 stashes, seven safety refs, root divergence, and closed-unmerged stray branches.

### 2026-07-16T18:32:38.211-07:00 — MR !66 exact-SHA CI timeout

- MR !66 is open at exact head `2021bac598de922ba67f812d1f1ec95b20d297ba`, non-draft, conflict-free, discussion-unblocked, and metadata-mergeable.
- Thirty minutes of polling found no pipeline, commit status, or job for that exact SHA. MR `head_pipeline` `2683421261` is superseded evidence: it failed on `1a2327f98bf9df19456255d6856c1c69a81d9ddf` and must be ignored.
- Issue #51's Curie independent-approval checkbox remains unchecked. MR !66 is not ready: exact-SHA CI is absent and Curie approval is outstanding.
