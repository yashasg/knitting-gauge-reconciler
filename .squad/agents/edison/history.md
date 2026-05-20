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
