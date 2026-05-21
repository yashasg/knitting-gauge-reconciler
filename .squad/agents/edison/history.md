# Edison — History

## Core Context

- **Project:** A knitting gauge reconciler that converts patterns between stitch/row gauges.
- **Role:** Frontend Dev
- **Joined:** 2026-05-19T07:11:08.646Z

## Learnings

### 2026-05-21T12:33:05-07:00 — Equal-Width Inline Mismatch Fields

**Session:** edison-gauge-field-equal-widths

- **Root cause:** `GaugeMeasurementPair` used a plain `HStack` and relied on `.frame(maxWidth: .infinity)` for both children. Once one `GaugeStepperField` gained a mismatch label, that side reported a larger ideal width and SwiftUI distributed the row unevenly, so the opposite field looked narrower.
- **Fix shape:** Swapped the non-accessibility row layout to a two-column `LazyVGrid` with `.flexible(minimum: 0)` columns. That gives the pair explicit equal-width columns in all four mismatch states (`none`, `stitches`, `rows`, `both`) while keeping the mismatch label conditionally rendered below only the offending field.
- **Regression test:** Added `testMismatchStatesKeepYourGaugeFieldsEqualWidth`, which launches the app in all four mismatch combinations and asserts equal field widths plus the correct mismatch-label visibility.
- **SwiftUI pitfall:** `.frame(maxWidth: .infinity)` inside an `HStack` is not an equal-width contract when child ideal widths differ. If one side can grow extra validation copy, use an explicit equal-column container instead of trusting intrinsic sizing.
- **Test result:** 57/57 tests pass, 0 warnings.

**Ive-1 Revised Spec (2026-05-21T12:41:13-07:00):** User directive rejected vertical growth. Ive-1 produced Option D spec (no vertical growth, inline warning glyph in picker affordance, full message in accessibility + picker sheet). This implementation retained below-field label (was acceptable per prior Ive Option B). Follow-up pass will implement Option D:
- Remove below-field mismatch `Text` from `GaugeStepperField` for paired gauge usage.
- Add warning semantics to field/button accessibility payloads.
- Overlay `exclamationmark.triangle.fill` on existing picker button in mismatch state.
- Surface full sentence in wheel-picker sheet/popover.

---

### 2026-05-20T22:32:00-07:00 — Stepper → Wheel Swap (Edison-8)

**Session:** edison-wheel-swap

**Swap shipped:** `GaugeStepperField` + `StepButton` deleted; `GaugeWheelField` + `WheelPickerSheet` added.

**Wheel-in-sheet pattern (iOS idiom):**
- Field renders as a tappable pill (chevron-down affordance). One tap opens a `.sheet(isPresented:)` with `.presentationDetents([.height(320)])`.
- Inside the sheet: `Picker(_, selection: $wheelSelection) { ForEach(1...99, ...) }.pickerStyle(.wheel)`. `Picker(.wheel)` has built-in VoiceOver; no extra accessibility wiring needed.
- Live commit: `.onChange(of: wheelSelection)` writes to the bound `text` String while `isPickerShowing && !isTypeMode`. Standard iOS pattern — value updates behind the open sheet.
- Binding type: kept `String` throughout. The wheel uses `Int` internally and commits via `"\(wheelSelection)"`. The existing `read()` / `GaugeMath.sanitized()` chain in ContentView already handles String → Double. No binding-widening needed.
- This pattern is worth extracting as a team skill (see `.squad/skills/swiftui-wheel-picker-sheet/SKILL.md`).

**Type-mode keyboard fallback:**
- "Type" toggle button inside the sheet (`accessibilityIdentifier: "wheel-picker-type-toggle"`) switches `isTypeMode`. When `true`, the Picker hides and a `TextField(.decimalPad)` appears in the same slot.
- `GaugeMath.parseGaugeTypeText(_ text: String, fallback: Int) -> String` centralises the clamp/decimal logic (new static in GaugeMath.swift, testable).
- Toggling back to Wheel snaps `wheelSelection` to `Int(typedValue.rounded())`.

