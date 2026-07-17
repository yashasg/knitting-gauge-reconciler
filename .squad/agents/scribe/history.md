# Scribe — History

## Core Context

- **Project:** A knitting gauge reconciler that converts patterns between stitch/row gauges.
- **Role:** Session Logger
- **Joined:** 2026-05-19T07:11:08.647Z

## Learnings

<!-- Append learnings below -->

### 2026-05-19 — corrected canonical Xcode project path

Record future session logs with `app/KnittingGaugeReconciler.xcodeproj` as the canonical Xcode project path. The earlier `app/app.xcodeproj` broadcast is superseded; scheme remains `KnittingGaugeReconciler`.

### 2026-05-22T02:50:32Z — Adjustment sheet session closeout

Merged four inbox decisions into `decisions.md`, wrote orchestration/session logs for the adjustment-sheet work, summarized Ive history into an archive, and prepared the shipped SwiftUI pull-up-sheet changes for commit.

### 2026-05-22T10:36:24Z — Decision inbox sweep + orchestration log

- **Inbox cleared:** 7 files processed (copilot-directive, app-icon-setup, icon-transparency, identifier-name-fix, line-length-fix, new-icon, typography-fix).
- **Decisions merged:** All 7 entries appended to `decisions.md` (now 54,816 bytes after merge; no archiving required).
- **Orchestration log:** `.squad/orchestration-log/2026-05-22T10:36:24Z-edison.md` created to capture edison-13 Pattern Instructions typography fix (commit 2e4f8b9, issue #31 closed).
- **Session log:** `.squad/log/2026-05-22T10:36:24Z-typography-fix.md` written.
- **Archive gate:** No decisions older than 7 days; no history files >= 15KB requiring summarization.

### 2026-05-23T10:06Z — ASC Auth File Fallback Session Closure

**Session:** Closed spawned agents hopper-11 and tesla-5  
**Work:** Fixed GitHub Actions CD workflow step-level env scoping issue

- **Inbox processed:** hopper-asc-auth-file-fallback.md merged to decisions.md
- **Orchestration log:** Created 2026-05-23T1006Z-hopper-11.md and 2026-05-23T1006Z-tesla-5.md
- **Session log:** Wrote 2026-05-23T1006Z-asc-auth-file-fallback.md documenting the env-scoping gotcha and file-fallback solution
- **Agent histories:** Appended hopper-11 and tesla-5 entries to respective history.md files
- **Commits:** fbd5fd0 (hopper fix) and e786f37 (tesla merge)
- **Archive gate:** 1 inbox decision processed; no backlog

**Lesson:** CD workflow step-level env vars require fallback to stable on-disk artifacts when those artifacts persist between steps. GitHub Actions env isolation is by design; Fastlane's dual-source auth strategy (env + file) is the right answer.

### 2026-07-15T00:51:39.795-07:00 — Issue #65 selection gate recorded

- Consolidated the repeated Work Loop directive and cleared its inbox file.
- Logged Tesla's selection of GitLab issue #65 and the Edison → Curie → Ive → Jacquard → Mendel → final Curie gate order.
- No decision archival, cross-agent propagation, or history summarization was required.

### 2026-07-15T14:58:16.016-07:00 — Issue #82 exact-SHA gate recorded

- Merged three current inbox records and logged Curie, Tesla, and Coordinator outcomes.
- Recorded Curie's 77/77 exact-SHA local pass and MR !47 as awaiting exact-SHA CI and reviewer gates.
- The decisions archive hard gate found no entries older than seven days; Tesla history crossed 15 KB and was summarized.

### 2026-07-15T14:58:16.016-07:00 — Issue #82 failure routing recorded

- Merged Hopper's exact-SHA CI failure and Tesla's retrospective decision; inbox cleared.
- Recorded #59 as Hopper's top runnable dependency and #82 as an Edison-owned later revision, with Shannon locked out and MR !47 preserved unchanged.
- Active decisions exceeded the hard-gate ceilings, but no entry was older than seven days; all active histories remained below 15 KB.

### 2026-07-15T14:58:16.016-07:00 — Issue #59 shipment recorded

- Merged Hopper's canonical exact-SHA CI record and cleared the decision inbox.
- Logged MR !48 shipment at source `f37cf5f` and merge `7f36b34`, with local, GitHub, and GitLab gates green.
- Routed the next focus to evaluation of open #83 / MR !49, then Edison's #82 / MR !47 revision; neither open follow-up was marked complete.
- The decisions archive hard gate found no eligible entry older than seven days; all active histories remained below 15 KB.

### 2026-07-16T02:37:00.354-07:00 — Final sign-off session: Tesla gate closure

- **Inbox processed:** 1 file merged (`tesla-goal-5-complete-diagnostic-scan.md`).
- **Decisions updated:** Appended Goal #5 gap analysis and final review verdict to decisions.md (now 77,568 bytes).
- **Archive gate:** No entries older than 7 days; no history summarization required.
- **Orchestration log:** Created `2026-07-16T02:37:00.354-07:00-tesla-final-review.md`.
- **Session log:** Created `2026-07-16T02:37:00.354-07:00-scribe-final-sign-off.md`.
- **Verdict:** Tesla's sync final review: PASS on all five exit goals. Overall: PASS.
- **Next:** Issue #90 (Hopper) is sole open work; depends on shipped #89.

### 2026-07-16T10:52:38.873-07:00 — Ralph reconciliation recorded

- Consolidated six inbox files into three canonical decisions and cleared the inbox.
- Logged Ralph's empty runnable queue, exact-main pipeline pass, and preservation boundary.
- Recorded a final-review handoff only; no final approval was claimed.
- No decision entry qualified for seven-day archival, and no history crossed 15,360 bytes.

### 2026-07-16T11:12:49.308-07:00 — Issue #51 runnable-queue correction recorded

- Recorded Tesla's and Ralph's reconciliation: #51 is open and runnable under explicit user authorization.
- Superseded the stale empty-queue/final-review handoff and routed independent revision ownership to Hopper.
- Preserved local main `cd42034`, all ambiguous state, and the already-dirty Ada/Jacquard/Ralph histories.
- Inbox was empty; no decision archival or history summarization was eligible.

### 2026-07-16T16:12:48.298-07:00 — Reconciliation recorded

- Merged two user directives and logged Tesla's local audit plus Ralph's GitLab audit.
- Preserved issue #51 for resumption and all unrelated ambiguous state.
- No decision was old enough to archive, and no history crossed 15,360 bytes.

### 2026-07-16T16:32:43.998-07:00 — Issue #51 unfinished state recorded

- Merged two unique inbox records and cleared the inbox.
- Logged Tesla's finding that MR !66 at `ea7ca64` has failed checks, lacks Curie approval, and has three later modified files preserved for Hopper.
- The active ledger exceeded both archive thresholds, but no decision predates the seven-day cutoff; no history reached 15,360 bytes.
- No fresh work, cleanup, or issue-worktree code change was performed.

### 2026-07-16T21:04:14.155-07:00 — Unit-only authority restored

- Restored the canonical formula and six-scenario sections from commit `93323af` without restoring unrelated historical content.
- Consolidated three inbox records under the latest unit-only directive and cleared the inbox.
- Recorded MR !66 as closed/unmerged/failed, issue #51 as user-blocked with obsolete UI scope, and Turing as eligible only for a real unit-only tooling drift issue.
- No decision qualified for seven-day archival and no history crossed 15,360 bytes. No tests, product files, GitLab mutation, commit, or push occurred.

### 2026-07-17T01:44:15.855-07:00 — Issue #114 reconciliation recorded

- Consolidated two unique inbox records and cleared the inbox while preserving
  the direct user directive as controlling authority.
- Logged Tesla's local audit and Ralph's GitLab inventory for issue #114/MR !82
  at `ffdfa5d2`, pending exact-head CI.
- No decision was old enough for the applicable archive gate. Tesla's history
  crossed 15,360 bytes and was summarized.
- No application code, test, GitLab state, or ambiguous saved state was changed.
