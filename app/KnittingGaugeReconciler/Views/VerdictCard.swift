import SwiftUI

struct VerdictCard: View {
    var result: GaugeMathResult
    var patternCastOn: Double
    var onVerdictHelp: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(verdictTitle(result: result))
                    .font(.headline.weight(.bold))
                    .foregroundStyle(titleColor)
                Text(firstSentence)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Button(action: onVerdictHelp) {
                Image(systemName: "questionmark.circle")
                    .font(.title3)
                    .foregroundStyle(AppTheme.muted)
            }
            .accessibilityLabel("More about verdict")
        }
        .cardStyle()
        .accessibilityIdentifier("verdict-card")
    }

    private var titleColor: Color {
        let title = verdictTitle(result: result)
        if title == "Gauge match" { return AppTheme.sage }
        if title == "Major mismatch" { return AppTheme.terracotta }
        return AppTheme.ink
    }

    private var firstSentence: String {
        let body = verdictBody(result: result, patternCastOn: patternCastOn)
        return body.components(separatedBy: ". ").first.map { $0 + "." } ?? body
    }
}
