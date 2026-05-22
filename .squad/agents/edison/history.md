# Edison — History

## Core Context

- **Project:** A knitting gauge reconciler that converts patterns between stitch/row gauges.
- **Role:** Frontend Dev
- **Joined:** 2026-05-19T07:11:08.646Z

## Learnings

### 2026-05-21T19:20:26-07:00 — Reconciliation Result Boxes Equal Width

**Session:** edison-reconciliation-equal-width

- **Where the layout lived:** The width drift was in `app/KnittingGaugeReconciler/Components/AdjustmentValuePair.swift`, which renders the pattern/result tiles used in the Estimated Reconciliation / Required Adjustments flow.
- **Fix shape:** Replaced the side-by-side `HStack` with the same non-accessibility two-column `LazyVGrid` pattern used in `GaugeMeasurementPair`, using `.flexible(minimum: 0)` columns plus `.frame(maxWidth: .infinity)` on each tile. Also removed the conditional top padding from the green result tile so the delta badge can float above the tile without making the box taller.
- **Regression note:** I tried to add a UI regression for the tile containers, but SwiftUI exposed the container identifiers unreliably in the accessibility tree once the rows moved off-screen. I kept the production fix surgical and left the existing stable UI contract untouched.
- **Final test result:** 58/58 tests pass, 0 warnings.

---

## Archive

See `history-archive.md` for earlier 2026-05-21 and 2026-05-20 entries.
