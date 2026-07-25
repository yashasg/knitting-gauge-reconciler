import SwiftUI
import UIKit

func fmtGaugeDelta(_ value: Double) -> String {
    let rounded = plain(value)
    if value != 0 && Double(rounded) == 0 {
        return value > 0 ? "+<0.01" : "-<0.01"
    }
    return value >= 0 ? "+\(rounded)" : rounded
}

struct DeltaPillBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.satoshiCaption2.weight(.semibold))
            .foregroundStyle(AppTheme.cream)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, Spacing.inner)
            .padding(.vertical, Spacing.tight)
            .background(AppTheme.sage)
            .clipShape(Capsule())
            .accessibilityHidden(true)
    }
}

struct GaugeInputAccessibilityContract: Equatable {
    let fieldValue: String
    let fieldHint: String
}

struct SheetContentProvider<Content: View> {
    let content: Content
    func contentView() -> Content { content }
}

struct GaugeInputField: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var controlMinimumHeight =
        Sizing.minimumTouchTarget

    private let title: String
    @Binding private var text: String
    private let unit: String
    private let field: GaugeFormField
    private let validationMessage: String?
    private let validationText: String
    private let accessibilityLabel: String
    private let focusedField: Binding<GaugeFormField?>
    private let range: ClosedRange<Double>
    private let hasMismatch: Bool
    private let mismatchLabel: String?
    private let mismatchDelta: Double?

    static func accessibilityContract(
        text: String,
        unit: String,
        isRequired: Bool = false,
        validationMessage: String? = nil,
        mismatchLabel: String? = nil,
        mismatchDelta: Double? = nil
    ) -> GaugeInputAccessibilityContract {
        let spokenUnit: String
        switch unit {
        case "st":
            spokenUnit = "stitches"
        case "ro":
            spokenUnit = "rows"
        default:
            spokenUnit = unit
        }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        var valueParts = [trimmed.isEmpty ? "Empty" : "\(trimmed) \(spokenUnit)"]
        if isRequired {
            valueParts.append("Required")
        }
        if let mismatchLabel, let firstCharacter = mismatchLabel.first {
            valueParts.append(firstCharacter.lowercased() + String(mismatchLabel.dropFirst()))
        }
        if let mismatchDelta {
            valueParts.append(fmtGaugeDelta(mismatchDelta))
        }
        if let validationMessage, !(isRequired && trimmed.isEmpty) {
            valueParts.append(validationMessage)
        }
        return GaugeInputAccessibilityContract(
            fieldValue: valueParts.joined(separator: ", "),
            fieldHint: validationMessage == nil
                ? "Double-tap to edit."
                : "Correct this value before viewing results."
        )
    }

    init(
        title: String,
        text: Binding<String>,
        unit: String,
        field: GaugeFormField,
        validationMessage: String?,
        validationText: String? = nil,
        accessibilityLabel: String? = nil,
        focusedField: Binding<GaugeFormField?>,
        range: ClosedRange<Double> = 1...99,
        hasMismatch: Bool = false,
        mismatchLabel: String? = nil,
        mismatchDelta: Double? = nil
    ) {
        self.title = title
        self._text = text
        self.unit = unit
        self.field = field
        self.validationMessage = validationMessage
        self.validationText = validationText ?? text.wrappedValue
        self.accessibilityLabel = accessibilityLabel ?? title
        self.focusedField = focusedField
        self.range = range
        self.hasMismatch = hasMismatch
        self.mismatchLabel = mismatchLabel
        self.mismatchDelta = mismatchDelta
    }

    private var accessibilityContract: GaugeInputAccessibilityContract {
        Self.accessibilityContract(
            text: text,
            unit: unit,
            isRequired: field.isRequired,
            validationMessage: validationMessage,
            mismatchLabel: hasMismatch ? mismatchLabel : nil,
            mismatchDelta: hasMismatch ? mismatchDelta : nil
        )
    }

    private var mismatchDeltaText: String? {
        guard hasMismatch, let mismatchDelta else { return nil }
        return fmtGaugeDelta(mismatchDelta)
    }

    private var visibleValidationMessage: String? {
        guard let validationMessage else { return nil }
        guard case .failure(.required) = GaugeMath.validate(validationText, for: field.mathField) else {
            return validationMessage
        }
        return "Required"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    stackedLabel
                } else {
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .center, spacing: Spacing.inner) {
                            fieldLabel
                            if let mismatchDeltaText {
                                DeltaPillBadge(text: mismatchDeltaText)
                            }
                        }
                        stackedLabel
                    }
                }
            }
            .frame(minHeight: Sizing.fieldLabelMinimumHeight, alignment: .leading)
            .padding(.bottom, Spacing.inner)

            GaugeKeyboardTextField(
                text: $text,
                field: field,
                focusedField: focusedField,
                label: accessibilityLabel,
                value: accessibilityContract.fieldValue,
                hint: accessibilityContract.fieldHint,
                showsCorrection: validationMessage != nil,
                range: range
            )
            .frame(maxWidth: .infinity, minHeight: controlMinimumHeight)
            .padding(.horizontal, Spacing.control)
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: Radius.small, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.small, style: .continuous)
                    .stroke(
                        (validationMessage != nil
                            ? AppTheme.mismatchText
                            : AppTheme.muted).opacity(0.7),
                        lineWidth: 1.5
                    )
            )

            Label(
                visibleValidationMessage ?? " ",
                systemImage: "exclamationmark.circle.fill"
            )
            .font(.satoshiCaption)
            .imageScale(.small)
            .foregroundStyle(AppTheme.mismatchText)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, Spacing.compact)
            .frame(maxWidth: .infinity, alignment: .leading)
            .opacity(visibleValidationMessage == nil ? 0 : 1)
            .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var fieldLabel: some View {
        Text(title)
            .font(.satoshiSubheadline.weight(.semibold))
            .foregroundStyle(AppTheme.muted)
            .fixedSize(horizontal: !dynamicTypeSize.isAccessibilitySize, vertical: true)
    }

    private var stackedLabel: some View {
        VStack(alignment: .leading, spacing: Spacing.tight) {
            fieldLabel
            if let mismatchDeltaText {
                DeltaPillBadge(text: mismatchDeltaText)
            }
        }
    }
}

