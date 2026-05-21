# Tesla — History

## Core Context

- **Project:** A knitting gauge reconciler that converts patterns between stitch/row gauges.
- **Role:** Lead / Architect
- **Joined:** 2026-05-19T07:11:08.646Z

## Learnings

### 2026-05-21T14:24:22Z — Push gate for log-only carry-forward cycles

- **Predecessor commits left unpushed.** Curie+Scribe commits (`7cbdff4` + `40c4c0f`) at 14:14Z were committed locally but never pushed by predecessor. Always check `git log origin/main..HEAD` at intake; push any pending local commits before evaluating CI/CD gate. Pushed cleanly: `8362c0b..40c4c0f main -> main`.
- **GitLab pipelines are `source=external` / webhook-only.** A `git push` does not auto-trigger a pipeline; new pipelines appear via external triggers (GitHub mirror sync) on their own schedule, often with zero jobs. The loop's "wait for CI/CD green" rule is satisfied by the predecessor's already-green pipeline on the immediate prior pushed SHA, given the established external/zero-jobs scoping (closed `#5`/`#10`/`#11`) puts pipeline jobs out of Squad scope and ties Goals 1/5 to local `./app/build.sh test`.
- **Carry-forward decision math when sibling xcodebuild active:** xcresult age + MD5 identity + sibling-saturation cost are the three inputs. If (age < 30 min) AND (all 5 MD5s match baseline) AND (sibling on contested 179149FE), prefer log-only carry-forward — starting a competing gate reproduces the documented sibling-saturation exit-65 flake without adding evidence value.

---

### 2026-05-20T22:37:00-07:00 — HIG Research: Wheel + Keyboard Numeric Input Field

**Session:** tesla-wheel-input-hig (design memo for Edison-9)

**Canonical pattern confirmed:**
`UITextField` with `inputView = UIPickerView` (two-component: integer wheel | fraction wheel) + `inputAccessoryView = UIToolbar` (Keyboard button + Done button). The picker occupies the keyboard slot at the bottom of the screen — not a sheet, not a popover, not an always-visible inline control. Mode switch to `.decimalPad` is a single toolbar button tap, not a separate screen.

**Key HIG citation:**
"On iPhone, pickers are typically displayed at the bottom of the screen." (HIG/Pickers) + UIKit `UITextField.inputView` API: "If the value of this property is not nil, the text field uses the view it contains as the first responder's input view, replacing the system keyboard." These two facts together define the pattern. Apple Health (weight), Contacts (label selector), and Settings (birthday) all implement it this way.

**UIKit/SwiftUI seam that surprised me:**
`UIPickerView` used as `inputView` on a `UITextField` does NOT automatically grant the `.adjustable` VoiceOver trait to the text field. The picker itself is adjustable when focused directly, but when hosted as `inputView`, the owning UITextField needs a subclass that overrides `accessibilityTraits` and implements `accessibilityIncrement()` / `accessibilityDecrement()` to proxy to the picker. This is the most non-obvious part of the pattern — and the part most likely to be skipped, breaking VoiceOver for all users who rely on swipe-up/down adjustment.

**Delivered:**
- `.squad/decisions/inbox/tesla-wheel-input-hig.md` — design memo for Edison-9
- `.squad/skills/swiftui-numeric-wheel-keyboard-input/SKILL.md` — reusable pattern (confidence: low)

---

### 2026-05-20T20:38:28-07:00 — Cleanup Round 2026-05-20 (Architecture Oversight)

**Session:** cleanup-round (Edison audit + Edison/Curie implementation, parallel)

**Deferred architectural calls:**
- **D.1 (split GaugeMath file boundaries):** `ResultsExportSummary`, `ResultsShareTextFormatter`, `ResultsExportRowsModel`, `plain()`, `fixed()`, `gaugeStatus()`, `rowStatus()` all in `GaugeMath.swift` (math engine + export-formatting layer). File boundary blurry. Could split into `GaugeExportFormatters.swift` but touches file organization (Hopper + Tesla call). **Deferred. No action this round.**

**4.1 fix (signpost inflation) — vetting:**
- Edison's cached `@State var cachedResult` + `.onChange(of: inputs, initial: true)` for `recomputeResult()`.
- Signpost fires 1× per input change instead of 15-20× per body render.
- **Confirmed:** Matches §2.2 math-boundary (GaugeMath pure, signpost view-layer only).
- **Status:** Approved and shipped.

**Status:** Cleanup round shipped 11 items (8 Edison + 3 Curie). All 49 tests pass, 0 warnings. D.1 pending Tesla call. Next round may invoke Tesla's decision if file architecture needs clarification.

---

## 2026-05-20T19:26:30Z — MetricKit V1 Shipped

MetricKit V1 implementation completed. 9 signpost names locked by user directive. Build: 49/49 tests (was 25). Swift coding standards amended (§2.2/§2.3/§2.12/§7). GitLab #9 updated with scope correction, privacy posture, and deferred items.

---

## Earlier Sessions

(See history-archive.md for full timeline of MetricKit scope design, swift-metrics V2 re-pass, user directives, and prior architecture decisions.)
