# Active Decisions

## 2026-07-15T00:51:39.795-07:00 — User directive

### 2026-07-15T00:51:39.795-07:00: User directive (consolidated)
**By:** Tesla (Squad) (via Copilot)
**What:** Run the complete Squad Work Loop autonomously. Use `gpt-5.6-sol` for every launched member, including Ralph and Scribe. Keep Ponytail full active: choose the smallest correct native or standard-library implementation without skipping explicit acceptance criteria, validation, security, accessibility, error handling, tests, warnings-as-errors, exact-commit CI, or the one-domain-issue/one-MR contract. Preserve unrelated working-tree changes and stop only when all five stated goals and final review are complete, or when a genuine external blocker remains after safe alternatives are exhausted. Do not fake unavailable remote actions.
**Why:** User request — captured for team memory

---

## 2026-07-14T23:38:12.955-07:00 — Tesla issue #65 before-work design gate

# Issue #65 Before-Work Design Gate

**Date:** 2026-07-14T23:38:12.955-07:00  
**Owner:** Tesla  
**Status:** Approved for implementation under this contract

## Authority and scope

- Issue #65 is the product contract. `.squad/decisions.md` remains the formula authority.
- The current instruction temporarily authorizes comparison with `prototype/index.html` for this review. It does not restore prototype parity: the prototype's hero tiles, live fallback calculation, optional defaults, privacy card, local storage, and share-link behavior are not requirements.
- Preserve the established formulas: stitch width `pattern/your`, cast-on multiplier `your/pattern`, row density `your/pattern`, dimension correction `pattern/your`, section rows `round((cm / 10) × yourRows)`, and shaping interval `patternInterval × row density`.
- No new abstraction or dependency. Keep the change native Swift/SwiftUI and in existing files.

## Execution order and ownership

All agents use `gpt-5.6-sol`.

### Edison — production implementation

May modify only:

- `app/KnittingGaugeReconciler/ContentView.swift`
- `app/KnittingGaugeReconciler/ContentViewHelpers.swift`
- `app/KnittingGaugeReconciler/GaugeMath.swift`
- `app/KnittingGaugeReconciler/Views/GaugeInputsCard.swift`
- `app/KnittingGaugeReconciler/Components/GaugeStepperField.swift`

Must not modify tests, the prototype, `project.pbxproj`, or create files.

Implementation contract:

1. Keep raw text as the source of truth. A single field/range validator must be the only route from raw text to typed `GaugeInputs`; validate finite values and bounds before rounding or integer conversion. No validation fallback or silent clamping.
2. Required gauge fields use `1...99`. Optional cast-on uses `40...400`; lengths use `5...100` canonical centimetres; shaping uses `1...30`. Blank optional text means absent. Keyboard, paste, wheel, restoration, and calculation use the same validator.
3. Keep only the four required sample defaults. Optional defaults are blank. Four valid required values must produce Gauge Summary without inventing cast-on, length, shaping, result, or export sections.
4. Show the exact lead sentence from issue #65, one gauge surface with a 24-point break between pattern and swatch, and an initially collapsed `Pattern details (optional)` disclosure.
5. Use `@SceneStorage` for all raw fields and disclosure state. Keep the existing global unit preference; draft values remain scene-local. Restore partial/invalid text exactly.
6. `View results` is disabled while invalid. Submission exposes field-specific inline errors, announces them accessibly, and focuses the first invalid field. Invalid input must never compute or leave a stale result visible.
7. Reset uses the exact issue copy, records the entire raw draft plus disclosure state for Undo, restores four samples, clears optionals/stale scene state, and preserves existing reset metrics. Undo restores that snapshot exactly.
8. Preserve accessibility identifiers where controls survive, Dynamic Type behavior, 44-point controls, MetricKit signposts, unit conversion semantics, and share fallback behavior.

Because the Xcode project uses a manual source manifest, the no-new-file rule also avoids an unnecessary `project.pbxproj` collision. If compilation proves an unlisted dependent view must change to represent absent optionals, Edison must return that dependency to Tesla for a scope gate rather than spreading the diff.

### Curie — tests after Edison freezes the source API

