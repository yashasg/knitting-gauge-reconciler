# iOS 26.4 UI Test Regression Triage

**Date:** 2026-06-01  
**Author:** Curie  
**Branch:** fix/ios-26-ui-test-failures (tests 1, 2, 4, 5)

## Summary

Five UI tests regressed after upgrading to iOS 26.4 simulator. All five are now fixed. This document records the root causes and workarounds for future reference.

---

## Test 1 & 2 — LazyVGrid off-screen cells never render

**Tests:** `testAccessibilityDynamicTypeStacksGaugeMeasurementPairs`, `testCompactWidthKeepsNumericFieldsSideBySideWhenTheyFit`

**Root cause:** `LazyVGrid` inside a `UISheetPresentationController`-hosted `UIHostingController` no longer renders cells that fall outside the initial viewport on iOS 26.4. XCTest accessibility queries return empty results for cells that were never rendered.

**Fix:** Replaced `LazyVGrid` with `HStack` in `GaugeMeasurementPair.swift`. All cells render eagerly.

**File:** `app/KnittingGaugeReconciler/Components/GaugeMeasurementPair.swift`

---

## Tests 4 & 5 — Reset button action never fires inside adjustment sheet

**Tests:** `testPrototypeParityControlsAreAvailable`, `testResetConfirmationAlertDoesNotDismissSheet`

**Root cause (multi-layer):**

### Layer 1: `.accessibilityElement(children: .contain)` required but blocks touches

The `AdjustmentSheetView` root `VStack` carries `.accessibilityElement(children: .contain)` + `.accessibilityIdentifier("adjustment-sheet")`. Without these modifiers, XCTest's accessibility tree is completely empty inside the sheet on iOS 26.4 (no buttons, no labels, nothing). So the modifiers are **required**.

However, `.accessibilityElement(children: .contain)` on iOS 26.4 inside `UISheetPresentationController` blocks **all** touches from reaching child SwiftUI views. Both `element.tap()` (accessibility-routed) and coordinate taps (`app.coordinate(...).tap()`) fail silently — the button never receives the interaction.

### Layer 2: SwiftUI `Button` action is specifically blocked

SwiftUI `Button` processes its action via SwiftUI's gesture recognizer pipeline. Under `.contain`, this pipeline never delivers the tap. UIKit controls are **not** affected by this block — UIKit UIButton's `touchUpInside` target-action fires correctly even when `.contain` is present.

### Fix: UIKitTapButton (UIViewRepresentable)

Replaced the SwiftUI `Button` with a `UIViewRepresentable` wrapper (`UIKitTapButton`) that hosts a `UIButton`. The UIButton's `touchUpInside` target fires correctly when XCTest calls `element.tap()`.

Additional changes:
- Moved the reset button **outside** the `ScrollView` (between header and scroll view). `UIScrollView.delaysContentTouches` caused interaction issues when the button was inside.
- The reset confirmation alert uses imperative `UIAlertController` (walks the VC chain to find the sheet's `UIHostingController` as presenter). SwiftUI `.alert()` had conflicts with the `.sheet(isPresented:)` presentation.
- Added `adjustsFontForContentSizeCategory = true` to the UIButton so Dynamic Type accessibility audits pass.

**File:** `app/KnittingGaugeReconciler/Views/RequiredAdjustmentsCard.swift`

---

## Remaining pre-existing failures (not regression, deferred)

- **`testMainScreenAccessibility`** — contrast audit failure on the main screen. Pre-existing; deferred to Edison.
- **`testAdjustmentSheetAccessibility`** — contrast audit failure inside the adjustment sheet. Pre-existing; deferred to Edison.

---

## Decision needed

None — this is informational. The `UIKitTapButton` workaround is intentional and load-bearing. Do not replace it with a SwiftUI `Button` until Apple resolves the `.contain` touch-blocking regression on iOS 26.4.
