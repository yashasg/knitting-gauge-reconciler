import Foundation
import SwiftUI
import Testing
@testable import KnittingGaugeReconciler

struct GaugeMathTests {
    private let pattern = GaugeInputs(
        patternStitches: 32, patternRows: 24, yourStitches: 32, yourRows: 24,
        patternYokeDepth: 20, patternBodyLength: 50, patternSleeveLength: 45,
        patternIncreaseSpacing: 6, patternCastOn: 128
    )

    @Test func scenario1PerfectMatch() {
        let result = GaugeMath.compute(pattern)
        expect(
            result, stitchWidthScale: 1, rowCountScale: 1,
            yoke: 20, body: 50, sleeve: 45, increases: 6, castOn: 128
        )
        #expect(result.adjustedYokeDepth == 20)
        #expect(result.adjustedBodyLength == 50)
        #expect(result.adjustedSleeveLength == 45)
        #expect(result.adjustedYokeRows?.isApproximately(48) == true)
        #expect(result.adjustedBodyRows?.isApproximately(120) == true)
        #expect(result.adjustedSleeveRows?.isApproximately(108) == true)
        #expect(result.adjustedIncreaseSpacing?.isApproximately(6) == true)
    }

    @Test func scenario2DenserRowsOnly() {
        let result = GaugeMath.compute(withGauge(yourStitches: 32, yourRows: 32))
        expect(
            result, stitchWidthScale: 1, rowCountScale: 32.0 / 24.0,
            yoke: 20, body: 50, sleeve: 45, increases: 8, castOn: 128
        )
        #expect(result.patternYokeRows?.isApproximately(48) == true)
        #expect(result.adjustedYokeRows?.isApproximately(64) == true)
        #expect(result.adjustedYokeDepth == 20)
        #expect(result.adjustedBodyLength == 50)
        #expect(result.adjustedSleeveLength == 45)
        #expect(result.adjustedBodyRows?.isApproximately(160) == true)
        #expect(result.adjustedSleeveRows?.isApproximately(144) == true)
        #expect(result.adjustedIncreaseSpacing?.isApproximately(8) == true)
        #expect(result.adjustedSleeveLength.map(GaugeMath.fmtCm) == "45.0")
        #expect(result.adjustedIncreaseSpacing.map(GaugeMath.fmtRows) == 8)
    }

    @Test func scenario3LooserRowsOnly() {
        let result = GaugeMath.compute(withGauge(yourStitches: 32, yourRows: 20))
        expect(
            result, stitchWidthScale: 1, rowCountScale: 20.0 / 24.0,
            yoke: 20, body: 50, sleeve: 45, increases: 5, castOn: 128
        )
        #expect(result.adjustedYokeDepth == 20)
        #expect(result.adjustedBodyLength == 50)
        #expect(result.adjustedSleeveLength == 45)
        #expect(result.adjustedYokeRows?.isApproximately(40) == true)
        #expect(result.adjustedBodyRows?.isApproximately(100) == true)
        #expect(result.adjustedSleeveRows?.isApproximately(90) == true)
        #expect(result.adjustedIncreaseSpacing?.isApproximately(5) == true)
        #expect(result.adjustedSleeveLength.map(GaugeMath.fmtCm) == "45.0")
        #expect(result.adjustedIncreaseSpacing.map(GaugeMath.fmtRows) == 5)
    }

    @Test func scenario4DenserStitchesOnly() {
        let result = GaugeMath.compute(withGauge(yourStitches: 36, yourRows: 24))
        expect(
            result, stitchWidthScale: 32.0 / 36.0, rowCountScale: 1,
            yoke: 20, body: 50, sleeve: 45, increases: 6, castOn: 144
        )
        #expect(result.adjustedYokeDepth == 20)
        #expect(result.adjustedBodyLength == 50)
        #expect(result.adjustedSleeveLength == 45)
        #expect(result.adjustedYokeRows?.isApproximately(48) == true)
        #expect(result.adjustedBodyRows?.isApproximately(120) == true)
        #expect(result.adjustedSleeveRows?.isApproximately(108) == true)
        #expect(result.adjustedIncreaseSpacing?.isApproximately(6) == true)
        #expect(GaugeMath.fmtPct(result.stitchWidthScale) == 89)
    }

    @Test func scenario5LooserStitchesHisahashisakaCase() {
        let result = GaugeMath.compute(withGauge(yourStitches: 28, yourRows: 24))
        expect(
            result, stitchWidthScale: 32.0 / 28.0, rowCountScale: 1,
            yoke: 20, body: 50, sleeve: 45, increases: 6, castOn: 112
        )
        #expect(result.adjustedYokeDepth == 20)
        #expect(result.adjustedBodyLength == 50)
        #expect(result.adjustedSleeveLength == 45)
        #expect(result.adjustedYokeRows?.isApproximately(48) == true)
        #expect(result.adjustedBodyRows?.isApproximately(120) == true)
        #expect(result.adjustedSleeveRows?.isApproximately(108) == true)
        #expect(result.adjustedIncreaseSpacing?.isApproximately(6) == true)
        #expect(GaugeMath.fmtPct(result.stitchWidthScale) == 114)
    }

    @Test func scenario6BothDenser() {
        let result = GaugeMath.compute(withGauge(yourStitches: 36, yourRows: 32))
        expect(
            result, stitchWidthScale: 32.0 / 36.0, rowCountScale: 32.0 / 24.0,
            yoke: 20, body: 50, sleeve: 45, increases: 8, castOn: 144
        )
        #expect(result.adjustedYokeDepth == 20)
        #expect(result.adjustedBodyLength == 50)
        #expect(result.adjustedSleeveLength == 45)
        #expect(result.adjustedYokeRows?.isApproximately(64) == true)
        #expect(result.adjustedBodyRows?.isApproximately(160) == true)
        #expect(result.adjustedSleeveRows?.isApproximately(144) == true)
        #expect(result.adjustedIncreaseSpacing?.isApproximately(8) == true)
        #expect(result.adjustedIncreaseSpacing.map(GaugeMath.fmtRows) == 8)
    }

    @Test func validatorMatrixCoversEveryFieldAndInputClass() {
        let rows = [
            ValidationRow(field: .patternStitches, lower: 1, upper: 99, decimal: 22.5, isRequired: true),
            ValidationRow(field: .patternRows, lower: 1, upper: 99, decimal: 24.5, isRequired: true),
            ValidationRow(field: .yourStitches, lower: 1, upper: 99, decimal: 21.5, isRequired: true),
            ValidationRow(field: .yourRows, lower: 1, upper: 99, decimal: 30.5, isRequired: true),
            ValidationRow(
                field: .patternCastOn, lower: 40, upper: 400, decimal: 128.5,
                isRequired: false, requiresWholeNumber: true
            ),
            ValidationRow(field: .patternYokeDepth, lower: 5, upper: 100, decimal: 20.5, isRequired: false),
            ValidationRow(field: .patternBodyLength, lower: 5, upper: 100, decimal: 50.5, isRequired: false),
            ValidationRow(field: .patternSleeveLength, lower: 5, upper: 100, decimal: 45.5, isRequired: false),
            ValidationRow(
                field: .patternIncreaseSpacing, lower: 1, upper: 30, decimal: 6.5,
                isRequired: false, requiresWholeNumber: true
            ),
        ]

        #expect(rows.count == GaugeMath.Field.allCases.count)
        for row in rows {
            let range = row.lower...row.upper
            let blank: ValidationExpectation = row.isRequired ? .error(.required) : .absent
            let cases = [
                ValidationCase(name: "empty", text: "", expectation: blank),
                ValidationCase(name: "whitespace", text: " \n\t ", expectation: blank),
                ValidationCase(name: "zero", text: "0", expectation: .error(.outOfRange(range))),
                ValidationCase(name: "negative", text: "-1", expectation: .error(.outOfRange(range))),
                ValidationCase(
                    name: "decimal below lower bound",
                    text: plain(row.lower - 0.5),
                    expectation: .error(.outOfRange(range))
                ),
                ValidationCase(
                    name: "decimal",
                    text: plain(row.decimal),
                    expectation: row.requiresWholeNumber ? .error(.wholeNumberRequired) : .value(row.decimal)
                ),
                ValidationCase(name: "lower bound", text: plain(row.lower), expectation: .value(row.lower)),
                ValidationCase(name: "upper bound", text: plain(row.upper), expectation: .value(row.upper)),
                ValidationCase(
                    name: "oversized",
                    text: plain(row.upper + 1),
                    expectation: .error(.outOfRange(range))
                ),
                ValidationCase(
                    name: "scientific notation",
                    text: "\(plain(row.lower))e0",
                    expectation: .value(row.lower)
                ),
                ValidationCase(name: "nan", text: "nan", expectation: .error(.invalidNumber)),
                ValidationCase(name: "infinity", text: "infinity", expectation: .error(.invalidNumber)),
            ]
            for testCase in cases {
                expectValidation(testCase, for: row.field)
            }
        }
    }

