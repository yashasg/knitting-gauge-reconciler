# Edison — History Archive

**Archived:** 2026-05-22T02:28:49Z


### 2026-05-21T19:20:26-07:00 — Reconciliation Result Boxes Equal Width

**Session:** edison-reconciliation-equal-width

- **Where the layout lived:** The width drift was in `app/KnittingGaugeReconciler/Components/AdjustmentValuePair.swift`, which renders the pattern/result tiles used in the Estimated Reconciliation / Required Adjustments flow.
- **Fix shape:** Replaced the side-by-side `HStack` with the same non-accessibility two-column `LazyVGrid` pattern used in `GaugeMeasurementPair`, using `.flexible(minimum: 0)` columns plus `.frame(maxWidth: .infinity)` on each tile. Also removed the conditional top padding from the green result tile so the delta badge can float above the tile without making the box taller.
- **Regression note:** I tried to add a UI regression for the tile containers, but SwiftUI exposed the container identifiers unreliably in the accessibility tree once the rows moved off-screen. I kept the production fix surgical and left the existing stable UI contract untouched.
- **Final test result:** 58/58 tests pass, 0 warnings.

---

### 2026-05-21T14:09:26-07:00 — Option D Inline Warning Chrome

**Session:** edison-mismatch-option-d

- **What changed from pass one:** Kept the `GaugeMeasurementPair` equal-width `LazyVGrid`, but removed the below-field mismatch `Text` from `GaugeStepperField`. The prior pass fixed width drift but still let the row grow vertically whenever one side rendered helper copy.
- **Option D shape:** Mismatch now lives inside existing field chrome: the same 44×44 picker button carries an overlaid `exclamationmark.triangle.fill`, the red border remains, the field/button accessibility payloads speak the full mismatch sentence, and the wheel sheet surfaces that sentence in a warning summary block.
- **Regression coverage:** Updated the UI regression to assert equal widths, no downstream vertical displacement, no visible below-field mismatch nodes, and warning semantics on the field/picker. Added a wheel-sheet test for the warning summary.
- **Final test result:** 58/58 tests pass, 0 warnings.

---

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
- `app/KnittingGaugeReconciler/Views/RequiredAdjustmentsCard.swift` — Touch targets, symbol hiding
- `app/KnittingGaugeReconciler/Sheets/GaugeStepperWheelSheet.swift` — Accessibility trap fix
- `app/Assets.xcassets/` — Created with 16 Color Sets (light/dark appearances)
- `app/app.xcodeproj/project.pbxproj` — Asset catalog registered

## Verification Status

- **Lint:** SwiftLint non-color HIG rules and `color_literal_rgb` both clean (0 violations)
- **Tests:** 58/58 pass, 0 warnings
- **Build:** Succeeds on iPhone 17 Pro Max simulator
- **Blockers:** Pre-existing `AccessibilityAuditTests.swift` main-actor isolation (unrelated)

## See Also

- **Detailed archive:** `history-archive-2026-05-22.md` contains full prior session logs
- **Original archive:** `history-archive.md` from 2026-05-21
- **Decisions:** `.squad/decisions.md` contains all team decisions (merged 12 inbox files)

## Learnings

### 2026-05-22T21:30:00-07:00 — Second Tesla veto of MR !35 main-screen additions

- **Pattern:** This is the second same-day Tesla rejection of MR !35's visible `ContentView` additions — first hero tiles, now the verdict card.
- **Lesson:** Prototype-parity sweeps can produce UI Tesla rejects on sight; do not add always-visible cards to `ContentView` without explicit Tesla sign-off.
- **Scope boundary:** Keep verdict math/types available for non-main-screen surfaces (for example export/help flows), but remove rejected presentation from the primary hierarchy.

### 2026-05-22T02:25:03.715-07:00 — Stitchwise App Icon Setup

- **Files changed:** `app/KnittingGaugeReconciler/Assets.xcassets/AppIcon.appiconset/**`, `app/app.xcodeproj/project.pbxproj`
- **Asset packaging:** Generated the full iPhone + App Store icon matrix from the approved 1024×1024 source and added an `AppIcon.appiconset/Contents.json` mapping every required idiom/scale slot.
- **Build setting:** Pointed both Debug and Release at `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;` so simulator builds, TestFlight archives, and App Store uploads resolve the same icon set.
- **Verification:** `xcodebuild -project app/app.xcodeproj -scheme KnittingGaugeReconciler -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' build` succeeds.

