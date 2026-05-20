import Foundation

struct GaugeInputs: Equatable {
    var patternStitches: Double = 32
    var patternRows: Double = 24
    var yourStitches: Double = 32
    var yourRows: Double = 32
    var patternYokeDepth: Double = 20
    var patternBodyLength: Double = 50
    var patternSleeveLength: Double = 45
    var patternIncreaseSpacing: Double = 6
    var patternCastOn: Double = 128
}

struct GaugeMathResult: Equatable {
    var stitchWidthScale: Double
    var stitchCountMultiplier: Double
    var rowCountScale: Double
    var dimensionScale: Double
    var adjustedYokeDepth: Double
    var adjustedBodyLength: Double
    var adjustedSleeveLength: Double
    var patternYokeRows: Double
    var patternBodyRows: Double
    var patternSleeveRows: Double
    var adjustedYokeRows: Double
    var adjustedBodyRows: Double
    var adjustedSleeveRows: Double
    var adjustedIncreaseSpacing: Double
    var adjustedCastOn: Int
    var castOnRoundingDriftPercent: Double
}

enum GaugeMath {
    static func compute(_ inputs: GaugeInputs) -> GaugeMathResult {
        let stitchWidthScale = inputs.patternStitches / inputs.yourStitches
        let stitchCountMultiplier = inputs.yourStitches / inputs.patternStitches
        let rowCountScale = inputs.yourRows / inputs.patternRows
        let dimensionScale = inputs.patternRows / inputs.yourRows
        let patternRowsPerCm = inputs.patternRows / 10
        let yourRowsPerCm = inputs.yourRows / 10
        let exactCastOn = inputs.patternCastOn * stitchCountMultiplier
        let adjustedCastOn = Int(exactCastOn.rounded())
        let castOnRoundingDriftPercent = ((Double(adjustedCastOn) - exactCastOn) / exactCastOn) * 100

        return GaugeMathResult(
            stitchWidthScale: stitchWidthScale,
            stitchCountMultiplier: stitchCountMultiplier,
            rowCountScale: rowCountScale,
            dimensionScale: dimensionScale,
            adjustedYokeDepth: inputs.patternYokeDepth * dimensionScale,
            adjustedBodyLength: inputs.patternBodyLength * dimensionScale,
            adjustedSleeveLength: inputs.patternSleeveLength * dimensionScale,
            patternYokeRows: inputs.patternYokeDepth * patternRowsPerCm,
            patternBodyRows: inputs.patternBodyLength * patternRowsPerCm,
            patternSleeveRows: inputs.patternSleeveLength * patternRowsPerCm,
            adjustedYokeRows: inputs.patternYokeDepth * dimensionScale * yourRowsPerCm,
            adjustedBodyRows: inputs.patternBodyLength * dimensionScale * yourRowsPerCm,
            adjustedSleeveRows: inputs.patternSleeveLength * dimensionScale * yourRowsPerCm,
            adjustedIncreaseSpacing: inputs.patternIncreaseSpacing * rowCountScale,
            adjustedCastOn: adjustedCastOn,
            castOnRoundingDriftPercent: castOnRoundingDriftPercent
        )
    }

    static func sanitized(_ value: Double?, default defaultValue: Double) -> Double {
        guard let value, value.isFinite, value > 0 else {
            return defaultValue
        }
        return value
    }

    static func fmtCm(_ value: Double) -> String {
        String(format: "%.1f", (value * 10).rounded() / 10)
    }

    static func fmtRows(_ value: Double) -> Int {
        max(1, Int(value.rounded()))
    }

    static func fmtPct(_ value: Double) -> Int {
        Int((value * 100).rounded())
    }
}

struct ResultsExportSummary: Equatable {
    struct GaugePair: Equatable {
        var stitches: String
        var rows: String
    }

    struct Metric: Equatable {
        var title: String
        var value: String
        var status: String
    }

    struct SectionGuidance: Equatable {
        var name: String
        var pattern: String
        var adjusted: String
        var textLine: String
    }

    var title = "Knitting Gauge Reconciler"
    var patternGauge: GaugePair
    var swatchGauge: GaugePair
    var stitchMetric: Metric
    var rowMetric: Metric
    var castOn: String
    var sections: [SectionGuidance]

