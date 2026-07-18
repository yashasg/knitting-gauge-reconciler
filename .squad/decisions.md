# Active Decisions

## 2026-07-15T00:51:39.795-07:00 — User directive

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

### 2026-07-17T00:44:14.771-07:00: User directive
**By:** Tesla (Squad) (via Copilot)
**What:** Execute the full reconciliation-to-merge Squad Work Loop using gpt-5.6-sol for every agent. UI tests and XCUITests are disabled; only non-UI tests invoked by `./app/build.sh test` are permitted, with warnings treated as failures. Preserve ambiguous work, avoid duplicate issue work, require exact-SHA green GitLab pipelines, and continue until all five stated goals pass or a true external blocker remains.
**Why:** User request — captured for team memory

### 2026-07-17T01:04:07.651-07:00: User directive
**By:** Tesla (Squad) (via Copilot)
**What:** Execute the autonomous GitLab Squad Work Loop through shipment and all five goals. Use Ponytail full and gpt-5.6-sol for every Squad agent. UI tests and XCUITests are disabled and must not be created, enabled, assigned, built, or run; only existing Swift unit tests covering the six Jacquard scenarios plus relevant math edges and `./app/build.sh test` on an iPhone simulator with warnings as errors are authorized. Preserve unrelated or ambiguous work, finish ready MRs first, require one coherent domain issue/MR and exact-head green CI, then merge and safely clean shipped state.
**Why:** User request — captured for team memory

### 2026-07-17T01:24:16.220-07:00: User directive
**By:** Tesla (Squad) (via Copilot)
**What:** Execute the complete Squad Work Loop reconciliation-first through one shipped domain issue (or all five goals, or genuine human-input block). Unit tests and `./app/build.sh test` are authorized and required. UI tests and XCUITests are disabled: never assign, create, enable, run, inventory, or use them as blockers; reviewers may only give non-blocking advisory coverage notes. Use `gpt-5.6-sol` for every launched member, including Ralph and Scribe. Keep changes minimal, preserve unrelated or ambiguous state, create/update exactly one MR for the issue, require exact-SHA green CI, merge, clean only shipped state, then re-evaluate goals.
**Why:** User request — captured for team memory

# Curie — Goals #1 and #5 final gate

**Date:** 2026-07-17T01:24:16.220-07:00
**Exact SHA:** `99f13d0dd0c84281b42a9a5565428b25abed084c`

- Static scheme inspection and the emitted xcodebuild command proved unit-only selection: `-only-testing:KnittingGaugeReconcilerTests`; no UI/XCUITest target was built or run.
- `./app/build.sh test` exited 0 with 74/74 tests passing, 0 failed/skipped/expected failures, retries, crashes, warnings, or SwiftLint violations.
- Simulator: iPhone 17 Pro, iOS 26.5, UDID `11CCFC00-6C86-434E-B022-0957C4A67EB0`.
- The xcresult includes all six canonical gauge scenarios and issue #112's exact-whole-inch regression.

`GOAL 1: PASS`
`GOAL 5: PASS`

# Jacquard — Goal #4 final signoff

- **Date:** 2026-07-17T01:24:16.220-07:00
- **Reviewed SHA:** `99f13d0dd0c84281b42a9a5565428b25abed084c`
- **Verdict:** `GOAL 4: PASS`
- **Finding:** The six canonical scenarios, gauge directions, practical integer rounding, percentage signs,
  validation boundaries, and exact `2.54` cm/in conversion agree. Issue #112 preserves `8 in` as
  `20.32 cm` and displays it back as `8 in`.

# Issue #112 canonical handoff

**Date:** 2026-07-17T01:04:07.651-07:00
**Owner:** Ada production; Curie authorized unit coverage and gate

- `main`/`origin/main`: `e3cf651033cdc47912a42d2bf5e51cc6171917b3`,
  with green exact pipeline `2684064872`.
- MRs !78, !80, and !79 shipped #109, #110, and distinct follow-up #111 at
  exact green heads `03516ea`, `50120ab`, and `6ed86eb`. No older MR is ready.
- #112 is the sole runnable domain issue. Its rewritten canonical description
  records no dependency, one issue/branch/MR, exact allowed scope, authorized
  unit-only commands, reviewer gates, and exact-head CI requirement.
- Local branch, remote branch, and MR !81 agree at
  `698cdaa1cf8de251753a688eada1a52a70460b1b`, based on `e3cf6510`. Worktree
  `/Users/yashasgujjar/dev/knitting-gauge-reconciler-112` has a later
  uncommitted two-file revision; preserve it for Ada and do not clean, reset,
  overwrite, or duplicate it.
- Allowed files are only
  `app/KnittingGaugeReconciler/MeasurementUnit.swift` and
  `app/KnittingGaugeReconcilerTests/GaugeMathTests.swift`.
- Allowed commands are only `git diff --check` and, after static unit-only
  selection proof, Curie's `./app/build.sh test`. UI/XCUITests must not be
  created, edited, enabled, assigned, built, run, required, or gated.
