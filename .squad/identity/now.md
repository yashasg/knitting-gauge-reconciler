---
updated_at: 2026-05-20T19:26:30-07:00
focus_area: MetricKit V1 shipped — 9 MXSignpost names, PrivacyInfo.xcprivacy, 49/49 tests
active_issues: [9]
---

# What We're Focused On

**MetricKit V1 implementation shipped 2026-05-20.** User directive pivot from apple/swift-metrics (vocabulary-only, no production sink) to Apple MetricKit (system framework, zero third-party SDKs, OS-mediated daily aggregation to App Store Connect Analytics).

**Scope locked by three user directives:**
1. **2026-05-20T18:50:53** — MetricKit pivot (resolve issue #9 backend question)
2. **2026-05-20T19:22:50** — Privacy card stays removed (PrivacyInfo.xcprivacy + ASC labels sufficient)
3. **2026-05-20T19:26:30** — 9-signpost roster ratified (compute, share.invoked, share.fallback, reset.tapped, verdict.improved, verdict.degraded, sheet.verdictHelp.opened, sheet.aboutHelp.opened, cast_on.driftBandShown)

**Deliverables:**
- MetricsSubscriber.swift, GaugeMathMetrics.swift (new)
- ContentView.swift + App bootstrap wiring (9 signpost call sites at lines 40, 42, 90, 95, 106, 108, 115, 417, 433, 436)
- PrivacyInfo.xcprivacy verified + pbxproj wired
- MetricKitSubscriberTests.swift (24 new tests, AC-1..AC-8 all green)
- docs/swift_coding_standards.md §2.2/§2.3/§2.12/§7 amended
- GitLab issue #9 comment (note 3370575474) posted

**Build state:** `./app/build.sh test` → 49/49 tests pass (was 25), 0 warnings. `./app/build.sh release` → otool -L guard passes.

**Developer endpoint POST deferred to V2.** App Store Connect Analytics is primary sink; optional developer webhook can be added later without client changes.

**Next pickup candidates:**
- Jacquard: cast_on threshold review (gates signpost #9)
- Mendel: deferred V3 re-scope for saved reconciliations (optional, app V2 priority)