    init(inputs: GaugeInputs, result: GaugeMathResult) {
        patternGauge = GaugePair(
            stitches: "\(plain(inputs.patternStitches)) st / 10 cm",
            rows: "\(plain(inputs.patternRows)) rows / 10 cm"
        )
        swatchGauge = GaugePair(
            stitches: "\(plain(inputs.yourStitches)) st / 10 cm",
            rows: "\(plain(inputs.yourRows)) rows / 10 cm"
        )
        stitchMetric = Metric(
            title: "Stitch-wise",
            value: "\(GaugeMath.fmtPct(result.stitchWidthScale))%",
            status: gaugeStatus(scale: result.stitchWidthScale)
        )
        rowMetric = Metric(
            title: "Row-wise",
            value: "\(GaugeMath.fmtPct(result.rowCountScale))%",
            status: rowStatus(scale: result.rowCountScale)
        )
        castOn = "Cast on \(result.adjustedCastOn) stitches instead of \(plain(inputs.patternCastOn))"

        let rowsModel = ResultsExportRowsModel(inputs: inputs, result: result)
        sections = rowsModel.sections
    }
}

enum ResultsShareTextFormatter {
    static func string(inputs: GaugeInputs, result: GaugeMathResult) -> String {
        let summary = ResultsExportSummary(inputs: inputs, result: result)
        return """
        \(summary.title)

        Pattern gauge
        • Stitches: \(summary.patternGauge.stitches)
        • Rows: \(summary.patternGauge.rows)

        Swatch gauge
        • Stitches: \(summary.swatchGauge.stitches)
        • Rows: \(summary.swatchGauge.rows)

        Correction summary
        • Stitch-wise: \(summary.stitchMetric.value) (\(summary.stitchMetric.status))
        • Row-wise: \(summary.rowMetric.value) (\(summary.rowMetric.status))
        • Cast-on: \(summary.castOn.lowercased())

        Section row/round guidance
        \(summary.sections.map(\.textLine).joined(separator: "\n"))
        """
    }
}

private struct ResultsExportRowsModel {
    var sections: [ResultsExportSummary.SectionGuidance] {
        [
            section(name: "Yoke depth", cm: result.adjustedYokeDepth, adjustedRows: result.adjustedYokeRows, patternRows: result.patternYokeRows),
            section(name: "Body length", cm: result.adjustedBodyLength, adjustedRows: result.adjustedBodyRows, patternRows: result.patternBodyRows),
            section(name: "Sleeve length", cm: result.adjustedSleeveLength, adjustedRows: result.adjustedSleeveRows, patternRows: result.patternSleeveRows),
            ResultsExportSummary.SectionGuidance(
                name: "Increase-row spacing",
                pattern: "Every \(plain(inputs.patternIncreaseSpacing)) rows",
                adjusted: "Space every \(GaugeMath.fmtRows(result.adjustedIncreaseSpacing)) rows/rounds",
                textLine: "• Increase-row spacing: space every \(GaugeMath.fmtRows(result.adjustedIncreaseSpacing)) rows/rounds (pattern every \(plain(inputs.patternIncreaseSpacing)) rows)"
            )
        ]
    }

    private let inputs: GaugeInputs
    private let result: GaugeMathResult

    init(inputs: GaugeInputs, result: GaugeMathResult) {
        self.inputs = inputs
        self.result = result
    }

    private func section(name: String, cm: Double, adjustedRows: Double, patternRows: Double) -> ResultsExportSummary.SectionGuidance {
        let adjusted = "Knit to \(GaugeMath.fmtCm(cm)) cm; about \(GaugeMath.fmtRows(adjustedRows)) rows/rounds"
        let pattern = "Pattern about \(GaugeMath.fmtRows(patternRows)) rows"
        return ResultsExportSummary.SectionGuidance(
            name: name,
            pattern: pattern,
            adjusted: adjusted,
            textLine: "• \(name): \(adjusted) (pattern about \(GaugeMath.fmtRows(patternRows)) rows)"
        )
    }
}


private func plain(_ value: Double) -> String {
    value.rounded() == value ? String(Int(value)) : fixed(value, places: 2).trimmingTrailingZeroes()
}

private func fixed(_ value: Double, places: Int) -> String {
    String(format: "%.\(places)f", value)
}

private func gaugeStatus(scale: Double) -> String {
    let drift = abs(scale - 1)
    if drift < 0.03 { return "Match" }
    if drift < 0.10 { return scale > 1 ? "Looser than pattern" : "Tighter than pattern" }
    return scale > 1 ? "Much looser" : "Much tighter"
}

private func rowStatus(scale: Double) -> String {
    let drift = abs(scale - 1)
    if drift < 0.03 { return "Match" }
    if drift < 0.10 { return scale > 1 ? "Denser than pattern" : "Looser than pattern" }
    return scale > 1 ? "Much denser" : "Much looser"
}

private extension String {
    func trimmingTrailingZeroes() -> String {
        var text = self
        while text.last == "0" {
            text.removeLast()
        }
        if text.last == "." {
            text.removeLast()
        }
        return text
    }
}
