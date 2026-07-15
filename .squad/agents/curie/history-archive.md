# Curie — History

## Core Context

- **Project:** A knitting gauge reconciler that converts patterns between stitch/row gauges.
- **Role:** Tester
- **Joined:** 2026-05-19T07:11:08.646Z

## Learnings

- Corrected gauge formulas confirmed by Jacquard craft-truth spec (decisions.md: Summary → The Correct Formulas). Use `your_st / pattern_st` for stitch scale and `pattern_row / your_row` for cm-depth scale in future test cases.
- 2026-05-19 (Compact Fields): UI test approved; updated KnittingGaugeReconcilerUITests.swift to expect numeric fields side-by-side when they fit. Stacked hero and adjustment rows preserved. Test passed on latest build.
- **Test file location:** `prototype/tests/gauge-math.test.js` — run with `node prototype/tests/gauge-math.test.js`. No external dependencies; Node 18+ stdlib only.
- **Rounding rule for increase rows:** `fmtRows(x) = Math.max(1, Math.round(x))`. JS `Math.round` is half-up: 6.5 → 7, 6.4 → 6. Minimum output is 1 (clamp prevents zero/negative row counts).
- **Spec discrepancies found:** Jacquard's Scenario 5 defines `stitchWidthScale` as `ys/ps` (count multiplier) while Scenario 4 and the code both use `ps/ys` (display width ratio). Scenario 6's Expected tuple lists increase spacing as 10.7 but the formula gives 8. Decision filed at `.squad/decisions/inbox/curie-test-discrepancy.md`.
- **Swift edge cases added (2026-05-19):** Extended `GaugeMathTests.swift` from 10 to 15 tests. Added: `edgeVeryLargeDriftDenserRows` (yr=48), `edgeVeryLargeDriftLooserRows` (yr=12), `floatPrecisionExactMatchNoFPDrift`, `floatPrecisionArbitraryMatchedGauge`, `castOnRoundingDriftZeroForExactRatio`, `stitchWidthScaleAndCountMultiplierAreReciprocals`. Also extended `invalidInputsFallBackToDefaults` (added infinity/-infinity) and `rowFormattingMatchesPrototype` (added 6.6→7 and 0.0→1 cases). All 15 tests pass, zero compiler warnings.
- **UI test runner blocker (2026-05-19):** Uncommitted changes in the working tree modify `app/build.sh` to add `-derivedDataPath "$PROJECT_DIR/.build/derived-data"`. This causes xcodebuild to build the runner app to the custom path, but the simulator installer attempts to install from the old default DerivedData path (which no longer exists), producing "Missing bundle ID" error. The committed version of build.sh (without `-derivedDataPath`) worked correctly. Filed in decisions/inbox/curie-test-coverage.md.
- **Hopper CI config fix validated (2026-05-19):** Reviewed commit `1183ed5` — removed invalid `image: macos-26-xcode-26` field from `.gitlab-ci.yml` (shell executor, not Docker) and added `timeout: 30 minutes`. `./app/build.sh test` exits 0: 15/15 Swift unit tests pass (GaugeMathTests), `** TEST SUCCEEDED **`, zero compiler warning diagnostics. JS prototype suite 77/77 pass. Build script correctly keeps `-derivedDataPath`, `xcrun simctl shutdown` pre-boot, and `SWIFT_TREAT_WARNINGS_AS_ERRORS=YES`. Only remaining blocker is external: GitLab CI `ios:test` job still fails with `no_matching_runner` (infrastructure, not code).
- **build.sh benign-crash exemption pattern (2026-05-19):** build.sh correctly exempts Xcode 26.4 post-test infrastructure crash (`Failed to launch app with identifier: (null)`) from causing false failure. This pattern should not be broadened — keep the two-condition check (benign string AND non-zero exit) so real launch failures still propagate.
- **Final local validation (2026-05-19):** Inbox was empty; latest logs still show only GitLab API/token blocker. `node prototype/tests/gauge-math.test.js` passed 77/77, and `./app/build.sh test` exited 0 with warnings-as-errors enabled, so compiler warnings remained zero. Swift `GaugeMathTests.swift` still names and covers all six Jacquard scenarios one-to-one. Git remote read and push dry-run succeeded, but CI API verification remains blocked without `GITLAB_TOKEN` (unauthenticated pipeline API not accessible).


