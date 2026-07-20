import SwiftUI

private struct EqualWidthPairLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let leadingWidth = subviews[0].sizeThatFits(.unspecified).width
        let trailingWidth = subviews[1].sizeThatFits(.unspecified).width
        let fallback = CGSize(width: max(leadingWidth, trailingWidth) * 2 + spacing, height: 0)
        let width = proposal.replacingUnspecifiedDimensions(by: fallback).width
        let itemWidth = max(0, (width - spacing) / 2)
        let itemProposal = ProposedViewSize(width: itemWidth, height: proposal.height)
        let leadingHeight = subviews[0].sizeThatFits(itemProposal).height
        let trailingHeight = subviews[1].sizeThatFits(itemProposal).height
        let height = max(leadingHeight, trailingHeight)
        return CGSize(width: width, height: height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let itemWidth = max(0, (bounds.width - spacing) / 2)
        let itemProposal = ProposedViewSize(width: itemWidth, height: bounds.height)
        for (index, subview) in subviews.enumerated() {
            subview.place(
                at: CGPoint(x: bounds.minX + CGFloat(index) * (itemWidth + spacing), y: bounds.minY),
                anchor: .topLeading,
                proposal: itemProposal
            )
        }
    }
}

// MARK: - GaugeMeasurementPair

struct GaugeMeasurementPair<Leading: View, Trailing: View>: View {
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
            EqualWidthPairLayout(spacing: spacing) {
                leading()
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                trailing()
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
    }
}
