import SwiftUI

// MARK: - RequiredAdjustmentsCard

struct RequiredAdjustmentsCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Binding var showAdjustmentSheet: Bool
    @State private var selectedDetent: PresentationDetent = .medium

    var cachedResult: GaugeMathResult?
    var inputs: GaugeInputs
    var unit: MeasurementUnit
    @Binding var showFullMath: Bool
    var onRecalculate: () -> Void
    var onReset: () -> Void
    var onShare: (GaugeMathResult) async -> [Any]

    init(
        cachedResult: GaugeMathResult?,
        inputs: GaugeInputs,
        unit: MeasurementUnit,
        showFullMath: Binding<Bool>,
        showAdjustmentSheet: Binding<Bool>,
        onRecalculate: @escaping () -> Void,
        onReset: @escaping () -> Void,
        onShare: @escaping (GaugeMathResult) async -> [Any]
    ) {
        self.cachedResult = cachedResult
        self.inputs = inputs
        self.unit = unit
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
                unit: unit,
                showFullMath: $showFullMath,
                onReset: onReset,
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
    @State private var isPreparingShare = false
    @State private var showResetConfirmation = false

    var result: GaugeMathResult
    var inputs: GaugeInputs
    var unit: MeasurementUnit
    @Binding var showFullMath: Bool
    var onReset: () -> Void
    var onShare: (GaugeMathResult) async -> [Any]
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            AdjustmentSheetHeader(
                isPreparingShare: isPreparingShare,
                onShare: {
                    guard !isPreparingShare else { return }
                    isPreparingShare = true
                    Task {
                        let items = await onShare(result)
                        sharePayload = ShareSheetPayload(items: items)
                        isPreparingShare = false
                    }
                },
                onClose: onClose
            )
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
                                adjusted: "Every \(GaugeMath.fmtRows(result.adjustedIncreaseSpacing)) rows",
                                adjustedIdentifier: "increases-result"
                            )
                            AdjustmentRow(
                                name: "Cast-on stitches",
                                pattern: "\(plain(inputs.patternCastOn)) stitches",
                                adjusted: "\(result.adjustedCastOn) stitches",
                                adjustedIdentifier: "cast-on-result",
                                driftPill: abs(result.castOnRoundingDriftPercent) >= 3
                                    ? String(format: "%+.0f%% width", result.castOnRoundingDriftPercent)
                                    : nil
                            )
                        }
                    }

                    actionsCard(result: result)
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
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("adjustment-sheet")
        // Reset confirmation is presented from within the sheet's own hierarchy
        // so it surfaces above the sheet without dismissing it. A root-level
        // alert (ContentView) does not present while this sheet is up. See #40.
        .alert("Reset to defaults?", isPresented: $showResetConfirmation) {
            Button("Reset", role: .destructive) { onReset() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Clears every stitch and row value you've entered.")
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

            Button("Reset to defaults") { showResetConfirmation = true }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.red)
                .accessibilityIdentifier("reset-defaults")
                .accessibilityHint(
                    "Destructive: clears every stitch and row value you've entered."
                )
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
        -> yoke: \(unit.formatMeasurement(inputs.patternYokeDepth)) → knit \(result.yokeRowsAtYourGauge) rows
        -> body: \(unit.formatMeasurement(inputs.patternBodyLength)) → knit \(result.bodyRowsAtYourGauge) rows
        -> for any horizontal dim, your stitch count produces \(String(format: "%.1f", result.stitchWidthScale * 100))% of the pattern's intended width
        cast-on adjust = your_st / pattern_st x patCastOn = \(plain(inputs.yourStitches))/\(plain(inputs.patternStitches)) x \(plain(inputs.patternCastOn)) = \(result.adjustedCastOn) stitches
        """
    }
    // swiftlint:enable line_length
}

// MARK: - AdjustmentSheetHeader

/// Custom header for `AdjustmentSheetView`. Replaces a `NavigationStack`
/// toolbar (#24 — Apple HIG: do not nest `NavigationStack` inside sheets
/// without real multi-level navigation). Provides a 44×44pt leading Share
/// button, a centered inline title, and a 44×44pt trailing Close button.
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
