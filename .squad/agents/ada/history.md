# Ada — History

## Core Context

- **Project:** A knitting gauge reconciler that converts patterns between stitch/row gauges.
- **Role:** Algorithms Dev
- **Joined:** 2026-05-19T07:11:08.646Z

## Learnings

<!-- Append learnings below -->

### 2026-05-19 — Gauge math inversion fix

**Diagnosis:** The original `compute()` used `rowCountScale = yr / pr` as the multiplier for all vertical cm dimensions (actYoke, actBody, actSleeve), producing `20 × (32/24) = 26.7 cm` for a denser swatch — the wrong direction. A knitter whose rows are denser (more rows per cm) needs to knit *fewer* cm to match the pattern's intended row count, not more. The correct cm-dimension multiplier is `dimScale = pr / yr = 24/32 = 0.75`, giving `actYoke = 20 × 0.75 = 15.0 cm`. Increase-row spacing is a separate case: it is measured in rows and uses `yr / pr` (correctly) so the physical gap between increase events is preserved.

**Corrected formulas (math notation):**
- `dim_scale = pr / yr`  
- `actDim = patDim × dim_scale`  (all vertical cm: yoke, body, sleeve)  
- `actIncs = patIncs × (yr / pr)`  (row-count spacing — unchanged, already correct)

**Before/after (demo defaults — ps=32, pr=24, ys=32, yr=32):**
| | Before | After |
|---|---|---|
| actYoke | 26.7 cm | 15.0 cm |
| actBody | 66.7 cm | 37.5 cm |
| actSleeve | 60.0 cm | 33.8 cm |
| actIncs | 8 rows | 8 rows (unchanged) |

**Key file:** `prototype/index.html` — `compute()` function, ~lines 284–300; about panel line 212; breakdown lines 344–351.

### 2026-05-19 — Cast-on stitch count implementation

**Formula (Jacquard Formula 1):**
```
actStitches = patCastOn × (your_st / pattern_st)
```
This is the *forward* scaling: multiply the pattern's cast-on by the ratio of your stitch gauge to the pattern's stitch gauge. A looser gauge (fewer stitches/cm) produces a smaller ratio, yielding fewer stitches to maintain the same fabric width.

**Rounding rule:** `Math.round(exactStitches)` — nearest integer. No fractional stitches.

**Drift threshold:** `Math.abs(driftPct) >= 3` triggers `#pill-cast-on` (class `pill pill-warn`). For realistic knitting values (ps/ys in 20–40 range, cast-on ≥ 20 stitches), rounding at most 0.5 stitches against a cast-on ≥ 20 yields < 2.5% drift, so the pill is effectively a safety net for degenerate inputs only.

**URL hash short name:** `pc` (maps to `patCastOn` key)

**Default:** `patCastOn: 128` (128 ÷ 32 st/10cm = 40 cm half-circumference, typical small-medium sweater at demo gauge)

**Key DOM elements:** `#pat-cast-on` (input), `#act-cast-on` (output span), `#pill-cast-on` (drift pill, hidden by default), `#hint-cast-on` (aria-describedby hint)

### 2026-05-19 — Gauge math JS→Swift port audit (this session)

**Task:** Port `prototype/tests/gauge-math.test.js` and prototype JS math into Swift. Verify alignment with `decisions.md`.

**Findings — GaugeMath.swift:** All formulas were already correct. No changes required. Full mapping:
- `stitchWidthScale = patternStitches / yourStitches` (= ps/ys)
- `stitchCountMultiplier = yourStitches / patternStitches` (= ys/ps)
- `rowCountScale = yourRows / patternRows` (= yr/pr)
- `dimensionScale = patternRows / yourRows` (= pr/yr) — applied to all vertical cm outputs
- `adjustedCastOn = round(patternCastOn × ys/ps)`, with drift% tracking
- `fmtCm`, `fmtRows`, `fmtPct`, `sanitized` all correct

**Findings — GaugeMathTests.swift:** File was already at 169 lines with complete coverage, including all edge cases from the JS test file:
- 6 Jacquard scenarios (scenarios 1–6) ✓
- `invalidInputsFallBackToDefaults` (readNumPure parity) ✓
- `rowFormattingMatchesPrototype` — including fmtRows(6.6)==7 ✓
- `cmAndPercentFormattingMatchPrototype` ✓
- `edgeVeryLargeDriftDenserRows` (yr = 2×pr) ✓
- `edgeVeryLargeDriftLooserRows` (yr = pr/2) ✓
- `floatPrecisionExactMatchNoFPDrift` ✓
- `floatPrecisionArbitraryMatchedGauge` (non-power-of-2 values) ✓
- `castOnRoundingDriftZeroForExactRatio` ✓
- `stitchWidthScaleAndCountMultiplierAreReciprocals` ✓

