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
