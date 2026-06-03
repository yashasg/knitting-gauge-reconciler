import SwiftUI

// MARK: - GaugeInputGroup
// Each gauge card is its own raised tile via .cardStyle(). Icons and PER tag
// are in the header row. At accessibility Dynamic Type sizes the header reflows
// into a VStack so text always renders at the user's chosen size.

struct GaugeInputGroup<Content: View>: View {
    var title: String
    var icon: String?
    var showPerTag: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: 8) {
                    iconView
                    titleView
                    Spacer()
                    if showPerTag { perTagView }
                }
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .center, spacing: 8) {
                        iconView
                        titleView
                        Spacer()
                    }
                    if showPerTag { perTagView }
                }
            }
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    @ViewBuilder private var iconView: some View {
        if let icon {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.secondary)
                .accessibilityHidden(true)
        }
    }

    private var titleView: some View {
        Text(title)
            .font(.title2.weight(.bold))
            .foregroundStyle(AppTheme.ink)
            .accessibilityAddTraits(.isHeader)
    }

    // Decorative per-unit tag — gauge values carry "/ 10 cm" in their
    // VoiceOver labels, so this is hidden from assistive technology.
    private var perTagView: some View {
        Text("PER 10CM / 4\"")
            .font(.caption2.weight(.bold))
            .tracking(0.5)
            .foregroundStyle(AppTheme.muted)
            .lineLimit(1)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityHidden(true)
            .accessibilityIdentifier("per-tag")
    }
}

// MARK: - Previews

#Preview("Default — xLarge") {
    GaugeInputGroup(title: "Your Gauge", icon: "ruler", showPerTag: true) {
        Text("Content goes here")
    }
    .padding()
}

#Preview("AX5 — accessibility5") {
    GaugeInputGroup(title: "Your Gauge", icon: "ruler", showPerTag: true) {
        Text("Content goes here")
    }
    .padding()
    .environment(\.dynamicTypeSize, .accessibility5)
}
