import SwiftUI

// MARK: - PatternGaugeCard

struct PatternGaugeCard: View {
    @Binding var patternStitches: String
    @Binding var patternRows: String

    var body: some View {
        GaugeInputGroup(title: "Pattern Gauge", icon: "book.fill", showPerTag: true) {
            GaugeMeasurementPair {
                GaugeStepperField(
                    title: "Stitches",
                    text: $patternStitches,
                    unit: "st",
                    identifier: "pattern-stitches"
                )
            } trailing: {
                GaugeStepperField(
                    title: "Rows",
                    text: $patternRows,
                    unit: "ro",
                    identifier: "pattern-rows"
                )
            }
        }
    }
}

// MARK: - YourGaugeCard

struct YourGaugeCard: View {
    @Binding var yourStitches: String
    @Binding var yourRows: String
    var stitchMismatch: Bool
    var rowMismatch: Bool

    var body: some View {
        GaugeInputGroup(title: "Your Gauge", icon: "ruler.fill", showPerTag: true) {
            GaugeMeasurementPair {
                GaugeStepperField(
                    title: "Stitches",
                    text: $yourStitches,
                    unit: "st",
                    identifier: "your-stitches",
                    hasMismatch: stitchMismatch,
                    mismatchLabel: "Stitch gauge mismatch detected"
                )
            } trailing: {
                GaugeStepperField(
                    title: "Rows",
                    text: $yourRows,
                    unit: "ro",
                    identifier: "your-rows",
                    hasMismatch: rowMismatch,
                    mismatchLabel: "Row gauge mismatch detected"
                )
            }
        }
    }
}
