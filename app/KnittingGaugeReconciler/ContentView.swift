import SwiftUI
import UIKit

struct ContentView: View {
    private static let defaults = GaugeTextDefaults()

    @State private var patternStitches = initialText("KGR_PS", defaultValue: "32")
    @State private var patternRows = initialText("KGR_PR", defaultValue: "24")
    @State private var yourStitches = initialText("KGR_YS", defaultValue: "32")
    @State private var yourRows = initialText("KGR_YR", defaultValue: "32")
    @State private var patternCastOn = initialText("KGR_CAST_ON", defaultValue: "128")
    @State private var patternYoke = initialText("KGR_YOKE", defaultValue: "20")
    @State private var patternBody = initialText("KGR_BODY", defaultValue: "50")
    @State private var patternSleeve = initialText("KGR_SLEEVE", defaultValue: "45")
    @State private var patternIncreases = initialText("KGR_INCREASES", defaultValue: "6")
    @State private var shareButtonTitle = "Copy share link"
    @State private var showFullMath = false

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
                    reconciliationCard
                    adjustmentsCard
                    aboutCard
                    privacyCard
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Knitting Gauge Reconciler")
                .font(.system(.largeTitle, design: .serif).weight(.bold))
                .foregroundStyle(AppTheme.ink)
            Text("Type your swatch. See every per-section adjustment — instantly.")
                .font(.body)
                .lineSpacing(3)
                .foregroundStyle(AppTheme.muted)
        }
    }

    private var gaugeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionTitle("Pattern gauge (per 10 cm)")
            AdaptiveTwoColumnStack {
                NumberField(
                    title: "Pattern stitches",
                    text: $patternStitches,
                    unit: "st / 10 cm",
                    identifier: "pattern-stitches"
                )
            } trailing: {
                NumberField(title: "Pattern rows", text: $patternRows, unit: "rows / 10 cm", identifier: "pattern-rows")
            }

            SectionTitle("Your swatch (per 10 cm)")
            AdaptiveTwoColumnStack {
                NumberField(
                    title: "Your stitches",
                    text: $yourStitches,
                    unit: "st / 10 cm",
                    hint: "measure on a blocked swatch",
                    identifier: "your-stitches"
                )
            } trailing: {
                NumberField(
                    title: "Your rows",
                    text: $yourRows,
                    unit: "rows / 10 cm",
                    hint: "same swatch, vertical count",
                    identifier: "your-rows"
                )
            }

            SectionTitle("Pattern instructions")
            NumberField(title: "Pattern cast-on", text: $patternCastOn, unit: "stitches", identifier: "pattern-cast-on")
            AdaptiveTwoColumnStack {
                NumberField(title: "Yoke depth", text: $patternYoke, unit: "cm", identifier: "pattern-yoke")
            } trailing: {
                NumberField(title: "Body length", text: $patternBody, unit: "cm", identifier: "pattern-body")
            }
            AdaptiveTwoColumnStack {
                NumberField(title: "Sleeve length", text: $patternSleeve, unit: "cm", identifier: "pattern-sleeve")
            } trailing: {
                NumberField(title: "Increase every", text: $patternIncreases, unit: "rows", identifier: "pattern-increases")
            }
        }
        .cardStyle()
    }

    private var reconciliationCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle("Reconciliation — both axes")
            AdaptiveTwoColumnStack(spacing: 14) {
                HeroMetric(
                    title: "Stitch-wise (horizontal)",
                    value: "\(GaugeMath.fmtPct(result.stitchWidthScale))%",
                    status: gaugeStatus(scale: result.stitchWidthScale),
                    detail: "Pattern asks \(formatPlain(inputs.patternStitches)) st/10cm · You hit \(formatPlain(inputs.yourStitches)) st/10cm",
                    identifier: "stitch-hero"
                )
            } trailing: {
                HeroMetric(
                    title: "Row-wise (vertical)",
                    value: "\(GaugeMath.fmtPct(result.rowCountScale))%",
                    status: rowStatus(scale: result.rowCountScale),
                    detail: "Pattern asks \(formatPlain(inputs.patternRows)) rows/10cm · You hit \(formatPlain(inputs.yourRows)) rows/10cm",
                    identifier: "row-hero"
                )
            }
            verdictPanel
        }
        .cardStyle()
    }

    private var verdictPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(verdictTitle)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.sage)
            Text(verdictBody)
                .font(.subheadline)
                .foregroundStyle(AppTheme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppTheme.accentSoft)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppTheme.sage, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(verdictAccessibilityLabel)
        .accessibilityIdentifier("verdict-panel")
    }

    private var adjustmentsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle("Per-section adjustments")
            AdjustmentRow(name: "Yoke depth", pattern: "\(formatPlain(inputs.patternYokeDepth)) cm", adjusted: "Knit to \(GaugeMath.fmtCm(result.adjustedYokeDepth)) cm")
            AdjustmentRow(name: "Body length", pattern: "\(formatPlain(inputs.patternBodyLength)) cm", adjusted: "Knit to \(GaugeMath.fmtCm(result.adjustedBodyLength)) cm")
            AdjustmentRow(name: "Sleeve length", pattern: "\(formatPlain(inputs.patternSleeveLength)) cm", adjusted: "Knit to \(GaugeMath.fmtCm(result.adjustedSleeveLength)) cm")
            AdjustmentRow(name: "Increase-row spacing", pattern: "Every \(formatPlain(inputs.patternIncreaseSpacing)) rows", adjusted: "Space every \(GaugeMath.fmtRows(result.adjustedIncreaseSpacing)) rows")
            AdjustmentRow(
                name: "Cast-on stitches",
                pattern: "\(formatPlain(inputs.patternCastOn)) stitches",
                adjusted: "Cast on \(result.adjustedCastOn) stitches",
                adjustedIdentifier: "cast-on-result",
                driftPill: abs(result.castOnRoundingDriftPercent) >= 3
                    ? String(format: "%+.0f%% width", result.castOnRoundingDriftPercent)
                    : nil
            )

            Button(action: { showFullMath.toggle() }) {
                HStack {
                    Text("Show full math")
                    Spacer()
                    Image(systemName: showFullMath ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.bold))
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppTheme.sage)
            // Identifier and label allow UI tests to find this element reliably as a button.
            .accessibilityIdentifier("disclosure-full-math")
            .accessibilityLabel("Show full math")

            if showFullMath {
                Text(fullMathBreakdown)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(AppTheme.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(AppTheme.oatmeal)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .accessibilityIdentifier("show-full-math")
            }

            HStack {
                Button("Reset to defaults", action: resetToDefaults)
                    .buttonStyle(.plain)
                    .frame(minWidth: 100, minHeight: 44)
                    .contentShape(Rectangle())
                    .accessibilityIdentifier("reset-defaults")
                Spacer()
                Button(shareButtonTitle, action: copyShareSummary)
                    .buttonStyle(.plain)
                    .frame(minWidth: 100, minHeight: 44)
                    .contentShape(Rectangle())
                    .accessibilityIdentifier("copy-share-link")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppTheme.sage)
        }
        .cardStyle()
    }

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle("About this calculator")
            Text("This tool reconciles a two-axis gauge mismatch — the kind that single-number gauge calculators hide. When your stitch gauge matches the pattern but your row gauge is off (or vice versa), every vertical section ends up the wrong length unless you adjust the row counts.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("The math is deterministic: dim_scale = pattern_row / your_row adjusts vertical dimensions; stitch_scale = pattern_st / your_st describes horizontal width; increase-row spacing is rescaled by your_row / pattern_row.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Scope: This tool provides estimates based on your swatch measurements. Always test a full-size gauge swatch (washed and blocked the way you'll wash and block the finished garment) before starting your project. Numbers here are a starting point — your finished piece is the final word.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(red: 0.35, green: 0.26, blue: 0.09))
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(red: 0.96, green: 0.94, blue: 0.87))
                .overlay(alignment: .leading) {
                    Rectangle()
                        .frame(width: 3)
                        .foregroundStyle(Color(red: 0.78, green: 0.55, blue: 0.17))
                }
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .accessibilityIdentifier("about-scope")
            Text("Not affiliated with Ravelry, Knit Companion, or any pattern designer. Gauge math is conventional knitting arithmetic from open craft literature.")
                .font(.footnote.italic())
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("about-non-affiliation")
        }
        .cardStyle()
        .accessibilityIdentifier("about-card")
    }

    private var privacyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle("Privacy")
            Text("This app collects nothing. Your gauge values stay on device. No server. No analytics. No network requests of any kind.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .cardStyle()
        .accessibilityIdentifier("privacy-card")
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
        let stitchOffRange = stitchDrift >= 0.03 && stitchDrift < 0.15
        let rowOffRange = rowDrift >= 0.03 && rowDrift < 0.15
        if stitchOffRange && rowOffRange {
            return "Significant drift"
        }
        return "Drift"
    }

    private var verdictBody: String {
        let stitchDrift   = abs(result.stitchWidthScale - 1)
        let rowDrift      = abs(result.rowCountScale - 1)
        let stitchPercent = abs(GaugeMath.fmtPct(result.stitchWidthScale) - 100)
        let rowPercent    = abs(GaugeMath.fmtPct(result.rowCountScale) - 100)
        let stitchOff = stitchPercent >= 3
        let rowOff    = rowPercent >= 3
        let stitchDir = result.stitchWidthScale > 1 ? "wider" : "narrower"
        let rowDir    = result.rowCountScale > 1 ? "denser" : "looser"
        let majorNote = (stitchDrift >= 0.15 || rowDrift >= 0.15)
            ? " Over 15% drift — consider re-swatching or changing needle size before proceeding."
            : ""

        if !stitchOff && !rowOff {
            return "Both gauges match. Cast on \(result.adjustedCastOn) stitches as written. Knit straight from the pattern — no adjustments needed. Re-check after blocking."
        }
        if stitchOff && !rowOff {
            return "Your row gauge matches, but your stitch gauge is \(stitchPercent)% \(stitchDir). Cast on \(result.adjustedCastOn) stitches instead of the pattern's \(Int(inputs.patternCastOn)) to hit the same width. Vertical sections need no adjustment.\(majorNote)"
        }
        if !stitchOff {
            return "Your stitch gauge matches — cast on \(result.adjustedCastOn) stitches as written. Your row gauge is \(rowPercent)% \(rowDir) than expected; use the adjusted cm values for every vertical section.\(majorNote)"
        }
        return "Both axes are off: stitch gauge \(stitchPercent)% \(stitchDir), row gauge \(rowPercent)% \(rowDir). Cast on \(result.adjustedCastOn) stitches (not \(Int(inputs.patternCastOn))). Use the adjusted cm values for vertical sections.\(majorNote)"
    }

    private var verdictAccessibilityLabel: String {
        let stitchPercent = abs(GaugeMath.fmtPct(result.stitchWidthScale) - 100)
        let rowPercent    = abs(GaugeMath.fmtPct(result.rowCountScale) - 100)
        let stitchOff = stitchPercent >= 3
        let rowOff    = rowPercent >= 3

        if !stitchOff && !rowOff {
            return "Gauge match. Cast on \(result.adjustedCastOn) stitches. Both axes within 2 percent."
        }
        if stitchOff && !rowOff {
            return "Stitch gauge off \(stitchPercent) percent. Cast on \(result.adjustedCastOn) instead of \(Int(inputs.patternCastOn)) stitches. Row counts as written."
        }
        if !stitchOff {
            return "Row gauge off \(rowPercent) percent. Cast on \(result.adjustedCastOn) stitches as written. Check adjusted centimetre targets for vertical sections."
        }
        return "Both axes off. Cast on \(result.adjustedCastOn) instead of \(Int(inputs.patternCastOn)) stitches. Review section targets below."
    }

    private var fullMathBreakdown: String {
        """
        pattern: \(formatPlain(inputs.patternStitches)) st x \(formatPlain(inputs.patternRows)) rows per 10cm (aspect \(String(format: "%.2f", inputs.patternStitches / inputs.patternRows)))
        you:     \(formatPlain(inputs.yourStitches)) st x \(formatPlain(inputs.yourRows)) rows per 10cm (aspect \(String(format: "%.2f", inputs.yourStitches / inputs.yourRows)))
        stitch width scale = pattern_st / your_st = \(formatPlain(inputs.patternStitches)) / \(formatPlain(inputs.yourStitches)) = \(String(format: "%.3f", result.stitchWidthScale))
        row density ratio  = your_row / pattern_row = \(formatPlain(inputs.yourRows)) / \(formatPlain(inputs.patternRows)) = \(String(format: "%.3f", result.rowCountScale))
        dim correction     = pattern_row / your_row = \(formatPlain(inputs.patternRows)) / \(formatPlain(inputs.yourRows)) = \(String(format: "%.3f", result.dimensionScale))
        -> for any vertical dim D the pattern names, knit to D x \(String(format: "%.3f", result.dimensionScale)) cm
        -> for any horizontal dim, your stitch count produces \(String(format: "%.1f", result.stitchWidthScale * 100))% of the pattern's intended width
        cast-on adjust = your_st / pattern_st x patCastOn = \(formatPlain(inputs.yourStitches))/\(formatPlain(inputs.patternStitches)) x \(formatPlain(inputs.patternCastOn)) = \(result.adjustedCastOn) stitches
        """
    }

    private func resetToDefaults() {
        patternStitches = Self.defaults.patternStitches
        patternRows = Self.defaults.patternRows
        yourStitches = Self.defaults.yourStitches
        yourRows = Self.defaults.yourRows
        patternCastOn = Self.defaults.patternCastOn
        patternYoke = Self.defaults.patternYoke
        patternBody = Self.defaults.patternBody
        patternSleeve = Self.defaults.patternSleeve
        patternIncreases = Self.defaults.patternIncreases
        shareButtonTitle = "Copy share link"
    }

    private func copyShareSummary() {
        UIPasteboard.general.string = shareSummary
        shareButtonTitle = "Copied!"
    }

    private var shareSummary: String {
        """
        Knitting Gauge Reconciler
        Pattern: \(formatPlain(inputs.patternStitches)) st x \(formatPlain(inputs.patternRows)) rows per 10cm
        Swatch: \(formatPlain(inputs.yourStitches)) st x \(formatPlain(inputs.yourRows)) rows per 10cm
        Cast on \(result.adjustedCastOn) stitches
        Yoke: knit to \(GaugeMath.fmtCm(result.adjustedYokeDepth)) cm
        Body: knit to \(GaugeMath.fmtCm(result.adjustedBodyLength)) cm
        Sleeve: knit to \(GaugeMath.fmtCm(result.adjustedSleeveLength)) cm
        Increases: space every \(GaugeMath.fmtRows(result.adjustedIncreaseSpacing)) rows
        """
    }
}

