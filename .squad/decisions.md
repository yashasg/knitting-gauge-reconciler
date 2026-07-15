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

# Issue #65 Coverage Verdict

- **Date:** 2026-07-15T04:42:30.201-07:00
- **Owner:** Curie
- **Verdict:** REJECTED — Edison UI artifact
- **Ada math artifact:** Accepted; focused formula, validator, and export coverage passed 23/23.
- **Blocking reproduction:** Launch with `KGR_PS=0` and `KGR_PR=100`, edit pattern rows, then activate `keyboard-done`. The app main run loop becomes unresponsive while the test verifies focus on `pattern-stitches-field`; canonical execution crashes/retries. A process relaunch also restores sample defaults instead of the valid/invalid/partial scene draft.
- **Accessibility:** `gauge-lead` fails contrast and `gauge-summary` fails the text-clipping audit.
- **Revision owner:** Hopper. Edison is locked out as original author; Curie remains reviewer-only.

---

# Issue #65 Form-Flow Adoption

**Date:** 2026-07-15T04:42:30.201-07:00
**Owner:** Edison
**Status:** Implemented; ready for Curie adoption

## Keyboard warning resolution

Removing the keyboard toolbar's bare `Spacer()` did not remove the focused test's `Invalid frame dimension`
runtime warning. The approved follow-up A/B removal of the SwiftUI text field's redundant flexible frame also left
the warning unchanged; removing the SwiftUI keyboard toolbar eliminated it.

Keep direct entry native and accessible by hosting `UITextField` in the existing `GaugeStepperField.swift` and
using a spacer-free `UIToolbar` as its `inputAccessoryView`. The accessory retains the public `keyboard-done`
identifier and routes Done through the same validation/focus submission path. No clamping or fallback enters the
raw-to-typed path.

## Test handoff

The focused wheel test passes and its xcresult contains no `Invalid frame dimension` warning when the stale
pre-issue-#65 unit-test source is excluded from that focused build. Curie must update the authorized tests for
Ada's optional result API before the canonical full test gate can compile.

---

# Issue #65 Lockout and Snapshot Resolution

**Date:** 2026-07-15T07:22:37.572-07:00
**Owner:** Tesla
**Verdict:** Hopper owns the UI revision; Edison remains locked out

## Authoritative resolution

Curie's rejection activated strict reviewer lockout on Edison's seven-file UI
artifact and assigned Hopper. The later recovery gate could preserve stash facts,
but it could not clear that lockout or return the rejected artifact to Edison.
Its “Edison resumes” instruction is therefore void. Lockout lasts until Curie
approves Hopper's independent revision.

## Snapshot facts

The intake working tree is not an exact restoration of recovered stash `6ae295a`.
That stash contained Edison history, `.squad/decisions.md`, eight production
files, and three test files. The intake tree:

- omits the stashed Edison history and decisions changes;
- adds Curie and Tesla history entries;
- exactly retains the recovered `GaugeMath.swift`, `ShareableView.swift`, and
  `AccessibilityAuditTests.swift`;
- contains later content in the other six production files and in
  `GaugeMathTests.swift` and `KnittingGaugeReconcilerUITests.swift`;
- contains still-later edits than stash `7d3c535` in `GaugeStepperField.swift`,
  `ContentView.swift`, `GaugeInputsCard.swift`, and
  `PatternInstructionsCard.swift`.

Observed production/test blob IDs before this decision:

| Path | Blob |
|---|---|
| `app/KnittingGaugeReconciler/Components/GaugeStepperField.swift` | `b2f8d575d85c859cdaf31688aeed972173d39e0a` |
| `app/KnittingGaugeReconciler/ContentView.swift` | `96bb3b6645fdae7bf0c416c9691995b1bd193296` |
| `app/KnittingGaugeReconciler/ContentViewHelpers.swift` | `f18c5ddec3fce0d57a36a9b87cef5a78c0b84004` |
| `app/KnittingGaugeReconciler/GaugeMath.swift` | `cc8755825fa9f9475afb6d7820761f9962bbb0f2` |
| `app/KnittingGaugeReconciler/Views/GaugeInputsCard.swift` | `fdd95dadcc254130375933f4fae2be5d8cfd5c92` |
| `app/KnittingGaugeReconciler/Views/PatternInstructionsCard.swift` | `198486b40e60d2d5e85913af041b7960c2f44f11` |
| `app/KnittingGaugeReconciler/Views/RequiredAdjustmentsCard.swift` | `6f5a2eab0cc63f5417f184184131d465e952e6d6` |
| `app/KnittingGaugeReconciler/Views/ShareableView.swift` | `a5dc9afb71b4f8e1ca3efae85ad05b19871b5779` |
| `app/KnittingGaugeReconcilerTests/GaugeMathTests.swift` | `64b1e1da4eacaf6edefb46fe56fe3d55d5c343b8` |
| `app/KnittingGaugeReconcilerUITests/AccessibilityAuditTests.swift` | `e91d8126cf6dc61fe9f76e47e11b86a4cdb4b5b6` |
| `app/KnittingGaugeReconcilerUITests/KnittingGaugeReconcilerUITests.swift` | `253425e32bba218ae73597dee7c7656adacafda1` |

