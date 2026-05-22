import SwiftUI

// MARK: - GaugeInputGroup
// Each gauge card is its own raised tile via .cardStyle(). Icons and PER tag
// are in the header row.

struct GaugeInputGroup<Content: View>: View {
    var title: String
    var icon: String?
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
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .fixedSize(horizontal: false, vertical: true)
                        // Decorative per-unit tag — the gauge values
                        // themselves include the "/ 10 cm" suffix in their
                        // VoiceOver labels. Hide from VoiceOver and clamp
                        // Dynamic Type so it cannot overflow the HStack
                        // header row at accessibility sizes.
                        .accessibilityHidden(true)
                        .accessibilityIdentifier("per-tag")
                        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                }
            }
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}
