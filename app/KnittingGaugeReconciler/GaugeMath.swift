import Foundation

/// Validated gauge values. Only the four required gauge samples have defaults.
struct GaugeInputs: Equatable {
    var patternStitches: Double = 32
    var patternRows: Double = 24
    var yourStitches: Double = 32
    var yourRows: Double = 32
    var patternYokeDepth: Double?
    var patternBodyLength: Double?
    var patternSleeveLength: Double?
    var patternIncreaseSpacing: Double?
    var patternCastOn: Double?

    /// True when the user's stitch count differs from the pattern's.
    var stitchMismatch: Bool { yourStitches != patternStitches }

    /// True when the user's row count differs from the pattern's.
    var rowMismatch: Bool { yourRows != patternRows }
}

/// Gauge corrections derived from validated inputs. Optional results mirror optional inputs.
struct GaugeMathResult: Equatable {
    var stitchWidthScale: Double
    var stitchCountMultiplier: Double
    var rowCountScale: Double
    var dimensionScale: Double
    var adjustedYokeDepth: Double?
    var adjustedBodyLength: Double?
    var adjustedSleeveLength: Double?
    var patternYokeRows: Double?
    var patternBodyRows: Double?
    var patternSleeveRows: Double?
    var adjustedYokeRows: Double?
    var adjustedBodyRows: Double?
    var adjustedSleeveRows: Double?
    var yokeRowsAtYourGauge: Int?
    var bodyRowsAtYourGauge: Int?
    var sleeveRowsAtYourGauge: Int?
    var adjustedIncreaseSpacing: Double?
    var adjustedCastOn: Int?
    var castOnRoundingDriftPercent: Double?
}

/// Deterministic validation, gauge conversion, and formatting.
enum GaugeMath {
    /// A raw input field and its canonical accepted range.
    enum Field: CaseIterable {
        case patternStitches
        case patternRows
        case yourStitches
        case yourRows
        case patternCastOn
        case patternYokeDepth
        case patternBodyLength
        case patternSleeveLength
        case patternIncreaseSpacing

        var range: ClosedRange<Double> {
            switch self {
            case .patternStitches, .patternRows, .yourStitches, .yourRows:
                return 1...99
            case .patternCastOn:
                return 40...400
            case .patternYokeDepth, .patternBodyLength, .patternSleeveLength:
                return 5...100
            case .patternIncreaseSpacing:
                return 1...30
            }
        }

        var isRequired: Bool {
            switch self {
            case .patternStitches, .patternRows, .yourStitches, .yourRows:
                return true
            default:
                return false
            }
        }
    }

    /// Why raw field text cannot become a validated value.
    enum ValidationError: Error, Equatable {
        case required
        case invalidNumber
        case outOfRange(ClosedRange<Double>)
    }