Do not apply, pop, restore, discard, or overwrite any stash or working-tree path.

## Ownership and exact allowlist

Hopper may revise only:

1. `app/KnittingGaugeReconciler/ContentView.swift`
2. `app/KnittingGaugeReconciler/ContentViewHelpers.swift`
3. `app/KnittingGaugeReconciler/Components/GaugeStepperField.swift`
4. `app/KnittingGaugeReconciler/Views/GaugeInputsCard.swift`
5. `app/KnittingGaugeReconciler/Views/PatternInstructionsCard.swift`
6. `app/KnittingGaugeReconciler/Views/RequiredAdjustmentsCard.swift`
7. `app/KnittingGaugeReconciler/Views/ShareableView.swift`

The intake's later edits already target the rejected focus loop, restoration,
contrast, and wrapping failures. They are preserved as a provisional candidate,
not accepted evidence. Hopper must assess and finish them independently.

Ada owns the accepted `GaugeMath.swift` artifact; it is read-only. Curie owns all
three test files and the rejection evidence; retain those files in place and
unchanged during Hopper's revision. Do not park them and do not restore older
stashed drafts. Curie receives the completed candidate only for an independent
review rerun; test edits require a separate Tesla gate.

Edison may not revise, advise, pair, review, or co-author this UI revision.
Hopper must not edit Squad records, tests, math, build scripts, project files,
prototype files, or create files.

## Executable handoff

Because this is a composite tree, a global HEAD diff is not an ownership check.
Compare Hopper's exit tree against the blob baseline above and require every
changed baseline blob to be in Hopper's seven-path allowlist. Any later
non-allowlisted change remains preserved but blocks this handoff pending its
owner's disposition. Then run:

1. `git diff --check`
2. `swiftlint lint --quiet --no-cache app/KnittingGaugeReconciler`
3. The five focused tests named in
   `tesla-issue-65-rejected-ui-revision-gate.md`
4. `xcodebuild test -project app/app.xcodeproj -scheme KnittingGaugeReconciler -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:KnittingGaugeReconcilerTests/GaugeMathTests`
5. `./app/build.sh test`

Acceptance requires the five focused failures fixed, Ada's unit gate green, all
75 canonical tests passing with no skips or retries, and zero lint, compiler,
analyzer, runtime-warning, or crash evidence. Curie then reviews read-only.

## Queue

GitLab issue #65 remains open, has no linked dependency, no related/open merge
request, and no remote issue branch. It is the highest-priority runnable domain
issue. The other open implementation items are follow-ups or depend on #65;
#66 depends on #65 and #70 depends on #66, while final review trackers remain
blocked. Do not change issue scope/status or create remote artifacts.

---

# Issue #65 Stash Recovery Gate

**Date:** 2026-07-15T06:42:38.937-07:00
**Owner:** Tesla
**Verdict:** Edison resumes; Curie remains blocked

## Recovered facts

`refs/stash` is `6ae295a`, based exactly on branch HEAD `9dc3492`. Its index parent
`74df693` has the same tree as HEAD, and its nominal untracked parent `0ff69d6`
is the empty tree. The stash therefore contains 13 unstaged modifications and
no untracked files:

1. `.squad/agents/edison/history.md`
2. `.squad/decisions.md`
3. `app/KnittingGaugeReconciler/Components/GaugeStepperField.swift`
4. `app/KnittingGaugeReconciler/ContentView.swift`
5. `app/KnittingGaugeReconciler/ContentViewHelpers.swift`
6. `app/KnittingGaugeReconciler/GaugeMath.swift`
7. `app/KnittingGaugeReconciler/Views/GaugeInputsCard.swift`
8. `app/KnittingGaugeReconciler/Views/PatternInstructionsCard.swift`
9. `app/KnittingGaugeReconciler/Views/RequiredAdjustmentsCard.swift`
10. `app/KnittingGaugeReconciler/Views/ShareableView.swift`
11. `app/KnittingGaugeReconcilerTests/GaugeMathTests.swift`
12. `app/KnittingGaugeReconcilerUITests/AccessibilityAuditTests.swift`
13. `app/KnittingGaugeReconcilerUITests/KnittingGaugeReconcilerUITests.swift`

This is a composite issue snapshot, not Edison-only work. It includes the math
API, expanded dependent views, Curie's draft tests, and stale Squad claims.
Do not pop or apply it wholesale.

## Production recovery

Edison is the next owner. While HEAD is still `9dc3492` and the product paths
are clean, Edison may selectively restore only these eight production files:

- `app/KnittingGaugeReconciler/GaugeMath.swift`
- `app/KnittingGaugeReconciler/ContentView.swift`
- `app/KnittingGaugeReconciler/ContentViewHelpers.swift`
- `app/KnittingGaugeReconciler/Components/GaugeStepperField.swift`
- `app/KnittingGaugeReconciler/Views/GaugeInputsCard.swift`
- `app/KnittingGaugeReconciler/Views/PatternInstructionsCard.swift`
- `app/KnittingGaugeReconciler/Views/RequiredAdjustmentsCard.swift`
- `app/KnittingGaugeReconciler/Views/ShareableView.swift`

The three added dependent views are necessary to preserve blank optionals and
omit absent screen/share sections. `GaugeMath.swift` is recovered as the math
candidate; Edison must not change formula direction or broaden its API.

Before freezing source, Edison must route wheel initialization through
`GaugeMath.validate` rather than reparsing raw text with `Double` and
`Int(exactly:)`. This keeps keyboard, paste, wheel, restoration, and
calculation behind one validation contract.

The pre-Curie gate is:

1. `git diff --check`
2. Diff allowlist contains exactly the eight production files above.
3. `swiftlint lint --quiet --no-cache app/KnittingGaugeReconciler`
4. `./app/build.sh build` exits zero with no compiler warnings.
5. The existing
   `testStepperFieldOpensWheelAndKeyboard` focused UI test passes with the
   stale `GaugeMathTests.swift` source excluded, and its xcresult has no
   `Invalid frame dimension` warning.
6. Edison records the exact source commit and API freeze without restoring the
   stashed Squad or test files.

## Curie handoff

Only after that freeze may Curie modify:

- `app/KnittingGaugeReconcilerTests/GaugeMathTests.swift`
- `app/KnittingGaugeReconcilerUITests/KnittingGaugeReconcilerUITests.swift`
- `app/KnittingGaugeReconcilerUITests/AccessibilityAuditTests.swift`

The stashed test versions are drafts, not approved coverage. They lack an
independent multiple-scene draft test, and their restoration test backgrounds
and reactivates one process rather than proving process interruption. Curie
must close those gaps, then run `./app/build.sh test` with zero lint,
compiler, analyzer, and runtime warnings before Ive receives the read-only
gate.

## Issue state

The canonical GitLab issue #65 description remains accurate. Do not rewrite
it and do not add a scope or status comment. `.squad/identity/now.md` stays
stale until production recovery is persistent; Scribe can reconcile it after
the source freeze.

---

# Issue #65 Rejected UI Revision Gate

**Date:** 2026-07-15T04:42:30.201-07:00
**Owner:** Tesla
**Verdict:** **HOPPER-REVISION-APPROVED**

## Facts

- The latest authoritative canonical xcresult bundle records 75 tests run, 70 passed, 5 failed, and 0 skipped.
- Curie's focused evidence isolates a 30-second app-main-run-loop stall during validation, exact scene-draft loss
  (`31.5` restored as sample `32`), a `gauge-summary` text-clipping audit issue, and a `gauge-lead`
  contrast issue. The canonical “signal kill” records are UI-runner termination after stalls, not evidence
  permitting test retries or weaker assertions.
- GaugeMath passed 23/23 and SwiftLint reported 0 violations. Ada's validator API, optional model, formulas,
  rounding, and export behavior are approved and read-only.
- The failures are UI/lifecycle defects. None requires changing Curie's tests or Ada's approved API.

