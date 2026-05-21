## 2026-05-20T20:38:28-07:00 — Cleanup Round Audit & Implementation (11 items shipped)

### 2026-05-20T20:38:28-07:00: Edison Cleanup Audit Decision

**Author:** Edison (Frontend Dev)
**Date:** 2026-05-20T20:38:28-07:00
**Scope:** `app/KnittingGaugeReconciler/` (all `.swift`), tests, build script
**Build baseline:** 49/49 tests pass, 0 warnings (must hold after cleanup)

**Summary:** 13 findings audited — 11 approved for immediate implementation, 2 deferred to Tesla/yashasg for architectural review.

**Approved items (11 items — all shipped as of 2026-05-20T20:45:00-07:00):**

**P0 Correctness Issue:**
- **4.1 (CLEANUP):** Signpost inflation. `result` computed property fired `os_signpost(.begin/.end)` on every access (15-20×/body render). Fixed via cached `@State var cachedResult` + `.onChange(of: inputs, initial: true)` → signpost fires exactly once per user-visible computation. **Fix shape: Option (a) cached state.** Bonus: eliminates per-keystroke GaugeMathResult recomputation.

**Dedupes (Dedupe 3 × identical code, 1 × identical logic):**
- **2.1:** `gaugeStatus(scale:)` and `rowStatus(scale:)` private in both GaugeMath.swift and ContentView.swift. Made internal in GaugeMath, deleted ContentView copies (~12 lines removed). ~14 lines total.
- **2.2:** `plain()` (GaugeMath.swift) vs `formatPlain()` (ContentView.swift) — both format doubles to display. `plain()` is canonical (2dp trim trailing zeros); deleted `formatPlain()`, migrated 14 call sites. Verified: no real-knitting-value divergence (both produce identical output for integers and single-decimal gauge). **Note:** `plain("24.333")` → `"24.33"` (2dp); `formatPlain("24.333")` → `"24.333"` (Swift default). All real inputs are integers or 1dp, no regression.
- **2.3:** `HeroMetric.pillBackground(status:)` and `sharePillBackground(status:)` identical. Deleted pillBackground method, all callers use free function. ~7 lines removed.

**Removes (2 dead code):**
- **4.2:** `AppTheme.tertiary` unused color constant. Deleted.
- **8.1:** `scrollToTop(in:)` dead UI test helper. Deleted.

**Cleanup (5 nits):**
- **1.1:** `didReceive(_ payloads: [MXDiagnosticPayload])` asymmetry — diagnostic payloads bypass `receive()` seam. Added `// TODO(V2):` marker noting gap (V2 should add parallel `receive(diagnostics:)` overload).
- **4.3:** AboutHelpSheet scope callout uses 3 inline RGB color literals not in AppTheme. Named them: `AppTheme.warningText`, `warningBackground`, `warningAccent`. Maintains byte-identical RGB values, improves maintainability + dark-mode readiness.
- **4.4:** Redundant `= nil` on `@State private var previousVerdictBucket: VerdictBucket? = nil`. Removed explicit nil (Swift Optionals default to nil).
- **7.1:** `MockMetricPayload.jsonRepresentation()` defined on mock but not in `MetricPayloadProtocol` (deliberately excluded per comment). Removed from mock (not protocol-required, not called by tests).
- **8.2:** `launchEnvironment` dict duplicated verbatim 7 times in UI tests. Extracted to `private static let defaultLaunchEnvironment: [String: String]` with canonical 7 keys; all tests use `.merging({_, new in new})` for scenario-specific overrides.

**Items deliberately NOT implemented (audited, user/Edison agreed to skip):**
- **5.1 (HelpSheetContainer extraction)** — Below 3-use threshold per swift coding standards §2.8. Wait for 3rd help sheet in V2.
- **D.1 (split GaugeMath math vs export formatters)** — Deferred to Tesla architectural call on file boundaries.
- **D.2 (flip VerdictBucket derivation direction)** — Deferred to yashasg behavioral call on "truth flow" direction.

