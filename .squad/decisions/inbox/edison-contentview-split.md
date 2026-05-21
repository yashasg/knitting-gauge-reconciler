# Decision: ContentView Structural Split

**Date:** 2026-05-21  
**Author:** Edison (SwiftUI implementer)  
**Status:** Shipped

## Final File Structure

```
app/KnittingGaugeReconciler/
  ContentView.swift              ← composition root: @State, recomputeResult, body, sheet modifiers
  GaugeMath.swift                ← untouched
  GaugeMathMetrics.swift         ← untouched
  MetricsSubscriber.swift        ← untouched
  KnittingGaugeReconcilerApp.swift ← untouched
  Views/
    HomeHeaderView.swift         ← title + about-help button
    GaugeInputsCard.swift        ← PatternGaugeCard + YourGaugeCard structs
    PatternInstructionsCard.swift ← 5 stepper fields for cast-on, yoke, body, sleeve, increases
    RequiredAdjustmentsCard.swift ← header+button, result sections, actionsCard, fullMathBreakdown
  Components/
    AppTheme.swift               ← AppTheme color enum + cardStyle() view extension
    TexturedBackground.swift     ← canvas dot-grid background
    GaugeStepperField.swift      ← unified pill stepper ([- value +])
    AdjustmentValuePair.swift    ← left (oatmeal/pattern) + right (sage/your) value blocks
    StepCircle.swift             ← numbered circle badge
    GaugeMeasurementPair.swift   ← adaptive 2-column layout for stepper pairs
    GaugeInputGroup.swift        ← card wrapper with icon + PER tag header
    SectionTitle.swift           ← uppercase section label
```

Private to ContentView (not extracted): `GaugeTextDefaults`, `SharePayload`, `VerdictHelpSheet`, `AboutHelpSheet`, `ActivityView`, `ResultsShareCard` family, `NumberField` (legacy), `AdaptiveTwoColumnStack` (legacy).

## State Ownership Rule

**All `@State` lives in `ContentView`.** Card views are stateless — they receive values from ContentView and report actions back via bindings/closures.

- Read-only display data → `let` props (e.g., `var cachedResult: GaugeMathResult?`, `var isResultStale: Bool`, `var inputs: GaugeInputs`)
- Mutable user input → `@Binding` (e.g., `@Binding var patternStitches: String`)
- Toggle state owned by parent → `@Binding` (e.g., `@Binding var showFullMath: Bool`)

## Action Dispatch Rule

**Actions dispatched via closures from ContentView.** Cards never call ContentView functions directly.

Pattern:
```swift
// In RequiredAdjustmentsCard:
var onRecalculate: () -> Void
var onReset: () -> Void
var onShare: (GaugeMathResult) -> Void

// Instantiated in ContentView.body:
RequiredAdjustmentsCard(
    ...
    onRecalculate: recomputeResult,
    onReset: resetToDefaults,
    onShare: { result in shareResults(result: result) }
)
```

Business logic (`recomputeResult`, `resetToDefaults`, `shareResults`, signpost calls) stays in ContentView.

## How to Edit Individual Cards

- **To edit the Pattern Gauge or Your Gauge card** → edit `Views/GaugeInputsCard.swift` only
- **To edit the Pattern Instructions card** → edit `Views/PatternInstructionsCard.swift` only
- **To edit the Required Adjustments card** (including Recalculate button, results sections, full math, reset, share) → edit `Views/RequiredAdjustmentsCard.swift` only
- **To edit the app header** → edit `Views/HomeHeaderView.swift` only
- **To add a new @State var or a new card** → also edit `ContentView.swift`
- **To edit a shared component** (stepper, value pair, etc.) → edit the relevant `Components/` file

**Never touch ContentView.swift** to edit card layout or styling.

## Pbxproj Registration

Project uses **manual pbxproj** (not PBXFileSystemSynchronized). New files require:
1. `PBXFileReference` entry in the `PBXFileReference` section
2. `PBXBuildFile` entry in the `PBXBuildFile` section  
3. File reference added to the appropriate `PBXGroup` (710=Views, 720=Components)
4. Build file ID added to `PBXSourcesBuildPhase` (ID `000000000000000000000901`) files list

ID conventions used: file refs 020-031, build files 120-131. Next available: 032/132+.

The `Views/` and `Components/` subdirectories have corresponding PBXGroup entries (IDs 710 and 720) under the main KnittingGaugeReconciler group (ID 701).