private struct GaugeTextDefaults {
    let patternStitches = "32"
    let patternRows = "24"
    let yourStitches = "32"
    let yourRows = "32"
    let patternCastOn = "128"
    let patternYoke = "20"
    let patternBody = "50"
    let patternSleeve = "45"
    let patternIncreases = "6"
}

private struct NumberField: View {
    var title: String
    @Binding var text: String
    var unit: String
    var hint: String? = nil
    var identifier: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.muted)
            TextField(title, text: $text)
                .keyboardType(.decimalPad)
                .font(.system(.title3, design: .monospaced).weight(.semibold))
                .frame(minHeight: 44)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(AppTheme.oatmeal)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(AppTheme.outline, lineWidth: 2)
                )
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .contentShape(Rectangle())
                .accessibilityIdentifier(identifier)
                .accessibilityLabel("\(title), \(spokenUnit)")
            Text(unit)
                .font(.caption)
                .foregroundStyle(AppTheme.muted)
            if let hint {
                Text(hint)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var spokenUnit: String {
        switch unit {
        case "st / 10 cm": "stitches per 10 centimetres"
        case "rows / 10 cm": "rows per 10 centimetres"
        case "cm": "centimetres"
        default: unit
        }
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
            .foregroundStyle(AppTheme.sage)
            .accessibilityAddTraits(.isHeader)
    }
}