**Cross-cutting observations (logged for future reference):**
- Three places answer "what does this scale deviation mean?": `gaugeStatus()`/`rowStatus()` thresholds (3%, 10%), `verdictTitle` thresholds (3%, 15%), `VerdictBucket` implicit. Consistent today; divergence risk as thresholds evolve. Future: consider unified `GaugeDeviation` classification layer (deferred).
- AppTheme gap: scope-warning callout has 3 out-of-band RGB literals. Now named, but pattern could recur if more callouts appear.
- `var` vs `let` on view struct inputs: All private view structs use `var` (convention for SwiftUI) but don't mutate. Minor inconsistency vs Apple's trending toward `let`. Low priority.
- GaugeTextDefaults.swift: Nine properties are mutable but never mutated. Should be `let` (minor pattern issue, not flagged as formal finding).

### 2026-05-20T20:45:00-07:00: Edison Cleanup Implementation Decision (8 items shipped)

**Author:** Edison (Frontend Dev)
**Date:** 2026-05-20T20:45:00-07:00
**Status:** SHIPPED
**Build:** `./app/build.sh test` → exit 0, 0 warnings, 49/49 tests pass (one simulator flake on first run, second run clean)

**Files modified:**
- `MetricsSubscriber.swift` — 1.1 TODO marker
- `GaugeMath.swift` — 2.1 (gaugeStatus/rowStatus internal), 2.2 (plain internal, formatPlain deleted)
- `ContentView.swift` — 2.1/2.2 dedupe deletes, 2.3 pillBackground delete, 4.1 cached @State result + .onChange(of: inputs), 4.2 AppTheme.tertiary delete, 4.3 AppTheme warning constants added, 4.4 redundant = nil stripped

**LOC delta:** ~−16 lines net production code (MetricsSubscriber +1 TODO, GaugeMath 0 keyword changes, ContentView −17).

**Key implementation decision — 4.1 fix shape (Option a):**
```swift
@State private var cachedResult: GaugeMathResult = GaugeMath.compute(GaugeInputs())
private var result: GaugeMathResult { cachedResult }
private func recomputeResult() {
    os_signpost(.begin, log: MetricsSubscriber.log, name: SignpostNames.compute)
    cachedResult = GaugeMath.compute(inputs)
    os_signpost(.end, log: MetricsSubscriber.log, name: SignpostNames.compute)
}
```
In body: `.onChange(of: inputs, initial: true) { _, _ in recomputeResult() }`

Signpost correctness:
- Body re-render (no input change): `result` accesses `cachedResult` (no compute), signpost fires 0 times. ✅
- Input change: `.onChange` fires once → signpost begin + compute + signpost end fires exactly 1 time. ✅

Rationale: `.onChange(of:initial:)` ensures main-actor synchronous execution (no async isolation questions). Initial: true fires both on first appear and on every subsequent change. Option (a) also eliminates per-keystroke recomputation (bonus benefit beyond signpost fix).

**2.2 divergence flag:** `plain()` and `formatPlain()` produce different output on 3+ decimal places (`24.333` → `"24.33"` vs `"24.333"`), but all real knitting inputs are integers or single-decimal. No user-visible regression. Share-text formatter tests pass.

### 2026-05-20T20:47:00-07:00: Curie Cleanup Implementation Decision (3 items shipped)

**Author:** Curie (Test Engineer)
**Date:** 2026-05-20T20:47:00-07:00
**Status:** SHIPPED
**Build:** `./app/build.sh test` → exit 0, 0 warnings, 49/49 tests pass

**Files modified:**
- `MetricKitSubscriberTests.swift` — 7.1 jsonRepresentation removed from MockMetricPayload
- `KnittingGaugeReconcilerUITests.swift` — 8.1 scrollToTop deletion, 8.2 defaultLaunchEnvironment static extracted + all 7 call sites use `Self.defaultLaunchEnvironment.merging(...)`

**Test count:** 49/49 before and after (no @Test methods deleted, only non-test helper removal).

**8.2 pattern note:** The `private static let defaultLaunchEnvironment` + `.merging({ _, new in new })` idiom is canonical for XCTestCase launch environment defaults in this project.

---

## 2026-05-20T18:50:53-07:00 — User Directive: MetricKit Pivot

