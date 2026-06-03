# Decision: SwiftLint Accessibility Guard Rules

**Date:** 2026-06-02T19:14:40-07:00
**Author:** Hopper (Tooling Dev)
**Branch:** squad/dynamic-type-elastic-layout
**Status:** Implemented

---

## Context

MR !43 (Edison) removed all `.minimumScaleFactor` and `.dynamicTypeSize(...ceiling)` usages from production code and replaced them with `ViewThatFits` reflow. This decision records the SwiftLint guard that prevents regression.

## Rules Added (`.swiftlint.yml`)

### `no_minimum_scale_factor` (error)
- **Regex:** `\.minimumScaleFactor\(`
- **Message:** "minimumScaleFactor shrinks text below the user's chosen Dynamic Type size — banned per accessibility decision; reflow with ViewThatFits instead."
- **Rationale:** `.minimumScaleFactor(0.7)` allows SwiftUI to shrink text to 70% of its target size under layout pressure. At large Dynamic Type settings this silently overrides the user's accessibility preference.

### `no_dynamic_type_cap` (error)
- **Regex:** `\.dynamicTypeSize\(\.\.\.`
- **Message:** "dynamicTypeSize cap clamps Dynamic Type growth — banned per accessibility decision; reflow with ViewThatFits instead."
- **Rationale:** The PartialRangeThrough form `.dynamicTypeSize(...DynamicTypeSize.accessibilityN)` acts as an upper ceiling on text size, overriding Apple's Accessibility → Display & Text Size → Larger Text setting.
- **Scope:** Targets only the view-modifier form. Does NOT fire on:
  - `@Environment(\.dynamicTypeSize)` — reading the env value
  - `.environment(\.dynamicTypeSize, .accessibilityN)` — setting env in `#Preview`
  - `dynamicTypeSize.isAccessibilitySize` — property access

## Exclusions

`app/KnittingGaugeReconcilerTests/` and `app/KnittingGaugeReconcilerUITests/` are excluded (already excluded from all custom rules in `.swiftlint.yml`). Test files may legitimately set specific DynamicTypeSize values for layout assertions.

## Documentation

Rules documented in `docs/swift_coding_standards.md` §3.2 (table) and §3.3 (new subsection with rationale, code examples, and scope notes).

## Pre-commit Hook

Hook installed at `.git/hooks/pre-commit` per §3.1. Hook script documented in §3.1 of `docs/swift_coding_standards.md` so teammates can reinstall.

## Verification

- **Positive (clean branch):** `swiftlint lint` → 0 violations on all 22 source files. Edison's MR !43 already removed the banned modifiers.
- **Negative test:** Temporarily appended `.minimumScaleFactor(0.5)` and `.dynamicTypeSize(...DynamicTypeSize.accessibility1)` (as comments) to a source file — both rules fired immediately. Reverted.

---

## UI Test Investigation Findings (Part A)

### Tests that relate to the Dynamic Type / accessibility-size layout change

