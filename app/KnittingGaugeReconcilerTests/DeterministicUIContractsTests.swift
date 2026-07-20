import SwiftUI
import Testing
import UIKit
@testable import KnittingGaugeReconciler

@MainActor
struct DeterministicUIContractsTests {
    @Test func formDraftActionsPreserveRawValuesValidationUnitsResetAndUndo() throws {
        let original = ["31", "23", "29", "21", "141", "19", "49", "44", "7"]
        var draft = GaugeFormDraft(
            values: original,
            unit: .centimeters,
            patternDetailsExpanded: true
        )

        #expect(draft.rawValues == original)
        #expect(draft.inputs != nil)
        #expect(draft.lengthFieldLabel(.patternYoke) == "Yoke depth (cm)")
        draft.unit = .inches
        #expect(draft.lengthFieldLabel(.patternYoke) == "Yoke depth (in)")
        draft.unit = .centimeters
        #expect(draft.lengthFieldLabel(.patternYoke) == "Yoke depth (cm)")

        draft[.patternStitches] = "0"
        draft[.patternRows] = "100"
        #expect(draft.rawValues[0] == "0")
        #expect(draft.rawValues[1] == "100")
        #expect(draft.inputs == nil)
        #expect(
            draft.validationMessage(for: .patternStitches) ==
                "Pattern stitch gauge must be between 1 and 99 stitches."
        )
        let announcement = draft.finishEditing()
        #expect(draft.focusedField == .patternStitches)
        #expect(announcement == "Pattern stitch gauge must be between 1 and 99 stitches.")

        draft.commitPicker(1, for: .patternStitches)
        draft.commitPicker(99, for: .patternRows)
        #expect(draft[.patternStitches] == "1")
        #expect(draft[.patternRows] == "99")
        #expect(draft.inputs != nil)
        #expect(draft.validationMessages.isEmpty)