**UI test protocol for wheel fields:**
- `app.buttons["your-stitches"]` replaces `app.textFields["your-stitches"]` (field is now a Button, not a TextField).
- `picker.adjust(toPickerWheelValue: "32 st")` is the correct XCTest API for wheel pickers. Avoids keyboard-coverage issues that arise when using type-mode in tests. Use this pattern for any future wheel field interaction in UI tests.
- Type-mode keyboard fallback is tested at the unit level via `gaugeWheelFieldTypeFallbackParsesDecimal`, not in UI tests (keyboard interactions in sheets are timing-sensitive).

**Test delta:** +3 unit tests (`wheelFieldClampEnforcesBounds` renamed from `stepperClampEnforcesBounds`, +`gaugeWheelFieldCommitsSelection`, +`gaugeWheelFieldTypeFallbackParsesDecimal`). Net: +2 new tests.

**Build:** `./app/build.sh test` → exit 0, 0 warnings, 24 unit + 2 MetricKit + 7 UITests = all pass.

---

### 2026-05-21T05:22:09Z — Design Pass 7.1–7.7

**Session:** edison-design-pass

**7 items shipped:**

**7.1 — Background texture:**
- Canvas dot grid (`TexturedBackground`). 14pt spacing, 1.2pt radius, 30% opacity. Canvas-based wins over PNG assets: no files to manage, scales device sizes, responds to `AppTheme` tokens.

**7.2 — Card icons + tag:**
- `GaugeInputGroup` takes `icon: String?` + `showPerTag: Bool`. Pattern card = `book.fill`, swatch card = `ruler.fill`. Tag capsule uses `AppTheme.secondary` (brown).

**7.3 — Stepper inputs:**
- `GaugeStepperField` + `StepButton` for all 4 gauge inputs. `GaugeMath.clampedGaugeValue(_:)` pure static clamp (1…999). `.accessibilityAdjustableAction` for VoiceOver swipe. `hasMismatch` colors text + unit + outline in `AppTheme.mismatchText`.

**7.4 — Calculate CTA:**
- `cachedResult: GaugeMathResult?` starts nil; no auto-compute on launch. Stale tracking: `.onChange(of: inputs)` sets `isResultStale = true` only if results exist. Button copy: "Calculate Adjustments" → "Recalculate" when stale. Old results dim to 0.6 opacity. `os_signpost` fires only on Calculate tap — cleaner MetricKit correlation.

**7.5 — Reconciliation card removed + inline mismatch:**
- `GaugeInputs.stitchMismatch`/`rowMismatch` computed booleans. `AppTheme.mismatchText` (red) = factual "IS different"; `warningText` (amber) = advisory "might be wrong". Same RGB as `terracotta` but separate semantic token.

**7.6 — AdjustmentValuePair:**
- Left block: `AppTheme.cream`. Right block: `AppTheme.sage` (dark-green). Delta badge: `AppTheme.secondary` (brown) Capsule. Value identifier (e.g. `"yoke-your-rows"`) on `Text` for UI test targeting.

**7.7 — Numbered circles:**
- `StepCircle` 24pt brown circles with white numbers. Used in `numberedSectionCard` for ①②③ sections.

**Build:** `./app/build.sh test` → exit 0, 0 warnings, 53 tests (46 unit + 7 UI). Was 50 unit tests; +3 new (`stepperClampEnforcesBounds`, `inlineMismatchDetectionMatchVsMismatch`, `inlineMismatchDefaultInputs`).

---

### 2026-05-20T21:29:43-07:00 — UX Cleanup (Notes 1–3)

**Session:** edison-ux-cleanup

**3 notes shipped:**

**Note 1 — Inline units:**
- Card titles: "Pattern gauge (per 10 cm)" (unchanged) / "Your gauge (per 10 cm)" (changed from "Your swatch").
- Inline unit idiom: **`HStack { TextField; Text(unit).fixedSize() }`** inside the pill container. Chose HStack over ZStack overlay because HStack naturally allocates space without needing to hard-code unit-text width as extra padding on the TextField. `inlineUnit: Bool = false` added to `NumberField`; `@ViewBuilder fieldView` dispatches between HStack and plain TextField.
- Abbreviations: `"st"` (stitches) / `"ro"` (rows). `spokenUnit` maps both to full per-10cm VoiceOver strings.

