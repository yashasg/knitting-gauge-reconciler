import SwiftUI

// MARK: - GaugeInputGroup
// Each gauge card is its own raised tile via .cardStyle(). Icons and PER tag
// are in the header row.

struct GaugeInputGroup<Content: View>: View {
    var title: String
    var icon: String? = nil
    var showPerTag: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AppTheme.secondary)
                        .accessibilityHidden(true)
                }
                Text(title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppTheme.ink)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                if showPerTag {
                    Text("PER 10CM / 4\"")
                        .font(.caption2.weight(.bold))
                        .tracking(0.5)
                        .foregroundStyle(AppTheme.muted)
                }
            }
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}