- Acceptance requires exact 2.54 conversion, `8 in` matching-gauge
  result/export identity, unchanged integer/range/overflow/toggle/cm behavior,
  all six canonical scenarios and relevant edges, Ada approval, Jacquard formula
  sign-off, Mendel mapping, Curie's warning-free gate, and green GitLab CI for
  MR !81's exact current SHA.
- MR !81 is conflict-free but has no exact-head pipeline, the worktree has
  uncommitted post-head work, and no attributable Curie/Mendel publication
  evidence exists. Do not merge or start final review.
- Preserve root Squad changes, dirty shipped #109 identity state, divergent
  prohibited #51 UI-test state, 34 ambiguous stashes, 11 safety refs, ignored
  logs/scratch, and closed-unmerged stray branches. No cleanup is authorized.

# MR !79 obsolete; resume MR !80

**Date:** 2026-07-17T00:44:14.771-07:00
**Owner:** Tesla

- MR !78 shipped issue #109 from `03516ea` and merged as `d9de26e`.
- MR !79's `689023a` is a later child of `03516ea`. Its two workflow paths are not in `main`, but !79 is obsolete as a second MR claiming the already-closed #109. Close the MR; retain its branch and dirty worktree.
- MR !80 is the sole valid unshipped issue #110 candidate. `50120ab` is based directly on `d9de26e` and changes only `.github/workflows/cd.yml` by adding `include-hidden-files: true` to failure diagnostics.
- Do not merge !80 until its exact current SHA has a green pipeline. Hopper owns the resumption; UI/XCUITests remain disabled.

### 2026-07-17T00:44:14.771-07:00: Preserve and reconcile MRs !79 and !80
**By:** Tesla (Lead / Architect)
**Decision:** Merge neither open MR. MR !79 (`689023a`) has no exact-head pipeline and incorrectly closes already-shipped issue #109, whose sole canonical MR !78 merged exact head `03516ea` with green pipeline `2683960731`. MR !80 (`50120ab`) is the sole valid MR for runnable issue #110, but it also has no exact-head pipeline. Preserve every worktree, branch, stash, safety ref, and dirty coordination file.
**Next work item:** The Coordinator must first give MR !79's distinct post-merge release-provenance correction a canonical issue identity, or close it if it duplicates shipped #109; only then may the queue proceed to exact-SHA CI and MR !80.
**Trade-off:** This delays two mergeable diffs, but preserves one issue per coherent MR and forbids merging on unknown pipeline evidence.

---

### 2026-07-17T01:44:15.855-07:00: User directive
**By:** Tesla (Squad) (via Copilot)
**What:** Run the complete autonomous Knitting Gauge Reconciler Squad Work Loop through merge, cleanup, and final review. UI tests and XCUITests are explicitly disabled and fail closed: do not assign, create, edit, enable, build, run, inventory, require, or gate on them. Authorized testing is `./app/build.sh test` constrained to non-UI/unit tests, plus issue-contracted release/build checks that do not activate UI tests. Map the six Jacquard scenarios to authorized unit tests only. Use `gpt-5.6-sol` for every agent, including Ralph and Scribe. Apply Ponytail full, preserve validation/error handling/security/accessibility/explicit requirements, and use the smallest runnable non-UI check unless an issue requires more authorized unit coverage. Follow issue/MR/exact-SHA CI/cleanup and commit-trailer requirements exactly; update issue descriptions rather than status/scope comments; one MR per domain issue; no duplicate subtask issues.
**Why:** User request — captured for team memory

---

# Tesla — Local saved-state reconciliation

- **Date:** 2026-07-17T01:44:15.855-07:00
- **Decision:** Resume only issue #114 through existing MR !82 and its clean,
  synchronized worktree at `ffdfa5d2`. Hopper remains the domain owner. Do not
  create fresh implementation or merge before an exact-head green pipeline.
- **Test boundary:** Static inspection authorizes `./app/build.sh test` as
  unit-only, but no test ran in this phase. UI tests and XCUITests remain
  prohibited.
- **Preservation:** Keep dirty root coordination records, shipped-but-dirty
  #109 identity state, blocked divergent #51 state, all 34 stashes, all 11
  safety refs, and closed-unmerged stray branches.
- **Trade-off:** Waiting for exact-head hosted evidence costs latency; preserving
  ambiguous state costs clutter. Both costs are preferable to a false-green
  merge or destructive cleanup.

---

### 2026-07-17T02:24:16.755-07:00: User directive
**By:** Tesla (Squad) (via Copilot)
**What:** The existing unit-test inventory required by `./app/build.sh test`, including Swift unit coverage of all six scenarios and edge cases, is authorized. UI tests and XCUITests are disabled and must not be assigned, created, enabled, or run. Scenario-to-UI mapping may be documentation/review only. This scope is fail closed and cannot be expanded by agents, reviewers, issues, or merge requests. Use `gpt-5.6-sol` for every helper. Apply Ponytail Full: prefer deletion, native/stdlib/already-installed tools, and the shortest correct diff without weakening requested validation, error handling, security, or accessibility.
**Why:** User request — captured for team memory

