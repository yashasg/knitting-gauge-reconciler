# Decision: Reconcile Button Above Title in RequiredAdjustmentsCard

**Date:** 2026-05-21  
**Author:** Edison (SwiftUI/iOS implementer)  
**Requested by:** yashasg

## Decision

Move the action button in `RequiredAdjustmentsCard` to its own row **above** the title, and rename it to **"Reconcile"** across all states.

## Rationale

- The button was competing for horizontal space with "Required Adjustments", causing the title to hyphenate.
- The button is the verb that *produces* the section — so it belongs as the header, above the title.
- Single label "Reconcile" across all 3 states: visual treatment (opacity + icon) signals staleness, not the word.

## Layout Change

**Before:** `[Required Adjustments]  [Recalculate ↻]` — single HStack row  
**After:**
```
Row 1: [                    Reconcile ✦]  (right-aligned)
Row 2: [Required Adjustments            ]  (full width, no hyphenation)
```

## Preserved

- Accessibility identifier `calculate-button` unchanged (UI tests depend on it)
- 3-state visual: nil → full sage + wand.and.stars; fresh → 50% opacity; stale → full sage + arrow.clockwise
- `onRecalculate()` callback, staleness detection, placeholder rendering
