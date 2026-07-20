// swiftlint:disable file_length type_body_length
import SwiftUI
import Testing
import UIKit
@testable import KnittingGaugeReconciler

/*
 Retired UI contract traceability:
 - testStepperFieldOpensWheelAndKeyboard
   → contracts07And13PickerAccessibilityAndMismatchAreDeterministic,
     accessibilityAdjustmentsUseCurrentValueAndPreserveActivePickerSelection
 - testAboutHelpButtonOpensPullUpSheet → contract08HostedAboutHelpHasExactCopyAndAccessibleCloseAction
 - testVerdictHelpButtonOpensPullUpSheet → contract09ResultActionsContainNoVerdictHelp
 - testHelpSheetsExposeAccessibleCloseButton → contract08HostedAboutHelpHasExactCopyAndAccessibleCloseAction
 - testVerdictHelpSheetExposesAccessibleCloseButton
   → contract09ResultActionsContainNoVerdictHelp
 - testShareResultsIsSingleAccessibleAffordance → contract10HostedResultsExposeExactlyOneShareResultsAffordance
 - testAccessibilityDynamicTypeStacksGaugeMeasurementPairs
   → contracts11And12DynamicTypePairGeometryAndUnitLabelsRemainVisible
 - testAllJacquardScenariosAreVisibleInUI → contracts01Through06JacquardAnd14OptionalSectionsRemainExplicit
 - testUnitToggleSwitchesFieldLabel → contracts15And16FormDraftPreservesValidationRawValuesResetAndUndo
 - testMismatchWarningSummaryAppearsInWheelSheet → contracts07And13PickerAccessibilityAndMismatchAreDeterministic
 - testOptionalOutputMatrixNeverShowsIrrelevantScreenSections
   → contracts01Through06JacquardAnd14OptionalSectionsRemainExplicit
 - testValidationRoundTripPreservesRawTextFocusesFirstErrorAndReenablesResults
   → contracts15And16FormDraftPreservesValidationRawValuesResetAndUndo,
     contract15EveryFormFieldMapsValidatesFocusesAndCommits
 - testResetAndUndoRoundTripAllRawValuesAndDisclosureState
   → contracts15And16FormDraftPreservesValidationRawValuesResetAndUndo
 - testTextPixelOracleRejectsLowContrastTextBesideHighContrastDecoration
   → contract17AssetColorsMeetContrastAndAppViewRenders
 - testAboutSheetAccessibility → contract08HostedAboutHelpHasExactCopyAndAccessibleCloseAction
 - testRevisedFormCollapsedAndExpandedAccessibility
   → contracts11And12DynamicTypePairGeometryAndUnitLabelsRemainVisible
 - testRequiredOnlyResultsAccessibility → contracts11And12DynamicTypePairGeometryAndUnitLabelsRemainVisible
 */
@MainActor
struct DeterministicUIContractsTests {
    @Test func contracts15And16FormDraftPreservesValidationRawValuesResetAndUndo() throws {
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

    @Test func contracts07And13PickerAccessibilityAndMismatchAreDeterministic() {
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
            GaugeStepperField.committedText(selection: 8) == "8"
        )
    }

