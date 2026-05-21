import SwiftUI

// MARK: - SectionTitle

struct SectionTitle: View {
    var title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title.uppercased())
            .font(.caption.weight(.bold))
            .foregroundStyle(AppTheme.sage)
            .accessibilityAddTraits(.isHeader)
    }
}