**Note 2 — Card order:**
- `gaugeCard` split into `gaugeInputsCard` (4 gauge fields only) + pattern instructions block moved to top of `adjustmentsCard`. New body order: `gaugeInputsCard → reconciliationCard → adjustmentsCard`.
- Reconciliation was already one card with both axes; `AdaptiveTwoColumnStack` collapses to VStack on phone width naturally.

**Note 3 — Math seam (rows at your gauge):**
- Old formula `adjustedYokeRows = patternYokeDepth × dimensionScale × yourRowsPerCm` algebraically = `patternYokeRows` (always). Wrong — always gave pattern's row count regardless of user gauge.
- New formula: `yokeRowsAtYourGauge = round((patternYokeDepth / 10) × yourRows)` — rows *at your gauge* to cover the pattern's cm.
- New fields on `GaugeMathResult`: `yokeRowsAtYourGauge`, `bodyRowsAtYourGauge`, `sleeveRowsAtYourGauge` (all `Int`). Located in `GaugeMath.compute()`, pure arithmetic, no signpost/MetricKit imports.
- Kept existing `adjustedYokeDepth/adjustedBodyLength/adjustedSleeveLength` and `adjustedYokeRows/etc.` (pinned by existing tests; used in full-math breakdown).
- Display framing: pattern side shows `"20 cm"`, adjusted side shows `"Knit 44 rows"`. Share text: `"• Yoke depth: 20 cm → knit 64 rows"`.

**Build:** `./app/build.sh test` → exit 0, 0 warnings, 50/50 tests (was 49, +1 new `sectionRowsAtYourGaugeMatchFormula`).

---

### 2026-05-20T20:38:28-07:00 — Cleanup Round 2026-05-20

**Session:** cleanup-round (Edison audit + implementation)

**8 items shipped (all code cleanup + 1 P0 correctness fix):**
- **1.1:** TODO marker on MetricsSubscriber diagnostic seam asymmetry (V2 footgun).
- **2.1:** gaugeStatus/rowStatus dedupe (internal in GaugeMath, ContentView copies deleted, ~12 lines removed).
- **2.2:** plain/formatPlain dedupe (canonical plain() internal in GaugeMath, 14 call sites migrated). Divergence flag: `plain()` trims to 2dp; `formatPlain()` uses Swift default. For 3+ decimals: `24.333` → `"24.33"` vs `"24.333"`. All real knitting inputs are integers or 1dp, no user-visible regression.
- **2.3:** HeroMetric.pillBackground dedupe (deleted, all callers use free function sharePillBackground, ~7 lines removed).
- **4.1 (P0):** Signpost inflation fixed. `result` computed property fired `os_signpost(.begin/.end)` 15-20×/body render; now fires 1× per input change via cached `@State var cachedResult` + `.onChange(of: inputs, initial: true) { recomputeResult() }`. Bonus: eliminates per-keystroke GaugeMathResult recomputation.
- **4.2:** AppTheme.tertiary dead color removed (unused).
- **4.3:** AppTheme.warning{Text,Background,Accent} added for AboutHelpSheet scope callout (RGB values unchanged from inline literals).
- **4.4:** Redundant `= nil` stripped from `@State private var previousVerdictBucket: VerdictBucket?`.

**Build:** `./app/build.sh test` → exit 0, 0 warnings, 49/49 tests pass.

**4.1 fix shape choice (Option a):**
- Why `.onChange(of: inputs, initial: true)` over `.task(id: inputs)`: Avoids Swift 6 async/actor isolation; `.onChange` is synchronous main-actor. `initial: true` fires on first appear and every subsequent input change.
- Why option (a) over (b): (a) also eliminates per-keystroke recomputation cost. Bonus performance win beyond signpost correction.
- Signpost correctness verified: no input change → 0 fires; input change → exactly 1 fire.

