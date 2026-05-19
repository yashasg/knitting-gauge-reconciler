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
        #expect(GaugeMath.fmtCm(result.adjustedSleeveLength) == "33.8")
        #expect(GaugeMath.fmtRows(result.adjustedIncreaseSpacing) == 8)
    }

    @Test func scenario3LooserRowsOnly() {
        let result = GaugeMath.compute(withGauge(yourStitches: 32, yourRows: 20))
        expect(result, stitchWidthScale: 1, rowCountScale: 20.0 / 24.0, dimensionScale: 24.0 / 20.0, yoke: 24, body: 60, sleeve: 54, increases: 5, castOn: 128)
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
        #expect(GaugeMath.sanitized(0.1, default: 32) == 0.1)
    }

    @Test func rowFormattingMatchesPrototype() {
        #expect(GaugeMath.fmtRows(6.5) == 7)
        #expect(GaugeMath.fmtRows(6.4) == 6)
        #expect(GaugeMath.fmtRows(0.4) == 1)
        #expect(GaugeMath.fmtRows(0) == 1)
    }

    @Test func cmAndPercentFormattingMatchPrototype() {
        #expect(GaugeMath.fmtCm(33.75) == "33.8")
        #expect(GaugeMath.fmtCm(37.5) == "37.5")
        #expect(GaugeMath.fmtPct(32.0 / 36.0) == 89)
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