May modify only:

- `app/KnittingGaugeReconcilerTests/GaugeMathTests.swift`
- `app/KnittingGaugeReconcilerUITests/KnittingGaugeReconcilerUITests.swift`
- `app/KnittingGaugeReconcilerUITests/AccessibilityAuditTests.swift`

Must not modify production code, prototype files, build scripts, or the project.

Required coverage:

- One table-driven validator matrix for every field class: empty, whitespace, zero, negative, decimal, both bounds, oversized, scientific notation, `nan`, and infinity.
- Optional-output matrix: none, cast-on only, one length only, shaping only, and all fields, including screen and share/export absence checks.
- UI validation round trip: raw invalid text remains, specific error is exposed, first invalid field receives focus, results are blocked, and correction re-enables them.
- Reset/Undo restores every raw value and disclosure state.
- Scene restoration covers valid, invalid, partial, reset, and independent multiple-scene drafts.
- Existing formula scenarios stay green and derive expected values from `.squad/decisions.md`, not prototype behavior.

### Ive — read-only UX/accessibility gate

Touches no files. Review the candidate against issue #65 and, as explicitly authorized for this session, compare `prototype/index.html` only for the useful single-surface gauge grouping. Reject prototype behaviors that conflict with issue #65 or current app decisions.

Approve only if hierarchy, exact copy, 24-point grouping, collapsed optional disclosure, blank-optionals behavior, inline correction, focus order, VoiceOver announcements, Dynamic Type reflow, contrast, and reset/Undo discoverability are coherent.

### Jacquard then Mendel — sequential final read-only gates

Neither reviewer touches files. Jacquard first verifies formula direction, rounding, canonical-centimetre handling, and that absence cannot enter arithmetic. Mendel then verifies the complete acceptance and scenario matrix, warning-free evidence, and that no irrelevant UI/export section is emitted. This is sequential, not the retired prototype-parity sweep.

## Dependencies, overlap, and rejection rules

- Edison owns all source/API edits; Curie starts edits only after that API is frozen. Both contributions land in one issue MR so tests cannot lag the API.
- Ive reviews only after Curie's focused tests pass. Jacquard and Mendel review only after Ive approval.
- Prototype and formula files are read-only comparison inputs.
- Any reviewer rejection locks the rejected artifact's author out of the next revision. The coordinator must assign a different revision owner; the reviewer does not implement the fix.

## Exit checks

- Every issue #65 acceptance criterion and regression guardrail has a named passing test or reviewer observation.
- `./app/build.sh test` exits successfully with zero SwiftLint violations and zero compiler warnings.
- No unchecked `Double`-to-`Int` path remains reachable from raw input.
- Formula scenarios match `.squad/decisions.md`; prototype differences are documented as intentional rather than copied.
- Diff is confined to the files assigned above; no new dependency, file, project change, prototype edit, commit, or push.

---

### 2026-07-15T05:42:35.191-07:00: User directive
**By:** Tesla (Squad) (via Copilot)
**What:** Execute the Squad Work Loop end-to-end with ponytail full mode; use gpt-5.6-sol for every Squad member or subagent, including Ralph and Scribe; preserve user changes; complete local implementation and validation even if remote actions are blocked; do not claim remote success without evidence.
**Why:** User request — captured for team memory

---

### 2026-07-15T13:58:22.271-07:00: User directive
**By:** Tesla (Squad) (via Copilot)
**What:** Execute the complete Squad Work Loop autonomously; use `gpt-5.6-sol` for every member including Ralph and Scribe; keep Ponytail full active; preserve ambiguous or unrelated state; require one coherent issue per MR, warning-free local tests, exact-pushed-SHA green CI, merge and safe cleanup, then parallel final reviews until all five goals pass or unavailable human input truly blocks progress.
**Why:** User request — captured for team memory

---

# APPROVED — Goal 2 final UX sign-off

**Date:** 2026-07-15T14:38:21.113-07:00
**Owner:** Ive
**Goal:** 2
**Review mode:** Source-and-test evidence; no simulator or build launched.

## Verdict

