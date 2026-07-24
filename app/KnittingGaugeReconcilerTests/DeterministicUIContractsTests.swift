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
    private var uniqueFormValues: GaugeFormValues {
        GaugeFormValues(
            patternStitches: "31",
            patternRows: "23",
            yourStitches: "29",
            yourRows: "21",
            patternCastOn: "141",
            patternYoke: "19",
            patternBody: "49",
            patternSleeve: "44",
            patternIncreases: "7"
        )
    }

    @Test func contracts15And16FormDraftPreservesValidationRawValuesResetAndUndo() throws {
        let blankValues = GaugeFormValues()
        let original = uniqueFormValues
        #expect(GaugeFormDraft().formValues == blankValues)
        var draft = GaugeFormDraft(
            values: original,
            unit: .centimeters,
            patternDetailsExpanded: true
        )

        #expect(draft.formValues == original)
        #expect(draft.inputs != nil)
        #expect(draft.lengthFieldLabel(.patternYoke) == "Yoke depth (cm)")
        draft.unit = .inches
        #expect(draft.lengthFieldLabel(.patternYoke) == "Yoke depth (in)")
        draft.unit = .centimeters
        #expect(draft.lengthFieldLabel(.patternYoke) == "Yoke depth (cm)")

        draft[.patternStitches] = "0"
        draft[.patternRows] = "100"
        #expect(draft.formValues.patternStitches == "0")
        #expect(draft.formValues.patternRows == "100")
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
        #expect(draft.formValues == blankValues)
        #expect(!draft.patternDetailsExpanded)
        draft.restore(snapshot)
        #expect(draft.formValues == original)
        #expect(draft.patternDetailsExpanded)
        #expect(draft.focusedField == nil)
    }

    @Test func contracts07And13PickerAccessibilityAndMismatchAreDeterministic() {
        for unit in MeasurementUnit.allCases {
            let fieldLabel = GaugeInputsCard.accessibilityLabel(for: .yourRows, unit: unit)
            let contract = GaugeStepperField.accessibilityContract(
                text: "32",
                unit: "ro",
                fieldLabel: fieldLabel,
                mismatchLabel: "Row gauge mismatch detected",
                mismatchDelta: 8
            )

            #expect(contract.fieldValue == "32 rows, row gauge mismatch detected, +8")
            #expect(contract.pickerLabel == "Open picker for \(fieldLabel)")
            #expect(contract.pickerValue == "Warning")
            #expect(contract.warningSummary == "Row gauge mismatch detected")
            #expect(contract.actions == ["Increment", "Decrement"])
            #expect(
                contract.pickerHint ==
                    "Row gauge mismatch detected. Opens the wheel picker and warning details."
            )
        }
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
                stitchPercent: 100, rowPercent: 100
            ),
            Scenario(
                name: "denser rows", yourStitches: 32, yourRows: 32,
                stitchMismatch: false, rowMismatch: true,
                stitchPercent: 100, rowPercent: 133
            ),
            Scenario(
                name: "looser rows", yourStitches: 32, yourRows: 20,
                stitchMismatch: false, rowMismatch: true,
                stitchPercent: 100, rowPercent: 83
            ),
            Scenario(
                name: "denser stitches", yourStitches: 36, yourRows: 24,
                stitchMismatch: true, rowMismatch: false,
                stitchPercent: 89, rowPercent: 100
            ),
            Scenario(
                name: "looser stitches", yourStitches: 28, yourRows: 24,
                stitchMismatch: true, rowMismatch: false,
                stitchPercent: 114, rowPercent: 100
            ),
            Scenario(
                name: "both denser", yourStitches: 36, yourRows: 32,
                stitchMismatch: true, rowMismatch: true,
                stitchPercent: 89, rowPercent: 133
            ),
        ]
        let unitCases: [(MeasurementUnit, basis: String, spokenBasis: String)] = [
            (.centimeters, "10 cm", "10 centimeters"),
            (.inches, "4 in", "4 inches"),
        ]

        for scenario in scenarios {
            let inputs = GaugeInputs(
                patternStitches: 32,
                patternRows: 24,
                yourStitches: scenario.yourStitches,
                yourRows: scenario.yourRows
            )
            #expect(inputs.stitchMismatch == scenario.stitchMismatch, "\(scenario.name): stitches")
            #expect(inputs.rowMismatch == scenario.rowMismatch, "\(scenario.name): rows")
            for (unit, basis, spokenBasis) in unitCases {
                let semantics = ResultCardSemantics(
                    inputs: inputs,
                    result: GaugeMath.compute(inputs),
                    unit: unit
                )
                #expect(
                    semantics.stitchComparison ==
                        "Pattern 32 st/\(basis) · Swatch \(plain(scenario.yourStitches)) st/\(basis)",
                    "\(scenario.name): \(unit) stitch comparison"
                )
                #expect(
                    semantics.rowComparison ==
                        "Pattern 24 rows/\(basis) · Swatch \(plain(scenario.yourRows)) rows/\(basis)",
                    "\(scenario.name): \(unit) row comparison"
                )
                #expect(
                    semantics.stitchSummary ==
                        "Stitch-wise, horizontal. Pattern 32 stitches per \(spokenBasis). " +
                        "Swatch \(plain(scenario.yourStitches)) stitches per \(spokenBasis). " +
                        "\(scenario.stitchPercent)% of pattern width.",
                    "\(scenario.name): \(unit) stitch summary"
                )
                #expect(
                    semantics.rowSummary ==
                        "Row-wise, vertical. Pattern 24 rows per \(spokenBasis). " +
                        "Swatch \(plain(scenario.yourRows)) rows per \(spokenBasis). " +
                        "\(scenario.rowPercent)% of pattern row density.",
                    "\(scenario.name): \(unit) row summary"
                )
            }
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
        #expect(
            GaugeInputsCard.accessibilityFieldOrder ==
                [.patternStitches, .patternRows, .yourStitches, .yourRows]
        )

        let gaugeValues = GaugeValueBindings()
        let standardCard = HostedViewProbe(
            gaugeValues.gaugeCard
                .environment(\.dynamicTypeSize, .large)
        )
        let accessibleCard = HostedViewProbe(
            gaugeValues.gaugeCard
                .environment(\.dynamicTypeSize, .accessibility5)
        )
        #expect(
            standardCard.containsNaturalSize,
            "\(standardCard.geometryDescription)"
        )
        #expect(accessibleCard.containsNaturalSize)
        #expect(accessibleCard.size.height > standardCard.size.height)
        let basisCases: [(MeasurementUnit, String)] = [
            (.centimeters, "10 centimeters"),
            (.inches, "4 inches"),
        ]
        for (unit, basis) in basisCases {
            gaugeValues.unit.value = unit
            let fieldLabels = GaugeInputsCard.accessibilityFieldOrder.map {
                GaugeInputsCard.accessibilityLabel(for: $0, unit: unit)
            }
            #expect(
                fieldLabels == [
                    "Pattern stitch gauge, per \(basis)",
                    "Pattern row gauge, per \(basis)",
                    "Swatch stitch gauge, per \(basis)",
                    "Swatch row gauge, per \(basis)",
                ]
            )
            #expect(fieldLabels.map(GaugeStepperField.pickerAccessibilityLabel).count == 4)
            #expect(HostedViewProbe(gaugeValues.gaugeCard).size.height > 0)
        }

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
                "Expands optional cast-on, length, and shaping fields"
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

    @Test func requiredValidationReservesStableStepperHeight() {
        let widths: [CGFloat] = [320, 390, 760]
        let textSizes: [DynamicTypeSize] = [
            .large, .xxxLarge, .accessibility1, .accessibility5,
        ]

        for width in widths {
            for textSize in textSizes {
                let pristine = HostedViewProbe(
                    requiredStepper(validationMessage: nil)
                        .environment(\.dynamicTypeSize, textSize),
                    width: width
                )
                let revealed = HostedViewProbe(
                    requiredStepper(validationMessage: "Pattern stitch gauge is required.")
                        .environment(\.dynamicTypeSize, textSize),
                    width: width
                )

                #expect(pristine.hasFiniteNaturalSize, "\(width), \(textSize): pristine")
                #expect(revealed.hasFiniteNaturalSize, "\(width), \(textSize): revealed")
                #expect(pristine.fits(proposedWidth: width), "\(width), \(textSize): pristine width")
                #expect(revealed.fits(proposedWidth: width), "\(width), \(textSize): revealed width")
                #expect(
                    abs(pristine.size.height - revealed.size.height) <= 0.5,
                    "\(width), \(textSize): \(pristine.size.height) vs \(revealed.size.height)"
                )
            }
        }
    }

    @Test func adaptiveLayoutsHaveFiniteNaturalSizesAcrossWidthsAndTextSizes() throws {
        let widths: [CGFloat] = [320, 390, 760]
        let textSizes: [DynamicTypeSize] = [
            .large, .xxxLarge, .accessibility1, .accessibility5,
        ]
        let values = GaugeValueBindings()
        values.patternDetailsExpanded = true
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
        let semantics = ResultCardSemantics(inputs: inputs, result: result)

        let pairMeasurements = expectNaturalSizeMatrix(
            "GaugeMeasurementPair",
            widths: widths,
            textSizes: textSizes
        ) {
            GaugeMeasurementPair {
                LayoutFixtureTile(
                    title: "Pattern stitch gauge",
                    value: "99 stitches per 10 centimeters"
                )
            } trailing: {
                LayoutFixtureTile(
                    title: "Swatch stitch gauge",
                    value: "4 stitches per 10 centimeters"
                )
            }
        }
        let gaugeMeasurements = expectNaturalSizeMatrix(
            "GaugeInputsCard",
            widths: widths,
            textSizes: textSizes
        ) {
            values.gaugeCard
        }
        let patternMeasurements = expectNaturalSizeMatrix(
            "PatternInstructionsCard",
            widths: widths,
            textSizes: textSizes
        ) {
            values.patternCard(expanded: true)
        }
        let heroMeasurements = expectNaturalSizeMatrix(
            "HeroTilesView",
            widths: widths,
            textSizes: textSizes
        ) {
            HeroTilesView(result: result, semantics: semantics)
        }
        let liveMeasurements = expectNaturalSizeMatrix(
            "LiveResultsView",
            widths: widths,
            textSizes: textSizes
        ) {
            LiveResultsView(
                result: result,
                inputs: inputs,
                unit: .centimeters,
                showFullMath: ValueBox(false).binding,
                onShare: { _ in [] }
            )
        }
        let resetMeasurements = expectNaturalSizeMatrix(
            "Reset and undo actions",
            widths: widths,
            textSizes: textSizes
        ) {
            RequiredAdjustmentsCard(
                result: nil,
                inputs: nil,
                correctionMessage: nil,
                unit: .centimeters,
                showFullMath: ValueBox(false).binding,
                canUndoReset: true,
                onCorrect: {},
                onReset: {},
                onUndoReset: {},
                onShare: { _ in [] }
            )
        }
        let driftMeasurements = expectNaturalSizeMatrix(
            "Consecutive drift AdjustmentRows",
            widths: widths,
            textSizes: textSizes
        ) {
            VStack(spacing: 12) {
                AdjustmentRow(
                    name: "Cast-on stitches",
                    pattern: "41 stitches",
                    adjusted: "2 stitches",
                    driftPill: "+21% width"
                )
                AdjustmentRow(
                    name: "Increase-row spacing",
                    pattern: "Every 6 rows",
                    adjusted: "Every 8 rows",
                    driftPill: "+33% rows"
                )
            }
        }

        for (name, measurements) in [
            ("GaugeMeasurementPair", pairMeasurements),
            ("GaugeInputsCard", gaugeMeasurements),
            ("PatternInstructionsCard", patternMeasurements),
            ("HeroTilesView", heroMeasurements),
            ("LiveResultsView", liveMeasurements),
            ("Reset and undo actions", resetMeasurements),
            ("Consecutive drift AdjustmentRows", driftMeasurements),
        ] {
            let narrow = try #require(
                measurements.measurement(width: 320, textSize: .xxxLarge)
            )
            let wide = try #require(
                measurements.measurement(width: 760, textSize: .xxxLarge)
            )
            #expect(
                narrow.size.height + 0.5 >= wide.size.height,
                "\(name) should grow vertically at 320pt instead of overflowing"
            )
        }

        for (name, measurements) in [
            ("GaugeMeasurementPair", pairMeasurements),
            ("GaugeInputsCard", gaugeMeasurements),
            ("PatternInstructionsCard", patternMeasurements),
            ("HeroTilesView", heroMeasurements),
            ("LiveResultsView", liveMeasurements),
            ("Consecutive drift AdjustmentRows", driftMeasurements),
        ] {
            let standard = try #require(
                measurements.measurement(width: 760, textSize: .large)
            )
            let accessible = try #require(
                measurements.measurement(width: 760, textSize: .accessibility5)
            )
            #expect(
                accessible.size.height > standard.size.height,
                "\(name) should grow vertically for Accessibility 5"
            )
        }

        let resetStandard = try #require(
            resetMeasurements.measurement(width: 320, textSize: .large)
        )
        let resetAccessible = try #require(
            resetMeasurements.measurement(width: 320, textSize: .accessibility5)
        )
        #expect(resetAccessible.size.height >= resetStandard.size.height)
    }

    @Test func resetUndoActionsRemainWiredAndMeetTouchTargetContract() throws {
        let expectedValues = uniqueFormValues
        let values = GaugeValueBindings(values: expectedValues)
        values.patternDetailsExpanded = true
        let original = values.formView.formDraft
        let view = values.formView

        view.resetToDefaults()
        #expect(view.formDraft.formValues == GaugeFormValues())
        #expect(!view.formDraft.patternDetailsExpanded)
        view.undoReset()
        #expect(view.formDraft.formValues == expectedValues)
        #expect(view.formDraft.formValues == original.formValues)
        #expect(view.formDraft.patternDetailsExpanded)

        let appDirectory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let source = try String(
            contentsOf: appDirectory.appendingPathComponent(
                "KnittingGaugeReconciler/Views/RequiredAdjustmentsCard.swift"
            ),
            encoding: .utf8
        ).replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)

        #expect(source.contains("Button(\"Resetvalues\",action:requestReset)"))
        #expect(source.contains("Button(\"Resetvalues\",role:.destructive,action:onReset)"))
        #expect(source.contains("Button(\"Undoreset\",action:onUndoReset)"))
        #expect(
            source.components(
                separatedBy: """
                .frame(minWidth:Sizing.minimumTouchTarget,\
                minHeight:Sizing.minimumTouchTarget,alignment:.leading)
                """
            ).count == 3
        )
    }

    @Test func globalNativeUnitMenuLivesInGaugeInputsAndBindsPersistedUnit() throws {
        let appDirectory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let contentSource = try String(
            contentsOf: appDirectory.appendingPathComponent("KnittingGaugeReconciler/ContentView.swift"),
            encoding: .utf8
        )
        let formStack = try #require(
            contentSource.range(of: "VStack(alignment: .leading, spacing: cardSpacing) {")
        )
        let gaugeCard = try #require(
            contentSource.range(
                of: "GaugeInputsCard(",
                range: formStack.upperBound..<contentSource.endIndex
            )
        )
        let patternCard = try #require(
            contentSource.range(
                of: "PatternInstructionsCard(",
                range: gaugeCard.upperBound..<contentSource.endIndex
            )
        )
        let resultsCard = try #require(
            contentSource.range(
                of: "RequiredAdjustmentsCard(",
                range: patternCard.upperBound..<contentSource.endIndex
            )
        )
        let formPadding = try #require(
            contentSource.range(
                of: ".padding(.horizontal, Spacing.margin)",
                range: resultsCard.upperBound..<contentSource.endIndex
            )
        )
        #expect(gaugeCard.lowerBound < patternCard.lowerBound)
        #expect(patternCard.lowerBound < resultsCard.lowerBound)
        #expect(
            contentSource[gaugeCard.lowerBound..<patternCard.lowerBound]
                .contains("unit: measurementUnitBinding")
        )
        #expect(
            contentSource[patternCard.lowerBound..<resultsCard.lowerBound]
                .contains("unit: measurementUnitBinding")
        )
        #expect(
            contentSource[resultsCard.lowerBound..<formPadding.lowerBound]
                .contains("unit: measurementUnit")
        )
        #expect(
            contentSource.contains(
                "@AppStorage(\"measurementUnit\") private var measurementUnit: MeasurementUnit"
            )
        )
        #expect(!contentSource.contains("Picker(\"Measurement unit\""))
        #expect(!contentSource.contains("UnitToggleView"))

        let patternSource = try String(
            contentsOf: appDirectory.appendingPathComponent(
                "KnittingGaugeReconciler/Views/PatternInstructionsCard.swift"
            ),
            encoding: .utf8
        )
        #expect(!patternSource.contains("UnitToggleView"))
        #expect(!patternSource.contains("Picker(\"Measurement unit\""))
        #expect(!patternSource.contains(".pickerStyle(.segmented)"))
        #expect(!PatternInstructionsCard.disclosureHint.localizedCaseInsensitiveContains("unit"))

        let gaugeSource = try String(
            contentsOf: appDirectory.appendingPathComponent(
                "KnittingGaugeReconciler/Views/GaugeInputsCard.swift"
            ),
            encoding: .utf8
        )
        #expect(gaugeSource.components(separatedBy: "Picker(").count == 2)
        #expect(
            gaugeSource.components(
                separatedBy: "Picker(\"Measurement unit\", selection: $unit)"
            ).count == 2
        )
        #expect(gaugeSource.contains("Text(\"Centimeters\").tag(MeasurementUnit.centimeters)"))
        #expect(gaugeSource.contains("Text(\"Inches\").tag(MeasurementUnit.inches)"))
        #expect(gaugeSource.contains(".pickerStyle(.menu)"))
        #expect(
            gaugeSource.components(
                separatedBy:
                ".accessibilityHint(\"Changes gauge basis and dimensions throughout the calculator.\")"
            ).count == 2
        )
        #expect(gaugeSource.contains("Text(unit == .centimeters ? \"PER 10 CM\" : \"PER 4 IN\")"))

        let values = GaugeValueBindings(values: uniqueFormValues)
        values[.patternYoke] = "20.32"
        let globalUnit = values.formView.measurementUnitBinding
        for unit in MeasurementUnit.allCases {
            globalUnit.wrappedValue = unit
            #expect(values.unit.value == unit)
            #expect(values.formView.formDraft.unit == unit)
            #expect(HostedViewProbe(values.gaugeCard).size.height > 0)
            let basis = unit == .centimeters ? "10 centimeters" : "4 inches"
            #expect(
                GaugeInputsCard.accessibilityLabel(for: .patternStitches, unit: unit) ==
                    "Pattern stitch gauge, per \(basis)"
            )
            let patternDetails = values.patternInstructionsCard(expanded: true)
            #expect(
                patternDetails.displayBinding(
                    for: values.binding(for: .patternYoke),
                    field: .patternYoke
                ).wrappedValue == (unit == .centimeters ? "20.32" : "8")
            )
        }
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
        messagesDraft[.patternStitches] = "32"
        messagesDraft[.patternRows] = ""
        messagesDraft[.yourStitches] = "32"
        messagesDraft[.yourRows] = "32"
        #expect(
            messagesDraft.validationMessages ==
                [.patternRows: "Pattern row gauge is required."]
        )

        var detailDraft = GaugeFormDraft()
        detailDraft[.patternStitches] = "32"
        detailDraft[.patternRows] = "24"
        detailDraft[.yourStitches] = "32"
        detailDraft[.yourRows] = "32"
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

    @Test func validationPresentationRevealsOnBlurOrViewResultsAndResetUndoRoundTrips() throws {
        var draft = GaugeFormDraft()
        var revealed = Set<GaugeFormField>()
        let requiredFields: Set<GaugeFormField> = [
            .patternStitches, .patternRows, .yourStitches, .yourRows,
        ]

        #expect(draft.focusedField == nil)
        #expect(Set(draft.validationMessages.keys) == requiredFields)
        #expect(draft.validationMessages.filter { revealed.contains($0.key) }.isEmpty)

        revealed.insert(.patternRows)
        #expect(
            draft.validationMessages.filter { revealed.contains($0.key) } ==
                [.patternRows: "Pattern row gauge is required."]
        )
        draft[.patternRows] = "24"
        #expect(draft.validationMessages.filter { revealed.contains($0.key) }.isEmpty)

        revealed.formUnion(draft.validationMessages.keys)
        #expect(
            Set(draft.validationMessages.filter { revealed.contains($0.key) }.keys) ==
                requiredFields.subtracting([.patternRows])
        )
        #expect(draft.finishEditing() == "Pattern stitch gauge is required.")
        #expect(draft.focusedField == .patternStitches)

        let savedRevealed = revealed
        let snapshot = draft.reset()
        revealed.removeAll()
        #expect(draft.formValues == GaugeFormValues())
        #expect(draft.focusedField == nil)
        #expect(draft.validationMessages.filter { revealed.contains($0.key) }.isEmpty)
        draft.restore(snapshot)
        revealed = savedRevealed
        #expect(draft[.patternRows] == "24")
        #expect(
            Set(draft.validationMessages.filter { revealed.contains($0.key) }.keys) ==
                requiredFields.subtracting([.patternRows])
        )

        for field in requiredFields {
            draft[field] = "24"
        }
        #expect(draft.finishEditing() == nil)
        #expect(draft.focusedField == nil)
        #expect(draft.inputs != nil)

        let appDirectory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let contentSource = try String(
            contentsOf: appDirectory.appendingPathComponent("KnittingGaugeReconciler/ContentView.swift"),
            encoding: .utf8
        ).replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
        #expect(contentSource.contains("@StateprivatevarrevealedValidationFields:Set<GaugeFormField>=[]"))
        #expect(contentSource.contains(".onChange(of:focusedField,fieldFocusChanged)"))
        #expect(!contentSource.contains(".onChange(of:validationMessages"))
        #expect(!contentSource.contains(".onAppear(perform:finishEditing)"))
        #expect(contentSource.contains("guardletpreviousField,previousField!=currentFieldelse{return}"))
        #expect(contentSource.contains("revealedValidationFields.insert(previousField)"))
        #expect(
            contentSource.contains(
                "formDraft.validationMessages.filter{revealedValidationFields.contains($0.key)}"
            )
        )
        #expect(contentSource.contains("revealedValidationFields.formUnion(draft.validationMessages.keys)"))
        #expect(contentSource.contains("Self.finishEditing(&draft)"))
        #expect(contentSource.contains("focusedField=draft.focusedField"))
        #expect(
            contentSource.contains(
                "ifletmessage{UIAccessibility.post(notification:.announcement,argument:message)}"
            )
        )
        #expect(contentSource.contains("resetSnapshot.revealedValidationFields=revealedValidationFields"))
        #expect(contentSource.contains("revealedValidationFields.removeAll()"))
        #expect(contentSource.contains("revealedValidationFields=resetSnapshot.revealedValidationFields"))

        let stepperSource = try String(
            contentsOf: appDirectory.appendingPathComponent(
                "KnittingGaugeReconciler/Components/GaugeStepperField.swift"
            ),
            encoding: .utf8
        ).replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
        #expect(
            stepperSource.contains(
                "guardcase.failure(.required)=GaugeMath.validate(validationText,for:field.mathField)" +
                    "else{returnvalidationMessage}return\"Required\""
            )
        )
        #expect(
            stepperSource.contains(
                "Label(visibleValidationMessage??\"\",systemImage:\"exclamationmark.circle.fill\")"
            )
        )
        #expect(stepperSource.contains(".opacity(visibleValidationMessage==nil?0:1)"))
        #expect(stepperSource.contains(".accessibilityHidden(true)"))

        let cardSource = try String(
            contentsOf: appDirectory.appendingPathComponent(
                "KnittingGaugeReconciler/Views/RequiredAdjustmentsCard.swift"
            ),
            encoding: .utf8
        ).replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
        let viewResultsStart = try #require(
            cardSource.range(
                of: "VStack(alignment:.leading,spacing:Spacing.control){" +
                    "Button(action:requestCorrection){" +
                    "Label(\"Viewresults\",systemImage:\"wand.and.stars\")"
            )
        )
        let liveResultsStart = try #require(
            cardSource.range(of: "ifletresult,letinputs{LiveResultsView(")
        )
        #expect(viewResultsStart.lowerBound < liveResultsStart.lowerBound)
        let persistentAction = cardSource[
            viewResultsStart.lowerBound..<liveResultsStart.lowerBound
        ]
        #expect(
            [
                ".font(.satoshiSubheadline.weight(.semibold))",
                ".foregroundStyle(AppTheme.cream)",
                ".frame(minWidth:Sizing.resetActionMinimumWidth," +
                    "minHeight:Sizing.minimumTouchTarget)",
                ".background(AppTheme.sage)",
                ".clipShape(Capsule())",
                ".frame(maxWidth:.infinity,alignment:.center)",
            ].allSatisfy { persistentAction.contains($0) }
        )
        #expect(
            !persistentAction.contains(".disabled(")
        )
        #expect(cardSource.contains(".accessibilityValue(correctionMessage??\"\")"))
        #expect(
            cardSource.contains(
                ".accessibilityHint(\"Validatestheformandfocusesthefirstfieldthatneedscorrection\")"
            )
        )
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

        let values = GaugeValueBindings(values: uniqueFormValues)
        values.unit.value = .inches
        let card = values.patternInstructionsCard(expanded: true)
        let yoke = card.displayBinding(
            for: values.binding(for: .patternYoke),
            field: .patternYoke
        )
        yoke.wrappedValue = GaugeStepperField.committedText(selection: 8)
        #expect(values[.patternYoke] == "20.32")
        #expect(yoke.wrappedValue == "8")
        yoke.wrappedValue = GaugeStepperField.adjustedText(
            values[.patternYoke],
            by: 1,
            field: .patternYoke,
            displayUnit: .inches,
            range: 2...39
        )
        #expect(values[.patternYoke] == "22.86")
        yoke.wrappedValue = GaugeStepperField.adjustedText(
            values[.patternYoke],
            by: -1,
            field: .patternYoke,
            displayUnit: .inches,
            range: 2...39
        )
        #expect(values[.patternYoke] == "20.32")
        let committedDraft = GaugeFormDraft(
            values: values.formValues,
            unit: .inches,
            patternDetailsExpanded: true
        )
        #expect(committedDraft.inputs != nil)

        yoke.wrappedValue = "9"
        #expect(values[.patternYoke] == "22.86")
        yoke.wrappedValue = ""
        #expect(values[.patternYoke] == "")
        #expect(yoke.wrappedValue == "")

        values[.patternYoke] = "not-a-number"
        #expect(yoke.wrappedValue == "not-a-number")
        values[.patternYoke] = MeasurementUnit.inches.centimeterStorageText(
            from: "1",
            cmRange: 5...100
        )
        #expect(yoke.wrappedValue == "1")
        values.unit.value = .centimeters
        values[.patternYoke] = "20"
        #expect(yoke.wrappedValue == "20")
    }

    @Test func sceneDraftStoreUsesDistinctKeysAndNamedValues() {
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

        let values = uniqueFormValues
        #expect(SceneDraftStore.reconcileInvalidInchProvenance(in: values, for: .inches) == values)
        #expect(SceneDraftStore.reconcileInvalidInchProvenance(in: values, for: .centimeters) == values)
    }

    @Test func stepperHelpersCoverValidationUnitsAndWarnings() {
        let pristineRequired = GaugeStepperField.accessibilityContract(
            text: " ",
            unit: "st",
            fieldLabel: "Pattern stitches",
            isRequired: true
        )
        #expect(pristineRequired.fieldValue == "Empty, Required")
        #expect(pristineRequired.fieldHint == "Double-tap to edit.")
        #expect(pristineRequired.pickerHint == "Double-tap to open wheel picker.")
        #expect(!pristineRequired.fieldValue.contains("is required"))

        let revealedInvalid = GaugeStepperField.accessibilityContract(
            text: " ",
            unit: "st",
            fieldLabel: "Pattern stitches",
            isRequired: true,
            validationMessage: "Pattern stitch gauge is required."
        )
        #expect(
            revealedInvalid.fieldValue ==
                "Empty, Required"
        )
        #expect(revealedInvalid.fieldHint == "Correct this value before viewing results.")
        #expect(!revealedInvalid.fieldValue.contains("is required"))

        let invalidNumber = GaugeStepperField.accessibilityContract(
            text: "abc",
            unit: "ro",
            fieldLabel: "Pattern rows",
            isRequired: true,
            validationMessage: "Enter pattern row gauge as a number."
        )
        #expect(
            invalidNumber.fieldValue ==
                "abc rows, Required, Enter pattern row gauge as a number."
        )
        #expect(invalidNumber.fieldHint == "Correct this value before viewing results.")

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

    @Test func keyboardAccessoryDoneResignsWithoutSubmitting() async throws {
        let appDirectory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let source = try String(
            contentsOf: appDirectory
                .appendingPathComponent("KnittingGaugeReconciler/Components/GaugeStepperField.swift"),
            encoding: .utf8
        ).replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
        #expect(
            source.contains("barButtonSystemItem:.flexibleSpace")
                && source.contains("barButtonSystemItem:.done")
                && source.contains("toolbar.items=[flexibleSpace,done]")
        )
        #expect(
            source.contains(
                "textField:textField,activate:false"
            )
        )

        let text = ValueBox("24")
        let focus = ValueBox<GaugeFormField?>(nil)
        let textField = FocusRecordingTextField()
        let field = GaugeKeyboardTextField(
            text: text.binding,
            field: .yourRows,
            focusedField: focus.binding,
            label: "Rows",
            value: "24 rows",
            hint: "Double-tap to edit.",
            showsCorrection: false
        )
        let coordinator = field.makeCoordinator()

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
        #expect(!textField.becameFirstResponder)
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
        #expect(textField.resignedFirstResponder)
        coordinator.didTapDone()

        focus.value = .yourRows
        await GaugeKeyboardTextField.updateFocusAfterUpdate(
            coordinator: coordinator,
            textField: textField
        ).value
        #expect(textField.becameFirstResponder)

        focus.value = nil
        await GaugeKeyboardTextField.updateFocusAfterUpdate(
            coordinator: coordinator,
            textField: textField
        ).value
        #expect(textField.resignedFirstResponder)

    }

    @Test func gaugeLeafAndCardProductionSeamHasNoSubmitCallback() throws {
        let appDirectory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let paths = [
            "KnittingGaugeReconciler/Components/GaugeStepperField.swift",
            "KnittingGaugeReconciler/Views/GaugeInputsCard.swift",
            "KnittingGaugeReconciler/Views/PatternInstructionsCard.swift",
        ]

        for path in paths {
            let source = try String(
                contentsOf: appDirectory.appendingPathComponent(path),
                encoding: .utf8
            )
            #expect(!source.contains("onSubmit"), "\(path) retains a submit callback")
        }
    }

    @Test func accessibilityAdjustmentsUseCurrentValueAndPreserveActivePickerSelection() {
        let text = ValueBox("25")
        let focus = ValueBox<GaugeFormField?>(nil)
        func field() -> GaugeKeyboardTextField {
            GaugeKeyboardTextField(
                text: text.binding,
                field: .yourRows,
                focusedField: focus.binding,
                label: "Rows",
                value: "\(text.value) rows",
                hint: "Double-tap to edit.",
                showsCorrection: false
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
        invalidValues[.patternStitches] = ""
        invalidValues[.patternRows] = "abc"
        let invalidCard = HostedViewProbe(
            invalidValues.gaugeCard(
                validationMessages: [
                    .patternStitches: "Pattern stitch gauge is required.",
                    .patternRows: "Enter pattern row gauge as a number.",
                ]
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
        let centimeterMath = LiveResultsView(
            result: result,
            inputs: inputs,
            unit: .centimeters,
            showFullMath: fullMath.binding,
            onShare: { _ in ["share"] }
        ).fullMathBreakdown.components(separatedBy: "\n")
        let inchMath = live.fullMathBreakdown.components(separatedBy: "\n")
        #expect(live.castOnDriftPill != nil)
        #expect(
            centimeterMath[0] ==
                "pattern: 99 st x 24 rows per 10 centimeters (aspect 4.12)"
        )
        #expect(
            inchMath[0] ==
                "pattern: 99 st x 24 rows per 4 inches (aspect 4.12)"
        )
        #expect(
            centimeterMath[1] ==
                "you:     4 st x 32 rows per 10 centimeters (aspect 0.12)"
        )
        #expect(
            inchMath[1] ==
                "you:     4 st x 32 rows per 4 inches (aspect 0.12)"
        )
        #expect(Array(centimeterMath[2...5]) == Array(inchMath[2...5]))
        #expect(inchMath.contains { $0.hasPrefix("yoke:") })
        #expect(inchMath.contains { $0.hasPrefix("body:") })
        #expect(inchMath.contains { $0.hasPrefix("sleeve:") })
        #expect(inchMath.contains { $0.hasPrefix("increase spacing") })
        #expect(inchMath.contains { $0.hasPrefix("cast-on adjust") })
        for prefix in ["increase spacing", "cast-on adjust"] {
            #expect(
                centimeterMath.first { $0.hasPrefix(prefix) } ==
                    inchMath.first { $0.hasPrefix(prefix) }
            )
        }
        let liveProbe = HostedViewProbe(live.environment(\.dynamicTypeSize, .accessibility2))
        #expect(liveProbe.size.height > 0)

        let correctionDraft = ValueBox(GaugeFormDraft())
        correctionDraft.value[.patternStitches] = "32"
        correctionDraft.value[.patternRows] = "24"
        correctionDraft.value[.yourStitches] = "32"
        correctionDraft.value[.yourRows] = "32"
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
            showsCorrection: true
        )
        #expect(HostedViewProbe(keyboard).size.height > 0)

        let stepper = GaugeStepperField(
            title: "Rows",
            text: text.binding,
            unit: "ro",
            field: .yourRows,
            validationMessage: nil,
            focusedField: focus.binding,
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

    @Test func contentAppearanceReconcilesDisconnectedSceneUnitsWithoutFocusing() throws {
        let contentForm = try #require(
            ContentView(sceneStorageEnabled: false).body as? GaugeFormView
        )
        #expect(HostedViewProbe(contentForm).size.width > 0)
        contentForm.applySceneDraft(
            values: GaugeTextDefaults().values,
            disclosure: true
        )
        contentForm.measurementUnitBinding.wrappedValue = .inches

        let inchScene = GaugeValueBindings(values: uniqueFormValues)
        let appliedSceneBindings = GaugeValueBindings()
        let appliedSceneForm = appliedSceneBindings.formView
        appliedSceneForm.applySceneDraft(values: uniqueFormValues, disclosure: true)
        #expect(appliedSceneForm.formValues == uniqueFormValues)
        #expect(appliedSceneForm.formDraft.patternDetailsExpanded)
        inchScene.unit.value = .inches
        inchScene[.patternYoke] = MeasurementUnit.inches.centimeterStorageText(
            from: "40",
            cmRange: 5...100
        )
        #expect(MeasurementUnit.invalidInchesText(from: inchScene[.patternYoke]) == "40")

        inchScene.unit.value = .centimeters
        let restoredCentimeterForm = inchScene.formView
        restoredCentimeterForm.sceneDidAppear()
        var expectedCentimeterValues = uniqueFormValues
        expectedCentimeterValues.patternYoke = "40"
        #expect(inchScene.formValues == expectedCentimeterValues)
        #expect(restoredCentimeterForm.formDraft.validationMessages.isEmpty)
        #expect(restoredCentimeterForm.formDraft.focusedField == nil)
        #expect(
            GaugeStepperField.pickerSelection(
                validationText: inchScene[.patternYoke],
                field: .patternYoke,
                displayUnit: .centimeters,
                range: 5...100
            ) == 40
        )

        let centimeterScene = GaugeValueBindings(values: uniqueFormValues)
        centimeterScene[.patternYoke] = "20.32"
        centimeterScene.unit.value = .inches
        let restoredInchForm = centimeterScene.formView
        restoredInchForm.sceneDidAppear()
        var expectedInchValues = uniqueFormValues
        expectedInchValues.patternYoke = "20.32"
        #expect(centimeterScene.formValues == expectedInchValues)
        #expect(restoredInchForm.formDraft.focusedField == nil)
        #expect(
            GaugeStepperField.pickerSelection(
                validationText: centimeterScene[.patternYoke],
                field: .patternYoke,
                displayUnit: .inches,
                range: 2...39
            ) == 8
        )
        let inchCard = centimeterScene.patternInstructionsCard(expanded: true)
        #expect(
            inchCard.displayBinding(
                for: centimeterScene.binding(for: .patternYoke),
                field: .patternYoke
            ).wrappedValue == "8"
        )

        let scene = KnittingGaugeReconcilerApp().body
        #expect(String(reflecting: type(of: scene)).contains("WindowGroup"))
    }

    @Test func contentBindingsActionsLifecycleAndSharingAreDeterministic() async throws {
        let values = GaugeValueBindings(values: uniqueFormValues)
        let view = values.formView
        #expect(HostedViewProbe(view).size.width > 0)
        let draftBinding = view.draftBinding(for: .patternStitches)
        draftBinding.wrappedValue = uniqueFormValues.patternStitches
        draftBinding.wrappedValue = "37"
        #expect(values[.patternStitches] == "37")

        let details = view.patternDetailsBinding
        details.wrappedValue = details.wrappedValue
        details.wrappedValue = true
        let unit = view.measurementUnitBinding
        unit.wrappedValue = unit.wrappedValue
        unit.wrappedValue = .inches
        var inchValues = view.formValues
        inchValues.patternYoke = MeasurementUnit.inches.centimeterStorageText(
            from: "1",
            cmRange: 5...100
        )
        inchValues.patternBody = MeasurementUnit.inches.centimeterStorageText(
            from: "40",
            cmRange: 5...100
        )
        inchValues.patternSleeve = MeasurementUnit.inches.centimeterStorageText(
            from: "sleeve-inch-sentinel",
            cmRange: 5...100
        )
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
        var expectedReconciledValues = inchValues
        expectedReconciledValues.patternYoke = "1"
        expectedReconciledValues.patternBody = "40"
        expectedReconciledValues.patternSleeve = "sleeve-inch-sentinel"
        #expect(reconciledValues == expectedReconciledValues)
        view.applySceneDraft(values: inchValues, disclosure: true)
        #expect(view.formValues == inchValues)
        #expect(view.reconcileSceneDraft(from: .centimeters, to: .inches) == nil)
        #expect(view.formValues == inchValues)
        let appliedValues = try #require(
            view.reconcileSceneDraft(from: .inches, to: .centimeters)
        )
        #expect(appliedValues == expectedReconciledValues)
        #expect(view.formValues == expectedReconciledValues)
        unit.wrappedValue = .centimeters
        view.finishEditing()
        var invalidDraft = GaugeFormDraft()
        invalidDraft[.patternStitches] = ""
        GaugeFormView.finishEditing(&invalidDraft)
        #expect(invalidDraft.focusedField == .patternStitches)

        view.undoReset()
        view.resetToDefaults()
        view.undoReset()
        #expect(view.formDraft.formValues == expectedReconciledValues)

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

        let valuesBeforeNoOpUnitChange = view.formDraft.formValues
        #expect(
            {
                view.measurementUnitChanged(.centimeters, .inches)
                return view.formDraft.formValues == valuesBeforeNoOpUnitChange
            }()
        )
        view.applySceneDraft(values: uniqueFormValues, disclosure: true)
        view.fieldFocusChanged(.patternRows, nil)
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
            unit: .inches,
            imageFactory: { _ in nil }
        )
        let fallbackText = try #require(fallback.first as? String)
        #expect(fallbackText.contains("32 st / 4 in"))
        #expect(fallbackText.contains("24 rows / 4 in"))
        #expect(!fallbackText.contains("/ 10 cm"))

        let shared = await GaugeFormView.shareItems(
            for: result,
            inputs: inputs,
            unit: .centimeters
        )
        let image = try #require(shared.first as? UIImage)
        #expect(image.size.width > 0)
        #expect(image.size.height > 0)

        let instanceItems = await view.shareItems(for: result)
        let instanceImage = try #require(instanceItems.first as? UIImage)
        #expect(instanceImage.size.width > 0)
        #expect(instanceImage.size.height > 0)
    }
}

