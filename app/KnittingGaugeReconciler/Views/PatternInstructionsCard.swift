import SwiftUI

struct PatternInstructionsCard: View {
    static let disclosureLabel = "Pattern details (optional)"
    static let disclosureHint = "Expands optional unit, cast-on, length, and shaping fields"

    static func disclosureValue(isExpanded: Bool) -> String {
        isExpanded ? "Expanded" : "Collapsed"
    }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @Binding private var patternCastOn: String
    @Binding private var patternYoke: String
    @Binding private var patternBody: String
    @Binding private var patternSleeve: String
    @Binding private var patternIncreases: String
    @Binding private var unit: MeasurementUnit
    @Binding private var isExpanded: Bool

    private let validationMessages: [GaugeFormField: String]
    private let focusedField: Binding<GaugeFormField?>
    private let onSubmit: () -> Void

    private static let lengthCmRange: ClosedRange<Int> = 5...100

    static func usesStackedLayout(at size: DynamicTypeSize) -> Bool {
        size.isAccessibilitySize
    }

    init(
        patternCastOn: Binding<String>,
        patternYoke: Binding<String>,
        patternBody: Binding<String>,
        patternSleeve: Binding<String>,
        patternIncreases: Binding<String>,
        unit: Binding<MeasurementUnit>,
        isExpanded: Binding<Bool>,
        validationMessages: [GaugeFormField: String],
        focusedField: Binding<GaugeFormField?>,
        onSubmit: @escaping () -> Void
    ) {
        self._patternCastOn = patternCastOn
        self._patternYoke = patternYoke
        self._patternBody = patternBody
        self._patternSleeve = patternSleeve
        self._patternIncreases = patternIncreases
        self._unit = unit
        self._isExpanded = isExpanded
        self.validationMessages = validationMessages
        self.focusedField = focusedField
        self.onSubmit = onSubmit
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 14) {
                UnitToggleView(unit: $unit)
                castOnField
                lengthFields
                sleeveAndShapingFields
            }
            .padding(.top, 14)
        } label: {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "list.bullet.clipboard.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppTheme.secondary)
                    .accessibilityHidden(true)
                Text(Self.disclosureLabel)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityValue(Self.disclosureValue(isExpanded: isExpanded))
            .accessibilityHint(Self.disclosureHint)
        }
        .tint(AppTheme.sage)
        .cardStyle()
    }

    private var castOnField: some View {
        GaugeStepperField(
            title: "Cast-on stitches",
            text: $patternCastOn,
            unit: "stitches",
            field: .patternCastOn,
            validationMessage: validationMessages[.patternCastOn],
            focusedField: focusedField,
            onSubmit: onSubmit,
            range: 40...400
        )
    }

    @ViewBuilder
    private var lengthFields: some View {
        if Self.usesStackedLayout(at: dynamicTypeSize) {
            VStack(alignment: .leading, spacing: 12) {
                yokeField
                bodyField
            }
        } else {
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 0) {
                GridRow(alignment: .top) {
                    yokeField
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    bodyField
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            }
        }
    }

    @ViewBuilder
    private var sleeveAndShapingFields: some View {
        if Self.usesStackedLayout(at: dynamicTypeSize) {
            VStack(alignment: .leading, spacing: 12) {
                sleeveField
                shapingField
            }
        } else {
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 0) {
                GridRow(alignment: .top) {
                    sleeveField
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    shapingField
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            }
        }
    }

    private var yokeField: some View {
        GaugeStepperField(
            title: GaugeFormDraft(unit: unit).lengthFieldLabel(.patternYoke),
            text: displayBinding(for: $patternYoke, field: .patternYoke),
            unit: unit.label,
            field: .patternYoke,
            validationMessage: validationMessages[.patternYoke],
            validationText: patternYoke,
            displayUnit: unit,
            focusedField: focusedField,
            onSubmit: onSubmit,
            range: unit.displayRange(from: Self.lengthCmRange)
        )
    }

    private var bodyField: some View {
        GaugeStepperField(
            title: GaugeFormDraft(unit: unit).lengthFieldLabel(.patternBody),
            text: displayBinding(for: $patternBody, field: .patternBody),
            unit: unit.label,
            field: .patternBody,
            validationMessage: validationMessages[.patternBody],
            validationText: patternBody,
            displayUnit: unit,
            focusedField: focusedField,
            onSubmit: onSubmit,
            range: unit.displayRange(from: Self.lengthCmRange)
        )
    }

    private var sleeveField: some View {
        GaugeStepperField(
            title: GaugeFormDraft(unit: unit).lengthFieldLabel(.patternSleeve),
            text: displayBinding(for: $patternSleeve, field: .patternSleeve),
            unit: unit.label,
            field: .patternSleeve,
            validationMessage: validationMessages[.patternSleeve],
            validationText: patternSleeve,
            displayUnit: unit,
            focusedField: focusedField,
            onSubmit: onSubmit,
            range: unit.displayRange(from: Self.lengthCmRange)
        )
    }

    private var shapingField: some View {
        GaugeStepperField(
            title: "Increase every (rows)",
            text: $patternIncreases,
            unit: "rows",
            field: .patternIncreases,
            validationMessage: validationMessages[.patternIncreases],
            focusedField: focusedField,
            onSubmit: onSubmit,
            range: 1...30
        )
    }

    func displayBinding(
        for centimeters: Binding<String>,
        field: GaugeFormField
    ) -> Binding<String> {
        Binding(
            get: {
                let rawText = centimeters.wrappedValue
                if let invalidInches = MeasurementUnit.invalidInchesText(from: rawText) {
                    return invalidInches
                }
                guard unit == .inches else { return rawText }
                switch GaugeMath.validate(rawText, for: field.mathField) {
                case .success(let value?):
                    return "\(unit.cmToDisplayInt(value))"
                case .success(nil):
                    return ""
                case .failure:
                    return rawText
                }
            },
            set: { newValue in
                centimeters.wrappedValue = unit.centimeterStorageText(
                    from: newValue,
                    cmRange: Self.lengthCmRange
                )
            }
        )
    }
}

private struct UnitToggleView: View {
    @Binding private var unit: MeasurementUnit

    init(unit: Binding<MeasurementUnit>) {
        self._unit = unit
    }

    var body: some View {
        Picker("Measurement unit", selection: $unit) {
            ForEach(MeasurementUnit.allCases, id: \.self) { option in
                Text(option.label).tag(option)
            }
        }
        .pickerStyle(.segmented)
        .frame(minHeight: 44)
        .accessibilityLabel("Measurement unit")
        .accessibilityHint("Switches all length fields between centimetres and inches")
    }
}