## Exact five-failure repair map

| # | Test | Symptom and root cause | Authorized source | Smallest repair |
|---|---|---|---|---|
| 1 | `AccessibilityAuditTests/testRequiredOnlyResultsAccessibility()` | `Text clipped`; xcresult identifies `gauge-summary`. Its section header is constrained by nested vertical `fixedSize` modifiers with no width headroom at audit Dynamic Type. | `Views/RequiredAdjustmentsCard.swift` | Let the title/subtitle wrap inside the card: remove the inherited fixed-size constraint and give the header full leading width. Keep `gauge-summary` on the container. |
| 2 | `AccessibilityAuditTests/testRevisedFormCollapsedAndExpandedAccessibility()` | `Contrast failed`; xcresult identifies `gauge-lead`. The accessibility frame is sampled over the textured Canvas rather than one opaque surface. | `ContentView.swift` | Put the exact lead sentence on an opaque `AppTheme.background` surface covering its full accessibility frame; retain `AppTheme.ink`, copy, identifier, and multiline reflow. |
| 3 | Canonical `testSceneRestorationPreservesValidInvalidPartialAndResetDrafts()`; current name `testSceneRestorationPreservesValidInvalidPartialAndResetDraftsAcrossProcessInterruption()` | After process interruption, raw `31.5` becomes launch sample `32`; the continuing scene is falling back to environment initialization instead of rehydrating its scene draft. | `ContentView.swift`, if needed `ContentViewHelpers.swift` | Keep all nine raw values and disclosure state in `@SceneStorage`; synchronously update/restore the continuing scene's restoration activity across background/process loss. Preserve exact strings, including invalid/partial text, and do not use global draft storage. |
| 4 | `KnittingGaugeReconcilerUITests/testStepperFieldOpensWheelAndKeyboard()` | Canonical UI runner was killed during responder interaction. The representable queues focus reconciliation from every `updateUIView`, while delegate/Done callbacks mutate the same focus binding, allowing a main-queue responder loop/backlog. | `Components/GaugeStepperField.swift`, `ContentView.swift` | Coalesce responder changes and schedule only when desired focus differs; make keyboard Done perform one focus transition. Do not parse, clamp, or change wheel validation. |
| 5 | `KnittingGaugeReconcilerUITests/testValidationRoundTripPreservesRawTextFocusesFirstErrorAndReenablesResults()` | Focused rerun reports “process main thread busy for 30.0s” after Done with multiple invalid fields. `finishEditing` globally resigns, clears focus, then asynchronously refocuses while each UIKit field independently queues reconciliation. | `ContentView.swift`, `Components/GaugeStepperField.swift` | Replace the clear/resign/refocus sequence with one deterministic transition directly to the first invalid field; only resign when no invalid field remains. Preserve inline error, announcement, raw text, blocked results, and correction flow. |

The stepper and validation failures share one responder-loop defect; they do not justify test changes.

## Hopper scope

Hopper is eligible and may revise only these seven Edison-authored UI files:

1. `app/KnittingGaugeReconciler/ContentView.swift`
2. `app/KnittingGaugeReconciler/ContentViewHelpers.swift`
3. `app/KnittingGaugeReconciler/Components/GaugeStepperField.swift`
4. `app/KnittingGaugeReconciler/Views/GaugeInputsCard.swift`
5. `app/KnittingGaugeReconciler/Views/PatternInstructionsCard.swift`
6. `app/KnittingGaugeReconciler/Views/RequiredAdjustmentsCard.swift`
7. `app/KnittingGaugeReconciler/Views/ShareableView.swift`

The expected minimal touch set is the first three plus `RequiredAdjustmentsCard.swift`; the remaining three are
available only for a directly required UI propagation. No formula, validation contract, or output-model change is
authorized.

## Forbidden and lockout

- Do not modify the three Curie test files, `GaugeMath.swift`, `app/build.sh`, `project.pbxproj`, any prototype
  path, any other source, or create files.
- Preserve Ada's API and formulas exactly.
- Edison is strictly locked out for this revision: no revision, advice, pairing, review guidance, or co-authorship.
  Hopper owns the revision independently.
- Do not commit, push, comment on issue #65, or open an MR during this revision handoff.

## Required reruns

From the repository root, first run the focused rejected surface:

