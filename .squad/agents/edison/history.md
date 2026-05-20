# Edison — History

## Core Context

- **Project:** A knitting gauge reconciler that converts patterns between stitch/row gauges.
- **Role:** Frontend Dev
- **Joined:** 2026-05-19T07:11:08.646Z

## Learnings

- Gauge dimension formulas fixed in prototype/index.html: `dimScale = pr / yr` for vertical cm outputs, `rowCountScale = yr / pr` for hero display and increase spacing. Reference Jacquard spec (decisions.md: The Correct Math) for UI text matching.
- 2026-05-19 (Compact Fields): Implemented compact numeric fields (92–156 pt widths) with 140 pt minimum columns for paired fields. Accessibility Dynamic Type stacks fields and expands to full width. ContentView.swift updated; build passed.

- **2026-05-19 ContentView fidelity pass:**
  - Verdict copy must be axis-aware, not severity-only. The prototype branches on WHICH axes are off (stitch-only, row-only, both, neither); severity (`verdictTitle`) remains a useful headline but the body copy must reflect which axis needs attention.
  - `gaugeStatus()` and `rowStatus()` match prototype's `pillFor`/`pillRowFor`: "Match", "Looser/Tighter/Denser than pattern" (3–10%), "Much looser/tighter/denser" (≥10%).
  - Adjustment row labels must include an action verb: "Knit to X cm", "Space every X rows", "Cast on X stitches". UI test `scenario.body` and `scenario.increases` strings must be updated in lock-step with any label format change.
  - Cast-on drift pill (≥3% rounding error) is surfaced inline in `AdjustmentRow` via optional `driftPill: String?`, matching prototype's inline `pill-warn`.
  - `HeroMetric.pillBackground` has three branches: green (Match), amber (3–10% drift), alert-pink ("Much" ≥10%), matching prototype's `pill-good`/`pill-warn`/`pill-alert`.
  - XCTest `app.staticTexts["label"].exists` finds individual Text elements even inside `.accessibilityElement(children: .combine)` HStacks — adjust test expectations whenever `AdjustmentRow.adjusted` format changes.



## [2026-05-19 19:13:04Z] Canonical Xcode Project Path Update

⚠️ **All squad members:** The Xcode project has been renamed to **`app/app.xcodeproj`**. 

- **Previous path:** `app/KnittingGaugeReconciler.xcodeproj`
- **Current path:** `app/app.xcodeproj` (canonical reference)
- **App target & scheme:** `KnittingGaugeReconciler` (unchanged)
- **Build script:** `app/build.sh` updated and validated

Any references to the old project path should be updated. Use `app/app.xcodeproj` going forward.

---

### 2026-05-19 — corrected canonical Xcode project path

Correction to earlier path note: the project bundle must remain `app/KnittingGaugeReconciler.xcodeproj` per the explicit Tesla scaffold priority item. UI work remains under `app/KnittingGaugeReconciler/`; scheme remains `KnittingGaugeReconciler`.

---

## [2026-05-20T02:21:23Z] Swatch Hint Layout Fix

**Session:** swatch-hint-layout (Edison + Curie)
**Decision:** Constrain `NumberField` hint copy to the compact numeric column width for non-accessibility Dynamic Type, while leaving it unconstrained at accessibility sizes.

**Work:** Fixed swatch hint text wrapping by constraining NumberField hints to column width at non-accessibility sizes. Preserves accessibility fallback. Simulator build passed. Curie verified with UI tests — both Pattern gauge and Your swatch remain side-by-side when they fit.

## [2026-05-20T03:31:51Z] Copy Results Menu Implementation

**Session:** copy-results-menu

**Task:** Implement Ive's Copy results menu UX spec.

**Deliverable:** Native SwiftUI `Menu` with deterministic formatters for TSV, Markdown, CSV, HTML. Removed old unavailable share-link affordance. Added formatter and UI test coverage.

**Validation:** Ive approved design; Curie tightened tests for old affordance removal and per-section guidance coverage. `./app/build.sh test` passed.

**Status:** Approved and ready for deployment.

## [2026-05-19T22:40:33-07:00] Major Mismatch Help Overlay

**Session:** major-mismatch-help-overlay
**Task:** Move verdictPanel explanatory body text behind a tappable `?` affordance.

**What changed:**
- `verdictPanel` now shows only the verdict title + a `?` (`questionmark.circle`) button. The inline `Text(verdictBody)` was removed from the card.
- Added `@State private var showVerdictHelp = false` and a `.sheet(isPresented:)` presentation attached to the NavigationStack.
- New `VerdictHelpSheet` private struct renders the title + explanation in a scrollable pull-up sheet with `.presentationDetents([.medium, .large])` and `.presentationDragIndicator(.visible)`.
- VoiceOver: the `?` button carries `accessibilityLabel("More information")` + hint; the title Text carries the existing `verdictAccessibilityLabel` summary. Sheet content is fully navigable.
- Added `testVerdictHelpButtonOpensPullUpSheet` UI test: asserts the help button exists, that `re-swatching` text is NOT in the main view, taps button, asserts sheet appears with the text.
- All 18 unit tests pass; app builds successfully.

