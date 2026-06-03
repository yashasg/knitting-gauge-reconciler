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
        #expect(summary.title == "Stitchwise")
        #expect(summary.patternGauge.stitches == "32 st / 10 cm")
        #expect(summary.swatchGauge.rows == "32 rows / 10 cm")
        #expect(summary.stitchMetric == .init(title: "Stitch-wise", value: "89%", status: "Much tighter"))
        #expect(summary.rowMetric == .init(title: "Row-wise", value: "133%", status: "Much denser"))
        #expect(summary.castOn == "Cast on 144 stitches instead of 128")
        #expect(summary.sections.map(\.name) == ["Yoke depth", "Body length", "Sleeve length", "Increase-row spacing"])
        // body: (50/10)*32 = 160 rows at user gauge; default unit is cm so pattern shows "50 cm"
        #expect(summary.sections[1].pattern == "50 cm")
        #expect(summary.sections[1].adjusted == "Knit 160 rows")
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
        // rows at your gauge: yoke (20/10)*32=64, body (50/10)*32=160, sleeve (45/10)*32=144
        #expect(summary.contains("• Yoke depth: 20 cm → knit 64 rows"))
        #expect(summary.contains("• Body length: 50 cm → knit 160 rows"))
        #expect(summary.contains("• Sleeve length: 45 cm → knit 144 rows"))
        #expect(summary.contains("• Increase-row spacing: space every 8 rows/rounds (pattern every 6 rows)"))
    }

    @Test func shareTextFormatterIsDeterministicFormattedTextFallback() {
        let inputs = GaugeInputs(patternStitches: 32, patternRows: 24, yourStitches: 32, yourRows: 32)
        let result = GaugeMath.compute(inputs)

        let first = ResultsShareTextFormatter.string(inputs: inputs, result: result)
        let second = ResultsShareTextFormatter.string(inputs: inputs, result: result)
        #expect(first == second)
        #expect(first.contains("Stitchwise"))
        #expect(first.contains("Section row/round guidance"))
        // body: (50/10)*32 = 160 rows at user gauge
        #expect(first.contains("• Body length: 50 cm → knit 160 rows"))
        #expect(!first.contains("<table>"))
        #expect(!first.contains("| Section |"))
    }

    /// yashasg's formula: rowsNeeded = round((patternCm / 10) × yourRowsPer10cm)
    /// Example: 20cm yoke at 22 ro/10cm → (20/10) × 22 = 44 rows.
    @Test func sectionRowsAtYourGaugeMatchFormula() {
        let inputs = GaugeInputs(
            patternStitches: 32, patternRows: 24, yourStitches: 32, yourRows: 22,
            patternYokeDepth: 20, patternBodyLength: 50, patternSleeveLength: 45,
            patternIncreaseSpacing: 6, patternCastOn: 128
        )
        let result = GaugeMath.compute(inputs)
        #expect(result.yokeRowsAtYourGauge == 44)    // (20/10) × 22 = 44
        #expect(result.bodyRowsAtYourGauge == 110)   // (50/10) × 22 = 110
        #expect(result.sleeveRowsAtYourGauge == 99)  // (45/10) × 22 = 99
    }

    // MARK: - Wheel field clamp + parse bounds

    /// GaugeMath.clampedGaugeValue enforces the [1, 99] wheel range.
    @Test func wheelFieldClampEnforcesBounds() {
        #expect(GaugeMath.clampedGaugeValue(0) == 1)
        #expect(GaugeMath.clampedGaugeValue(-5) == 1)
        #expect(GaugeMath.clampedGaugeValue(1) == 1)
        #expect(GaugeMath.clampedGaugeValue(50) == 50)
        #expect(GaugeMath.clampedGaugeValue(99) == 99)
        #expect(GaugeMath.clampedGaugeValue(100) == 99)
        #expect(GaugeMath.clampedGaugeValue(999) == 99)
    }

    /// A whole-number wheel selection commits as a plain integer string.
    @Test func gaugeWheelFieldCommitsSelection() {
        #expect(GaugeMath.parseGaugeTypeText("20", fallback: 20) == "20")
        #expect(GaugeMath.parseGaugeTypeText("1", fallback: 20) == "1")
        #expect(GaugeMath.parseGaugeTypeText("99", fallback: 20) == "99")
        // Out-of-range integers are clamped.
        #expect(GaugeMath.parseGaugeTypeText("0", fallback: 20) == "1")
        #expect(GaugeMath.parseGaugeTypeText("100", fallback: 20) == "99")
    }

    /// Decimal values typed in the keyboard fallback are clamped and preserved where meaningful.
    @Test func gaugeWheelFieldTypeFallbackParsesDecimal() {
        // Decimal within range: kept as one decimal place.
        #expect(GaugeMath.parseGaugeTypeText("22.5", fallback: 20) == "22.5")
        // Decimal that rounds to a whole number: stripped to integer string.
        #expect(GaugeMath.parseGaugeTypeText("30.0", fallback: 20) == "30")
        // Decimal out-of-range: clamped.
        #expect(GaugeMath.parseGaugeTypeText("0.5", fallback: 20) == "1")
        #expect(GaugeMath.parseGaugeTypeText("99.9", fallback: 20) == "99")
        // Empty string: falls back to the fallback integer.
        #expect(GaugeMath.parseGaugeTypeText("", fallback: 25) == "25")
        // Un-parseable string: falls back to clamped fallback.
        #expect(GaugeMath.parseGaugeTypeText("abc", fallback: 30) == "30")
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

// MARK: - MeasurementUnit conversion tests

struct MeasurementUnitTests {

    // MARK: Display conversion (cm → in, rounded to nearest whole inch)

    @Test func cmToDisplayIntCentimetres() {
        // cm mode returns same value rounded
        #expect(MeasurementUnit.centimeters.cmToDisplayInt(20) == 20)
        #expect(MeasurementUnit.centimeters.cmToDisplayInt(50.4) == 50)
        #expect(MeasurementUnit.centimeters.cmToDisplayInt(50.6) == 51)
    }

    @Test func cmToDisplayIntInches() {
        // 20 cm = 7.87 in → rounds to 8
        #expect(MeasurementUnit.inches.cmToDisplayInt(20) == 8)
        // 50 cm = 19.69 in → rounds to 20
        #expect(MeasurementUnit.inches.cmToDisplayInt(50) == 20)
        // 45 cm = 17.72 in → rounds to 18
        #expect(MeasurementUnit.inches.cmToDisplayInt(45) == 18)
        // 5 cm = 1.97 in → rounds to 2
        #expect(MeasurementUnit.inches.cmToDisplayInt(5) == 2)
        // 100 cm = 39.37 in → rounds to 39
        #expect(MeasurementUnit.inches.cmToDisplayInt(100) == 39)
    }

    // MARK: Write-back conversion (display int → cm string)

    @Test func displayIntToCmStringCentimetres() {
        #expect(MeasurementUnit.centimeters.displayIntToCmString(20) == "20")
        #expect(MeasurementUnit.centimeters.displayIntToCmString(50) == "50")
    }

    @Test func displayIntToCmStringInches() {
        // 8 in × 2.54 = 20.32 → rounds to 20
        #expect(MeasurementUnit.inches.displayIntToCmString(8) == "20")
        // 20 in × 2.54 = 50.8 → rounds to 51
        #expect(MeasurementUnit.inches.displayIntToCmString(20) == "51")
        // 18 in × 2.54 = 45.72 → rounds to 46
        #expect(MeasurementUnit.inches.displayIntToCmString(18) == "46")
        // 1 in → 3 cm (2.54 → rounds to 3)
        #expect(MeasurementUnit.inches.displayIntToCmString(1) == "3")
    }

    // MARK: Round-trip: toggle cm → in → cm must not corrupt the cm model

    /// Toggling the unit does NOT alter the stored cm value — only the display
    /// binding converts. The stored strings are never written unless the user edits.
    @Test func roundTripToggleDoesNotCorruptCmStore() {
        // Simulate: start with "20" cm stored, toggle to in and back.
        // The stored value ("20") should be unchanged because the conversion binding
        // only reads for display; it only writes on user edit (Done tap).
        // This test validates that cmToDisplayInt then displayIntToCmString is
        // "close" (within 1 cm rounding) for expected knitting values.
        let cmValues: [Double] = [20, 50, 45, 25, 30, 60]
        for cm in cmValues {
            let displayInt = MeasurementUnit.inches.cmToDisplayInt(cm)
            let recoveredCmStr = MeasurementUnit.inches.displayIntToCmString(displayInt)
            let recoveredCm = Double(recoveredCmStr) ?? 0
            // Allow up to 2 cm rounding error (one in cm→in, one in in→cm)
            #expect(abs(recoveredCm - cm) <= 2, "cm=\(cm) → \(displayInt) in → \(recoveredCmStr) cm")
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

    // MARK: formatMeasurement

    @Test func formatMeasurementCentimetres() {
        #expect(MeasurementUnit.centimeters.formatMeasurement(20) == "20 cm")
        #expect(MeasurementUnit.centimeters.formatMeasurement(50) == "50 cm")
    }

    @Test func formatMeasurementInches() {
        #expect(MeasurementUnit.inches.formatMeasurement(20) == "8 in")
        #expect(MeasurementUnit.inches.formatMeasurement(50) == "20 in")
    }

    // MARK: ResultsExportSummary respects unit

    @Test func exportSummaryUsesInchesWhenRequested() {
        let inputs = GaugeInputs(patternStitches: 32, patternRows: 24, yourStitches: 32, yourRows: 24)
        let result = GaugeMath.compute(inputs)
        let summary = ResultsExportSummary(inputs: inputs, result: result, unit: .inches)
        // Yoke depth: 20 cm → 8 in
        #expect(summary.sections[0].pattern == "8 in")
        // Body length: 50 cm → 20 in
        #expect(summary.sections[1].pattern == "20 in")
        // Sleeve length: 45 cm → 18 in
        #expect(summary.sections[2].pattern == "18 in")
        // Yoke textLine uses in
        #expect(summary.sections[0].textLine.contains("8 in"))
    }

    @Test func shareTextFormatterUsesInchesWhenRequested() {
        let inputs = GaugeInputs(patternStitches: 32, patternRows: 24, yourStitches: 32, yourRows: 24)
        let result = GaugeMath.compute(inputs)
        let text = ResultsShareTextFormatter.string(inputs: inputs, result: result, unit: .inches)
        #expect(text.contains("• Yoke depth: 8 in → knit"))
        #expect(text.contains("• Body length: 20 in → knit"))
    }
}

private extension Double {
    func isApproximately(_ expected: Double, tolerance: Double = 0.000_001) -> Bool {
        abs(self - expected) <= tolerance
    }
}
