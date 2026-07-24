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
// Tap the chevron (⇅) → wheel picker opens in the field's input view.
// Unit suffix intentionally omitted — labels above each field communicate units.

struct DeltaPillBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.satoshiCaption2.weight(.semibold))
            .foregroundStyle(AppTheme.card)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, Spacing.inner)
            .padding(EdgeInsets(top: Spacing.tight, leading: 0, bottom: Spacing.tight, trailing: 0))
            .background(AppTheme.deltaPill)
            .clipShape(Capsule())
            // Pill is purely decorative — adjacent value tile carries the
            // semantic value (e.g. "Knit 64 rows, +16 from pattern").
            .accessibilityHidden(true)
    }
}

struct GaugeStepperAccessibilityContract: Equatable {
    let fieldValue: String
    let fieldHint: String
    let pickerLabel: String
    let pickerValue: String
    let pickerHint: String
    let actions: [String]
    let warningSummary: String?
}

struct SheetContentProvider<Content: View> {
    let content: Content
    func contentView() -> Content { content }
}

struct GaugeStepperOpenPickerAction {
    let field: GaugeFormField
    let focusedField: Binding<GaugeFormField?>
    let pickerRequest: Binding<Int>

    @MainActor func perform() {
        pickerRequest.wrappedValue += 1
        focusedField.wrappedValue = field
    }
}

// Issue #134 keeps the pure stepper semantics on the view instead of adding an adapter.
// swiftlint:disable:next type_body_length
struct GaugeStepperField: View {
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
    private let displayUnit: MeasurementUnit?
    private let focusedField: Binding<GaugeFormField?>
    private let range: ClosedRange<Int>
    private let hasMismatch: Bool
    private let mismatchLabel: String?
    private let mismatchDelta: Double?

    @State private var pickerRequest = 0

    static func pickerAccessibilityLabel(for fieldLabel: String) -> String {
        "Open picker for \(fieldLabel)"
    }

    static func accessibilityContract(
        text: String,
        unit: String,
        fieldLabel: String,
        isRequired: Bool = false,
        validationMessage: String? = nil,
        mismatchLabel: String? = nil,
        mismatchDelta: Double? = nil
    ) -> GaugeStepperAccessibilityContract {
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
        let fieldHint: String
        if validationMessage != nil {
            fieldHint = "Correct this value before viewing results."
        } else if mismatchLabel == nil {
            fieldHint = "Double-tap to edit."
        } else {
            fieldHint = "Double-tap to edit. Use the picker button for wheel selection and warning details."
        }
        let pickerHint = mismatchLabel.map {
            "\($0). Opens the wheel picker and warning details."
        } ?? "Double-tap to open wheel picker."
        return GaugeStepperAccessibilityContract(
            fieldValue: valueParts.joined(separator: ", "),
            fieldHint: fieldHint,
            pickerLabel: pickerAccessibilityLabel(for: fieldLabel),
            pickerValue: mismatchLabel == nil ? "" : "Warning",
            pickerHint: pickerHint,
            actions: ["Increment", "Decrement"],
            warningSummary: mismatchLabel
        )
    }

    static func pickerSelection(
        validationText: String,
        field: GaugeFormField,
        displayUnit: MeasurementUnit?,
        range: ClosedRange<Int>
    ) -> Int {
        let rounded: Int?
        switch GaugeMath.validate(validationText, for: field.mathField) {
        case .success(let value?):
            rounded = displayUnit?.cmToDisplayInt(value) ?? Int(value.rounded())
        case .success(nil), .failure:
            rounded = nil
        }
        return rounded.flatMap { range.contains($0) ? $0 : nil } ?? range.lowerBound
    }

    static func committedText(selection: Int) -> String {
        "\(selection)"
    }

    static func adjustedText(
        _ text: String,
        by adjustment: Int,
        field: GaugeFormField,
        displayUnit: MeasurementUnit?,
        range: ClosedRange<Int>
    ) -> String {
        let current = pickerSelection(
            validationText: text,
            field: field,
            displayUnit: displayUnit,
            range: range
        )
        let adjusted = min(max(current + adjustment, range.lowerBound), range.upperBound)
        return committedText(selection: adjusted)
    }

    init(
        title: String,
        text: Binding<String>,
        unit: String,
        field: GaugeFormField,
        validationMessage: String?,
        validationText: String? = nil,
        accessibilityLabel: String? = nil,
        displayUnit: MeasurementUnit? = nil,
        focusedField: Binding<GaugeFormField?>,
        range: ClosedRange<Int> = 1...99,
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
        self.displayUnit = displayUnit
        self.focusedField = focusedField
        self.range = range
        self.hasMismatch = hasMismatch
        self.mismatchLabel = mismatchLabel
        self.mismatchDelta = mismatchDelta
    }

    private var mismatchSentence: String? {
        guard hasMismatch, let mismatchLabel else { return nil }
        return mismatchLabel
    }

    private var fieldAccessibilityValue: String {
        accessibilityContract.fieldValue
    }

    private var fieldAccessibilityHint: String {
        accessibilityContract.fieldHint
    }

