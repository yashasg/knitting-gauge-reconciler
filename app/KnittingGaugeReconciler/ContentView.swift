import SwiftUI
import UIKit
import MetricKit
import os.signpost

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
                    header
                    patternGaugeCard
                    yourGaugeCard
                    patternInstructionsCard
                    requiredAdjustmentsCard
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

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: 4) {
            Text("Gauge Reconciler")
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
    }

    // MARK: - Pattern Gauge Card (unified-pill stepper fields)

    private var patternGaugeCard: some View {
        GaugeInputGroup(title: "Pattern Gauge", icon: "book.fill", showPerTag: true) {
            GaugeMeasurementPair {
                GaugeStepperField(
                    title: "Stitches",
                    text: $patternStitches,
                    unit: "st",
                    identifier: "pattern-stitches"
                )
            } trailing: {
                GaugeStepperField(
                    title: "Rows",
                    text: $patternRows,
                    unit: "ro",
                    identifier: "pattern-rows"
                )
            }
        }
    }

    // MARK: - Your Gauge Card (unified-pill stepper fields + live mismatch helpers)

    private var yourGaugeCard: some View {
        GaugeInputGroup(title: "Your Gauge", icon: "ruler.fill", showPerTag: true) {
            GaugeMeasurementPair {
                GaugeStepperField(
                    title: "Stitches",
                    text: $yourStitches,
                    unit: "st",
                    identifier: "your-stitches",
                    hasMismatch: inputs.stitchMismatch,
                    mismatchLabel: "Stitch gauge mismatch detected"
                )
            } trailing: {
                GaugeStepperField(
                    title: "Rows",
                    text: $yourRows,
                    unit: "ro",
                    identifier: "your-rows",
                    hasMismatch: inputs.rowMismatch,
                    mismatchLabel: "Row gauge mismatch detected"
                )
            }
        }
    }

    // MARK: - Pattern Instructions Card (always visible)

    private var patternInstructionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
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

    // MARK: - Required Adjustments Card (always visible)

    private var requiredAdjustmentsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header row: title + in-header calculate/recalculate button
            HStack(alignment: .center, spacing: 12) {
                Text("Required\nAdjustments")
                    .font(.system(.largeTitle, design: .serif).weight(.bold))
                    .foregroundStyle(AppTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button {
                    recomputeResult()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: isResultStale ? "arrow.clockwise" : "wand.and.stars")
                            .font(.footnote.weight(.semibold))
                        Text(cachedResult == nil ? "Calculate" : "Recalculate")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(AppTheme.cream)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        // Full color when: never calculated, or stale (action needed).
                        // Subdued when fresh — results visible, no action required.
                        (cachedResult != nil && !isResultStale)
                            ? AppTheme.sage.opacity(0.5)
                            : AppTheme.sage
                    )
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("calculate-button")
                .accessibilityLabel(cachedResult == nil ? "Calculate Adjustments" : "Recalculate Adjustments")
                .accessibilityHint("Computes gauge reconciliation adjustments for your pattern")
            }

            if let result = cachedResult {
                // Results — dimmed when stale to signal a Recalculate tap is needed.
                Group {
                    // ① Yoke Depth
                    numberedSectionCard(number: 1, title: "Yoke Depth", subtitle: "To hit target measurement") {
                        AdjustmentValuePair(
                            patternValue: GaugeMath.fmtRows(result.patternYokeRows),
                            yourValue: result.yokeRowsAtYourGauge,
                            valueIdentifier: "yoke-your-rows"
                        )
                    }

                    // ② Body & Sleeves
                    numberedSectionCard(number: 2, title: "Body & Sleeves", subtitle: "Length Correction") {
                        VStack(spacing: 12) {
                            AdjustmentValuePair(
                                patternValue: GaugeMath.fmtRows(result.patternBodyRows),
                                yourValue: result.bodyRowsAtYourGauge,
                                patternLabel: "Body Rows",
                                valueIdentifier: "body-your-rows"
                            )
                            AdjustmentValuePair(
                                patternValue: GaugeMath.fmtRows(result.patternSleeveRows),
                                yourValue: result.sleeveRowsAtYourGauge,
                                patternLabel: "Sleeve Rows",
                                valueIdentifier: "sleeve-your-rows"
                            )
                        }
                    }

                    // ③ Shaping Rates
                    numberedSectionCard(number: 3, title: "Shaping Rates", subtitle: "Increases / Decreases") {
                        VStack(spacing: 8) {
                            AdjustmentRow(
                                name: "Increase-row spacing",
                                pattern: "Every \(plain(inputs.patternIncreaseSpacing)) rows",
                                adjusted: "Space every \(GaugeMath.fmtRows(result.adjustedIncreaseSpacing)) rows/rounds"
                            )
                            AdjustmentRow(
                                name: "Cast-on stitches",
                                pattern: "\(plain(inputs.patternCastOn)) stitches",
                                adjusted: "Cast on \(result.adjustedCastOn) stitches",
                                adjustedIdentifier: "cast-on-result",
                                driftPill: abs(result.castOnRoundingDriftPercent) >= 3
                                    ? String(format: "%+.0f%% width", result.castOnRoundingDriftPercent)
                                    : nil
                            )
                        }
                    }

                    actionsCard(result: result)
                }
                // Dim stale results to signal they need a Recalculate tap.
                .opacity(isResultStale ? 0.6 : 1.0)
            } else {
                // Pre-calculate placeholder — shown until the first Calculate tap.
                Text("Enter your gauge above and tap Calculate to see your adjustments.")
                    .font(.body)
                    .foregroundStyle(AppTheme.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
                    .accessibilityIdentifier("adjustments-placeholder")
            }
        }
    }

    @ViewBuilder
    private func numberedSectionCard<Content: View>(
        number: Int,
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 10) {
                StepCircle(number: number)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(AppTheme.ink)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AppTheme.muted)
                }
            }
            content()
        }
        .cardStyle()
    }

    // MARK: - Actions Card (full math, share, reset)

    @ViewBuilder
    private func actionsCard(result: GaugeMathResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
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
            .accessibilityIdentifier("disclosure-full-math")
            .accessibilityLabel("Show full math")

            if showFullMath {
                Text(fullMathBreakdown(result: result))
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
                Button(action: { shareResults(result: result) }) {
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

    // MARK: - Full math breakdown

    private func fullMathBreakdown(result: GaugeMathResult) -> String {
        """
        pattern: \(plain(inputs.patternStitches)) st x \(plain(inputs.patternRows)) rows per 10cm (aspect \(String(format: "%.2f", inputs.patternStitches / inputs.patternRows)))
        you:     \(plain(inputs.yourStitches)) st x \(plain(inputs.yourRows)) rows per 10cm (aspect \(String(format: "%.2f", inputs.yourStitches / inputs.yourRows)))
        stitch width scale = pattern_st / your_st = \(plain(inputs.patternStitches)) / \(plain(inputs.yourStitches)) = \(String(format: "%.3f", result.stitchWidthScale))
        row density ratio  = your_row / pattern_row = \(plain(inputs.yourRows)) / \(plain(inputs.patternRows)) = \(String(format: "%.3f", result.rowCountScale))
        dim correction     = pattern_row / your_row = \(plain(inputs.patternRows)) / \(plain(inputs.yourRows)) = \(String(format: "%.3f", result.dimensionScale))
        -> section rows at your gauge = (cm / 10) x your_rows:
        -> yoke: \(plain(inputs.patternYokeDepth)) cm → knit \(result.yokeRowsAtYourGauge) rows
        -> body: \(plain(inputs.patternBodyLength)) cm → knit \(result.bodyRowsAtYourGauge) rows
        -> for any horizontal dim, your stitch count produces \(String(format: "%.1f", result.stitchWidthScale * 100))% of the pattern's intended width
        cast-on adjust = your_st / pattern_st x patCastOn = \(plain(inputs.yourStitches))/\(plain(inputs.patternStitches)) x \(plain(inputs.patternCastOn)) = \(result.adjustedCastOn) stitches
        """
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

// MARK: - TexturedBackground
// Canvas-based dot grid that renders behind all cards. Spacing and dot size are
// tuned to look like cross-stitch fabric without being noisy. Color is
// AppTheme.surfaceTextureDot (muted at 30% opacity).

private struct TexturedBackground: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 14
            let dotRadius: CGFloat = 1.2
            let cols = Int(size.width / spacing) + 2
            let rows = Int(size.height / spacing) + 2
            for row in 0...rows {
                for col in 0...cols {
                    let x = CGFloat(col) * spacing
                    let y = CGFloat(row) * spacing
                    let rect = CGRect(
                        x: x - dotRadius, y: y - dotRadius,
                        width: dotRadius * 2, height: dotRadius * 2
                    )
                    context.fill(Path(ellipseIn: rect), with: .color(AppTheme.surfaceTextureDot))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
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

// MARK: - GaugeInputGroup
// Each gauge card is its own raised tile via .cardStyle(). Icons and PER tag
// are in the header row.

private struct GaugeInputGroup<Content: View>: View {
    var title: String
    var icon: String? = nil
    var showPerTag: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AppTheme.secondary)
                }
                Text(title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppTheme.ink)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                if showPerTag {
                    Text("PER 10CM / 4\"")
                        .font(.caption2.weight(.bold))
                        .tracking(0.5)
                        .foregroundStyle(AppTheme.muted)
                }
            }
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

// MARK: - GaugeStepperField
// Unified capsule: [−  value  +] — one pill, no separate button backgrounds.
// The minus/plus icons sit inside the same capsule as the value; tapping the
// value opens the number pad for direct keyboard entry.
// Unit suffix intentionally omitted — labels above each field communicate units.

private struct GaugeStepperField: View {
    var title: String
    @Binding var text: String
    var unit: String
    var identifier: String
    var hasMismatch: Bool = false
    var mismatchLabel: String? = nil

    private static let range = 1...99

    private var currentValue: Int {
        if let i = Int(text) { return i }
        if let d = Double(text) { return Int(d.rounded()) }
        return 20
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.muted)

            HStack(spacing: 0) {
                Button {
                    text = "\(max(Self.range.lowerBound, currentValue - 1))"
                } label: {
                    Image(systemName: "minus")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppTheme.ink)
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Decrease \(title)")
                .accessibilityIdentifier("\(identifier)-minus")

                Spacer()

                TextField("", text: $text)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(hasMismatch ? AppTheme.mismatchText : AppTheme.ink)
                    .fixedSize()
                    .frame(minWidth: 44)
                    .accessibilityIdentifier("\(identifier)-field")

                Spacer()

                Button {
                    text = "\(min(Self.range.upperBound, currentValue + 1))"
                } label: {
                    Image(systemName: "plus")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppTheme.ink)
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Increase \(title)")
                .accessibilityIdentifier(identifier)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .frame(minHeight: 44)
            .background(AppTheme.oatmeal)
            .clipShape(Capsule())

            if let mismatchLabel, hasMismatch {
                Text(mismatchLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AppTheme.mismatchText)
                    .accessibilityIdentifier("\(identifier)-mismatch")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - AdjustmentValuePair
// Left block: pattern value on cream background (informational).
// Right block: your value on dark-green background (actionable).
// Delta badge floats top-right of the green block; hidden when delta == 0.

private struct AdjustmentValuePair: View {
    var patternValue: Int
    var yourValue: Int
    var patternLabel: String = "Pattern Rows"
    var yourLabel: String = "You Must Knit"
    var valueIdentifier: String? = nil

    private var delta: Int { yourValue - patternValue }

    var body: some View {
        HStack(spacing: 10) {
            // Left: pattern rows (low-contrast, informational)
            VStack(alignment: .center, spacing: 4) {
                Text(patternLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.muted)
                    .multilineTextAlignment(.center)
                Text("\(patternValue)")
                    .font(.system(.title, design: .monospaced).weight(.bold))
                    .foregroundStyle(AppTheme.muted)
            }
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(AppTheme.oatmeal)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            // Right: your rows (high-contrast, actionable)
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .center, spacing: 4) {
                    Text(yourLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                    Text("\(yourValue)")
                        .font(.system(.title, design: .monospaced).weight(.bold))
                        .foregroundStyle(.white)
                        .accessibilityIdentifier(valueIdentifier ?? "adjustment-value-your")
                }
                .frame(maxWidth: .infinity)
                .padding(14)
                .padding(.top, delta != 0 ? 8 : 0)
                .background(AppTheme.sage)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                if delta != 0 {
                    Text(delta > 0 ? "+\(delta)" : "\(delta)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.secondary)
                        .clipShape(Capsule())
                        .offset(x: -4, y: -8)
                }
            }
        }
    }
}

// MARK: - StepCircle

private struct StepCircle: View {
    var number: Int

    var body: some View {
        ZStack {
            Circle()
                .fill(AppTheme.secondary)
            Text("\(number)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
        }
        .frame(width: 24, height: 24)
        .accessibilityHidden(true)
    }
}

// MARK: - NumberField (plain pill — used for pattern gauge + pattern instruction inputs)

private struct NumberField: View {
    var title: String
    @Binding var text: String
    var unit: String
    var hint: String? = nil
    var identifier: String
    var fieldWidth: CGFloat = 112
    var inlineUnit: Bool = false

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.muted)
            fieldView
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
            if !inlineUnit {
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted)
            }
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

    @ViewBuilder
    private var fieldView: some View {
        if inlineUnit {
            HStack(spacing: 6) {
                TextField(title, text: $text)
                    .keyboardType(.decimalPad)
                    .font(.system(.title3, design: .monospaced).weight(.semibold))
                Text(unit)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.muted)
                    .fixedSize()
                    .accessibilityHidden(true)
            }
        } else {
            TextField(title, text: $text)
                .keyboardType(.decimalPad)
                .font(.system(.title3, design: .monospaced).weight(.semibold))
        }
    }

    private var spokenUnit: String {
        switch unit {
        case "st / 10 cm": "stitches per 10 centimetres"
        case "rows / 10 cm": "rows per 10 centimetres"
        case "st": "stitches per 10 centimetres"
        case "ro": "rows per 10 centimetres"
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

// MARK: - SectionTitle

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

// MARK: - AdaptiveTwoColumnStack

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

// MARK: - GaugeMeasurementPair

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

// MARK: - AdjustmentRow (used inside ③ Shaping Rates)

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

// MARK: - cardStyle

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

// MARK: - AppTheme

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
    static let warningText = Color(red: 0.35, green: 0.26, blue: 0.09)
    static let warningBackground = Color(red: 0.96, green: 0.94, blue: 0.87)
    static let warningAccent = Color(red: 0.78, green: 0.55, blue: 0.17)
    /// Red for inline gauge mismatch indicators. Semantically "this IS different
    /// from the pattern" — distinct from warningText (warm amber, "might be wrong").
    static let mismatchText = Color(red: 0.73, green: 0.10, blue: 0.10)
    /// Cream text for use on dark backgrounds (e.g. the Calculate CTA button).
    static let cream = Color(red: 0.97, green: 0.96, blue: 0.92)
    /// Dot color for the TexturedBackground canvas. Muted at 30% opacity gives
    /// the subtle cross-stitch fabric look without visual noise.
    static let surfaceTextureDot = Color(red: 0.27, green: 0.28, blue: 0.26).opacity(0.30)
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
