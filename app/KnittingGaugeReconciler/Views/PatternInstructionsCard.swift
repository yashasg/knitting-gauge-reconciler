import SwiftUI

struct PatternInstructionsCard: View {
    static let disclosureLabel = "Pattern details (optional)"
    static let disclosureHint = "Expands optional cast-on, length, and shaping fields"

    static func disclosureValue(isExpanded: Bool) -> String {
        isExpanded ? "Expanded" : "Collapsed"
    }

    @Binding private var patternCastOn: String
    @Binding private var patternYoke: String
    @Binding private var patternBody: String
    @Binding private var patternSleeve: String
    @Binding private var patternIncreases: String
    @Binding private var unit: MeasurementUnit
    @Binding private var isExpanded: Bool

    private let validationMessages: [GaugeFormField: String]
    private let focusedField: Binding<GaugeFormField?>

    private static let lengthCmRange: ClosedRange<Double> = 5...100

    init(
        patternCastOn: Binding<String>,
        patternYoke: Binding<String>,
        patternBody: Binding<String>,
        patternSleeve: Binding<String>,
        patternIncreases: Binding<String>,
        unit: Binding<MeasurementUnit>,
        isExpanded: Binding<Bool>,
        validationMessages: [GaugeFormField: String],
        focusedField: Binding<GaugeFormField?>
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
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 0) {
                castOnField
                lengthFields
                sleeveAndShapingFields
            }
            .padding(.top, Spacing.margin)
        } label: {
            HStack(alignment: .center, spacing: Spacing.inner) {
                Image(systemName: "list.bullet.clipboard.fill")
                    .font(.satoshiTitle3.weight(.semibold))
                    .foregroundStyle(AppTheme.secondary)
                    .accessibilityHidden(true)
                Text(Self.disclosureLabel)
                    .font(.satoshiTitle3.weight(.bold))
                    .foregroundStyle(AppTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
            }
            .frame(maxWidth: .infinity, minHeight: Sizing.minimumTouchTarget, alignment: .leading)
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
        GaugeInputField(
            title: "Cast-on stitches",
            text: $patternCastOn,
            unit: "stitches",
            field: .patternCastOn,
            validationMessage: validationMessages[.patternCastOn],
            focusedField: focusedField,
            range: 40...400
        )
    }

    private var lengthFields: some View {
        GaugeMeasurementPair(spacing: Spacing.control) {
            yokeField
        } trailing: {
            bodyField
        }
    }

    private var sleeveAndShapingFields: some View {
        GaugeMeasurementPair(spacing: Spacing.control) {
            sleeveField
        } trailing: {
            shapingField
        }
    }

    private var yokeField: some View {
        GaugeInputField(
            title: GaugeFormDraft(unit: unit).lengthFieldLabel(.patternYoke),
            text: displayBinding(for: $patternYoke),
            unit: unit.label,
            field: .patternYoke,
            validationMessage: validationMessages[.patternYoke],
            validationText: patternYoke,
            focusedField: focusedField,
            range: unit.displayDecimalRange(from: Self.lengthCmRange)
        )
    }

    private var bodyField: some View {
        GaugeInputField(
            title: GaugeFormDraft(unit: unit).lengthFieldLabel(.patternBody),
            text: displayBinding(for: $patternBody),
            unit: unit.label,
            field: .patternBody,
            validationMessage: validationMessages[.patternBody],
            validationText: patternBody,
            focusedField: focusedField,
            range: unit.displayDecimalRange(from: Self.lengthCmRange)
        )
    }

    private var sleeveField: some View {
        GaugeInputField(
            title: GaugeFormDraft(unit: unit).lengthFieldLabel(.patternSleeve),
            text: displayBinding(for: $patternSleeve),
            unit: unit.label,
            field: .patternSleeve,
            validationMessage: validationMessages[.patternSleeve],
            validationText: patternSleeve,
            focusedField: focusedField,
            range: unit.displayDecimalRange(from: Self.lengthCmRange)
        )
    }

    private var shapingField: some View {
        GaugeInputField(
            title: "Increase every (rows)",
            text: $patternIncreases,
            unit: "rows",
            field: .patternIncreases,
            validationMessage: validationMessages[.patternIncreases],
            focusedField: focusedField,
            range: 1...30
        )
    }

    func displayBinding(for centimeters: Binding<String>) -> Binding<String> {
        Binding(
            get: {
                unit.positiveMeasurementDisplayText(from: centimeters.wrappedValue)
            },
            set: { newValue in
                centimeters.wrappedValue = unit.positiveMeasurementStorageText(from: newValue)
            }
        )
    }
}
