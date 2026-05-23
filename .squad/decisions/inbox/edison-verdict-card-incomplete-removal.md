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
