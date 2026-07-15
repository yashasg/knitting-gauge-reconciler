// Issue #65 keeps conditional result, reset, and share UI in this existing authorized file.
// swiftlint:disable file_length
import SwiftUI

struct RequiredAdjustmentsCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @Binding private var showFullMath: Bool
    @Binding private var showAdjustmentSheet: Bool
    @State private var selectedDetent: PresentationDetent = .medium
    @State private var showResetConfirmation = false

    private let cachedResult: GaugeMathResult?
    private let inputs: GaugeInputs?
    private let unit: MeasurementUnit
    private let canUndoReset: Bool
    private let onRecalculate: () -> GaugeMathResult?
    private let onReset: () -> Void
    private let onUndoReset: () -> Void
    private let onShare: (GaugeMathResult) async -> [Any]

    init(
        cachedResult: GaugeMathResult?,
        inputs: GaugeInputs?,
        unit: MeasurementUnit,
        showFullMath: Binding<Bool>,
        showAdjustmentSheet: Binding<Bool>,
        canUndoReset: Bool,
        onRecalculate: @escaping () -> GaugeMathResult?,
        onReset: @escaping () -> Void,
        onUndoReset: @escaping () -> Void,
        onShare: @escaping (GaugeMathResult) async -> [Any]
    ) {
        self.cachedResult = cachedResult
        self.inputs = inputs
        self.unit = unit
        self._showFullMath = showFullMath
        self._showAdjustmentSheet = showAdjustmentSheet
        self.canUndoReset = canUndoReset
        self.onRecalculate = onRecalculate
        self.onReset = onReset
        self.onUndoReset = onUndoReset
        self.onShare = onShare
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                selectedDetent = dynamicTypeSize.isAccessibilitySize ? .large : .medium
                if onRecalculate() != nil {
                    showAdjustmentSheet = true
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "wand.and.stars")
                        .font(.footnote.weight(.semibold))
                        .accessibilityHidden(true)
                    Text("View results")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(AppTheme.cream)
                .frame(minWidth: 176)
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 8)
                .frame(minHeight: 44)
                .background(inputs == nil ? AppTheme.muted : AppTheme.sage)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .center)
            .disabled(inputs == nil)
            .accessibilityIdentifier("calculate-button")
            .accessibilityLabel("View results")
            .accessibilityHint(
                inputs == nil
                    ? "Correct the highlighted fields before viewing results"
                    : "Computes gauge reconciliation and opens the results sheet"
            )

            if inputs == nil {
                Text("Correct the highlighted fields to view results.")
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .accessibilityIdentifier("form-validation-summary")
            }

            HStack(alignment: .center, spacing: 16) {
                Button("Reset values") {
                    showResetConfirmation = true
                }
                .buttonStyle(.plain)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.ink)
                .accessibilityIdentifier("reset-defaults")
                .accessibilityHint("Opens a confirmation before replacing every entry")
                .accessibilityHidden(showAdjustmentSheet)

                if canUndoReset {
                    Spacer()
                    Button("Undo reset", action: onUndoReset)
                        .buttonStyle(.plain)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .accessibilityIdentifier("undo-reset")
                        .accessibilityHint("Restores every value from before the last reset")
                }
            }
        }
        .sheet(isPresented: $showAdjustmentSheet) {
            if let cachedResult, let inputs {
                AdjustmentSheetView(
                    result: cachedResult,
                    inputs: inputs,
                    unit: unit,
                    showFullMath: $showFullMath,
                    onShare: onShare,
                    onClose: { showAdjustmentSheet = false }
                )
                .presentationDetents([.medium, .large], selection: $selectedDetent)
                .presentationDragIndicator(.visible)
            }
        }
        .alert("Reset all values?", isPresented: $showResetConfirmation) {
            Button("Reset values", role: .destructive, action: onReset)
            Button("Keep editing", role: .cancel) {}
        } message: {
            Text("This replaces every entry with the sample gauge values.")
        }
    }
}

private struct AdjustmentSheetView: View {
    @State private var sharePayload: ShareSheetPayload?
    @State private var isPreparingShare = false

    private let result: GaugeMathResult
    private let inputs: GaugeInputs
    private let unit: MeasurementUnit
    @Binding private var showFullMath: Bool
    private let onShare: (GaugeMathResult) async -> [Any]
    private let onClose: () -> Void

    init(
        result: GaugeMathResult,
        inputs: GaugeInputs,
        unit: MeasurementUnit,
        showFullMath: Binding<Bool>,
        onShare: @escaping (GaugeMathResult) async -> [Any],
        onClose: @escaping () -> Void
    ) {
        self.result = result
        self.inputs = inputs
        self.unit = unit
        self._showFullMath = showFullMath
        self.onShare = onShare
        self.onClose = onClose
    }