**Decision:** Applied to all verdict states (not just "Major mismatch") for consistent UX — the card is always compact with title + `?`.

---

## ⚠️ [2026-05-20T06:25:04Z] Serial iOS UI Testing Constraint

**Directive:** When running locally, Squad must not run more than one iOS simulator at any given time. All UI tests must run in serial.

**Rationale:** Concurrent local simulator usage can conflict and destabilize UI test runs.

**Impact on Edison:** Build and test scenarios coordinated with other agents must respect single-simulator access during local UI test execution.

## [2026-05-19T23:27:48-07:00] About Calculator Help Overlay

**Session:** about-calculator-help-overlay
**Task:** Apply the same compact `?` pull-up overlay pattern to the "About this calculator" card.

**What changed:**
- `aboutCard` now shows only a compact title + `?` (`questionmark.circle`) button. The long explanatory paragraphs, scope warning block, and non-affiliation disclaimer were removed from the main card.
- Added `@State private var showAboutHelp = false` and a new `.sheet(isPresented: $showAboutHelp)` attached to the NavigationStack.
- New `AboutHelpSheet` private struct renders all the about content (two explanation paragraphs, amber scope warning block, footnote disclaimer) in a scrollable pull-up sheet with `accessibilityIdentifier("about-help-sheet")`.
- VoiceOver: the `?` button carries `accessibilityLabel("About this calculator, more information")` + hint; sheet is fully navigable with Dynamic Type.
- Added `testAboutHelpButtonOpensPullUpSheet` UI test: asserts button exists with correct label, that `two-axis gauge mismatch` text is NOT in the main view, taps button, asserts sheet appears with the text.
- Build passed (exit code 0). No unrelated files touched.

**Pattern generalised:** Both `verdictPanel` and `aboutCard` now follow the same compact title + `?` → sheet convention for reducing clutter in the main scroll view.

## [2026-05-19T23:53:43.824-07:00] About `?` Moved to App Title — About Card Removed

**Session:** about-help-title
**Task:** Remove the standalone "About this calculator" card; place the `?` button directly beside the app title in the `header`.

**What changed:**
- Removed `aboutCard` from `ContentView.body` and deleted the property entirely.
- Updated `header` to wrap the app title + `?` button in an `HStack`. The button still shows `showAboutHelp = true`, triggering the same `AboutHelpSheet` pull-up sheet.
- Title `Text` carries `.fixedSize(horizontal: false, vertical: true)` to prevent truncation on small screens when the button is adjacent.
- Updated `testAboutHelpButtonOpensPullUpSheet`: removed `scrollToElement` (button is now at the top, always visible), replaced `.exists` assertion with `waitForExistence(timeout: 3)` for launch-timing robustness.
- Build succeeded (no compile errors).

**Key learning:** When promoting a contextual help button from a card at an arbitrary scroll position to the title area, always verify Dynamic Type wrapping of the adjacent title — `fixedSize(horizontal: false, vertical: true)` prevents the title from being truncated by the button's minimum tap target (44 pt).

## [2026-05-19T23:53:43-07:00] Removed Privacy Card from About

**Session:** remove-about-privacy-copy
**Task:** Remove privacy/non-tracking card from the main scroll view — analytics are being added so the "no analytics" claim would become false.

**What changed:**
- Removed `privacyCard` reference from `ContentView.body` VStack.
- Deleted the `privacyCard` computed property (SectionTitle "Privacy" + "This app collects nothing…" text).
- Added negative UI assertion in `testAboutHelpButtonOpensPullUpSheet`: `XCTAssertFalse(app.otherElements["privacy-card"].exists)`.
- No replacement privacy/analytics copy added.

**Key learning:** When a truthfulness-limited piece of copy must be removed (not just hidden), delete both the view and its property; a negative assertion in an existing test is sufficient to guard against accidental re-introduction without making the test brittle.

## [2026-05-20T00:00:00Z] Final Help Overlay UI Changes — Reviewed and Approved

**Session:** help-overlays (Help Overlay UI Finalization)
**Reviewer:** Curie (QA)
**Status:** APPROVED

**Summary:** Completed final help overlay UI changes as directed by yashasg:
1. **About `?` Help Overlay** — Applied compact title + `?` → pull-up sheet pattern to About card
2. **About `?` Repositioned** — Removed standalone About card; moved `?` button next to app title in header
3. **Privacy Card Removed** — Eliminated misleading "no analytics" copy; no replacement

**Verification by Curie:**
- Build successful (exit code 0)
- Accessibility verified: VoiceOver labels intact, Dynamic Type support preserved
- UI tests updated and passing
- Share/export functionality preserved
- Math and layout unchanged
- No misleading privacy claims

**Status:** Ready for deployment. All decisions documented in decisions.md.