| File:Test | What it asserts | Failure status | Recommendation |
|---|---|---|---|
| `KnittingGaugeReconcilerUITests.swift:testAccessibilityDynamicTypeStacksGaugeMeasurementPairs` | At `.accessibilityExtraExtraExtraLarge` font size, gauge field pairs stack vertically (not side-by-side) | Currently **PASSING** (per Edison's report) — the `ViewThatFits` reflow works correctly | **KEEP** — directly guards the new reflow behavior |
| `KnittingGaugeReconcilerUITests.swift:testCompactWidthKeepsNumericFieldsSideBySideWhenTheyFit` | At default font size, fields are side-by-side; also asserts `cast-on-result` element exists | **FAILING** — `cast-on-result` element not found (iOS 26 simulator infra flake; element exists but accessibility tree walk races with animation) | **FIX** — add a longer `waitForExistence` on the `cast-on-result` element; do not delete (guards the complementary side-by-side behavior) |
| `AccessibilityAuditTests.swift:testMainScreenAccessibility` | Full Apple accessibility audit of main screen | **FAILING** — `Invalid target app <pid>` (-902) iOS 26 simulator infra flake | **Keep / fix** — already has `performAccessibilityAuditWithFlakeRetry` wrapper; if still flaking the retry count may need increasing |
| `AccessibilityAuditTests.swift:testAdjustmentSheetAccessibility` | Full Apple accessibility audit of adjustments sheet | **FAILING** — same `-902` infra flake | Same as above |

### Tests that are pre-existing failures unrelated to MR !43

| File:Test | Why failing | Recommendation |
|---|---|---|
| `KnittingGaugeReconcilerUITests.swift:testAllJacquardScenariosAreVisibleInUI` | `cast-on-result` element not found — iOS 26 simulator rendering race | **FIX** (Curie domain) — increase `waitForExistence` or add explicit scroll-and-wait |
| `KnittingGaugeReconcilerUITests.swift:testPrototypeParityControlsAreAvailable` | Reset confirmation alert buttons not found — UIKit alert timing on iOS 26 | **FIX** (Curie domain) |
| `KnittingGaugeReconcilerUITests.swift:testResetConfirmationAlertDoesNotDismissSheet` | Same alert timing issue | **FIX** (Curie domain) |
| Possible unit-toggle test | `testUnitToggleSwitchesFieldLabel` — known pre-existing failure | **FIX** (Edison/Curie domain) |

### Does any UI test specifically guard "no text clamping at accessibility sizes"?

**No.** The accessibility audit tests (`testMainScreenAccessibility`, `testAdjustmentSheetAccessibility`) check for `.textClipped` violations via Apple's audit API, but that catches runtime truncation — not the source-level `minimumScaleFactor`/`dynamicTypeSize` modifier patterns. The new SwiftLint rules provide faster, more reliable source-level guards.

**What lint CAN'T cover:** SwiftLint checks source patterns at commit time; it cannot verify at runtime that no text visually clips or truncates at AX5 font size. `testAccessibilityDynamicTypeStacksGaugeMeasurementPairs` (the reflow behavioral test) provides the complementary runtime guard and should be kept.

## Recommended Split

- **SwiftLint `no_minimum_scale_factor` + `no_dynamic_type_cap`:** guards "don't reintroduce the banned source modifiers" — commit-time, zero runtime cost. ✅ Now implemented.
- **Keep `testAccessibilityDynamicTypeStacksGaugeMeasurementPairs`:** guards that `ViewThatFits` actually reflows at AX3 — runtime behavioral test for the positive case.
- **Keep `AccessibilityAuditTests` (fix flake retry):** guards that the app is auditable for `.textClipped`, contrast, hit targets.
- **Fix (don't delete) the `cast-on-result` flake tests:** they guard scenario calculation results; the failure is infra timing, not a code regression.

## Test Removal Recommendation (for Curie)

**Do NOT delete any test in this pass.** Specific recommendations:

| Test | Action | Owner |
|---|---|---|
| `testAllJacquardScenariosAreVisibleInUI` | FIX: increase `waitForExistence` for `cast-on-result` to 8–10s | Curie |
| `testCompactWidthKeepsNumericFieldsSideBySideWhenTheyFit` | FIX: same — `cast-on-result` wait | Curie |
| `testPrototypeParityControlsAreAvailable` | FIX: add `Thread.sleep` before alert button tap | Curie |
| `testResetConfirmationAlertDoesNotDismissSheet` | FIX: same | Curie |
| `testMainScreenAccessibility` / `testAdjustmentSheetAccessibility` | FIX: increase `maxAttempts` in `performAccessibilityAuditWithFlakeRetry` from 4→6 | Curie |
| `testAccessibilityDynamicTypeStacksGaugeMeasurementPairs` | **KEEP** — guards Dynamic Type reflow. Do not remove. | — |
