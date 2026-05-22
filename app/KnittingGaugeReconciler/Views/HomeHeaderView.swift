import SwiftUI

// MARK: - AboutHelpToolbarButton

struct AboutHelpToolbarButton: View {
    @Binding private var showAboutHelp: Bool

    init(showAboutHelp: Binding<Bool>) {
        _showAboutHelp = showAboutHelp
    }

    var body: some View {
        Button {
            showAboutHelp = true
        } label: {
            Image(systemName: "questionmark.circle")
                .font(.body.weight(.medium))
                .foregroundStyle(AppTheme.sage)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("About this calculator")
        .accessibilityHint("Opens an explanation of how this calculator works")
        .accessibilityIdentifier("about-help-button")
    }
}