```bash
xcodebuild test \
  -project app/app.xcodeproj \
  -scheme KnittingGaugeReconciler \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:KnittingGaugeReconcilerUITests/AccessibilityAuditTests/testRequiredOnlyResultsAccessibility \
  -only-testing:KnittingGaugeReconcilerUITests/AccessibilityAuditTests/testRevisedFormCollapsedAndExpandedAccessibility \
  -only-testing:KnittingGaugeReconcilerUITests/KnittingGaugeReconcilerUITests/testStepperFieldOpensWheelAndKeyboard \
  -only-testing:KnittingGaugeReconcilerUITests/KnittingGaugeReconcilerUITests/testValidationRoundTripPreservesRawTextFocusesFirstErrorAndReenablesResults \
  -only-testing:KnittingGaugeReconcilerUITests/KnittingGaugeReconcilerUITests/testSceneRestorationPreservesValidInvalidPartialAndResetDraftsAcrossProcessInterruption
```

Then preserve Ada's gate and run the canonical gate:

```bash
xcodebuild test \
  -project app/app.xcodeproj \
  -scheme KnittingGaugeReconciler \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:KnittingGaugeReconcilerTests/GaugeMathTests
./app/build.sh test
```

Approval requires all focused tests and all 75 canonical tests passing, 0 skips/retries, 0 SwiftLint violations,
and 0 warnings or crashes.

---

# Issue #65 Prepublication Acceptance

**Date:** 2026-07-15T09:08:17-07:00
**Owner:** Tesla
**Verdict:** Approved for one issue merge request

- Ada/Jacquard approved the validator, formula directions, optional arithmetic, and rounding.
- Hopper's independent UI revision resolved focus loops, process restoration, Dynamic Type, contrast, and
  keyboard-toolbar warnings. Scene snapshots are keyed by every open scene session and discarded with that session.
- Ive approved the required-first hierarchy, collapsed blank optionals, correction flow, reset/Undo, semantic text
  colors, and accessibility behavior.
- Mendel approved exact unit and visible UI result coverage for all six Jacquard scenarios, plus deterministic
  production-path coverage for separate scene drafts.
- Curie's isolated canonical gate passed 76 tests with 0 failures, 0 retries, 0 SwiftLint violations, and no compiler,
  analyzer, or application-runtime warning matches.
- Fastlane now requests an explicit result bundle so a successful test run is reported deterministically.

---

# Issue #65 Exact-Commit CI Restoration Remediation

**Date:** 2026-07-15T10:34:00-07:00
**Owner:** Tesla
**Verdict:** Approved for replacement exact-commit CI

- GitHub run `29435073981` failed only the reset half of the process-interruption restoration test: `your-rows`
  relaunched as the fixture value `24` instead of the saved reset value `32`.
- The test initialized its first process with `-ApplePersistenceIgnoreState YES`. That system argument also prevents
  iOS from retaining the scene session the test subsequently expects to restore, so CI could legitimately create a
  new session and fall back to launch fixtures.
- The first process now ignores prior draft values through app-scoped `-KGRIgnoreStoredDraft YES`, leaving iOS scene
  persistence enabled. Production snapshots are also written synchronously to `UISceneSession.userInfo` as well as
  the existing scene-keyed store.
- The focused restoration test passed on a freshly erased isolated simulator. The canonical
  `./app/build.sh test` gate then passed 76/76 with 0 failures, 0 skips, 0 retries, 0 SwiftLint violations, and no
  compiler, analyzer, or application-runtime warning matches.
- Follow-up CI showed that `XCUIApplication.activate()` could relaunch with the first process's fixture arguments.
  That made the initial fixture appear restored while replacing the later reset snapshot with fixture value `24`.
  The process-interruption helper now uses `terminate()` followed by `launch()`, which applies the explicitly cleared
  relaunch arguments. Reset, Undo, and scene deactivation also synchronize their completed scene-keyed writes before
  returning. The corrected process test passed three consecutive fresh-simulator executions.
- The GitHub-only bridge uses the canonical `.git` clone URL and an exact `arm64` simulator destination, removing the
  clone redirect and dual-architecture destination warnings from raw CI output.
- Curie's final local rerun captured an iOS 26 contrast-audit false positive for the exact `Pattern 100%` label. The
  attached element image shows opaque near-black text over the opaque oatmeal tile; the existing audit filter now
  excludes only that exact platform report. The following signal-kill record was suite cancellation after the audit
  failure, and both affected tests passed together without test-level retry.
