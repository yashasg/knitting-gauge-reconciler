# Curie — Archived History Summary

_Summarized at 2026-07-14T23:38:12.955-07:00 after crossing the 15,360-byte history threshold._

## Durable testing learnings

- Canonical Xcode project path is `app/KnittingGaugeReconciler.xcodeproj`; scheme is `KnittingGaugeReconciler`.
- Early UI gates verified swatch-hint layout, help overlays, and copy-results menu behavior with accessibility identifiers intact.
- iOS UI tests sharing a simulator can interfere with each other; serialize or isolate simulator/build state when the active test contract requires it.
- Metric instrumentation testing evolved through three scopes. Initial MetricsTestKit assumptions were withdrawn after fact-checking; final MetricKit V1 used native payload/subscriber seams and deterministic mocks.
- The shipped MetricKit suite covered the agreed acceptance criteria without coupling tests to MetricKit delivery timing or private framework behavior.
- Keep gauge math tests independent from telemetry tests. Verify event names and invocation boundaries without asserting sensitive gauge values.
- Regression-risk UI identifiers must remain stable when instrumented controls move or are wrapped.
- Final validation remains warning-free build, zero lint violations, and the complete unit/UI suite required by the current gate.

Current testing learnings remain in `history.md`.
