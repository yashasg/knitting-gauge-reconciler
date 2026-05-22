import SwiftUI

struct ShareableView: View {
    private let columns = [
        GridItem(.flexible(minimum: 0), spacing: 12),
        GridItem(.flexible(minimum: 0), spacing: 12)
    ]

    var summary: ResultsExportSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            LazyVGrid(columns: columns, spacing: 12) {
                ShareableGaugeCard(title: "Pattern Gauge", gauge: summary.patternGauge)
                ShareableGaugeCard(title: "Your Gauge", gauge: summary.swatchGauge)
            }

            shareableSection(title: "Estimated Reconciliation") {
                LazyVGrid(columns: columns, spacing: 12) {
                    ShareableMetricCard(metric: summary.stitchMetric)
                    ShareableMetricCard(metric: summary.rowMetric)
                }
            }

            shareableSection(title: "Required Adjustments") {
                VStack(spacing: 10) {
                    ShareableAdjustmentRow(
                        title: "Cast-on stitches",
                        pattern: "Pattern",
                        adjusted: summary.castOn
                    )

                    ForEach(summary.sections, id: \.name) { section in
                        ShareableAdjustmentRow(
                            title: section.name,
                            pattern: section.pattern,
                            adjusted: section.adjusted
                        )
                    }
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "wand.and.stars")
                    .font(.caption.weight(.semibold))
                Text("Gauge Reconciler")
                    .font(.caption.weight(.semibold))
                Spacer()
                Text("knitting gauge snapshot")
                    .font(.caption)
            }
            .foregroundStyle(AppTheme.muted)
        }
        .padding(20)
        .frame(width: 390, alignment: .leading)
        .background(AppTheme.background)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(summary.title)
                .font(.system(.title2, design: .serif).weight(.bold))
                .foregroundStyle(AppTheme.ink)
            Text("Your gauge, pattern gauge, and adjustment plan in one shareable card.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func shareableSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.sage)
            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct ShareableGaugeCard: View {
    var title: String
    var gauge: ResultsExportSummary.GaugePair

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.sage)
            Text(gauge.stitches)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.ink)
            Text(gauge.rows)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.ink)
        }
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        .padding(14)
        .background(AppTheme.oatmeal)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct ShareableMetricCard: View {
    var metric: ResultsExportSummary.Metric

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(metric.title)
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.muted)
            Text(metric.value)
                .font(.system(.title3, design: .monospaced).weight(.bold))
                .foregroundStyle(AppTheme.ink)
            Text(metric.status)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(shareMetricBackground(metric.status))
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, minHeight: 118, alignment: .topLeading)
        .padding(14)
        .background(AppTheme.oatmeal)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct ShareableAdjustmentRow: View {
    var title: String
    var pattern: String
    var adjusted: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.ink)
            Text(pattern)
                .font(.caption)
                .foregroundStyle(AppTheme.muted)
            Text(adjusted)
                .font(.system(.body, design: .monospaced).weight(.bold))
                .foregroundStyle(AppTheme.sage)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppTheme.oatmeal)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private func shareMetricBackground(_ status: String) -> Color {
    if status == "Match" {
        return AppTheme.sage
    }
    if status.hasPrefix("Much") {
        return AppTheme.terracotta
    }
    return AppTheme.secondary
}
