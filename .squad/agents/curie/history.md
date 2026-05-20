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
