**Date:** 2026-05-21T01:19:39Z
**Topic:** swift-metrics scoping for issue #9
**Agents:** Tesla (Lead), Ada (math-layer), Edison (SwiftUI), Curie (test), Hopper (tooling), Ive (UX), Mendel (research), Jacquard (domain)

**Summary:**

Eight-member parallel scoping pass on GitLab issue #9 (swift-metrics integration). Tesla led the scope synthesis, establishing façade-only adoption (NOOPMetricsHandler release default, in-memory sink for debug), in-process-only storage, env-var gating (`KGR_METRICS_BACKEND`), and integration with Swift Coding Standards §2.2 (math determinism), §2.3 (no network), §2.12 (release logging discipline). Ada locked math-layer boundary (5 in-scope signals measurable at call site; no clock reads inside `GaugeMath`). Edison scoped UI instrumentation (compute pipeline, input field edits, disclosure affordances, verdict gauges — zero new accessibility identifiers). Curie drafted test strategy (in-memory factory, per-test isolation, three regression-prone tests identified). Hopper defined build integration (SPM package, exact version pin, env-var pass-through in build.sh). Ive enforced UX constraints (zero user-facing surface, no privacy-copy revival). Mendel identified five high-value research questions (scenario coverage, 30-second latency, field churn, verdict-help taps, cast-on reach). Jacquard bounded domain-meaningful signals (axis-mismatch bucketing, drift-magnitude histograms, implausible-input detection, cast-on rounding analysis).

**Status:** All scopes proposed; awaiting yashasg sign-off before implementation cycle opens. Tesla parallel synthesis (issue9-synthesis.md) in flight for GitLab issue comment post-back.

**Decisions merged:** `.squad/decisions.md` now carries 8 scope sections (20,447 → 98,243 bytes). Eight orchestration-log entries written. Team updates pending (task 5).
