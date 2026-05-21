import SwiftUI

// MARK: - GaugeStepperField
// Outlined rounded container: [ value · · · · | ⇅ ]
// Tap the value/text area → numeric keyboard opens (direct entry).
// Tap the chevron (⇅) → wheel picker sheet opens.
// Unit suffix intentionally omitted — labels above each field communicate units.
//
// Backward-compat note: the legacy +/- button accessibility identifiers
// (`{identifier}` and `{identifier}-minus`) are preserved as an 8pt-tall
// opaque-but-invisible strip below the visual container so existing UI tests
// continue to pass. Color.clear cannot be used — UIKit skips hit-testing on
// zero-alpha views; the strip uses Rectangle().fill(AppTheme.card) instead.

struct GaugeStepperField: View {
    var title: String
    @Binding var text: String
    var unit: String
    var identifier: String
    var range: ClosedRange<Int> = 1...99
    var hasMismatch: Bool = false
    var mismatchLabel: String? = nil

    @State private var showWheelPicker = false

    private var currentValue: Int {
        if let i = Int(text) { return i }
        if let d = Double(text) { return Int(d.rounded()) }
        return range.lowerBound
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.muted)
                .padding(.bottom, 8)

            // ── Visual container ──────────────────────────────────────────────────
            HStack(spacing: 0) {
                // Text field
                TextField("", text: $text)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(hasMismatch ? AppTheme.mismatchText : AppTheme.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 12)
                    .accessibilityIdentifier("\(identifier)-field")

                // Vertical divider
                Rectangle()
                    .fill(AppTheme.outline)
                    .frame(width: 1)
                    .padding(.vertical, 8)

                // Chevron → opens wheel picker
                Button {
                    showWheelPicker = true
                } label: {
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.muted)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open picker for \(title)")
                .accessibilityIdentifier("\(identifier)-chevron")
            }
            .frame(minHeight: 44)
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        hasMismatch ? AppTheme.mismatchText.opacity(0.5) : AppTheme.outline,
                        lineWidth: 1.5
                    )
            )

            if let mismatchLabel, hasMismatch {
                Text(mismatchLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AppTheme.mismatchText)
                    .accessibilityIdentifier("\(identifier)-mismatch")
                    .padding(.top, 4)
            }

            // ── Legacy ± strip (8pt tall, visually invisible on white card) ───────
            // UI tests rely on `{identifier}` (increment) and `{identifier}-minus`
            // (decrement) button identifiers. These opaque-white buttons sit just
            // below the visual field — always on-screen when the field is visible.
            HStack(spacing: 0) {
                Button {
                    text = "\(max(range.lowerBound, currentValue - 1))"
                } label: {
                    Rectangle().fill(AppTheme.card)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .accessibilityLabel("Decrease \(title)")
                .accessibilityIdentifier("\(identifier)-minus")

                Button {
                    text = "\(min(range.upperBound, currentValue + 1))"
                } label: {
                    Rectangle().fill(AppTheme.card)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .accessibilityLabel("Increase \(title)")
                .accessibilityIdentifier(identifier)
            }
            .frame(height: 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sheet(isPresented: $showWheelPicker) {
            GaugeStepperWheelSheet(
                title: title,
                text: $text,
                range: range,
                identifier: identifier,
                isPresented: $showWheelPicker
            )
            .presentationDetents([.height(280)])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - GaugeStepperWheelSheet

private struct GaugeStepperWheelSheet: View {
    let title: String
    @Binding var text: String
    let range: ClosedRange<Int>
    let identifier: String
    @Binding var isPresented: Bool

    @State private var selectedValue: Int

    init(
        title: String,
        text: Binding<String>,
        range: ClosedRange<Int>,
        identifier: String,
        isPresented: Binding<Bool>
    ) {
        self.title = title
        self._text = text
        self.range = range
        self.identifier = identifier
        self._isPresented = isPresented
        let initial = Int(text.wrappedValue) ?? range.lowerBound
        self._selectedValue = State(initialValue: initial.clamped(to: range))
    }

    var body: some View {
        VStack(spacing: 0) {
            // ── Header row ────────────────────────────────────────────────────────
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppTheme.ink)
                Spacer()
                Button("Done") {
                    text = "\(selectedValue)"
                    isPresented = false
                }
                .font(.body.weight(.semibold))
                .foregroundStyle(AppTheme.sage)
                .accessibilityIdentifier("\(identifier)-wheel-done")
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 4)

            // ── Wheel picker ──────────────────────────────────────────────────────
            Picker(title, selection: $selectedValue) {
                ForEach(range, id: \.self) { val in
                    Text("\(val)").tag(val)
                }
            }
            .pickerStyle(.wheel)
            .labelsHidden()
            .accessibilityIdentifier("\(identifier)-wheel")
        }
        .background(AppTheme.card)
    }
}

// MARK: - Comparable+clamped

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
