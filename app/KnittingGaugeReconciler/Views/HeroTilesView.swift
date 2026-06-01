import SwiftUI

struct HeroTilesView: View {
    var result: GaugeMathResult

    private let columns = [
        GridItem(.flexible(minimum: 0), spacing: 12),
        GridItem(.flexible(minimum: 0), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            HeroTile(
                label: "Stitch-wise",
                value: "\(GaugeMath.fmtPct(result.stitchWidthScale))%",
                status: gaugeStatus(scale: result.stitchWidthScale)
            )
            HeroTile(
                label: "Row-wise",
                value: "\(GaugeMath.fmtPct(result.rowCountScale))%",
                status: rowStatus(scale: result.rowCountScale)
            )
        }
    }
}

private struct HeroTile: View {
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
                .foregroundStyle(.white)
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
