import SwiftUI

struct PatternInstructionsCard: View {
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

    static func title(for field: GaugeFormField, unit: MeasurementUnit) -> String {
        switch field {
        case .patternYoke: return "Yoke depth (\(unit.label))"
        case .patternBody: return "Body length (\(unit.label))"
        case .patternSleeve: return "Sleeve length (\(unit.label))"
        default: return field.correctionName
        }
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
            PatternInstructionsLabel(isExpanded: isExpanded)
        }
        .tint(AppTheme.sage)
        .cardStyle()
    }

    private var castOnField: some View {
        GaugeStepperField(
            title: "Cast-on stitches",
            text: $patternCastOn,
            unit: "stitches",
            identifier: "pattern-cast-on",
            field: .patternCastOn,
            validationMessage: validationMessages[.patternCastOn],
            focusedField: focusedField,
            onSubmit: onSubmit,
            range: 40...400
        )
    }

    @ViewBuilder
    private var lengthFields: some View {
        if dynamicTypeSize.isAccessibilitySize {
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
        if dynamicTypeSize.isAccessibilitySize {
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
            title: Self.title(for: .patternYoke, unit: unit),
            text: displayBinding(for: $patternYoke, field: .patternYoke),
            unit: unit.label,
            identifier: "pattern-yoke",
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
            title: Self.title(for: .patternBody, unit: unit),
            text: displayBinding(for: $patternBody, field: .patternBody),
            unit: unit.label,
            identifier: "pattern-body",
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
            title: Self.title(for: .patternSleeve, unit: unit),
            text: displayBinding(for: $patternSleeve, field: .patternSleeve),
            unit: unit.label,
            identifier: "pattern-sleeve",
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
            identifier: "pattern-increases",
            field: .patternIncreases,
            validationMessage: validationMessages[.patternIncreases],
            focusedField: focusedField,
            onSubmit: onSubmit,
            range: 1...30
        )
    }

    private func displayBinding(
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

struct PatternInstructionsLabel: View {
    let isExpanded: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: "list.bullet.clipboard.fill")
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.secondary)
                .accessibilityHidden(true)
            Text("Pattern details (optional)")
                .font(.title3.weight(.bold))
                .foregroundStyle(AppTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
        .accessibilityIdentifier("pattern-details-disclosure")
        .accessibilityHint("Expands optional unit, cast-on, length, and shaping fields")
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
        .accessibilityIdentifier("unit-toggle")
        .accessibilityLabel("Measurement unit")
        .accessibilityHint("Switches all length fields between centimetres and inches")
    }
}