**APPROVED.** No user-facing or accessibility defect was found. Shipped commit
`1608bcc5b2cba824b54a600c6a7590a8ed681c19` contains issue #65 exact commit
`99fd75d096daf74de1edd272bf24325f732f9920`; all authorized production and UI-test
paths are clean.

## Evidence

- **Core task and hierarchy:** `ContentView.swift:125-179` presents the exact issue lead, then one gauge surface,
  optional pattern details, and the results/reset actions. `GaugeInputsCard.swift:45-59` keeps Pattern Gauge and
  Swatch Gauge together with the required 24-point group break.
- **Four required inputs:** `GaugeInputsCard.swift:99-155` exposes stitches and rows for pattern and swatch.
  `ContentView.swift:76-99` requires all four while permitting blank optionals. Required-only results are guarded by
  `AccessibilityAuditTests.swift:219-228`.
- **Hero outputs:** The prototype's always-live main-screen heroes are intentionally replaced by an on-demand native
  results sheet, consistent with the authoritative main-screen task-execution decision. The sheet retains both hero
  meanings as “Stitch-wise width” and “Row-wise density” in
  `RequiredAdjustmentsCard.swift:281-298,390-428`, with text labels and VoiceOver labels rather than color-only status.
- **Adjustment table:** The prototype's always-populated rows are intentionally replaced by conditional adjustment
  cards. `RequiredAdjustmentsCard.swift:180-239` emits only supplied yoke, body/sleeve, shaping, and cast-on guidance;
  `KnittingGaugeReconcilerUITests.swift:386-445` covers none, each representative optional class, and all optionals.
- **Labels, roles, state, and focus:** Fields expose label, value, hint, mismatch, and error
  (`GaugeStepperField.swift:105-131,179-249`). Native `Button`, `TextField`, `Picker`, `DisclosureGroup`, `Alert`, and
  sheets preserve platform roles and states. Submission expands hidden invalid optionals, focuses the first invalid
  field, and announces its exact correction (`ContentView.swift:437-449`); the correction round trip is guarded by
  `KnittingGaugeReconcilerUITests.swift:447-495`.
- **Errors and contrast semantics:** Invalid values remain raw, receive wrapped inline text, an accessibility value,
  and a correction hint; results remain disabled (`GaugeStepperField.swift:105-123,242-250`;
  `RequiredAdjustmentsCard.swift:46-88`). Mismatch and invalid styling is never the sole signal. The lead uses
  `AppTheme.ink` on an opaque `AppTheme.background` surface (`ContentView.swift:125-137`).
- **Target sizes and HIG:** Primary result, reset, Undo, disclosure, field, picker, and Close controls provide 44-point
  minimum targets. Optional details use native disclosure and segmented picker; results, wheel selection, reset
  confirmation, and sharing use native sheets, picker, alert, and activity controller.
- **Dynamic Type:** No text-size cap or `minimumScaleFactor` exists in the reviewed SwiftUI source. Input grids and
  result pairs stack at accessibility sizes (`GaugeInputsCard.swift:61-97`;
  `GaugeMeasurementPair.swift:12-31`), long text wraps, and the AX5 input-stack behavior is guarded by
  `KnittingGaugeReconcilerUITests.swift:210-233`.
- **Keyboard, paste, and wheel parity:** The native `UITextField` accepts direct entry and paste into the raw binding
  (`GaugeStepperField.swift:312-344,383-401`). Calculation validates through `GaugeMath.validate`
  (`ContentView.swift:381-385`), and wheel initialization uses the same validator
  (`GaugeStepperField.swift:443-451`) before bounded selection.
- **Reset and Undo:** Exact confirmation copy appears in `RequiredAdjustmentsCard.swift:90-135`; the full raw draft
  and disclosure state are snapshotted, reset, and restored in `ContentView.swift:605-652`. The complete user flow is
  guarded by `KnittingGaugeReconcilerUITests.swift:497-571`.
- **Optional disclosures:** `PatternInstructionsCard.swift:44-71` uses a collapsed native disclosure with an explicit
  optional label and state-bound content. Full math remains a secondary disclosure inside results
  (`RequiredAdjustmentsCard.swift:325-357`).
