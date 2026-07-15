# Active Decisions

## 2026-07-14T23:38:12.955-07:00 — User directive

### 2026-07-14T23:38:12.955-07:00: User directive
**By:** Tesla (Squad) (via Copilot)
**What:** Run the complete Squad Work Loop autonomously; use `gpt-5.6-sol` for every launched agent including Ralph and Scribe; keep Ponytail full active; require local zero-warning tests and all named reviews before MR/merge; skip tracker/follow-up work; do not fake unavailable remote actions.
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
