import SwiftUI
import UIKit
import MetricKit
import os.signpost
// Components and Views are in separate files under Components/ and Views/

struct ContentView: View {
    private static let defaults = GaugeTextDefaults()

    // MARK: - State

    @State private var patternStitches = initialText("KGR_PS", defaultValue: "32")
    @State private var patternRows = initialText("KGR_PR", defaultValue: "24")
    @State private var yourStitches = initialText("KGR_YS", defaultValue: "32")
    @State private var yourRows = initialText("KGR_YR", defaultValue: "32")
    @State private var patternCastOn = initialText("KGR_CAST_ON", defaultValue: "128")
    @State private var patternYoke = initialText("KGR_YOKE", defaultValue: "20")
    @State private var patternBody = initialText("KGR_BODY", defaultValue: "50")
    @State private var patternSleeve = initialText("KGR_SLEEVE", defaultValue: "45")
    @State private var patternIncreases = initialText("KGR_INCREASES", defaultValue: "6")
    @State private var showFullMath = initialBool("KGR_SHOW_FULL_MATH")
    @State private var showVerdictHelp = initialBool("KGR_SHOW_VERDICT_HELP")
    @State private var showAboutHelp = initialBool("KGR_SHOW_ABOUT_HELP")
    @State private var sharePayload: SharePayload?
    @State private var previousVerdictBucket: VerdictBucket?
    @State private var driftBandSignpostFired = false
    /// nil until the user taps "Calculate Adjustments".
    @State private var cachedResult: GaugeMathResult?
    /// True after any input change following the first successful compute.
    @State private var isResultStale = false

    // MARK: - Derived

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

    /// Always-live result — used for the verdict help sheet so it has content
    /// even before the first Calculate tap. NOT used for the signpost-tracked
    /// verdictTitle (which only changes on Calculate).
    private var liveResult: GaugeMathResult {
        cachedResult ?? GaugeMath.compute(inputs)
    }