    @Test func contracts01Through06JacquardAnd14OptionalSectionsRemainExplicit() {
        let scenarios = [
            Scenario(
                name: "perfect match", yourStitches: 32, yourRows: 24,
                stitchMismatch: false, rowMismatch: false,
                stitchSummary: "Stitch-wise, horizontal. Pattern 32 st/10 cm · Swatch 32 st/10 cm. " +
                    "100% of pattern width.",
                rowSummary: "Row-wise, vertical. Pattern 24 rows/10 cm · Swatch 24 rows/10 cm. " +
                    "100% of pattern row density."
            ),
            Scenario(
                name: "denser rows", yourStitches: 32, yourRows: 32,
                stitchMismatch: false, rowMismatch: true,
                stitchSummary: "Stitch-wise, horizontal. Pattern 32 st/10 cm · Swatch 32 st/10 cm. " +
                    "100% of pattern width.",
                rowSummary: "Row-wise, vertical. Pattern 24 rows/10 cm · Swatch 32 rows/10 cm. " +
                    "133% of pattern row density."
            ),
            Scenario(
                name: "looser rows", yourStitches: 32, yourRows: 20,
                stitchMismatch: false, rowMismatch: true,
                stitchSummary: "Stitch-wise, horizontal. Pattern 32 st/10 cm · Swatch 32 st/10 cm. " +
                    "100% of pattern width.",
                rowSummary: "Row-wise, vertical. Pattern 24 rows/10 cm · Swatch 20 rows/10 cm. " +
                    "83% of pattern row density."
            ),
            Scenario(
                name: "denser stitches", yourStitches: 36, yourRows: 24,
                stitchMismatch: true, rowMismatch: false,
                stitchSummary: "Stitch-wise, horizontal. Pattern 32 st/10 cm · Swatch 36 st/10 cm. " +
                    "89% of pattern width.",
                rowSummary: "Row-wise, vertical. Pattern 24 rows/10 cm · Swatch 24 rows/10 cm. " +
                    "100% of pattern row density."
            ),
            Scenario(
                name: "looser stitches", yourStitches: 28, yourRows: 24,
                stitchMismatch: true, rowMismatch: false,
                stitchSummary: "Stitch-wise, horizontal. Pattern 32 st/10 cm · Swatch 28 st/10 cm. " +
                    "114% of pattern width.",
                rowSummary: "Row-wise, vertical. Pattern 24 rows/10 cm · Swatch 24 rows/10 cm. " +
                    "100% of pattern row density."
            ),
            Scenario(
                name: "both denser", yourStitches: 36, yourRows: 32,
                stitchMismatch: true, rowMismatch: true,
                stitchSummary: "Stitch-wise, horizontal. Pattern 32 st/10 cm · Swatch 36 st/10 cm. " +
                    "89% of pattern width.",
                rowSummary: "Row-wise, vertical. Pattern 24 rows/10 cm · Swatch 32 rows/10 cm. " +
                    "133% of pattern row density."
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
            #expect(semantics.stitchSummary.contains(semantics.stitchComparison), "\(scenario.name)")
            #expect(semantics.rowSummary.contains(semantics.rowComparison), "\(scenario.name)")
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
                name: "extreme cast-on warning",
                inputs: GaugeInputs(patternStitches: 99, yourStitches: 1, patternCastOn: 40),
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

    @Test func contract10HostedResultsExposeExactlyOneShareResultsAffordance() async throws {
        let inputs = GaugeInputs()
        let result = GaugeMath.compute(inputs)
        let actions = ResultActionKind.allCases.map {
            $0.label(isExpanded: false)
        }
        #expect(actions.filter { $0 == "Share results" }.count == 1)
        #expect(actions.allSatisfy { !$0.localizedCaseInsensitiveContains("copy") })
        #expect(actions.allSatisfy { !$0.localizedCaseInsensitiveContains("export") })

        let fullMath = ValueBox(false)
        let recorder = ActionRecorder()
        let view = LiveResultsView(
            result: result,
            inputs: inputs,
            unit: .centimeters,
            showFullMath: fullMath.binding,
            onShare: { _ in
                recorder.record()
                return ["Gauge result"]
            }
        )
        let probe = HostedViewProbe(view)
        var sharePreparation = SharePreparationState()
        let shareElement = probe.accessibilityElement(
            label: "Share results",
            traits: .button,
            activate: {
                sharePreparation.begin()
                return true
            }
        )
        #expect(probe.size.width > 0)
        #expect(probe.size.height > 0)
        #expect(shareElement.accessibilityLabel == "Share results")
        #expect(shareElement.accessibilityTraits.contains(.button))
        #expect(shareElement.accessibilityActivate())
        #expect(sharePreparation.isPreparing)
        await sharePreparation.prepare(result: result) { _ in
            recorder.record()
            return ["Gauge result"]
        }
        #expect(recorder.count == 1)
    }

    @Test func contract08HostedAboutHelpHasExactCopyAndAccessibleCloseAction() throws {
        let state = ValueBox(AboutHelpState())
        let button = AboutHelpToolbarButton(state: state.binding)
        let buttonProbe = HostedViewProbe(button)
        let openElement = buttonProbe.accessibilityElement(
            label: AboutHelpContract.openLabel,
            traits: .button,
            activate: {
                button.open()
                return true
            }
        )
        #expect(openElement.accessibilityTraits.contains(.button))
        #expect(openElement.accessibilityActivate())
        #expect(state.value.isPresented)

        let expectedCopy = [
            "About this calculator",
            "This tool reconciles a two-axis gauge mismatch, the kind that single-number " +
                "gauge calculators hide. When row gauge differs, section centimetres remain unchanged; " +
                "it calculates the row count you need to knit at your gauge for each section. " +
                "Stitch-gauge differences are handled separately for width.",
            "The math is deterministic: adjusted rows = cm × your_row / 10. " +
                "Section centimetres stay fixed; a denser row gauge produces more rows per cm — " +
                "the row count adapts, not the dimension; " +
                "stitch_scale = pattern_st / your_st describes horizontal width. " +
                "Increase-row spacing is rescaled by your_row / pattern_row so the physical gap " +
                "between increases stays correct.",
            "Scope: This tool provides estimates based on your swatch measurements. Always test a full-size gauge swatch " +
                "(washed and blocked the way you'll wash and block the finished garment) before starting your project. " +
                "Numbers here are a starting point — your finished piece is the final word.",
            "Not affiliated with Ravelry, Knit Companion, or any pattern designer. Gauge math is conventional knitting " +
                "arithmetic from open craft literature.",
            "Privacy",
            "Your gauge values stay on this device. No account, ads, or third-party tracking. The app includes no analytics " +
                "SDK and makes no app-initiated network requests. Apple may receive crash and performance diagnostics " +
                "according to your device settings.",
        ]
        let actualCopy = [
            AboutHelpContract.openLabel,
            AboutHelpContract.explanation,
            AboutHelpContract.math,
            AboutHelpContract.scope,
            AboutHelpContract.nonAffiliation,
            AboutHelpContract.privacyHeading,
            AboutHelpContract.privacy,
        ]
        #expect(actualCopy == expectedCopy)
        #expect(AboutHelpContract.closeLabel == "Close")
        #expect(AboutHelpContract.closeHitTarget == 44)
        let sheet = AboutHelpSheet(state: state.binding)
        let sheetProbe = HostedViewProbe(sheet)
        let contentProbe = HostedViewProbe(AboutHelpContent())
        #expect(contentProbe.size.width > 0)
        #expect(contentProbe.size.height > 0)
        let closeElement = sheetProbe.accessibilityElement(
            label: AboutHelpContract.closeLabel,
            traits: .button,
            activate: {
                sheet.close()
                return true
            }
        )
        #expect(closeElement.accessibilityTraits.contains(.button))
        let headerProbe = HostedViewProbe(HelpSheetHeader(onClose: {}))
        #expect(headerProbe.size.height >= AboutHelpContract.closeHitTarget)
        #expect(closeElement.accessibilityActivate())
        #expect(!state.value.isPresented)
    }

    @Test func contracts11And12DynamicTypePairGeometryAndUnitLabelsRemainVisible() throws {
        #expect(GaugeInputsCard.usesStackedLayout(at: .accessibility5))
        #expect(!GaugeInputsCard.usesStackedLayout(at: .large))
        #expect(
            GaugeInputsCard.accessibilityFieldOrder ==
                [.patternStitches, .patternRows, .yourStitches, .yourRows]
        )
        #expect(GaugeFormContract.leadCopy.hasSuffix("affect the garment."))

        let gaugeValues = GaugeValueBindings()
        let compact = HostedViewProbe(
            gaugeValues.gaugeCard
                .environment(\.dynamicTypeSize, .large)
        )
        let accessibleCard = HostedViewProbe(
            gaugeValues.gaugeCard
                .environment(\.dynamicTypeSize, .accessibility5)
        )
        #expect(accessibleCard.size.height > compact.size.height)
        #expect(accessibleCard.containsNaturalSize)
        let fieldLabels = GaugeInputsCard.accessibilityFieldOrder.map(
            GaugeInputsCard.accessibilityLabel
        )
        #expect(
            fieldLabels == [
                "Pattern stitch gauge, per 10 centimeters",
                "Pattern row gauge, per 10 centimeters",
                "Swatch stitch gauge, per 10 centimeters",
                "Swatch row gauge, per 10 centimeters",
            ]
        )
        #expect(fieldLabels.map(GaugeStepperField.pickerAccessibilityLabel).count == 4)

        let collapsedCard = HostedViewProbe(
            gaugeValues.patternCard(expanded: false)
                .environment(\.dynamicTypeSize, .accessibility5)
        )
        #expect(collapsedCard.containsNaturalSize)

        let expandedCard = HostedViewProbe(
            gaugeValues.patternCard(expanded: true)
                .environment(\.dynamicTypeSize, .accessibility5)
        )
        #expect(expandedCard.size.height > collapsedCard.size.height)
        #expect(expandedCard.containsNaturalSize)
        #expect(PatternInstructionsCard.usesStackedLayout(at: .accessibility5))
        #expect(MeasurementUnit.allCases.map(\.label) == ["cm", "in"])
        let draft = GaugeFormDraft(unit: .centimeters)
        #expect(
            [
                "Cast-on stitches",
                draft.lengthFieldLabel(.patternYoke),
                draft.lengthFieldLabel(.patternBody),
                draft.lengthFieldLabel(.patternSleeve),
                "Increase every (rows)",
            ] == [
                "Cast-on stitches",
                "Yoke depth (cm)",
                "Body length (cm)",
                "Sleeve length (cm)",
                "Increase every (rows)",
            ]
        )
        #expect(PatternInstructionsCard.disclosureLabel == "Pattern details (optional)")
        #expect(
            PatternInstructionsCard.disclosureHint ==
                "Expands optional unit, cast-on, length, and shaping fields"
        )
        #expect(PatternInstructionsCard.disclosureValue(isExpanded: false) == "Collapsed")
        #expect(PatternInstructionsCard.disclosureValue(isExpanded: true) == "Expanded")

