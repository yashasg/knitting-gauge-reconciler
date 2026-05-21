import SwiftUI

// MARK: - StepCircle

struct StepCircle: View {
    var number: Int

    var body: some View {
        ZStack {
            Circle()
                .fill(AppTheme.secondary)
            Text("\(number)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
        }
        .frame(width: 24, height: 24)
        .accessibilityHidden(true)
    }
}
