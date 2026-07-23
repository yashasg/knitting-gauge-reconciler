import SwiftUI

struct GaugeInputsCard: View {
    static let accessibilityFieldOrder: [GaugeFormField] = [
        .patternStitches, .patternRows, .yourStitches, .yourRows,
    ]

    static func accessibilityLabel(
        for field: GaugeFormField,
        unit: MeasurementUnit = .centimeters
    ) -> String {
        guard !field.isPatternDetail else { return field.correctionName }
        let spokenGaugeBasis = unit == .centimeters ? "per 10 centimeters" : "per 4 inches"
        return "\(field.correctionName), \(spokenGaugeBasis)"
    }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @Binding private var patternStitches: String
    @Binding private var patternRows: String
    @Binding private var yourStitches: String
    @Binding private var yourRows: String

    @Binding private var unit: MeasurementUnit
    private let stitchMismatch: Bool
    private let rowMismatch: Bool
    private let stitchDelta: Double?
    private let rowDelta: Double?
    private let validationMessages: [GaugeFormField: String]
    private let focusedField: Binding<GaugeFormField?>

    init(
        patternStitches: Binding<String>,
        patternRows: Binding<String>,
        yourStitches: Binding<String>,
        yourRows: Binding<String>,
        unit: Binding<MeasurementUnit>,
        stitchMismatch: Bool,
        rowMismatch: Bool,
        stitchDelta: Double?,
        rowDelta: Double?,
        validationMessages: [GaugeFormField: String],
        focusedField: Binding<GaugeFormField?>
    ) {
        self._patternStitches = patternStitches
        self._patternRows = patternRows
        self._yourStitches = yourStitches
        self._yourRows = yourRows
        self._unit = unit
        self.stitchMismatch = stitchMismatch
        self.rowMismatch = rowMismatch
        self.stitchDelta = stitchDelta
        self.rowDelta = rowDelta
        self.validationMessages = validationMessages
        self.focusedField = focusedField
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 4) {
                    measurementUnitLabel
                    measurementUnitPicker
                }
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        measurementUnitLabel
                            .fixedSize(horizontal: true, vertical: false)
                        Spacer(minLength: 0)
                        measurementUnitPicker
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .frame(minHeight: 44)

                    VStack(alignment: .leading, spacing: 4) {
                        measurementUnitLabel
                        measurementUnitPicker
                    }
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                }
            }

            Divider()
                .overlay(AppTheme.outline)
                .padding(.top, 4)

            VStack(alignment: .leading, spacing: 14) {
                sectionHeader(title: "Pattern Gauge", icon: "book.fill")
                patternFields
            }
            .padding(.top, 20)

            VStack(alignment: .leading, spacing: 14) {
                sectionHeader(title: "Swatch Gauge", icon: "ruler.fill")
                swatchFields
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var measurementUnitLabel: some View {
        Text("Measurement unit")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppTheme.muted)
            .accessibilityHidden(true)
    }

    private var measurementUnitPicker: some View {
        Picker("Measurement unit", selection: $unit) {
            Text("Centimeters").tag(MeasurementUnit.centimeters)
            Text("Inches").tag(MeasurementUnit.inches)
        }
        .labelsHidden()
        .pickerStyle(.menu)
        .font(.subheadline.weight(.semibold))
        .tint(AppTheme.ink)
        .accessibilityHint("Changes gauge basis and dimensions throughout the calculator.")
    }

    private var patternFields: some View {
        GaugeMeasurementPair {
            patternStitchesField
        } trailing: {
            patternRowsField
        }
    }

    private var swatchFields: some View {
        GaugeMeasurementPair {
            yourStitchesField
        } trailing: {
            yourRowsField
        }
    }

    private var patternStitchesField: some View {
        GaugeStepperField(
            title: "Stitches",
            text: $patternStitches,
            unit: "st",
            field: .patternStitches,
            validationMessage: validationMessages[.patternStitches],
            accessibilityLabel: Self.accessibilityLabel(for: .patternStitches, unit: unit),
            focusedField: focusedField
        )
    }

    private var patternRowsField: some View {
        GaugeStepperField(
            title: "Rows",
            text: $patternRows,
            unit: "ro",
            field: .patternRows,
            validationMessage: validationMessages[.patternRows],
            accessibilityLabel: Self.accessibilityLabel(for: .patternRows, unit: unit),
            focusedField: focusedField
        )
    }

    private var yourStitchesField: some View {
        GaugeStepperField(
            title: "Stitches",
            text: $yourStitches,
            unit: "st",
            field: .yourStitches,
            validationMessage: validationMessages[.yourStitches],
            accessibilityLabel: Self.accessibilityLabel(for: .yourStitches, unit: unit),
            focusedField: focusedField,
            hasMismatch: stitchMismatch,
            mismatchLabel: "Stitch gauge mismatch detected",
            mismatchDelta: stitchDelta
        )
    }

    private var yourRowsField: some View {
        GaugeStepperField(
            title: "Rows",
            text: $yourRows,
            unit: "ro",
            field: .yourRows,
            validationMessage: validationMessages[.yourRows],
            accessibilityLabel: Self.accessibilityLabel(for: .yourRows, unit: unit),
            focusedField: focusedField,
            hasMismatch: rowMismatch,
            mismatchLabel: "Row gauge mismatch detected",
            mismatchDelta: rowDelta
        )
    }

    @ViewBuilder
    private func sectionHeader(title: String, icon: String) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 6) {
                sectionTitle(title: title, icon: icon)
                perTag
            }
        } else {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: 8) {
                    sectionTitle(title: title, icon: icon)
                        .fixedSize(horizontal: true, vertical: false)
                    Spacer()
                    perTag
                        .fixedSize(horizontal: true, vertical: false)
                }

                VStack(alignment: .leading, spacing: 6) {
                    sectionTitle(title: title, icon: icon)
                    perTag
                }
            }
        }
    }

    private func sectionTitle(title: String, icon: String) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.secondary)
                .accessibilityLabel("\(title) gauge")
                .accessibilityHidden(true)
            Text(title)
                .font(.title2.weight(.bold))
                .foregroundStyle(AppTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
        }
    }

    private var perTag: some View {
        Text(unit == .centimeters ? "PER 10 CM" : "PER 4 IN")
            .font(.caption2.weight(.bold))
            .tracking(0.5)
            .foregroundStyle(AppTheme.muted)
            .lineLimit(1)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityHidden(true)
    }
}
