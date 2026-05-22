import SwiftUI

// MARK: - ShareSheetPayload

struct ShareSheetPayload: Identifiable {
    let id = UUID()
    var items: [Any]
}

// MARK: - AdjustmentRow

// Tile-based layout matching AdjustmentValuePair chrome:
// left oatmeal tile (pattern), right sage tile (adjusted).

struct AdjustmentRow: View {
    var name: String
    var pattern: String
    var adjusted: String
    var adjustedIdentifier: String?
    var driftPill: String?

    private var defaultAdjustedID: String {
        "adjustment-\(name.lowercased().replacingOccurrences(of: " ", with: "-"))-value"
    }

    var body: some View {
        GaugeMeasurementPair(spacing: 10) {
            patternTile
        } trailing: {
            adjustedTile
        }
    }

    private var patternTile: some View {
        VStack(alignment: .center, spacing: 4) {
            Text(name)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.muted)
                .multilineTextAlignment(.center)
            Text(pattern)
                .font(.system(.body, design: .monospaced).weight(.bold))
                .foregroundStyle(AppTheme.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(AppTheme.oatmeal)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name) in pattern: \(pattern)")
    }

    private var adjustedTile: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .center, spacing: 4) {
                Text("Adjusted")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                Text(adjusted)
                    .font(.system(.body, design: .monospaced).weight(.bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(14)
            .padding(.top, driftPill != nil ? 8 : 0)
            .background(AppTheme.sage)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            if let pill = driftPill {
                Text(pill)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .padding(.top, 4)
                    .padding(.bottom, 4)
                    .background(AppTheme.secondary)
                    .clipShape(Capsule())
                    .offset(x: -4, y: -8)
                    // Decorative drift indicator — adjacent adjusted tile
                    // carries the semantic information. Hide from VoiceOver
                    // and clamp Dynamic Type so it doesn't outgrow the tile.
                    .accessibilityHidden(true)
                    .accessibilityIdentifier("drift-pill")
                    .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(adjustedTileAccessibilityLabel)
        .accessibilityIdentifier(adjustedIdentifier ?? defaultAdjustedID)
    }

    private var adjustedTileAccessibilityLabel: String {
        if let pill = driftPill {
            return "\(name) adjusted: \(adjusted), \(pill) drift"
        }
        return "\(name) adjusted: \(adjusted)"
    }
}