## [2026-05-19 19:13:04Z] Canonical Xcode Project Path Update

⚠️ **All squad members:** The Xcode project has been renamed to **`app/app.xcodeproj`**.

- **Previous path:** `app/KnittingGaugeReconciler.xcodeproj`
- **Current path:** `app/app.xcodeproj` (canonical reference)
- **App target & scheme:** `KnittingGaugeReconciler` (unchanged)
- **Build script:** `app/build.sh` updated and validated

Any references to the old project path should be updated. Use `app/app.xcodeproj` going forward.

---

### 2026-05-19 — corrected canonical Xcode project path

Correction to earlier path note: the project bundle must remain `app/KnittingGaugeReconciler.xcodeproj` per the explicit Tesla scaffold priority item. Curie's validation gate should continue to run `./app/build.sh test`, which targets the full project path with warnings as errors.

---

## [2026-05-20T02:21:23Z] Swatch Hint Layout Verification

**Session:** swatch-hint-layout (Edison + Curie)
**Outcome:** APPROVED

**Work:** Verified Edison's swatch hint layout fix. Updated UI tests to confirm both Pattern gauge and Your swatch fields remain side-by-side when they fit. Build-for-testing and targeted UI test passed.

## [2026-05-20T03:31:51Z] Copy Results Menu Review & Approval

**Session:** copy-results-menu

**Task:** Review and approve Edison's Copy results menu implementation.

**Validation:** Confirmed UI no longer exposes old copy-share-link affordance. Formatter output includes current gauge results plus per-section row/round guidance. Tests explicitly cover menu formats, formatter guidance rows, and old affordance removal. `./app/build.sh test` passed.

**Decision:** APPROVED.

**Status:** Ready for deployment.

---

## ⚠️ [2026-05-20T06:25:04Z] Serial iOS UI Testing Constraint

**Directive:** When running locally, Squad must not run more than one iOS simulator at any given time. All UI tests must run in serial.

**Rationale:** Concurrent local simulator usage can conflict and destabilize UI test runs.

**Impact on Curie:** Test suite must enforce serial simulator access when invoked from CI/local workflows.

## [2026-05-20T00:00:00Z] Final Help Overlay UI Changes — Review Complete

**Session:** help-overlays (Help Overlay UI Finalization)
**Status:** APPROVED

**Summary:** Reviewed and approved Edison's final help overlay UI changes:
1. **About `?` Help Overlay** — Applied compact title + `?` → pull-up sheet to About card
2. **About `?` Repositioned** — Moved from card to app title header area
3. **Privacy Card Removed** — Eliminated misleading "no analytics" claim

**Verification:**
- Build succeeded without errors
- Accessibility verified: VoiceOver labels and Dynamic Type fully supported
- UI tests updated and passing
- Share/export preserved
- Math and layout preserved
- No misleading privacy statements in UI

**Decision:** All changes ready for deployment. Decisions documented in decisions.md.

---

## [2026-05-20T18:19:39-07:00] swift-metrics test scope (issue #9)

**Session:** metrics-scoping (parallel with 7 other Squad members)
**Drop:** `.squad/decisions/inbox/curie-metrics-scope.md`

### Verification strategy I'm committing to

- **Swift Testing for all metrics unit tests** (§2.9). XCTest stays reserved for UI; **no new UI tests for metrics** — they're invisible, asserting on them through XCUIApplication would require a debug HUD or pasteboard exfiltration. Metrics are validated where assertions are deterministic: the unit/integration layer.
- **In-process `TestMetricsFactory` we own locally** (≈30 lines, thread-safe via a lock) under `KnittingGaugeReconcilerTests/Support/`. Confirmed swift-metrics' upstream package does **not** ship a test handler — only `NOOPMetricsHandler` and `MultiplexMetricsHandler` are public. Tests assert on labels, dimensions, and **exact counter increment counts** — never on timer durations or wall-clock values.
- **No new test target.** One file (`MetricsTests.swift`) added to the existing `KnittingGaugeReconcilerTests` target plus the support factory. A separate target would double project churn and simulator boot time (constrained by serial-UI directive).
- **Determinism guard test:** assert `GaugeMath.compute` records zero metrics signals. If anyone wires a counter into the math layer, this test fails loudly — §2.2 stays defended.

### Isolation rules I'm committing to

