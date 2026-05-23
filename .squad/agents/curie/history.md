# Curie — History

## Core Context

- **Project:** A knitting gauge reconciler that converts patterns between stitch/row gauges.
- **Role:** Tester
- **Joined:** 2026-05-19T07:11:08.646Z

## Learnings

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


### 2026-05-23T08:25:00Z — Fastlane CI test shape override (from hopper-3)

The new Fastlane CI shape adopted from cocktail-batch-dilution supersedes prior accepted CI design:
- Release-config-builds-Debug-tests split (removed)
- Serial UI policy (dropped)  
- Canceled-as-failed behavior (removed)

The `ci` and `test` lanes now rely on the shared `KnittingGaugeReconciler` scheme as the source of truth for test participation, without lane-level `only_testing` filters. This is a design-level change approved by Tesla as part of the fastlane-from-cocktail integration (user directive 2026-05-23T01:01:48-07:00).

**Impact on Curie's charter:** The CI test decisions documented in your prior learnings (test scope, serial policy, failure reporting) are now superseded. Future test work should align with the scheme-driven model, not the prior lane-explicit model.

**For session memory:** If you need to debug CI test behavior, the Fastlane `ci` lane now delegates to the scheme definition. Check `app/app.xcodeproj/xcshareddata/xcschemes/KnittingGaugeReconciler.xcscheme` for the actual test targets and parallelization settings, not the Fastlane lane code.

