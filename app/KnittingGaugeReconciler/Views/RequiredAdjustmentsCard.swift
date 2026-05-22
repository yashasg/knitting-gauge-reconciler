import SwiftUI

// MARK: - RequiredAdjustmentsCard

struct RequiredAdjustmentsCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Binding var showAdjustmentSheet: Bool
    @State private var selectedDetent: PresentationDetent = .medium

    var cachedResult: GaugeMathResult?
    var inputs: GaugeInputs
    @Binding var showFullMath: Bool
    var onRecalculate: () -> Void
    var onReset: () -> Void
    var onShare: (GaugeMathResult) -> [Any]

    init(
        cachedResult: GaugeMathResult?,
        inputs: GaugeInputs,
        showFullMath: Binding<Bool>,
        showAdjustmentSheet: Binding<Bool>,
        onRecalculate: @escaping () -> Void,
        onReset: @escaping () -> Void,
        onShare: @escaping (GaugeMathResult) -> [Any]
    ) {
        self.cachedResult = cachedResult
        self.inputs = inputs
        self._showFullMath = showFullMath
        self._showAdjustmentSheet = showAdjustmentSheet
        self.onRecalculate = onRecalculate
        self.onReset = onReset
        self.onShare = onShare
    }

    private var presentedResult: GaugeMathResult {
        cachedResult ?? GaugeMath.compute(inputs)
    }

    private let availableDetents: Set<PresentationDetent> = [.medium, .large]

    var body: some View {
        Button {
            selectedDetent = dynamicTypeSize.isAccessibilitySize ? .large : .medium
            onRecalculate()
            showAdjustmentSheet = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "wand.and.stars")
                    .font(.footnote.weight(.semibold))
                    .accessibilityHidden(true)
                Text("View Adjustments")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(AppTheme.cream)
            .frame(minWidth: 176)
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 8)
            .frame(minHeight: 44)
            .background(AppTheme.sage)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .center)
        .accessibilityIdentifier("calculate-button")
        .accessibilityLabel("View Adjustments")
        .accessibilityHint("Computes gauge reconciliation adjustments and opens the results sheet")
        .sheet(isPresented: $showAdjustmentSheet) {
            AdjustmentSheetView(
                result: presentedResult,
                inputs: inputs,
                showFullMath: $showFullMath,
                onReset: {
                    onReset()
                    showAdjustmentSheet = false
                },
                onShare: onShare,
                onClose: { showAdjustmentSheet = false }
            )
            .presentationDetents(availableDetents, selection: $selectedDetent)
            .presentationDragIndicator(.visible)
        }
    }
}

private struct AdjustmentSheetView: View {
    @State private var sharePayload: ShareSheetPayload?

    var result: GaugeMathResult
    var inputs: GaugeInputs
    @Binding var showFullMath: Bool
    var onReset: () -> Void
    var onShare: (GaugeMathResult) -> [Any]
    var onClose: () -> Void

    private var requiresAdjustments: Bool {
        inputs.stitchMismatch || inputs.rowMismatch
    }

    private var hasMajorDrift: Bool {
        abs(result.stitchWidthScale - 1) >= 0.15 || abs(result.rowCountScale - 1) >= 0.15
    }

    private var statusSymbolName: String {
        requiresAdjustments ? "exclamationmark.circle.fill" : "checkmark.circle.fill"
    }

    private var statusSymbolColor: Color {
        requiresAdjustments ? AppTheme.secondary : AppTheme.sage
    }

    private var keyActionText: String {
        switch (inputs.stitchMismatch, inputs.rowMismatch) {
        case (false, false):
            return "Work from the pattern as written. No stitch or row adjustments are needed."
        case (true, false):
            return "Cast on \(result.adjustedCastOn) stitches instead of \(plain(inputs.patternCastOn))."
        case (false, true):
            return "Keep the pattern cast-on, then follow the updated row counts and shaping cadence below."
        case (true, true):
            return "Cast on \(result.adjustedCastOn) stitches and follow the updated row counts throughout."
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    numberedSectionCard(number: 1, title: "Yoke Depth", subtitle: "To hit target measurement") {
                        AdjustmentValuePair(
                            patternValue: GaugeMath.fmtRows(result.patternYokeRows),
                            yourValue: result.yokeRowsAtYourGauge,
                            valueIdentifier: "yoke-your-rows"
                        )
                    }

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

                    numberedSectionCard(number: 3, title: "Shaping Rates", subtitle: "Increases / Decreases") {
                        VStack(spacing: 12) {
                            AdjustmentRow(
                                name: "Increase-row spacing",
                                pattern: "Every \(plain(inputs.patternIncreaseSpacing)) rows",
                                // swiftlint:disable:next line_length
                                adjusted: "Space every \(GaugeMath.fmtRows(result.adjustedIncreaseSpacing)) rows/rounds",
                                adjustedIdentifier: "increases-result"
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

                    statusCard
                    actionsCard(result: result)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("Adjustments")
            .navigationBarTitleDisplayMode(.inline)
            .background(AppTheme.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(
                        action: { sharePayload = ShareSheetPayload(items: onShare(result)) },
                        label: { Image(systemName: "square.and.arrow.up") }
                    )
                    .accessibilityIdentifier("share-results")
                    .accessibilityLabel("Share results")
                    .accessibilityHint(
                        "Opens the share sheet with an image of the current results." +
                        " Copy is available from the share sheet."
                    )
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close", action: onClose)
                        .foregroundStyle(AppTheme.sage)
                }
            }
            .sheet(item: $sharePayload) { payload in
                ActivityView(activityItems: payload.items)
                    .presentationDetents([.medium, .large])
            }
        }
        .accessibilityIdentifier("adjustment-sheet")
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: statusSymbolName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(statusSymbolColor)
                    .padding(.top, 1)
                    .accessibilityHidden(true)

                Text(keyActionText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if hasMajorDrift {
                Text("Over 15% drift — consider re-swatching or changing needle size before proceeding.")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .cardStyle()
        .accessibilityElement(children: .combine)
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

    @ViewBuilder
    private func actionsCard(result: GaugeMathResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(
                action: { showFullMath.toggle() },
                label: {
                    HStack {
                        Text("Show full math")
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

            Button("Reset to defaults", action: onReset)
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.sage)
                .accessibilityIdentifier("reset-defaults")
        }
        .cardStyle()
    }

    // swiftlint:disable line_length
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
    // swiftlint:enable line_length
}