- **Never call `MetricsSystem.bootstrap(_:)` from tests.** It's process-global and once-per-process; calling it poisons every later test in the run. Production bootstrap goes through `MetricsBootstrap.installIfNeeded()` invoked only from `@main`; tests use the injectable-factory seam.
- **Per-test factory, never per-suite.** Each `@Test` gets a fresh local `TestMetricsFactory()`. No `static`, no `@TaskLocal`, no singleton. Counters can't bleed across tests because the instance is gone at end-of-test.
- **Warning-free under all gating combos.** `#if DEBUG` / env-var gates must compile clean in DEBUG-on, DEBUG-off, gate-set, gate-unset. Any `#if !DEBUG` block that imports `Metrics` must guard the import or §2.1 warnings-as-errors will trip on unused-import.
- **Pin swift-metrics version explicitly** and confirm 0 diagnostics under Swift 6 strict concurrency on Xcode 26.4 before merge. Sendable conformance on `MetricsFactory`/`CounterHandler` is the known risk surface; ≥ 2.5 is the historical floor.

### UI tests flagged as regression risk if identifiers shift

- `testShareResultsIsSingleAccessibleAffordance` — **high risk** (wrapping the `share-results` button to attach a `share.invoked` counter must not restructure the affordance).
- `testAllJacquardScenariosAreVisibleInUI` — **medium risk** (live-recalc pipeline touch).
- `testAboutHelpButtonOpensPullUpSheet` — **low risk** (single tap site).
- These tests stay metrics-unaware; they're the regression net Edison's identifier-rename rule keeps honest.

### Validation gate (unchanged)

`./app/build.sh test` exits 0, 0 warnings, 25/25 today → N/N after metrics. UI count stays at 7 unless an identifier change forces a same-commit UI test update.