        draft = GaugeFormDraft(
            values: original,
            unit: .centimeters,
            patternDetailsExpanded: true
        )
        let snapshot = draft.reset()
        #expect(draft.rawValues == GaugeTextDefaults().resetSceneDraftValues)
        #expect(!draft.patternDetailsExpanded)
        draft.restore(snapshot)
        #expect(draft.rawValues == original)
        #expect(draft.patternDetailsExpanded)
        #expect(draft.focusedField == nil)
    }

    @Test func stepperPickerAndAccessibilitySemanticsAreDeterministic() {
        let contract = GaugeStepperField.accessibilityContract(
            text: "32",
            unit: "ro",
            fieldLabel: "Swatch row gauge, per 10 centimeters",
            mismatchLabel: "Row gauge mismatch detected",
            mismatchDelta: 8
        )

        #expect(
            contract.fieldValue ==
                "32 rows, row gauge mismatch detected, +8"
        )
        #expect(contract.pickerLabel == "Open picker for Swatch row gauge, per 10 centimeters")
        #expect(contract.pickerValue == "Warning")
        #expect(contract.warningSummary == "Row gauge mismatch detected")
        #expect(contract.actions == ["Increment", "Decrement"])
        #expect(
            contract.pickerHint ==
                "Row gauge mismatch detected. Opens the wheel picker and warning details."
        )
        #expect(
            GaugeStepperField.pickerSelection(
                validationText: "32",
                field: .yourRows,
                displayUnit: nil,
                range: 1...99
            ) == 32
        )
        #expect(
            GaugeStepperField.adjustedText(
                "32",
                by: 1,
                field: .yourRows,
                displayUnit: nil,
                range: 1...99
            ) == "33"
        )
        #expect(
            GaugeStepperField.adjustedText(
                "1",
                by: -1,
                field: .yourRows,
                displayUnit: nil,
                range: 1...99
            ) == "1"
        )
        #expect(
            GaugeStepperField.committedText(
                selection: 8,
                field: .patternYoke,
                displayUnit: .inches
            ) == "20.32"
        )
    }

    @Test func sixJacquardScenariosAndOptionalResultSectionsRemainExplicit() {
        let scenarios = [
            Scenario(
                name: "perfect match", yourStitches: 32, yourRows: 24,
                stitchMismatch: false, rowMismatch: false,
                stitchSummary: "Stitch-wise width adjusted: 100%",
                rowSummary: "Row-wise density adjusted: 100%"
            ),
            Scenario(
                name: "denser rows", yourStitches: 32, yourRows: 32,
                stitchMismatch: false, rowMismatch: true,
                stitchSummary: "Stitch-wise width adjusted: 100%",
                rowSummary: "Row-wise density adjusted: 133%"
            ),
            Scenario(
                name: "looser rows", yourStitches: 32, yourRows: 20,
                stitchMismatch: false, rowMismatch: true,
                stitchSummary: "Stitch-wise width adjusted: 100%",
                rowSummary: "Row-wise density adjusted: 83%"
            ),
            Scenario(
                name: "denser stitches", yourStitches: 36, yourRows: 24,
                stitchMismatch: true, rowMismatch: false,
                stitchSummary: "Stitch-wise width adjusted: 89%",
                rowSummary: "Row-wise density adjusted: 100%"
            ),
            Scenario(
                name: "looser stitches", yourStitches: 28, yourRows: 24,
                stitchMismatch: true, rowMismatch: false,
                stitchSummary: "Stitch-wise width adjusted: 114%",
                rowSummary: "Row-wise density adjusted: 100%"
            ),
            Scenario(
                name: "both denser", yourStitches: 36, yourRows: 32,
                stitchMismatch: true, rowMismatch: true,
                stitchSummary: "Stitch-wise width adjusted: 89%",
                rowSummary: "Row-wise density adjusted: 133%"
            ),
        ]

        for scenario in scenarios {
            let inputs = GaugeInputs(
                patternStitches: 32,
                patternRows: 24,
                yourStitches: scenario.yourStitches,
                yourRows: scenario.yourRows
            )
            let semantics = ResultCardSemantics(inputs: inputs, result: GaugeMath.compute(inputs))
            #expect(inputs.stitchMismatch == scenario.stitchMismatch, "\(scenario.name): stitches")
            #expect(inputs.rowMismatch == scenario.rowMismatch, "\(scenario.name): rows")
            #expect(semantics.stitchSummary == scenario.stitchSummary, "\(scenario.name)")
            #expect(semantics.rowSummary == scenario.rowSummary, "\(scenario.name)")
        }

        let optionalMatrix = [
            OptionalScenario(name: "required only", inputs: GaugeInputs(), kinds: [.gaugeSummary, .actions]),
            OptionalScenario(
                name: "cast-on only",
                inputs: GaugeInputs(patternCastOn: 128),
                kinds: [.gaugeSummary, .castOn, .actions]
            ),
            OptionalScenario(
                name: "one length only",
                inputs: GaugeInputs(patternYokeDepth: 20),
                kinds: [.gaugeSummary, .yokeDepth, .actions]
            ),
            OptionalScenario(
                name: "shaping only",
                inputs: GaugeInputs(patternIncreaseSpacing: 6),
                kinds: [.gaugeSummary, .shapingRates, .actions]
            ),
            OptionalScenario(
                name: "all optional fields",
                inputs: GaugeInputs(
                    patternYokeDepth: 20,
                    patternBodyLength: 50,
                    patternSleeveLength: 45,
                    patternIncreaseSpacing: 6,
                    patternCastOn: 128
                ),
                kinds: [.gaugeSummary, .yokeDepth, .bodyAndSleeves, .shapingRates, .castOn, .actions]
            ),
        ]
        for scenario in optionalMatrix {
            let result = GaugeMath.compute(scenario.inputs)
            #expect(
                ResultCardSemantics(inputs: scenario.inputs, result: result).sectionKinds == scenario.kinds,
                "\(scenario.name)"
            )
        }
    }

    @Test func hostedResultsExposeExactlyOneShareResultsAffordance() throws {
        let inputs = GaugeInputs()
        let result = GaugeMath.compute(inputs)
        let semantics = ResultCardSemantics(inputs: inputs, result: result)
        #expect(semantics.actionLabels.filter { $0 == "Share results" }.count == 1)
        #expect(semantics.actionLabels.allSatisfy { !$0.localizedCaseInsensitiveContains("copy") })
        #expect(semantics.actionLabels.allSatisfy { !$0.localizedCaseInsensitiveContains("export") })

        let fullMath = ValueBox(false)
        let probe = HostedViewProbe(
            LiveResultsView(
                result: result,
                inputs: inputs,
                verdict: ("Gauge match", "Both gauges are within the match range."),
                unit: .centimeters,
                showFullMath: fullMath.binding,
                onShare: { _ in [] }
            )
        )
        #expect(probe.size.width > 0)
        #expect(probe.size.height > 0)
    }

    @Test func hostedAboutHelpHasExactCopyAndAccessibleCloseAction() {
        var state = AboutHelpState()
        state.open()
        #expect(state.isPresented)
        #expect(AboutHelpContract.openLabel == "About this calculator")
        #expect(AboutHelpContract.explanation.contains("two-axis gauge mismatch"))
        #expect(AboutHelpContract.closeLabel == "Close")
        #expect(AboutHelpContract.closeHitTarget == 44)
        #expect(AboutHelpContract.accessibilityText.count == 8)
        #expect(AboutHelpContract.accessibilityText.filter { $0 == "Close" }.count == 1)

        let closeRecorder = CloseRecorder()
        let probe = HostedViewProbe(
            AboutHelpSheet {
                closeRecorder.close()
            }
        )
        #expect(probe.size.width > 0)
        #expect(probe.size.height > 0)
        let closeAction = AboutHelpContract.closeAction {
            closeRecorder.close()
            return true
        }
        #expect(closeAction.name == AboutHelpContract.closeLabel)
        #expect(closeAction.actionHandler?(closeAction) == true)
        #expect(closeRecorder.didClose)

        state.close()
        #expect(!state.isPresented)
    }

    @Test func hostedDynamicTypeAndDisclosureLayoutsRetainSemanticContent() {
        #expect(GaugeInputsCard.usesStackedLayout(at: .accessibility5))
        #expect(!GaugeInputsCard.usesStackedLayout(at: .large))
        #expect(
            GaugeInputsCard.accessibilityFieldOrder ==
                [.patternStitches, .patternRows, .yourStitches, .yourRows]
        )
        #expect(GaugeFormContract.leadCopy.hasSuffix("affect the garment."))

        let gaugeValues = GaugeValueBindings()
        let compact = HostedViewProbe(
            gaugeValues.gaugeCard.environment(\.dynamicTypeSize, .large)
        )
        let accessible = HostedViewProbe(
            gaugeValues.gaugeCard.environment(\.dynamicTypeSize, .accessibility5)
        )
        #expect(accessible.size.width > 0)
        #expect(accessible.size.height > compact.size.height)

        let collapsedSemantics = PatternDetailsSemantics(isExpanded: false, unit: .centimeters)
        let expandedSemantics = PatternDetailsSemantics(isExpanded: true, unit: .centimeters)
        #expect(collapsedSemantics.visibleFields.isEmpty)
        #expect(
            expandedSemantics.visibleFields ==
                [.patternCastOn, .patternYoke, .patternBody, .patternSleeve, .patternIncreases]
        )
        #expect(expandedSemantics.lengthLabels == ["Yoke depth (cm)", "Body length (cm)", "Sleeve length (cm)"])
        #expect(
            PatternDetailsSemantics(isExpanded: true, unit: .inches).lengthLabels ==
                ["Yoke depth (in)", "Body length (in)", "Sleeve length (in)"]
        )

        let collapsed = HostedViewProbe(gaugeValues.patternCard(expanded: false))
        let expanded = HostedViewProbe(gaugeValues.patternCard(expanded: true))
        #expect(expanded.size.height > collapsed.size.height)
        #expect(expandedSemantics.disclosureLabel == "Pattern details (optional)")
        #expect(
            expandedSemantics.disclosureHint ==
                "Expands optional unit, cast-on, length, and shaping fields"
        )
    }

    @Test func adaptiveTextTokensMeetContrastAndRepresentativeViewRenders() throws {
        let traits = [
            UITraitCollection(userInterfaceStyle: .light),
            UITraitCollection(userInterfaceStyle: .dark),
        ]
        for pair in AppTheme.textContrastPairs {
            let foregroundColors = try assetColors(named: pair.foreground)
            let backgroundColors = try assetColors(named: pair.background)
            for (index, trait) in traits.enumerated() {
                let foreground = foregroundColors[index]
                let background = backgroundColors[index]
                #expect(
                    contrastRatio(foreground, background) >= pair.minimumRatio,
                    "\(pair.foreground) on \(pair.background), \(trait.userInterfaceStyle)"
                )
            }
        }

        let ink = try #require(assetColors(named: "app-theme-ink").first)
        let background = try #require(assetColors(named: "app-theme-background").first)
        let image = UIGraphicsImageRenderer(size: CGSize(width: 44, height: 44)).image { _ in
            background.setFill()
            UIRectFill(CGRect(x: 0, y: 0, width: 44, height: 44))
            ink.setFill()
            UIRectFill(CGRect(x: 10, y: 10, width: 24, height: 24))
        }
        #expect(image.size == CGSize(width: 44, height: 44))
    }

    @Test func verdictHelpHasNoProductDestination() {
        #expect(HelpDestination.allCases == [.about])
    }
}

