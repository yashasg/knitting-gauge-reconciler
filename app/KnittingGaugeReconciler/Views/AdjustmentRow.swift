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
    var adjustedIdentifier: String?
    var driftPill: String?

    static func defaultAdjustedIdentifier(name: String) -> String {
        "adjustment-\(name.lowercased().replacingOccurrences(of: " ", with: "-"))-value"
    }

    static func adjustedAccessibilityLabel(name: String, adjusted: String, driftPill: String?) -> String {
        if let driftPill {
            return "\(name) adjusted: \(adjusted), \(driftPill) drift"
        }
        return "\(name) adjusted: \(adjusted)"
    }

    private var defaultAdjustedID: String {
        Self.defaultAdjustedIdentifier(name: name)
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
                    .foregroundStyle(.white)
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
                    .foregroundStyle(AppTheme.card)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .padding(.top, 4)
                    .padding(.bottom, 4)
                    .background(AppTheme.deltaPill)
                    .clipShape(Capsule())
                    .offset(x: -4, y: -8)
                    // Decorative drift indicator — adjacent adjusted tile
                    // carries the semantic information.
                    .accessibilityHidden(true)
                    .accessibilityIdentifier("drift-pill")
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(adjustedTileAccessibilityLabel)
        .accessibilityIdentifier(adjustedIdentifier ?? defaultAdjustedID)
    }

    private var adjustedTileAccessibilityLabel: String {
        Self.adjustedAccessibilityLabel(name: name, adjusted: adjusted, driftPill: driftPill)
    }
}
