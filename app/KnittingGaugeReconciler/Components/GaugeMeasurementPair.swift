import SwiftUI

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
            // HStack instead of LazyVGrid: LazyVGrid defers rendering cells that are
            // off-screen at initial layout. On iOS 26.4 those cells never appear in the
            // accessibility tree even after scrolling into view. Two fixed columns is
            // not a lazy-rendering use case — HStack renders both eagerly.
            HStack(alignment: .top, spacing: spacing) {
                leading()
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                trailing()
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
    }
}