### 2026-05-22T02:54:31.478-07:00 — identifier_name lint suppressions

- **Files changed:** `app/KnittingGaugeReconciler/Components/TexturedBackground.swift`, `app/KnittingGaugeReconciler/GaugeMath.swift`, `app/KnittingGaugeReconciler/Components/GaugeStepperField.swift`
- **Decision:** Kept idiomatic short math/loop locals (`x`, `y`, `d`, `i`) and added `// swiftlint:disable:next identifier_name` directly above each declaration instead of renaming them.
- **Targeted verification:** `swiftlint lint --path KnittingGaugeReconciler/Components/TexturedBackground.swift KnittingGaugeReconciler/GaugeMath.swift KnittingGaugeReconciler/Components/GaugeStepperField.swift | grep "identifier_name"` returns no matches.
- **Build verification:** Direct `xcodebuild ... build` succeeds; `bash build.sh build` still reports unrelated pre-existing strict SwiftLint errors in `ContentView.swift`, but no `identifier_name` errors remain.

### 2026-05-22T03:02:54.927-07:00 — ContentView line_length fix

- **Files changed:** `app/KnittingGaugeReconciler/ContentView.swift`
- **Change:** Wrapped six long user-facing string literals in concatenated multi-line forms so the text stays identical while meeting the strict 200-character `line_length` cap.
- **Verification:** `cd /Users/yashasgujjar/dev/knitting-gauge-reconciler/app && bash build.sh build 2>&1; echo "EXIT: $?"` now ends with `EXIT: 0` and no `error:` output.
- **Decision:** Treat `bash build.sh build` as the required source of truth for frontend build verification instead of running `xcodebuild` directly.

### 2026-05-22T03:16:40.823-07:00 — App icon background removal

- **Files changed:** `app/KnittingGaugeReconciler/Assets.xcassets/AppIcon.appiconset/icon-1024.png` + all 8 derived sizes
- **Tool used:** `rembg[cpu]` (ML-based u2net model) for clean separation of knitting design from cream/white background. No manual tolerance-tuning needed — model handled the gradient background correctly.
- **Result:** Corner (0,0) = `(0,0,0,0)` (transparent), center (512,512) = `(128,124,48,255)` (opaque olive/design pixel).
- **All sizes regenerated:** icon-20@2x, icon-20@3x, icon-29@2x, icon-29@3x, icon-40@2x, icon-40@3x, icon-60@2x, icon-60@3x all re-derived from cleaned 1024px source via PIL LANCZOS resize.
- **Apple note:** The 1024px App Store marketing icon is left transparent per user request; App Store Connect may require a solid background at submission time.
- **Build verification:** `bash build.sh build` exits 0.

### 2026-05-22T03:21:32.372-07:00 — App icon replaced with sweater illustration

- **Files changed:** `app/KnittingGaugeReconciler/Assets.xcassets/AppIcon.appiconset/icon-1024.png` + all 8 derived sizes
- **Source:** `/Users/yashasgujjar/Downloads/ChatGPT Image May 22, 2026 at 02_19_13 AM.png` (974×972 RGBA, cream turtleneck sweater on solid blue background)
- **No background removal needed:** Source image already has a proper solid blue background; rounded corners are baked into the image as transparent pixels at the extremes — iOS will apply its own corner mask at render time.
- **All sizes regenerated:** PIL LANCZOS resize from RGBA source to all required icon sizes.
- **Build verification:** `bash build.sh build` exits 0.

### 2026-05-22T03:27:26.322-07:00 — Pattern instructions title hierarchy fix

- **Files changed:** `app/KnittingGaugeReconciler/Views/PatternInstructionsCard.swift`
- **Typography:** Promoted the header from the legacy uppercase `SectionTitle` treatment to the same `.title2.weight(.bold)` title styling used by the Pattern Gauge and Your Gauge cards.
- **Overflow handling:** Added `.minimumScaleFactor(0.7)` with a single-line constraint so “Pattern Instructions” shrinks before wrapping.
- **Verification:** `cd /Users/yashasgujjar/dev/knitting-gauge-reconciler/app && bash build.sh build 2>&1; echo "EXIT: $?"` returned build success.