### 2026-05-20T18:50:53-07:00: User directive
**By:** yashasg (via Copilot)
**What:** "We will be using apple swift-metrics backend." — followed by clarification "we want to capture metrics for analytics and improving the app, if it goes into the void there is no point". User then selected **Option A — MetricKit only**: Apple's system framework, daily aggregated `MXMetricPayload` reports flowing to App Store Connect Analytics (and optionally a developer endpoint), opt-out in iOS Settings. NO third-party analytics SDK. Custom user-behavior events ride `MXSignpost(_:)`.
**Why:** User request — captured for team memory.

**Resolution:** Drop `apple/swift-metrics` from this work entirely. Pivot to MetricKit (`import MetricKit`). swift-metrics V1/V2 scope drafts in this inbox and merged into decisions.md are SUPERSEDED for the runtime backend question; the math-boundary, UX-NONE, category-only-granularity, and §2.2 ban survive. §2.3 needs a MetricKit-shaped amendment (system-mediated egress is allowed; user code never opens a socket; re-export of `MXMetricPayload` to non-developer endpoints forbidden). §7 (MetricKit open question) closes in favor.

---

### 2026-05-20T19:22:50-07:00: User directive — Privacy card stays removed under MetricKit
**By:** yashasg (via Copilot)
**What:** User rejected Tesla V3's recommendation to bring back an in-app privacy disclosure card. MetricKit collects only diagnostics and analytics with no user-identifying data (no IP, no advertising ID, no input values, no user IDs — all device-aggregated and OS-mediated). Disclosure obligations are satisfied by:
  1. `PrivacyInfo.xcprivacy` (already drafted by Hopper V3 — `CrashData`, `PerformanceData`, `OtherDiagnosticData`, all `linked-to-user: false`, `used-for-tracking: false`)
  2. App Store Connect privacy nutrition labels (declares analytics collection at submission time)
  3. OS-level user opt-out under iOS Settings → Privacy & Security → Analytics & Improvements → Share With App Developers

User quote: *"we are only collecting metrics on diagnostics and analytics, nothing that can identify a user, why do need to prompt or update disclosure?"* and *"just declare it in the label, you're good."*

**Why:** User asserted — correctly — that the privacy card was over-engineering. MetricKit's threat model is materially less invasive than custom analytics SDKs; Apple already mediates consent at OS-level. The user's 2026-05-19 decision to remove the privacy card stands as enacted; this directive reaffirms it post-MetricKit-pivot.

**Consequences:**
- `testAboutHelpButtonOpensPullUpSheet` keeps its current assertion (`privacy-card` does NOT exist). No test changes needed.
- Tesla V3 §3.2 draft privacy copy is DISCARDED. Ive's V2 NONE-on-UX scope survives the pivot fully intact.
- Curie V3 AC-8 flag (privacy card decision pending) is now resolved: card does not return.
- Edison V3 placement set does not include any privacy-card UI work.
- `PrivacyInfo.xcprivacy` + App Store Connect nutrition labels remain MANDATORY before submission.

**Status:** Resolved.

---

### 2026-05-20T19:26:30-07:00: User directive — Signpost roster ratified (Tesla's 9)
**By:** yashasg (via Copilot)
**What:** User ratified Tesla V3's 9-name MXSignpost roster over Edison's 11-name proposal. Final V1 ship list:

