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
            HStack(alignment: .top, spacing: spacing) {
                leading()
                    // maxHeight: .infinity ensures both sides fill the same row height
                    // so a mismatch label appearing on one side cannot shrink the other.
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                trailing()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
    }
}
