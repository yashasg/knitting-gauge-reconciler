# Edison — History

## Core Context

- **Project:** A knitting gauge reconciler that converts patterns between stitch/row gauges.
- **Role:** Frontend Dev
- **Joined:** 2026-05-19T07:11:08.646Z

## Current Status (2026-06-01)

**Latest work:**
1. **SwiftLint UI cleanup** — 5 files, 0 violations
2. **Async share-image flow** — non-blocking, detached file write
3. **Share branding rename** — "Stitchwise" across all surfaces
4. **cm/in unit toggle Phase 1** — MR !42, issue #50 Phase 1 complete

**Verification:** Build EXIT: 0, 0 warnings, tests 39/39 unit pass, SwiftLint 0 violations.

## This Session (2026-05-31)

### cm/in Unit Toggle — Phase 1 (MR !42, issue #50)

**Branch:** `squad/50-unit-toggle-phase1`

New files/changes:
- `MeasurementUnit.swift` — enum with `.centimeters`/`.inches`, label, `cmToDisplayInt`, `displayIntToCmString`, `displayRange(from:)`, `formatMeasurement`
- `ContentView.swift` — `@AppStorage("measurementUnit")`, `UnitToggleView` segmented Picker
- `PatternInstructionsCard.swift` — `unit` param, `displayBinding(for:)`, dynamic field titles
- `RequiredAdjustmentsCard.swift` — threads `unit` through to `fullMathBreakdown`
- `GaugeMath.swift` — `ResultsExportSummary`, `ResultsShareTextFormatter` accept `unit` (default `.centimeters`)
- 13 new unit tests (`MeasurementUnitTests`), 1 UI test (`testUnitToggleSwitchesFieldLabel`)
- Fixed pre-existing UITest compile error in `testMismatchWarningSummaryAppearsInWheelSheet`

**Architecture:** cm is canonical storage; toggle is display/entry only; rounding to nearest whole inch.



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

- **cm/in unit toggle pattern:** Internal model always cm. Conversion binding only at display/entry boundary (`Binding<String>` with `get: cm→display, set: display→cm`). `@AppStorage` works with `RawRepresentable where RawValue == String` (iOS 14+). `GaugeStepperField` range must also be converted via `unit.displayRange(from:)`.
- **Async share-image constraint:** ImageRenderer is @MainActor-isolated
- **pngData encoding:** Co-located on main to avoid capturing UIImage across detached boundary
- **Prototype-parity:** Necessary but not sufficient — visual quality/hierarchy is separate approval gate
- **Accessibility:** `.accessibilityElement(children: .ignore)` suppresses child visibility in XCUITest
- **Nav title:** `NavigationStack(.navigationTitle(...))` in ContentView.swift auto-centers/scales on scroll
- **UIKit scene-walk under XCUITest:** Filter `connectedScenes` by `UIWindowScene` but NOT by `.foregroundActive` — during XCUITest the scene is `.foregroundInactive`, so activation-state guards silently drop the sheet. Use `compactMap` to get the key window, then walk `.presentedViewController`. See `.squad/skills/uikit-scene-walk-xcuitest/SKILL.md`.
- **WCAG contrast in dark mode:** Always check the simulator appearance (`xcrun simctl ui <UDID> appearance`) before debugging contrast failures — a dark-mode sim with light-mode math gives false passes. The `app-theme-sage` dark value was `(0.560, 0.700, 0.530)` → 2.12:1 with cream (❌), fixed to `(0.365, 0.455, 0.360)` → 4.58:1 cream-on-sage (✅) and 3.12:1 sage-on-card-dark for large text (✅).
- **Asset catalog recompile pitfall:** `xcodebuild` may skip recompiling `Assets.car` when only a `.colorset` JSON changes if derived data is stale. Delete the derived data root (`rm -rf app/.build/derived-data` or default Xcode DerivedData) to force a clean asset compile. Verify with `ls -la` on the `.app/Assets.car` timestamp after build.
- **ViewThatFits reflow pattern (Dynamic Type):** `ViewThatFits(in: .horizontal)` measures child ideal size; first child that fits in the available width is used. Provide preferred layout (HStack side-by-side) first, fallback layout (VStack stacked) second. `Spacer()` inside a child HStack is safe — its ideal size is 0, so the HStack's ideal width is only the sum of non-flexible children. Use this for header/badge layouts where a pill or tag must not overflow. Decorative elements keep `.accessibilityHidden(true)` in all branches.
- **Pill fallback judgment:** The delta-pill (`DeltaPillBadge`) uses `.fixedSize(horizontal: true, vertical: false)` — it insists on its full intrinsic width regardless of available space. Combined with an inline `HStack` at AX5, overflow is near-certain. `ViewThatFits` VStack fallback required. The drift-pill is in a `ZStack` overlay — the overlay pattern absorbs larger sizes gracefully without structural break; no `ViewThatFits` needed.
- **AX5 preview:** Use `#Preview("AX5") { ... }.environment(\.dynamicTypeSize, .accessibility5)` to visually verify reflow in Xcode canvas without running the simulator.
- **Files touched (Dynamic Type elastic layout):** `GaugeInputGroup.swift`, `GaugeStepperField.swift`, `AdjustmentRow.swift`, `PatternInstructionsCard.swift`, `AccessibilityAuditTests.swift`

