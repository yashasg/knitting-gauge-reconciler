import SwiftUI

// MARK: - PatternInstructionsCard

struct PatternInstructionsCard: View {
    @Binding var patternCastOn: String
    @Binding var patternYoke: String
    @Binding var patternBody: String
    @Binding var patternSleeve: String
    @Binding var patternIncreases: String
    var unit: MeasurementUnit

    private static let lengthCmRange: ClosedRange<Int> = 5...100

    // Creates a display binding that reads a cm-stored string value in the
    // active display unit and writes it back to cm on commit.
    private func displayBinding(for cmBinding: Binding<String>) -> Binding<String> {
        Binding(
            get: {
                // swiftlint:disable:next identifier_name
                let cm = Double(cmBinding.wrappedValue) ?? Double(Self.lengthCmRange.lowerBound)
                return "\(unit.cmToDisplayInt(cm))"
            },
            set: { newVal in
                let displayInt = Int(newVal) ?? unit.displayRange(from: Self.lengthCmRange).lowerBound
                cmBinding.wrappedValue = unit.displayIntToCmString(displayInt)
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "list.bullet.clipboard.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppTheme.secondary)
                    .accessibilityHidden(true)
                Text("Pattern Instructions")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
            }
            GaugeStepperField(
                title: "Cast-on stitches",
                text: $patternCastOn,
                unit: "stitches",
                identifier: "pattern-cast-on",
                range: 40...400
            )
            GaugeMeasurementPair {
                GaugeStepperField(
                    title: "Yoke depth (\(unit.label))",
                    text: displayBinding(for: $patternYoke),
                    unit: unit.label,
                    identifier: "pattern-yoke",
                    range: unit.displayRange(from: Self.lengthCmRange)
                )
            } trailing: {
                GaugeStepperField(
                    title: "Body length (\(unit.label))",
                    text: displayBinding(for: $patternBody),
                    unit: unit.label,
                    identifier: "pattern-body",
                    range: unit.displayRange(from: Self.lengthCmRange)
                )
            }
            GaugeMeasurementPair {
                GaugeStepperField(
                    title: "Sleeve length (\(unit.label))",
                    text: displayBinding(for: $patternSleeve),
                    unit: unit.label,
                    identifier: "pattern-sleeve",
                    range: unit.displayRange(from: Self.lengthCmRange)
                )
            } trailing: {
                GaugeStepperField(
                    title: "Increase every (rows)",
                    text: $patternIncreases,
                    unit: "rows",
                    identifier: "pattern-increases",
                    range: 1...30
                )
            }
        }
        .cardStyle()
    }
}
