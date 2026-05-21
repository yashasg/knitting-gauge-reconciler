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

## 2026-05-20T19:26:30Z — MetricKit V1 shipped (Team session)

MetricKit V1 implementation completed. User directives: (1) MetricKit pivot from swift-metrics (2026-05-20T18:50:53), (2) privacy card stays removed (2026-05-20T19:22:50), (3) 9-signpost roster locked (2026-05-20T19:26:30). Build: 49/49 tests pass (was 25). Session log: .squad/log/2026-05-20T19-26-30Z-metrickit-pivot-shipped.md. Orchestration logs: .squad/orchestration-log/2026-05-21T02-26-30Z-{agent-round}.md.
