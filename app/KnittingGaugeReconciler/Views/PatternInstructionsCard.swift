import SwiftUI

// MARK: - PatternInstructionsCard

struct PatternInstructionsCard: View {
    @Binding var patternCastOn: String
    @Binding var patternYoke: String
    @Binding var patternBody: String
    @Binding var patternSleeve: String
    @Binding var patternIncreases: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle("Pattern instructions")
            GaugeStepperField(
                title: "Cast-on stitches",
                text: $patternCastOn,
                unit: "stitches",
                identifier: "pattern-cast-on",
                range: 40...400
            )
            GaugeMeasurementPair {
                GaugeStepperField(
                    title: "Yoke depth (cm)",
                    text: $patternYoke,
                    unit: "cm",
                    identifier: "pattern-yoke",
                    range: 5...100
                )
            } trailing: {
                GaugeStepperField(
                    title: "Body length (cm)",
                    text: $patternBody,
                    unit: "cm",
                    identifier: "pattern-body",
                    range: 5...100
                )
            }
            GaugeMeasurementPair {
                GaugeStepperField(
                    title: "Sleeve length (cm)",
                    text: $patternSleeve,
                    unit: "cm",
                    identifier: "pattern-sleeve",
                    range: 5...100
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
