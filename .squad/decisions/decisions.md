# Edison Decision — Main Screen App Name

- **Date:** 2026-05-23
- **Author:** Edison
- **Scope:** iOS main screen navigation title

## Decision

Use **"Stitchwise"** as the user-facing app name on the main screen.

## Notes

- This changes the SwiftUI navigation title only.
- Project name remains `KnittingGaugeReconciler`.
- Bundle ID and other app identity values remain unchanged.
# Edison — VerdictCard incomplete removal root cause

- **Date:** 2026-05-23T02:27:08-07:00
- **Status:** Recorded
- **Related commit:** 515ab51

## Root cause

The earlier fix removed only the `VerdictCard(...)` call site from `ContentView.swift`.
That left two verdict-family remnants behind:

1. `AdjustmentSheetView.statusCard` in `Views/RequiredAdjustmentsCard.swift` still rendered the same summary/rejection family (including the major-drift warning card copy).
2. `Views/VerdictCard.swift` and `GaugeMathPresentation.swift` remained in the Xcode target even though they were no longer referenced.

## Decision

When Tesla rejects a verdict-family surface, remove the entire presentation family, not just the top-level main-screen call site:

- delete unused verdict-only view files,
- remove any inline summary/status cards carrying the same judgmental copy,
- and clean the Xcode project entries in the same sweep.

## Follow-up

Future UI removals should grep for naming variants (`Verdict`, `Major mismatch`, `mismatch`, `statusCard`) before calling the rollback complete.

---

# Ive Decision — Elastic Layout for Dynamic Type (No Exceptions)

**Author:** Ive (UI/UX Designer)  
**Date:** 2026-06-02T18:32:46-07:00  
**Status:** ACTIVE → SUPERSEDES `ive-dynamic-type-reflow.md` and `ive-minimum-scale-factor.md`

## Summary

The layout must absorb any Dynamic Type size gracefully. No text shrinking, no size capping, no conditional hiding. Text always renders at the user's exact chosen Dynamic Type size; the LAYOUT adapts.

## Action Items for Edison

1. **Remove all `.dynamicTypeSize(...DynamicTypeSize.accessibility1)` caps** (3 locations):
   - `GaugeStepperField.swift` (DeltaPillBadge) line 28
   - `AdjustmentRow.swift` line 87
   
2. **Remove `.minimumScaleFactor(0.7)`** from `GaugeInputGroup.swift` line 33

3. **Implement `ViewThatFits` reflow in `GaugeInputGroup`**:
   - Replace header HStack with `ViewThatFits(in: .horizontal)` for side-by-side → stacked reflow
   - Side-by-side at normal sizes; tag wraps below title at AX1–AX5
   
4. **Test at Dynamic Type AX5** on device; verify no truncation, VoiceOver labels unchanged

5. **Delta/drift pills**: Remove `.dynamicTypeSize` cap; acceptable to overlap at AX5. Add VStack fallback only if visual breakage on device.

## Key Details

- **Badge visibility**: All badges remain `.accessibilityHidden(true)` (decorative chrome)
- **VoiceOver**: No change to focus order; info already present in parent labels
- **Files**: GaugeInputGroup.swift, GaugeStepperField.swift, AdjustmentRow.swift (AdjustmentValuePair.swift needs no changes)

## Supersedes

- `ive-dynamic-type-reflow.md` (hide-at-accessibility-sizes pattern — REPLACED)
- `ive-minimum-scale-factor.md` (tokenize minimumScaleFactor — REPLACED)

The app must have **zero** Dynamic Type exceptions. Zero.
