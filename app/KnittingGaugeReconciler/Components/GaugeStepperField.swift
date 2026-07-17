// swiftlint:disable file_length
import SwiftUI
import UIKit

func fmtGaugeDelta(_ value: Double) -> String {
    let rounded = plain(value)
    if value != 0 && Double(rounded) == 0 {
        return value > 0 ? "+<0.01" : "-<0.01"
    }
    return value >= 0 ? "+\(rounded)" : rounded
}

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
            .foregroundStyle(AppTheme.card)
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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private let title: String
    @Binding private var text: String
    private let unit: String
    private let identifier: String
    private let field: GaugeFormField
    private let validationMessage: String?
    private let validationText: String
    private let accessibilityLabel: String
    private let displayUnit: MeasurementUnit?
    private let focusedField: Binding<GaugeFormField?>
    private let onSubmit: () -> Void
    private let range: ClosedRange<Int>
    private let hasMismatch: Bool
    private let mismatchLabel: String?
    private let mismatchDelta: Double?

    @State private var showWheelPicker = false

    static func pickerAccessibilityLabel(for fieldLabel: String) -> String {
        "Open picker for \(fieldLabel)"
    }

    init(
        title: String,
        text: Binding<String>,
        unit: String,
        identifier: String,
        field: GaugeFormField,
        validationMessage: String?,
        validationText: String? = nil,
        accessibilityLabel: String? = nil,
        displayUnit: MeasurementUnit? = nil,
        focusedField: Binding<GaugeFormField?>,
        onSubmit: @escaping () -> Void,
        range: ClosedRange<Int> = 1...99,
        hasMismatch: Bool = false,
        mismatchLabel: String? = nil,
        mismatchDelta: Double? = nil
    ) {
        self.title = title
        self._text = text
        self.unit = unit
        self.identifier = identifier
        self.field = field
        self.validationMessage = validationMessage
        self.validationText = validationText ?? text.wrappedValue
        self.accessibilityLabel = accessibilityLabel ?? title
        self.displayUnit = displayUnit
        self.focusedField = focusedField
        self.onSubmit = onSubmit
        self.range = range
        self.hasMismatch = hasMismatch
        self.mismatchLabel = mismatchLabel
        self.mismatchDelta = mismatchDelta
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
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        var parts = [trimmed.isEmpty ? "Empty" : "\(trimmed) \(spokenUnit)"]
        if let spokenMismatchSentence {
            parts.append(spokenMismatchSentence)
        }
        if let mismatchDeltaText {
            parts.append(mismatchDeltaText)
        }
        if let validationMessage {
            parts.append(validationMessage)
        }
        return parts.joined(separator: ", ")
    }

    private var fieldAccessibilityHint: String {
        if validationMessage != nil {
            return "Correct this value before viewing results."
        }
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
        Self.sheetDetents(
            for: dynamicTypeSize,
            hasWarning: mismatchSentence != nil
        )
    }

    static func sheetDetents(
        for dynamicTypeSize: DynamicTypeSize,
        hasWarning: Bool
    ) -> Set<PresentationDetent> {
        if dynamicTypeSize.isAccessibilitySize {
            return [.large]
        }
        if hasWarning {
            return [.medium, .large]
        }
        return [.height(280)]
    }

    private var mismatchDeltaText: String? {
        guard hasMismatch, let mismatchDelta else { return nil }
        return fmtGaugeDelta(mismatchDelta)
    }

    private func mismatchBadge(_ text: String) -> some View {
        DeltaPillBadge(text: text)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.muted)

                        if let mismatchDeltaText {
                            mismatchBadge(mismatchDeltaText)
                        }
                    }
                } else {
                    HStack(alignment: .center, spacing: 8) {
                        Text(title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.muted)

                        if let mismatchDeltaText {
                            mismatchBadge(mismatchDeltaText)
                        }
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
                GaugeKeyboardTextField(
                    text: $text,
                    field: field,
                    focusedField: focusedField,
                    label: accessibilityLabel,
                    value: fieldAccessibilityValue,
                    hint: fieldAccessibilityHint,
                    identifier: "\(identifier)-field",
                    showsCorrection: hasMismatch || validationMessage != nil,
                    onSubmit: onSubmit
                )
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 12)

                Rectangle()
                    .fill(AppTheme.outline)
                    .frame(width: 1)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    .frame(minHeight: 44)

                Button {
                    focusedField.wrappedValue = nil
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil,
                        from: nil,
                        for: nil
                    )
                    showWheelPicker = true
                } label: {
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.muted)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Self.pickerAccessibilityLabel(for: accessibilityLabel))
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
                        (hasMismatch || validationMessage != nil
                            ? AppTheme.mismatchText
                            : AppTheme.muted).opacity(0.7),
                        lineWidth: 1.5
                    )
            )
            // Expose the entire field container as a single accessibility node
            // so UI tests can locate the field by its bare identifier
            // (`app.otherElements[identifier]`). The visible TextField + chevron
            // retain their own child identifiers for tap-targeted interaction.
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(identifier)

            if let validationMessage {
                Text(validationMessage)
                    .font(.caption)
                    .foregroundStyle(AppTheme.mismatchText)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("\(identifier)-error")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sheet(isPresented: $showWheelPicker) {
            GaugeStepperWheelSheet(
                title: title,
                text: $text,
                range: range,
                identifier: identifier,
                validationText: validationText,
                field: field,
                accessibilityLabel: accessibilityLabel,
                displayUnit: displayUnit,
                mismatchLabel: mismatchSentence,
                mismatchDeltaText: mismatchDeltaText,
                isPresented: $showWheelPicker
            )
            .presentationDetents(sheetDetents)
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - GaugeKeyboardTextField

private struct GaugeKeyboardTextField: UIViewRepresentable {
    @Binding private var text: String

    private let field: GaugeFormField
    private let focusedField: Binding<GaugeFormField?>
    private let label: String
    private let value: String
    private let hint: String
    private let identifier: String
    private let showsCorrection: Bool
    private let onSubmit: () -> Void

    init(
        text: Binding<String>,
        field: GaugeFormField,
        focusedField: Binding<GaugeFormField?>,
        label: String,
        value: String,
        hint: String,
        identifier: String,
        showsCorrection: Bool,
        onSubmit: @escaping () -> Void
    ) {
        self._text = text
        self.field = field
        self.focusedField = focusedField
        self.label = label
        self.value = value
        self.hint = hint
        self.identifier = identifier
        self.showsCorrection = showsCorrection
        self.onSubmit = onSubmit
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.keyboardType = .decimalPad
        textField.textAlignment = .center
        textField.borderStyle = .none
        textField.adjustsFontForContentSizeCategory = true
        let preferredFont = UIFont.preferredFont(forTextStyle: .title2)
        let descriptor = preferredFont.fontDescriptor.addingAttributes([
            .traits: [UIFontDescriptor.TraitKey.weight: UIFont.Weight.semibold]
        ])
        textField.font = UIFont(descriptor: descriptor, size: 0)
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.addTarget(
            context.coordinator,
            action: #selector(Coordinator.textDidChange(_:)),
            for: .editingChanged
        )

        let toolbar = UIToolbar()
        toolbar.autoresizingMask = [.flexibleWidth]
        let done = UIBarButtonItem(
            title: "Done",
            style: .done,
            target: context.coordinator,
            action: #selector(Coordinator.didTapDone)
        )
        done.accessibilityIdentifier = "keyboard-done"
        toolbar.items = [done]
        toolbar.sizeToFit()
        textField.inputAccessoryView = toolbar
        return textField
    }

    func updateUIView(_ textField: UITextField, context: Context) {
        context.coordinator.parent = self
        if textField.text != text {
            textField.text = text
        }
        textField.textColor = UIColor(showsCorrection ? AppTheme.mismatchText : AppTheme.ink)
        textField.accessibilityLabel = label
        textField.accessibilityValue = value
        textField.accessibilityHint = hint
        textField.accessibilityIdentifier = identifier

        let coordinator = context.coordinator
        let shouldFocus = focusedField.wrappedValue == field
        guard shouldFocus != textField.isFirstResponder,
              !coordinator.focusUpdateScheduled else { return }
        coordinator.focusUpdateScheduled = true
        Task { @MainActor in
            defer { coordinator.focusUpdateScheduled = false }
            let shouldFocus = coordinator.parent.focusedField.wrappedValue == coordinator.parent.field
            guard shouldFocus != textField.isFirstResponder else { return }
            if shouldFocus {
                textField.becomeFirstResponder()
            } else {
                textField.resignFirstResponder()
            }
        }
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: GaugeKeyboardTextField
        var focusUpdateScheduled = false

        init(parent: GaugeKeyboardTextField) {
            self.parent = parent
        }

        @objc func textDidChange(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            if parent.focusedField.wrappedValue != parent.field {
                parent.focusedField.wrappedValue = parent.field
            }
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            if parent.focusedField.wrappedValue == parent.field {
                parent.focusedField.wrappedValue = nil
            }
        }

        @objc func didTapDone() {
            parent.onSubmit()
        }
    }
}

// MARK: - GaugeStepperWheelSheet

private struct GaugeStepperWheelSheet: View {
    let title: String
    @Binding private var text: String
    let range: ClosedRange<Int>
    let identifier: String
    let validationText: String
    let field: GaugeFormField
    let accessibilityLabel: String
    let displayUnit: MeasurementUnit?
    let mismatchLabel: String?
    let mismatchDeltaText: String?
    @Binding private var isPresented: Bool

    @State private var selectedValue: Int

    init(
        title: String,
        text: Binding<String>,
        range: ClosedRange<Int>,
        identifier: String,
        validationText: String,
        field: GaugeFormField,
        accessibilityLabel: String,
        displayUnit: MeasurementUnit?,
        mismatchLabel: String?,
        mismatchDeltaText: String?,
        isPresented: Binding<Bool>
    ) {
        self.title = title
        self._text = text
        self.range = range
        self.identifier = identifier
        self.validationText = validationText
        self.field = field
        self.accessibilityLabel = accessibilityLabel
        self.displayUnit = displayUnit
        self.mismatchLabel = mismatchLabel
        self.mismatchDeltaText = mismatchDeltaText
        self._isPresented = isPresented
        let rounded: Int?
        switch GaugeMath.validate(validationText, for: field.mathField) {
        case .success(let value?):
            rounded = displayUnit?.cmToDisplayInt(value) ?? Int(value.rounded())
        case .success(nil), .failure:
            rounded = nil
        }
        let initial = rounded.flatMap { range.contains($0) ? $0 : nil } ?? range.lowerBound
        self._selectedValue = State(initialValue: initial)
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
            .accessibilityLabel(accessibilityLabel)
            .accessibilityIdentifier("\(identifier)-wheel")

            Button("Done") {
                text = "\(selectedValue)"
                isPresented = false
            }
            .font(.body.weight(.semibold))
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.horizontal)
            .padding(.vertical)
            .accessibilityIdentifier("\(identifier)-wheel-done")
        }
        .background(AppTheme.card)
    }
}
