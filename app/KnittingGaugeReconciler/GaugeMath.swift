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

    /// True when the user's stitch count differs from the pattern's.
    var stitchMismatch: Bool { yourStitches != patternStitches }

    /// True when the user's row count differs from the pattern's.
    var rowMismatch: Bool { yourRows != patternRows }
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
    /// Rows to knit at the user's gauge to achieve the pattern's cm target.
    /// Formula: round((patternCm / 10) × yourRows).
    var yokeRowsAtYourGauge: Int
    var bodyRowsAtYourGauge: Int
    var sleeveRowsAtYourGauge: Int
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
            yokeRowsAtYourGauge: max(1, Int((inputs.patternYokeDepth / 10 * inputs.yourRows).rounded())),
            bodyRowsAtYourGauge: max(1, Int((inputs.patternBodyLength / 10 * inputs.yourRows).rounded())),
            sleeveRowsAtYourGauge: max(1, Int((inputs.patternSleeveLength / 10 * inputs.yourRows).rounded())),
            adjustedIncreaseSpacing: inputs.patternIncreaseSpacing * rowCountScale,
            adjustedCastOn: adjustedCastOn,
            castOnRoundingDriftPercent: castOnRoundingDriftPercent
        )
    }

    /// Clamp a gauge value to the valid wheel range [1, 99].
    static func clampedGaugeValue(_ value: Int) -> Int {
        max(1, min(99, value))
    }

    /// Parse a free-typed gauge string (from the wheel sheet's keyboard fallback) into a
    /// normalised String suitable for storing in the gauge text bindings.
    /// - Decimal values are clamped to [1, 99] and emitted as whole numbers where possible.
    /// - Empty or un-parseable input falls back to the current wheel integer selection.
    static func parseGaugeTypeText(_ text: String, fallback: Int) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, let d = Double(trimmed) else {
            return "\(clampedGaugeValue(fallback))"
        }
        let clamped = min(max(d, 1), 99)
        let isWhole = clamped == Double(Int(clamped))
        return isWhole ? "\(Int(clamped))" : String(format: "%.1f", clamped)
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
            section(name: "Yoke depth", patternCm: inputs.patternYokeDepth, rowsAtYourGauge: result.yokeRowsAtYourGauge),
            section(name: "Body length", patternCm: inputs.patternBodyLength, rowsAtYourGauge: result.bodyRowsAtYourGauge),
            section(name: "Sleeve length", patternCm: inputs.patternSleeveLength, rowsAtYourGauge: result.sleeveRowsAtYourGauge),
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

    private func section(name: String, patternCm: Double, rowsAtYourGauge: Int) -> ResultsExportSummary.SectionGuidance {
        let pattern = "\(plain(patternCm)) cm"
        let adjusted = "Knit \(rowsAtYourGauge) rows"
        return ResultsExportSummary.SectionGuidance(
            name: name,
            pattern: pattern,
            adjusted: adjusted,
            textLine: "• \(name): \(plain(patternCm)) cm → knit \(rowsAtYourGauge) rows"
        )
    }
}


func plain(_ value: Double) -> String {
    value.rounded() == value ? String(Int(value)) : fixed(value, places: 2).trimmingTrailingZeroes()
}

private func fixed(_ value: Double, places: Int) -> String {
    String(format: "%.\(places)f", value)
}

func gaugeStatus(scale: Double) -> String {
    let drift = abs(scale - 1)
    if drift < 0.03 { return "Match" }
    if drift < 0.10 { return scale > 1 ? "Looser than pattern" : "Tighter than pattern" }
    return scale > 1 ? "Much looser" : "Much tighter"
}

func rowStatus(scale: Double) -> String {
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