## Verification Status

- **Build:** iPhone 17 Pro / Pro Max simulator, EXIT: 0
- **Tests:** 62/62 pass (49 Swift Testing + 13 XCTest UI)
- **Lint:** 0 violations
- **Compiler:** 0 warnings (SWIFT_TREAT_WARNINGS_AS_ERRORS=YES)

## This Session (2026-06-02)

### Issues #48 & #49 — Gauge Delta Flip + Adjusted Tile Copy (Commit 4351ae9, MR !41)

**#48 — Delta sign:** Flipped `ContentView.swift` delta from `Pattern − Your` to `Your − Pattern`. Your=20 vs Pattern=32 now shows −12 badge. Mismatch highlight uses `!=` (sign-agnostic) — no warning logic inverted.

**#49 — Adjusted tile copy:** `RequiredAdjustmentsCard.swift` Shaping Rates section:
- Increase-row spacing adjusted: `"Space every N rows/rounds"` → `"Every N rows"` (matches input tile)
- Cast-on adjusted: `"Cast on N stitches"` → `"N stitches"` (matches input tile)
- Removed now-unnecessary `swiftlint:disable:next line_length` comment
- Share/export strings in `GaugeMath.swift` left verbose per approved decision

**UI test updates:** `KnittingGaugeReconcilerUITests.swift` — 6 scenario `increases` strings updated; cast-on label assertions updated to drop "Cast on " prefix (2 locations).

**Build/Test:** BUILD SUCCEEDED + all unit tests pass (iPhone 15 simulator).

**Learning:** When flipping a sign in delta computation, always audit `> 0` / `< 0` branch conditions on the consumer side. Here `hasMismatch` used `!=` so was safe. Badge formatting `>= 0 ? "+" : ""` also sign-correct post-flip.

## See Also

- **Archive:** `history-archive.md` — prior sessions (2026-05-23 VerdictCard, 2026-05-22 Delta Pills, earlier)
- **Decisions:** `.squad/decisions.md`

---

## Session Update (2026-06-03T01:27:43Z)

**Ive audit:** minimumScaleFactor(0.7) accessibility concern resolved. Tokenization recommended for consistency & documentation. No behavior change required.

**Token recommendation:** Extract to AppTheme.minimumScaleFactor. Update:
- GaugeInputGroup.swift:33
- PatternInstructionsCard.swift:41

This is optional follow-up work; current behavior is a11y-correct.

---

## PENDING WORK ORDER | 2026-06-03 (ELASTIC LAYOUT — SUPERSEDES PRIOR)

**From:** Ive (UI/UX)  
**Scope:** Dynamic Type Elastic Layout — Remove ALL minimumScaleFactor + dynamicTypeSize caps; implement ViewThatFits for reflow  
**Status:** Awaiting Yashas approval  
**Research Validation:** 2026-06-03T01:47:58Z — Ive completed accessibility research. Apple WWDC citations confirm elastic-layout principle is HIG-sanctioned. ViewThatFits is the correct solution. Research-backed decision ready for implementation.

**SUPERSEDES:** Prior 2026-06-02 order (hide-at-accessibility-sizes pattern). **This is the new approach.**

**Work order:**
1. `GaugeInputGroup.swift:33` — **DELETE** `.minimumScaleFactor(0.7)`
2. `GaugeInputGroup.swift:42` — **DELETE** `.dynamicTypeSize(...DynamicTypeSize.accessibility1)` cap
3. `GaugeStepperField.swift:28` (DeltaPillBadge) — **DELETE** `.dynamicTypeSize(...DynamicTypeSize.accessibility1)` cap
4. `AdjustmentRow.swift:87` — **DELETE** `.dynamicTypeSize(...DynamicTypeSize.accessibility1)` cap (drift pill)
5. **GaugeInputGroup header refactor:** Replace HStack with `ViewThatFits(in: .horizontal)` for side-by-side → stacked reflow
   - Side-by-side at xSmall–xxxLarge (unchanged)
   - Tag wraps below title at AX1–AX5
   - Add `@Environment(\.dynamicTypeSize)` for potential future use
6. **Delta/drift pills:** Remove cap; acceptable overlap at AX5. Add VStack fallback only if device testing shows visual breakage.
7. **Test:** UI tests at AX5. Verify no text truncation. Verify VoiceOver labels intact.

**Key principle:** Text always renders at user's exact chosen size. Layout reflows (never shrinks).

**Full spec:** `.squad/decisions/decisions.md` (merged 2026-06-03T01:41:25Z)  
**Orchestration:** `.squad/orchestration-log/2026-06-03T01:41:25Z-ive.md`

**STATUS: COMPLETED 2026-06-02T18:32:46-07:00 — MR !43**