- **Canonical evidence:** Issue #65 records every acceptance item complete, exact-commit verification, zero SwiftLint
  violations, and a passing canonical test gate. Current decisions additionally record the final accessibility,
  focus, restoration, and warning-free approvals.

## Intentional prototype differences

The archival prototype's live fallback calculation, always-visible hero/verdict block, populated optional rows,
privacy card, browser storage, and share-link behavior conflict with current canonical decisions and are correctly
absent. Native controls and the smaller required-first surface are positive, not parity defects.

## Regression guardrail

Retain the existing accessibility audits, AX5 stacking test, optional-output matrix, validation/focus round trip, and
Reset/Undo round trip. No revision owner is required because the verdict is approved.

---

# Post-#65 queue and cleanup classification

**Recorded:** 2026-07-15T13:58:22.271-07:00

GitLab confirms MR !46 merged exact SHA `99fd75d096daf74de1edd272bf24325f732f9920` with a successful exact-SHA pipeline and issue #65 closed. No merge request is open.

## Removed because GitLab proves shipped

- Clean detached worktree `~/.copilot/session-state/dba12446-c72d-4542-8b74-70fb4af58ee8/files/issue65-commit-worktree`; its `dc1a8fa` commit is included in merged !46.
- Local branches `fix/24-followup-sheet-identifiers`, `fix/40-reset-confirmation-lift-v2`, `fix/a11y-audit-offscreen-filter`, `fix/ci-shared-scheme`, and `squad/20260714-work-loop`; their tips are the merged MR source tips.
- Local branches `squad/48-49-gauge-display-fixes`, `squad/50-unit-toggle-phase1`, and `squad/dynamic-type-elastic-layout`; their tips are ancestors of merged MR !44's source.

Each cleanup used forced worktree removal where applicable, forced local branch deletion where applicable, and worktree pruning.

## Preserved live or ambiguous state

- Current worktree on `squad/65-harden-form-state` at merged SHA `99fd75d` is dirty: 13 tracked Squad-state paths, `ContentView.swift`, `AccessibilityAuditTests.swift`, plus untracked `.scratch-ada-xcresult/`, `.squad/agents/babbage/`, and `.squad/agents/turing/`.
- Detached worktree `/Users/yashasgujjar/dev/knitting-gauge-reconciler-issue65-turing` at `99fd75d` is dirty in `ContentView.swift`, `AccessibilityAuditTests.swift`, and `KnittingGaugeReconcilerUITests.swift`.
- All 70 stashes, `stash@{0}` through `stash@{69}`. None has an exact payload snapshot matching shipped `origin/main`; 60 also contain untracked payloads. Their bases being shipped is insufficient proof.
- Ambiguous local branches: `ci-smoke-test` (closed, unmerged !28), `fix/38-about-sheet-decorative-rectangle-hidden` (closed, unmerged !25), `fix/asc-numeric-app-id` (closed, unmerged !40), `fix/24-navstack-in-sheet` and `fix/cast-on-result-a11y-identifier` (local tips continue beyond their merged MR source), and `fix/cast-on-result-a11y-identifier-v2` and `squad/consolidated-release` (no proof their local tips shipped).
- Retain `main` and the dirty current `squad/65-harden-form-state` branch.

No Git notes or inbox records represented additional loop-preserved work before this decision.

## Exact open queue

Open issues are #1, #9, #51, #52, #57, #59, #60, #62, #66, #70, and #77–#80. #1 is the project brief, #9 is the metrics tracker, and every domain/final-review issue is labeled `follow-up`.

Under the loop contract, no domain issue is currently runnable while that label remains. #62 is the dependency-frontier candidate to promote next; #66 waits on #62, #70 waits on #66, and final review #77–#80 remains blocked.

---

### 2026-07-15T14:58:16.016-07:00: User directive
**By:** Tesla (Squad) (via Copilot)
**What:** Use gpt-5.6-sol for every agent launched in this session, including Ralph and Scribe; run the entire Knitting Gauge Reconciler Squad Work Loop autonomously with Ponytail full mode.
**Why:** User request — captured for team memory

---