**2.2 divergence flag:** `plain()` canonical (2dp trim trailing zeros); `formatPlain()` deleted (14 call sites migrated). Verified no real-knitting-value divergence via existing share-text formatter tests (all pass).

---

## 2026-05-20T19:26:30Z — MetricKit V1 Implementation

MetricKit V1 shipped. 9-name signpost roster locked by user directive (2026-05-20T19:26:30). Build: 49/49 tests (was 25). Files created: MetricsSubscriber.swift, GaugeMathMetrics.swift. ContentView.swift: 9 signpost call sites, 2 @State vars. PrivacyInfo.xcprivacy wired.

---

## Earlier Sessions

(See history-archive.md for full timeline of 2026-05-19 and earlier 2026-05-20 work.)

---

## 2026-05-21T00:46:41Z — Pattern Instructions Card Restyle

Replaced all 5 `NumberField` inputs in `patternInstructionsCard` with `GaugeStepperField` (the unified-pill stepper used by Your Gauge / Pattern Gauge cards). Extended `GaugeStepperField` with a configurable `range: ClosedRange<Int>` param (default `1...99` for backward compat). Layout now uses `GaugeMeasurementPair` for two-column rows (yoke+body, sleeve+increases) matching the gauge card layout pattern. State bindings and types unchanged (all `String`). Build: exit 0.

---

## 2026-05-21T01:05:35Z — Structural Refactor: Per-Card File Split

Split monolithic `ContentView.swift` (1373 lines) into 13 separate files. Zero behavior or visual change.

**New file layout:**
```
app/KnittingGaugeReconciler/
  ContentView.swift              ← composition root only (~200 lines)
  Views/
    HomeHeaderView.swift         ← title + about-help button
    GaugeInputsCard.swift        ← PatternGaugeCard + YourGaugeCard structs
    PatternInstructionsCard.swift
    RequiredAdjustmentsCard.swift ← incl. AdjustmentRow (private), fullMathBreakdown, numberedSectionCard, actionsCard
  Components/
    AppTheme.swift               ← AppTheme enum + cardStyle view extension
    TexturedBackground.swift
    GaugeStepperField.swift
    AdjustmentValuePair.swift
    StepCircle.swift
    GaugeMeasurementPair.swift
    GaugeInputGroup.swift
    SectionTitle.swift
```

**Binding/closure pattern:**
- All `@State` vars remain in `ContentView`
- Card inputs passed as `@Binding` (mutable fields) or `let` (read-only display data like `cachedResult`, `isResultStale`, `inputs`)
- Actions dispatched via closures: `onRecalculate: () -> Void`, `onReset: () -> Void`, `onShare: (GaugeMathResult) -> Void`
- `RequiredAdjustmentsCard` takes `@Binding var showFullMath: Bool` for the disclosure toggle

**pbxproj registration:**
- Project uses manual pbxproj (no PBXFileSystemSynchronized groups)
- Added PBXFileReference entries (IDs 020-031), PBXBuildFile entries (IDs 120-131)
- Added PBXGroup entries for `Views` (ID 710) and `Components` (ID 720) under the main KnittingGaugeReconciler group
- Updated PBXSourcesBuildPhase (ID 901) files list

**Private helpers kept in ContentView:** `GaugeTextDefaults`, `SharePayload`, `VerdictHelpSheet`, `AboutHelpSheet`, `ActivityView`, `ResultsShareCard` family, `GaugeTextDefaults`, `initialText/Bool/read/sharePillBackground` helpers, `NumberField` (legacy/unused), `AdaptiveTwoColumnStack` (legacy/unused)

**Build:** exit 0, 0 warnings. All 8 UI tests + 41 unit tests pass via `./build.sh test`.

**Gotcha:** `testAllJacquardScenariosAreVisibleInUI` is sensitive to simulator timing when run in parallel (180s timeout); passes consistently with `build.sh` which uses `-test-iterations 2` and avoids parallel contention.