private struct Scenario {
    let name: String
    let yourStitches: Double
    let yourRows: Double
    let stitchMismatch: Bool
    let rowMismatch: Bool
    let stitchSummary: String
    let rowSummary: String
}

private struct OptionalScenario {
    let name: String
    let inputs: GaugeInputs
    let kinds: [ResultSectionKind]
}

@MainActor
private final class ValueBox<Value> {
    var value: Value

    init(_ value: Value) {
        self.value = value
    }

    var binding: Binding<Value> {
        Binding(
            get: { self.value },
            set: { self.value = $0 }
        )
    }
}

@MainActor
private final class CloseRecorder {
    private(set) var didClose = false

    func close() {
        didClose = true
    }
}

@MainActor
private final class GaugeValueBindings {
    private let values = [
        ValueBox("32"), ValueBox("24"), ValueBox("32"), ValueBox("32"),
        ValueBox(""), ValueBox(""), ValueBox(""), ValueBox(""), ValueBox(""),
    ]
    private let focus = ValueBox<GaugeFormField?>(nil)
    private let unit = ValueBox(MeasurementUnit.centimeters)

    var gaugeCard: some View {
        GaugeInputsCard(
            patternStitches: values[0].binding,
            patternRows: values[1].binding,
            yourStitches: values[2].binding,
            yourRows: values[3].binding,
            stitchMismatch: false,
            rowMismatch: true,
            stitchDelta: 0,
            rowDelta: 8,
            validationMessages: [:],
            focusedField: focus.binding,
            onSubmit: {}
        )
    }

