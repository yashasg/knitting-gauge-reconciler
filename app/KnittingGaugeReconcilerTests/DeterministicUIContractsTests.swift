// swiftlint:disable file_length type_body_length
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

        let stateBox = ValueBox(state)
        let sheet = AboutHelpSheet(state: stateBox.binding)
        let probe = HostedViewProbe(sheet)
        #expect(probe.size.width > 0)
        #expect(probe.size.height > 0)
        sheet.close()
        #expect(!stateBox.value.isPresented)

        let closeRecorder = CloseRecorder()
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

    @Test func everyFormFieldMapsValidatesFocusesAndCommits() {
        let mappings: [(GaugeFormField, GaugeMath.Field, String, Bool)] = [
            (.patternStitches, .patternStitches, "Pattern stitch gauge", false),
            (.patternRows, .patternRows, "Pattern row gauge", false),
            (.yourStitches, .yourStitches, "Swatch stitch gauge", false),
            (.yourRows, .yourRows, "Swatch row gauge", false),
            (.patternCastOn, .patternCastOn, "Cast-on stitches", true),
            (.patternYoke, .patternYokeDepth, "Yoke depth", true),
            (.patternBody, .patternBodyLength, "Body length", true),
            (.patternSleeve, .patternSleeveLength, "Sleeve length", true),
            (.patternIncreases, .patternIncreaseSpacing, "Increase spacing", true),
        ]
        #expect(mappings.count == GaugeFormField.allCases.count)
        for (field, mathField, name, isDetail) in mappings {
            #expect(field.mathField == mathField)
            #expect(field.correctionName == name)
            #expect(field.isPatternDetail == isDetail)
        }

        let cases: [(GaugeFormField, String, String)] = [
            (.patternStitches, "", "Pattern stitch gauge is required."),
            (.patternRows, "abc", "Enter pattern row gauge as a number."),
            (.yourStitches, "abc", "Enter swatch stitch gauge as a number."),
            (.yourRows, "100", "Swatch row gauge must be between 1 and 99 rows."),
            (.patternCastOn, "39", "Cast-on stitches must be between 40 and 400 stitches."),
            (.patternCastOn, "40.5", "Enter cast-on stitches as a whole number."),
            (.patternYoke, "4", "Yoke depth must be between 5 and 100 cm."),
            (.patternBody, "101", "Body length must be between 5 and 100 cm."),
            (.patternSleeve, "4", "Sleeve length must be between 5 and 100 cm."),
            (.patternIncreases, "31", "Increase spacing must be between 1 and 30 rows."),
        ]
        for (field, value, message) in cases {
            var draft = GaugeFormDraft()
            draft[field] = value
            #expect(draft.validationMessage(for: field) == message)
        }
        var messagesDraft = GaugeFormDraft()
        messagesDraft[.patternRows] = ""
        #expect(
            messagesDraft.validationMessages ==
                [.patternRows: "Pattern row gauge is required."]
        )

        var detailDraft = GaugeFormDraft()
        detailDraft[.patternBody] = "bad"
        #expect(detailDraft.finishEditing() == "Enter body length as a number.")
        #expect(detailDraft.focusedField == .patternBody)
        #expect(detailDraft.patternDetailsExpanded)

        var committed = GaugeFormDraft(unit: .inches)
        for field in GaugeFormField.allCases {
            committed.commitPicker(8, for: field)
        }
        #expect(committed[.patternStitches] == "8")
        #expect(committed[.patternCastOn] == "8")
        #expect(committed[.patternYoke] == "20.32")
        #expect(committed[.patternBody] == "20.32")
        #expect(committed[.patternSleeve] == "20.32")
    }

    @Test func invalidInchValidationAndPatternBindingsPreserveUserText() {
        var draft = GaugeFormDraft(unit: .inches)
        draft[.patternYoke] = MeasurementUnit.inches.centimeterStorageText(
            from: "1",
            cmRange: 5...100
        )
        #expect(
            draft.validationMessage(for: .patternYoke) ==
                "Yoke depth must be a whole number between 2 and 39 in. Entered: 1."
        )

        let values = GaugeValueBindings()
        values.unit.value = .inches
        values.value(at: 5).value = "20.32"
        let card = values.patternInstructionsCard(expanded: true)
        let yoke = card.displayBinding(for: values.value(at: 5).binding, field: .patternYoke)
        #expect(yoke.wrappedValue == "8")
        yoke.wrappedValue = "9"
        #expect(values.value(at: 5).value == "22.86")
        yoke.wrappedValue = ""
        #expect(values.value(at: 5).value == "")
        #expect(yoke.wrappedValue == "")

        values.value(at: 5).value = "not-a-number"
        #expect(yoke.wrappedValue == "not-a-number")
        values.value(at: 5).value = MeasurementUnit.inches.centimeterStorageText(
            from: "1",
            cmRange: 5...100
        )
        #expect(yoke.wrappedValue == "1")
        values.unit.value = .centimeters
        values.value(at: 5).value = "20"
        #expect(yoke.wrappedValue == "20")
    }

    @Test func sceneDraftStoreRejectsMalformedRestorationData() throws {
        let values = GaugeTextDefaults().resetSceneDraftValues
        let serialized = SceneDraftStore.serialize(values: values, disclosure: true)
        let decoded = try #require(SceneDraftStore.deserialize(serialized))
        #expect(decoded.values == values)
        #expect(decoded.disclosure)
        #expect(SceneDraftStore.deserialize([:]) == nil)
        #expect(
            SceneDraftStore.deserialize([
                SceneDraftStore.rawValuesKey: Array(values.dropLast()),
                SceneDraftStore.disclosureKey: true,
            ]) == nil
        )
        #expect(
            SceneDraftStore.deserialize([
                SceneDraftStore.rawValuesKey: values,
                SceneDraftStore.disclosureKey: "yes",
            ]) == nil
        )
        #expect(SceneDraftStore.reconcileInvalidInchProvenance(in: values, for: .inches) == values)
        #expect(
            SceneDraftStore.reconcileInvalidInchProvenance(
                in: Array(values.dropLast()),
                for: .centimeters
            ) == Array(values.dropLast())
        )
    }

    @Test func stepperHelpersCoverValidationUnitsWarningsAndDetents() {
        let contracts = [
            GaugeStepperField.accessibilityContract(
                text: " ",
                unit: "st",
                fieldLabel: "Pattern stitches"
            ),
            GaugeStepperField.accessibilityContract(
                text: "24",
                unit: "cm",
                fieldLabel: "Yoke",
                validationMessage: "Invalid"
            ),
        ]
        #expect(contracts[0].fieldValue == "Empty")
        #expect(contracts[0].fieldHint == "Double-tap to edit.")
        #expect(contracts[0].pickerHint == "Double-tap to open wheel picker.")
        #expect(contracts[1].fieldValue == "24 cm, Invalid")
        #expect(contracts[1].fieldHint == "Correct this value before viewing results.")

        #expect(
            GaugeStepperField.pickerSelection(
                validationText: "",
                field: .patternYoke,
                displayUnit: .inches,
                range: 2...39
            ) == 2
        )
        #expect(
            GaugeStepperField.pickerSelection(
                validationText: "100",
                field: .patternYoke,
                displayUnit: .inches,
                range: 2...39
            ) == 39
        )
        #expect(
            GaugeStepperField.pickerSelection(
                validationText: "50",
                field: .yourRows,
                displayUnit: nil,
                range: 1...10
            ) == 1
        )
        #expect(
            GaugeStepperField.committedText(
                selection: 7,
                field: .patternStitches,
                displayUnit: nil
            ) == "7"
        )
        #expect(
            GaugeStepperField.committedText(
                selection: 7,
                field: .patternBody,
                displayUnit: nil
            ) == "7"
        )
        #expect(
            GaugeStepperField.adjustedText(
                "99",
                by: 1,
                field: .yourStitches,
                displayUnit: nil,
                range: 1...99
            ) == "99"
        )
        #expect(GaugeStepperField.sheetDetents(for: .accessibility1, hasWarning: false) == [.large])
        #expect(GaugeStepperField.sheetDetents(for: .large, hasWarning: true) == [.medium, .large])
        #expect(GaugeStepperField.sheetDetents(for: .large, hasWarning: false) == [.height(280)])
    }

    @Test func keyboardCoordinatorPropagatesTextFocusAndSubmit() async throws {
        let text = ValueBox("24")
        let focus = ValueBox<GaugeFormField?>(nil)
        let recorder = ActionRecorder()
        let field = GaugeKeyboardTextField(
            text: text.binding,
            field: .yourRows,
            focusedField: focus.binding,
            label: "Rows",
            value: "24 rows",
            hint: "Double-tap to edit.",
            identifier: "rows-field",
            showsCorrection: false,
            onSubmit: recorder.record
        )
        let coordinator = field.makeCoordinator()
        let textField = FocusRecordingTextField()
        GaugeKeyboardTextField.updateFocus(true, textField: textField)
        GaugeKeyboardTextField.updateFocus(false, textField: textField)
        #expect(textField.becameFirstResponder)
        #expect(textField.resignedFirstResponder)

        textField.text = "31"
        coordinator.textDidChange(textField)
        #expect(text.value == "31")
        textField.text = nil
        coordinator.textDidChange(textField)
        #expect(text.value == "")
        coordinator.textDidChange(NilTextField())
        #expect(text.value == "")

        coordinator.textFieldDidBeginEditing(textField)
        coordinator.textFieldDidBeginEditing(textField)
        #expect(focus.value == .yourRows)
        coordinator.textFieldDidEndEditing(textField)
        coordinator.textFieldDidEndEditing(textField)
        #expect(focus.value == nil)
        coordinator.didTapDone()
        #expect(recorder.count == 1)

        focus.value = .yourRows
        await GaugeKeyboardTextField.updateFocusAfterUpdate(
            coordinator: coordinator,
            textField: textField
        ).value
        #expect(textField.becameFirstResponder)
    }

    @Test func adjustmentRowsExposeStableIdentifiersLabelsAndAdaptiveLayouts() {
        let plainRow = AdjustmentRow(
            name: "Body length",
            pattern: "50 cm",
            adjusted: "37.5 cm"
        )
        #expect(
            AdjustmentRow.defaultAdjustedIdentifier(name: "Body length") ==
                "adjustment-body-length-value"
        )
        #expect(
            AdjustmentRow.adjustedAccessibilityLabel(
                name: "Body length",
                adjusted: "37.5 cm",
                driftPill: nil
            ) == "Body length adjusted: 37.5 cm"
        )

        let driftRow = AdjustmentRow(
            name: "Cast-on stitches",
            pattern: "40 stitches",
            adjusted: "99 stitches",
            adjustedIdentifier: "cast-on-result",
            driftPill: "+4% width"
        )
        #expect(
            AdjustmentRow.adjustedAccessibilityLabel(
                name: "Cast-on stitches",
                adjusted: "99 stitches",
                driftPill: "+4% width"
            ) ==
                "Cast-on stitches adjusted: 99 stitches, +4% width drift"
        )

        let compact = HostedViewProbe(plainRow.environment(\.dynamicTypeSize, .large))
        let accessible = HostedViewProbe(driftRow.environment(\.dynamicTypeSize, .accessibility3))
        #expect(compact.size.width > 0)
        #expect(accessible.size.height > compact.size.height)
    }

    @Test func hostedCardsCoverInvalidRequiredOptionalFullMathAndStatusBranches() {
        let invalidValues = GaugeValueBindings()
        let invalidCard = HostedViewProbe(
            invalidValues.gaugeCard(
                validationMessages: [.patternRows: "Pattern row gauge is required."]
            )
        )
        #expect(invalidCard.size.height > 0)

        let inputs = GaugeInputs(
            patternStitches: 99,
            patternRows: 24,
            yourStitches: 4,
            yourRows: 32,
            patternYokeDepth: 20,
            patternBodyLength: 50,
            patternSleeveLength: 45,
            patternIncreaseSpacing: 6,
            patternCastOn: 41
        )
        let result = GaugeMath.compute(inputs)
        let fullMath = ValueBox(true)
        let live = LiveResultsView(
            result: result,
            inputs: inputs,
            verdict: ("Major mismatch", "Both axes are off."),
            unit: .inches,
            showFullMath: fullMath.binding,
            onShare: { _ in ["share"] }
        )
        #expect(live.castOnDriftPill != nil)
        #expect(live.fullMathBreakdown.contains("yoke:"))
        #expect(live.fullMathBreakdown.contains("body:"))
        #expect(live.fullMathBreakdown.contains("sleeve:"))
        #expect(live.fullMathBreakdown.contains("increase spacing"))
        #expect(live.fullMathBreakdown.contains("cast-on adjust"))
        let liveProbe = HostedViewProbe(live.environment(\.dynamicTypeSize, .accessibility2))
        #expect(liveProbe.size.height > 0)

        let invalidResult = HostedViewProbe(
            RequiredAdjustmentsCard(
                result: nil,
                inputs: nil,
                verdict: ("", "Fix fields"),
                unit: .centimeters,
                showFullMath: ValueBox(false).binding,
                canUndoReset: true,
                onReset: {},
                onUndoReset: {},
                onShare: { _ in [] }
            )
        )
        #expect(invalidResult.size.height > 0)

        let noDriftInputs = GaugeInputs(patternCastOn: 128)
        let noDriftResult = GaugeMath.compute(noDriftInputs)
        let noDrift = LiveResultsView(
            result: noDriftResult,
            inputs: noDriftInputs,
            verdict: ("Gauge match", "Both gauges match."),
            unit: .centimeters,
            showFullMath: ValueBox(false).binding,
            onShare: { _ in [] }
        )
        #expect(noDrift.castOnDriftPill == nil)
        #expect(HostedViewProbe(noDrift).size.height > 0)

        let refinementInputs = GaugeInputs(
            yourStitches: 32.5,
            yourRows: 24,
            patternCastOn: 128
        )
        let refinement = LiveResultsView(
            result: GaugeMath.compute(refinementInputs),
            inputs: refinementInputs,
            verdict: ("Gauge match", "Within range."),
            unit: .centimeters,
            showFullMath: ValueBox(false).binding,
            onShare: { _ in [] }
        )
        #expect(
            HostedViewProbe(
                refinement.environment(\.colorScheme, .dark)
            ).size.height > 0
        )

        let moderateInputs = GaugeInputs(yourStitches: 30, yourRows: 26)
        let moderate = LiveResultsView(
            result: GaugeMath.compute(moderateInputs),
            inputs: moderateInputs,
            verdict: ("Drift", "Both axes are slightly off."),
            unit: .centimeters,
            showFullMath: ValueBox(false).binding,
            onShare: { _ in [] }
        )
        #expect(HostedViewProbe(moderate).size.height > 0)
    }

    @Test func shareableRequiredAndFullCardsRenderAllStatusColors() throws {
        let statusInputs = [
            GaugeInputs(),
            GaugeInputs(yourStitches: 30, yourRows: 26),
            GaugeInputs(yourStitches: 50, yourRows: 40),
        ]
        let statuses = statusInputs.map {
            ResultsExportSummary(inputs: $0, result: GaugeMath.compute($0))
        }
        #expect(statuses[0].stitchMetric.status == "Match")
        #expect(!statuses[1].stitchMetric.status.hasPrefix("Much"))
        #expect(statuses[2].stitchMetric.status.hasPrefix("Much"))
        _ = shareMetricBackground(statuses[0].stitchMetric.status)
        _ = shareMetricBackground(statuses[1].stitchMetric.status)
        _ = shareMetricBackground(statuses[2].stitchMetric.status)

        for summary in statuses {
            let probe = HostedViewProbe(ShareableView(summary: summary))
            #expect(probe.size.width == 390)
            #expect(probe.size.height > 0)
        }

        let fullInputs = GaugeInputs(
            yourStitches: 36,
            yourRows: 32,
            patternYokeDepth: 20,
            patternBodyLength: 50,
            patternSleeveLength: 45,
            patternIncreaseSpacing: 6,
            patternCastOn: 128
        )
        let fullSummary = ResultsExportSummary(
            inputs: fullInputs,
            result: GaugeMath.compute(fullInputs),
            unit: .inches
        )
        #expect(!ShareableView.pngData(summary: fullSummary).isEmpty)
    }

    @Test func texturedBackgroundRendersPixelsAtRequestedSize() throws {
        let size = CGSize(width: 42, height: 28)
        let renderer = ImageRenderer(
            content: TexturedBackground()
                .frame(width: size.width, height: size.height)
                .background(AppTheme.background)
        )
        renderer.proposedSize = .init(size)
        var renderedImage: UIImage?
        renderer.render(rasterizationScale: 2) { renderedSize, draw in
            renderedImage = UIGraphicsImageRenderer(size: renderedSize).image { context in
                draw(context.cgContext)
            }
        }
        let image = try #require(renderedImage)
        #expect(image.size == size)
        #expect(try #require(image.pngData()).isEmpty == false)
    }

    @Test func homeHelpActionAndActivityControllerUsePublicContracts() {
        let state = ValueBox(AboutHelpState())
        let button = AboutHelpToolbarButton(state: state.binding)
        button.open()
        #expect(state.value.isPresented)
        #expect(HostedViewProbe(button).size.width > 0)

        let activity = ActivityView(activityItems: ["Gauge result"])
        let probe = HostedViewProbe(activity)
        #expect(probe.size.width > 0)
    }

    @Test func wheelSheetsAndKeyboardFieldsHostBothWarningLayouts() {
        let text = ValueBox("32")
        let presented = ValueBox(true)
        let warning = GaugeStepperWheelSheet(
            title: "Rows",
            text: text.binding,
            range: 1...99,
            identifier: "rows",
            validationText: "32",
            field: .yourRows,
            accessibilityLabel: "Swatch rows",
            displayUnit: nil,
            mismatchLabel: "Row gauge mismatch detected",
            mismatchDeltaText: "+8",
            isPresented: presented.binding
        )
        warning.commit()
        #expect(!presented.value)
        #expect(HostedViewProbe(warning).size.height > 0)

        let plain = GaugeStepperWheelSheet(
            title: "Yoke",
            text: text.binding,
            range: 2...39,
            identifier: "yoke",
            validationText: "",
            field: .patternYoke,
            accessibilityLabel: "Yoke depth",
            displayUnit: .inches,
            mismatchLabel: nil,
            mismatchDeltaText: nil,
            isPresented: presented.binding
        )
        plain.commit()
        #expect(HostedViewProbe(plain.environment(\.dynamicTypeSize, .accessibility1)).size.height > 0)

        text.value = "32"
        let focus = ValueBox<GaugeFormField?>(.yourRows)
        let keyboard = GaugeKeyboardTextField(
            text: text.binding,
            field: .yourRows,
            focusedField: focus.binding,
            label: "Rows",
            value: "32 rows",
            hint: "Edit",
            identifier: "rows-field",
            showsCorrection: true,
            onSubmit: {}
        )
        #expect(HostedViewProbe(keyboard).size.height > 0)

        let stepper = GaugeStepperField(
            title: "Rows",
            text: text.binding,
            unit: "ro",
            identifier: "rows",
            field: .yourRows,
            validationMessage: nil,
            focusedField: focus.binding,
            onSubmit: {},
            hasMismatch: true,
            mismatchLabel: "Row gauge mismatch detected",
            mismatchDelta: 8
        )
        text.value = "32"
        stepper.openPicker()
        stepper.increment()
        #expect(text.value == "33")
        stepper.decrement()
        #expect(text.value == "31")
        #expect(HostedViewProbe(stepper.wheelSheet()).size.height > 0)
    }

    @Test func defaultPairPayloadAndAccessiblePatternLeavesAreLive() {
        let pair = GaugeMeasurementPair {
            Text("Pattern")
        } trailing: {
            Text("Adjusted")
        }
        #expect(HostedViewProbe(pair).size.height > 0)

        let id = UUID()
        let payload = ShareSheetPayload(id: id, items: ["Gauge"])
        #expect(payload.items.count == 1)
        #expect(payload.id == id)

        let values = GaugeValueBindings()
        let pattern = values.patternInstructionsCard(expanded: true)
            .environment(\.dynamicTypeSize, .accessibility3)
        #expect(HostedViewProbe(pattern).size.height > 0)
    }

    @Test func validRequiredCardHostsLiveResultsAndResetChrome() {
        let inputs = GaugeInputs(
            patternYokeDepth: 20,
            patternBodyLength: 50,
            patternSleeveLength: 45,
            patternIncreaseSpacing: 6,
            patternCastOn: 128
        )
        let result = GaugeMath.compute(inputs)
        let card = RequiredAdjustmentsCard(
            result: result,
            inputs: inputs,
            verdict: ("Gauge match", "Both gauges match."),
            unit: .centimeters,
            showFullMath: ValueBox(false).binding,
            canUndoReset: false,
            onReset: {},
            onUndoReset: {},
            onShare: { _ in ["Gauge"] }
        )
        card.requestReset()
        card.keepEditing()
        #expect(HostedViewProbe(card).size.height > 0)
    }

    @Test func sharePreparationStartsOnceCompletesAndHonorsCancellation() async {
        var preparation = SharePreparationState()
        let inputs = GaugeInputs()
        let result = GaugeMath.compute(inputs)
        await preparation.prepare(result: result) { _ in ["ignored"] }
        #expect(preparation.payload == nil)

        preparation.begin()
        preparation.begin()
        #expect(preparation.isPreparing)
        await preparation.prepare(result: result) { _ in ["Gauge"] }
        #expect(!preparation.isPreparing)
        #expect(preparation.payload?.items.first as? String == "Gauge")

        preparation.begin()
        preparation.finish(items: ["Cancelled"], cancelled: true)
        #expect(!preparation.isPreparing)
        #expect(preparation.payload?.items.first as? String == "Gauge")

        let fullMath = ValueBox(false)
        let view = LiveResultsView(
            result: result,
            inputs: inputs,
            verdict: ("Gauge match", "Within range."),
            unit: .centimeters,
            showFullMath: fullMath.binding,
            onShare: { _ in ["Gauge"] }
        )
        view.toggleFullMath()
        #expect(fullMath.value)
        view.beginSharing()
        await view.prepareShare()
        let payload = ShareSheetPayload(items: ["Gauge"])
        #expect(HostedViewProbe(view.activityView(payload)).size.width > 0)
    }

    @Test func contentRendersAndUpdatesNativeRestorationActivity() async throws {
        let content = HostedViewProbe(ContentView())
        #expect(content.size.width > 0)
        await Task.yield()
        await Task.yield()

        let activity = NSUserActivity(activityType: "test.scene-draft")
        let view = ContentView()
        view.updateSceneRestorationActivity(activity)
        let restored = try #require(
            activity.userInfo.flatMap(SceneDraftStore.deserialize)
        )
        #expect(restored.values == GaugeTextDefaults().resetSceneDraftValues)
        #expect(!restored.disclosure)

        view.restoreSceneDraft(NSUserActivity(activityType: "empty"))
        view.restoreSceneDraft(activity)

        let scene = KnittingGaugeReconcilerApp().body
        #expect(String(reflecting: type(of: scene)).contains("WindowGroup"))
        #expect(HostedViewProbe(KnittingGaugeReconcilerApp.content()).size.width > 0)
    }

    @Test func contentBindingsActionsLifecycleAndSharingAreDeterministic() async throws {
        let view = ContentView()
        let text = ValueBox("32")
        let draftBinding = view.draftBinding(text.binding, at: 0)
        draftBinding.wrappedValue = "32"
        draftBinding.wrappedValue = "31"
        #expect(text.value == "31")

        let details = view.patternDetailsBinding
        details.wrappedValue = details.wrappedValue
        details.wrappedValue = true
        let unit = view.measurementUnitBinding
        unit.wrappedValue = unit.wrappedValue
        unit.wrappedValue = .inches
        let rawInchDraft = MeasurementUnit.inches.centimeterStorageText(
            from: "1",
            cmRange: 5...100
        )
        var inchValues = view.rawTextValues
        inchValues[5] = rawInchDraft
        #expect(
            ContentView.reconciledSceneDraft(
                values: inchValues,
                from: .centimeters,
                to: .inches
            ) == nil
        )
        let reconciledValues = try #require(
            ContentView.reconciledSceneDraft(
                values: inchValues,
                from: .inches,
                to: .centimeters
            )
        )
        #expect(reconciledValues[5] == "1")
        #expect(Array(reconciledValues[0...4]) == Array(inchValues[0...4]))
        let unchangedValues = view.rawTextValues
        #expect(view.reconcileSceneDraft(from: .centimeters, to: .inches) == nil)
        #expect(view.rawTextValues == unchangedValues)
        let appliedValues = try #require(
            view.reconcileSceneDraft(from: .inches, to: .centimeters)
        )
        #expect(
            appliedValues ==
                SceneDraftStore.reconcileInvalidInchProvenance(
                    in: unchangedValues,
                    for: .centimeters
                )
        )
        unit.wrappedValue = .centimeters
        view.finishEditing()
        var invalidDraft = GaugeFormDraft()
        invalidDraft[.patternStitches] = ""
        ContentView.finishEditing(&invalidDraft)
        #expect(invalidDraft.focusedField == .patternStitches)

        view.undoReset()
        view.resetToDefaults()
        view.undoReset()
        #expect(view.formDraft.rawValues.count == GaugeFormField.allCases.count)

        let telemetryCases: [
            (decision: StaticString?, expected: String?, perform: () -> Void)
        ] = [
            (
                ContentView.helpSignpostName(previous: true, current: false),
                nil,
                { view.helpPresentationChanged(true, false) }
            ),
            (
                ContentView.helpSignpostName(previous: false, current: true),
                SignpostNames.sheetAboutHelpOpened.description,
                { view.helpPresentationChanged(false, true) }
            ),
            (
                ContentView.verdictSignpostName(previous: "", current: "Gauge match"),
                nil,
                { view.verdictChanged("", "Gauge match") }
            ),
            (
                ContentView.verdictSignpostName(previous: "Gauge match", current: "Drift"),
                SignpostNames.verdictDegraded.description,
                { view.verdictChanged("Gauge match", "Drift") }
            ),
            (
                ContentView.verdictSignpostName(
                    previous: "Major mismatch",
                    current: "Gauge match"
                ),
                SignpostNames.verdictImproved.description,
                { view.verdictChanged("Major mismatch", "Gauge match") }
            ),
            (
                ContentView.driftBandSignpostName(previous: true, current: false),
                nil,
                { view.castOnDriftChanged(true, false) }
            ),
            (
                ContentView.driftBandSignpostName(previous: false, current: true),
                SignpostNames.castOnDriftBandShown.description,
                { view.castOnDriftChanged(false, true) }
            ),
        ]
        for testCase in telemetryCases {
            testCase.perform()
            #expect(testCase.decision?.description == testCase.expected)
        }

        let valuesBeforeNoOpUnitChange = view.formDraft.rawValues
        #expect(
            {
                view.measurementUnitChanged(.centimeters, .inches)
                return view.formDraft.rawValues == valuesBeforeNoOpUnitChange
            }()
        )
        let stitchError = "Pattern stitch gauge is required."
        #expect(
            view.validationMessagesChanged(
                [:],
                [.patternStitches: stitchError],
                isVoiceOverRunning: false
            ) == nil
        )
        #expect(
            view.validationMessagesChanged(
                [:],
                [:],
                isVoiceOverRunning: true
            ) == nil
        )
        #expect(
            {
                view.validationMessagesChanged(
                    [:],
                    [.patternStitches: stitchError]
                )
                return ContentView.validationAnnouncement(
                    previous: [:],
                    current: [.patternStitches: stitchError],
                    isVoiceOverRunning: true
                ) == stitchError
            }()
        )
        #expect(
            view.validationMessagesChanged(
                [:],
                [.patternStitches: stitchError],
                isVoiceOverRunning: true
            ) == stitchError
        )
        #expect(HostedViewProbe(view.aboutHelpSheet()).size.height > 0)

        let inputs = GaugeInputs(yourRows: 24, patternCastOn: 128)
        let result = GaugeMath.compute(inputs)
        #expect(ContentView.computeResult(nil) == nil)
        #expect(ContentView.computeResult(inputs) != nil)
        let emptyPresentation = ContentView.inputPresentation(nil)
        #expect(!emptyPresentation.stitchMismatch)
        #expect(emptyPresentation.stitchDelta == nil)
        let presentation = ContentView.inputPresentation(inputs)
        #expect(!presentation.stitchMismatch)
        #expect(presentation.stitchDelta == 0)
        #expect(!ContentView.hasCastOnDrift(nil))
        #expect(!ContentView.hasCastOnDrift(result))
        #expect(ContentView.verdictTitle(inputs: nil, result: nil) == "")
        #expect(
            ContentView.resultGuidanceBody(inputs: nil, result: nil) ==
                "Correct the highlighted fields before viewing gauge guidance."
        )
        #expect(ContentView.verdictTitle(inputs: inputs, result: result) == "Gauge match")
        #expect(ContentView.resultGuidanceBody(inputs: inputs, result: result).contains("match range"))

        let significantInputs = GaugeInputs(
            patternStitches: 32,
            patternRows: 24,
            yourStitches: 35,
            yourRows: 26
        )
        let significantResult = GaugeMath.compute(significantInputs)
        #expect(view.verdictTitleComputed(result: significantResult) == "Significant drift")
        #expect(
            view.verdictBodyComputed(result: significantResult, inputs: significantInputs)
                .hasPrefix("Both axes are off.")
        )
        let rowInputs = GaugeInputs(yourRows: 30, patternYokeDepth: 20)
        #expect(
            view.verdictBodyComputed(result: GaugeMath.compute(rowInputs), inputs: rowInputs)
                .contains("Use the adjusted depth guidance below")
        )
        #expect(
            view.verdictTitleComputed(
                result: GaugeMath.compute(GaugeInputs(yourStitches: 34, yourRows: 24))
            ) == "Drift"
        )

        let emptyShare = await ContentView.shareItems(
            for: result,
            inputs: nil,
            unit: .centimeters
        )
        #expect(emptyShare.isEmpty)

        let fallback = await ContentView.shareItems(
            for: result,
            inputs: inputs,
            unit: .centimeters,
            exportDirectory: URL(fileURLWithPath: "/dev/null/share-exports")
        )
        #expect(fallback.first is String)

        let shared = await ContentView.shareItems(
            for: result,
            inputs: inputs,
            unit: .centimeters
        )
        let url = try #require(shared.first as? URL)
        #expect(FileManager.default.fileExists(atPath: url.path))
        try FileManager.default.removeItem(at: url)

        let instanceItems = await view.shareItems(for: result)
        let instanceURL = try #require(instanceItems.first as? URL)
        try FileManager.default.removeItem(at: instanceURL)
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
private final class FocusRecordingTextField: UITextField {
    var becameFirstResponder = false
    var resignedFirstResponder = false