### 2026-07-15T16:38:18.613-07:00: User directive
**By:** Tesla (Squad) (via Copilot)
**What:** Run the complete autonomous Knitting Gauge Reconciler work loop until all five stated goals pass or unavailable human input is the concrete blocker. Use gpt-5.6-sol for every agent, including Ralph and Scribe. Keep Ponytail full active: prefer the smallest native/stdlib solution without skipping explicit requirements, validation, error handling, security, accessibility, tests, GitLab exact-SHA CI gates, merge/cleanup, or persistent logging.
**Why:** User request — captured for team memory

---

### 2026-07-15T19:00:03.336-07:00: User directive
**By:** Tesla (Squad) (via Copilot)
**What:** For issue #82, use gpt-5.6-sol for every Squad sub-agent, including Ralph and Scribe. Shannon is locked out completely: do not launch, consult, cite, pair with, or use Shannon for this revision. Keep one coherent existing MR !47, rewrite canonical issue/MR descriptions instead of posting status comments, and preserve unrelated or ambiguous state.
**Why:** User request — captured for team memory

---

### 2026-07-15T19:20:37.221-07:00: User directive
**By:** Tesla (Squad) (via Copilot)
**What:** Run the complete Squad Work Loop end-to-end in PONYTAIL full mode; every launched Squad member, including Ralph and Scribe, must use gpt-5.6-sol; preserve ambiguous or unshipped work; only remove GitLab-confirmed shipped stale state; finish implementation, validation, reviews, GitLab lifecycle, cleanup, and five-goal evaluation.
**Why:** User request — captured for team memory

---

### 2026-07-15T19:41:14.088-07:00: User directive
**By:** Tesla (Squad) (via Copilot)
**What:** Execute the complete Squad Work Loop autonomously: reconcile unfinished local and GitLab state first, then finish one coherent highest-priority runnable domain issue per branch/MR through warning-free tests, exact-commit green CI, merge, safe cleanup, five-goal re-evaluation, and continued looping. Use `gpt-5.6-sol` for every launched member or subagent, keep Ponytail full active, preserve ambiguous or unshipped state, do not add issue status comments, and defer final review until runnable domain work is empty.
**Why:** User request — captured for team memory

---

### 2026-07-15T20:21:35.561-07:00: User directive
**By:** Tesla (Squad) (via Copilot)
**What:** Run the complete Knitting Gauge Reconciler iOS Squad Work Loop autonomously. Ponytail full is active: use the minimum correct implementation without dropping explicit validation, accessibility, error handling, warning-free builds, GitLab workflow, or signoffs. Resume and preserve unfinished or ambiguous state; clean only work GitLab proves shipped; finish ready MRs before selecting one highest-priority runnable domain issue; keep one coherent issue per MR; require `./app/build.sh test` with zero warnings; commit with the specified Copilot co-author trailer; gate merge on the exact pushed SHA pipeline; loop on drift by creating non-duplicate domain issues; and complete simultaneous ownership reviews only after domain issues and MRs are clear. Every spawned member, including Ralph and Scribe, must use `gpt-5.6-sol`. Do not modify unrelated user changes. Persist until all five stated exit goals pass or genuine unavailable human input blocks progress.
**Why:** User request — captured for team memory


---

### 2026-07-16T01:53:30.891-07:00: Complete exported diagnostics is a real Goal #5 gap

**Date:** 2026-07-16T01:53:30.891-07:00
**By:** Tesla
**Classification:** Real remaining false-green gap

Shipped issue #89 / MR !56 scans the raw xcodebuild log and exported files named `StandardOutputAndStandardError.txt`. The observed diagnostics export has four regular files; unscanned `testmanagerd.log`, session, and scheduling logs contain 1,333 additional lines. A prohibited runtime diagnostic present only there can therefore return green, contrary to the explicit zero-diagnostic Goal #5 contract.

Local-only commit `b8f1930` broadens plugin, `fopen`, and fallback matching, enumerates every exported regular file (including dot paths), safely decodes binary input, and reports matching path/line details. Its `app/build.sh` matcher is aligned with that contract. These are recovery semantics, not approved code.