    @Test func validatorAcceptsExplicitLocaleAndInvariantDecimalSeparators() {
        let german = Locale(identifier: "de_DE")
        let localizedDecimals: [(GaugeMath.Field, String, Double)] = [
            (.patternStitches, "32,5", 32.5),
            (.patternRows, "24,5", 24.5),
            (.yourStitches, "31,5", 31.5),
            (.yourRows, "30,5", 30.5),
            (.patternYokeDepth, "20,5", 20.5),
            (.patternBodyLength, "50,5", 50.5),
            (.patternSleeveLength, "45,5", 45.5),
        ]

        for (field, text, value) in localizedDecimals {
            #expect(GaugeMath.validate(text, for: field, locale: german) == .success(value))
        }
        #expect(
            GaugeMath.validate("32.5", for: .yourStitches, locale: german) == .success(32.5)
        )
        #expect(
            GaugeMath.validate("32,5,1", for: .yourStitches, locale: german) ==
                .failure(.invalidNumber)
        )
        #expect(
            GaugeMath.validate("6,5", for: .patternIncreaseSpacing, locale: german) ==
                .failure(.wholeNumberRequired)
        )
        #expect(
            GaugeMath.validate("128,5", for: .patternCastOn, locale: german) ==
                .failure(.wholeNumberRequired)
        )
    }

    @Test func rowFormattingUsesEstablishedRounding() {
        #expect(GaugeMath.fmtRows(6.5) == 7)
        #expect(GaugeMath.fmtRows(6.4) == 6)
        #expect(GaugeMath.fmtRows(6.6) == 7)
        #expect(GaugeMath.fmtRows(0.4) == 1)
        #expect(GaugeMath.fmtRows(0) == 1)
        #expect(GaugeMath.fmtRows(0.0) == 1)
    }

    @Test func cmAndPercentFormattingAreDeterministic() {
        #expect(GaugeMath.fmtCm(33.75) == "33.8")
        #expect(GaugeMath.fmtCm(37.5) == "37.5")
        #expect(GaugeMath.fmtPct(32.0 / 36.0) == 89)
        #expect(GaugeMath.fmtSignedPct(72.5) == "+73% width")
        #expect(GaugeMath.fmtSignedPct(-72.4) == "-72% width")
        #expect(GaugeMath.fmtSignedPct(-17.5) == "-18% width")
        #expect(fmtGaugeDelta(0.5) == "+0.5")
        #expect(fmtGaugeDelta(1) == "+1")
        #expect(fmtGaugeDelta(-0.5) == "-0.5")
        #expect(fmtGaugeDelta(0.001) == "+<0.01")
        #expect(fmtGaugeDelta(-0.001) == "-<0.01")
        #expect(fmtGaugeDelta(10.001 - 10) == "+<0.01")
        #expect(fmtGaugeDelta(10 - 10.001) == "-<0.01")
        #expect(fmtGaugeDelta(Double.ulpOfOne) == "+<0.01")
        #expect(fmtGaugeDelta(0) == "+0")
    }

    @Test func statusBandsAreSymmetricAtExactBoundaries() {
        #expect(isGaugeMatch(scale: 0.971))
        #expect(isGaugeMatch(scale: 1.029))
        #expect(gaugeStatus(scale: 0.971) == "Match")
        #expect(gaugeStatus(scale: 1.029) == "Match")
        #expect(gaugeStatus(scale: 0.97) == "Tighter than pattern")
        #expect(gaugeStatus(scale: 1.03) == "Looser than pattern")
        #expect(gaugeStatus(scale: 0.901) == "Tighter than pattern")
        #expect(gaugeStatus(scale: 1.099) == "Looser than pattern")
        #expect(gaugeStatus(scale: 0.90) == "Much tighter")
        #expect(gaugeStatus(scale: 1.10) == "Much looser")

        #expect(rowStatus(scale: 0.971) == "Match")
        #expect(rowStatus(scale: 1.029) == "Match")
        #expect(rowStatus(scale: 0.97) == "Looser than pattern")
        #expect(rowStatus(scale: 1.03) == "Denser than pattern")
        #expect(rowStatus(scale: 0.901) == "Looser than pattern")
        #expect(rowStatus(scale: 1.099) == "Denser than pattern")
        #expect(rowStatus(scale: 0.90) == "Much looser")
        #expect(rowStatus(scale: 1.10) == "Much denser")

        for scale in [56.7 / 63, 1.017 / 1.13] {
            #expect(gaugeStatus(scale: scale) == "Much tighter")
            #expect(rowStatus(scale: scale) == "Much looser")
        }
        for scale in [69.3 / 63, 1.243 / 1.13] {
            #expect(gaugeStatus(scale: scale) == "Much looser")
            #expect(rowStatus(scale: scale) == "Much denser")
        }
    }

    @Test func computedExactThreePercentBoundariesAreNotMatches() {
        let lowerInputs = GaugeInputs(
            patternStitches: 29.1, patternRows: 30, yourStitches: 30, yourRows: 29.1,
            patternCastOn: 100
        )
        let upperInputs = GaugeInputs(
            patternStitches: 71.07, patternRows: 69, yourStitches: 69, yourRows: 71.07,
            patternCastOn: 100
        )
        let fineLowerInputs = GaugeInputs(
            patternStitches: 1.0961, patternRows: 1.13, yourStitches: 1.13, yourRows: 1.0961,
            patternCastOn: 100
        )
        let fineUpperInputs = GaugeInputs(
            patternStitches: 1.1639, patternRows: 1.13, yourStitches: 1.13, yourRows: 1.1639,
            patternCastOn: 100
        )
        let lowerInsideInputs = GaugeInputs(
            patternStitches: 29.13, patternRows: 30, yourStitches: 30, yourRows: 29.13,
            patternCastOn: 100
        )
        let upperInsideInputs = GaugeInputs(
            patternStitches: 30.87, patternRows: 30, yourStitches: 30, yourRows: 30.87,
            patternCastOn: 100
        )
        let lower = GaugeMath.compute(lowerInputs)
        let upper = GaugeMath.compute(upperInputs)
        let fineLower = GaugeMath.compute(fineLowerInputs)
        let fineUpper = GaugeMath.compute(fineUpperInputs)
        let lowerInside = GaugeMath.compute(lowerInsideInputs)
        let upperInside = GaugeMath.compute(upperInsideInputs)
        #expect(lower.stitchWidthScale == 0.97.nextUp)
        #expect(lower.rowCountScale == 0.97.nextUp)
        #expect(upper.stitchWidthScale == 1.03.nextDown)
        #expect(upper.rowCountScale == 1.03.nextDown)

        let boundaries = [
            (lowerInputs, lower, "Tighter than pattern", "Looser than pattern"),
            (fineLowerInputs, fineLower, "Tighter than pattern", "Looser than pattern"),
            (upperInputs, upper, "Looser than pattern", "Denser than pattern"),
            (fineUpperInputs, fineUpper, "Looser than pattern", "Denser than pattern"),
        ]
        for (inputs, result, stitchStatus, rowStatusValue) in boundaries {
            #expect(!isGaugeMatch(scale: result.stitchWidthScale))
            #expect(!isGaugeMatch(scale: result.rowCountScale))
            #expect(gaugeStatus(scale: result.stitchWidthScale) == stitchStatus)
            #expect(rowStatus(scale: result.rowCountScale) == rowStatusValue)
            #expect(castOnGuidanceText(inputs: inputs, result: result)?.hasPrefix("Cast on") == true)
        }

        for (inputs, result) in [(lowerInsideInputs, lowerInside), (upperInsideInputs, upperInside)] {
            #expect(isGaugeMatch(scale: result.stitchWidthScale))
            #expect(isGaugeMatch(scale: result.rowCountScale))
            #expect(gaugeStatus(scale: result.stitchWidthScale) == "Match")
            #expect(rowStatus(scale: result.rowCountScale) == "Match")
            #expect(castOnGuidanceText(inputs: inputs, result: result)?.hasPrefix("Optionally cast on") == true)
        }
    }

    @Test func castOnGuidanceTextOptionalInsideMatchImperativeOutside() {
        let nearMatchInputs = GaugeInputs(
            patternStitches: 32, patternRows: 24, yourStitches: 32.5, yourRows: 24,
            patternCastOn: 128
        )
        let nearMatchResult = GaugeMath.compute(nearMatchInputs)
        let offGaugeInputs = GaugeInputs(
            patternStitches: 32, patternRows: 24, yourStitches: 36, yourRows: 24,
            patternCastOn: 128
        )
        let offGaugeResult = GaugeMath.compute(offGaugeInputs)
        let absentInputs = GaugeInputs(
            patternStitches: 32, patternRows: 24, yourStitches: 32.5, yourRows: 24
        )
        let absentResult = GaugeMath.compute(absentInputs)

        #expect(nearMatchResult.adjustedCastOn == 130)
        #expect(
            castOnGuidanceText(inputs: nearMatchInputs, result: nearMatchResult) ==
                "Optionally cast on 130 stitches instead of 128 for a width refinement. " +
                "Reconcile this rounded stitch count with your pattern's stitch-repeat multiple."
        )
        #expect(
            castOnGuidanceText(inputs: offGaugeInputs, result: offGaugeResult) ==
                "Cast on 144 stitches instead of 128. " +
                "Reconcile this rounded stitch count with your pattern's stitch-repeat multiple."
        )
        #expect(castOnGuidanceText(inputs: absentInputs, result: absentResult) == nil)
    }

    // MARK: - Formula guardrails from .squad/decisions.md

    /// yr = 2 × pr: cm dimensions stay unchanged; section rows and increase-row guidance double.
    @Test func edgeVeryLargeDriftDenserRows() {
        let result = GaugeMath.compute(withGauge(yourStitches: 32, yourRows: 48))
        #expect(result.rowCountScale.isApproximately(2.0))
        #expect(result.adjustedYokeDepth.map(GaugeMath.fmtCm) == "20.0")
        #expect(result.adjustedBodyLength.map(GaugeMath.fmtCm) == "50.0")
        #expect(result.adjustedYokeRows.map(GaugeMath.fmtRows) == 96)
        #expect(result.adjustedIncreaseSpacing.map(GaugeMath.fmtRows) == 12)
    }

    /// yr = pr / 2: cm dimensions stay unchanged; section rows and increase-row guidance halve.
    @Test func edgeVeryLargeDriftLooserRows() {
        let result = GaugeMath.compute(withGauge(yourStitches: 32, yourRows: 12))
        #expect(result.rowCountScale.isApproximately(0.5))
        #expect(result.adjustedYokeDepth.map(GaugeMath.fmtCm) == "20.0")
        #expect(result.adjustedBodyLength.map(GaugeMath.fmtCm) == "50.0")
        #expect(result.adjustedYokeRows.map(GaugeMath.fmtRows) == 24)
        #expect(result.adjustedIncreaseSpacing.map(GaugeMath.fmtRows) == 3)
    }

    /// Issue #158 anchors: 20 cm → 64 rows at 32 rows/10cm; 40 rows at 20 rows/10cm.
    @Test func rowGaugeRowCountsTableAnchor() {
        let cases: [(yr: Double, yokeRows: Int, bodyRows: Int)] = [
            (32, 64, 160),  // denser:  20×32/10=64, 50×32/10=160
            (20, 40, 100),  // looser:  20×20/10=40, 50×20/10=100
            (24, 48, 120),  // match:   20×24/10=48, 50×24/10=120
        ]
        for (yr, yokeRows, bodyRows) in cases {
            let result = GaugeMath.compute(withGauge(yourStitches: 32, yourRows: yr))
            #expect(result.adjustedYokeDepth == 20.0, "yr=\(Int(yr)) cm unchanged")
            #expect(result.adjustedYokeRows.map(GaugeMath.fmtRows) == yokeRows, "yr=\(Int(yr)) yoke rows")
            #expect(result.adjustedBodyRows.map(GaugeMath.fmtRows) == bodyRows, "yr=\(Int(yr)) body rows")
        }
    }

    /// Perfect-match gauge: no floating-point drift — results must be exactly the pattern values.
    @Test func floatPrecisionExactMatchNoFPDrift() {
        let result = GaugeMath.compute(GaugeInputs(
            patternStitches: 32, patternRows: 24,
            yourStitches: 32, yourRows: 24,
            patternYokeDepth: 20, patternBodyLength: 50,
            patternSleeveLength: 45, patternIncreaseSpacing: 6,
            patternCastOn: 128
        ))
        #expect(result.adjustedYokeDepth == 20.0)
        #expect(result.adjustedBodyLength == 50.0)
        #expect(result.adjustedSleeveLength == 45.0)
        #expect(result.adjustedIncreaseSpacing == 6.0)
    }

    /// Non-power-of-2 matched gauges leave physical dimensions exactly unchanged.
    @Test func floatPrecisionArbitraryMatchedGauge() {
        let result = GaugeMath.compute(GaugeInputs(
            patternStitches: 30, patternRows: 22,
            yourStitches: 30, yourRows: 22,
            patternYokeDepth: 18.5, patternBodyLength: 52.3,
            patternSleeveLength: 41.0, patternIncreaseSpacing: 7,
            patternCastOn: 120
        ))
        #expect(result.adjustedYokeDepth == 18.5)
        #expect(result.adjustedBodyLength == 52.3)
        #expect(result.adjustedIncreaseSpacing == 7.0)
    }

    /// For exact-ratio cast-ons (no fractional stitches), rounding drift must be zero.
    @Test func castOnRoundingDriftZeroForExactRatio() {
        // Scenario 4: 128 × (36/32) = 144.0 — no rounding required
        let result4 = GaugeMath.compute(withGauge(yourStitches: 36, yourRows: 24))
        #expect(result4.castOnRoundingDriftPercent?.isApproximately(0.0) == true)
        // Scenario 5: 128 × (28/32) = 112.0 — no rounding required
        let result5 = GaugeMath.compute(withGauge(yourStitches: 28, yourRows: 24))
        #expect(result5.castOnRoundingDriftPercent?.isApproximately(0.0) == true)
    }

    @Test func adjustedCastOnWarnsForExtremeRatio() {
        let inputs = GaugeInputs(
            patternStitches: 99, patternRows: 24, yourStitches: 1, yourRows: 24,
            patternCastOn: 40
        )
        let result = GaugeMath.compute(inputs)
        let export = ResultsExportSummary(inputs: inputs, result: result)
        let share = ResultsShareTextFormatter.string(inputs: inputs, result: result)
        let warning = "No usable whole-stitch cast-on result. Re-swatch or change needle size before casting on."

        #expect(result.adjustedCastOn == nil)
        #expect(result.castOnRoundingDriftPercent == nil)
        #expect(castOnGuidanceText(inputs: inputs, result: result) == warning)
        #expect(export.castOn == warning)
        #expect(share.contains("• Cast-on: \(warning.lowercased())"))
        #expect(!share.contains("Cast on 0"))
    }

    @Test func castOnHalfTieAndSignedRoundingDriftUseDeliveredCount() {
        let positiveResult = GaugeMath.compute(GaugeInputs(
            patternStitches: 50, patternRows: 24, yourStitches: 40.5, yourRows: 24,
            patternCastOn: 50
        ))
        let negativeResult = GaugeMath.compute(GaugeInputs(
            patternStitches: 50, patternRows: 24, yourStitches: 40.4, yourRows: 24,
            patternCastOn: 50
        ))

        #expect(positiveResult.adjustedCastOn == 41)
        #expect(positiveResult.castOnRoundingDriftPercent?.isApproximately((0.5 / 40.5) * 100) == true)
        #expect(negativeResult.adjustedCastOn == 40)
        #expect(negativeResult.castOnRoundingDriftPercent?.isApproximately((-0.4 / 40.4) * 100) == true)
    }

    /// stitchWidthScale (ps/ys) × stitchCountMultiplier (ys/ps) must equal 1.0.
    @Test func stitchWidthScaleAndCountMultiplierAreReciprocals() {
        let result = GaugeMath.compute(withGauge(yourStitches: 36, yourRows: 24))
        #expect((result.stitchWidthScale * result.stitchCountMultiplier).isApproximately(1.0))
        let result2 = GaugeMath.compute(withGauge(yourStitches: 28, yourRows: 24))
        #expect((result2.stitchWidthScale * result2.stitchCountMultiplier).isApproximately(1.0))
    }


    @Test func resultsExportSummaryIncludesShareCardContent() {
        let inputs = optionalInputs(
            yourStitches: 36, yourRows: 32, castOn: 128,
            yoke: 20, body: 50, sleeve: 45, shaping: 6
        )
        let result = GaugeMath.compute(inputs)
        let cases: [
            (
                unit: MeasurementUnit,
                basis: String,
                yoke: String,
                adjustedYoke: String,
                body: String,
                adjustedBody: String,
                sleeve: String,
                adjustedSleeve: String
            )
        ] = [
            (.centimeters, "10 cm", "20 cm / 48 rows", "20 cm / 64 rows",
             "50 cm / 120 rows", "50 cm / 160 rows", "45 cm / 108 rows", "45 cm / 144 rows"),
            (.inches, "4 in", "7.9 in / 48 rows", "7.9 in / 64 rows",
             "19.7 in / 120 rows", "19.7 in / 160 rows", "17.7 in / 108 rows", "17.7 in / 144 rows"),
        ]

        for testCase in cases {
            let summary = ResultsExportSummary(inputs: inputs, result: result, unit: testCase.unit)
            #expect(summary.title == "Stitchwise")
            #expect(summary.patternGauge.stitches == "32 st / \(testCase.basis)")
            #expect(summary.patternGauge.rows == "24 rows / \(testCase.basis)")
            #expect(summary.swatchGauge.stitches == "36 st / \(testCase.basis)")
            #expect(summary.swatchGauge.rows == "32 rows / \(testCase.basis)")
            #expect(summary.stitchMetric == .init(title: "Stitch-wise", value: "89%", status: "Much tighter"))
            #expect(summary.rowMetric == .init(title: "Row-wise", value: "133%", status: "Much denser"))
            #expect(
                summary.castOn == "Cast on 144 stitches instead of 128. " +
                    "Reconcile this rounded stitch count with your pattern's stitch-repeat multiple."
            )
            #expect(
                summary.sections.map(\.name) ==
                    ["Yoke depth", "Body length", "Sleeve length", "Increase-row spacing"]
            )
            #expect(summary.sections[0].pattern == testCase.yoke)
            #expect(summary.sections[0].adjusted == testCase.adjustedYoke)
            #expect(summary.sections[1].pattern == testCase.body)
            #expect(summary.sections[1].adjusted == testCase.adjustedBody)
            #expect(summary.sections[2].pattern == testCase.sleeve)
            #expect(summary.sections[2].adjusted == testCase.adjustedSleeve)
            #expect(summary.sections[3].pattern == "Every 6 rows")
            #expect(summary.sections[3].adjusted == "Space every 8 rows/rounds")
        }
    }

    @Test func shareTextFormatterIncludesCurrentGaugeAndGuidanceAsFallback() {
        let inputs = optionalInputs(
            yourStitches: 36, yourRows: 32, castOn: 128,
            yoke: 20, body: 50, sleeve: 45, shaping: 6
        )
        let result = GaugeMath.compute(inputs)

        let cases: [
            (
                unit: MeasurementUnit,
                basis: String,
                yoke: String,
                body: String,
                sleeve: String
            )
        ] = [
            (
                .centimeters,
                "10 cm",
                "20 cm / 48 rows → 20 cm / 64 rows",
                "50 cm / 120 rows → 50 cm / 160 rows",
                "45 cm / 108 rows → 45 cm / 144 rows"
            ),
            (
                .inches,
                "4 in",
                "7.9 in / 48 rows → 7.9 in / 64 rows",
                "19.7 in / 120 rows → 19.7 in / 160 rows",
                "17.7 in / 108 rows → 17.7 in / 144 rows"
            ),
        ]

        for testCase in cases {
            let summary = ResultsShareTextFormatter.string(
                inputs: inputs,
                result: result,
                unit: testCase.unit
            )
            #expect(
                summary.contains(
                    "Pattern gauge\n• Stitches: 32 st / \(testCase.basis)\n" +
                        "• Rows: 24 rows / \(testCase.basis)"
                )
            )
            #expect(
                summary.contains(
                    "Swatch gauge\n• Stitches: 36 st / \(testCase.basis)\n" +
                        "• Rows: 32 rows / \(testCase.basis)"
                )
            )
            #expect(summary.contains("• Stitch-wise: 89% (Much tighter)"))
            #expect(summary.contains("• Row-wise: 133% (Much denser)"))
            #expect(
                summary.contains(
                    "• Cast-on: cast on 144 stitches instead of 128. " +
                        "reconcile this rounded stitch count with your pattern's stitch-repeat multiple."
                )
            )
            #expect(summary.contains("• Yoke depth: \(testCase.yoke)"))
            #expect(summary.contains("• Body length: \(testCase.body)"))
            #expect(summary.contains("• Sleeve length: \(testCase.sleeve)"))
            #expect(summary.contains("64 rows"))
            #expect(summary.contains("• Increase-row spacing: space every 8 rows/rounds (pattern every 6 rows)"))
        }
    }

    @Test func shareTextFormatterIsDeterministicFormattedTextFallback() {
        let inputs = optionalInputs(
            yourRows: 32, castOn: 128, yoke: 20, body: 50, sleeve: 45, shaping: 6
        )
        let result = GaugeMath.compute(inputs)

        let first = ResultsShareTextFormatter.string(inputs: inputs, result: result)
        let second = ResultsShareTextFormatter.string(inputs: inputs, result: result)
        #expect(first == second)
        #expect(first.contains("Stitchwise"))
        #expect(first.contains("Section row/round guidance"))
        #expect(first.contains("• Body length: 50 cm / 120 rows → 50 cm / 160 rows"))
        #expect(!first.contains("<table>"))
        #expect(!first.contains("| Section |"))
    }

    @Test func sectionGuidancePreservesDepthAndAdaptsRowCount() {
        let inputs = GaugeInputs(
            patternStitches: 32, patternRows: 24, yourStitches: 32, yourRows: 32,
            patternYokeDepth: 20, patternBodyLength: 50, patternSleeveLength: 45,
            patternIncreaseSpacing: 6, patternCastOn: 128
        )
        let result = GaugeMath.compute(inputs)
        let export = ResultsExportSummary(inputs: inputs, result: result)
        let share = ResultsShareTextFormatter.string(inputs: inputs, result: result)

        #expect(result.adjustedYokeDepth?.isApproximately(20) == true)
        #expect(result.adjustedBodyLength?.isApproximately(50) == true)
        #expect(result.adjustedSleeveLength?.isApproximately(45) == true)
        #expect(result.adjustedYokeRows?.isApproximately(64) == true)
        #expect(result.adjustedBodyRows?.isApproximately(160) == true)
        #expect(result.adjustedSleeveRows?.isApproximately(144) == true)
        #expect(export.sections[0].pattern == "20 cm / 48 rows")
        #expect(export.sections[0].adjusted == "20 cm / 64 rows")
        #expect(export.sections[1].adjusted == "50 cm / 160 rows")
        #expect(export.sections[2].adjusted == "45 cm / 144 rows")
        #expect(share.contains("• Yoke depth: 20 cm / 48 rows → 20 cm / 64 rows"))
        #expect(share.contains("• Body length: 50 cm / 120 rows → 50 cm / 160 rows"))
        #expect(share.contains("• Sleeve length: 45 cm / 108 rows → 45 cm / 144 rows"))
        #expect(share.contains("64 rows"))
    }

    @Test func optionalOutputMatrixOmitsIrrelevantExportAndShareSections() {
        let scenarios = [
            OptionalOutputScenario(name: "none", inputs: optionalInputs(), sectionNames: []),
            OptionalOutputScenario(
                name: "cast-on only",
                inputs: optionalInputs(castOn: 128),
                includesCastOn: true,
                sectionNames: []
            ),
            OptionalOutputScenario(
                name: "one length only",
                inputs: optionalInputs(yoke: 20),
                sectionNames: ["Yoke depth"]
            ),
            OptionalOutputScenario(
                name: "shaping only",
                inputs: optionalInputs(shaping: 6),
                sectionNames: ["Increase-row spacing"]
            ),
            OptionalOutputScenario(
                name: "all fields",
                inputs: optionalInputs(castOn: 128, yoke: 20, body: 50, sleeve: 45, shaping: 6),
                includesCastOn: true,
                sectionNames: ["Yoke depth", "Body length", "Sleeve length", "Increase-row spacing"]
            ),
        ]

        for scenario in scenarios {
            let result = GaugeMath.compute(scenario.inputs)
            let export = ResultsExportSummary(inputs: scenario.inputs, result: result)
            let share = ResultsShareTextFormatter.string(inputs: scenario.inputs, result: result)

            #expect((export.castOn != nil) == scenario.includesCastOn, "\(scenario.name): cast-on export")
            #expect(export.sections.map(\.name) == scenario.sectionNames, "\(scenario.name): export sections")
            #expect(
                share.contains("• Cast-on:") == scenario.includesCastOn,
                "\(scenario.name): cast-on share text"
            )
            #expect(
                share.contains("Section row/round guidance") == !scenario.sectionNames.isEmpty,
                "\(scenario.name): share heading"
            )

            let sections = [
                ("Yoke depth", scenario.inputs.patternYokeDepth != nil),
                ("Body length", scenario.inputs.patternBodyLength != nil),
                ("Sleeve length", scenario.inputs.patternSleeveLength != nil),
                ("Increase-row spacing", scenario.inputs.patternIncreaseSpacing != nil),
            ]
            for (name, isRelevant) in sections {
                #expect(share.contains("• \(name):") == isRelevant, "\(scenario.name): \(name)")
            }
            #expect((result.adjustedCastOn != nil) == (scenario.inputs.patternCastOn != nil))
            #expect((result.adjustedYokeRows != nil) == (scenario.inputs.patternYokeDepth != nil))
            #expect((result.adjustedBodyRows != nil) == (scenario.inputs.patternBodyLength != nil))
            #expect((result.adjustedSleeveRows != nil) == (scenario.inputs.patternSleeveLength != nil))
            #expect(
                (result.adjustedIncreaseSpacing != nil) == (scenario.inputs.patternIncreaseSpacing != nil)
            )
        }
    }

    @MainActor
    @Test func sceneStorageOwnsEveryRawValueAndDisclosure() {
        let properties = Array(Mirror(reflecting: ContentView()).children)
        let stringStorage = Set(properties.compactMap { child in
            child.value is SceneStorage<String> ? child.label?.dropFirst().description : nil
        })
        let boolStorage = Set(properties.compactMap { child in
            child.value is SceneStorage<Bool> ? child.label?.dropFirst().description : nil
        })

        #expect(stringStorage == [
            "patternStitches", "patternRows", "yourStitches", "yourRows",
            "patternCastOn", "patternYoke", "patternBody", "patternSleeve", "patternIncreases",
        ])
        #expect(boolStorage == ["patternDetailsExpanded"])

        let values = GaugeFormValues(
            patternStitches: "31.5",
            patternRows: "0",
            yourStitches: "32",
            yourRows: "24",
            patternYoke: "20.5",
            patternBody: ".",
            patternIncreases: "7e0"
        )
        let restored = GaugeFormDraft(values: values, patternDetailsExpanded: true)
        #expect(restored.formValues == values)
        #expect(restored.patternDetailsExpanded)
    }

    @Test func everyGaugeFormFieldMapsToItsMatchingNamedProperty() {
        let cases: [
            (
                field: GaugeFormField,
                expectedKeyPath: WritableKeyPath<GaugeFormValues, String>,
                sentinel: String,
                expectedClassification: GaugeFormField.StorageClassification
            )
        ] = [
            (.patternStitches, \.patternStitches, "pattern-stitches-key-path-sentinel", .text),
            (.patternRows, \.patternRows, "pattern-rows-key-path-sentinel", .text),
            (.yourStitches, \.yourStitches, "your-stitches-key-path-sentinel", .text),
            (.yourRows, \.yourRows, "your-rows-key-path-sentinel", .text),
            (.patternCastOn, \.patternCastOn, "pattern-cast-on-key-path-sentinel", .text),
            (.patternYoke, \.patternYoke, "pattern-yoke-key-path-sentinel", .centimeterLength),
            (.patternBody, \.patternBody, "pattern-body-key-path-sentinel", .centimeterLength),
            (.patternSleeve, \.patternSleeve, "pattern-sleeve-key-path-sentinel", .centimeterLength),
            (.patternIncreases, \.patternIncreases, "pattern-increases-key-path-sentinel", .text),
        ]

        #expect(cases.map(\.field) == GaugeFormField.allCases)
        for testCase in cases {
            var actual = GaugeFormValues()
            actual[keyPath: testCase.field.valueKeyPath] = testCase.sentinel
            var expected = GaugeFormValues()
            expected[keyPath: testCase.expectedKeyPath] = testCase.sentinel
            #expect(actual == expected, "\(testCase.field)")
            #expect(
                testCase.field.storageClassification == testCase.expectedClassification,
                "\(testCase.field)"
            )
        }
    }

    @Test func namedValuesRoundTripThroughResetAndRestoreWithoutFieldDrift() {
        let original = GaugeFormValues(
            patternStitches: "pattern-stitches-sentinel",
            patternRows: "pattern-rows-sentinel",
            yourStitches: "your-stitches-sentinel",
            yourRows: "your-rows-sentinel",
            patternCastOn: "pattern-cast-on-sentinel",
            patternYoke: "pattern-yoke-sentinel",
            patternBody: "pattern-body-sentinel",
            patternSleeve: "pattern-sleeve-sentinel",
            patternIncreases: "pattern-increases-sentinel"
        )
        var draft = GaugeFormDraft(
            values: original,
            unit: .inches,
            patternDetailsExpanded: true,
            focusedField: .patternSleeve
        )

        #expect(draft.formValues == original)
        let snapshot = draft.reset()
        #expect(draft.formValues == GaugeTextDefaults().values)
        #expect(!draft.patternDetailsExpanded)
        #expect(draft.focusedField == nil)

        draft.restore(snapshot)
        #expect(draft.formValues == original)
        #expect(draft.unit == .inches)
        #expect(draft.patternDetailsExpanded)
        #expect(draft.focusedField == nil)
    }

    @Test func inchReconciliationChangesExactlyTheThreeCentimeterLengthFields() {
        let storedYoke = MeasurementUnit.inches.positiveMeasurementStorageText(
            from: "yoke-inch-sentinel"
        )
        let storedBody = MeasurementUnit.inches.positiveMeasurementStorageText(
            from: "body-inch-sentinel"
        )
        let storedSleeve = MeasurementUnit.inches.positiveMeasurementStorageText(
            from: "sleeve-inch-sentinel"
        )
        let original = GaugeFormValues(
            patternStitches: "pattern-stitches-sentinel",
            patternRows: "pattern-rows-sentinel",
            yourStitches: "your-stitches-sentinel",
            yourRows: "your-rows-sentinel",
            patternCastOn: "pattern-cast-on-sentinel",
            patternYoke: storedYoke,
            patternBody: storedBody,
            patternSleeve: storedSleeve,
            patternIncreases: "pattern-increases-sentinel"
        )

        #expect(
            SceneDraftStore.reconcileInvalidInchProvenance(in: original, for: .inches) == original
        )
        let reconciled = SceneDraftStore.reconcileInvalidInchProvenance(
            in: original,
            for: .centimeters
        )
        #expect(reconciled.patternYoke == "yoke-inch-sentinel")
        #expect(reconciled.patternBody == "body-inch-sentinel")
        #expect(reconciled.patternSleeve == "sleeve-inch-sentinel")
        let changedFields = Set(GaugeFormField.allCases.filter {
            original[keyPath: $0.valueKeyPath] != reconciled[keyPath: $0.valueKeyPath]
        })
        #expect(changedFields == [.patternYoke, .patternBody, .patternSleeve])
    }

    @Test func sceneStorageKeyLiteralsRemainStable() {
        let keys: [(actual: String, expected: String)] = [
            (SceneDraftStore.patternStitchesKey, "gauge.pattern-stitches"),
            (SceneDraftStore.patternRowsKey, "gauge.pattern-rows"),
            (SceneDraftStore.yourStitchesKey, "gauge.your-stitches"),
            (SceneDraftStore.yourRowsKey, "gauge.your-rows"),
            (SceneDraftStore.patternCastOnKey, "gauge.pattern-cast-on"),
            (SceneDraftStore.patternYokeKey, "gauge.pattern-yoke"),
            (SceneDraftStore.patternBodyKey, "gauge.pattern-body"),
            (SceneDraftStore.patternSleeveKey, "gauge.pattern-sleeve"),
            (SceneDraftStore.patternIncreasesKey, "gauge.pattern-increases"),
            (SceneDraftStore.disclosureKey, "gauge.pattern-details-expanded"),
        ]

        for key in keys {
            #expect(key.actual == key.expected)
        }
        #expect(Set(keys.map(\.actual)).count == keys.count)
    }

    @Test func sceneDraftRestorationPreservesExactCasesAndIsolation() {
        let cases = [
            GaugeFormValues(
                patternStitches: "31",
                patternRows: "23",
                yourStitches: "29",
                yourRows: "21",
                patternCastOn: "141",
                patternYoke: "19",
                patternBody: "49",
                patternSleeve: "44",
                patternIncreases: "7"
            ),
            GaugeFormValues(
                patternStitches: "bad",
                patternRows: "100",
                yourStitches: "-1",
                yourRows: "nan",
                patternCastOn: "39",
                patternYoke: "4",
                patternBody: "101",
                patternSleeve: "∞",
                patternIncreases: "31"
            ),
            GaugeFormValues(
                patternStitches: "3.",
                patternRows: "2e",
                yourStitches: "-",
                yourRows: " ",
                patternYoke: "20.",
                patternBody: ".",
                patternIncreases: "7e"
            ),
            GaugeTextDefaults().values,
        ]
        for values in cases {
            #expect(GaugeFormDraft(values: values).formValues == values)
        }

        var firstScene = GaugeFormDraft(values: cases[0], patternDetailsExpanded: true)
        let secondScene = GaugeFormDraft(values: cases[2])
        firstScene[.patternBody] = "changed"
        #expect(secondScene.formValues == cases[2])
        #expect(!secondScene.patternDetailsExpanded)

        let snapshot = firstScene.reset()
        firstScene.restore(snapshot)
        #expect(firstScene[.patternBody] == "changed")
        #expect(firstScene.patternDetailsExpanded)
    }

    // MARK: - Inline mismatch detection

    /// stitchMismatch / rowMismatch are pure boolean derivations from GaugeInputs.
    @Test func inlineMismatchDetectionMatchVsMismatch() {
        let matched = GaugeInputs(patternStitches: 20, patternRows: 28, yourStitches: 20, yourRows: 28)
        #expect(!matched.stitchMismatch)
        #expect(!matched.rowMismatch)

        let stitchOnly = GaugeInputs(patternStitches: 20, patternRows: 28, yourStitches: 24, yourRows: 28)
        #expect(stitchOnly.stitchMismatch)
        #expect(!stitchOnly.rowMismatch)

        let rowOnly = GaugeInputs(patternStitches: 20, patternRows: 28, yourStitches: 20, yourRows: 32)
        #expect(!rowOnly.stitchMismatch)
        #expect(rowOnly.rowMismatch)

        let both = GaugeInputs(patternStitches: 20, patternRows: 28, yourStitches: 24, yourRows: 32)
        #expect(both.stitchMismatch)
        #expect(both.rowMismatch)
    }

    // MARK: - Mismatch detection with default values

    /// Default GaugeInputs (ps=32, pr=24, ys=32, yr=32) has row mismatch but not stitch mismatch.
    @Test func inlineMismatchDefaultInputs() {
        let defaults = GaugeInputs()
        #expect(!defaults.stitchMismatch)
        #expect(defaults.rowMismatch)
    }

    @MainActor
    @Test func requiredGaugeAccessibilityLabelsIncludeMeasurementBasis() {
        let cases: [(MeasurementUnit, String)] = [
            (.centimeters, "10 centimeters"),
            (.inches, "4 inches"),
        ]

        for (unit, basis) in cases {
            for field in GaugeInputsCard.accessibilityFieldOrder {
                let expectedLabel = "\(field.correctionName), per \(basis)"
                let label = GaugeInputsCard.accessibilityLabel(for: field, unit: unit)
                #expect(label == expectedLabel)
            }
        }
    }

    @Test func resultsActionTokensMeetTextContrastInLightAndDark() throws {
        let appDirectory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let sourceURL = appDirectory
            .appendingPathComponent("KnittingGaugeReconciler/Views/RequiredAdjustmentsCard.swift")
        let source = try String(contentsOf: sourceURL, encoding: .utf8)
        let actionsStart = try #require(
            source.range(of: "private func actionView(_ action: ResultActionKind)")?.lowerBound
        )
        let shareStart = try #require(
            source.range(of: "case .share:", range: actionsStart..<source.endIndex)?.lowerBound
        )
        let mathStart = try #require(
            source.range(of: "case .fullMath:", range: shareStart..<source.endIndex)?.lowerBound
        )
        let mathEnd = try #require(
            source.range(of: "if showFullMath {", range: mathStart..<source.endIndex)?.lowerBound
        )

        #expect(source[shareStart..<mathStart].contains(".foregroundStyle(AppTheme.ink)"))
        #expect(source[mathStart..<mathEnd].contains(".foregroundStyle(AppTheme.ink)"))

        let ink = try themeColors(named: "app-theme-ink", appDirectory: appDirectory)
        let card = try themeColors(named: "app-theme-card", appDirectory: appDirectory)
        for appearance in ["light", "dark"] {
            let foreground = try #require(ink[appearance])
            let background = try #require(card[appearance])
            #expect(contrastRatio(foreground, background) >= 4.5)
        }
    }

    @Test func badgeCaptionTokensMeetTextContrastInLightAndDark() throws {
        let appDirectory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let inputField = try sourceSection(
            "KnittingGaugeReconciler/Components/GaugeInputField.swift",
            from: "struct DeltaPillBadge",
            to: "struct GaugeInputField",
            appDirectory: appDirectory
        )
        let adjustment = try sourceSection(
            "KnittingGaugeReconciler/Views/AdjustmentRow.swift",
            from: "if let pill = driftPill {",
            to: ".accessibilityElement(children: .ignore)",
            appDirectory: appDirectory
        )
        #expect(inputField.contains(".foregroundStyle(AppTheme.cream)"))
        #expect(inputField.contains(".background(AppTheme.sage)"))
        #expect(adjustment.contains(".foregroundStyle(AppTheme.card)"))
        #expect(adjustment.contains(".background(AppTheme.deltaPill)"))

        let themeURL = appDirectory
            .appendingPathComponent("KnittingGaugeReconciler/Components/AppTheme.swift")
        let themeSource = try String(contentsOf: themeURL, encoding: .utf8)
        #expect(themeSource.contains("static let deltaPill        = ink"))

        let ink = try themeColors(named: "app-theme-ink", appDirectory: appDirectory)
        let card = try themeColors(named: "app-theme-card", appDirectory: appDirectory)
        let cream = try themeColors(named: "app-theme-cream", appDirectory: appDirectory)
        let sage = try themeColors(named: "app-theme-sage", appDirectory: appDirectory)
        for appearance in ["light", "dark"] {
            #expect(
                contrastRatio(
                    try #require(card[appearance]),
                    try #require(ink[appearance])
                ) >= 4.5
            )
            #expect(
                contrastRatio(
                    try #require(cream[appearance]),
                    try #require(sage[appearance])
                ) >= 4.5
            )
        }
    }

    @Test func gaugeInputBoundariesMeetNonTextContrastInLightAndDark() throws {
        let appDirectory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let boundary = try sourceSection(
            "KnittingGaugeReconciler/Components/GaugeInputField.swift",
            from: ".background(AppTheme.card)",
            to: "private var fieldLabel",
            appDirectory: appDirectory
        )
        let source = try String(
            contentsOf: appDirectory.appendingPathComponent(
                "KnittingGaugeReconciler/Components/GaugeInputField.swift"
            ),
            encoding: .utf8
        )
        #expect(boundary.contains("? AppTheme.mismatchText"))
        #expect(boundary.contains(": AppTheme.muted"))
        #expect(boundary.contains(").opacity(0.7)"))
        #expect(!boundary.contains("hasMismatch"))
        #expect(source.contains("showsCorrection: validationMessage != nil"))
        #expect(!source.contains("showsCorrection: hasMismatch || validationMessage != nil"))

        let muted = try themeColors(named: "app-theme-muted", appDirectory: appDirectory)
        let mismatch = try themeColors(
            named: "app-theme-mismatch-text",
            appDirectory: appDirectory
        )
        let card = try themeColors(named: "app-theme-card", appDirectory: appDirectory)
        let ratios = ["light", "dark"].flatMap { appearance in
            [muted, mismatch].compactMap { colors -> Double? in
                guard let foreground = colors[appearance],
                      let background = card[appearance] else { return nil }
                let boundary = foreground * 0.7 + background * 0.3
                return contrastRatio(boundary, background)
            }
        }

        #expect(ratios.count == 4 && ratios.allSatisfy { $0 >= 3 })
    }

    @Test func adjustedTileCaptionsUseSolidWhiteWithAccessibleContrast() throws {
        let appDirectory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let sites = [
            (
                "KnittingGaugeReconciler/Views/AdjustmentRow.swift",
                "Text(\"Adjusted\")",
                "Text(adjusted)",
                "private var adjustedTile",
                "private var adjustedTileAccessibilityLabel"
            ),
        ]

        for (path, captionStart, valueStart, tileStart, tileEnd) in sites {
            let caption = try sourceSection(
                path,
                from: captionStart,
                to: valueStart,
                appDirectory: appDirectory
            )
            #expect(caption.contains(".foregroundStyle(.white)"))
            #expect(!caption.contains(".opacity("))

            let tile = try sourceSection(
                path,
                from: tileStart,
                to: tileEnd,
                appDirectory: appDirectory
            )
            #expect(tile.contains(".background(AppTheme.sage)"))
        }

        let white = SIMD3<Double>(repeating: 1)
        let sage = try themeColors(named: "app-theme-sage", appDirectory: appDirectory)
        for appearance in ["light", "dark"] {
            #expect(contrastRatio(white, try #require(sage[appearance])) >= 4.5)
        }
    }

    private func sourceSection(
        _ path: String,
        from startMarker: String,
        to endMarker: String,
        appDirectory: URL
    ) throws -> Substring {
        let source = try String(
            contentsOf: appDirectory.appendingPathComponent(path),
            encoding: .utf8
        )
        let start = try #require(source.range(of: startMarker)?.lowerBound)
        let end = try #require(
            source.range(of: endMarker, range: start..<source.endIndex)?.lowerBound
        )
        return source[start..<end]
    }

    private func themeColors(
        named name: String,
        appDirectory: URL
    ) throws -> [String: SIMD3<Double>] {
        let url = appDirectory
            .appendingPathComponent("KnittingGaugeReconciler/Assets.xcassets")
            .appendingPathComponent("\(name).colorset/Contents.json")
        let object = try JSONSerialization.jsonObject(with: Data(contentsOf: url))
        let root = try #require(object as? [String: Any])
        let entries = try #require(root["colors"] as? [[String: Any]])
        var result: [String: SIMD3<Double>] = [:]

        for entry in entries {
            let appearances = entry["appearances"] as? [[String: String]]
            let appearance = appearances?.first?["value"] ?? "light"
            let color = try #require(entry["color"] as? [String: Any])
            let components = try #require(color["components"] as? [String: String])
            result[appearance] = SIMD3(
                try #require(components["red"].flatMap(Double.init)),
                try #require(components["green"].flatMap(Double.init)),
                try #require(components["blue"].flatMap(Double.init))
            )
        }
        return result
    }

    private func contrastRatio(_ first: SIMD3<Double>, _ second: SIMD3<Double>) -> Double {
        let luminances = [relativeLuminance(first), relativeLuminance(second)].sorted()
        return (luminances[1] + 0.05) / (luminances[0] + 0.05)
    }

    private func relativeLuminance(_ color: SIMD3<Double>) -> Double {
        0.2126 * linearized(color.x) +
            0.7152 * linearized(color.y) +
            0.0722 * linearized(color.z)
    }

    private func linearized(_ component: Double) -> Double {
        component <= 0.04045
            ? component / 12.92
            : pow((component + 0.055) / 1.055, 2.4)
    }

    private func withGauge(yourStitches: Double, yourRows: Double) -> GaugeInputs {
        GaugeInputs(
            patternStitches: 32, patternRows: 24,
            yourStitches: yourStitches, yourRows: yourRows,
            patternYokeDepth: 20, patternBodyLength: 50,
            patternSleeveLength: 45, patternIncreaseSpacing: 6,
            patternCastOn: 128
        )
    }

    private func optionalInputs(
        yourStitches: Double = 32,
        yourRows: Double = 24,
        castOn: Double? = nil,
        yoke: Double? = nil,
        body: Double? = nil,
        sleeve: Double? = nil,
        shaping: Double? = nil
    ) -> GaugeInputs {
        GaugeInputs(
            patternStitches: 32, patternRows: 24,
            yourStitches: yourStitches, yourRows: yourRows,
            patternYokeDepth: yoke, patternBodyLength: body,
            patternSleeveLength: sleeve, patternIncreaseSpacing: shaping,
            patternCastOn: castOn
        )
    }

    private func expectValidation(_ testCase: ValidationCase, for field: GaugeMath.Field) {
        let result = GaugeMath.validate(testCase.text, for: field)
        switch (result, testCase.expectation) {
        case (.success(nil), .absent):
            break
        case let (.success(actual?), .value(expected)):
            #expect(actual == expected, "\(field) \(testCase.name)")
        case let (.failure(actual), .error(expected)):
            #expect(actual == expected, "\(field) \(testCase.name)")
        default:
            Issue.record("\(field) \(testCase.name): got \(result)")
        }
    }

    private func expect(
        _ result: GaugeMathResult,
        stitchWidthScale: Double,
        rowCountScale: Double,
        yoke: Double,
        body: Double,
        sleeve: Double,
        increases: Double,
        castOn: Int
    ) {
        #expect(result.stitchWidthScale.isApproximately(stitchWidthScale))
        #expect(result.rowCountScale.isApproximately(rowCountScale))
        #expect(result.adjustedYokeDepth?.isApproximately(yoke) == true)
        #expect(result.adjustedBodyLength?.isApproximately(body) == true)
        #expect(result.adjustedSleeveLength?.isApproximately(sleeve) == true)
        #expect(result.adjustedIncreaseSpacing?.isApproximately(increases) == true)
        #expect(result.adjustedCastOn == castOn)
    }

    private struct ValidationRow {
        let field: GaugeMath.Field
        let lower: Double
        let upper: Double
        let decimal: Double
        let isRequired: Bool
        var requiresWholeNumber = false
    }

    private struct ValidationCase {
        let name: String
        let text: String
        let expectation: ValidationExpectation
    }

    private enum ValidationExpectation {
        case absent
        case value(Double)
        case error(GaugeMath.ValidationError)
    }

    private struct OptionalOutputScenario {
        let name: String
        let inputs: GaugeInputs
        var includesCastOn = false
        let sectionNames: [String]
    }
}