    override func becomeFirstResponder() -> Bool {
        becameFirstResponder = true
        return true
    }

    override func resignFirstResponder() -> Bool {
        resignedFirstResponder = true
        return true
    }
}

@MainActor
private final class NilTextField: UITextField {
    override var text: String? {
        get { nil }
        set {}
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
private final class ActionRecorder {
    private(set) var count = 0

    func record() {
        count += 1
    }
}

@MainActor
private final class GaugeValueBindings {
    private let values = [
        ValueBox("32"), ValueBox("24"), ValueBox("32"), ValueBox("32"),
        ValueBox(""), ValueBox(""), ValueBox(""), ValueBox(""), ValueBox(""),
    ]
    private let focus = ValueBox<GaugeFormField?>(nil)
    let unit = ValueBox(MeasurementUnit.centimeters)

    func value(at index: Int) -> ValueBox<String> {
        values[index]
    }

    var gaugeCard: some View {
        gaugeCard(validationMessages: [:])
    }

    func gaugeCard(validationMessages: [GaugeFormField: String]) -> some View {
        GaugeInputsCard(
            patternStitches: values[0].binding,
            patternRows: values[1].binding,
            yourStitches: values[2].binding,
            yourRows: values[3].binding,
            stitchMismatch: false,
            rowMismatch: true,
            stitchDelta: 0,
            rowDelta: 8,
            validationMessages: validationMessages,
            focusedField: focus.binding,
            onSubmit: {}
        )
    }

    func patternCard(expanded: Bool) -> some View {
        patternInstructionsCard(expanded: expanded)
    }

    func patternInstructionsCard(expanded: Bool) -> PatternInstructionsCard {
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
    private let window: UIWindow?
    let size: CGSize

    init<Content: View>(
        _ content: Content,
        width: CGFloat = 390,
        windowScene: UIWindowScene? = nil
    ) {
        controller = UIHostingController(rootView: AnyView(content))
        if let windowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = controller
            window.frame = CGRect(x: 0, y: 0, width: width, height: 844)
            window.isHidden = false
            self.window = window
        } else {
            window = nil
        }
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
