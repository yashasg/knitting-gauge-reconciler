import SwiftUI

// MARK: - AppTheme

enum AppTheme {
    static let background = Color(red: 0.99, green: 0.98, blue: 0.96)
    static let card = Color.white
    static let oatmeal = Color(red: 0.96, green: 0.95, blue: 0.93)
    static let accentSoft = Color(red: 0.94, green: 0.91, blue: 0.86)
    static let ink = Color(red: 0.11, green: 0.11, blue: 0.10)
    static let muted = Color(red: 0.27, green: 0.28, blue: 0.26)
    static let outline = Color(red: 0.77, green: 0.78, blue: 0.75)
    static let sage = Color(red: 0.27, green: 0.33, blue: 0.26)
    static let secondary = Color(red: 0.57, green: 0.29, blue: 0.18)
    static let terracotta = Color(red: 0.73, green: 0.10, blue: 0.10)
    static let warningText = Color(red: 0.35, green: 0.26, blue: 0.09)
    static let warningBackground = Color(red: 0.96, green: 0.94, blue: 0.87)
    static let warningAccent = Color(red: 0.78, green: 0.55, blue: 0.17)
    /// Red for inline gauge mismatch indicators. Semantically "this IS different
    /// from the pattern" — distinct from warningText (warm amber, "might be wrong").
    static let mismatchText = Color(red: 0.73, green: 0.10, blue: 0.10)
    /// Cream text for use on dark backgrounds (e.g. the Calculate CTA button).
    static let cream = Color(red: 0.97, green: 0.96, blue: 0.92)
    /// Dot color for the TexturedBackground canvas. Muted at 30% opacity gives
    /// the subtle cross-stitch fabric look without visual noise.
    static let surfaceTextureDot = Color(red: 0.27, green: 0.28, blue: 0.26).opacity(0.30)
}

// MARK: - cardStyle

extension View {
    func cardStyle() -> some View {
        padding()
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .shadow(color: AppTheme.sage.opacity(0.08), radius: 34, x: 0, y: 16)
    }
}