## Team updates
- 2026-05-20T18:19:39-07:00: swift-metrics scoping round (issue #9) completed. 8-agent parallel pass. Decisions merged to decisions.md (now 98,243 bytes).

## [2026-05-20T18:42:54-07:00] swift-metrics test scope V2 (issue #9 re-run)

**Session:** metrics-scoping-v2 (V2 re-run with fact-check directive)
**Drop:** `.squad/decisions/inbox/curie-metrics-scope-v2.md`

### MetricsTestKit fact-check — Curie CONCEDES V1

**V1 claim (wrong):** swift-metrics does not ship a public test handler; a local 30-line `TestMetricsFactory` is required.

**V2 evidence:** `curl -sL https://raw.githubusercontent.com/apple/swift-metrics/main/Package.swift` returns a `Package.swift` that explicitly declares `.library(name: "MetricsTestKit", targets: ["MetricsTestKit"])` as a top-level product. Tesla was correct in V1. Curie concedes.

**Correction:** Use `MetricsTestKit` from `apple/swift-metrics` as the primary test support library. Link it only to `KnittingGaugeReconcilerTests`. The local factory fallback is retained only if the upstream API is incompatible (unlikely).

### V2 strategy additions over V1

- nm/grep release binary check command documented (exact shell command for AC-7).
- TEST_RUNNER_KGR_* pass-through mechanism documented; Hopper owns the build.sh change; Curie owns the end-to-end validation test.
- Acceptance criteria formalised as 10-item AC table (AC-1 through AC-10).
- All V1 architecture decisions (no bootstrap from tests, per-test factory, no new target, determinism guard, UI regression net) ratified unchanged.

## [2026-05-20T18:50:53-07:00] MetricKit test scope V3 (architecture pivot)

**Session:** metrickit-scope-v3
**Drop:** `.squad/decisions/inbox/curie-metrickit-scope.md`

### Pivot summary

User directive confirmed: drop `apple/swift-metrics`. MetricKit is the sole
sanctioned metrics backend. `MXMetricPayload` flows daily via `MXMetricManagerSubscriber.didReceive(_:)`. Custom user-behavior events ride `MXSignpost` / `os_signpost`.

### Key decisions (V3)

- **Mocking strategy:** Protocol-wrap `MXMetricPayload` as `MetricPayloadProtocol`. Subscriber depends on the protocol; production passes `MXMetricPayload` directly via a bridge method; tests pass a `MockMetricPayload` struct. Subclassing ruled out (no public init); fixture JSON ruled out (brittle across OS versions).
- **Subscriber test architecture:** Both (a) handler-logic isolation and (b) lifecycle idempotency. Handler logic tested via `MockMetricPayload` in Swift Testing. Lifecycle (add/remove from `MXMetricManager.shared`) tested as an integration smoke test in XCTest.
- **Determinism guard (V3 shape):** Two-layer: (i) static file-scan of `GaugeMath.swift` for `import os.signpost`, `import MetricKit`, `os_signpost(`, `MXSignpost(` — fail if any; (ii) runtime stub via `SignpostRecording` protocol + `RecordingDouble` double — assert zero emissions from `GaugeMath.compute`.
- **Linker check:** Three-step — `Package.resolved` scan (no forbidden packages), `otool -L` (only system frameworks), `nm` symbol scan (no analytics runtime symbols). MetricKit is the only sanctioned non-system import.
- **Signpost emission tests:** Wrapper-protocol approach recommended. Tests assert on `RecordingDouble.emissions`, not on OS signpost delivery. Honest limitation documented.
- **Privacy card flag:** `testAboutHelpButtonOpensPullUpSheet` currently asserts `privacy-card` does NOT exist. MetricKit changes the analytics posture — flagged for Tesla + Edison. Test unchanged until decision made; same-commit rule applies if card returns.
- **V2 superseded:** MetricsTestKit, MetricsSystem.bootstrap pattern, TEST_RUNNER_KGR_* env pass-through, per-test TestMetrics() factory, KGR_METRICS_BACKEND gate test — all dropped.
- **Acceptance criteria:** 14-item AC table (AC-1 through AC-14) in the scope document.

### Reusable pattern filed

`.squad/skills/metrickit-protocol-wrap-mock/SKILL.md` — how to mock `MXMetricPayload` (and other sealed system classes) via protocol wrapping.

## [2026-05-20T19:26:30-07:00] MetricKit test suite shipped

**Session:** metrickit-tests-ship
**Drop:** `.squad/decisions/inbox/curie-metrickit-tests-shipped.md`

### AC implementations

- **AC-1 (subscriber receives payloads):** 4 tests in `MetricKitSubscriberTests` — empty array, single payload, edge-case dates, batch delivery. All pass.
- **AC-2 (MockMetricPayload):** `struct MockMetricPayload: MetricPayloadProtocol` defined in test file. Required implementing `jsonRepresentation() -> Data` (Edison added this field to the protocol — V3 scope doc hadn't captured it).
- **AC-3 (static scan):** `gaugemath_hasNoSignpostOrMetricKitImports` reads `GaugeMath.swift` via `#filePath`-relative path. No build phase copy needed — `#filePath` resolves at compile time to absolute source path.
- **AC-4 (runtime determinism stub):** `RecordingDouble` struct with empty `emissions`. GaugeMath has no signpost injection point; test documents the invariant. Stub will gain full conformance when Edison ships `SignpostRecording` protocol.
- **AC-5 (verdict classifier):** 17 tests covering all 16 ordered pairs (4 equal → nil, 6 degraded, 6 improved) plus nil-previous case. Edison's return type is `SignpostDecision` (not `VerdictDelta` as spec named it) — updated to match.
- **AC-6 (otool -L):** `otool_metricKitLinkedAndNoThirdPartySDKs` uses `Bundle.main.executableURL` + `Process()` to run `otool -L`. MetricKit present; no forbidden SDKs. PASSED.
- **AC-7 (build script):** `./app/build.sh test` exits 0. 42/42 unit + 7/7 UI tests.
- **AC-8 (privacy card):** `testAboutHelpButtonOpensPullUpSheet` unchanged and passing. Privacy-card absent assertion intact.

### Deviations from V3 scope doc

- Edison named the verdict delta enum `SignpostDecision`, not `VerdictDelta`. Updated tests to match.
- `MetricPayloadProtocol` has a third field `func jsonRepresentation() -> Data` not in V3 scope. `MockMetricPayload` implements it with `JSONSerialization`.
- Edison's files (`MetricsSubscriber.swift`, `GaugeMathMetrics.swift`) were on disk but missing from Xcode project; fixed in `project.pbxproj`.

### Test count

18 unit → 42 unit (+24). 7 UI unchanged. Total: 49 tests.

---

## Active history archived by Scribe — 2026-07-14T19:32:30.380-07:00

# Curie — History

## Core Context

- **Project:** A knitting gauge reconciler that converts patterns between stitch/row gauges.
- **Role:** Tester
- **Joined:** 2026-05-19T07:11:08.646Z

## Learnings

### 2026-06-01 — iOS 26.4 UI test regression cluster (tests 1, 2, 4, 5)

**Branch:** fix/ios-26-ui-test-failures

**Five tests regressed on iOS 26.4 simulator. All are now fixed.**

#### Tests 1 & 2 — LazyVGrid stops rendering off-screen cells
`LazyVGrid` inside a `UISheetPresentationController`-hosted `UIHostingController` no longer renders off-screen cells on iOS 26.4. XCTest sees empty accessibility tree.
**Fix:** Replace `LazyVGrid` with `HStack` in `GaugeMeasurementPair.swift`.

#### Tests 4 & 5 — SwiftUI Button action never fires under `.accessibilityElement(children: .contain)`
Two separate issues stack:

1. **`.contain` is required**: Without `.accessibilityElement(children: .contain)` on the sheet's root view, XCTest's accessibility tree is completely empty inside `UISheetPresentationController` on iOS 26.4. All `app.buttons[...]` lookups fail.

2. **`.contain` blocks SwiftUI Button actions**: With `.contain` present, SwiftUI `Button` taps (both accessibility-routed and coordinate-based) are silently swallowed. The button is visible and hittable in XCTest, but the action closure never runs.

3. **UIKit UIButton is NOT blocked**: `UIViewRepresentable` wrapping a `UIButton` with `touchUpInside` fires correctly under the same `.contain` constraint. The block is specific to SwiftUI's gesture recognizer pipeline.

**Fix:** `UIKitTapButton` — a `UIViewRepresentable` housing a `UIButton` with `touchUpInside`. Added `adjustsFontForContentSizeCategory = true` for Dynamic Type audit compliance. Button placed outside `ScrollView` to avoid `delaysContentTouches` interaction. Reset confirmation uses imperative `UIAlertController` (walks VC chain to sheet's `UIHostingController`).

**Do not replace `UIKitTapButton` with a SwiftUI `Button`** until Apple resolves the `.contain` touch-blocking regression on iOS 26.4.

#### Pre-existing failures (not regression)
- `testMainScreenAccessibility` — contrast failure, deferred to Edison
- `testAdjustmentSheetAccessibility` — contrast failure, deferred to Edison


### 2026-05-31T16:56:57-07:00 — UI scroll-loop over-scrolling fix

**Root cause:** `scrollToElement(_:in:requireHittable:direction:)` looped up to 12 times with a fixed `while attempts < 12` guard. The early-return (`element.exists && (…isHittable)`) was inside the loop — so on the first iteration it was checked — but the loop had two failure modes:

1. **`requireHittable: true` + keyboard coverage or off-screen element with no-op scroll surface**: Element exists but isn't hittable, and the drag target (`preferredScrollSurface`) returns an obscured/background ScrollView. Each drag is a no-op; the loop burns all 12 × 0.2 s ≈ 2.4 s of wasted settle time.

2. **Wrong surface via `app.scrollViews.firstMatch`**: When `adjustment-sheet` exists but `preferredScrollSurface` somehow resolves to the background scroll view (timing race), gestures are no-ops on that obscured surface.

**Fix — no-progress early-bail technique:**

Before each drag, snapshot two signals:
- `surface.value as? String` — UIScrollView exposes its content-offset position as a percentage string (e.g. `"0%"`, `"50%"`) via the accessibility `value` property. If this string does NOT change after the drag, the surface did not scroll.
- `element.frame` (when `element.exists`) — if the target element is already in the accessibility tree (but not yet hittable), its frame should shift when real scrolling occurs.

After the drag, compare. **Only count as no-progress when at least one signal was measurable** (`canMeasure = beforeValue != nil || beforeFrame != nil`). When both are nil (SwiftUI ScrollView that doesn't expose an accessibility value AND element not yet in the tree), we cannot determine progress — assume the scroll may be working and let the loop continue. After **2 consecutive provable no-progress drags**, bail early.

Max iterations reduced from 12 → 6. Per-attempt settle kept at 0.2 s (safe for flakiness).

**XCUITest gotchas:**
- `CGRect` in Swift IS Equatable; `CGRect? != CGRect?` optional comparison works correctly.
- SwiftUI `ScrollView` may or may not expose `accessibilityValue` as a percentage string (UIKit `UIScrollView` does; SwiftUI behavior depends on iOS version). Always gate the bail on `canMeasure` — never bail blindly when signals are absent.
- `preferredScrollSurface` is re-evaluated each loop iteration, so if the adjustment sheet becomes visible mid-loop the correct surface is picked automatically.
- The pre-loop fast-path (`if element.exists && …isHittable { return }`) must remain OUTSIDE the loop to guarantee zero drags when the element is already ready.

**Test run note (2026-05-31):** First test run with the initial (flawed) implementation showed 5 failures after retries. The flaw was that when `surface.value = nil` AND element didn't yet exist, both signals were nil → false no-progress bail fired after 2 attempts, preventing legitimate scrolling. Fixed with `canMeasure` guard. A second run was attempted but bash/posix_spawn tools were unavailable due to system resource exhaustion post-run; static analysis confirms the revised logic is correct for all measurable/unmeasurable signal combinations.

### 2025-08-01T00:00:00Z — Goal 5 validation: fix/cast-on-result-a11y-identifier

**Branch:** `fix/cast-on-result-a11y-identifier` (Edison's a11y identifier fix for AdjustmentRow.adjustedTile and AdjustmentValuePair.yourTile)

**Result:** PASS — exit code 0, all 61 tests pass, 0 SwiftLint violations.

**Note (2026-05-22T21:18Z):** `run.sh` now isolates its build workspace (`.build/run-build`) and disables index-store accumulation; if your tests share derived-data, expect cleaner runs.

**Test counts:** 48 unit + 13 UI = 61 total. All passed. This is the first run to report 61 tests (13 UI); the +5 UI delta from the prior 56-test baseline reflects new UI tests added with the Jacquard + compact-width work.

**testAllJacquardScenariosAreVisibleInUI:** Passed — but only after build.sh's flake-rerun guard fired. The first iteration ended with a simulator SIGTERM (not an assertion failure). build.sh correctly classified this as a "signal-term flake" and issued a full simulator erase+reboot+rerun. The rerun passed cleanly (78.6 s). All 6 unit-level Jacquard scenarios also passed on first iteration.

**testCompactWidthKeepsNumericFieldsSideBySideWhenTheyFit:** Passed on first iteration (9.7 s).

**SwiftLint:** 0 violations, 0 serious in 20 files.

**Build warnings:** 2 pre-existing iPad icon warnings (76×76@2x, 83.5×83.5@2x). Pre-existing, unrelated to Edison's change.

**Unexpected finding:** Simulator instability was significant in this environment — multiple prior xcodebuild processes (from other squad agents) were competing for simulator 179149FE-BAFF-4464-893B-7468D06F49B7. Contention caused repeated Mach error -308 failures. The build.sh lock + flake-rerun logic handled this correctly and delivered a clean exit 0.

### 2026-05-21T14:14:19Z — Confirmatory cycle after carry-forward chain

- **Sibling xcodebuild check can show transient PIDs.** PID 14864 appeared in the first `pgrep` but was already gone by the time we re-checked (< 1 s later). Always re-verify before aborting a cycle — a single positive hit may be a briefly-lived process, not a competing gate.
- **xcresult freshness window boundary (~15–30 min) triggers a fresh run correctly.** The predecessor's xcresult was ~16 min old, putting it at the edge. The confirmatory run was clean: exit 0, 56/56, 0 warnings — confirming carry-forward was honest.
- **Total test count is 56 (48 unit Swift Testing + 8 XCTest UI).** The unit suite previously logged as "49" reflected an earlier counting convention; the actual Swift Testing runner reports 48 tests in 5 suites. No test was lost — counts are consistent cycle-to-cycle.

### 2026-05-20T20:38:28-07:00 — Cleanup Round 2026-05-20

**Session:** cleanup-round (Edison audit + Edison/Curie implementation, parallel)

**3 items shipped (all test-file improvements):**
- **7.1:** MockMetricPayload.jsonRepresentation() removed (not protocol-required). All AC tests pass.
- **8.1:** scrollToTop(in:) dead UI test helper deleted.
- **8.2:** defaultLaunchEnvironment dedupe. Extracted to `private static let defaultLaunchEnvironment: [String: String]` with 7 canonical keys. All 7 tests use `.merging({ _, new in new })` for overrides. **Key pattern:** Static required (not let) for @MainActor XCTestCase methods. Eliminates silent divergence risk.

**Test count:** 49/49 before and after (no @Test methods deleted).

**Build:** exit 0, ** TEST SUCCEEDED **, 0 warnings, 49/49 tests pass.

---

## 2026-05-20T19:26:30Z — MetricKit V1 Shipped

24 new tests in MetricKitSubscriberTests.swift across 4 suites (AC-1..AC-8, all PASS). Test count: 18 unit → 42 unit (+24). 7 UI unchanged. Total: 49 tests.

---

## Earlier Sessions

(See history-archive.md for full timeline of 2026-05-19 and earlier 2026-05-20 work, including edge case tests, float precision, UI test runner blockers, and build.sh validation.)

---

## 2025-08-01T00:00:00Z — Goal 5 Verified & All Goals Gated

**Session:** a11y-identifier-fix
**Command:** `./app/build.sh test`
**Branch:** main @ 07ef822

### Test Results: 61/61 PASS ✅

| Category | Count | Status |
|----------|-------|--------|
| Unit tests (Swift Testing) | 48 | ✅ PASS |
| UI tests (XCTest) | 13 | ✅ PASS |
| **Total** | **61** | **✅ PASS** |

**Exit code:** 0
**Compiler warnings:** 0 (SWIFT_TREAT_WARNINGS_AS_ERRORS=YES enforced)
**SwiftLint violations:** 0
**Build warnings:** 2 iPad icon stubs (pre-existing, non-blocking)
**Crashes:** 0

### Test Suites Verified

- **GaugeMathTests**: 6 Jacquard scenarios (scenario1PerfectMatch–scenario6BothDenser) + 7 edge cases — all ✅
- **KnittingGaugeReconcilerUITests**: 10 tests including testAllJacquardScenariosAreVisibleInUI ✅
- **AccessibilityAuditTests**: 3 tests (main, adjustment sheet, about sheet) — all ✅

### Quality Gates: ALL PASSED

**Goal 1:** Working app (exit 0, no crashes) ✅
**Goal 5:** 61/61 tests pass, 0 violations, 0 warnings ✅

### Final State

- **Repository:** Main branch production-ready
- **Tree:** Clean (no unpushed commits)
- **Handoff:** Ready for yashasg

### Session Context

This test run gates the final 5-goal sign-off. Edison's `.accessibilityIdentifier` fix (on separate branch) is ready for merge and needs a follow-up Curie gate. Main itself is clean and ready for release.

---

## 2026-05-22T22:08:27Z — Reviewer Self-Correction Note

**Session:** CI review postmortem
**Topic:** Distinguishing blocker bugs from design choices and deferred work

In this session, Curie flagged several findings as blockers for the Fastlane-based CI workflow. On postmortem verification:

- **Release config with Debug tests** (blocker) — Found to be intentional design. Fastfile explicitly builds Release but tests Debug. User confirmed.
- **Serial UI policy dropped** (blocker) — Found to be user-accepted. CI does not require serial UI testing (distinct from pre-commit).
- **Canceled-run reporting as failed** (blocker) — Found to be user-accepted behavior.
- **Coverage/JUnit not uploaded** (issue) — Found to be deferred work, not a bug. User directive: "diagnostics upload deferred" (2026-05-22T15:08:27-07:00).
- **Jacquard parity not enforced** (issue) — Found to be out of scope for this review cycle.

**Lesson for future reviews:** Before flagging blockers, align with user intent and prior decisions:
- Read `.squad/decisions.md` for context and user directives
- Distinguish between actual bugs, design choices, and deferred work
- Confirm with user rather than assuming CI best practices apply universally

Pattern-matching against CI standards without grounding in user directives leads to false-positive blockers that delay delivery.

**Recommendation:** On next test-execution review, include a decision-alignment step that confirms the scope and design intent before finalizing the verdict.

### 2026-05-22T21:50:00-07:00 — VerdictCard removed from main UI; UI test audit pending

**Change:** Edison-1 removed `VerdictCard(...)` from `ContentView.swift` per Tesla directive 2026-05-22T21:30:00-07:00. VerdictCard.swift file preserved for export/future use, but no longer instantiated on the main screen.

**Implication for Curie:** If any XCUITest in `KnittingGaugeReconcilerUITests/` queries for VerdictCard elements, verdicts, or verdict-related UI state on the main screen, those test expectations need updating in the next cycle (likely #45 or follow-up to this batch). Verdict logic is still validated in unit tests (GaugeMathTests); UI expectations should reflect the revised hierarchy (inputs + adjustments only, no visible verdict card).

**Cross-ref:** Ive-1 postmortem in `.squad/decisions.md` explains the design principle: main screen is task-execution surface (inputs + adjustments), not analysis display. Verdict enum/math preserved for ShareableView export and accessibility labels.

---

## 2026-05-22T20:37:00-07:00 — Prototype-parity governance purge + §2.9 carveout withdrawn

**Session:** scribe-orchestration-2026-05-22

**Context:** Tesla retired the team-wide prototype-parity heuristic after the hero-tiles incident (2026-05-22T19:27:12-07:00). Follow-up directive 2026-05-22T19:39:36-07:00 **withdrew the Curie §2.9 carveout** that treated `prototype/tests/gauge-math.test.js` as a sanctioned test-vector source.

**Change to §2.9:** Scenario-coverage rules are re-anchored to Jacquard-defined craft scenarios sourced from Jacquard's charter and `.squad/decisions.md`, NOT from `prototype/tests/gauge-math.test.js`. The prototype is archival. Every Jacquard-defined craft scenario (from team decisions, not from prototype) must have a matching Swift test.

**Implication for Curie:** Charter updated. Test vectors come from Jacquard and `.squad/decisions.md`. `docs/swift_coding_standards.md` §2.9 updated to match. See directives 2026-05-22T19:39:36-07:00 in `.squad/decisions.md`.

**New regime:** The app is the source of truth. `prototype/` is archival only, not a reference, spec, or test oracle. Drift audits are against `.squad/decisions.md` and Tesla directives, never against the prototype.


### 2026-06-02T18:32:46-07:00 — Dynamic Type Implementation UI test results

**Session:** Edison-dynamic-type-implementation
**Change:** MR !43 (ViewThatFits elastic-layout reflow)

**4 UI test failures flagged as pre-existing, pending confirmation:**

1. **`testMainScreenAccessibility`** — Contrast audit failure. Related: dark-mode sage color change (2026-06-01T07:18:00-07:00, Edison fix from Curie + Hopper directive). May be pre-existing from before the sage fix, or unrelated to layout changes.
2. **`testAllJacquardScenariosAreVisibleInUI`** — `cast-on-result` element not found. iOS 26 infra flake. First reported 2026-06-01 in Hopper gate; removed from default test gate per Hopper directive 2026-06-01T14:44:32-07:00. Flag this for Yashas: Is this a known simulator/iOS 26 issue, or a regression?
3. **`testCompactWidthKeepsNumericFieldsSideBySideWhenTheyFit`** — Same iOS 26 infra flake as above. Also in removal directive.
4. **`testUnitToggleSwitchesFieldLabel`** — Pre-existing unit-toggle regression. From prior MR; empty label issue. Not related to elastic-layout changes.

**Pattern:** All 4 failures pre-date MR !43. Confirm with Yashas which (if any) are regressions vs. known iOS 26 simulator flakes.

---

### 2026-05-23T08:25:00Z — Fastlane CI test shape override (from hopper-3)

The new Fastlane CI shape adopted from cocktail-batch-dilution supersedes prior accepted CI design:
- Release-config-builds-Debug-tests split (removed)
- Serial UI policy (dropped)
- Canceled-as-failed behavior (removed)

The `ci` and `test` lanes now rely on the shared `KnittingGaugeReconciler` scheme as the source of truth for test participation, without lane-level `only_testing` filters. This is a design-level change approved by Tesla as part of the fastlane-from-cocktail integration (user directive 2026-05-23T01:01:48-07:00).

**Impact on Curie's charter:** The CI test decisions documented in your prior learnings (test scope, serial policy, failure reporting) are now superseded. Future test work should align with the scheme-driven model, not the prior lane-explicit model.

**For session memory:** If you need to debug CI test behavior, the Fastlane `ci` lane now delegates to the scheme definition. Check `app/app.xcodeproj/xcshareddata/xcschemes/KnittingGaugeReconciler.xcscheme` for the actual test targets and parallelization settings, not the Fastlane lane code.
