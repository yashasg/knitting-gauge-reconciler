# Jacquard — Archived History Summary

_Summarized at 2026-07-14T23:38:12.955-07:00 after crossing the 15,360-byte history threshold._

## Durable craft and formula authority

- Treat stitch and row gauge as independent axes. Stitch width uses `pattern / your`; cast-on correction uses `your / pattern`. Row density uses `your / pattern`; dimension correction uses `pattern / your`.
- Section rows are `round((cm / 10) × yourRows)`. Shaping intervals scale by row density. Preserve formula direction and apply rounding only at the defined output boundary.
- Craft scenarios must cover perfect match, stitch-only mismatch in both directions, row-only mismatch in both directions, and both axes mismatched.
- Knitter-facing language should describe actionable stitch counts, row counts, dimensions, and shaping cadence rather than abstract percentages alone.
- The JS-to-Swift port was signed off only after scenario-by-scenario equivalence and follow-up craft-truth review.
- Saved reconciliations were not justified by the knitting workflow at the time; persistence should not be added without a concrete use case.
- MetricKit review separated actionable workflow health from vanity telemetry. Never emit raw gauge values or sensitive/high-cardinality payloads; use stable event names and privacy-safe aggregates.
- Canonical project path is `app/KnittingGaugeReconciler.xcodeproj`; scheme is `KnittingGaugeReconciler`.

Current domain decisions remain in `history.md` and `.squad/decisions.md`.