    /// Validates raw text without clamping, rounding, or substituting defaults.
    /// A blank optional field succeeds with `nil`; a blank required field fails.
    static func validate(_ text: String, for field: Field) -> Result<Double?, ValidationError> {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return field.isRequired ? .failure(.required) : .success(nil)
        }
        guard let value = Double(trimmed), value.isFinite else {
            return .failure(.invalidNumber)
        }
        guard field.range.contains(value) else {
            return .failure(.outOfRange(field.range))
        }
        return .success(value)
    }

    /// Computes gauge corrections from values accepted by `validate(_:for:)`.
    static func compute(_ inputs: GaugeInputs) -> GaugeMathResult {
        let stitchWidthScale = inputs.patternStitches / inputs.yourStitches
        let stitchCountMultiplier = inputs.yourStitches / inputs.patternStitches
        let rowCountScale = inputs.yourRows / inputs.patternRows
        let dimensionScale = inputs.patternRows / inputs.yourRows
        let patternRowsPerCm = inputs.patternRows / 10
        let yourRowsPerCm = inputs.yourRows / 10
        let exactCastOn = inputs.patternCastOn.map { $0 * stitchCountMultiplier }
        let adjustedCastOn = exactCastOn.flatMap(roundedInt)
        let castOnRoundingDriftPercent = exactCastOn.flatMap { exact in
            adjustedCastOn.map { ((Double($0) - exact) / exact) * 100 }
        }

        return GaugeMathResult(
            stitchWidthScale: stitchWidthScale,
            stitchCountMultiplier: stitchCountMultiplier,
            rowCountScale: rowCountScale,
            dimensionScale: dimensionScale,
            adjustedYokeDepth: inputs.patternYokeDepth.map { $0 * dimensionScale },
            adjustedBodyLength: inputs.patternBodyLength.map { $0 * dimensionScale },
            adjustedSleeveLength: inputs.patternSleeveLength.map { $0 * dimensionScale },
            patternYokeRows: inputs.patternYokeDepth.map { $0 * patternRowsPerCm },
            patternBodyRows: inputs.patternBodyLength.map { $0 * patternRowsPerCm },
            patternSleeveRows: inputs.patternSleeveLength.map { $0 * patternRowsPerCm },
            adjustedYokeRows: inputs.patternYokeDepth.map { $0 * dimensionScale * yourRowsPerCm },
            adjustedBodyRows: inputs.patternBodyLength.map { $0 * dimensionScale * yourRowsPerCm },
            adjustedSleeveRows: inputs.patternSleeveLength.map { $0 * dimensionScale * yourRowsPerCm },
            yokeRowsAtYourGauge: sectionRows(inputs.patternYokeDepth, yourRows: inputs.yourRows),
            bodyRowsAtYourGauge: sectionRows(inputs.patternBodyLength, yourRows: inputs.yourRows),
            sleeveRowsAtYourGauge: sectionRows(inputs.patternSleeveLength, yourRows: inputs.yourRows),
            adjustedIncreaseSpacing: inputs.patternIncreaseSpacing.map { $0 * rowCountScale },
            adjustedCastOn: adjustedCastOn,
            castOnRoundingDriftPercent: castOnRoundingDriftPercent
        )
    }

    /// Formats centimetres to one deterministic decimal place.
    static func fmtCm(_ value: Double) -> String {
        String(format: "%.1f", (value * 10).rounded() / 10)
    }

    /// Formats a validated row value as a whole number.
    static func fmtRows(_ value: Double) -> Int {
        max(1, roundedInt(value) ?? 0)
    }

    /// Formats a validated scale as a whole percentage.
    static func fmtPct(_ value: Double) -> Int {
        roundedInt(value * 100) ?? 0
    }

    private static func sectionRows(_ centimeters: Double?, yourRows: Double) -> Int? {
        centimeters.flatMap { roundedInt(($0 / 10) * yourRows) }
    }

    private static func roundedInt(_ value: Double) -> Int? {
        Int(exactly: value.rounded())
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

    var title = "Stitchwise"
    var patternGauge: GaugePair
    var swatchGauge: GaugePair
    var stitchMetric: Metric
    var rowMetric: Metric
    var castOn: String?
    var sections: [SectionGuidance]

    init(inputs: GaugeInputs, result: GaugeMathResult, unit: MeasurementUnit = .centimeters) {
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
        if let patternCastOn = inputs.patternCastOn, let adjustedCastOn = result.adjustedCastOn {
            castOn = "Cast on \(adjustedCastOn) stitches instead of \(plain(patternCastOn))"
        }

        let rowsModel = ResultsExportRowsModel(inputs: inputs, result: result, unit: unit)
        sections = rowsModel.sections
    }
}