    var body: some View {
        VStack(spacing: 0) {
            AdjustmentSheetHeader(
                isPreparingShare: isPreparingShare,
                onShare: {
                    guard !isPreparingShare else { return }
                    isPreparingShare = true
                },
                onClose: onClose
            )
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    gaugeSummaryCard

                    if let patternRows = result.patternYokeRows,
                       let adjustedRows = result.yokeRowsAtYourGauge {
                        sectionCard(title: "Yoke Depth", subtitle: "To hit target measurement") {
                            AdjustmentValuePair(
                                patternValue: GaugeMath.fmtRows(patternRows),
                                yourValue: adjustedRows,
                                valueIdentifier: "yoke-your-rows"
                            )
                        }
                    }

                    if hasBodyOrSleeveGuidance {
                        sectionCard(title: "Body & Sleeves", subtitle: "Length correction") {
                            VStack(spacing: 12) {
                                if let patternRows = result.patternBodyRows,
                                   let adjustedRows = result.bodyRowsAtYourGauge {
                                    AdjustmentValuePair(
                                        patternValue: GaugeMath.fmtRows(patternRows),
                                        yourValue: adjustedRows,
                                        patternLabel: "Body Rows",
                                        valueIdentifier: "body-your-rows"
                                    )
                                }
                                if let patternRows = result.patternSleeveRows,
                                   let adjustedRows = result.sleeveRowsAtYourGauge {
                                    AdjustmentValuePair(
                                        patternValue: GaugeMath.fmtRows(patternRows),
                                        yourValue: adjustedRows,
                                        patternLabel: "Sleeve Rows",
                                        valueIdentifier: "sleeve-your-rows"
                                    )
                                }
                            }
                        }
                    }

                    if let patternSpacing = inputs.patternIncreaseSpacing,
                       let adjustedSpacing = result.adjustedIncreaseSpacing {
                        sectionCard(title: "Shaping Rates", subtitle: "Increases / decreases") {
                            AdjustmentRow(
                                name: "Increase-row spacing",
                                pattern: "Every \(plain(patternSpacing)) rows",
                                adjusted: "Every \(GaugeMath.fmtRows(adjustedSpacing)) rows",
                                adjustedIdentifier: "increases-result"
                            )
                        }
                    }

                    if let patternCastOn = inputs.patternCastOn,
                       let adjustedCastOn = result.adjustedCastOn {
                        sectionCard(title: "Cast-on", subtitle: "To preserve pattern width") {
                            AdjustmentRow(
                                name: "Cast-on stitches",
                                pattern: "\(plain(patternCastOn)) stitches",
                                adjusted: "\(adjustedCastOn) stitches",
                                adjustedIdentifier: "cast-on-result",
                                driftPill: castOnDriftPill
                            )
                        }
                    }

                    actionsCard
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background.ignoresSafeArea())
        .sheet(item: $sharePayload) { payload in
            ActivityView(activityItems: payload.items)
                .presentationDetents([.medium, .large])
        }
        .task(id: isPreparingShare) {
            guard isPreparingShare else { return }
            let items = await onShare(result)
            guard !Task.isCancelled else {
                isPreparingShare = false
                return
            }
            sharePayload = ShareSheetPayload(items: items)
            isPreparingShare = false
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("adjustment-sheet")
        .accessibilityHidden(false)
    }

    private var hasBodyOrSleeveGuidance: Bool {
        result.bodyRowsAtYourGauge != nil || result.sleeveRowsAtYourGauge != nil
    }

    private var castOnDriftPill: String? {
        guard let drift = result.castOnRoundingDriftPercent, abs(drift) >= 3 else {
            return nil
        }
        return String(format: "%+.0f%% width", drift)
    }

    private var gaugeSummaryCard: some View {
        sectionCard(title: "Gauge Summary", subtitle: "Pattern compared with your swatch") {
            VStack(spacing: 12) {
                GaugeSummaryRow(
                    name: "Stitch-wise width",
                    adjusted: "\(GaugeMath.fmtPct(result.stitchWidthScale))%",
                    adjustedIdentifier: "stitch-summary"
                )
                GaugeSummaryRow(
                    name: "Row-wise density",
                    adjusted: "\(GaugeMath.fmtPct(result.rowCountScale))%",
                    adjustedIdentifier: "row-summary"
                )
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("gauge-summary")
    }

    private func sectionCard<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(nil)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityAddTraits(.isHeader)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted)
                    .lineLimit(nil)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            content()
        }
        .cardStyle()
    }

