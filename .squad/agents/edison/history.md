# Edison — History

## Core Context

- **Project:** A knitting gauge reconciler that converts patterns between stitch/row gauges.
- **Role:** Frontend Dev
- **Joined:** 2026-05-19T07:11:08.646Z

## Current Status (2026-05-31)

**Latest work:** 
1. **SwiftLint UI cleanup** — 5 files, 0 violations
2. **Async share-image flow** — non-blocking, detached file write
3. **Share branding rename** — "Stitchwise" across all surfaces

**Verification:** Build EXIT: 0, 0 warnings, tests 62/62 pass, SwiftLint 0 violations.

## This Session (2026-05-31)

### SwiftLint UI Source Cleanup (Commit 08f8a70)

- `AdjustmentValuePair.swift`, `GaugeMeasurementPair.swift` — removed trailing commas
- `HeroTilesView.swift`, `GaugeStepperField.swift` — replaced disable commands with EdgeInsets
- `MetricsSubscriber.swift` — `// V2 (deferred):` instead of `// TODO(V2):`

**Key insight:** Auto-discovery mode doesn't consistently load disabled_rules. Fix patterns in source, not inline disables.

### Async Share-Image Flow (Commits b36d9be, 1f65536)

- ImageRenderer + pngData encoding on @MainActor (required)
- File write to Task.detached(priority: .userInitiated)
- Re-entrancy guard: @State isPreparingShare in AdjustmentSheetView
- Share button shows ProgressView while preparing
- All contracts (accessibility, metrics, signposts) preserved

### Share Branding: "Stitchwise" (Commit d506c12)

- ShareableView.swift footer → "Stitchwise"
- GaugeMath.swift ResultsExportSummary.title → "Stitchwise"
- Tests updated for branding consistency

## Learnings

- **Async share-image constraint:** ImageRenderer is @MainActor-isolated
- **pngData encoding:** Co-located on main to avoid capturing UIImage across detached boundary
- **Prototype-parity:** Necessary but not sufficient — visual quality/hierarchy is separate approval gate
- **Accessibility:** `.accessibilityElement(children: .ignore)` suppresses child visibility in XCUITest
- **Nav title:** `NavigationStack(.navigationTitle(...))` in ContentView.swift auto-centers/scales on scroll

## Verification Status

- **Build:** iPhone 17 Pro / Pro Max simulator, EXIT: 0
- **Tests:** 62/62 pass (49 Swift Testing + 13 XCTest UI)
- **Lint:** 0 violations
- **Compiler:** 0 warnings (SWIFT_TREAT_WARNINGS_AS_ERRORS=YES)

## See Also

- **Archive:** `history-archive.md` — prior sessions (2026-05-23 VerdictCard, 2026-05-22 Delta Pills, earlier)
- **Decisions:** `.squad/decisions.md`
