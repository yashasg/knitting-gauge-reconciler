# Edison — Delta pill circular style

- **Date:** 2026-05-22T03:56:42-07:00
- **Requested by:** Yashas
- **Scope:** `app/KnittingGaugeReconciler/Components/GaugeStepperField.swift`, `app/KnittingGaugeReconciler/Components/AdjustmentValuePair.swift`, `app/KnittingGaugeReconciler/Components/AppTheme.swift`, `app/KnittingGaugeReconciler/Assets.xcassets/app-theme-delta-pill.colorset/Contents.json`

## Decision

Use a shared circular delta badge for signed mismatch indicators instead of the previous capsule treatment.

## Details

- Badge shape is a true circle with a fixed `32 × 32` frame.
- Badge fill uses the approved muted olive tone via `app-theme-delta-pill` color asset (`red: 0.30, green: 0.35, blue: 0.23`).
- Badge text remains white with `.caption2.weight(.semibold)` and a `minimumScaleFactor` so short labels like `+2` and wider labels like `+10` fit inside the circle.
- The same shared badge component is used in the field header, wheel-picker header, and adjustment summary delta so the treatment stays visually consistent.

## Verification

- `cd /Users/yashasgujjar/dev/knitting-gauge-reconciler/app && bash build.sh build 2>&1; echo "EXIT: $?"`
- Result: `EXIT: 0`