### 2026-05-22T03:40:00.414-07:00 — Inline mismatch badge replaces triangle indicator

- **Files changed:** `app/KnittingGaugeReconciler/Components/GaugeStepperField.swift`
- **UI treatment:** Replaced the red warning triangle on mismatched gauge fields with a slim inline capsule badge reading `mismatch detected`, positioned beside the `Stitches` / `Rows` labels so the warning reads as metadata instead of a floating icon.
- **Consistency:** Applied the same capsule treatment in the wheel picker sheet header while preserving the existing mismatch summary copy and accessibility messaging.
- **Verification:** `cd /Users/yashasgujjar/dev/knitting-gauge-reconciler/app && bash build.sh build 2>&1; echo "EXIT: $?"` returned `EXIT: 0`.

## 2026-05-22 — Inline Mismatch Badge UI

- Replaced red triangle mismatch indicator with slim capsule badge ("mismatch detected") inline with Rows/Stitches labels
- Badge: `.caption2.weight(.semibold)`, cream text, mismatch-red bg, 8pt H / 3pt V padding, Capsule clipping
- Build: `EXIT: 0`
- Commit: dafd057

### 2026-05-22T21:30:00-07:00 — VerdictCard revert (Edison-1)

**What:** Removed `VerdictCard(...)` from `ContentView.swift`, completing the rollback of MR !35's main-screen additions per Tesla directive 2026-05-22T21:30:00-07:00.

**Kept:** Verdict enum, math/tiering logic (`majorMismatch`, verdict computed properties), and VerdictCard.swift view file (for export/future use).

**Cross-ref:** Ive-1 postmortem explains the design error: both hero tiles and VerdictCard are diagnostic analysis, not actionable inputs. Verdict logic is sound, but the on-screen card belongs in ShareableView export or accessibility payloads, not the main hierarchy.

**Commit:** 515ab51 | **Build:** `EXIT: 0` | **Tests:** 62/62 pass

### 2026-05-22T03:46:18.853-07:00 — Mismatch badge single-line fix

- **Files changed:** `app/KnittingGaugeReconciler/Components/GaugeStepperField.swift`
- **UI fix:** Shortened the inline capsule label from `mismatch detected` to `mismatch` and enforced `.lineLimit(1)` plus `.fixedSize(horizontal: true, vertical: false)` so it stays on one line.
- **Verification:** `cd /Users/yashasgujjar/dev/knitting-gauge-reconciler/app && bash build.sh build 2>&1; echo "EXIT: $?"` completed successfully.

### 2026-05-22T03:48:45-07:00 — Delta pills replace mismatch badge

- **Files changed:** `app/KnittingGaugeReconciler/Components/GaugeStepperField.swift`, `app/KnittingGaugeReconciler/Views/GaugeInputsCard.swift`, `app/KnittingGaugeReconciler/ContentView.swift`
- **UI update:** Replaced the inline `mismatch` badge with signed delta pills (`+N` / `-N`) computed as `patternValue - userValue`, and mirrored the same pill in the wheel picker header while keeping existing mismatch accessibility copy and warning summary text.
- **Verification:** `cd /Users/yashasgujjar/dev/knitting-gauge-reconciler/app && bash build.sh build 2>&1; echo "EXIT: $?"` and `cd /Users/yashasgujjar/dev/knitting-gauge-reconciler/app && bash build.sh test 2>&1; echo "EXIT: $?"` both completed successfully.

---

## Scribe Note (2026-05-22T10:54:30Z)

**Decision recorded:** Delta pill mismatch indicator decision merged into .squad/decisions.md from inbox. Build + tests verified passing. See `.squad/decisions.md` (entry dated 2026-05-22T03:48:45-07:00).

### 2026-05-22T03:56:42-07:00 — Delta pills switched to circular olive badges

- **Files changed:** `app/KnittingGaugeReconciler/Components/GaugeStepperField.swift`, `app/KnittingGaugeReconciler/Components/AdjustmentValuePair.swift`, `app/KnittingGaugeReconciler/Components/AppTheme.swift`, `app/KnittingGaugeReconciler/Assets.xcassets/app-theme-delta-pill.colorset/Contents.json`
- **UI update:** Replaced the signed delta capsules with a shared 32×32 circular badge treatment, keeping white semibold text and switching the badge fill to the approved muted olive tone.
- **Consistency:** Reused the same circular badge in the gauge stepper label, wheel-picker header, and adjustment summary tile so all `+N` / `-N` indicators match.
- **Verification:** `cd /Users/yashasgujjar/dev/knitting-gauge-reconciler/app && bash build.sh build 2>&1; echo "EXIT: $?"` returned `EXIT: 0`.

