# Session Log: MetricKit V1 Implementation Shipped (2026-05-20)

**Session ID:** metrickit-pivot-shipped
**Date:** 2026-05-20
**End time:** 2026-05-20T19:26:30-07:00
**Team:** Edison, Hopper, Curie, Tesla (V3-IMPL round) + Ada, Ive, Mendel, Jacquard (V2 scoping, pivot-survival verification)

## What Shipped

**MetricKit V1 implementation** — Apple system framework integration (zero third-party SDKs, OS-mediated daily aggregation to App Store Connect Analytics, user opt-out via iOS Settings).

### Core Deliverables

| Component | Files | Status |
|---|---|---|
| Subscriber + Math metrics | MetricsSubscriber.swift, GaugeMathMetrics.swift | ✅ Created |
| App bootstrap | KnittingGaugeReconcilerApp.swift, ContentView.swift | ✅ Modified |
| 9 MXSignpost names | ContentView.swift (lines 40, 42, 90, 95, 106, 108, 115, 417, 433, 436) | ✅ Placed |
| Privacy posture | PrivacyInfo.xcprivacy, pbxproj wiring, docs/app-store-connect-privacy-setup.md | ✅ Complete |
| Test suite | MetricKitSubscriberTests.swift (24 new tests across 4 suites, AC-1..AC-8 all green) | ✅ Shipped |
| Standards | docs/swift_coding_standards.md §2.2/§2.3/§2.12/§7 amended | ✅ Updated |

### Build State

- `./app/build.sh test`: 49/49 tests pass, 0 warnings (was 25 tests, now +24 from Curie-3)
- `./app/build.sh release`: otool -L check passes (MetricKit linked, no third-party SDKs)

## Four-Question Resolution Path

| Question | V1 Decision | User Directive | Notes |
|---|---|---|---|
| **Runtime backend?** | MetricKit (system framework) | 2026-05-20T18:50:53 | Drop apple/swift-metrics (vocabulary-only, no sink). MetricKit → App Store Connect Analytics (OS-mediated). Developer endpoint deferred to V2. |
| **Privacy card in app?** | Removed, stays removed | 2026-05-20T19:22:50 | PrivacyInfo.xcprivacy + ASC nutrition labels sufficient. User explicit: "nothing identifies a user; declare in label, you're good." |
| **How many signposts?** | 9 (Tesla's roster) | 2026-05-20T19:26:30 | Over Edison's 11-name proposal. Rationale: "is the calculator helping people improve?" (improved/degraded signal) > "what is verdict distribution?" (bucket counts). |
| **Developer endpoint?** | Deferred to V2 | Implicit in MetricKit design | No server standing up, no retention policy, no amendment with URL. App Store Connect Analytics is primary sink. Can add opt-in developer POST later without client changes. |

## Directives Captured This Session

1. **2026-05-20T18:50:53-07:00** — MetricKit pivot (was swift-metrics V1/V2 scope; now all MetricKit)
2. **2026-05-20T19:22:50-07:00** — Privacy card stays removed (post-MetricKit reaffirmation of prior user decision)
3. **2026-05-20T19:26:30-07:00** — Signpost roster locked at 9 (user ratification of Tesla V3 proposal)

## Scope Inheritance (V2 → V3 → Shipped)

| Rule/Scope | Owner | Status | Fate |
|---|---|---|---|
| Math-layer determinism (§2.2) | Ada V2 | Binding | ✅ Enforced in V3-IMPL via AC-3 (static) + AC-4 (stub) |
| UX NONE (no in-app analytics UI) | Ive V2 | Binding | ✅ Survives pivot; no privacy card |
| Category-only granularity (Jacquard V2 §5) | Jacquard V2 | Binding | ✅ All 9 signposts are names only, no raw numbers in strings |
| cast_on threshold gate (Jacquard V2) | Jacquard V2 | Binding | ✅ Signpost #9 gated by Jacquard V3 threshold evaluation (shipping in V1) |
| Saved reconciliations MVP (Mendel V2) | Mendel V2 | Optional, deferred | ⏸ Full re-scope planned for app V2; not blocking V1 |
| swift-metrics V1/V2 backend choice | Tesla V1/V2 | Superseded | 🗑 Replaced by MetricKit architecture |

## Open Follow-Ups for Future Sessions

### For Jacquard

- **Threshold review:** cast_on drift band visibility gate (signpost #9). V3 scope drafted the thresholds; verify they're locked for V1 ship or mark for revisit.

### For Mendel

- **Deferred re-scope:** Saved reconciliations full re-scope (pattern name + yarn + timestamp metadata). Was planned for app V2; team can prioritize in next session if desired.

## GitLab Issue Status

**Issue #9 (swift-metrics → MetricKit):** Comment posted (note 3370575474) explaining the pivot, user directives, final decision, and deferred items. Prior stale comment (3370481646) marked SUPERSEDED.

## Session Stats

- **Directives processed:** 3 (all user-originating)
- **Decisions merged into decisions.md:** 20 inbox files (3 directives + 4 V3 scope + 4 V3-IMPL shipped + 8 V2 scope marked SUPERSEDED/survives + tesla-gitlab-9-comment-DRAFT)
- **Archive operation:** 20448 bytes of 2026-05-19 entries archived to decisions-archive.md; decisions.md reduced from 98243 to 18624 bytes
- **Orchestration logs written:** 4 (edison-3, hopper-3, curie-3, tesla-4 at 2026-05-21T02:26:30Z)
- **Test delta:** KnittingGaugeReconcilerTests 18 → 42 (+24 tests); total 49/49 tests passing
- **Standards amendments:** 4 sections of docs/swift_coding_standards.md (§2.2/§2.3/§2.12/§7)