    private var pickerAccessibilityValue: String {
        accessibilityContract.pickerValue
    }

    private var pickerAccessibilityHint: String {
        accessibilityContract.pickerHint
    }

    private var accessibilityContract: GaugeStepperAccessibilityContract {
        Self.accessibilityContract(
            text: text,
            unit: unit,
            fieldLabel: accessibilityLabel,
            isRequired: field.isRequired,
            validationMessage: validationMessage,
            mismatchLabel: mismatchSentence,
            mismatchDelta: mismatchDelta
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

    private func mismatchBadge(_ text: String) -> some View {
        DeltaPillBadge(text: text)
    }

    func increment() {
        text = Self.adjustedText(
            validationText,
            by: 1,
            field: field,
            displayUnit: displayUnit,
            range: range
        )
    }

    func decrement() {
        text = Self.adjustedText(
            validationText,
            by: -1,
            field: field,
            displayUnit: displayUnit,
            range: range
        )
    }

    var body: some View {
        let openPicker = GaugeStepperOpenPickerAction(
            field: field,
            focusedField: focusedField,
            pickerRequest: $pickerRequest
        )
        return VStack(alignment: .leading, spacing: 0) {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: Spacing.tight) {
                        Text(title)
                            .font(.satoshiSubheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.muted)

                        if let mismatchDeltaText {
                            mismatchBadge(mismatchDeltaText)
                        }
                    }
                } else {
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .center, spacing: Spacing.inner) {
                            Text(title)
                                .font(.satoshiSubheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.muted)
                                .fixedSize(horizontal: true, vertical: false)

                            if let mismatchDeltaText {
                                mismatchBadge(mismatchDeltaText)
                            }
                        }

                        VStack(alignment: .leading, spacing: Spacing.tight) {
                            Text(title)
                                .font(.satoshiSubheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.muted)

                            if let mismatchDeltaText {
                                mismatchBadge(mismatchDeltaText)
                            }
                        }
                    }
                }
            }
            // Keep the horizontal title row stable when mismatch toggles;
            // adaptive stacked layouts remain free to expand vertically.
            .frame(minHeight: Sizing.fieldLabelMinimumHeight, alignment: .leading)
            .padding(.bottom, Spacing.inner)

            HStack(spacing: 0) {
                GaugeKeyboardTextField(
                    text: $text,
                    field: field,
                    focusedField: focusedField,
                    label: accessibilityLabel,
                    value: fieldAccessibilityValue,
                    hint: fieldAccessibilityHint,
                    showsCorrection: hasMismatch || validationMessage != nil,
                    validationText: validationText,
                    displayUnit: displayUnit,
                    range: range,
                    pickerRequest: pickerRequest
                )
                    .frame(maxWidth: .infinity, minHeight: controlMinimumHeight)
                    .padding(.horizontal, Spacing.control)

                Rectangle()
                    .fill(AppTheme.outline)
                    .frame(width: Sizing.separator)
                    .padding(.top, Spacing.inner)
                    .padding(.bottom, Spacing.inner)
                    .frame(minHeight: controlMinimumHeight)

                Button(action: openPicker.perform) {
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.satoshiCaption.weight(.medium))
                        .foregroundStyle(AppTheme.muted)
                        .frame(width: controlMinimumHeight, height: controlMinimumHeight)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Self.pickerAccessibilityLabel(for: accessibilityLabel))
                .accessibilityValue(pickerAccessibilityValue)
                .accessibilityHint(pickerAccessibilityHint)
                .accessibilityAction(named: "Increment", increment)
                .accessibilityAction(named: "Decrement", decrement)
            }
            .frame(minHeight: controlMinimumHeight)
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: Radius.small, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.small, style: .continuous)
                    .stroke(
                        (hasMismatch || validationMessage != nil
                            ? AppTheme.mismatchText
                            : AppTheme.muted).opacity(0.7),
                        lineWidth: 1.5
                    )
            )
            .accessibilityElement(children: .contain)

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
}

// MARK: - GaugeKeyboardTextField

class GaugePickerTextField: UITextField {
    weak var coordinator: GaugeKeyboardTextField.Coordinator?

    override func accessibilityIncrement() {
        coordinator?.adjust(by: 1)
    }

