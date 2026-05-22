import SwiftUI

// MARK: - AppTheme

enum AppTheme {
    static let background       = Color("app-theme-background")
    static let card             = Color("app-theme-card")
    static let oatmeal          = Color("app-theme-oatmeal")
    static let accentSoft       = Color("app-theme-accent-soft")
    static let ink              = Color("app-theme-ink")
    static let muted            = Color("app-theme-muted")
    static let outline          = Color("app-theme-outline")
    static let sage             = Color("app-theme-sage")
    static let secondary        = Color("app-theme-secondary")
    static let terracotta       = Color("app-theme-terracotta")
    static let warningText      = Color("app-theme-warning-text")
    static let warningBackground = Color("app-theme-warning-background")
    static let warningAccent    = Color("app-theme-warning-accent")
    /// Red for inline gauge mismatch indicators. Semantically "this IS different
    /// from the pattern" — distinct from warningText (warm amber, "might be wrong").
    static let mismatchText     = Color("app-theme-mismatch-text")
    /// Cream text for use on dark backgrounds (e.g. the Calculate CTA button).
    static let cream            = Color("app-theme-cream")
    /// Dot color for the TexturedBackground canvas. Alpha baked into Color Set
    /// (0.30 light / 0.10 dark) — gives the subtle cross-stitch fabric look
    /// without visual noise, and recedes further on dark surfaces.
    static let surfaceTextureDot = Color("app-theme-surface-texture-dot")
}

// MARK: - cardStyle

extension View {
    func cardStyle() -> some View {
        padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .shadow(color: AppTheme.sage.opacity(0.08), radius: 34, x: 0, y: 16)
    }
}
