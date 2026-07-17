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
        expect(result, stitchWidthScale: 1, rowCountScale: 1, dimensionScale: 1, yoke: 20, body: 50, sleeve: 45, increases: 6, castOn: 128)
    }

    @Test func scenario2DenserRowsOnly() {
        let result = GaugeMath.compute(withGauge(yourStitches: 32, yourRows: 32))
        expect(result, stitchWidthScale: 1, rowCountScale: 32.0 / 24.0, dimensionScale: 24.0 / 32.0, yoke: 15, body: 37.5, sleeve: 33.75, increases: 8, castOn: 128)
        #expect(result.patternYokeRows?.isApproximately(48) == true)
        #expect(result.adjustedYokeRows?.isApproximately(48) == true)
        #expect(result.adjustedSleeveLength.map(GaugeMath.fmtCm) == "33.8")
        #expect(result.adjustedIncreaseSpacing.map(GaugeMath.fmtRows) == 8)
    }

    @Test func scenario3LooserRowsOnly() {
        let result = GaugeMath.compute(withGauge(yourStitches: 32, yourRows: 20))
        expect(result, stitchWidthScale: 1, rowCountScale: 20.0 / 24.0, dimensionScale: 24.0 / 20.0, yoke: 24, body: 60, sleeve: 54, increases: 5, castOn: 128)
        #expect(result.adjustedSleeveLength.map(GaugeMath.fmtCm) == "54.0")
        #expect(result.adjustedIncreaseSpacing.map(GaugeMath.fmtRows) == 5)
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
        #expect(GaugeMath.fmtSignedPct(-72.5) == "-72% width")
    }

    @Test func statusBandsAreSymmetricAtExactBoundaries() {
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
    }

    @Test func isMajorDriftIsSymmetricAtExact15Percent() {
        let positiveBoundaryResult = GaugeMath.compute(GaugeInputs(
            patternStitches: 23, patternRows: 24, yourStitches: 20, yourRows: 24
        ))
        let negativeBoundaryResult = GaugeMath.compute(GaugeInputs(
            patternStitches: 17, patternRows: 24, yourStitches: 20, yourRows: 24
        ))
        let belowBoundaryResult = GaugeMath.compute(GaugeInputs(
            patternStitches: 22, patternRows: 24, yourStitches: 20, yourRows: 24
        ))

        #expect(isMajorDrift(abs(positiveBoundaryResult.stitchWidthScale - 1)))
        #expect(isMajorDrift(abs(negativeBoundaryResult.stitchWidthScale - 1)))
        #expect(!isMajorDrift(abs(belowBoundaryResult.stitchWidthScale - 1)))
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

    /// yr = 2 × pr: cm dimensions halve; increase-row guidance doubles.
    @Test func edgeVeryLargeDriftDenserRows() {
        let result = GaugeMath.compute(withGauge(yourStitches: 32, yourRows: 48))
        #expect(result.dimensionScale.isApproximately(0.5))
        #expect(result.rowCountScale.isApproximately(2.0))
        #expect(result.adjustedYokeDepth.map(GaugeMath.fmtCm) == "10.0")
        #expect(result.adjustedBodyLength.map(GaugeMath.fmtCm) == "25.0")
        #expect(result.adjustedYokeRows.map(GaugeMath.fmtRows) == 48)
        #expect(result.adjustedIncreaseSpacing.map(GaugeMath.fmtRows) == 12)
    }

    /// yr = pr / 2: cm dimensions double; increase-row guidance halves.
    @Test func edgeVeryLargeDriftLooserRows() {
        let result = GaugeMath.compute(withGauge(yourStitches: 32, yourRows: 12))
        #expect(result.dimensionScale.isApproximately(2.0))
        #expect(result.rowCountScale.isApproximately(0.5))
        #expect(result.adjustedYokeDepth.map(GaugeMath.fmtCm) == "40.0")
        #expect(result.adjustedBodyLength.map(GaugeMath.fmtCm) == "100.0")
        #expect(result.adjustedYokeRows.map(GaugeMath.fmtRows) == 48)
        #expect(result.adjustedIncreaseSpacing.map(GaugeMath.fmtRows) == 3)
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
        #expect(result4.castOnRoundingDriftPercent?.isApproximately(0.0) == true)
        // Scenario 5: 128 × (28/32) = 112.0 — no rounding required
        let result5 = GaugeMath.compute(withGauge(yourStitches: 28, yourRows: 24))
        #expect(result5.castOnRoundingDriftPercent?.isApproximately(0.0) == true)
    }

    @Test func adjustedCastOnPreservesExtremeRatioParity() {
        let inputs = GaugeInputs(
            patternStitches: 99, patternRows: 24, yourStitches: 1, yourRows: 24,
            patternCastOn: 40
        )
        let result = GaugeMath.compute(inputs)
        let exactCastOn = 40.0 / 99.0

        #expect(result.adjustedCastOn == 0)
        #expect(
            result.castOnRoundingDriftPercent?.isApproximately(
                ((0 - exactCastOn) / exactCastOn) * 100
            ) == true
        )
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

        let summary = ResultsExportSummary(inputs: inputs, result: result)
        #expect(summary.title == "Stitchwise")
        #expect(summary.patternGauge.stitches == "32 st / 10 cm")
        #expect(summary.swatchGauge.rows == "32 rows / 10 cm")
        #expect(summary.stitchMetric == .init(title: "Stitch-wise", value: "89%", status: "Much tighter"))
        #expect(summary.rowMetric == .init(title: "Row-wise", value: "133%", status: "Much denser"))
        #expect(
            summary.castOn == "Cast on 144 stitches instead of 128. " +
                "Reconcile this rounded stitch count with your pattern's stitch-repeat multiple."
        )
        #expect(summary.sections.map(\.name) == ["Yoke depth", "Body length", "Sleeve length", "Increase-row spacing"])
        #expect(summary.sections[0].pattern == "20 cm / 48 rows")
        #expect(summary.sections[0].adjusted == "15 cm / 48 rows")
        #expect(summary.sections[1].pattern == "50 cm / 120 rows")
        #expect(summary.sections[1].adjusted == "37.5 cm / 120 rows")
        #expect(summary.sections[2].pattern == "45 cm / 108 rows")
        #expect(summary.sections[2].adjusted == "33.8 cm / 108 rows")
    }

    @Test func shareTextFormatterIncludesCurrentGaugeAndGuidanceAsFallback() {
        let inputs = optionalInputs(
            yourStitches: 36, yourRows: 32, castOn: 128,
            yoke: 20, body: 50, sleeve: 45, shaping: 6
        )
        let result = GaugeMath.compute(inputs)

        let summary = ResultsShareTextFormatter.string(inputs: inputs, result: result)
        #expect(summary.contains("Pattern gauge\n• Stitches: 32 st / 10 cm\n• Rows: 24 rows / 10 cm"))
        #expect(summary.contains("Swatch gauge\n• Stitches: 36 st / 10 cm\n• Rows: 32 rows / 10 cm"))
        #expect(summary.contains("• Stitch-wise: 89% (Much tighter)"))
        #expect(summary.contains("• Row-wise: 133% (Much denser)"))
        #expect(
            summary.contains(
                "• Cast-on: cast on 144 stitches instead of 128. " +
                    "reconcile this rounded stitch count with your pattern's stitch-repeat multiple."
            )
        )
        #expect(summary.contains("• Yoke depth: 20 cm / 48 rows → 15 cm / 48 rows"))
        #expect(summary.contains("• Body length: 50 cm / 120 rows → 37.5 cm / 120 rows"))
        #expect(summary.contains("• Sleeve length: 45 cm / 108 rows → 33.8 cm / 108 rows"))
        #expect(!summary.contains("64 rows"))
        #expect(summary.contains("• Increase-row spacing: space every 8 rows/rounds (pattern every 6 rows)"))
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
        #expect(first.contains("• Body length: 50 cm / 120 rows → 37.5 cm / 120 rows"))
        #expect(!first.contains("<table>"))
        #expect(!first.contains("| Section |"))
    }

    @Test func sectionGuidanceAdjustsDepthAndPreservesPatternRows() {
        let inputs = GaugeInputs(
            patternStitches: 32, patternRows: 24, yourStitches: 32, yourRows: 32,
            patternYokeDepth: 20, patternBodyLength: 50, patternSleeveLength: 45,
            patternIncreaseSpacing: 6, patternCastOn: 128
        )
        let result = GaugeMath.compute(inputs)
        let export = ResultsExportSummary(inputs: inputs, result: result)
        let share = ResultsShareTextFormatter.string(inputs: inputs, result: result)

        #expect(result.adjustedYokeDepth?.isApproximately(15) == true)
        #expect(result.adjustedBodyLength?.isApproximately(37.5) == true)
        #expect(result.adjustedSleeveLength?.isApproximately(33.75) == true)
        #expect(result.adjustedYokeRows == result.patternYokeRows)
        #expect(result.adjustedBodyRows == result.patternBodyRows)
        #expect(result.adjustedSleeveRows == result.patternSleeveRows)
        #expect(export.sections[0].pattern == "20 cm / 48 rows")
        #expect(export.sections[0].adjusted == "15 cm / 48 rows")
        #expect(export.sections[1].adjusted == "37.5 cm / 120 rows")
        #expect(export.sections[2].adjusted == "33.8 cm / 108 rows")
        #expect(share.contains("• Yoke depth: 20 cm / 48 rows → 15 cm / 48 rows"))
        #expect(share.contains("• Body length: 50 cm / 120 rows → 37.5 cm / 120 rows"))
        #expect(share.contains("• Sleeve length: 45 cm / 108 rows → 33.8 cm / 108 rows"))
        #expect(!share.contains("64 rows"))
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
    @Test func sceneDraftSerializationPreservesEveryRawValueAndDisclosure() throws {
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

        let values = ["31.5", "0", "32", "24", "", "20.5", ".", "", "7e0"]
        let serialization = try #require(
            SceneDraftStore.serialize(values: values, disclosure: true)
        )
        let restored = try #require(SceneDraftStore.deserialize(serialization))

        #expect(restored.values == values)
        #expect(restored.disclosure)
    }

    @Test func malformedSceneDraftSerializationIsRejected() throws {
        let values = ["31.5", "0", "32", "24", "", "20.5", ".", "", "7e0"]
        let valid = try #require(SceneDraftStore.serialize(values: values, disclosure: true))
        var missingDisclosure = valid
        var wrongValueCount = valid
        var wrongValuesType = valid
        var wrongDisclosureType = valid
        missingDisclosure.removeValue(forKey: SceneDraftStore.disclosureKey)
        wrongValueCount[SceneDraftStore.rawValuesKey] = Array(values.dropLast())
        wrongValuesType[SceneDraftStore.rawValuesKey] = values.joined(separator: ",")
        wrongDisclosureType[SceneDraftStore.disclosureKey] = "true"

        #expect(SceneDraftStore.serialize(values: Array(values.dropLast()), disclosure: true) == nil)
        #expect(SceneDraftStore.deserialize([:]) == nil)
        #expect(SceneDraftStore.deserialize(missingDisclosure) == nil)
        #expect(SceneDraftStore.deserialize(wrongValueCount) == nil)
        #expect(SceneDraftStore.deserialize(wrongValuesType) == nil)
        #expect(SceneDraftStore.deserialize(wrongDisclosureType) == nil)
    }

    @Test func independentSceneDraftsRemainIsolated() throws {
        let suiteName = "SceneDraftStoreTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let firstValues = ["31.5", "0", "32", "24", "", "20.5", ".", "", ""]
        let secondValues = ["28", "22", "30", "26", "144", "", "", "46", "7"]
        let firstDraft = try #require(
            SceneDraftStore.serialize(values: firstValues, disclosure: true)
        )
        let secondDraft = try #require(
            SceneDraftStore.serialize(values: secondValues, disclosure: false)
        )
        SceneDraftStore.save(
            firstDraft,
            sceneID: "scene-a",
            defaults: defaults
        )
        SceneDraftStore.save(
            secondDraft,
            sceneID: "scene-b",
            defaults: defaults
        )

        let firstRestored = try #require(
            SceneDraftStore.load(sceneID: "scene-a", defaults: defaults)
                .flatMap(SceneDraftStore.deserialize)
        )
        let secondRestored = try #require(
            SceneDraftStore.load(sceneID: "scene-b", defaults: defaults)
                .flatMap(SceneDraftStore.deserialize)
        )

        #expect(firstRestored.values == firstValues)
        #expect(firstRestored.disclosure)
        #expect(secondRestored.values == secondValues)
        #expect(!secondRestored.disclosure)
    }

    @Test func resetDraftPersistsThroughHandoffAndDiscardRemovesOnlyItsScene() throws {
        let suiteName = "SceneDraftStoreResetTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let resetValues = GaugeTextDefaults().resetSceneDraftValues
        let resetDraft = try #require(
            SceneDraftStore.serialize(values: resetValues, disclosure: false)
        )
        let otherValues = ["28", "22", "30", "26", "144", "", "", "46", "7"]
        let otherDraft = try #require(
            SceneDraftStore.serialize(values: otherValues, disclosure: true)
        )
        SceneDraftStore.save(resetDraft, sceneID: "scene-a", defaults: defaults)
        SceneDraftStore.save(otherDraft, sceneID: "scene-b", defaults: defaults)
        SceneDraftStore.setSingleSceneID("scene-a", defaults: defaults)
        SceneDraftStore.setSingleSceneHandoff(resetDraft, defaults: defaults)

        let resetRestored = try #require(
            SceneDraftStore.load(sceneID: "scene-a", defaults: defaults)
                .flatMap(SceneDraftStore.deserialize)
        )
        let handoffRestored = try #require(
            SceneDraftStore.singleSceneHandoff(defaults: defaults)
                .flatMap(SceneDraftStore.deserialize)
        )

        #expect(resetRestored.values == ["32", "24", "32", "32", "", "", "", "", ""])
        #expect(!resetRestored.disclosure)
        #expect(handoffRestored.values == resetRestored.values)
        #expect(!handoffRestored.disclosure)

        SceneDraftStore.discard(sceneIDs: ["scene-a"], defaults: defaults)
        #expect(SceneDraftStore.load(sceneID: "scene-a", defaults: defaults) == nil)
        #expect(
            SceneDraftStore.load(sceneID: "scene-b", defaults: defaults)
                .flatMap(SceneDraftStore.deserialize)?.values == otherValues
        )
        #expect(SceneDraftStore.singleSceneID(defaults: defaults) == nil)
        #expect(SceneDraftStore.singleSceneHandoff(defaults: defaults) == nil)
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
        let expectedLabels: [(GaugeFormField, String)] = [
            (.patternStitches, "Pattern stitch gauge, per 10 centimeters / 4 inches"),
            (.patternRows, "Pattern row gauge, per 10 centimeters / 4 inches"),
            (.yourStitches, "Swatch stitch gauge, per 10 centimeters / 4 inches"),
            (.yourRows, "Swatch row gauge, per 10 centimeters / 4 inches"),
        ]

        for (field, expectedLabel) in expectedLabels {
            let label = GaugeInputsCard.accessibilityLabel(for: field)
            #expect(label == expectedLabel)
            #expect(
                GaugeStepperField.pickerAccessibilityLabel(for: label)
                    == "Open picker for \(expectedLabel)"
            )
        }
    }

    @Test func resultsActionTokensMeetTextContrastInLightAndDark() throws {
        let appDirectory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let sourceURL = appDirectory
            .appendingPathComponent("KnittingGaugeReconciler/Views/RequiredAdjustmentsCard.swift")
        let source = try String(contentsOf: sourceURL, encoding: .utf8)
        let shareStart = try #require(source.range(of: "Text(\"Share results\")")?.lowerBound)
        let mathStart = try #require(source.range(of: "Text(showFullMath ?")?.lowerBound)
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
        let stepper = try sourceSection(
            "KnittingGaugeReconciler/Components/GaugeStepperField.swift",
            from: "struct DeltaPillBadge",
            to: "struct GaugeStepperField",
            appDirectory: appDirectory
        )
        let adjustment = try sourceSection(
            "KnittingGaugeReconciler/Views/AdjustmentRow.swift",
            from: "if let pill = driftPill {",
            to: ".accessibilityElement(children: .ignore)",
            appDirectory: appDirectory
        )
        for source in [stepper, adjustment] {
            #expect(source.contains(".foregroundStyle(AppTheme.card)"))
            #expect(source.contains(".background(AppTheme.deltaPill)"))
        }

        let themeURL = appDirectory
            .appendingPathComponent("KnittingGaugeReconciler/Components/AppTheme.swift")
        let themeSource = try String(contentsOf: themeURL, encoding: .utf8)
        #expect(themeSource.contains("static let deltaPill        = ink"))

        let ink = try themeColors(named: "app-theme-ink", appDirectory: appDirectory)
        let card = try themeColors(named: "app-theme-card", appDirectory: appDirectory)
        for appearance in ["light", "dark"] {
            #expect(
                contrastRatio(
                    try #require(card[appearance]),
                    try #require(ink[appearance])
                ) >= 4.5
            )
        }
    }

    @Test func gaugeStepperBoundariesMeetNonTextContrastInLightAndDark() throws {
        let appDirectory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let boundary = try sourceSection(
            "KnittingGaugeReconciler/Components/GaugeStepperField.swift",
            from: ".background(AppTheme.card)",
            to: "// Expose the entire field container",
            appDirectory: appDirectory
        )
        #expect(boundary.contains("? AppTheme.mismatchText"))
        #expect(boundary.contains(": AppTheme.muted"))
        #expect(boundary.contains(").opacity(0.7)"))

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
                "KnittingGaugeReconciler/Components/AdjustmentValuePair.swift",
                "Text(yourLabel)",
                "Text(\"\\(yourValue)\")",
                "private var yourTile",
                "private var yourTileAccessibilityLabel"
            ),
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
        #expect(MeasurementUnit.inches.displayIntToCmString(8) == "20.32")
        #expect(MeasurementUnit.inches.displayIntToCmString(20) == "50.8")
        #expect(MeasurementUnit.inches.displayIntToCmString(18) == "45.72")
        #expect(MeasurementUnit.inches.displayIntToCmString(1) == "2.54")
        #expect(MeasurementUnit.inches.displayIntToCmString(Int.max) == nil)
    }

    @Test func matchingGaugePreservesWholeInchLengthInResults() throws {
        let storedDepthText = MeasurementUnit.inches.centimeterStorageText(
            from: "8",
            cmRange: 5...100
        )
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
        let decimal = MeasurementUnit.inches.centimeterStorageText(from: "8.5", cmRange: 5...100)
        let oversized = MeasurementUnit.inches.centimeterStorageText(
            from: "\(Int.max)",
            cmRange: 5...100
        )

        #expect(MeasurementUnit.invalidInchesText(from: decimal) == "8.5")
        #expect(MeasurementUnit.invalidInchesText(from: oversized) == "\(Int.max)")
        #expect(GaugeMath.validate(decimal, for: .patternYokeDepth) == .failure(.invalidNumber))
        #expect(GaugeMath.validate(oversized, for: .patternYokeDepth) == .failure(.invalidNumber))
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
            let recoveredCm = recoveredCmStr.flatMap(Double.init) ?? 0
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