private struct Scenario {
    let name: String
    let yourStitches: Double
    let yourRows: Double
    let stitchMismatch: Bool
    let rowMismatch: Bool
    let stitchPercent: Int
    let rowPercent: Int
}

private struct OptionalScenario {
    let name: String
    let inputs: GaugeInputs
    let kinds: [ResultSectionKind]
}

private struct LayoutMeasurement {
    let proposedWidth: CGFloat
    let textSize: DynamicTypeSize
    let size: CGSize
}

private extension Array where Element == LayoutMeasurement {
    func measurement(
        width: CGFloat,
        textSize: DynamicTypeSize
    ) -> LayoutMeasurement? {
        first {
            abs($0.proposedWidth - width) <= 0.5 &&
                $0.textSize == textSize
        }
    }
}

private struct LayoutFixtureTile: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
            Text(value)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
    }
}

@MainActor
private func requiredStepper(validationMessage: String?) -> some View {
    let text = ValueBox("")
    let focus = ValueBox<GaugeFormField?>(nil)
    return GaugeStepperField(
        title: "Stitches",
        text: text.binding,
        unit: "st",
        field: .patternStitches,
        validationMessage: validationMessage,
        focusedField: focus.binding
    )
}

@MainActor
private func expectNaturalSizeMatrix<Content: View>(
    _ name: String,
    widths: [CGFloat],
    textSizes: [DynamicTypeSize],
    view: () -> Content
) -> [LayoutMeasurement] {
    var measurements: [LayoutMeasurement] = []
    for width in widths {
        for textSize in textSizes {
            let probe = HostedViewProbe(
                view().environment(\.dynamicTypeSize, textSize),
                width: width
            )
            #expect(probe.hasFiniteNaturalSize, "\(name), \(width), \(textSize): finite size")
            #expect(probe.fits(proposedWidth: width), "\(name), \(width), \(textSize): width")
            measurements.append(
                LayoutMeasurement(
                    proposedWidth: width,
                    textSize: textSize,
                    size: probe.size
                )
            )
        }
    }
    return measurements
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
    private var active = false

    override var isFirstResponder: Bool {
        active
    }

    override func becomeFirstResponder() -> Bool {
        becameFirstResponder = true
        active = true
        return true
    }

    override func resignFirstResponder() -> Bool {
        resignedFirstResponder = true
        active = false
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
    private let patternStitches: ValueBox<String>
    private let patternRows: ValueBox<String>
    private let yourStitches: ValueBox<String>
    private let yourRows: ValueBox<String>
    private let patternCastOn: ValueBox<String>
    private let patternYoke: ValueBox<String>
    private let patternBody: ValueBox<String>
    private let patternSleeve: ValueBox<String>
    private let patternIncreases: ValueBox<String>
    private let focus = ValueBox<GaugeFormField?>(nil)
    private let details = ValueBox(false)
    let unit = ValueBox(MeasurementUnit.centimeters)

    init(
        values: GaugeFormValues = GaugeFormValues(
            patternStitches: "32",
            patternRows: "24",
            yourStitches: "32",
            yourRows: "32"
        )
    ) {
        patternStitches = ValueBox(values.patternStitches)
        patternRows = ValueBox(values.patternRows)
        yourStitches = ValueBox(values.yourStitches)
        yourRows = ValueBox(values.yourRows)
        patternCastOn = ValueBox(values.patternCastOn)
        patternYoke = ValueBox(values.patternYoke)
        patternBody = ValueBox(values.patternBody)
        patternSleeve = ValueBox(values.patternSleeve)
        patternIncreases = ValueBox(values.patternIncreases)
    }

    var patternDetailsExpanded: Bool {
        get { details.value }
        set { details.value = newValue }
    }

    var formValues: GaugeFormValues {
        GaugeFormValues(
            patternStitches: patternStitches.value,
            patternRows: patternRows.value,
            yourStitches: yourStitches.value,
            yourRows: yourRows.value,
            patternCastOn: patternCastOn.value,
            patternYoke: patternYoke.value,
            patternBody: patternBody.value,
            patternSleeve: patternSleeve.value,
            patternIncreases: patternIncreases.value
        )
    }

    subscript(field: GaugeFormField) -> String {
        get { formValues[keyPath: field.valueKeyPath] }
        set { valueBox(for: field).value = newValue }
    }

    func binding(for field: GaugeFormField) -> Binding<String> {
        valueBox(for: field).binding
    }

    private func valueBox(for field: GaugeFormField) -> ValueBox<String> {
        switch field {
        case .patternStitches: return patternStitches
        case .patternRows: return patternRows
        case .yourStitches: return yourStitches
        case .yourRows: return yourRows
        case .patternCastOn: return patternCastOn
        case .patternYoke: return patternYoke
        case .patternBody: return patternBody
        case .patternSleeve: return patternSleeve
        case .patternIncreases: return patternIncreases
        }
    }

    var formView: GaugeFormView {
        GaugeFormView(
            patternStitches: binding(for: .patternStitches),
            patternRows: binding(for: .patternRows),
            yourStitches: binding(for: .yourStitches),
            yourRows: binding(for: .yourRows),
            patternCastOn: binding(for: .patternCastOn),
            patternYoke: binding(for: .patternYoke),
            patternBody: binding(for: .patternBody),
            patternSleeve: binding(for: .patternSleeve),
            patternIncreases: binding(for: .patternIncreases),
            patternDetailsExpanded: details.binding,
            measurementUnit: unit.binding
        )
    }

    var gaugeCard: some View {
        gaugeCard(validationMessages: [:])
    }

    func gaugeCard(validationMessages: [GaugeFormField: String]) -> some View {
        GaugeInputsCard(
            patternStitches: binding(for: .patternStitches),
            patternRows: binding(for: .patternRows),
            yourStitches: binding(for: .yourStitches),
            yourRows: binding(for: .yourRows),
            unit: unit.binding,
            stitchMismatch: false,
            rowMismatch: true,
            stitchDelta: 0,
            rowDelta: 8,
            validationMessages: validationMessages,
            focusedField: focus.binding
        )
    }

    func patternCard(expanded: Bool) -> some View {
        patternInstructionsCard(expanded: expanded)
    }

    func patternInstructionsCard(expanded: Bool) -> PatternInstructionsCard {
        PatternInstructionsCard(
            patternCastOn: binding(for: .patternCastOn),
            patternYoke: binding(for: .patternYoke),
            patternBody: binding(for: .patternBody),
            patternSleeve: binding(for: .patternSleeve),
            patternIncreases: binding(for: .patternIncreases),
            unit: unit.binding,
            isExpanded: ValueBox(expanded).binding,
            validationMessages: [:],
            focusedField: focus.binding
        )
    }
}

@MainActor
private final class HostedViewProbe<Content: View> {
    private let controller: UIHostingController<Content>
    let size: CGSize

    var containsNaturalSize: Bool {
        controller.view.bounds.width + 0.5 >= size.width &&
            controller.view.bounds.height + 0.5 >= size.height &&
            size.width.isFinite &&
            size.height.isFinite
    }

    var geometryDescription: String {
        "bounds: \(controller.view.bounds.size), fitting size: \(size)"
    }

    var hasFiniteNaturalSize: Bool {
        size.width.isFinite &&
            size.height.isFinite &&
            size.width > 0 &&
            size.height > 0
    }

    func fits(proposedWidth: CGFloat) -> Bool {
        hasFiniteNaturalSize && size.width <= proposedWidth + 0.5
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