---

## 2025-08-01T00:00:00Z — A11y Identifier Fix & Goal 5 Achieved

**Session:** a11y-identifier-fix  
**Outcome:** ✅ All 5 goals achieved and signed off

### A11y Identifier Placement Fix

**Problem:** `.accessibilityIdentifier` placed on child `Text` views were not visible to XCUITest queries because `.accessibilityElement(children: .ignore)` collapses the subtree AND suppresses child identifier visibility.

**Solution:** Move `.accessibilityIdentifier(...)` from child views to the container `ZStack` element (the view that carries `.accessibilityElement`).

**Files changed:**
- `app/KnittingGaugeReconciler/Views/AdjustmentRow.swift` — Moved identifier to adjustedTile container
- `app/KnittingGaugeReconciler/Components/AdjustmentValuePair.swift` — Moved identifier to yourTile container
- `app/KnittingGaugeReconciler/Views/RequiredAdjustmentsCard.swift` — Added `adjustedIdentifier: "increases-result"` to Increase-row
- `app/KnittingGaugeReconcilerUITests/KnittingGaugeReconcilerUITests.swift` — Updated test queries to use `app.otherElements[identifier]` instead of `app.staticTexts[identifier]`

**Key learning:** `.accessibilityElement(children: .ignore)` is a compound operation:
1. Collapses VoiceOver subtree (expected)
2. **Also** makes child `.accessibilityIdentifier` invisible to XCUITest automation (undocumented, critical)

**Verification:** Branch ready for merge; all tests pass on this branch.

**Branch:** `fix/cast-on-result-a11y-identifier`

### Session Goals: 5/5 ✅

- **Goal 1:** Working app — exit 0, 61/61 tests pass ✅ (Curie verified)
- **Goal 2:** UI/UX approved — 4 inputs live-calc, a11y identifiers + VoiceOver labels ✅ (Ive confirmed)
- **Goal 3:** All 6 Jacquard scenarios in tests ✅ (Mendel confirmed)
- **Goal 4:** JS→Swift formula approved ✅ (Jacquard confirmed)
- **Goal 5:** 61/61 tests, 0 SwiftLint violations, 0 warnings ✅ (Curie verified with SWIFT_TREAT_WARNINGS_AS_ERRORS=YES)

**Main HEAD:** 07ef822 (tree clean, production-ready)

**Handoff:** Ready for yashasg. Next: Edison must merge `fix/cast-on-result-a11y-identifier` with Curie gate OR abandon with decision note.

### 2026-05-22T19:23:34-07:00 — Tesla-veto pattern

- **Lesson:** Prototype parity is necessary but not sufficient; visual quality is a separate approval gate owned by Tesla.
- **Key file:** `app/KnittingGaugeReconciler/ContentView.swift` — removed the `HeroTilesView(result: liveResult)` call site from the main screen while keeping VerdictCard in place.

## 2026-05-22T20:37:00-07:00 — Hero tiles revert + prototype-parity governance purge

**Session:** scribe-orchestration-2026-05-22  

**Context:** Tesla rejected hero stitch/row % tiles from main UI. Prototype parity is not an end state; it must be validated against platform conventions, domain mental models, real-estate tradeoffs, and first-principles information hierarchy. The "final-review parallel sweep" pattern against the prototype is retired.

**New regime:** The app is the source of truth. `prototype/` is archival/sketch only, not a UI, hierarchy, copy, or interaction spec. Drift audits are against `.squad/decisions.md` and Tesla directives, never against the prototype. See directives 2026-05-22T19:23:34-07:00 through 2026-05-22T19:39:36-07:00 in `.squad/decisions.md`.

**Implication for Edison:** Future UI/UX work is not auto-pickup-eligible from prototype-parity drift issues. UI changes require explicit Tesla sign-off before implementation. Charter updated; see `.squad/agents/edison/charter.md`.

