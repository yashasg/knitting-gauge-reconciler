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
    @State private var showFullMath = false
    @State private var showVerdictHelp = false
    @State private var showAboutHelp = false
    @State private var sharePayload: SharePayload?

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
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $sharePayload) { payload in
                ActivityView(activityItems: payload.items)
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showVerdictHelp) {
                VerdictHelpSheet(title: verdictTitle, explanation: verdictBody)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showAboutHelp) {
                AboutHelpSheet()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 4) {
                Text("Knitting Gauge Reconciler")
                    .font(.system(.largeTitle, design: .serif).weight(.bold))
                    .foregroundStyle(AppTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    showAboutHelp = true
                } label: {
                    Image(systemName: "questionmark.circle")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AppTheme.sage)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("About this calculator, more information")
                .accessibilityHint("Opens an explanation of how this calculator works")
                .accessibilityIdentifier("about-help-button")
            }
            Text("Type your swatch. See every per-section adjustment — instantly.")
                .font(.body)
                .lineSpacing(3)
                .foregroundStyle(AppTheme.muted)
        }
    }

    private var gaugeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            GaugeInputGroup(title: "Pattern gauge (per 10 cm)") {
                GaugeMeasurementPair {
                    NumberField(
                        title: "Pattern stitches",
                        text: $patternStitches,
                        unit: "st / 10 cm",
                        identifier: "pattern-stitches",
                        fieldWidth: 88
                    )
                } trailing: {
                    NumberField(title: "Pattern rows", text: $patternRows, unit: "rows / 10 cm", identifier: "pattern-rows", fieldWidth: 88)
                }
            }

            GaugeInputGroup(title: "Your swatch (per 10 cm)") {
                GaugeMeasurementPair {
                    NumberField(
                        title: "Your stitches",
                        text: $yourStitches,
                        unit: "st / 10 cm",
                        hint: "measure on a blocked swatch",
                        identifier: "your-stitches",
                        fieldWidth: 88
                    )
                } trailing: {
                    NumberField(
                        title: "Your rows",
                        text: $yourRows,
                        unit: "rows / 10 cm",
                        hint: "same swatch, vertical count",
                        identifier: "your-rows",
                        fieldWidth: 88
                    )
                }
            }

            SectionTitle("Pattern instructions")
            NumberField(title: "Pattern cast-on", text: $patternCastOn, unit: "stitches", identifier: "pattern-cast-on", fieldWidth: 128)
            AdaptiveTwoColumnStack(minColumnWidth: 140) {
                NumberField(title: "Yoke depth", text: $patternYoke, unit: "cm", identifier: "pattern-yoke")
            } trailing: {
                NumberField(title: "Body length", text: $patternBody, unit: "cm", identifier: "pattern-body")
            }
            AdaptiveTwoColumnStack(minColumnWidth: 140) {
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
        HStack(alignment: .center, spacing: 8) {
            Text(verdictTitle)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.sage)
                .accessibilityLabel(verdictAccessibilityLabel)
            Spacer()
            Button {
                showVerdictHelp = true
            } label: {
                Image(systemName: "questionmark.circle")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.sage)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("More information")
            .accessibilityHint("Opens a description of this gauge verdict")
            .accessibilityIdentifier("verdict-help-button")
        }
        .padding(14)
        .background(AppTheme.accentSoft)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppTheme.sage, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityIdentifier("verdict-panel")
    }

    private var adjustmentsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle("Per-section adjustments")
            AdjustmentRow(
                name: "Yoke depth",
                pattern: sectionPatternDescription(cm: inputs.patternYokeDepth, rows: result.patternYokeRows),
                adjusted: sectionGuidance(cm: result.adjustedYokeDepth, rows: result.adjustedYokeRows)
            )
            AdjustmentRow(
                name: "Body length",
                pattern: sectionPatternDescription(cm: inputs.patternBodyLength, rows: result.patternBodyRows),
                adjusted: sectionGuidance(cm: result.adjustedBodyLength, rows: result.adjustedBodyRows)
            )
            AdjustmentRow(
                name: "Sleeve length",
                pattern: sectionPatternDescription(cm: inputs.patternSleeveLength, rows: result.patternSleeveRows),
                adjusted: sectionGuidance(cm: result.adjustedSleeveLength, rows: result.adjustedSleeveRows)
            )
            AdjustmentRow(name: "Increase-row spacing", pattern: "Every \(formatPlain(inputs.patternIncreaseSpacing)) rows", adjusted: "Space every \(GaugeMath.fmtRows(result.adjustedIncreaseSpacing)) rows/rounds")
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

            HStack(alignment: .center, spacing: 12) {
                Button("Reset to defaults", action: resetToDefaults)
                    .buttonStyle(.plain)
                    .frame(minWidth: 100, minHeight: 44)
                    .contentShape(Rectangle())
                    .accessibilityIdentifier("reset-defaults")
                Spacer()
                Button(action: shareResults) {
                    Label("Share results", systemImage: "square.and.arrow.up")
                        .labelStyle(.titleAndIcon)
                        .frame(minWidth: 100, minHeight: 44)
                        .contentShape(Rectangle())
                    }
                .buttonStyle(.plain)
                .accessibilityIdentifier("share-results")
                .accessibilityLabel("Share results")
                .accessibilityHint("Opens the share sheet with an image of the current results. Copy is available from the share sheet.")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppTheme.sage)
        }
        .cardStyle()
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
            return "Your stitch gauge matches — cast on \(result.adjustedCastOn) stitches as written. Your row gauge is \(rowPercent)% \(rowDir) than expected; keep the pattern's cm targets and use the row/round guidance for each vertical section.\(majorNote)"
        }
        return "Both axes are off: stitch gauge \(stitchPercent)% \(stitchDir), row gauge \(rowPercent)% \(rowDir). Cast on \(result.adjustedCastOn) stitches (not \(Int(inputs.patternCastOn))). Keep the pattern's cm targets and use the row/round guidance for vertical sections.\(majorNote)"
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
            return "Row gauge off \(rowPercent) percent. Cast on \(result.adjustedCastOn) stitches as written. Keep the pattern centimetre targets and check row or round guidance for vertical sections."
        }
        return "Both axes off. Cast on \(result.adjustedCastOn) instead of \(Int(inputs.patternCastOn)) stitches. Review section row or round guidance below."
    }

    private var fullMathBreakdown: String {
        """
        pattern: \(formatPlain(inputs.patternStitches)) st x \(formatPlain(inputs.patternRows)) rows per 10cm (aspect \(String(format: "%.2f", inputs.patternStitches / inputs.patternRows)))
        you:     \(formatPlain(inputs.yourStitches)) st x \(formatPlain(inputs.yourRows)) rows per 10cm (aspect \(String(format: "%.2f", inputs.yourStitches / inputs.yourRows)))
        stitch width scale = pattern_st / your_st = \(formatPlain(inputs.patternStitches)) / \(formatPlain(inputs.yourStitches)) = \(String(format: "%.3f", result.stitchWidthScale))
        row density ratio  = your_row / pattern_row = \(formatPlain(inputs.yourRows)) / \(formatPlain(inputs.patternRows)) = \(String(format: "%.3f", result.rowCountScale))
        section rows       = section_cm x rows_per_10cm / 10
        -> keep the pattern's vertical cm targets; row gauge changes row/round counts, not finished measurements
        -> yoke: \(formatPlain(inputs.patternYokeDepth)) cm = about \(GaugeMath.fmtRows(result.patternYokeRows)) pattern rows, about \(GaugeMath.fmtRows(result.adjustedYokeRows)) of your rows/rounds
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
    }

    @MainActor
    private func shareResults() {
        let summary = ResultsExportSummary(inputs: inputs, result: result)
        if let imageURL = renderShareImageURL(summary: summary) {
            sharePayload = SharePayload(items: [imageURL])
        } else {
            sharePayload = SharePayload(items: [ResultsShareTextFormatter.string(inputs: inputs, result: result)])
        }
    }

    @MainActor
    private func renderShareImageURL(summary: ResultsExportSummary) -> URL? {
        let card = ResultsShareCard(summary: summary)
            .frame(width: 1080)
            .background(AppTheme.background)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 2

        guard let image = renderer.uiImage, let pngData = image.pngData() else {
            return nil
        }

        do {
            let directory = try shareExportDirectory()
            let fileURL = directory.appendingPathComponent("knitting-gauge-results.png")
            try pngData.write(to: fileURL, options: [.atomic])
            return fileURL
        } catch {
            return nil
        }
    }

    private func shareExportDirectory() throws -> URL {
        let caches = try FileManager.default.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = caches.appendingPathComponent("ShareExports", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func sectionPatternDescription(cm: Double, rows: Double) -> String {
        "\(formatPlain(cm)) cm · about \(GaugeMath.fmtRows(rows)) pattern rows"
    }

    private func sectionGuidance(cm: Double, rows: Double) -> String {
        "Keep \(GaugeMath.fmtCm(cm)) cm · about \(GaugeMath.fmtRows(rows)) rows/rounds"
    }
}

private struct SharePayload: Identifiable {
    let id = UUID()
    var items: [Any]
}

private struct VerdictHelpSheet: View {
    var title: String
    var explanation: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.sage)
                    .accessibilityAddTraits(.isHeader)
                Text(explanation)
                    .font(.body)
                    .lineSpacing(4)
                    .foregroundStyle(AppTheme.ink)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .accessibilityIdentifier("verdict-help-sheet")
    }
}

private struct AboutHelpSheet: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("About this calculator")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.sage)
                    .accessibilityAddTraits(.isHeader)
                Text("This tool reconciles a two-axis gauge mismatch — the kind that single-number gauge calculators hide. When your stitch gauge matches the pattern but your row gauge is off (or vice versa), every vertical section ends up the wrong length unless you adjust the row counts.")
                    .font(.body)
                    .lineSpacing(4)
                    .foregroundStyle(AppTheme.ink)
                Text("The math is deterministic: section rows = section_cm × rows_per_10cm / 10. Row gauge changes row/round guidance, not the finished centimetre targets; stitch_scale = pattern_st / your_st describes horizontal width.")
                    .font(.body)
                    .lineSpacing(4)
                    .foregroundStyle(AppTheme.ink)
                Text("Scope: This tool provides estimates based on your swatch measurements. Always test a full-size gauge swatch (washed and blocked the way you'll wash and block the finished garment) before starting your project. Numbers here are a starting point — your finished piece is the final word.")
                    .font(.body.weight(.semibold))
                    .lineSpacing(4)
                    .foregroundStyle(Color(red: 0.35, green: 0.26, blue: 0.09))
                    .padding(14)
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
                    .lineSpacing(3)
                    .foregroundStyle(AppTheme.muted)
                    .accessibilityIdentifier("about-non-affiliation")
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .accessibilityIdentifier("about-help-sheet")
    }
}

private struct ActivityView: UIViewControllerRepresentable {
    var activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private struct ResultsShareCard: View {
    var summary: ResultsExportSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            VStack(alignment: .leading, spacing: 10) {
                Text(summary.title)
                    .font(.system(size: 54, weight: .bold, design: .serif))
                    .foregroundStyle(AppTheme.ink)
                Text("Gauge reconciliation results")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(AppTheme.muted)
            }

            HStack(alignment: .top, spacing: 24) {
                ShareGaugeBlock(title: "Pattern gauge", gauge: summary.patternGauge)
                ShareGaugeBlock(title: "Swatch gauge", gauge: summary.swatchGauge)
            }

            HStack(alignment: .top, spacing: 24) {
                ShareMetricBlock(metric: summary.stitchMetric)
                ShareMetricBlock(metric: summary.rowMetric)
            }

            Text(summary.castOn)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.sage)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(26)
                .background(AppTheme.accentSoft)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

            VStack(alignment: .leading, spacing: 18) {
                Text("Section row/round guidance")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(AppTheme.sage)
                ForEach(summary.sections, id: \.name) { section in
                    ShareSectionRow(section: section)
                }
            }
            .padding(26)
            .background(AppTheme.oatmeal)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
        .padding(52)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 44, style: .continuous))
        .padding(40)
    }
}

private struct ShareGaugeBlock: View {
    var title: String
    var gauge: ResultsExportSummary.GaugePair

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(AppTheme.sage)
            Text(gauge.stitches)
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
            Text(gauge.rows)
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(26)
        .background(AppTheme.oatmeal)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

private struct ShareMetricBlock: View {
    var metric: ResultsExportSummary.Metric

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(metric.title.uppercased())
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(AppTheme.muted)
            Text(metric.value)
                .font(.system(size: 58, weight: .bold, design: .monospaced))
                .foregroundStyle(AppTheme.ink)
            Text(metric.status)
                .font(.system(size: 23, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(sharePillBackground(metric.status))
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(26)
        .background(AppTheme.oatmeal)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

private struct ShareSectionRow: View {
    var section: ResultsExportSummary.SectionGuidance

    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text(section.name)
                    .font(.system(size: 27, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                Text(section.pattern)
                    .font(.system(size: 21, weight: .medium))
                    .foregroundStyle(AppTheme.muted)
            }
            Spacer(minLength: 20)
            Text(section.adjusted)
                .font(.system(size: 25, weight: .bold, design: .monospaced))
                .foregroundStyle(AppTheme.sage)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 8)
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

private struct GaugeInputGroup<Content: View>: View {
    var title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppTheme.outline.opacity(0.55), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct NumberField: View {
    var title: String
    @Binding var text: String
    var unit: String
    var hint: String? = nil
    var identifier: String
    var fieldWidth: CGFloat = 112

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.muted)
            TextField(title, text: $text)
                .keyboardType(.decimalPad)
                .font(.system(.title3, design: .monospaced).weight(.semibold))
                .frame(width: compactFieldWidth, alignment: .leading)
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
                    .frame(maxWidth: compactColumnWidth, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
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

    private var compactFieldWidth: CGFloat? {
        dynamicTypeSize.isAccessibilitySize ? nil : fieldWidth
    }

    private var compactColumnWidth: CGFloat? {
        dynamicTypeSize.isAccessibilitySize ? nil : fieldWidth + 28
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
        dynamicTypeSize.isAccessibilitySize
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

private struct GaugeMeasurementPair<Leading: View, Trailing: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var spacing: CGFloat = 12
    @ViewBuilder var leading: () -> Leading
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: spacing) {
                leading()
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                trailing()
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        } else {
            HStack(alignment: .top, spacing: spacing) {
                leading()
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                trailing()
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
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

private func sharePillBackground(_ status: String) -> Color {
    if status == "Match" {
        return AppTheme.sage
    } else if status.hasPrefix("Much") {
        return AppTheme.terracotta
    }
    return AppTheme.secondary
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
