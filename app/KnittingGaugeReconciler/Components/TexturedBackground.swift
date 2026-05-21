import SwiftUI

// MARK: - TexturedBackground
// Canvas-based dot grid that renders behind all cards. Spacing and dot size are
// tuned to look like cross-stitch fabric without being noisy. Color is
// AppTheme.surfaceTextureDot (muted at 30% opacity).

struct TexturedBackground: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 14
            let dotRadius: CGFloat = 1.2
            let cols = Int(size.width / spacing) + 2
            let rows = Int(size.height / spacing) + 2
            for row in 0...rows {
                for col in 0...cols {
                    let x = CGFloat(col) * spacing
                    let y = CGFloat(row) * spacing
                    let rect = CGRect(
                        x: x - dotRadius, y: y - dotRadius,
                        width: dotRadius * 2, height: dotRadius * 2
                    )
                    context.fill(Path(ellipseIn: rect), with: .color(AppTheme.surfaceTextureDot))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
