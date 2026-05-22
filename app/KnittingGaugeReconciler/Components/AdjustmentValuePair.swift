import SwiftUI

// MARK: - AdjustmentValuePair
// Left block: pattern value on cream background (informational).
// Right block: your value on dark-green background (actionable).
// Delta badge floats above the green block without changing the row footprint.

struct AdjustmentValuePair: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var patternValue: Int
    var yourValue: Int
    var patternLabel: String = "Pattern Rows"
    var yourLabel: String = "You Must Knit"
    var valueIdentifier: String? = nil

    private var delta: Int { yourValue - patternValue }

    private var columns: [GridItem] {
        [
            GridItem(.flexible(minimum: 0), spacing: 10),
            GridItem(.flexible(minimum: 0)),
        ]
    }

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 10) {
                patternTile
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                yourTile
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        } else {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 0) {
                patternTile
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                yourTile
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
    }

    private var patternTile: some View {
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
    }

    private var yourTile: some View {
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
            .background(AppTheme.sage)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            if delta != 0 {
                Text(delta > 0 ? "+\(delta)" : "\(delta)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.top, 4)
                    .padding(.bottom, 4)
                    .frame(minHeight: 44)
                    .background(AppTheme.secondary)
                    .clipShape(Capsule())
                    .offset(x: -4, y: -8)
            }
        }
    }
}
