import SwiftUI

// MARK: - AdjustmentValuePair
// Left block: pattern value on cream background (informational).
// Right block: your value on dark-green background (actionable).
// Delta badge floats top-right of the green block; hidden when delta == 0.

struct AdjustmentValuePair: View {
    var patternValue: Int
    var yourValue: Int
    var patternLabel: String = "Pattern Rows"
    var yourLabel: String = "You Must Knit"
    var valueIdentifier: String? = nil

    private var delta: Int { yourValue - patternValue }

    var body: some View {
        HStack(spacing: 10) {
            // Left: pattern rows (low-contrast, informational)
            VStack(alignment: .center, spacing: 4) {
                Text(patternLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.muted)
                    .multilineTextAlignment(.center)
                Text("\(patternValue)")
                    .font(.system(.title, design: .monospaced).weight(.bold))
                    .foregroundStyle(AppTheme.muted)
            }
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(AppTheme.oatmeal)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            // Right: your rows (high-contrast, actionable)
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .center, spacing: 4) {
                    Text(yourLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                    Text("\(yourValue)")
                        .font(.system(.title, design: .monospaced).weight(.bold))
                        .foregroundStyle(.white)
                        .accessibilityIdentifier(valueIdentifier ?? "adjustment-value-your")
                }
                .frame(maxWidth: .infinity)
                .padding(14)
                .padding(.top, delta != 0 ? 8 : 0)
                .background(AppTheme.sage)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                if delta != 0 {
                    Text(delta > 0 ? "+\(delta)" : "\(delta)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.secondary)
                        .clipShape(Capsule())
                        .offset(x: -4, y: -8)
                }
            }
        }
    }
}
