import SwiftUI

struct ContentView: View {
    @State private var patternStitches = initialText("KGR_PS", defaultValue: "32")
    @State private var patternRows = initialText("KGR_PR", defaultValue: "24")
    @State private var yourStitches = initialText("KGR_YS", defaultValue: "32")
    @State private var yourRows = initialText("KGR_YR", defaultValue: "32")
    @State private var patternCastOn = initialText("KGR_CAST_ON", defaultValue: "128")
    @State private var patternYoke = initialText("KGR_YOKE", defaultValue: "20")
    @State private var patternBody = initialText("KGR_BODY", defaultValue: "50")
    @State private var patternSleeve = initialText("KGR_SLEEVE", defaultValue: "45")
    @State private var patternIncreases = initialText("KGR_INCREASES", defaultValue: "6")
    @State private var hasCalculated = false

    private var inputs: GaugeInputs {
        GaugeInputs(
            patternStitches: read(patternStitches, defaultValue: 32),
            patternRows: read(patternRows, defaultValue: 24),
            yourStitches: read(yourStitches, defaultValue: 32),
            yourRows: read(yourRows, defaultValue: 32),
            patternYokeDepth: read(patternYoke, defaultValue: 20),
            patternBodyLength: read(patternBody, defaultValue: 50),
            patternSleeveLength: read(patternSleeve, defaultValue: 45),
            patternIncreaseSpacing: read(patternIncreases, defaultValue: 6),
            patternCastOn: read(patternCastOn, defaultValue: 128)
        )
    }

    private var result: GaugeMathResult {
        GaugeMath.compute(inputs)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    gaugeCard
                    calculateButton
                    verdictCard
                    heroCard
                    adjustmentsCard
                }
                .padding()
            }
            .background(Color(red: 0.98, green: 0.96, blue: 0.94))
            .navigationTitle("Gauge Reconciler")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Knitting Gauge Reconciler")
                .font(.largeTitle.bold())
            Text("Enter the pattern gauge and your blocked swatch. One calculation gives concrete stitch counts and section targets.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    private var gaugeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionTitle("Pattern gauge")
            HStack(spacing: 12) {
                NumberField(title: "Pattern stitches", text: $patternStitches, unit: "st / 10 cm", identifier: "pattern-stitches")
                NumberField(title: "Pattern rows", text: $patternRows, unit: "rows / 10 cm", identifier: "pattern-rows")
            }

            SectionTitle("Your swatch")
            HStack(spacing: 12) {
                NumberField(title: "Your stitches", text: $yourStitches, unit: "st / 10 cm", identifier: "your-stitches")
                NumberField(title: "Your rows", text: $yourRows, unit: "rows / 10 cm", identifier: "your-rows")
            }

            SectionTitle("Pattern instructions")
            NumberField(title: "Pattern cast-on", text: $patternCastOn, unit: "stitches", identifier: "pattern-cast-on")
            HStack(spacing: 12) {
                NumberField(title: "Yoke depth", text: $patternYoke, unit: "cm", identifier: "pattern-yoke")
                NumberField(title: "Body length", text: $patternBody, unit: "cm", identifier: "pattern-body")
            }
            HStack(spacing: 12) {
                NumberField(title: "Sleeve length", text: $patternSleeve, unit: "cm", identifier: "pattern-sleeve")
                NumberField(title: "Increase every", text: $patternIncreases, unit: "rows", identifier: "pattern-increases")
            }
        }
        .cardStyle()
    }

    private var calculateButton: some View {
        Button {
            hasCalculated = true
        } label: {
            Text("Calculate")
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 50)
        }
        .buttonStyle(.borderedProminent)
        .accessibilityIdentifier("calculate-button")
    }

    private var verdictCard: some View {
        Group {
            if hasCalculated {
                VStack(alignment: .leading, spacing: 8) {
                    Text(verdictTitle)
                        .font(.title2.bold())
                    Text(verdictBody)
                        .font(.body)
                    Text("Cast on \(result.adjustedCastOn) stitches")
                        .font(.title.bold())
                        .accessibilityIdentifier("cast-on-result")
                }
            } else {
                Text("Enter your gauge, then press Calculate to see the adjusted cast-on and section targets.")
                    .font(.headline)
                    .accessibilityIdentifier("placeholder-verdict")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(red: 0.94, green: 0.90, blue: 0.97))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.purple.opacity(0.35)))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("verdict-card")
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle("Hero ratios")
            HStack(spacing: 12) {
                HeroMetric(
                    title: "Stitch gauge",
                    value: "\(GaugeMath.fmtPct(result.stitchWidthScale))%",
                    status: gaugeStatus(scale: result.stitchWidthScale),
                    detail: "Pattern \(formatPlain(inputs.patternStitches)) st · You \(formatPlain(inputs.yourStitches)) st",
                    identifier: "stitch-hero"
                )
                HeroMetric(
                    title: "Row gauge",
                    value: "\(GaugeMath.fmtPct(result.rowCountScale))%",
                    status: rowStatus(scale: result.rowCountScale),
                    detail: "Pattern \(formatPlain(inputs.patternRows)) rows · You \(formatPlain(inputs.yourRows)) rows",
                    identifier: "row-hero"
                )
            }
        }
        .cardStyle()
    }

    private var adjustmentsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle("Per-section adjustments")
            AdjustmentRow(name: "Yoke depth", pattern: "\(formatPlain(inputs.patternYokeDepth)) cm", adjusted: "\(GaugeMath.fmtCm(result.adjustedYokeDepth)) cm")
            AdjustmentRow(name: "Body length", pattern: "\(formatPlain(inputs.patternBodyLength)) cm", adjusted: "\(GaugeMath.fmtCm(result.adjustedBodyLength)) cm")
            AdjustmentRow(name: "Sleeve length", pattern: "\(formatPlain(inputs.patternSleeveLength)) cm", adjusted: "\(GaugeMath.fmtCm(result.adjustedSleeveLength)) cm")
            AdjustmentRow(name: "Increase-row spacing", pattern: "Every \(formatPlain(inputs.patternIncreaseSpacing)) rows", adjusted: "Every \(GaugeMath.fmtRows(result.adjustedIncreaseSpacing)) rows")
            AdjustmentRow(name: "Cast-on stitches", pattern: "\(formatPlain(inputs.patternCastOn)) stitches", adjusted: "\(result.adjustedCastOn) stitches")
        }
        .cardStyle()
        .accessibilityIdentifier("adjustments-table")
    }

    private var verdictTitle: String {
        let stitchDrift = abs(result.stitchWidthScale - 1)
        let rowDrift = abs(result.rowCountScale - 1)

        if stitchDrift < 0.03, rowDrift < 0.03 {
            return "Gauge match"
        }
        if stitchDrift >= 0.15 || rowDrift >= 0.15 {
            return "Major mismatch"
        }
        if stitchDrift >= 0.10 || rowDrift >= 0.10 {
            return "Significant drift"
        }
        return "Minor drift"
    }

    private var verdictBody: String {
        let stitchPercent = abs(GaugeMath.fmtPct(result.stitchWidthScale) - 100)
        let rowPercent = abs(GaugeMath.fmtPct(result.rowCountScale) - 100)

        switch verdictTitle {
        case "Gauge match":
            return "Both axes are within 2%. Cast on as written and knit the pattern targets."
        case "Major mismatch":
            return "Over 15% drift on at least one axis. Use \(result.adjustedCastOn) as the math check, but re-swatch or change needle size before proceeding."
        case "Significant drift":
            return "Stitches are \(stitchPercent)% off and rows are \(rowPercent)% off. Check every section target before knitting."
        default:
            return "One axis is off by up to 10%. Adjusted: cast on \(result.adjustedCastOn) stitches and knit body to \(GaugeMath.fmtCm(result.adjustedBodyLength)) cm."
        }
    }
}