        let requiredInputs = GaugeInputs()
        let requiredResult = GaugeMath.compute(requiredInputs)
        let requiredResults = HostedViewProbe(
            LiveResultsView(
                result: requiredResult,
                inputs: requiredInputs,
                unit: .centimeters,
                showFullMath: ValueBox(false).binding,
                onShare: { _ in [] }
            )
                .environment(\.dynamicTypeSize, .accessibility5)
        )
        let semantics = ResultCardSemantics(inputs: requiredInputs, result: requiredResult)
        let requiredResultLabels = [
            "Reconciliation — both axes",
            semantics.stitchSummary,
            semantics.rowSummary,
            "Share results",
            "Show full math",
        ]
        #expect(requiredResults.size.width > 0)
        #expect(requiredResults.size.height > 0)
        #expect(requiredResults.containsNaturalSize)
        #expect(semantics.sectionKinds == [.gaugeSummary, .actions])
        #expect(requiredResultLabels.count == 5)
    }

    @Test func contract17AssetColorsMeetContrastAndAppViewRenders() throws {
        let traits = [
            UITraitCollection(userInterfaceStyle: .light),
            UITraitCollection(userInterfaceStyle: .dark),
        ]
        for pair in AppTheme.textContrastPairs {
            for trait in traits {
                let foreground = try #require(
                    UIColor(named: pair.foreground, in: appResourceBundle, compatibleWith: trait)?
                        .resolvedColor(with: trait)
                )
                let background = try #require(
                    UIColor(named: pair.background, in: appResourceBundle, compatibleWith: trait)?
                        .resolvedColor(with: trait)
                )
                #expect(
                    contrastRatio(foreground, background) >= pair.minimumRatio,
                    "\(pair.foreground) on \(pair.background), \(trait.userInterfaceStyle)"
                )
            }
        }

        let inputs = GaugeInputs(
            yourStitches: 36,
            yourRows: 32,
            patternYokeDepth: 20,
            patternCastOn: 128
        )
        let summary = ResultsExportSummary(inputs: inputs, result: GaugeMath.compute(inputs))
        let pngData = ShareableView.pngData(summary: summary, scale: 1)
        #expect(!pngData.isEmpty)
        let image = try #require(
            UIImage(data: pngData)
        )
        let pixels = try #require(image.cgImage)
        #expect(pixels.width > 0)
        #expect(pixels.height > pixels.width)
    }

    @Test func contract09ResultActionsContainNoVerdictHelp() {
        #expect(
            ResultSectionKind.allCases ==
                [.gaugeSummary, .yokeDepth, .bodyAndSleeves, .shapingRates, .castOn, .actions]
        )
        #expect(ResultActionKind.allCases == [.share, .fullMath])
        let inputs = GaugeInputs()
        let semantics = ResultCardSemantics(inputs: inputs, result: GaugeMath.compute(inputs))
        #expect(semantics.sectionKinds == [.gaugeSummary, .actions])
        #expect(
            ResultActionKind.allCases.map { $0.label(isExpanded: false) } ==
                ["Share results", "Show full math"]
        )
        let results = HostedViewProbe(
            LiveResultsView(
                result: GaugeMath.compute(inputs),
                inputs: inputs,
                unit: .centimeters,
                showFullMath: ValueBox(false).binding,
                onShare: { _ in [] }
            )
        )
        #expect(results.size.width > 0)
        #expect(results.containsNaturalSize)
        for forbidden in [
            AboutHelpContract.openLabel,
            "Major mismatch",
            "Significant drift",
            "Both axes are off",
            "At least 15% drift",
        ] {
            #expect(ResultActionKind.allCases.allSatisfy {
                !$0.label(isExpanded: false).localizedCaseInsensitiveContains(forbidden)
            })
        }
    }

    @Test func contract15EveryFormFieldMapsValidatesFocusesAndCommits() {
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
        let card = values.patternInstructionsCard(expanded: true)
        let yoke = card.displayBinding(for: values.value(at: 5).binding, field: .patternYoke)
        yoke.wrappedValue = GaugeStepperField.committedText(selection: 8)
        #expect(values.value(at: 5).value == "20.32")
        #expect(yoke.wrappedValue == "8")
        yoke.wrappedValue = GaugeStepperField.adjustedText(
            values.value(at: 5).value,
            by: 1,
            field: .patternYoke,
            displayUnit: .inches,
            range: 2...39
        )
        #expect(values.value(at: 5).value == "22.86")
        yoke.wrappedValue = GaugeStepperField.adjustedText(
            values.value(at: 5).value,
            by: -1,
            field: .patternYoke,
            displayUnit: .inches,
            range: 2...39
        )
        #expect(values.value(at: 5).value == "20.32")
        let committedDraft = GaugeFormDraft(
            values: (0..<GaugeFormField.allCases.count).map { values.value(at: $0).value },
            unit: .inches,
            patternDetailsExpanded: true
        )
        #expect(committedDraft.inputs != nil)

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

    @Test func sceneDraftStoreUsesDistinctKeysAndReconcilesOnlyCompleteDrafts() {
        let keys = [
            SceneDraftStore.patternStitchesKey,
            SceneDraftStore.patternRowsKey,
            SceneDraftStore.yourStitchesKey,
            SceneDraftStore.yourRowsKey,
            SceneDraftStore.patternCastOnKey,
            SceneDraftStore.patternYokeKey,
            SceneDraftStore.patternBodyKey,
            SceneDraftStore.patternSleeveKey,
            SceneDraftStore.patternIncreasesKey,
            SceneDraftStore.disclosureKey,
        ]
        #expect(Set(keys).count == 10)

        let values = GaugeTextDefaults().resetSceneDraftValues
        #expect(SceneDraftStore.reconcileInvalidInchProvenance(in: values, for: .inches) == values)
        #expect(
            SceneDraftStore.reconcileInvalidInchProvenance(
                in: Array(values.dropLast()),
                for: .centimeters
            ) == Array(values.dropLast())
        )
    }

    @Test func stepperHelpersCoverValidationUnitsAndWarnings() {
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
            GaugeStepperField.committedText(selection: 7) == "7"
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
            showsCorrection: false,
            onSubmit: recorder.record
        )
        let coordinator = field.makeCoordinator()
        let textField = FocusRecordingTextField()

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

        GaugeKeyboardTextField.handlePickerRequest(
            1,
            coordinator: coordinator,
            textField: textField,
            activate: false
        )
        GaugeKeyboardTextField.handlePickerRequest(
            1,
            coordinator: coordinator,
            textField: textField,
            activate: false
        )
        #expect(coordinator.handledPickerRequest == 1)
        #expect(textField.inputView === coordinator.pickerView)
        #expect(coordinator.pendingSelection == 24)
        #expect(coordinator.numberOfComponents(in: coordinator.pickerView) == 1)
        #expect(
            coordinator.pickerView(
                coordinator.pickerView,
                numberOfRowsInComponent: 0
            ) == 99
        )
        #expect(
            coordinator.pickerView(
                coordinator.pickerView,
                titleForRow: 0,
                forComponent: 0
            ) == "1"
        )
        coordinator.adjust(by: 1)
        #expect(text.value == "25")
        #expect(coordinator.pendingSelection == 25)
        coordinator.pickerView(
            coordinator.pickerView,
            didSelectRow: 30,
            inComponent: 0
        )
        coordinator.didTapDone()
        #expect(text.value == "31")
        #expect(textField.inputView == nil)
        #expect(recorder.count == 1)
        coordinator.didTapDone()
        #expect(recorder.count == 2)

        focus.value = nil
        await GaugeKeyboardTextField.updateFocusAfterUpdate(
            coordinator: coordinator,
            textField: textField
        ).value

    }

    @Test func accessibilityAdjustmentsUseCurrentValueAndPreserveActivePickerSelection() {
        let text = ValueBox("25")
        let focus = ValueBox<GaugeFormField?>(nil)
        let recorder = ActionRecorder()
        func field() -> GaugeKeyboardTextField {
            GaugeKeyboardTextField(
                text: text.binding,
                field: .yourRows,
                focusedField: focus.binding,
                label: "Rows",
                value: "\(text.value) rows",
                hint: "Double-tap to edit.",
                showsCorrection: false,
                onSubmit: recorder.record
            )
        }

        let coordinator = field().makeCoordinator()
        let textField = GaugePickerTextField()
        coordinator.textField = textField
        textField.coordinator = coordinator

        text.value = "31"
        coordinator.parent = field()
        textField.accessibilityIncrement()
        #expect(text.value == "32")
        #expect(coordinator.pendingSelection == 32)

        text.value = "40"
        coordinator.parent = field()
        textField.accessibilityDecrement()
        #expect(text.value == "39")
        #expect(coordinator.pendingSelection == 39)

        coordinator.parent = field()
        coordinator.showPicker(in: textField, activate: false)
        coordinator.pickerView(
            coordinator.pickerView,
            didSelectRow: 49,
            inComponent: 0
        )
        text.value = "31"
        coordinator.parent = field()
        textField.accessibilityIncrement()
        #expect(coordinator.pendingSelection == 51)
        coordinator.didTapDone()
        #expect(text.value == "51")
        #expect(textField.inputView == nil)
        #expect(recorder.count == 1)
    }

    @Test func adjustmentRowsExposeLabelsAndAdaptiveLayouts() {
        let plainRow = AdjustmentRow(
            name: "Body length",
            pattern: "50 cm",
            adjusted: "37.5 cm"
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

        let correctionDraft = ValueBox(GaugeFormDraft())
        correctionDraft.value[.patternBody] = "bad"
        let correctionCard = RequiredAdjustmentsCard(
            result: nil,
            inputs: nil,
            correctionMessage: "Enter body length as a number.",
            unit: .centimeters,
            showFullMath: ValueBox(false).binding,
            canUndoReset: true,
            onCorrect: {
                _ = correctionDraft.value.finishEditing()
            },
            onReset: {},
            onUndoReset: {},
            onShare: { _ in [] }
        )
        correctionCard.requestCorrection()
        #expect(correctionDraft.value.patternDetailsExpanded)
        #expect(correctionDraft.value.focusedField == .patternBody)
        let invalidResult = HostedViewProbe(correctionCard)
        #expect(invalidResult.size.height > 0)

        let unusableCastOnInputs = GaugeInputs(
            patternStitches: 99, patternRows: 24, yourStitches: 1, yourRows: 24,
            patternCastOn: 40
        )
        let unusableCastOnResult = GaugeMath.compute(unusableCastOnInputs)
        #expect(
            ResultCardSemantics(inputs: unusableCastOnInputs, result: unusableCastOnResult).castOnGuidance ==
                "No usable whole-stitch cast-on result. Re-swatch or change needle size before casting on."
        )
        let unusableCastOnLive = LiveResultsView(
            result: unusableCastOnResult,
            inputs: unusableCastOnInputs,
            unit: .centimeters,
            showFullMath: ValueBox(true).binding,
            onShare: { _ in [] }
        )
        #expect(unusableCastOnLive.fullMathBreakdown.contains("cast-on adjust = your_st / pattern_st x 40"))
        #expect(unusableCastOnLive.fullMathBreakdown.contains("No usable whole-stitch cast-on result."))
        #expect(
            unusableCastOnLive.fullMathBreakdown.contains(
                "Re-swatch or change needle size before casting on."
            )
        )
        let unusableCastOn = RequiredAdjustmentsCard(
            result: unusableCastOnResult,
            inputs: unusableCastOnInputs,
            correctionMessage: nil,
            unit: .centimeters,
            showFullMath: ValueBox(false).binding,
            canUndoReset: false,
            onCorrect: {},
            onReset: {},
            onUndoReset: {},
            onShare: { _ in [] }
        )
        #expect(HostedViewProbe(unusableCastOn).size.height > 0)

        let noDriftInputs = GaugeInputs(patternCastOn: 128)
        let noDriftResult = GaugeMath.compute(noDriftInputs)
        let noDrift = LiveResultsView(
            result: noDriftResult,
            inputs: noDriftInputs,
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
        let view = AboutHelpToolbarButton(state: state.binding)
        let button = HostedViewProbe(view)
        let open = button.accessibilityElement(
            label: AboutHelpContract.openLabel,
            traits: .button,
            activate: {
                view.open()
                return true
            }
        )
        #expect(open.accessibilityActivate())
        #expect(state.value.isPresented)

        let activity = ActivityView(activityItems: ["Gauge result"])
        let probe = HostedViewProbe(activity)
        #expect(probe.size.width > 0)

        let provider = SheetContentProvider(content: Text("About"))
        #expect(HostedViewProbe(provider.contentView()).size.width > 0)
    }

    @Test func pickerInputViewAndKeyboardFieldsHostBothWarningLayouts() {
        let text = ValueBox("32")
        let focus = ValueBox<GaugeFormField?>(nil)
        let actionFocus = ValueBox<GaugeFormField?>(nil)
        let pickerRequest = ValueBox(0)
        let openPicker = GaugeStepperOpenPickerAction(
            field: .yourRows,
            focusedField: actionFocus.binding,
            pickerRequest: pickerRequest.binding
        )
        openPicker.perform()
        #expect(actionFocus.value == .yourRows)
        #expect(pickerRequest.value == 1)

        let keyboard = GaugeKeyboardTextField(
            text: text.binding,
            field: .yourRows,
            focusedField: focus.binding,
            label: "Rows",
            value: "32 rows",
            hint: "Edit",
            showsCorrection: true,
            onSubmit: {}
        )
        #expect(HostedViewProbe(keyboard).size.height > 0)

        let stepper = GaugeStepperField(
            title: "Rows",
            text: text.binding,
            unit: "ro",
            field: .yourRows,
            validationMessage: nil,
            focusedField: focus.binding,
            onSubmit: {},
            hasMismatch: true,
            mismatchLabel: "Row gauge mismatch detected",
            mismatchDelta: 8
        )
        text.value = "32"
        let stepperProbe = HostedViewProbe(stepper)
        stepper.increment()
        #expect(text.value == "33")
        stepper.decrement()
        #expect(text.value == "31")
        #expect(stepperProbe.size.height > 0)
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
            correctionMessage: nil,
            unit: .centimeters,
            showFullMath: ValueBox(false).binding,
            canUndoReset: false,
            onCorrect: {},
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

    @Test func contentAppearanceReconcilesDisconnectedSceneUnitsBeforeRestoringFocus() throws {
        let contentForm = try #require(
            ContentView(sceneStorageEnabled: false).body as? GaugeFormView
        )
        #expect(HostedViewProbe(contentForm).size.width > 0)
        contentForm.applySceneDraft(
            values: GaugeTextDefaults().resetSceneDraftValues,
            disclosure: true
        )
        contentForm.measurementUnitBinding.wrappedValue = .inches

        let inchScene = GaugeValueBindings()
        inchScene.unit.value = .inches
        inchScene.value(at: 5).value = MeasurementUnit.inches.centimeterStorageText(
            from: "40",
            cmRange: 5...100
        )
        #expect(MeasurementUnit.invalidInchesText(from: inchScene.value(at: 5).value) == "40")

        inchScene.unit.value = .centimeters
        let restoredCentimeterForm = inchScene.formView
        restoredCentimeterForm.sceneDidAppear()
        #expect(inchScene.value(at: 5).value == "40")
        #expect(restoredCentimeterForm.formDraft.validationMessages.isEmpty)
        #expect(restoredCentimeterForm.formDraft.focusedField == nil)
        #expect(
            GaugeStepperField.pickerSelection(
                validationText: inchScene.value(at: 5).value,
                field: .patternYoke,
                displayUnit: .centimeters,
                range: 5...100
            ) == 40
        )

        let centimeterScene = GaugeValueBindings()
        centimeterScene.value(at: 5).value = "20.32"
        centimeterScene.unit.value = .inches
        let restoredInchForm = centimeterScene.formView
        restoredInchForm.sceneDidAppear()
        #expect(centimeterScene.value(at: 5).value == "20.32")
        #expect(
            GaugeStepperField.pickerSelection(
                validationText: centimeterScene.value(at: 5).value,
                field: .patternYoke,
                displayUnit: .inches,
                range: 2...39
            ) == 8
        )
        let inchCard = centimeterScene.patternInstructionsCard(expanded: true)
        #expect(
            inchCard.displayBinding(
                for: centimeterScene.value(at: 5).binding,
                field: .patternYoke
            ).wrappedValue == "8"
        )

        let scene = KnittingGaugeReconcilerApp().body
        #expect(String(reflecting: type(of: scene)).contains("WindowGroup"))
    }

    @Test func contentBindingsActionsLifecycleAndSharingAreDeterministic() async throws {
        let values = GaugeValueBindings()
        let view = values.formView
        #expect(HostedViewProbe(view).size.width > 0)
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
            GaugeFormView.reconciledSceneDraft(
                values: inchValues,
                from: .centimeters,
                to: .inches
            ) == nil
        )
        let reconciledValues = try #require(
            GaugeFormView.reconciledSceneDraft(
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
        GaugeFormView.finishEditing(&invalidDraft)
        #expect(invalidDraft.focusedField == .patternStitches)

        view.undoReset()
        view.resetToDefaults()
        view.undoReset()
        #expect(view.formDraft.rawValues.count == GaugeFormField.allCases.count)

        let telemetryCases: [
            (decision: StaticString?, expected: String?, perform: () -> Void)
        ] = [
            (
                GaugeFormView.helpSignpostName(previous: true, current: false),
                nil,
                { view.helpPresentationChanged(true, false) }
            ),
            (
                GaugeFormView.helpSignpostName(previous: false, current: true),
                SignpostNames.sheetAboutHelpOpened.description,
                { view.helpPresentationChanged(false, true) }
            ),
            (
                GaugeFormView.driftBandSignpostName(previous: true, current: false),
                nil,
                { view.castOnDriftChanged(true, false) }
            ),
            (
                GaugeFormView.driftBandSignpostName(previous: false, current: true),
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
                return GaugeFormView.validationAnnouncement(
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
        let aboutHelp = ValueBox(AboutHelpState(isPresented: true))
        #expect(
            HostedViewProbe(
                GaugeFormView.aboutHelpSheet(state: aboutHelp.binding)
            ).size.height > 0
        )

        let inputs = GaugeInputs(yourRows: 24, patternCastOn: 128)
        let result = GaugeMath.compute(inputs)
        #expect(GaugeFormView.computeResult(nil) == nil)
        #expect(GaugeFormView.computeResult(inputs) != nil)
        let emptyPresentation = GaugeFormView.inputPresentation(nil)
        #expect(!emptyPresentation.stitchMismatch)
        #expect(emptyPresentation.stitchDelta == nil)
        let presentation = GaugeFormView.inputPresentation(inputs)
        #expect(!presentation.stitchMismatch)
        #expect(presentation.stitchDelta == 0)
        #expect(!GaugeFormView.hasCastOnDrift(nil))
        #expect(!GaugeFormView.hasCastOnDrift(result))

        let emptyShare = await GaugeFormView.shareItems(
            for: result,
            inputs: nil,
            unit: .centimeters
        )
        #expect(emptyShare.isEmpty)

        let fallback = await GaugeFormView.shareItems(
            for: result,
            inputs: inputs,
            unit: .centimeters,
            exportDirectory: URL(fileURLWithPath: "/dev/null/share-exports")
        )
        #expect(fallback.first is String)

        let shared = await GaugeFormView.shareItems(
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
private final class FocusRecordingTextField: GaugePickerTextField {
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
    private let details = ValueBox(false)
    let unit = ValueBox(MeasurementUnit.centimeters)

    var patternDetailsExpanded: Bool {
        get { details.value }
        set { details.value = newValue }
    }

    func value(at index: Int) -> ValueBox<String> {
        values[index]
    }

    var formView: GaugeFormView {
        GaugeFormView(
            patternStitches: values[0].binding,
            patternRows: values[1].binding,
            yourStitches: values[2].binding,
            yourRows: values[3].binding,
            patternCastOn: values[4].binding,
            patternYoke: values[5].binding,
            patternBody: values[6].binding,
            patternSleeve: values[7].binding,
            patternIncreases: values[8].binding,
            patternDetailsExpanded: details.binding,
            measurementUnit: unit.binding
        )
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
private final class HostedViewProbe<Content: View> {
    private let controller: UIHostingController<Content>
    let size: CGSize

    var containsNaturalSize: Bool {
        controller.view.bounds.width == size.width &&
            controller.view.bounds.height >= size.height &&
            size.width.isFinite &&
            size.height.isFinite
    }

    init(
        _ content: Content,
        width: CGFloat = 390,
        height: CGFloat? = nil
    ) {
        let controller = UIHostingController(rootView: content)
        controller.loadViewIfNeeded()
        let size = controller.view.sizeThatFits(
            CGSize(width: width, height: height ?? CGFloat.greatestFiniteMagnitude)
        )
        let frame = CGRect(
            x: 0,
            y: 0,
            width: width,
            height: height ?? max(100, size.height)
        )
        controller.view.frame = frame
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        self.controller = controller
        self.size = height.map { CGSize(width: width, height: $0) } ?? size
    }

    func accessibilityElement(
        label: String,
        traits: UIAccessibilityTraits,
        activate: @escaping () -> Bool
    ) -> UIAccessibilityElement {
        let hostedView: UIView = controller.view
        let element = ActivatingAccessibilityElement(accessibilityContainer: hostedView)
        element.accessibilityLabel = label
        element.accessibilityTraits = traits
        element.accessibilityFrameInContainerSpace = hostedView.bounds
        element.activate = activate
        return element
    }
}

private final class ActivatingAccessibilityElement: UIAccessibilityElement {
    var activate: () -> Bool = { false }

    override func accessibilityActivate() -> Bool {
        activate()
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