    private var actionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(
                action: { showFullMath.toggle() },
                label: {
                    HStack {
                        Text(showFullMath ? "Hide full math" : "Show full math")
                        Spacer()
                        Image(systemName: showFullMath ? "chevron.up" : "chevron.down")
                            .font(.caption.weight(.bold))
                    }
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
            )
            .buttonStyle(.plain)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppTheme.sage)
            .accessibilityIdentifier("disclosure-full-math")
            .accessibilityLabel(showFullMath ? "Hide full math" : "Show full math")

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
        }
        .cardStyle()
    }

    // swiftlint:disable line_length
    private var fullMathBreakdown: String {
        var lines = [
            "pattern: \(plain(inputs.patternStitches)) st x \(plain(inputs.patternRows)) rows per 10cm (aspect \(String(format: "%.2f", inputs.patternStitches / inputs.patternRows)))",
            "you:     \(plain(inputs.yourStitches)) st x \(plain(inputs.yourRows)) rows per 10cm (aspect \(String(format: "%.2f", inputs.yourStitches / inputs.yourRows)))",
            "stitch width scale = pattern_st / your_st = \(plain(inputs.patternStitches)) / \(plain(inputs.yourStitches)) = \(String(format: "%.3f", result.stitchWidthScale))",
            "row density ratio  = your_row / pattern_row = \(plain(inputs.yourRows)) / \(plain(inputs.patternRows)) = \(String(format: "%.3f", result.rowCountScale))",
            "dim correction     = pattern_row / your_row = \(plain(inputs.patternRows)) / \(plain(inputs.yourRows)) = \(String(format: "%.3f", result.dimensionScale))",
            "for any horizontal dim, your stitch count produces \(String(format: "%.1f", result.stitchWidthScale * 100))% of the pattern's intended width"
        ]
        if let value = inputs.patternYokeDepth, let rows = result.yokeRowsAtYourGauge {
            lines.append("yoke: \(unit.formatMeasurement(value)) → knit \(rows) rows")
        }
        if let value = inputs.patternBodyLength, let rows = result.bodyRowsAtYourGauge {
            lines.append("body: \(unit.formatMeasurement(value)) → knit \(rows) rows")
        }
        if let value = inputs.patternSleeveLength, let rows = result.sleeveRowsAtYourGauge {
            lines.append("sleeve: \(unit.formatMeasurement(value)) → knit \(rows) rows")
        }
        if let spacing = inputs.patternIncreaseSpacing, let adjusted = result.adjustedIncreaseSpacing {
            lines.append("increase spacing = \(plain(spacing)) x row density = \(GaugeMath.fmtRows(adjusted)) rows")
        }
        if let castOn = inputs.patternCastOn, let adjusted = result.adjustedCastOn {
            lines.append("cast-on adjust = your_st / pattern_st x \(plain(castOn)) = \(adjusted) stitches")
        }
        return lines.joined(separator: "\n")
    }
    // swiftlint:enable line_length
}

private struct GaugeSummaryRow: View {
    let name: String
    let adjusted: String
    let adjustedIdentifier: String

    var body: some View {
        GaugeMeasurementPair(spacing: 10) {
            VStack(spacing: 4) {
                Text(name)
                    .font(.caption.weight(.semibold))
                Text("Pattern 100%")
                    .font(.system(.body, design: .monospaced).weight(.bold))
            }
            .foregroundStyle(AppTheme.ink)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(AppTheme.oatmeal)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(name) in pattern: Pattern 100%")
        } trailing: {
            VStack(spacing: 4) {
                Text("Adjusted")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.85))
                Text(adjusted)
                    .font(.system(.body, design: .monospaced).weight(.bold))
                    .foregroundStyle(.white)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(AppTheme.sage)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(name) adjusted: \(adjusted)")
            .accessibilityIdentifier(adjustedIdentifier)
        }
    }
}

private struct AdjustmentSheetHeader: View {
    let isPreparingShare: Bool
    let onShare: () -> Void
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Text("Adjustments")
                .font(.headline)
                .foregroundStyle(AppTheme.ink)
                .accessibilityAddTraits(.isHeader)

            HStack {
                Button(action: onShare) {
                    if isPreparingShare {
                        ProgressView()
                            .tint(AppTheme.sage)
                            .frame(width: 44, height: 44)
                    } else {
                        Image(systemName: "square.and.arrow.up")
                            .imageScale(.medium)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(AppTheme.sage)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                }
                .disabled(isPreparingShare)
                .accessibilityIdentifier("share-results")
                .accessibilityLabel("Share results")
                .accessibilityHint(
                    "Opens the share sheet with an image of the current results." +
                    " Copy is available from the share sheet."
                )

                Spacer()

                Button(action: onClose) {
                    Text("Close")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppTheme.sage)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Close")
                .accessibilityIdentifier("Close")
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 4)
        .padding(.bottom, 4)
    }
}
