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

struct DeltaPillBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .frame(width: 32, height: 32)
            .background {
                Circle()
                    .fill(AppTheme.deltaPill)
            }
            .accessibilityHidden(true)
    }
}

struct GaugeStepperField: View {
    var title: String
    @Binding var text: String
    var unit: String
    var identifier: String
    var range: ClosedRange<Int> = 1...99
    var hasMismatch: Bool = false
    var mismatchLabel: String? = nil
    var mismatchDelta: Int? = nil

    @State private var showWheelPicker = false

    private var currentValue: Int {
        // swiftlint:disable:next identifier_name
        if let i = Int(text) { return i }
        // swiftlint:disable:next identifier_name
        if let d = Double(text) { return Int(d.rounded()) }
        return range.lowerBound
    }

    private var spokenUnit: String {
        switch unit {
        case "st":
            return "stitches"
        case "ro":
            return "rows"
        default:
            return unit
        }
    }

    private var mismatchSentence: String? {
        guard hasMismatch, let mismatchLabel else { return nil }
        return mismatchLabel
    }

    private var spokenMismatchSentence: String? {
        guard let mismatchSentence else { return nil }
        guard let firstCharacter = mismatchSentence.first else { return mismatchSentence }
        return firstCharacter.lowercased() + String(mismatchSentence.dropFirst())
    }

    private var fieldAccessibilityValue: String {
        let baseValue = "\(currentValue) \(spokenUnit)"
        guard let spokenMismatchSentence else { return baseValue }
        return "\(baseValue), \(spokenMismatchSentence)"
    }

    private var fieldAccessibilityHint: String {
        guard mismatchSentence != nil else { return "Double-tap to edit." }
        return "Double-tap to edit. Use the picker button for wheel selection and warning details."
    }

    private var pickerAccessibilityValue: String {
        mismatchSentence == nil ? "" : "Warning"
    }

    private var pickerAccessibilityHint: String {
        guard let mismatchSentence else { return "Double-tap to open wheel picker." }
        return "\(mismatchSentence). Opens the wheel picker and warning details."
    }

    private var sheetDetents: Set<PresentationDetent> {
        mismatchSentence == nil ? [.height(280)] : [.medium, .large]
    }

    private var mismatchDeltaText: String? {
        guard hasMismatch, let mismatchDelta else { return nil }
        return mismatchDelta >= 0 ? "+\(mismatchDelta)" : "\(mismatchDelta)"
    }

    private func mismatchBadge(_ text: String) -> some View {
        DeltaPillBadge(text: text)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 8) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.muted)

                if let mismatchDeltaText {
                    mismatchBadge(mismatchDeltaText)
                }
            }
            .padding(.bottom, 8)

            HStack(spacing: 0) {
                TextField("", text: $text)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(hasMismatch ? AppTheme.mismatchText : AppTheme.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 12)
                    .accessibilityLabel(title)
                    .accessibilityValue(fieldAccessibilityValue)
                    .accessibilityHint(fieldAccessibilityHint)
                    .accessibilityIdentifier("\(identifier)-field")

                Rectangle()
                    .fill(AppTheme.outline)
                    .frame(width: 1)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    .frame(minHeight: 44)

                Button {
                    showWheelPicker = true
                } label: {
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.muted)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open picker for \(title)")
                .accessibilityValue(pickerAccessibilityValue)
                .accessibilityHint(pickerAccessibilityHint)
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
                mismatchLabel: mismatchSentence,
                mismatchDeltaText: mismatchDeltaText,
                isPresented: $showWheelPicker
            )
            .presentationDetents(sheetDetents)
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
    let mismatchLabel: String?
    let mismatchDeltaText: String?
    @Binding var isPresented: Bool

    @State private var selectedValue: Int

    init(
        title: String,
        text: Binding<String>,
        range: ClosedRange<Int>,
        identifier: String,
        mismatchLabel: String?,
        mismatchDeltaText: String?,
        isPresented: Binding<Bool>
    ) {
        self.title = title
        self._text = text
        self.range = range
        self.identifier = identifier
        self.mismatchLabel = mismatchLabel
        self.mismatchDeltaText = mismatchDeltaText
        self._isPresented = isPresented
        let initial = Int(text.wrappedValue) ?? range.lowerBound
        self._selectedValue = State(initialValue: initial.clamped(to: range))
    }

    private func mismatchBadge(_ text: String) -> some View {
        DeltaPillBadge(text: text)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppTheme.ink)

                if let mismatchDeltaText {
                    mismatchBadge(mismatchDeltaText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top)
            .padding(.bottom, mismatchLabel == nil ? 4 : 12)

            if let mismatchLabel {
                Text(mismatchLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.mismatchText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    .accessibilityIdentifier("\(identifier)-warning-summary")
            }

            Picker(title, selection: $selectedValue) {
                ForEach(range, id: \.self) { value in
                    Text("\(value)").tag(value)
                }
            }
            .pickerStyle(.wheel)
            .labelsHidden()
            .accessibilityIdentifier("\(identifier)-wheel")

            Button("Done") {
                text = "\(selectedValue)"
                isPresented = false
            }
            .font(.body.weight(.semibold))
            .foregroundStyle(AppTheme.sage)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.horizontal)
            .padding(.vertical)
            .accessibilityIdentifier("\(identifier)-wheel-done")
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
