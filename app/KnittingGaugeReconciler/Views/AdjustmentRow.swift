import SwiftUI

// MARK: - ShareSheetPayload

struct ShareSheetPayload: Identifiable {
    let id: UUID
    var items: [Any]

    init(id: UUID = UUID(), items: [Any]) {
        self.id = id
        self.items = items
    }
}

// MARK: - AdjustmentRow

// Tile-based layout matching AdjustmentValuePair chrome:
// left oatmeal tile (pattern), right sage tile (adjusted).

struct AdjustmentRow: View {
    var name: String
    var pattern: String
    var adjusted: String
    var driftPill: String?

    static func adjustedAccessibilityLabel(name: String, adjusted: String, driftPill: String?) -> String {
        if let driftPill {
            return "\(name) adjusted: \(adjusted), \(driftPill) drift"
        }
        return "\(name) adjusted: \(adjusted)"
    }

    var body: some View {
        GaugeMeasurementPair(spacing: Spacing.control) {
            patternTile
        } trailing: {
            adjustedTile
        }
    }

    private var patternTile: some View {
        VStack(alignment: .center, spacing: Spacing.tight) {
            Text(name)
                .font(.satoshiCaption.weight(.semibold))
                .foregroundStyle(AppTheme.muted)
                .multilineTextAlignment(.center)
            Text(pattern)
                .font(.satoshiBody.monospaced().weight(.bold))
                .foregroundStyle(AppTheme.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.margin)
        .background(AppTheme.oatmeal)
        .clipShape(RoundedRectangle(cornerRadius: Radius.medium, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name) in pattern: \(pattern)")
    }

    private var adjustedTile: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .center, spacing: Spacing.tight) {
                Text("Adjusted")
                    .font(.satoshiCaption.weight(.semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text(adjusted)
                    .font(.satoshiBody.monospaced().weight(.bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(Spacing.margin)
            .padding(.top, driftPill != nil ? 16 : 0)

            if let pill = driftPill {
                Text(pill)
                    .font(.satoshiCaption.weight(.semibold))
                    .foregroundStyle(AppTheme.card)
                    .lineLimit(1)
                    .padding(.horizontal, Spacing.inner)
                    .padding(.top, Spacing.tight)
                    .padding(.bottom, Spacing.tight)
                    .background(AppTheme.deltaPill)
                    .clipShape(Capsule())
                    .padding(.top, Spacing.tight)
                    .padding(.trailing, Spacing.tight)
                    // Decorative drift indicator — adjacent adjusted tile
                    // carries the semantic information.
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity)
        .background(AppTheme.sage)
        .clipShape(RoundedRectangle(cornerRadius: Radius.medium, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(adjustedTileAccessibilityLabel)
    }

    private var adjustedTileAccessibilityLabel: String {
        Self.adjustedAccessibilityLabel(name: name, adjusted: adjusted, driftPill: driftPill)
    }
}