GitLab issue #90, **Hopper — Goal #5: scan every exported test diagnostic**, is the sole open owner. It depends on shipped #89 and requires a minimal synthetic false-green self-check plus the canonical gate. Hopper must revise independently from current `origin/main`.

Trade-off: scanning all exported diagnostics may expose more Xcode noise, but silently omitting diagnostic sources violates the contract. Do not weaken the gate; constrain only demonstrably benign matches.

Preserve `b8f1930`, its local branch/worktree, all 32 stashes now present (31 at triage intake plus one concurrent stash), and all five safety refs for human disposition.
# Process-Restoration UI Coverage Prohibition

**Date:** 2026-07-15T19:12:58.363-07:00
**Owner:** Tesla
**Verdict:** Canonical superseding decision

- Never add or reintroduce `testSceneRestorationPreservesValidInvalidPartialAndResetDraftsAcrossProcessInterruption`,
  or an equivalent process-interruption/process-relaunch XCUITest.
- Scene persistence, restoration, and reset coverage must use deterministic unit/static tests at the existing
  `SceneDraftStore`/snapshot/serialization seam.
- Do not add replacement UI/process automation or test-only production reset/handoff hooks.
- This supersedes every earlier decision, issue criterion, merge-request claim, or guardrail requiring protected
  process-restoration UI coverage.
- Contrast and unrelated stable UI/accessibility assertions remain in force.

---

# Temporary UI Test Execution Prohibition

**Date:** 2026-07-15T21:34:56.578-07:00
**Owner:** User
**Verdict:** Canonical superseding decision

- The user decided that no UI tests or XCUITests run until the implementation issue queue is clear.
- During this temporary period, do not add, restore, fix, invoke, require, or gate issues, merge requests, or CI on
  `KnittingGaugeReconcilerUITests`, `AccessibilityAuditTests`, or any UI-test equivalent.
- Keep UI test source files intact except for prior explicit deletions; disable execution through the shared scheme.
- Use deterministic unit, static, compile, and SwiftLint guardrails instead. Accessibility production requirements
  remain mandatory and are reviewed through deterministic, static, and manual checks while UI tests are disabled.
- This temporarily supersedes all prior decisions, issue acceptance criteria, merge-request claims, and guardrails
  requiring UI tests.
- Re-enable UI tests only after the issue queue is clear and the user explicitly approves re-enabling. Revert by
  changing the shared scheme value back to `skipped = "NO"`.

---

### 2026-07-16T19:21:32.147-07:00: Canonical user directive — Test scope authority
**By:** User (via Tesla)
**What:**
- Only a direct user directive may enable or disable a test suite or determine the mandatory test inventory.
- Agent charters, reviewer verdicts or rejections, issue or merge-request rewrites, general authorization to run the loop, final-review goals, and inferred coverage requirements may never expand or override user-set test scope.
- UI tests and XCUITests remain disabled. Clearing the implementation queue is necessary but is not approval; re-enabling them requires a newer explicit user approval even when the queue is empty.
- Before assigning or running test work, read the active user-owned test-scope decision in full. If it is absent, unreadable, truncated, conflicting, or ambiguous, stop, fail closed, and ask the user. Never run tests outside the last explicit scope.
- Reviewers may report an out-of-scope coverage gap as advisory, but may not activate or rewrite issues, alter labels, re-enable targets, reject an authorized artifact, or invoke reviewer lockout to expand test scope.
- Curie executes and reviews only the test scope assigned by direct user decisions and `loop.md`; Curie's charter does not decide mandatory suites or test inventory. Curie cannot reject because an explicitly disabled or out-of-scope suite did not run, re-enable it, or rewrite issues, merge requests, or labels to expand scope. Curie may report the gap as advisory only.
- Direct user test-scope decisions outrank reviewer rejection and lockout protocol.
**Supersedes:** Every prior decision, review, issue, or merge-request claim that allowed Curie, Tesla, Ralph, Hopper, final review, or reviewer lockout to decide or expand test execution scope.
**Why:** Test execution scope belongs only to direct user decisions and the active loop contract. This authority boundary preserves the existing Temporary UI Test Execution Prohibition unchanged.
