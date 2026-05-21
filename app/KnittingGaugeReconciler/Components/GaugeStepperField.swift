import SwiftUI

// MARK: - GaugeStepperField
// Unified capsule: [−  value  +] — one pill, no separate button backgrounds.
// The minus/plus icons sit inside the same capsule as the value; tapping the
// value opens the number pad for direct keyboard entry.
// Unit suffix intentionally omitted — labels above each field communicate units.

struct GaugeStepperField: View {
    var title: String
    @Binding var text: String
    var unit: String
    var identifier: String
    var range: ClosedRange<Int> = 1...99
    var hasMismatch: Bool = false
    var mismatchLabel: String? = nil

    private var currentValue: Int {
        if let i = Int(text) { return i }
        if let d = Double(text) { return Int(d.rounded()) }
        return range.lowerBound
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.muted)

            HStack(spacing: 0) {
                Button {
                    text = "\(max(range.lowerBound, currentValue - 1))"
                } label: {
                    Image(systemName: "minus")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppTheme.ink)
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Decrease \(title)")
                .accessibilityIdentifier("\(identifier)-minus")

                Spacer()

                TextField("", text: $text)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(hasMismatch ? AppTheme.mismatchText : AppTheme.ink)
                    .fixedSize()
                    .frame(minWidth: 44)
                    .accessibilityIdentifier("\(identifier)-field")

                Spacer()

                Button {
                    text = "\(min(range.upperBound, currentValue + 1))"
                } label: {
                    Image(systemName: "plus")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppTheme.ink)
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Increase \(title)")
                .accessibilityIdentifier(identifier)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .frame(minHeight: 44)
            .background(AppTheme.oatmeal)
            .clipShape(Capsule())

            if let mismatchLabel, hasMismatch {
                Text(mismatchLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AppTheme.mismatchText)
                    .accessibilityIdentifier("\(identifier)-mismatch")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