enum ResultsShareTextFormatter {
    /// Returns deterministic plain text, omitting guidance for absent optional inputs.
    static func string(inputs: GaugeInputs, result: GaugeMathResult, unit: MeasurementUnit = .centimeters) -> String {
        let summary = ResultsExportSummary(inputs: inputs, result: result, unit: unit)
        var lines = [
            summary.title,
            "",
            "Pattern gauge",
            "• Stitches: \(summary.patternGauge.stitches)",
            "• Rows: \(summary.patternGauge.rows)",
            "",
            "Swatch gauge",
            "• Stitches: \(summary.swatchGauge.stitches)",
            "• Rows: \(summary.swatchGauge.rows)",
            "",
            "Correction summary",
            "• Stitch-wise: \(summary.stitchMetric.value) (\(summary.stitchMetric.status))",
            "• Row-wise: \(summary.rowMetric.value) (\(summary.rowMetric.status))"
        ]
        if let castOn = summary.castOn {
            lines.append("• Cast-on: \(castOn.lowercased())")
        }
        if !summary.sections.isEmpty {
            lines += ["", "Section row/round guidance"]
            lines += summary.sections.map(\.textLine)
        }
        return lines.joined(separator: "\n")
    }
}

private struct ResultsExportRowsModel {
    var sections: [ResultsExportSummary.SectionGuidance] {
        var values: [ResultsExportSummary.SectionGuidance] = []
        if let patternCm = inputs.patternYokeDepth, let rows = result.yokeRowsAtYourGauge {
            values.append(section(
                name: "Yoke depth",
                patternCm: patternCm,
                rowsAtYourGauge: rows
            ))
        }
        if let patternCm = inputs.patternBodyLength, let rows = result.bodyRowsAtYourGauge {
            values.append(section(
                name: "Body length",
                patternCm: patternCm,
                rowsAtYourGauge: rows
            ))
        }
        if let patternCm = inputs.patternSleeveLength, let rows = result.sleeveRowsAtYourGauge {
            values.append(section(
                name: "Sleeve length",
                patternCm: patternCm,
                rowsAtYourGauge: rows
            ))
        }
        if let patternSpacing = inputs.patternIncreaseSpacing,
           let adjustedSpacing = result.adjustedIncreaseSpacing {
            let adjustedRows = GaugeMath.fmtRows(adjustedSpacing)
            values.append(ResultsExportSummary.SectionGuidance(
                name: "Increase-row spacing",
                pattern: "Every \(plain(patternSpacing)) rows",
                adjusted: "Space every \(adjustedRows) rows/rounds",
                textLine: "• Increase-row spacing: space every " +
                    "\(adjustedRows) rows/rounds " +
                    "(pattern every \(plain(patternSpacing)) rows)"
            ))
        }
        return values
    }

    private let inputs: GaugeInputs
    private let result: GaugeMathResult
    private let unit: MeasurementUnit

    init(inputs: GaugeInputs, result: GaugeMathResult, unit: MeasurementUnit = .centimeters) {
        self.inputs = inputs
        self.result = result
        self.unit = unit
    }

    private func section(
        name: String, patternCm: Double, rowsAtYourGauge: Int
    ) -> ResultsExportSummary.SectionGuidance {
        let pattern = unit.formatMeasurement(patternCm)
        let adjusted = "Knit \(rowsAtYourGauge) rows"
        return ResultsExportSummary.SectionGuidance(
            name: name,
            pattern: pattern,
            adjusted: adjusted,
            textLine: "• \(name): \(unit.formatMeasurement(patternCm)) → knit \(rowsAtYourGauge) rows"
        )
    }
}

func plain(_ value: Double) -> String {
    if let integer = Int(exactly: value) {
        return String(integer)
    }
    return fixed(value, places: 2).trimmingTrailingZeroes()
}

private func fixed(_ value: Double, places: Int) -> String {
    String(format: "%.\(places)f", value)
}

func gaugeStatus(scale: Double) -> String {
    if scale > 0.97, scale < 1.03 { return "Match" }
    if scale > 0.90, scale < 1.10 { return scale > 1 ? "Looser than pattern" : "Tighter than pattern" }
    return scale > 1 ? "Much looser" : "Much tighter"
}

func rowStatus(scale: Double) -> String {
    if scale > 0.97, scale < 1.03 { return "Match" }
    if scale > 0.90, scale < 1.10 { return scale > 1 ? "Denser than pattern" : "Looser than pattern" }
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
