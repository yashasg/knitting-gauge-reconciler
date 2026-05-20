import Testing
@testable import KnittingGaugeReconciler

struct GaugeMathTests {
    private let pattern = GaugeInputs(patternStitches: 32, patternRows: 24, yourStitches: 32, yourRows: 24)

    @Test func scenario1PerfectMatch() {
        let result = GaugeMath.compute(pattern)
        expect(result, stitchWidthScale: 1, rowCountScale: 1, dimensionScale: 1, yoke: 20, body: 50, sleeve: 45, increases: 6, castOn: 128)
    }

    @Test func scenario2DenserRowsOnly() {
        let result = GaugeMath.compute(withGauge(yourStitches: 32, yourRows: 32))
        expect(result, stitchWidthScale: 1, rowCountScale: 32.0 / 24.0, dimensionScale: 24.0 / 32.0, yoke: 15, body: 37.5, sleeve: 33.75, increases: 8, castOn: 128)
        #expect(result.patternYokeRows.isApproximately(48))
        #expect(result.adjustedYokeRows.isApproximately(48))
        #expect(GaugeMath.fmtCm(result.adjustedSleeveLength) == "33.8")
        #expect(GaugeMath.fmtRows(result.adjustedIncreaseSpacing) == 8)
    }

    @Test func scenario3LooserRowsOnly() {
        let result = GaugeMath.compute(withGauge(yourStitches: 32, yourRows: 20))
        expect(result, stitchWidthScale: 1, rowCountScale: 20.0 / 24.0, dimensionScale: 24.0 / 20.0, yoke: 24, body: 60, sleeve: 54, increases: 5, castOn: 128)
        #expect(GaugeMath.fmtCm(result.adjustedSleeveLength) == "54.0")
        #expect(GaugeMath.fmtRows(result.adjustedIncreaseSpacing) == 5)
    }

    @Test func scenario4DenserStitchesOnly() {
        let result = GaugeMath.compute(withGauge(yourStitches: 36, yourRows: 24))
        expect(result, stitchWidthScale: 32.0 / 36.0, rowCountScale: 1, dimensionScale: 1, yoke: 20, body: 50, sleeve: 45, increases: 6, castOn: 144)
        #expect(GaugeMath.fmtPct(result.stitchWidthScale) == 89)
    }

    @Test func scenario5LooserStitchesHisahashisakaCase() {
        let result = GaugeMath.compute(withGauge(yourStitches: 28, yourRows: 24))
        expect(result, stitchWidthScale: 32.0 / 28.0, rowCountScale: 1, dimensionScale: 1, yoke: 20, body: 50, sleeve: 45, increases: 6, castOn: 112)
        #expect(GaugeMath.fmtPct(result.stitchWidthScale) == 114)
    }

    @Test func scenario6BothDenser() {
        let result = GaugeMath.compute(withGauge(yourStitches: 36, yourRows: 32))
        expect(result, stitchWidthScale: 32.0 / 36.0, rowCountScale: 32.0 / 24.0, dimensionScale: 24.0 / 32.0, yoke: 15, body: 37.5, sleeve: 33.75, increases: 8, castOn: 144)
        #expect(GaugeMath.fmtRows(result.adjustedIncreaseSpacing) == 8)
    }

    @Test func invalidInputsFallBackToDefaults() {
        #expect(GaugeMath.sanitized(nil, default: 32) == 32)
        #expect(GaugeMath.sanitized(0, default: 32) == 32)
        #expect(GaugeMath.sanitized(-5, default: 32) == 32)
        #expect(GaugeMath.sanitized(.nan, default: 32) == 32)
        #expect(GaugeMath.sanitized(.infinity, default: 32) == 32)
        #expect(GaugeMath.sanitized(-.infinity, default: 32) == 32)
        #expect(GaugeMath.sanitized(0.1, default: 32) == 0.1)
    }

    @Test func rowFormattingMatchesPrototype() {
        #expect(GaugeMath.fmtRows(6.5) == 7)
        #expect(GaugeMath.fmtRows(6.4) == 6)
        #expect(GaugeMath.fmtRows(6.6) == 7)
        #expect(GaugeMath.fmtRows(0.4) == 1)
        #expect(GaugeMath.fmtRows(0) == 1)
        #expect(GaugeMath.fmtRows(0.0) == 1)
    }

