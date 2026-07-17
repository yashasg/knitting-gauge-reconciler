// swiftlint:disable file_length
// Issue #65 keeps conditional result, reset, and share UI in this existing authorized file.
import SwiftUI

struct RequiredAdjustmentsCard: View {
    @Binding private var showFullMath: Bool
    @State private var showResetConfirmation = false

    private let result: GaugeMathResult?
    private let inputs: GaugeInputs?
    private let verdict: (title: String, body: String)
    private let unit: MeasurementUnit
    private let canUndoReset: Bool
    private let onReset: () -> Void
    private let onUndoReset: () -> Void
    private let onShare: (GaugeMathResult) async -> [Any]

    init(
        result: GaugeMathResult?,
        inputs: GaugeInputs?,
        verdict: (title: String, body: String),
        unit: MeasurementUnit,
        showFullMath: Binding<Bool>,
        canUndoReset: Bool,
        onReset: @escaping () -> Void,
        onUndoReset: @escaping () -> Void,
        onShare: @escaping (GaugeMathResult) async -> [Any]
    ) {
        self.result = result
        self.inputs = inputs
        self.verdict = verdict
        self.unit = unit
        self._showFullMath = showFullMath
        self.canUndoReset = canUndoReset
        self.onReset = onReset
        self.onUndoReset = onUndoReset
        self.onShare = onShare
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let result, let inputs {
                LiveResultsView(
                    result: result,
                    inputs: inputs,
                    verdict: verdict,
                    unit: unit,
                    showFullMath: $showFullMath,
                    onShare: onShare
                )
            } else {
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
        .alert("Reset all values?", isPresented: $showResetConfirmation) {
            Button("Reset values", role: .destructive, action: onReset)
            Button("Keep editing", role: .cancel) {}
        } message: {
            Text("This replaces every entry with the sample gauge values.")
        }
    }
}

private struct LiveResultsView: View {
    @State private var sharePayload: ShareSheetPayload?
    @State private var isPreparingShare = false

    private let result: GaugeMathResult
    private let inputs: GaugeInputs
    private let verdict: (title: String, body: String)
    private let unit: MeasurementUnit
    @Binding private var showFullMath: Bool
    private let onShare: (GaugeMathResult) async -> [Any]

    init(
        result: GaugeMathResult,
        inputs: GaugeInputs,
        verdict: (title: String, body: String),
        unit: MeasurementUnit,
        showFullMath: Binding<Bool>,
        onShare: @escaping (GaugeMathResult) async -> [Any]
    ) {
        self.result = result
        self.inputs = inputs
        self.verdict = verdict
        self.unit = unit
        self._showFullMath = showFullMath
        self.onShare = onShare
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HeroTilesView(result: result)

            VStack(alignment: .leading, spacing: 6) {
                Text(verdict.title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.ink)
                    .accessibilityAddTraits(.isHeader)
                Text(verdict.body)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()

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
                let castOnSubtitle = gaugeStatus(scale: result.stitchWidthScale) == "Match" &&
                    Double(adjustedCastOn) != patternCastOn
                    ? "Optional exact-width refinement"
                    : "To preserve pattern width"
                sectionCard(title: "Cast-on", subtitle: castOnSubtitle) {
                    VStack(alignment: .leading, spacing: 8) {
                        AdjustmentRow(
                            name: "Cast-on stitches",
                            pattern: "\(plain(patternCastOn)) stitches",
                            adjusted: "\(adjustedCastOn) stitches",
                            adjustedIdentifier: "cast-on-result",
                            driftPill: castOnDriftPill
                        )
                        Text("Reconcile this rounded stitch count with your pattern's stitch-repeat multiple.")
                            .font(.caption)
                            .foregroundStyle(AppTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            actionsCard
        }
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
            Button {
                guard !isPreparingShare else { return }
                isPreparingShare = true
            } label: {
                HStack {
                    Text("Share results")
                    Spacer()
                    if isPreparingShare {
                        ProgressView()
                            .tint(AppTheme.sage)
                    } else {
                        Image(systemName: "square.and.arrow.up")
                            .accessibilityHidden(true)
                    }
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppTheme.ink)
            .disabled(isPreparingShare)
            .accessibilityIdentifier("share-results")
            .accessibilityHint("Opens the share sheet with an image of the current results")

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
            .foregroundStyle(AppTheme.ink)
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
            lines.append("reconcile the rounded stitch count with the pattern stitch-repeat multiple")
        }
        return lines.joined(separator: "\n")
    }
    // swiftlint:enable line_length
}

struct HeroTilesView: View {
    var result: GaugeMathResult

    var body: some View {
        GaugeMeasurementPair(spacing: 12) {
            HeroTile(
                label: "Stitch-wise",
                value: "\(GaugeMath.fmtPct(result.stitchWidthScale))%",
                status: gaugeStatus(scale: result.stitchWidthScale)
            )
            .accessibilityIdentifier("stitch-summary")
        } trailing: {
            HeroTile(
                label: "Row-wise",
                value: "\(GaugeMath.fmtPct(result.rowCountScale))%",
                status: rowStatus(scale: result.rowCountScale)
            )
            .accessibilityIdentifier("row-summary")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("gauge-summary")
    }
}

private struct HeroTile: View {
    @Environment(\.colorScheme) private var colorScheme

    var label: String
    var value: String
    var status: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.muted)
            Text(value)
                .font(.system(.title2, design: .monospaced).weight(.bold))
                .foregroundStyle(AppTheme.ink)
            Text(status)
                .font(.caption.weight(.semibold))
                .foregroundStyle(colorScheme == .dark && status != "Match" ? .black : .white)
                .padding(.horizontal, 10)
                .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                .frame(minHeight: 44)
                .background(tileBackground(status))
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        .padding(14)
        .background(AppTheme.oatmeal)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value), \(status)")
    }

    // swiftlint:disable:next identifier_name
    private func tileBackground(_ s: String) -> Color {
        if s == "Match" { return AppTheme.sage }
        if s.hasPrefix("Much") { return AppTheme.terracotta }
        return AppTheme.secondary
    }
}