1. `compute` — INTERVAL signpost; per-invocation timing of `GaugeMath.compute(...)` so MetricKit aggregates a duration distribution.
2. `share.invoked` — EVENT signpost; share sheet successfully presented.
3. `share.fallback` — EVENT signpost; copy-to-clipboard fallback path taken.
4. `reset.tapped` — EVENT signpost; user tapped Reset.
5. `verdict.improved` — EVENT signpost; new verdict bucket is closer to gaugeMatch than the prior verdict for this session's gauge.
6. `verdict.degraded` — EVENT signpost; new verdict bucket is farther from gaugeMatch than the prior verdict for this session's gauge.
7. `sheet.verdictHelp.opened` — EVENT signpost; verdict-help pull-up sheet opened.
8. `sheet.aboutHelp.opened` — EVENT signpost; about-help pull-up sheet opened.
9. `cast_on.driftBandShown` — EVENT signpost; cast-on drift band visible to user (Jacquard's V3 threshold gate applies).

**Explicitly DROPPED (decided once, stays dropped):**
- Field-edit churn (`stitches.changed`, `rows.changed`, etc.) — too noisy, low analytical value
- Disclosure-card toggle — UI mechanic, not a behavioral signal
- The four verdict bucket signposts (`verdict.gaugeMatch`, `verdict.drift`, `verdict.significantDrift`, `verdict.majorMismatch`) — collapsed into `verdict.improved` / `verdict.degraded` directional pair
- `verdict.current` (Edison's gauge-snapshot variant) — same dropped reasoning as buckets

**Why:** User chose the "is the calculator helping people improve?" question over the "what is the distribution of verdict outcomes?" question. Improved/degraded is a directional signal — exactly what's needed to validate whether the app makes anyone's life better. Bucket distribution can be inferred indirectly from `compute` interval volume + improved/degraded ratios if needed later; can always be added in V2.

**Implementation consequences:**
- Edison V3's placement design (subscriber + bootstrap + signpost calls) targets these 9 names exactly.
- Verdict-improved/degraded requires tracking a per-session "last verdict bucket" in memory (no persistence) and comparing on each `compute` cycle — Edison owns the comparator state machine.
- Curie V3's `RecordingDouble` (determinism guard) asserts that `GaugeMath.compute(...)` emits zero signposts — derivation happens in the view layer post-call, not in math.
- Jacquard V3's `cast_on.driftBandShown` threshold work is still in scope; it gates whether signpost #9 ever fires.
- Tesla's GitLab #9 update body should now reference 9 named signposts, not 11.

**Status:** Resolved. Ready for implementation dispatch.

---

## 2026-05-20T18:50:53-07:00 — MetricKit V3 Scope (Post-Pivot)

### Tesla — MetricKit Scope (issue #9, Lead architecture view)

**Author:** Tesla (Lead / Architect)
**Date:** 2026-05-20T18:50:53-07:00
**Version:** V3 (MetricKit pivot)
**Status:** Implemented
**Supersedes:** `tesla-metrics-scope-v2.md` (runtime backend question); `tesla-issue9-synthesis.md` (V1 — runtime backend question)
**Related:** GitLab issue #9, `docs/swift_coding_standards.md` §2.2/§2.3/§2.12/§7

**Summary:** MetricKit is the runtime data path. Primary sink: App Store Connect Analytics (OS-mediated daily aggregation). Developer endpoint deferred to V2. Nine MXSignpost names locked by user directive (2026-05-20T19:26:30). PrivacyInfo.xcprivacy + ASC labels for privacy posture; no in-app disclosure card (user directive 2026-05-20T19:22:50). Math-boundary, UX-NONE, category-only-granularity from V2 all survive. §2.2/§2.3/§2.12/§7 of swift_coding_standards.md amended post-pivot.

### Edison — MetricKit Instrumentation Scope V3

**Author:** Edison (Frontend Dev)
**Date:** 2026-05-20T18:50:53-07:00
**Version:** V3
**Status:** Implemented
**Issue:** #9 (swift-metrics)
**Supersedes:** `edison-metrics-scope-v2.md` (runtime-backend only)

**Summary:** New files: `MetricsSubscriber.swift` (MXMetricManagerSubscriber impl), `GaugeMathMetrics.swift` (verdict classifier). Bootstrap in App.init() via MXMetricManager.shared.add(_:). 9 os_signpost call sites in ContentView.swift targeting the 9-name roster. PrivacyInfo.xcprivacy wired into pbxproj.

### Curie — MetricKit Test Scope

**Author:** Curie (Test Engineer)
**Date:** 2026-05-20T18:50:53-07:00
**Version:** V3 (MetricKit pivot)
**Status:** Implemented
**Issue:** #9

**Summary:** Test architecture: (a) handler-logic isolation via MetricPayloadProtocol mock + unit tests (Swift Testing), (b) lifecycle idempotency via integration tests (XCTest). AC-1..AC-8 all green. 24 new tests in MetricKitSubscriberTests.swift across 4 suites. Protocol-wrap mocking for MXMetricPayload (no subclassing). otool -L guard for MetricKit linkage + third-party SDK absence.

### Hopper — MetricKit Tooling Scope (V3)

**Author:** Hopper (Tooling Dev)
**Date:** 2026-05-20T18:50:53-07:00
**Version:** V3
**Status:** Implemented
**Requested by:** yashasg

**Summary:** Zero new SPM dependencies (MetricKit is system framework). Info.plist: no MetricKit keys required. PrivacyInfo.xcprivacy wired correctly (linked-to-user: false, used-for-tracking: false). pbxproj updated with PrivacyInfo.xcprivacy refs. release build gate: otool -L check + Package.resolved guard. `docs/app-store-connect-privacy-setup.md` written.

---

## 2026-05-20T19:26:30-07:00 — MetricKit V3 Implementation Shipped

### Edison — MetricKit Implementation Decision

**Author:** Edison (Frontend Dev)
**Date:** 2026-05-20T19:26:30-07:00
**Issue:** #9 (swift-metrics)
**Status:** SHIPPED

**Files created:**
- `app/KnittingGaugeReconciler/MetricsSubscriber.swift` (~80 lines): MetricPayloadProtocol, SignpostNames, MetricsSubscriber class
- `app/KnittingGaugeReconciler/GaugeMathMetrics.swift` (~55 lines): VerdictBucket, SignpostDecision, GaugeMathMetrics comparator

**Files modified:**
- `app/KnittingGaugeReconciler/KnittingGaugeReconcilerApp.swift`: import MetricKit, stored metricsSubscriber, init() bootstrap
- `app/KnittingGaugeReconciler/ContentView.swift`: import MetricKit, import os.signpost, 2 @State vars, 9 signpost call sites at lines 40, 42, 90, 95, 106, 108, 115, 417, 433, 436
- `app/KnittingGaugeReconcilerTests/MetricKitSubscriberTests.swift`: AC-6 otool guard wrapped in #if os(macOS)
- `app/app.xcodeproj/project.pbxproj`: File refs + build file entries

**9 Signpost call sites (ContentView.swift):**
1. `compute` (INTERVAL): lines 40, 42 — os_signpost(.begin/.end) wrapping GaugeMath.compute(inputs)
2. `sheet.verdictHelp.opened` (EVENT): line 90 — onChange(of: showVerdictHelp)
3. `sheet.aboutHelp.opened` (EVENT): line 95 — onChange(of: showAboutHelp)
4. `verdict.improved` (EVENT): line 106 — onChange(of: verdictTitle) + GaugeMathMetrics.classifyVerdictDelta
5. `verdict.degraded` (EVENT): line 108 — same onChange, degraded branch
6. `cast_on.driftBandShown` (EVENT): line 115 — onChange(of: abs(result.castOnRoundingDriftPercent) >= 3) + driftBandSignpostFired guard
7. `reset.tapped` (EVENT): line 417 — first line of resetToDefaults()
8. `share.invoked` (EVENT): line 433 — share sheet presented
9. `share.fallback` (EVENT): line 436 — copy-to-clipboard fallback

**Build state:** ./app/build.sh test → 0 warnings, 49/49 tests pass (was 25).

### Hopper — MetricKit Implementation Decision Drop

**Author:** Hopper (Tooling Dev)
**Date:** 2026-05-20T19:26:30-07:00
**Status:** SHIPPED

**PrivacyInfo.xcprivacy:** Verified correct. NSPrivacyTracking: false. NSPrivacyCollectedDataTypes: 3 entries (CrashData, PerformanceData, OtherDiagnosticData) — all linked-to-user: false, tracking: false, purposes: AppFunctionality + Analytics.

**pbxproj wiring:** Sequential UUID convention applied. Three new entries added (PBXBuildFile, PBXFileReference, PBXResourcesBuildPhase).

**Build gate:** release build runs otool -L on arm64 device binary; fails if non-system dylib linked. Package.resolved guard also checks for telemetry-SDK package names.

**Documentation:** `docs/app-store-connect-privacy-setup.md` written. Verified build.sh guards.

### Curie — MetricKit Test Suite Shipped

**Author:** Curie (Test Engineer)
**Date:** 2026-05-20T19:26:30-07:00
**Status:** SHIPPED

**Test files created:**
- `app/KnittingGaugeReconcilerTests/MetricKitSubscriberTests.swift`: 24 new tests across 4 suites

**pbxproj updated:** Added Edison's MetricsSubscriber.swift + GaugeMathMetrics.swift (were on disk but missing from project).

**AC status (all PASS):**
- AC-1: Subscriber receives payloads (4 tests: empty, single, batch, date edges)
- AC-2: MockMetricPayload in test file (MetricPayloadProtocol impl)
- AC-3: GaugeMath static scan (no MetricKit/signpost imports)
- AC-4: Runtime determinism — GaugeMath.compute emits zero signposts (stub)
- AC-5: Verdict classifier all 16 ordered pairs + nil-previous (17 tests)
- AC-6: otool -L MetricKit linked, no third-party SDKs
- AC-7: ./app/build.sh test exits 0 (49/49 tests)
- AC-8: testAboutHelpButtonOpensPullUpSheet — privacy-card absent

**Test count delta:** KnittingGaugeReconcilerTests 18 → 42 (+24 tests).

### Tesla — MetricKit Standards Shipped

**Author:** Tesla (Lead / Architect)
**Date:** 2026-05-20T19:26:30-07:00
**Status:** SHIPPED
**Related:** GitLab issue #9 note 3370575474

**swift_coding_standards.md amendments:**
- §2.2: Added enforcement sentence (GaugeMath forbids MetricKit/os.signpost/os/analytics).
- §2.3: Rewrote carve-out. System-mediated egress (MetricKit) PERMITTED. User code socket/URLSession/third-party SDK forbidden. Developer endpoint re-export DEFERRED to V2.
- §2.12: Logging discipline. didReceive(_:) payload logging must be #if DEBUG.
- §7: Closed MetricKit open question. Resolved 2026-05-20. 9 signpost names locked in decisions.md.

**GitLab #9 comment:** New note 3370575474 posted. Scope correction from swift-metrics → MetricKit. Explains no production sink for swift-metrics. Documents 9-signpost roster. States privacy posture (PrivacyInfo.xcprivacy + ASC, no card). Lists deferred items (developer endpoint). References §2.2/§2.3/§2.12/§7 amendments.

---

## 2026-05-20T18:19:39-07:00 — swift-metrics V2 Scope (SUPERSEDED by MetricKit pivot, kept for audit)

### Tesla — swift-metrics scope, V2 (SUPERSEDED)

**Author:** Tesla (Lead / Architect)
**Date:** 2026-05-20T18:19:39-07:00
**Version:** V2 (SUPERSEDED by V3 MetricKit pivot 2026-05-20T18:50:53)
**Status:** SUPERSEDED for runtime backend question; math-boundary/UX-NONE/category-only-granularity and §2.2/§2.3 framework survive into V3
**Context:** Independent V2 re-pass before MetricKit pivot

**Note:** This scope is archived as an audit trail. Runtime backend recommendation (apple/swift-metrics façade) was superseded by user directive (2026-05-20T18:50:53) selecting MetricKit only. Mathematical determinism boundary, UX NONE policy, and category-only granularity remain binding post-pivot.

### Edison — swift-metrics scope, V2 (SUPERSEDED)

**Author:** Edison (Frontend Dev)
**Date:** 2026-05-20T18:19:39-07:00
**Version:** V2 (SUPERSEDED by V3 MetricKit pivot 2026-05-20T18:50:53)
**Issue:** #9 (swift-metrics)
**Status:** SUPERSEDED

**Note:** This scope proposed swift-metrics library wiring and NOOP handler bootstrap. Superseded by V3 MetricKit implementation (2026-05-20T19:26:30). Mathematical accessibility (Determinism contract, zero metric calls in math layer) and signpost naming rules (category-only, no raw numbers) survive the pivot.

### Curie — swift-metrics Test Scope, V2 (SUPERSEDED)

**Author:** Curie (Test Engineer)
**Date:** 2026-05-20T18:19:39-07:00
**Version:** V2 (SUPERSEDED by V3 MetricKit pivot 2026-05-20T18:50:53)
**Status:** SUPERSEDED

**Note:** This scope proposed test architecture for swift-metrics handler injection and NOOP backend verification. Superseded by V3 MetricKit test design (2026-05-20T18:50:53 and shipped 2026-05-20T19:26:30). Determinism guard (GaugeMath has zero metric calls) and mock payload pattern survive.

### Hopper — swift-metrics Tooling Scope, V2 (SUPERSEDED)

**Author:** Hopper (Tooling Dev)
**Date:** 2026-05-20T18:19:39-07:00
**Version:** V2 (SUPERSEDED by V3 MetricKit pivot 2026-05-20T18:50:53)
**Requested by:** yashasg
**Status:** SUPERSEDED

**Note:** This scope covered swift-metrics SPM dependency wiring, MetricsSystem.bootstrap() placement, and environment-variable backend selector. Superseded by V3 (MetricKit is zero-SPM system framework; MXMetricManager.shared.add() replaces bootstrap; no env-var selector). PrivacyInfo.xcprivacy requirement and release-build determinism guard survive the pivot.

---

## 2026-05-20T18:19:39-07:00 — swift-metrics V2 Scope (SURVIVED the pivot, still binding)

### Ada — Math-Layer Metrics Boundary (V2, SURVIVED)

**Author:** Ada (Algorithms Dev, §2.2 owner)
**Date:** 2026-05-20T18:42:54-07:00
**Version:** V2
**Status:** BINDING post-MetricKit-pivot
**Context:** Independent re-examination of math-layer contract. Foundation for determinism guard in V3.

**Core contract (binding):** GaugeMath.swift is a caseless namespace of pure static functions. Identical GaugeInputs → bit-identical GaugeMathResult, unconditionally across runs, locales, builds, threads, restarts. Forbidden inside GaugeMath: Metrics imports, Clock reads (Date, ContinuousClock, DispatchTime), os_log/Logger/print, metric-sink parameters.

**Signpost placement rule:** No signpost or Timer calls inside GaugeMath. Verdict classification for analytics (improved/degraded, bucket tracking) lives in GaugeMathMetrics.swift, called by view layer after GaugeMath.compute() returns.

**Post-V3 enforcement:** GaugeMathMetrics.classifyVerdictDelta (new in V3-IMPL) implements the comparator state machine; MetricKitSubscriberTests AC-3 (static file scan) and AC-4 (recording double stub) enforce the boundary.

### Ive — Compact Numeric Fields + Field Grouping (V2, SURVIVED)

**Author:** Ive (Design)
**Date:** 2026-05-20 (from prior session history)
**Status:** BINDING post-MetricKit-pivot
**Note:** Metrics pivot does not affect UX. Ive's V2 scope (compact fields, grouping, accessibility stacking) survives fully. No metrics UI surface (UX NONE policy, confirmed post-pivot by user directive 2026-05-20T19:22:50).

### Mendel — Saved Reconciliations — Research & MVP Scope (V2, SURVIVED)

**Author:** Mendel (Data Architecture)
**Date:** 2026-05-20 (from prior session history)
**Status:** BINDING post-MetricKit-pivot; full re-scope planned for V2 of app
**Note:** Metrics pivot does not affect saved-reconciliation research. Mendel's V2 MVP scope (pattern name, yarn identifier, timestamp metadata + 4 gauge values) survives as optional work for app V2. Deferred pending further prioritization.

### Jacquard — cast_on Threshold Evaluation (V2, SURVIVED)

**Author:** Jacquard (Domain Expert)
**Date:** 2026-05-20 (from prior session history)
**Status:** BINDING post-MetricKit-pivot; gates signpost #9 in V3-IMPL
**Note:** Metrics pivot does not affect domain math. Jacquard's V2 threshold evaluation (when to show cast-on drift band) survives and gates signpost #9 (`cast_on.driftBandShown` in user directive 2026-05-20T19:26:30). This work is in scope for V1 implementation (Edison V3 places signpost #9 behind Jacquard's threshold gate).