private struct NumberField: View {
    var title: String
    @Binding var text: String
    var unit: String
    var identifier: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            TextField(title, text: $text)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .font(.system(.title3, design: .monospaced).weight(.semibold))
                .frame(minHeight: 44)
                .accessibilityIdentifier(identifier)
            Text(unit)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SectionTitle: View {
    var title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title.uppercased())
            .font(.caption.weight(.bold))
            .foregroundStyle(.purple)
            .accessibilityAddTraits(.isHeader)
    }
}

private struct HeroMetric: View {
    var title: String
    var value: String
    var status: String
    var detail: String
    var identifier: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .minimumScaleFactor(0.7)
                .accessibilityIdentifier("\(identifier)-value")
            Text(status)
                .font(.caption.weight(.bold))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(status == "Match" ? Color.green.opacity(0.18) : Color.orange.opacity(0.22))
                .clipShape(Capsule())
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityIdentifier(identifier)
    }
}

private struct AdjustmentRow: View {
    var name: String
    var pattern: String
    var adjusted: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.body.weight(.semibold))
                Text("Pattern: \(pattern)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 12)
            Text(adjusted)
                .font(.system(.body, design: .monospaced).weight(.bold))
                .foregroundStyle(.purple)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("adjustment-\(name.lowercased().replacingOccurrences(of: " ", with: "-"))")
    }
}

private extension View {
    func cardStyle() -> some View {
        padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
    }
}

private func initialText(_ environmentKey: String, defaultValue: String) -> String {
    ProcessInfo.processInfo.environment[environmentKey] ?? defaultValue
}

private func read(_ text: String, defaultValue: Double) -> Double {
    GaugeMath.sanitized(Double(text), default: defaultValue)
}

private func formatPlain(_ value: Double) -> String {
    value.rounded() == value ? String(Int(value)) : String(value)
}

private func gaugeStatus(scale: Double) -> String {
    let drift = abs(scale - 1)
    if drift < 0.03 {
        return "Match"
    }
    return scale > 1 ? "Looser than pattern" : "Tighter than pattern"
}

private func rowStatus(scale: Double) -> String {
    let drift = abs(scale - 1)
    if drift < 0.03 {
        return "Match"
    }
    return scale > 1 ? "Denser than pattern" : "Looser than pattern"
}
