import SwiftUI

// MARK: - StepCircle

struct StepCircle: View {
    var number: Int

    @ScaledMetric(relativeTo: .caption) private var size: CGFloat = 24

    var body: some View {
        ZStack {
            Circle()
                .fill(AppTheme.secondary)
            Text("\(number)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