    @Test func cmAndPercentFormattingMatchPrototype() {
        #expect(GaugeMath.fmtCm(33.75) == "33.8")
        #expect(GaugeMath.fmtCm(37.5) == "37.5")
        #expect(GaugeMath.fmtPct(32.0 / 36.0) == 89)
    }

    // MARK: - Edge cases from prototype/tests/gauge-math.test.js

    /// yr = 2 × pr: cm dimensions halve; increase-row guidance doubles.
    @Test func edgeVeryLargeDriftDenserRows() {
        let result = GaugeMath.compute(withGauge(yourStitches: 32, yourRows: 48))
        #expect(result.dimensionScale.isApproximately(0.5))
        #expect(result.rowCountScale.isApproximately(2.0))
        #expect(GaugeMath.fmtCm(result.adjustedYokeDepth) == "10.0")
        #expect(GaugeMath.fmtCm(result.adjustedBodyLength) == "25.0")
        #expect(GaugeMath.fmtRows(result.adjustedYokeRows) == 48)
        #expect(GaugeMath.fmtRows(result.adjustedIncreaseSpacing) == 12)
    }

    /// yr = pr / 2: cm dimensions double; increase-row guidance halves.
    @Test func edgeVeryLargeDriftLooserRows() {
        let result = GaugeMath.compute(withGauge(yourStitches: 32, yourRows: 12))
        #expect(result.dimensionScale.isApproximately(2.0))
        #expect(result.rowCountScale.isApproximately(0.5))
        #expect(GaugeMath.fmtCm(result.adjustedYokeDepth) == "40.0")
        #expect(GaugeMath.fmtCm(result.adjustedBodyLength) == "100.0")
        #expect(GaugeMath.fmtRows(result.adjustedYokeRows) == 48)
        #expect(GaugeMath.fmtRows(result.adjustedIncreaseSpacing) == 3)
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

    /// Non-power-of-2 gauge values, stitch and row match: dimScale must be exactly 1.0.
    @Test func floatPrecisionArbitraryMatchedGauge() {
        let result = GaugeMath.compute(GaugeInputs(
            patternStitches: 30, patternRows: 22,
            yourStitches: 30, yourRows: 22,
            patternYokeDepth: 18.5, patternBodyLength: 52.3,
            patternSleeveLength: 41.0, patternIncreaseSpacing: 7,
            patternCastOn: 120
        ))
        #expect(result.dimensionScale == 1.0)
        #expect(result.adjustedYokeDepth == 18.5)
        #expect(result.adjustedBodyLength == 52.3)
        #expect(result.adjustedIncreaseSpacing == 7.0)
    }

    /// For exact-ratio cast-ons (no fractional stitches), rounding drift must be zero.
    @Test func castOnRoundingDriftZeroForExactRatio() {
        // Scenario 4: 128 × (36/32) = 144.0 — no rounding required
        let result4 = GaugeMath.compute(withGauge(yourStitches: 36, yourRows: 24))
        #expect(result4.castOnRoundingDriftPercent.isApproximately(0.0))
        // Scenario 5: 128 × (28/32) = 112.0 — no rounding required
        let result5 = GaugeMath.compute(withGauge(yourStitches: 28, yourRows: 24))
        #expect(result5.castOnRoundingDriftPercent.isApproximately(0.0))
    }

    /// stitchWidthScale (ps/ys) × stitchCountMultiplier (ys/ps) must equal 1.0.
    @Test func stitchWidthScaleAndCountMultiplierAreReciprocals() {
        let result = GaugeMath.compute(withGauge(yourStitches: 36, yourRows: 24))
        #expect((result.stitchWidthScale * result.stitchCountMultiplier).isApproximately(1.0))
        let result2 = GaugeMath.compute(withGauge(yourStitches: 28, yourRows: 24))
        #expect((result2.stitchWidthScale * result2.stitchCountMultiplier).isApproximately(1.0))
    }


    @Test func resultsExportSummaryIncludesShareCardContent() {
        let inputs = GaugeInputs(patternStitches: 32, patternRows: 24, yourStitches: 36, yourRows: 32)
        let result = GaugeMath.compute(inputs)

        let summary = ResultsExportSummary(inputs: inputs, result: result)
        #expect(summary.title == "Knitting Gauge Reconciler")
        #expect(summary.patternGauge.stitches == "32 st / 10 cm")
        #expect(summary.swatchGauge.rows == "32 rows / 10 cm")
        #expect(summary.stitchMetric == .init(title: "Stitch-wise", value: "89%", status: "Much tighter"))
        #expect(summary.rowMetric == .init(title: "Row-wise", value: "133%", status: "Much denser"))
        #expect(summary.castOn == "Cast on 144 stitches instead of 128")
        #expect(summary.sections.map(\.name) == ["Yoke depth", "Body length", "Sleeve length", "Increase-row spacing"])
        #expect(summary.sections[1].adjusted == "Knit to 37.5 cm; about 120 rows/rounds")
        #expect(summary.sections[1].pattern == "Pattern about 120 rows")
    }

    @Test func shareTextFormatterIncludesCurrentGaugeAndGuidanceAsFallback() {
        let inputs = GaugeInputs(patternStitches: 32, patternRows: 24, yourStitches: 36, yourRows: 32)
        let result = GaugeMath.compute(inputs)

        let summary = ResultsShareTextFormatter.string(inputs: inputs, result: result)
        #expect(summary.contains("Pattern gauge\n• Stitches: 32 st / 10 cm\n• Rows: 24 rows / 10 cm"))
        #expect(summary.contains("Swatch gauge\n• Stitches: 36 st / 10 cm\n• Rows: 32 rows / 10 cm"))
        #expect(summary.contains("• Stitch-wise: 89% (Much tighter)"))
        #expect(summary.contains("• Row-wise: 133% (Much denser)"))
        #expect(summary.contains("• Cast-on: cast on 144 stitches instead of 128"))
        #expect(summary.contains("• Yoke depth: Knit to 15.0 cm; about 48 rows/rounds (pattern about 48 rows)"))
        #expect(summary.contains("• Body length: Knit to 37.5 cm; about 120 rows/rounds (pattern about 120 rows)"))
        #expect(summary.contains("• Sleeve length: Knit to 33.8 cm; about 108 rows/rounds (pattern about 108 rows)"))
        #expect(summary.contains("• Increase-row spacing: space every 8 rows/rounds (pattern every 6 rows)"))
    }

    @Test func shareTextFormatterIsDeterministicFormattedTextFallback() {
        let inputs = GaugeInputs(patternStitches: 32, patternRows: 24, yourStitches: 32, yourRows: 32)
        let result = GaugeMath.compute(inputs)

        let first = ResultsShareTextFormatter.string(inputs: inputs, result: result)
        let second = ResultsShareTextFormatter.string(inputs: inputs, result: result)
        #expect(first == second)
        #expect(first.contains("Knitting Gauge Reconciler"))
        #expect(first.contains("Section row/round guidance"))
        #expect(first.contains("• Body length: Knit to 37.5 cm; about 120 rows/rounds (pattern about 120 rows)"))
        #expect(!first.contains("<table>"))
        #expect(!first.contains("| Section |"))
    }

    private func withGauge(yourStitches: Double, yourRows: Double) -> GaugeInputs {
        GaugeInputs(patternStitches: 32, patternRows: 24, yourStitches: yourStitches, yourRows: yourRows)
    }

    private func expect(
        _ result: GaugeMathResult,
        stitchWidthScale: Double,
        rowCountScale: Double,
        dimensionScale: Double,
        yoke: Double,
        body: Double,
        sleeve: Double,
        increases: Double,
        castOn: Int
    ) {
        #expect(result.stitchWidthScale.isApproximately(stitchWidthScale))
        #expect(result.rowCountScale.isApproximately(rowCountScale))
        #expect(result.dimensionScale.isApproximately(dimensionScale))
        #expect(result.adjustedYokeDepth.isApproximately(yoke))
        #expect(result.adjustedBodyLength.isApproximately(body))
        #expect(result.adjustedSleeveLength.isApproximately(sleeve))
        #expect(result.adjustedIncreaseSpacing.isApproximately(increases))
        #expect(result.adjustedCastOn == castOn)
    }
}

private extension Double {
    func isApproximately(_ expected: Double, tolerance: Double = 0.000_001) -> Bool {
        abs(self - expected) <= tolerance
    }
}
