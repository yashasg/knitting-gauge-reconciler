import SwiftUI

struct GaugeInputsCard: View {
    private static let spokenGaugeBasis = "per 10 centimeters"

    static func accessibilityLabel(for field: GaugeFormField) -> String {
        guard !field.isPatternDetail else { return field.correctionName }
        return "\(field.correctionName), \(spokenGaugeBasis)"
    }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @Binding private var patternStitches: String
    @Binding private var patternRows: String
    @Binding private var yourStitches: String
    @Binding private var yourRows: String

    private let stitchMismatch: Bool
    private let rowMismatch: Bool
    private let stitchDelta: Double?
    private let rowDelta: Double?
    private let validationMessages: [GaugeFormField: String]
    private let focusedField: Binding<GaugeFormField?>
    private let onSubmit: () -> Void

    init(
        patternStitches: Binding<String>,
        patternRows: Binding<String>,
        yourStitches: Binding<String>,
        yourRows: Binding<String>,
        stitchMismatch: Bool,
        rowMismatch: Bool,
        stitchDelta: Double?,
        rowDelta: Double?,
        validationMessages: [GaugeFormField: String],
        focusedField: Binding<GaugeFormField?>,
        onSubmit: @escaping () -> Void
    ) {
        self._patternStitches = patternStitches
        self._patternRows = patternRows
        self._yourStitches = yourStitches
        self._yourRows = yourRows
        self.stitchMismatch = stitchMismatch
        self.rowMismatch = rowMismatch
        self.stitchDelta = stitchDelta
        self.rowDelta = rowDelta
        self.validationMessages = validationMessages
        self.focusedField = focusedField
        self.onSubmit = onSubmit
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 14) {
                sectionHeader(title: "Pattern Gauge", icon: "book.fill")
                patternFields
            }

            VStack(alignment: .leading, spacing: 14) {
                sectionHeader(title: "Swatch Gauge", icon: "ruler.fill")
                swatchFields
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    @ViewBuilder
    private var patternFields: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 12) {
                patternStitchesField
                patternRowsField
            }
        } else {
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 0) {
                GridRow(alignment: .top) {
                    patternStitchesField
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    patternRowsField
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            }
        }
    }

    @ViewBuilder
    private var swatchFields: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 12) {
                yourStitchesField
                yourRowsField
            }
        } else {
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 0) {
                GridRow(alignment: .top) {
                    yourStitchesField
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    yourRowsField
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            }
        }
    }

    private var patternStitchesField: some View {
        GaugeStepperField(
            title: "Stitches",
            text: $patternStitches,
            unit: "st",
            identifier: "pattern-stitches",
            field: .patternStitches,
            validationMessage: validationMessages[.patternStitches],
            accessibilityLabel: Self.accessibilityLabel(for: .patternStitches),
            focusedField: focusedField,
            onSubmit: onSubmit
        )
    }

    private var patternRowsField: some View {
        GaugeStepperField(
            title: "Rows",
            text: $patternRows,
            unit: "ro",
            identifier: "pattern-rows",
            field: .patternRows,
            validationMessage: validationMessages[.patternRows],
            accessibilityLabel: Self.accessibilityLabel(for: .patternRows),
            focusedField: focusedField,
            onSubmit: onSubmit
        )
    }

    private var yourStitchesField: some View {
        GaugeStepperField(
            title: "Stitches",
            text: $yourStitches,
            unit: "st",
            identifier: "your-stitches",
            field: .yourStitches,
            validationMessage: validationMessages[.yourStitches],
            accessibilityLabel: Self.accessibilityLabel(for: .yourStitches),
            focusedField: focusedField,
            onSubmit: onSubmit,
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
            identifier: "your-rows",
            field: .yourRows,
            validationMessage: validationMessages[.yourRows],
            accessibilityLabel: Self.accessibilityLabel(for: .yourRows),
            focusedField: focusedField,
            onSubmit: onSubmit,
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
            HStack(alignment: .center, spacing: 8) {
                sectionTitle(title: title, icon: icon)
                Spacer()
                perTag
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
        Text("PER 10CM")
            .font(.caption2.weight(.bold))
            .tracking(0.5)
            .foregroundStyle(AppTheme.muted)
            .lineLimit(1)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityHidden(true)
            .accessibilityIdentifier("per-tag")
    }
}