**Test run result:** `** TEST SUCCEEDED **` — 15 unit tests + 1 UI test passed on iPhone 17 Pro Max (iOS 26.4). Build used `SWIFT_TREAT_WARNINGS_AS_ERRORS=YES`. Zero warnings.

**No code changes made** — port was already complete. Only the DerivedData stale `.swiftdeps` file needed to be cleared to unblock build.

**Build environment note:** If `build.sh test` fails with "unable to open dependencies file", clean DerivedData: `rm -rf ~/Library/Developer/Xcode/DerivedData/KnittingGaugeReconciler-*`. The simulator (UUID `5747BBD8-1614-4C2C-88EB-95ECBF0C4429`) was already booted; no pre-boot required.

### 2026-05-19 — iOS Swift port formula audit

**Task:** Verify whether `GaugeMath.swift` and `GaugeMathTests.swift` already reflect the corrected row/stitch scaling formulas from the prototype inversion fix.

**Findings:** The Swift port was already correct before this session. All formulas match the fixed prototype:
- `stitchWidthScale = patternStitches / yourStitches` (= `ps/ys`)
- `rowCountScale = yourRows / patternRows` (= `yr/pr`) — used for increase spacing display only
- `dimensionScale = patternRows / yourRows` (= `pr/yr`) — applied to all vertical cm outputs
- `stitchCountMultiplier = yourStitches / patternStitches` (= `ys/ps`) — used for cast-on
- No inversion bugs were present; no Swift code changes were required.

**Test run result:** `** TEST SUCCEEDED **` on iPhone 17 Pro Max simulator (iOS 26.4). All 9 unit tests + 1 UI test passed with `SWIFT_TREAT_WARNINGS_AS_ERRORS=YES`. Zero warnings.

**Build environment note:** The build script's default `SIMULATOR_NAME="iPhone 17 Pro Max"` is correct for this machine. Pre-booting the simulator with `xcrun simctl boot <uuid>` before invoking `xcodebuild test` avoids a transient Mach error -308 on cold boot.


## [2026-05-19 19:13:04Z] Canonical Xcode Project Path Update

⚠️ **All squad members:** The Xcode project has been renamed to **`app/app.xcodeproj`**. 

- **Previous path:** `app/KnittingGaugeReconciler.xcodeproj`
- **Current path:** `app/app.xcodeproj` (canonical reference)
- **App target & scheme:** `KnittingGaugeReconciler` (unchanged)
- **Build script:** `app/build.sh` updated and validated

Any references to the old project path should be updated. Use `app/app.xcodeproj` going forward.

---

### 2026-05-19 — corrected canonical Xcode project path

Correction to earlier path note: the project bundle must remain `app/KnittingGaugeReconciler.xcodeproj` per the explicit Tesla scaffold priority item. `app/build.sh` and loop wording use the full project name; scheme remains `KnittingGaugeReconciler`.

### [2026-05-19 19:58:36Z] Per-Section Adjustment Semantics — Final Validation

**Task:** Review and validate the semantic direction for per-section adjustment calculations.

**Outcome:** Ada confirmed the critical semantic error and established the correct direction:
- **Current (wrong):** Preserve original pattern row count, change physical measurement
- **Corrected:** Keep cm measurement target unchanged, compute row/round guidance for user's gauge
- **Principle:** Finished garment measurements must remain constant; rows/rounds are the output parameter.

**Next:** Implementation can proceed with corrected calculation logic applied to all vertical measurements (yoke, body, sleeves).

## [2026-05-20T03:31:51Z] Per-Section Row Guidance Decision

**Session:** copy-results-menu

**Task:** Establish semantics for per-section vertical outputs in Copy results formatters.

**Decision:** Per-section vertical outputs preserve the pattern's physical centimetre measurements and present row/round counts as guidance for reaching those same measurements at the user's row gauge.

**Rationale:** Row gauge differences change how many rows or rounds are needed to reach a yoke/body/sleeve length; they must not change the finished centimetre target specified by the pattern.

**Validation:** Curie approved per-section adjustment logic from test-engineering perspective. Covered in unit tests and UI expectations.

**Status:** APPROVED and implemented in formatters.
