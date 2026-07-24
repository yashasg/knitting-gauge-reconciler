import SwiftUI

// MARK: - GaugeMeasurementPair

struct GaugeMeasurementPair<Leading: View, Trailing: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var spacing: CGFloat = Spacing.control
    @ViewBuilder var leading: () -> Leading
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            verticalPair
        } else {
            ViewThatFits(in: .horizontal) {
                horizontalPair
                verticalPair
            }
        }
    }

    private var horizontalPair: some View {
        HStack(alignment: .top, spacing: spacing) {
            leading()
                .frame(maxWidth: .infinity, alignment: .topLeading)
            trailing()
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    private var verticalPair: some View {
        VStack(alignment: .leading, spacing: spacing) {
            leading()
                .frame(maxWidth: .infinity, alignment: .topLeading)
            trailing()
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }
}
