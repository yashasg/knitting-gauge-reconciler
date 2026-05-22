# Edison: pattern instructions typography fix

- **Date:** 2026-05-22T03:27:26.322-07:00
- Normalize the Pattern Instructions card title to the same visual hierarchy as the Pattern Gauge and Your Gauge card titles.
- Keep the label in title case (no `.textCase(.uppercase)` / `.uppercased()` treatment) and use `.title2.weight(.bold)` to match the sibling card headers.
- Add `.minimumScaleFactor(0.7)` and keep the title on one line so the longer string shrinks before wrapping.
- Files: `app/KnittingGaugeReconciler/Views/PatternInstructionsCard.swift`.
- Verification: `cd /Users/yashasgujjar/dev/knitting-gauge-reconciler/app && bash build.sh build 2>&1; echo "EXIT: $?"` completed with a successful build.
