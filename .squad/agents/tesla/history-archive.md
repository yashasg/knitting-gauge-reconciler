# Tesla — Archived History Summary

_Summarized at 2026-07-14T23:38:12.955-07:00 after crossing the 15,360-byte history threshold._

## Durable decisions and learnings

- Canonical project path is `app/KnittingGaugeReconciler.xcodeproj`; scheme is `KnittingGaugeReconciler`.
- The run-script rescue established real simulator builds as the acceptance signal and discouraged environment-specific shortcuts.
- Saved reconciliations were evaluated as unnecessary scope; favor the current calculator workflow unless product requirements explicitly add persistence.
- Swift coding standards were adopted as enforceable project policy: native Swift/SwiftUI, explicit math boundaries, accessibility, warning-free builds, and tests for behavior.
- Metrics scope evolved from `swift-metrics` exploration to MetricKit V1. Final architecture kept gauge math pure, placed signposts at view/workflow boundaries, used a protocol seam for payload handling, avoided sensitive values, and tested payload conversion/subscriber behavior. MetricsTestKit assumptions were corrected during review.
- Vanity or high-cardinality telemetry was rejected. Instrument only actionable workflow events with stable names and privacy-safe data.
- Cross-cutting decisions must reconcile product value, API/platform constraints, privacy, testability, dependency cost, and existing decisions before implementation.
- The 2026-05-20 MetricKit closeout amended standards and issue scope, then shipped the agreed native implementation and test coverage.

This summary supersedes the verbose archive; current work remains in `history.md`.

## 2026-07-15T14:58:16.016-07:00 — Additional durable summary

- Fastlane/CD work established that step-scoped environment values need stable file fallback across workflow steps and that scheme participation governs test selection.
- Prototype-parity governance was retired; current issue contracts and canonical decisions own acceptance.
- Issue #65 reinforced strict owner allowlists, independent revision after lockout, exact-result-bundle inspection, and preservation of unrelated dirty state.
- Issue #82 static reconciliation proved the authorized three-file branch and MR !47 at `b22c775`; Curie's local gate then passed 77/77, while CI and reviewer gates remain separate prerequisites.

## 2026-07-17T01:44:15.855-07:00 — Reconciliation and publication summary

- Repeated issue/MR races reinforced that exact-head CI, canonical issue identity,
  independent review, and clean ownership must all agree before merge.
- The direct unit-only authority superseded stale test contracts. Build tooling
  must make selection explicit, avoid retry masking, and produce attributable
  evidence without broadening the issue diff.
- Issues #103, #104, #106/#108, #109–#112 moved through reconciliation and
  publication while ambiguous branches, worktrees, stashes, and safety refs
  remained preserved.
- At this snapshot, issue #114 and MR !82 at `ffdfa5d2` are the sole active
  domain identity and await an exact-head green pipeline; Hopper owns resumption.
- Dirty coordination records, the shipped-but-dirty #109 identity, blocked #51
  state, 34 stashes, 11 safety refs, and closed-unmerged branches remain outside
  cleanup authority.
