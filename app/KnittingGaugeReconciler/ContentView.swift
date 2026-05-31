// swiftlint:disable file_length
import SwiftUI
import UIKit
import MetricKit
import os.signpost
// Components and Views are in separate files under Components/ and Views/

// swiftlint:disable:next type_body_length
struct ContentView: View {
    private static let defaults = GaugeTextDefaults()

    // MARK: - Adaptive layout

    @ScaledMetric(relativeTo: .body) private var cardSpacing: CGFloat = 12

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
    @State private var showAdjustmentSheet = false
    @State private var showResetConfirmation = false
    @State private var previousVerdictBucket: VerdictBucket?
    @State private var driftBandSignpostFired = false
    /// Latest result presented from a "View Adjustments" tap.
    @State private var cachedResult: GaugeMathResult?

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
    /// even before the first View Adjustments tap. NOT used for the signpost-tracked
    /// verdictTitle (which only changes on sheet presentation).
    private var liveResult: GaugeMathResult {
        cachedResult ?? GaugeMath.compute(inputs)
    }

    private func recomputeResult() {
        os_signpost(.begin, log: MetricsSubscriber.log, name: SignpostNames.compute)
        cachedResult = GaugeMath.compute(inputs)
        os_signpost(.end, log: MetricsSubscriber.log, name: SignpostNames.compute)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: cardSpacing) {
                    PatternGaugeCard(patternStitches: $patternStitches, patternRows: $patternRows)
                    YourGaugeCard(
                        yourStitches: $yourStitches,
                        yourRows: $yourRows,
                        stitchMismatch: inputs.stitchMismatch,
                        rowMismatch: inputs.rowMismatch,
                        stitchDelta: Int(inputs.patternStitches - inputs.yourStitches),
                        rowDelta: Int(inputs.patternRows - inputs.yourRows)
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
                        inputs: inputs,
                        showFullMath: $showFullMath,
                        showAdjustmentSheet: $showAdjustmentSheet,
                        onRecalculate: recomputeResult,
                        onReset: { showResetConfirmation = true },
                        onShare: { result in await shareItems(for: result) }
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
            // While a help sheet is presented, the underlying view is still rendered
            // (dimmed) behind the sheet. Apple's accessibility audit traverses every
            // visible element — including bare body paragraphs that legitimately
            // render in full width. Mark the main content inert to a11y while a
            // *help* sheet is up so the audit focuses on the sheet itself.
            //
            // The Adjustment sheet is deliberately NOT included here: doing so makes
            // SwiftUI propagate the hidden state into the sheet's own accessibility
            // tree on some iOS versions, which hides the sheet's "Close" button
            // from XCUITest queries (regression caught by
            // testAllJacquardScenariosAreVisibleInUI). The audit's element filter
            // already handles parent stepper-shim and pill noise that surfaces
            // behind the Adjustment sheet.
            .accessibilityHidden(showVerdictHelp || showAboutHelp)
            .navigationTitle("Stitchwise")
            .background(
                ZStack {
                    AppTheme.background
                    TexturedBackground()
                }
                .ignoresSafeArea()
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    AboutHelpToolbarButton(showAboutHelp: $showAboutHelp)
                }
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
            // Reset confirmation lives at ContentView root (not inside the
            // Adjustment sheet's NavigationStack) so it presents above the sheet
            // without dismissing it. See issue #40.
            .alert(
                "Reset to defaults?",
                isPresented: $showResetConfirmation
            ) {
                Button("Reset", role: .destructive) {
                    resetToDefaults()
                    showAdjustmentSheet = false
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Clears every stitch and row value you've entered.")
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
            // View Adjustments tap), because verdictTitle returns "" while cachedResult is nil.
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
        }
    }

    // MARK: - Verdict (signpost-only; derived from cachedResult so it changes only on sheet presentation)

    /// Returns "" when no result exists — prevents spurious signpost fires before first sheet presentation.
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
            ? " Over 15% drift. Consider re-swatching or changing needle size before proceeding."
            : ""
        if !stitchOff && !rowOff {
            return "Both gauges match. Cast on \(result.adjustedCastOn) stitches as written. " +
                "Knit straight from the pattern. No adjustments needed. Re-check after blocking."
        }
        if stitchOff && !rowOff {
            return (
                "Your row gauge matches, but your stitch gauge is \(stitchPercent)% \(stitchDir). " +
                "Cast on \(result.adjustedCastOn) stitches instead of the pattern's \(Int(inputs.patternCastOn)) " +
                "to hit the same width. Vertical sections need no adjustment.\(majorNote)"
            )
        }
        if !stitchOff {
            return (
                "Your stitch gauge matches. Cast on \(result.adjustedCastOn) stitches as written. " +
                "Your row gauge is \(rowPercent)% \(rowDir) than expected; use the row count guidance " +
                "for each vertical section.\(majorNote)"
            )
        }
        return (
            "Both axes are off: stitch gauge \(stitchPercent)% \(stitchDir), row gauge \(rowPercent)% \(rowDir). " +
            "Cast on \(result.adjustedCastOn) stitches (not \(Int(inputs.patternCastOn))) and use the row count " +
            "guidance for vertical sections.\(majorNote)"
        )
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
        // Reset previousVerdictBucket so no spurious signpost fires when verdictTitle
        // transitions "" → "" on next render after clearing cachedResult.
        previousVerdictBucket = nil
    }

    @MainActor
    private func shareItems(for result: GaugeMathResult) async -> [Any] {
        let summary = ResultsExportSummary(inputs: inputs, result: result)
        if let imageURL = await renderShareImageURL(summary: summary) {
            os_signpost(.event, log: MetricsSubscriber.log, name: SignpostNames.shareInvoked)
            return [imageURL]
        }

        os_signpost(.event, log: MetricsSubscriber.log, name: SignpostNames.shareFallback)
        return [ResultsShareTextFormatter.string(inputs: inputs, result: result)]
    }

    /// Rasterizes the share card on the MainActor (ImageRenderer requirement), then
    /// encodes to PNG on the MainActor and offloads the file write to a detached task
    /// so the main thread is never blocked by disk I/O.
    @MainActor
    private func renderShareImageURL(summary: ResultsExportSummary) async -> URL? {
        let renderer = ImageRenderer(content: ShareableView(summary: summary))
        renderer.proposedSize = .init(width: 390, height: nil)
        renderer.scale = 3

        // ImageRenderer.uiImage must be accessed on the MainActor.
        // pngData() is kept here too — do NOT capture UIImage across the detached boundary.
        guard let image = renderer.uiImage, let pngData = image.pngData() else {
            return nil
        }

        // Offload only the disk write; Data and URL are Sendable.
        return await Task.detached(priority: .userInitiated) {
            do {
                let caches = try FileManager.default.url(
                    for: .cachesDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: true
                )
                let directory = caches.appendingPathComponent("ShareExports", isDirectory: true)
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                let fileURL = directory.appendingPathComponent("knitting-gauge-results.png")
                try pngData.write(to: fileURL, options: [.atomic])
                return fileURL
            } catch {
                return nil as URL?
            }
        }.value
    }
}

// MARK: - VerdictHelpSheet

private struct VerdictHelpSheet: View {
    var title: String
    var explanation: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HelpSheetHeader(closeIdentifier: "verdict-help-close") { dismiss() }
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(AppTheme.sage)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    Text(explanation)
                        .font(.body)
                        .lineSpacing(4)
                        .foregroundStyle(AppTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityIdentifier("verdict-help-sheet")
        }
        .background(AppTheme.background.ignoresSafeArea())
    }
}