    func patternCard(expanded: Bool) -> some View {
        PatternInstructionsCard(
            patternCastOn: values[4].binding,
            patternYoke: values[5].binding,
            patternBody: values[6].binding,
            patternSleeve: values[7].binding,
            patternIncreases: values[8].binding,
            unit: unit.binding,
            isExpanded: ValueBox(expanded).binding,
            validationMessages: [:],
            focusedField: focus.binding,
            onSubmit: {}
        )
    }
}

@MainActor
private final class HostedViewProbe {
    private let controller: UIHostingController<AnyView>
    let size: CGSize

    init<Content: View>(_ content: Content, width: CGFloat = 390) {
        controller = UIHostingController(rootView: AnyView(content))
        controller.loadViewIfNeeded()
        size = controller.view.sizeThatFits(
            CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        )
        controller.view.frame = CGRect(origin: .zero, size: CGSize(width: width, height: size.height))
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
    }

}

private func assetColors(named name: String) throws -> [UIColor] {
    let appDirectory = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
    let url = appDirectory
        .appendingPathComponent("KnittingGaugeReconciler/Assets.xcassets")
        .appendingPathComponent("\(name).colorset/Contents.json")
    let data = try Data(contentsOf: url)
    let json = try JSONSerialization.jsonObject(with: data)
    guard let dictionary = json as? [String: Any],
          let colors = dictionary["colors"] as? [[String: Any]] else {
        return []
    }
    return colors.compactMap { entry in
        guard let color = entry["color"] as? [String: Any],
              let components = color["components"] as? [String: String],
              let red = components["red"].flatMap(Double.init),
              let green = components["green"].flatMap(Double.init),
              let blue = components["blue"].flatMap(Double.init) else {
            return nil
        }
        return UIColor(red: red, green: green, blue: blue, alpha: 1)
    }
}

private func contrastRatio(_ first: UIColor, _ second: UIColor) -> Double {
    let lighter = max(relativeLuminance(first), relativeLuminance(second))
    let darker = min(relativeLuminance(first), relativeLuminance(second))
    return (lighter + 0.05) / (darker + 0.05)
}

private func relativeLuminance(_ color: UIColor) -> Double {
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    guard color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
        return 0
    }
    func linearized(_ component: CGFloat) -> Double {
        let value = Double(component)
        return value <= 0.04045
            ? value / 12.92
            : pow((value + 0.055) / 1.055, 2.4)
    }
    return 0.2126 * linearized(red) +
        0.7152 * linearized(green) +
        0.0722 * linearized(blue)
}
