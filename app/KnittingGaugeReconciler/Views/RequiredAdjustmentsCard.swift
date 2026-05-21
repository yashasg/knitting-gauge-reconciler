import SwiftUI

// MARK: - RequiredAdjustmentsCard

struct RequiredAdjustmentsCard: View {
    var cachedResult: GaugeMathResult?
    var isResultStale: Bool
    var inputs: GaugeInputs
    @Binding var showFullMath: Bool
    var onRecalculate: () -> Void
    var onReset: () -> Void
    var onShare: (GaugeMathResult) -> Void

    var body: some View {
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
                    onRecalculate()
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
                        VStack(spacing: 12) {
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
                Button("Reset to defaults", action: onReset)
                    .buttonStyle(.plain)
                    .frame(minWidth: 100, minHeight: 44)
                    .contentShape(Rectangle())
                    .accessibilityIdentifier("reset-defaults")
                Spacer()
                Button(action: { onShare(result) }) {
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
}

// MARK: - AdjustmentRow (used only inside RequiredAdjustmentsCard)
// Tile-based layout matching AdjustmentValuePair chrome:
// left oatmeal tile (pattern), right sage tile (adjusted).

private struct AdjustmentRow: View {
    var name: String
    var pattern: String
    var adjusted: String
    var adjustedIdentifier: String? = nil
    var driftPill: String? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Left tile: pattern value (oatmeal background — informational)
            VStack(alignment: .center, spacing: 4) {
                Text(name)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.muted)
                    .multilineTextAlignment(.center)
                Text(pattern)
                    .font(.system(.body, design: .monospaced).weight(.bold))
                    .foregroundStyle(AppTheme.muted)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(AppTheme.oatmeal)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            // Right tile: adjusted value (sage background — actionable)
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .center, spacing: 4) {
                    Text("Adjusted")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                    Text(adjusted)
                        .font(.system(.body, design: .monospaced).weight(.bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier(adjustedIdentifier ?? "adjustment-\(name.lowercased().replacingOccurrences(of: " ", with: "-"))-value")
                }
                .frame(maxWidth: .infinity)
                .padding(14)
                .padding(.top, driftPill != nil ? 8 : 0)
                .background(AppTheme.sage)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                if let pill = driftPill {
                    Text(pill)
                        .font(.caption.weight(.semibold))
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