struct GaugeKeyboardTextField: UIViewRepresentable {
    @Binding private var text: String

    private let field: GaugeFormField
    private let focusedField: Binding<GaugeFormField?>
    private let label: String
    private let value: String
    private let hint: String
    private let showsCorrection: Bool
    private let range: ClosedRange<Double>

    init(
        text: Binding<String>,
        field: GaugeFormField,
        focusedField: Binding<GaugeFormField?>,
        label: String,
        value: String,
        hint: String,
        showsCorrection: Bool,
        range: ClosedRange<Double> = 1...99
    ) {
        self._text = text
        self.field = field
        self.focusedField = focusedField
        self.label = label
        self.value = value
        self.hint = hint
        self.showsCorrection = showsCorrection
        self.range = range
    }

    static func keyboardType(for field: GaugeFormField) -> UIKeyboardType {
        switch field {
        case .patternCastOn, .patternIncreases:
            .numberPad
        default:
            .decimalPad
        }
    }

    static func permitsChange(
        currentText: String,
        range: NSRange,
        replacement: String,
        upperBound: Double,
        locale: Locale = .current
    ) -> Bool {
        guard let stringRange = Range(range, in: currentText) else { return false }
        let proposedText = currentText.replacingCharacters(in: stringRange, with: replacement)
        guard let proposedValue = GaugeMath.parsedNumber(proposedText, locale: locale) else {
            return true
        }
        return proposedValue <= upperBound
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.keyboardType = Self.keyboardType(for: field)
        textField.textAlignment = .center
        textField.borderStyle = .none
        textField.adjustsFontForContentSizeCategory = true
        textField.font = SatoshiVariableFont.scaledFont(
            size: 22,
            textStyle: .title2,
            weight: .semibold
        )
        textField.addTarget(
            context.coordinator,
            action: #selector(Coordinator.textDidChange(_:)),
            for: .editingChanged
        )
        context.coordinator.textField = textField

        let toolbar = UIToolbar()
        toolbar.autoresizingMask = [.flexibleWidth]
        toolbar.items = [
            UIBarButtonItem(
                barButtonSystemItem: .flexibleSpace,
                target: nil,
                action: nil
            ),
            UIBarButtonItem(
                barButtonSystemItem: .done,
                target: context.coordinator,
                action: #selector(Coordinator.didTapDone)
            ),
        ]
        toolbar.sizeToFit()
        textField.inputAccessoryView = toolbar
        return textField
    }

    func updateUIView(_ textField: UITextField, context: Context) {
        context.coordinator.parent = self
        if textField.text != text {
            textField.text = text
        }
        textField.keyboardType = Self.keyboardType(for: field)
        textField.textColor = UIColor(showsCorrection ? AppTheme.mismatchText : AppTheme.ink)
        textField.accessibilityLabel = label
        textField.accessibilityValue = value
        textField.accessibilityHint = hint
        Self.updateFocusAfterUpdate(coordinator: context.coordinator, textField: textField)
    }

    @discardableResult
    static func updateFocusAfterUpdate(
        coordinator: Coordinator,
        textField: UITextField
    ) -> Task<Void, Never> {
        Task { @MainActor in
            let shouldFocus = coordinator.parent.focusedField.wrappedValue == coordinator.parent.field
            // swiftlint:disable:next line_length
            if shouldFocus != textField.isFirstResponder { _ = shouldFocus ? textField.becomeFirstResponder() : textField.resignFirstResponder() }
        }
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: GaugeKeyboardTextField
        weak var textField: UITextField?

        init(parent: GaugeKeyboardTextField) {
            self.parent = parent
        }

        @objc func textDidChange(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }

        func textField(
            _ textField: UITextField,
            shouldChangeCharactersIn range: NSRange,
            replacementString string: String
        ) -> Bool {
            GaugeKeyboardTextField.permitsChange(
                currentText: textField.text ?? "",
                range: range,
                replacement: string,
                upperBound: parent.range.upperBound
            )
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
            textField?.resignFirstResponder()
        }
    }
}
