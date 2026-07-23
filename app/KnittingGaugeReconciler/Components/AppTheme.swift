import SwiftUI

private final class AppResourceBundleToken {}

let appResourceBundle = Bundle(for: AppResourceBundleToken.self)

// MARK: - AppTheme

enum AppTheme {
    struct ContrastPair: Equatable {
        let foreground: String
        let background: String
        let minimumRatio: Double
    }

    static let textContrastPairs = [
        ContrastPair(
            foreground: "app-theme-ink",
            background: "app-theme-background",
            minimumRatio: 4.5
        ),
        ContrastPair(
            foreground: "app-theme-muted",
            background: "app-theme-card",
            minimumRatio: 4.5
        ),
        ContrastPair(
            foreground: "app-theme-warning-text",
            background: "app-theme-warning-background",
            minimumRatio: 4.5
        ),
        ContrastPair(
            foreground: "app-theme-cream",
            background: "app-theme-sage",
            minimumRatio: 4.5
        ),
        ContrastPair(
            foreground: "app-theme-muted",
            background: "app-theme-accent-soft",
            minimumRatio: 4.5
        ),
    ]

    static let background       = Color("app-theme-background", bundle: appResourceBundle)
    static let card             = Color("app-theme-card", bundle: appResourceBundle)
    static let oatmeal          = Color("app-theme-oatmeal", bundle: appResourceBundle)
    static let accentSoft       = Color("app-theme-accent-soft", bundle: appResourceBundle)
    static let ink              = Color("app-theme-ink", bundle: appResourceBundle)
    static let muted            = Color("app-theme-muted", bundle: appResourceBundle)
    static let outline          = Color("app-theme-outline", bundle: appResourceBundle)
    static let sage             = Color("app-theme-sage", bundle: appResourceBundle)
    static let secondary        = Color("app-theme-secondary", bundle: appResourceBundle)
    static let terracotta       = Color("app-theme-terracotta", bundle: appResourceBundle)
    static let warningText      = Color("app-theme-warning-text", bundle: appResourceBundle)
    static let warningBackground = Color("app-theme-warning-background", bundle: appResourceBundle)
    static let warningAccent    = Color("app-theme-warning-accent", bundle: appResourceBundle)
    /// Red for inline gauge mismatch indicators. Semantically "this IS different
    /// from the pattern" — distinct from warningText (warm amber, "might be wrong").
    static let mismatchText     = Color("app-theme-mismatch-text", bundle: appResourceBundle)
    /// Cream text for use on dark backgrounds (e.g. the Calculate CTA button).
    static let cream            = Color("app-theme-cream", bundle: appResourceBundle)
    static let deltaPill        = ink
    /// Dot color for the TexturedBackground canvas. Alpha baked into Color Set
    /// (0.30 light / 0.10 dark) — gives the subtle cross-stitch fabric look
    /// without visual noise, and recedes further on dark surfaces.
    static let surfaceTextureDot = Color(
        "app-theme-surface-texture-dot",
        bundle: appResourceBundle
    )
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