    private func recomputeResult() {
        os_signpost(.begin, log: MetricsSubscriber.log, name: SignpostNames.compute)
        cachedResult = GaugeMath.compute(inputs)
        os_signpost(.end, log: MetricsSubscriber.log, name: SignpostNames.compute)
        isResultStale = false
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HomeHeaderView(showAboutHelp: $showAboutHelp)
                    PatternGaugeCard(patternStitches: $patternStitches, patternRows: $patternRows)
                    YourGaugeCard(
                        yourStitches: $yourStitches,
                        yourRows: $yourRows,
                        stitchMismatch: inputs.stitchMismatch,
                        rowMismatch: inputs.rowMismatch
                    )
                    PatternInstructionsCard(
                        patternCastOn: $patternCastOn,
                        patternYoke: $patternYoke,
                        patternBody: $patternBody,
                        patternSleeve: $patternSleeve,
                        patternIncreases: $patternIncreases
                    )
                    RequiredAdjustmentsCard(
                        cachedResult: cachedResult,
                        isResultStale: isResultStale,
                        inputs: inputs,
                        showFullMath: $showFullMath,
                        onRecalculate: recomputeResult,
                        onReset: resetToDefaults,
                        onShare: { result in shareResults(result: result) }
                    )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
            }
            .background(
                ZStack {
                    AppTheme.background
                    TexturedBackground()
                }
                .ignoresSafeArea()
            )
            .toolbar(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder),
                            to: nil,
                            from: nil,
                            for: nil
                        )
                    }
                    .accessibilityIdentifier("keyboard-done")
                }
            }
            .sheet(item: $sharePayload) { payload in
                ActivityView(activityItems: payload.items)
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showVerdictHelp) {
                VerdictHelpSheet(title: sheetVerdictTitle, explanation: sheetVerdictBody)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showAboutHelp) {
                AboutHelpSheet()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .onChange(of: showVerdictHelp) { _, newValue in
                if newValue {
                    os_signpost(.event, log: MetricsSubscriber.log, name: SignpostNames.sheetVerdictHelpOpened)
                }
            }
            .onChange(of: showAboutHelp) { _, newValue in
                if newValue {
                    os_signpost(.event, log: MetricsSubscriber.log, name: SignpostNames.sheetAboutHelpOpened)
                }
            }
            // verdict.improved / verdict.degraded fire only when cachedResult changes (i.e. on
            // Calculate tap), because verdictTitle returns "" while cachedResult is nil.
            .onChange(of: verdictTitle) { _, newValue in
                let current = VerdictBucket(verdictTitle: newValue)
                if let decision = GaugeMathMetrics.classifyVerdictDelta(
                    previous: previousVerdictBucket,
                    current: current
                ) {
                    switch decision {
                    case .improved:
                        os_signpost(.event, log: MetricsSubscriber.log, name: SignpostNames.verdictImproved)
                    case .degraded:
                        os_signpost(.event, log: MetricsSubscriber.log, name: SignpostNames.verdictDegraded)
                    }
                }
                previousVerdictBucket = current
            }
            .onChange(of: cachedResult.map { abs($0.castOnRoundingDriftPercent) >= 3 } ?? false) { _, isVisible in
                if isVisible, !driftBandSignpostFired {
                    os_signpost(.event, log: MetricsSubscriber.log, name: SignpostNames.castOnDriftBandShown)
                    driftBandSignpostFired = true
                } else if !isVisible {
                    driftBandSignpostFired = false
                }
            }
            // Mark stale when inputs change AFTER a successful compute.
            // Does NOT recompute — that only happens on Calculate tap.
            .onChange(of: inputs) { _, _ in
                if cachedResult != nil {
                    isResultStale = true
                }
            }
        }
    }

    // MARK: - Verdict (signpost-only; derived from cachedResult so it changes only on Calculate tap)

    /// Returns "" when no result exists — prevents spurious signpost fires before first Calculate.
    private var verdictTitle: String {
        guard let result = cachedResult else { return "" }
        return verdictTitleComputed(result: result)
    }

    /// Live verdict for the help sheet — always has content, regardless of Calculate state.
    private var sheetVerdictTitle: String { verdictTitleComputed(result: liveResult) }
    private var sheetVerdictBody: String { verdictBodyComputed(result: liveResult) }

    private func verdictTitleComputed(result: GaugeMathResult) -> String {
        let stitchDrift = abs(result.stitchWidthScale - 1)
        let rowDrift = abs(result.rowCountScale - 1)
        if stitchDrift < 0.03, rowDrift < 0.03 { return "Gauge match" }
        if stitchDrift >= 0.15 || rowDrift >= 0.15 { return "Major mismatch" }
        let stitchOffRange = stitchDrift >= 0.03 && stitchDrift < 0.15
        let rowOffRange = rowDrift >= 0.03 && rowDrift < 0.15
        if stitchOffRange && rowOffRange { return "Significant drift" }
        return "Drift"
    }

    private func verdictBodyComputed(result: GaugeMathResult) -> String {
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
            return "Your stitch gauge matches — cast on \(result.adjustedCastOn) stitches as written. Your row gauge is \(rowPercent)% \(rowDir) than expected; use the row count guidance for each vertical section.\(majorNote)"
        }
        return "Both axes are off: stitch gauge \(stitchPercent)% \(stitchDir), row gauge \(rowPercent)% \(rowDir). Cast on \(result.adjustedCastOn) stitches (not \(Int(inputs.patternCastOn))) and use the row count guidance for vertical sections.\(majorNote)"
    }

    // MARK: - Actions

    private func resetToDefaults() {
        os_signpost(.event, log: MetricsSubscriber.log, name: SignpostNames.resetTapped)
        patternStitches = Self.defaults.patternStitches
        patternRows = Self.defaults.patternRows
        yourStitches = Self.defaults.yourStitches
        yourRows = Self.defaults.yourRows
        patternCastOn = Self.defaults.patternCastOn
        patternYoke = Self.defaults.patternYoke
        patternBody = Self.defaults.patternBody
        patternSleeve = Self.defaults.patternSleeve
        patternIncreases = Self.defaults.patternIncreases
        cachedResult = nil
        isResultStale = false
        // Reset previousVerdictBucket so no spurious signpost fires when verdictTitle
        // transitions "" → "" on next render after clearing cachedResult.
        previousVerdictBucket = nil
    }

    @MainActor
    private func shareResults(result: GaugeMathResult) {
        let summary = ResultsExportSummary(inputs: inputs, result: result)
        if let imageURL = renderShareImageURL(summary: summary) {
            os_signpost(.event, log: MetricsSubscriber.log, name: SignpostNames.shareInvoked)
            sharePayload = SharePayload(items: [imageURL])
        } else {
            os_signpost(.event, log: MetricsSubscriber.log, name: SignpostNames.shareFallback)
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
}

// MARK: - SharePayload

private struct SharePayload: Identifiable {
    let id = UUID()
    var items: [Any]
}

// MARK: - VerdictHelpSheet

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

// MARK: - AboutHelpSheet

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
                Text("The math is deterministic: dimension correction = pattern_row / your_row. A denser swatch means fewer centimetres are needed to reach the pattern's intended row count; stitch_scale = pattern_st / your_st describes horizontal width.")
                    .font(.body)
                    .lineSpacing(4)
                    .foregroundStyle(AppTheme.ink)
                Text("Scope: This tool provides estimates based on your swatch measurements. Always test a full-size gauge swatch (washed and blocked the way you'll wash and block the finished garment) before starting your project. Numbers here are a starting point — your finished piece is the final word.")
                    .font(.body.weight(.semibold))
                    .lineSpacing(4)
                    .foregroundStyle(AppTheme.warningText)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.warningBackground)
                    .overlay(alignment: .leading) {
                        Rectangle()
                            .frame(width: 3)
                            .foregroundStyle(AppTheme.warningAccent)
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

// MARK: - ActivityView

private struct ActivityView: UIViewControllerRepresentable {
    var activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - ResultsShareCard

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
                Text("Section adjustment guidance")
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

// MARK: - GaugeTextDefaults

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

// MARK: - Helpers

private func initialText(_ environmentKey: String, defaultValue: String) -> String {
    ProcessInfo.processInfo.environment[environmentKey] ?? defaultValue
}

private func initialBool(_ environmentKey: String) -> Bool {
    ProcessInfo.processInfo.environment[environmentKey] == "1"
}

private func read(_ text: String, defaultValue: Double) -> Double {
    GaugeMath.sanitized(Double(text), default: defaultValue)
}

private func sharePillBackground(_ status: String) -> Color {
    if status == "Match" {
        return AppTheme.sage
    } else if status.hasPrefix("Much") {
        return AppTheme.terracotta
    }
    return AppTheme.secondary
}
