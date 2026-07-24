import SwiftUI
import UIKit

struct ShareableView: View {
    var summary: ResultsExportSummary

    private var columns: [GridItem] {
        [
            GridItem(.flexible(minimum: 0), spacing: Spacing.control),
            GridItem(.flexible(minimum: 0), spacing: Spacing.control),
        ]
    }

    @MainActor
    static func pngData(summary: ResultsExportSummary, scale: CGFloat = 3) -> Data {
        let renderer = ImageRenderer(content: ShareableView(summary: summary))
        renderer.proposedSize = .init(width: 390, height: nil)
        var data = Data()
        renderer.render(rasterizationScale: scale) { size, draw in
            data = UIGraphicsImageRenderer(size: size).pngData { context in
                draw(context.cgContext)
            }
        }
        return data
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.margin) {
            header

            LazyVGrid(columns: columns, spacing: Spacing.control) {
                ShareableGaugeCard(title: "Pattern Gauge", gauge: summary.patternGauge)
                ShareableGaugeCard(title: "Your Gauge", gauge: summary.swatchGauge)
            }

            shareableSection(title: "Estimated Reconciliation") {
                LazyVGrid(columns: columns, spacing: Spacing.control) {
                    ShareableMetricCard(metric: summary.stitchMetric)
                    ShareableMetricCard(metric: summary.rowMetric)
                }
            }

            if summary.castOn != nil || !summary.sections.isEmpty {
                shareableSection(title: "Gauge Guidance") {
                    VStack(spacing: Spacing.control) {
                        if let castOn = summary.castOn {
                            ShareableAdjustmentRow(
                                title: "Cast-on stitches",
                                pattern: "Pattern",
                                adjusted: castOn
                            )
                        }

                        ForEach(summary.sections, id: \.name) { section in
                            ShareableAdjustmentRow(
                                title: section.name,
                                pattern: section.pattern,
                                adjusted: section.adjusted
                            )
                        }
                    }
                }
            }

            HStack(spacing: Spacing.inner) {
                Image(systemName: "wand.and.stars")
                    .font(.satoshiCaption.weight(.semibold))
                    .accessibilityHidden(true)
                Text("Stitchwise")
                    .font(.satoshiCaption.weight(.semibold))
                Spacer()
                Text("knitting gauge snapshot")
                    .font(.satoshiCaption)
            }
            .foregroundStyle(AppTheme.muted)
        }
        .padding(Spacing.roomy)
        .frame(width: Sizing.shareCardWidth, alignment: .leading)
        .background(AppTheme.background)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.compact) {
            Text(summary.title)
                .font(.satoshiTitle2.weight(.bold))
                .foregroundStyle(AppTheme.ink)
            Text("Your pattern and swatch gauge comparison in one shareable card.")
                .font(.satoshiSubheadline)
                .foregroundStyle(AppTheme.muted)
        }
        .padding(Spacing.roomy)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: Radius.extraLarge, style: .continuous))
    }

    private func shareableSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Spacing.control) {
            Text(title)
                .font(.satoshiHeadline.weight(.bold))
                .foregroundStyle(AppTheme.sage)
            content()
        }
        .padding(Spacing.roomy)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: Radius.extraLarge, style: .continuous))
    }
}

private struct ShareableGaugeCard: View {
    var title: String
    var gauge: ResultsExportSummary.GaugePair

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.inner) {
            Text(title)
                .font(.satoshiCaption.weight(.bold))
                .foregroundStyle(AppTheme.sage)
            Text(gauge.stitches)
                .font(.satoshiSubheadline.weight(.semibold))
                .foregroundStyle(AppTheme.ink)
            Text(gauge.rows)
                .font(.satoshiSubheadline.weight(.semibold))
                .foregroundStyle(AppTheme.ink)
        }
        .frame(
            maxWidth: .infinity,
            minHeight: Sizing.resultCardMinimumHeight,
            alignment: .topLeading
        )
        .padding(Spacing.margin)
        .background(AppTheme.oatmeal)
        .clipShape(RoundedRectangle(cornerRadius: Radius.large, style: .continuous))
    }
}

private struct ShareableMetricCard: View {
    var metric: ResultsExportSummary.Metric

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.inner) {
            Text(metric.title)
                .font(.satoshiCaption.weight(.bold))
                .foregroundStyle(AppTheme.muted)
            Text(metric.value)
                .font(.satoshiTitle3.monospaced().weight(.bold))
                .foregroundStyle(AppTheme.ink)
            Text(metric.status)
                .font(.satoshiCaption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, Spacing.control)
                .padding(.top, Spacing.compact)
                .padding(.bottom, Spacing.compact)
                .frame(minHeight: Sizing.minimumTouchTarget)
                .background(shareMetricBackground(metric.status))
                .clipShape(Capsule())
        }
        .frame(
            maxWidth: .infinity,
            minHeight: Sizing.shareSummaryMinimumHeight,
            alignment: .topLeading
        )
        .padding(Spacing.margin)
        .background(AppTheme.oatmeal)
        .clipShape(RoundedRectangle(cornerRadius: Radius.large, style: .continuous))
    }
}

private struct ShareableAdjustmentRow: View {
    var title: String
    var pattern: String
    var adjusted: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.compact) {
            Text(title)
                .font(.satoshiSubheadline.weight(.bold))
                .foregroundStyle(AppTheme.ink)
            Text(pattern)
                .font(.satoshiCaption)
                .foregroundStyle(AppTheme.muted)
            Text(adjusted)
                .font(.satoshiBody.monospaced().weight(.bold))
                .foregroundStyle(AppTheme.sage)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.margin)
        .background(AppTheme.oatmeal)
        .clipShape(RoundedRectangle(cornerRadius: Radius.large, style: .continuous))
    }
}

func shareMetricBackground(_ status: String) -> Color {
    if status == "Match" {
        return AppTheme.sage
    }
    if status.hasPrefix("Much") {
        return AppTheme.terracotta
    }
    return AppTheme.secondary
}
