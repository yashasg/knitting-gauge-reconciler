import SwiftUI

// MARK: - HomeHeaderView

struct HomeHeaderView: View {
    @Binding var showAboutHelp: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            Text("Gauge Reconciler")
                .font(.system(.largeTitle, design: .serif).weight(.bold))
                .foregroundStyle(AppTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                showAboutHelp = true
            } label: {
                Image(systemName: "questionmark.circle")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppTheme.sage)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("About this calculator, more information")
            .accessibilityHint("Opens an explanation of how this calculator works")
            .accessibilityIdentifier("about-help-button")
        }
    }
}