---

### 2026-07-17T02:24:16.755-07:00: Close issue #51, preserve unshipped state
**By:** Tesla (Lead / Architect)
**What:** Close issue #51 after replacing its stale description with the direct boundary: the existing `./app/build.sh test` unit inventory, including all six scenarios and edge cases, is authorized; UI tests and XCUITests remain disabled. Keep MR !66 closed and unmerged. Preserve the divergent #51 branch, worktree, and its two dirty UI-test files.
**Why:** The issue's sole implementation purpose was a UI-test gate, so no authorized work remains. Closing the issue is correct, but deleting dirty, divergent, unshipped work is not independently authorized.
**Trade-off:** Historical local clutter remains, but this avoids irreversible loss while honoring the fail-closed scope.

---

### 2026-07-17T02:24:16.755-07:00: Final #51 cleanup and #113 verification reconciliation
**By:** Scribe (Session Logger)
**What:** Treat Tesla's later cleanup result as the final operational state: after rewriting and closing #51, Tesla removed only its closed-issue worktree and local branch and pruned worktree metadata; MR !66, its remote branch, and stashes remain preserved. Hopper independently verified exact main SHA `6292cdec1763f6a614e70a2e96315309e120147a`, matching live workflows, a successful exact-name Build & Test run and GitLab external pipeline, and a tamper-rejecting CD predicate before rewriting and closing #113.
**Why:** This reconciles the earlier preservation snapshot with the manifested final cleanup and records the exact evidence supporting #113 closure.
**Status:** No open domain MR or runnable domain issue remains. Tracker #1 and follow-up issues remain non-runnable.

---

### 2026-07-17T03:24:12.830-07:00: User directive
**By:** Tesla (Squad) (via Copilot)
**What:** Execute the complete autonomous Squad Work Loop through reconciliation, ready-MR completion, implementation, exact-SHA CI validation, merge, cleanup, goal reevaluation, and final review. The only authorized test command/suite is `./app/build.sh test` and its non-UI/unit tests. UI tests and XCUITests are explicitly disabled and must not be created, enabled, assigned, or run. No reviewer, issue rewrite, goal, work item wording, or inferred coverage requirement may expand that scope. Mendel may map the six Jacquard scenarios to existing/non-UI unit tests and report UI-level gaps only as advisory; those gaps cannot block or reject the artifact. Any additional ambiguity must fail closed by preserving state and reporting instead of expanding tests. Every Squad member or helper launched must use model `gpt-5.6-sol`. Apply Ponytail full: prefer deletion/native/standard-library solutions and smallest complete diffs without simplifying away correctness, accessibility, validation, error handling, explicit criteria, or the smallest authorized runnable unit check for nontrivial logic.
**Why:** User request — captured for team memory

---

### 2026-07-17T04:50:29.193-07:00: User directive
**By:** Tesla (Squad) (via Copilot)
**What:** For issue #117, review only the already-produced authorized unit-test artifacts from the successful `./app/build.sh test` rerun. Do not rerun tests. UI tests/XCUITests remain prohibited from inspection, assignment, creation, editing, enabling, building, running, inventory, or gate use. Confirm using `xcresulttool` and the existing gate log only. Approve only if the unit gate has zero warnings, failures, skips, expected failures, and retries. Do not edit issue artifacts, commit, push, or mutate GitLab.
**Why:** User request — captured for team memory

---

# Issue #62 Ready-MR Gate

**Date:** 2026-07-17T03:24:12.830-07:00  
**Owner:** Tesla  
**Decision:** Preserve MR !84 and route its next revision to Edison.

MR !84 is mergeable and has a successful exact-head pipeline at
`db711eeb597f510ee8fa3ff879b2de54ee7a4431`, with no unresolved discussion.
It is nevertheless blocked by issue #62's strict revision contract: the commit
records Tesla as both author and committer even though Tesla is locked out and
Edison is the required independent revision owner.

Edison must independently revise the existing issue-62 branch/MR. Do not merge,
open a duplicate MR, or clean its worktree before a contract-compliant exact
head passes the required gates.

**Trade-off:** Repeating a technically green revision costs time, but merging a
locked-out author's artifact would invalidate the reviewer-independence rule.

---

### 2026-07-17T15:05:00.467-07:00: User directive
**By:** Tesla (Squad) (via Copilot)
**What:** UI tests and XCUITests are disabled and must remain disabled. Do not assign, create, enable, or run them. The authorized inventory is Swift unit tests only, including the six Jacquard gauge-math scenarios and relevant unit-level edge cases. Reviewer feedback and inferred coverage cannot expand this scope. Use gpt-5.6-sol for every nested Squad agent, follow Ponytail full, preserve ambiguous work, and include the specified Copilot co-author trailer on commits.
**Why:** User request — captured for team memory

---