private struct AdaptiveTwoColumnStack<Leading: View, Trailing: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var spacing: CGFloat = 12
    var minColumnWidth: CGFloat = 248
    @ViewBuilder var leading: () -> Leading
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        if shouldCollapse {
            vertical
        } else {
            ViewThatFits(in: .horizontal) {
                horizontal
                vertical
            }
        }
    }

    private var shouldCollapse: Bool {
        horizontalSizeClass == .compact || dynamicTypeSize.isAccessibilitySize
    }

    private var horizontal: some View {
        HStack(alignment: .top, spacing: spacing) {
            leading()
                .frame(minWidth: minColumnWidth, maxWidth: .infinity, alignment: .topLeading)
            trailing()
                .frame(minWidth: minColumnWidth, maxWidth: .infinity, alignment: .topLeading)
        }
    }

    private var vertical: some View {
        VStack(alignment: .leading, spacing: spacing) {
            leading()
                .frame(maxWidth: .infinity, alignment: .topLeading)
            trailing()
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
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
                .foregroundStyle(AppTheme.muted)
            Text(value)
                .font(.system(.largeTitle, design: .monospaced).weight(.bold))
                .minimumScaleFactor(0.7)
                .foregroundStyle(AppTheme.ink)
                .accessibilityIdentifier("\(identifier)-value")
            Text(status)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(pillBackground(status: status))
                .clipShape(Capsule())
            Text(detail)
                .font(.caption)
                .foregroundStyle(AppTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(AppTheme.oatmeal)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .accessibilityIdentifier(identifier)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(value), \(status)")
        .accessibilityHint(detail)
    }
    
    private func pillBackground(status: String) -> Color {
        if status == "Match" {
            return AppTheme.sage
        } else if status.hasPrefix("Much") {
            return AppTheme.terracotta
        }
        return AppTheme.secondary
    }
}

private struct AdjustmentRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var name: String
    var pattern: String
    var adjusted: String
    var adjustedIdentifier: String? = nil
    var driftPill: String? = nil

    var body: some View {
        Group {
            if shouldCollapse {
                vertical
            } else {
                ViewThatFits(in: .horizontal) {
                    horizontal
                    vertical
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var shouldCollapse: Bool {
        horizontalSizeClass == .compact || dynamicTypeSize.isAccessibilitySize
    }

    private var horizontal: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            labelBlock
                .frame(minWidth: 148, maxWidth: .infinity, alignment: .leading)
            valueBlock(alignment: .trailing)
                .frame(minWidth: 180, alignment: .trailing)
        }
    }

    private var vertical: some View {
        VStack(alignment: .leading, spacing: 8) {
            labelBlock
            valueBlock(alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var labelBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(name)
                .font(.body.weight(.semibold))
                .foregroundStyle(AppTheme.ink)
            Text("Pattern: \(pattern)")
                .font(.caption)
                .foregroundStyle(AppTheme.muted)
        }
    }

    private func valueBlock(alignment: TextAlignment) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(adjusted)
                .font(.system(.body, design: .monospaced).weight(.bold))
                .foregroundStyle(AppTheme.sage)
                .multilineTextAlignment(alignment)
                .accessibilityIdentifier(adjustedIdentifier ?? "adjustment-\(name.lowercased().replacingOccurrences(of: " ", with: "-"))-value")
            if let pill = driftPill {
                Text(pill)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppTheme.secondary)
                    .clipShape(Capsule())
            }
        }
    }
}

private extension View {
    func cardStyle() -> some View {
        padding()
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .shadow(color: AppTheme.sage.opacity(0.08), radius: 34, x: 0, y: 16)
    }
}

private enum AppTheme {
    static let background = Color(red: 0.99, green: 0.98, blue: 0.96)
    static let card = Color.white
    static let oatmeal = Color(red: 0.96, green: 0.95, blue: 0.93)
    static let accentSoft = Color(red: 0.94, green: 0.91, blue: 0.86)
    static let ink = Color(red: 0.11, green: 0.11, blue: 0.10)
    static let muted = Color(red: 0.27, green: 0.28, blue: 0.26)
    static let outline = Color(red: 0.77, green: 0.78, blue: 0.75)
    static let sage = Color(red: 0.27, green: 0.33, blue: 0.26)
    static let secondary = Color(red: 0.57, green: 0.29, blue: 0.18)
    static let terracotta = Color(red: 0.73, green: 0.10, blue: 0.10)
    static let tertiary = Color(red: 0.39, green: 0.29, blue: 0.32)
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