    override func accessibilityDecrement() {
        coordinator?.adjust(by: -1)
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
    private let validationText: String
    private let displayUnit: MeasurementUnit?
    private let range: ClosedRange<Int>
    private let pickerRequest: Int

    init(
        text: Binding<String>,
        field: GaugeFormField,
        focusedField: Binding<GaugeFormField?>,
        label: String,
        value: String,
        hint: String,
        showsCorrection: Bool,
        validationText: String? = nil,
        displayUnit: MeasurementUnit? = nil,
        range: ClosedRange<Int> = 1...99,
        pickerRequest: Int = 0
    ) {
        self._text = text
        self.field = field
        self.focusedField = focusedField
        self.label = label
        self.value = value
        self.hint = hint
        self.showsCorrection = showsCorrection
        self.validationText = validationText ?? text.wrappedValue
        self.displayUnit = displayUnit
        self.range = range
        self.pickerRequest = pickerRequest
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = GaugePickerTextField()
        textField.delegate = context.coordinator
        textField.keyboardType = .decimalPad
        textField.textAlignment = .center
        textField.borderStyle = .none
        textField.adjustsFontForContentSizeCategory = true
        textField.font = SatoshiVariableFont.scaledFont(
            size: 22,
            textStyle: .title2,
            weight: .semibold
        )
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.addTarget(
            context.coordinator,
            action: #selector(Coordinator.textDidChange(_:)),
            for: .editingChanged
        )
        textField.accessibilityTraits.insert(.adjustable)
        textField.coordinator = context.coordinator
        context.coordinator.textField = textField

        let toolbar = UIToolbar()
        toolbar.autoresizingMask = [.flexibleWidth]
        let flexibleSpace = UIBarButtonItem(
            barButtonSystemItem: .flexibleSpace,
            target: nil,
            action: nil
        )
        let done = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: context.coordinator,
            action: #selector(Coordinator.didTapDone)
        )
        toolbar.items = [flexibleSpace, done]
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

        let coordinator = context.coordinator
        Self.handlePickerRequest(
            pickerRequest,
            coordinator: coordinator,
            textField: textField,
            activate: false
        )
        Self.updateFocusAfterUpdate(coordinator: coordinator, textField: textField)
    }

    static func handlePickerRequest(
        _ request: Int,
        coordinator: Coordinator,
        textField: UITextField,
        activate: Bool = true
    ) {
        guard coordinator.handledPickerRequest != request else { return }
        coordinator.handledPickerRequest = request
        coordinator.showPicker(in: textField, activate: activate)
    }

    @discardableResult
    static func updateFocusAfterUpdate(
        coordinator: Coordinator,
        textField: UITextField
    ) -> Task<Void, Never> {
        return Task { @MainActor in
            let shouldFocus = coordinator.parent.focusedField.wrappedValue == coordinator.parent.field
            // swiftlint:disable:next line_length
            if shouldFocus != textField.isFirstResponder { _ = shouldFocus ? textField.becomeFirstResponder() : textField.resignFirstResponder() }
        }
    }

    final class Coordinator: NSObject, UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate {
        var parent: GaugeKeyboardTextField
        var handledPickerRequest = 0
        weak var textField: UITextField?
        lazy var pickerView: UIPickerView = {
            let pickerView = UIPickerView()
            pickerView.dataSource = self
            pickerView.delegate = self
            return pickerView
        }()
        private(set) var pendingSelection: Int

        init(parent: GaugeKeyboardTextField) {
            self.parent = parent
            self.pendingSelection = GaugeStepperField.pickerSelection(
                validationText: parent.validationText,
                field: parent.field,
                displayUnit: parent.displayUnit,
                range: parent.range
            )
            super.init()
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
            textField.inputView = nil
            if parent.focusedField.wrappedValue == parent.field {
                parent.focusedField.wrappedValue = nil
            }
        }

        func showPicker(in textField: UITextField, activate: Bool = true) {
            self.textField = textField
            pendingSelection = GaugeStepperField.pickerSelection(
                validationText: parent.validationText,
                field: parent.field,
                displayUnit: parent.displayUnit,
                range: parent.range
            )
            pickerView.accessibilityLabel = parent.label
            pickerView.selectRow(
                pendingSelection - parent.range.lowerBound,
                inComponent: 0,
                animated: false
            )
            textField.inputView = pickerView
            textField.reloadInputViews()
            if activate { textField.becomeFirstResponder() }
        }

        @objc func didTapDone() {
            if textField?.inputView === pickerView {
                parent.text = GaugeStepperField.committedText(selection: pendingSelection)
            }
            textField?.inputView = nil
            textField?.reloadInputViews()
            textField?.resignFirstResponder()
        }

        func adjust(by adjustment: Int) {
            if textField?.inputView !== pickerView {
                pendingSelection = GaugeStepperField.pickerSelection(
                    validationText: parent.validationText,
                    field: parent.field,
                    displayUnit: parent.displayUnit,
                    range: parent.range
                )
            }
            pendingSelection = min(
                max(pendingSelection + adjustment, parent.range.lowerBound),
                parent.range.upperBound
            )
            parent.text = GaugeStepperField.committedText(selection: pendingSelection)
            pickerView.selectRow(
                pendingSelection - parent.range.lowerBound,
                inComponent: 0,
                animated: true
            )
        }

        func numberOfComponents(in pickerView: UIPickerView) -> Int {
            1
        }

        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            parent.range.count
        }

        func pickerView(
            _ pickerView: UIPickerView,
            titleForRow row: Int,
            forComponent component: Int
        ) -> String? {
            "\(parent.range.lowerBound + row)"
        }

        func pickerView(
            _ pickerView: UIPickerView,
            didSelectRow row: Int,
            inComponent component: Int
        ) {
            pendingSelection = parent.range.lowerBound + row
        }
    }
}