// MARK: - AboutHelpSheet

private struct AboutHelpSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HelpSheetHeader(closeIdentifier: "about-help-close") { dismiss() }
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("About this calculator")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(AppTheme.sage)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    Text(
                        "This tool reconciles a two-axis gauge mismatch, " +
                        "the kind that single-number gauge calculators hide. " +
                        "When your stitch gauge matches the pattern " +
                        "but your row gauge is off (or vice versa), every vertical " +
                        "section ends up the wrong length unless you adjust the row counts."
                    )
                        .font(.body)
                        .lineSpacing(4)
                        .foregroundStyle(AppTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(
                        "The math is deterministic: dimension correction = pattern_row / your_row. " +
                        "A denser swatch means fewer " +
                        "centimetres are needed to reach the pattern's intended row count; " +
                        "stitch_scale = pattern_st / your_st " +
                        "describes horizontal width."
                    )
                        .font(.body)
                        .lineSpacing(4)
                        .foregroundStyle(AppTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(
                        "Scope: This tool provides estimates based on your swatch measurements. " +
                        "Always test a full-size gauge " +
                        "swatch (washed and blocked the way you'll wash and block the finished garment) " +
                        "before starting your " +
                        "project. Numbers here are a starting point; your finished piece is the final word."
                    )
                        .font(.body.weight(.semibold))
                        .lineSpacing(4)
                        .foregroundStyle(AppTheme.warningText)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.warningBackground)
                        .overlay(alignment: .leading) {
                            Rectangle()
                                .frame(width: 3)
                                .foregroundStyle(AppTheme.warningAccent)
                                .accessibilityHidden(true)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .accessibilityIdentifier("about-scope")
                    Text(
                        "Not affiliated with Ravelry, Knit Companion, or any pattern designer." +
                        " Gauge math is conventional knitting arithmetic from open craft literature."
                    )
                        .font(.footnote.italic())
                        .lineSpacing(3)
                        .foregroundStyle(AppTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("about-non-affiliation")
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityIdentifier("about-help-sheet")
        }
        .background(AppTheme.background.ignoresSafeArea())
    }
}

// MARK: - HelpSheetHeader

/// Custom drag-handle-friendly header for help sheets. Avoids the
/// NavigationStack-in-sheet anti-pattern (#24) while providing a 44×44pt
/// trailing Close button (#25) so VoiceOver users can dismiss the sheet
/// without relying on the drag indicator.
private struct HelpSheetHeader: View {
    let closeIdentifier: String
    let onClose: () -> Void

    var body: some View {
        HStack {
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .imageScale(.medium)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppTheme.sage)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Close")
            .accessibilityIdentifier(closeIdentifier)
        }
        .padding(.horizontal, 8)
        .padding(.top, 4)
    }
}
