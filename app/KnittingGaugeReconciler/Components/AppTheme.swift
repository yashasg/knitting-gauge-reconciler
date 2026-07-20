import SwiftUI

// MARK: - AppTheme

enum AppTheme {
    private static let bundle = Bundle(for: MetricsSubscriber.self)

    static let background       = Color("app-theme-background", bundle: bundle)
    static let card             = Color("app-theme-card", bundle: bundle)
    static let oatmeal          = Color("app-theme-oatmeal", bundle: bundle)
    static let accentSoft       = Color("app-theme-accent-soft", bundle: bundle)
    static let ink              = Color("app-theme-ink", bundle: bundle)
    static let muted            = Color("app-theme-muted", bundle: bundle)
    static let outline          = Color("app-theme-outline", bundle: bundle)
    static let sage             = Color("app-theme-sage", bundle: bundle)
    static let secondary        = Color("app-theme-secondary", bundle: bundle)
    static let terracotta       = Color("app-theme-terracotta", bundle: bundle)
    static let warningText      = Color("app-theme-warning-text", bundle: bundle)
    static let warningBackground = Color("app-theme-warning-background", bundle: bundle)
    static let warningAccent    = Color("app-theme-warning-accent", bundle: bundle)
    /// Red for inline gauge mismatch indicators. Semantically "this IS different
    /// from the pattern" — distinct from warningText (warm amber, "might be wrong").
    static let mismatchText     = Color("app-theme-mismatch-text", bundle: bundle)
    /// Cream text for use on dark backgrounds (e.g. the Calculate CTA button).
    static let cream            = Color("app-theme-cream", bundle: bundle)
    static let deltaPill        = ink
    /// Dot color for the TexturedBackground canvas. Alpha baked into Color Set
    /// (0.30 light / 0.10 dark) — gives the subtle cross-stitch fabric look
    /// without visual noise, and recedes further on dark surfaces.
    static let surfaceTextureDot = Color("app-theme-surface-texture-dot", bundle: bundle)
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