// MARK: - MeasurementUnit conversion tests

struct MeasurementUnitTests {
    @Test func gaugeBasisLabelsCoverEveryMeasurementUnit() {
        let cases: [(MeasurementUnit, label: String, spoken: String)] = [
            (.centimeters, "10 cm", "10 centimeters"),
            (.inches, "4 in", "4 inches"),
        ]

        #expect(cases.map { $0.0 } == MeasurementUnit.allCases)
        for (unit, label, spoken) in cases {
            #expect(unit.gaugeBasis == label)
            #expect(unit.spokenGaugeBasis == spoken)
        }
    }

    @Test func unitTogglePreservesCanonicalInputsAndUnitlessResults() throws {
        var draft = GaugeFormDraft(
            values: GaugeFormValues(
                patternStitches: "32",
                patternRows: "24",
                yourStitches: "36",
                yourRows: "32",
                patternCastOn: "128",
                patternYoke: "20",
                patternBody: "50",
                patternSleeve: "45",
                patternIncreases: "6"
            ),
            unit: .centimeters,
            patternDetailsExpanded: true
        )
        let centimeterInputs = try #require(draft.inputs)
        let centimeterResult = GaugeMath.compute(centimeterInputs)

        draft.unit = .inches
        let inchInputs = try #require(draft.inputs)
        let inchResult = GaugeMath.compute(inchInputs)
        #expect(inchInputs == centimeterInputs)
        #expect(inchResult == centimeterResult)

        let centimeterSummary = ResultsExportSummary(
            inputs: centimeterInputs,
            result: centimeterResult,
            unit: .centimeters
        )
        let inchSummary = ResultsExportSummary(
            inputs: inchInputs,
            result: inchResult,
            unit: .inches
        )
        #expect(centimeterSummary.stitchMetric == inchSummary.stitchMetric)
        #expect(centimeterSummary.rowMetric == inchSummary.rowMetric)
        #expect(centimeterSummary.castOn == inchSummary.castOn)
        #expect(centimeterSummary.sections.last == inchSummary.sections.last)

        let gaugePairs = [
            (centimeterSummary.patternGauge.stitches, inchSummary.patternGauge.stitches),
            (centimeterSummary.patternGauge.rows, inchSummary.patternGauge.rows),
            (centimeterSummary.swatchGauge.stitches, inchSummary.swatchGauge.stitches),
            (centimeterSummary.swatchGauge.rows, inchSummary.swatchGauge.rows),
        ]
        for (centimeters, inches) in gaugePairs {
            #expect(
                centimeters.replacingOccurrences(of: "10 cm", with: "4 in") == inches
            )
        }
    }

    // MARK: Exact decimal display conversion

    @Test func matchingGaugePreservesWholeInchLengthInResults() throws {
        let storedDepthText = MeasurementUnit.inches.positiveMeasurementStorageText(from: "8")
        let storedDepth = try #require(Double(storedDepthText))
        let inputs = GaugeInputs(
            patternStitches: 32,
            patternRows: 24,
            yourStitches: 32,
            yourRows: 24,
            patternYokeDepth: storedDepth
        )
        let result = GaugeMath.compute(inputs)
        let adjustedDepth = try #require(result.adjustedYokeDepth)
        let section = try #require(
            ResultsExportSummary(inputs: inputs, result: result, unit: .inches).sections.first
        )

        #expect(storedDepthText == "20.32")
        #expect(adjustedDepth.isApproximately(storedDepth))
        #expect(section.pattern == "8 in / 49 rows")
        #expect(section.adjusted == "8 in / 49 rows")
    }

    @Test func matchingGaugePreservesDecimalCentimeterLengthInResults() throws {
        let inputs = GaugeInputs(
            patternStitches: 32,
            patternRows: 24,
            yourStitches: 32,
            yourRows: 24,
            patternYokeDepth: 18.5
        )
        let result = GaugeMath.compute(inputs)
        let section = try #require(
            ResultsExportSummary(inputs: inputs, result: result, unit: .centimeters).sections.first
        )

        #expect(section.pattern == "18.5 cm / 44 rows")
        #expect(section.adjusted == "18.5 cm / 44 rows")
    }

    @Test func invalidInchInputIsPreservedWithoutConversion() {
        let malformed = MeasurementUnit.inches.positiveMeasurementStorageText(from: "8..5")
        let negative = MeasurementUnit.inches.positiveMeasurementStorageText(from: "-8.5")
        let separatorOnly = MeasurementUnit.inches.positiveMeasurementStorageText(from: ".")

        #expect(MeasurementUnit.invalidInchesText(from: malformed) == "8..5")
        #expect(MeasurementUnit.invalidInchesText(from: negative) == "-8.5")
        #expect(MeasurementUnit.invalidInchesText(from: separatorOnly) == ".")
        #expect(GaugeMath.validate(malformed, for: .patternYokeDepth) == .failure(.invalidNumber))
        #expect(GaugeMath.validate(negative, for: .patternYokeDepth) == .failure(.invalidNumber))
        #expect(GaugeMath.validate(separatorOnly, for: .patternYokeDepth) == .failure(.invalidNumber))
    }

    @Test func inchStorageAcceptsLocaleAndInvariantDecimalSeparators() {
        let german = Locale(identifier: "de_DE")

        #expect(
            MeasurementUnit.inches.positiveMeasurementStorageText(from: "8,5", locale: german) ==
                "21.59"
        )
        #expect(
            MeasurementUnit.inches.positiveMeasurementStorageText(from: "8.5", locale: german) ==
                "21.59"
        )
    }

    @Test func acceptedDecimalInchesKeepExactCanonicalStorageAcrossToggles() {
        let cases = [
            (inches: "2.5", centimeters: "6.35"),
            (inches: "8", centimeters: "20.32"),
            (inches: "39.25", centimeters: "99.695"),
        ]

        for testCase in cases {
            let stored = MeasurementUnit.inches.positiveMeasurementStorageText(
                from: testCase.inches
            )

            #expect(stored == testCase.centimeters)
            #expect(
                MeasurementUnit.inches.positiveMeasurementDisplayText(from: stored)
                    == testCase.inches
            )
            #expect(MeasurementUnit.invalidInchesText(from: stored) == nil)
            #expect(MeasurementUnit.inches.storageText(stored, transitioningTo: .centimeters) == stored)
            #expect(MeasurementUnit.centimeters.storageText(stored, transitioningTo: .inches) == stored)
        }
    }

    // MARK: Display range conversion

    @Test func displayRangeReturnsCmRangeUnchanged() {
        let range = MeasurementUnit.centimeters.displayRange(from: 5...100)
        #expect(range == 5...100)
    }

    @Test func displayRangeConvertsCmToInches() {
        let range = MeasurementUnit.inches.displayRange(from: 5...100)
        // 5 cm → 2 in, 100 cm → 39 in
        #expect(range.lowerBound == 2)
        #expect(range.upperBound == 39)
    }

    @Test func decimalDisplayRangePreservesExactInchLimits() {
        let range = MeasurementUnit.inches.displayDecimalRange(from: 5.0...100.0)
        #expect(range.lowerBound == 5 / 2.54)
        #expect(range.upperBound == 100 / 2.54)
    }

    // MARK: formatMeasurement

    @Test func formatMeasurementCentimetres() {
        #expect(MeasurementUnit.centimeters.formatMeasurement(20) == "20 cm")
        #expect(MeasurementUnit.centimeters.formatMeasurement(50) == "50 cm")
        #expect(MeasurementUnit.centimeters.formatMeasurement(18.5) == "18.5 cm")
        #expect(MeasurementUnit.centimeters.formatResultMeasurement(15) == "15 cm")
        #expect(MeasurementUnit.centimeters.formatResultMeasurement(37.5) == "37.5 cm")
        #expect(MeasurementUnit.centimeters.formatResultMeasurement(33.75) == "33.8 cm")
    }

    @Test func formatMeasurementInches() {
        #expect(MeasurementUnit.inches.formatMeasurement(20) == "7.9 in")
        #expect(MeasurementUnit.inches.formatMeasurement(50) == "19.7 in")
        #expect(MeasurementUnit.inches.formatMeasurement(20.32) == "8 in")
        #expect(MeasurementUnit.inches.formatResultMeasurement(20) == "7.9 in")
        #expect(MeasurementUnit.inches.formatResultMeasurement(50) == "19.7 in")
        #expect(MeasurementUnit.inches.formatResultMeasurement(37.5) == "14.8 in")
    }

    @Test func measurementExportAndShareUseStableASCIIFormatting() throws {
        let inputs = GaugeInputs(
            patternStitches: 32, patternRows: 24, yourStitches: 32, yourRows: 24,
            patternYokeDepth: 20.32
        )
        let result = GaugeMath.compute(inputs)
        let centimeterSection = try #require(
            ResultsExportSummary(inputs: inputs, result: result, unit: .centimeters).sections.first
        )
        let inchSection = try #require(
            ResultsExportSummary(inputs: inputs, result: result, unit: .inches).sections.first
        )

        #expect(MeasurementUnit.centimeters.formatResultMeasurement(33.75) == "33.8 cm")
        #expect(MeasurementUnit.inches.formatResultMeasurement(20.32) == "8 in")
        #expect(centimeterSection.pattern == "20.3 cm / 49 rows")
        #expect(centimeterSection.adjusted == "20.3 cm / 49 rows")
        #expect(inchSection.pattern == "8 in / 49 rows")
        #expect(inchSection.adjusted == "8 in / 49 rows")
        #expect(
            ResultsShareTextFormatter.string(inputs: inputs, result: result, unit: .centimeters)
                .contains("• Yoke depth: 20.3 cm / 49 rows → 20.3 cm / 49 rows")
        )
        #expect(
            ResultsShareTextFormatter.string(inputs: inputs, result: result, unit: .inches)
                .contains("• Yoke depth: 8 in / 49 rows → 8 in / 49 rows")
        )
    }

    // MARK: ResultsExportSummary respects unit

    @Test func exportSummaryUsesInchesWhenRequested() {
        let inputs = GaugeInputs(
            patternStitches: 32, patternRows: 24, yourStitches: 32, yourRows: 24,
            patternYokeDepth: 20, patternBodyLength: 50, patternSleeveLength: 45
        )
        let result = GaugeMath.compute(inputs)
        let summary = ResultsExportSummary(inputs: inputs, result: result, unit: .inches)
        #expect(summary.sections[0].pattern == "7.9 in / 48 rows")
        #expect(summary.sections[1].pattern == "19.7 in / 120 rows")
        #expect(summary.sections[2].pattern == "17.7 in / 108 rows")
        #expect(summary.sections[0].adjusted == "7.9 in / 48 rows")
        #expect(summary.sections[1].adjusted == "19.7 in / 120 rows")
        #expect(summary.sections[2].adjusted == "17.7 in / 108 rows")
        // Yoke textLine uses in
        #expect(summary.sections[0].textLine.contains("7.9 in / 48 rows → 7.9 in"))
    }

    @Test func shareTextFormatterUsesInchesWhenRequested() {
        let inputs = GaugeInputs(
            patternStitches: 32, patternRows: 24, yourStitches: 32, yourRows: 24,
            patternYokeDepth: 20, patternBodyLength: 50
        )
        let result = GaugeMath.compute(inputs)
        let text = ResultsShareTextFormatter.string(inputs: inputs, result: result, unit: .inches)
        #expect(text.contains("• Yoke depth: 7.9 in / 48 rows → 7.9 in / 48 rows"))
        #expect(text.contains("• Body length: 19.7 in / 120 rows → 19.7 in / 120 rows"))
    }
}

private extension Double {
    func isApproximately(_ expected: Double, tolerance: Double = 0.000_001) -> Bool {
        abs(self - expected) <= tolerance
    }
}
