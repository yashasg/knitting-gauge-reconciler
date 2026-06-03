import SwiftUI

// MARK: - GaugeStepperField
// Outlined rounded container: [ value · · · · | ⇅ ]
// Tap the value/text area → numeric keyboard opens (direct entry).
// Tap the chevron (⇅) → wheel picker sheet opens.
// Unit suffix intentionally omitted — labels above each field communicate units.

struct DeltaPillBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 8)
            .padding(EdgeInsets(top: 3, leading: 0, bottom: 3, trailing: 0))
            .background(AppTheme.deltaPill)
            .clipShape(Capsule())
            // Pill is purely decorative — adjacent value tile carries the
            // semantic value (e.g. "Knit 64 rows, +16 from pattern").
            .accessibilityHidden(true)
            .accessibilityIdentifier("delta-pill")
    }
}

struct GaugeStepperField: View {
    var title: String
    @Binding var text: String
    var unit: String
    var identifier: String
    var range: ClosedRange<Int> = 1...99
    var hasMismatch: Bool = false
    var mismatchLabel: String?
    var mismatchDelta: Int?

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
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: 8) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.muted)

                    if let mismatchDeltaText {
                        mismatchBadge(mismatchDeltaText)
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.muted)

                    if let mismatchDeltaText {
                        mismatchBadge(mismatchDeltaText)
                    }
                }
            }
            // Pin the title row height so the delta pill (caption2 + capsule
            // padding) cannot push the field downward when mismatch toggles.
            // Both states (with and without pill) now occupy identical vertical
            // space, keeping the Calculate button anchored. See GitLab #35.
            .frame(minHeight: 22, alignment: .leading)
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
            // Expose the entire field container as a single accessibility node
            // so UI tests can locate the field by its bare identifier
            // (`app.otherElements[identifier]`). The visible TextField + chevron
            // retain their own child identifiers for tap-targeted interaction.
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(identifier)
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
