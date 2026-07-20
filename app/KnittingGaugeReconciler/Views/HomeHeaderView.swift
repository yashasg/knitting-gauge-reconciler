import SwiftUI

// MARK: - AboutHelpToolbarButton

struct AboutHelpToolbarButton: View {
    @Binding private var state: AboutHelpState

    init(state: Binding<AboutHelpState>) {
        _state = state
    }

    var body: some View {
        Button {
            state.open()
        } label: {
            Image(systemName: "questionmark.circle")
                .font(.body.weight(.medium))
                .foregroundStyle(AppTheme.sage)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(AboutHelpContract.openLabel)
        .accessibilityHint(AboutHelpContract.openHint)
        .accessibilityIdentifier("about-help-button")
    }
}
