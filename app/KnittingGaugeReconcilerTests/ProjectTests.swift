import CoreText
import SwiftData
import SwiftUI
import Testing
import UIKit
@testable import KnittingGaugeReconciler

@MainActor
@Suite("Projects")
struct ProjectTests {
    private static let sceneHost: (UIWindow, UIViewController)? = {
        let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first

        let controller = UIViewController()
        let window: UIWindow
        if let scene {
            window = UIWindow(windowScene: scene)
        } else {
            window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        }
        window.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        window.rootViewController = controller
        window.isHidden = false
        return (window, controller)
    }()

    @Test func satoshiFontsAreRegisteredScaledAndUsedByNavigation() throws {
        let regularURL = try #require(
            appResourceBundle.url(forResource: "Satoshi-Variable", withExtension: "ttf")
        )
        let italicURL = try #require(
            appResourceBundle.url(
                forResource: "Satoshi-VariableItalic",
                withExtension: "ttf"
            )
        )

        let registeredFonts = try #require(
            appResourceBundle.object(forInfoDictionaryKey: "UIAppFonts") as? [String]
        )
        #expect(
            Set(registeredFonts) == Set([
                "Satoshi-Variable.ttf",
                "Satoshi-VariableItalic.ttf",
            ])
        )
        for url in [regularURL, italicURL] {
            _ = CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
        #expect(UIFont.familyNames.contains(SatoshiVariableFont.familyName))
        #expect(UIFont(name: SatoshiVariableFont.regularPostScriptName, size: 17) != nil)
        #expect(UIFont(name: SatoshiVariableFont.italicPostScriptName, size: 17) != nil)

        let scaledFont = SatoshiVariableFont.scaledFont(
            size: 17,
            textStyle: .body,
            weight: .regular
        )
        #expect(scaledFont.familyName == SatoshiVariableFont.familyName)
        #expect(scaledFont.pointSize >= 17)
        #expect(
            scaledFont.fontDescriptor.object(
                forKey: UIFontDescriptor.AttributeName(
                    rawValue: kCTFontVariationAttribute as String
                )
            ) != nil
        )

        let fallbackFont = SatoshiVariableFont.scaledFont(
            size: 17,
            textStyle: .body,
            weight: .regular,
            fontName: "Unavailable Font"
        )
        #expect(fallbackFont.familyName != SatoshiVariableFont.familyName)

        _ = Font.satoshiLargeTitle
        _ = Font.satoshiTitle
        _ = Font.satoshiTitle2
        _ = Font.satoshiTitle3
        _ = Font.satoshiHeadline
        _ = Font.satoshiBody
        _ = Font.satoshiCallout
        _ = Font.satoshiSubheadline
        _ = Font.satoshiFootnote
        _ = Font.satoshiCaption
        _ = Font.satoshiCaption2

        _ = KnittingGaugeReconcilerApp()
        let navigationAppearance = UINavigationBar.appearance().standardAppearance
        let navigationFont = try #require(
            navigationAppearance.titleTextAttributes[.font] as? UIFont
        )
        let largeNavigationFont = try #require(
            navigationAppearance.largeTitleTextAttributes[.font] as? UIFont
        )
        #expect(navigationFont.familyName == SatoshiVariableFont.familyName)
        #expect(largeNavigationFont.familyName == SatoshiVariableFont.familyName)
        #expect(navigationFont.pointSize >= 17)
        #expect(largeNavigationFont.pointSize >= 34)
    }

    @Test func taxonomyAndMetadataCoverEverySupportedProjectShape() {
        #expect(ProjectType.allCases.map(\.label) == [
            "Headwear", "Tops", "Bottoms", "Footwear", "Other",
        ])
        #expect(ProjectType.allCases.map(\.id) == ProjectType.allCases)
        #expect(ProjectType.allCases.allSatisfy { !$0.description.isEmpty })
        #expect(ProjectType.allCases.allSatisfy {
            ProjectIcons.symbols(for: $0).contains($0.defaultSymbolName)
        })
        #expect(ProjectIcons.symbols(for: .bottoms) == [
            "figure.stand", "figure.stand.dress",
        ])
        #expect(ProjectIcons.symbols(for: .tops) == [
            "tshirt.fill", "coat.fill",
        ])
        #expect(ProjectIcons.symbols(
            for: .bottoms,
            availableWhere: { $0 != "figure.stand.dress" }
        ) == ["figure.stand"])
        #expect(!ProjectIcons.all.contains("scissors"))
        #expect(ProjectIcons.clipsTopHalf("figure.stand"))
        #expect(ProjectIcons.clipsTopHalf("figure.stand.dress"))
        #expect(!ProjectIcons.clipsTopHalf("tshirt.fill"))
        #expect(ProjectType.tops.constructions == [
            .circularYokeRaglan, .setInSleeve, .dropShoulder,
        ])
        #expect(ProjectType.bottoms.constructions == [.skirt, .pantsShortsLeggings])
        #expect(ProjectType.headwear.constructions.isEmpty)
        #expect(ProjectType.footwear.constructions.isEmpty)
        #expect(ProjectType.other.constructions.isEmpty)

        for construction in ProjectConstruction.allCases {
            #expect(!construction.label.isEmpty)
            #expect(!construction.detail.isEmpty)
        }
        for shape in ProjectCrownShape.allCases {
            #expect(!shape.label.isEmpty)
        }
        for kind in allMeasurementKinds {
            #expect(!kind.label.isEmpty)
            #expect(!kind.axis.resultLabel.isEmpty)
        }
        for color in ProjectColor.allCases {
            #expect(!color.label.isEmpty)
            _ = color.color
            _ = color.symbolColor
        }
        #expect(ProjectColor.selectableCases == ProjectColor.allCases)
        #expect(ProjectColor.sage.color == AppTheme.sage)
        #expect(ProjectColor.blue.color == Color(uiColor: .systemBlue))
        #expect(ProjectColor.indigo.color == Color(uiColor: .systemIndigo))
        #expect(ProjectColor.purple.color == Color(uiColor: .systemPurple))
        #expect(ProjectColor.pink.color == Color(uiColor: .systemPink))
        #expect(ProjectColor.red.color == Color(uiColor: .systemRed))
        #expect(ProjectColor.orange.color == Color(uiColor: .systemOrange))
        #expect(ProjectColor.yellow.color == Color(uiColor: .systemYellow))
        #expect(ProjectColor.mint.color == Color(uiColor: .systemMint))
        #expect(ProjectColor.terracotta.color == AppTheme.terracotta)
        #expect(ProjectColor.graphite.color == Color(uiColor: .systemGray))
        for type in ProjectType.allCases {
            let symbols = ProjectIcons.symbols(for: type)
            #expect(!symbols.isEmpty)
            for symbol in symbols {
                #expect(ProjectIcons.label(for: symbol) != "Project icon")
                #expect(UIImage(systemName: symbol) != nil)
            }
        }
        #expect(ProjectIcons.label(for: "missing") == "Project icon")
        #expect(
            BottomHalfShape().path(in: CGRect(x: 0, y: 0, width: 20, height: 20)).boundingRect ==
                CGRect(x: 0, y: 10, width: 20, height: 10)
        )
        _ = ProjectIconImage(symbolName: "figure.stand").body
        _ = ProjectIconImage(symbolName: "tshirt.fill").body
    }

    @Test func draftsMapEveryConstructionToOptionalAxisMeasurements() {
        let cases: [(ProjectType, ProjectConstruction?, [ProjectMeasurementKind])] = [
            (
                .tops,
                .circularYokeRaglan,
                [
                    .neckOpeningCircumference, .chestCircumference,
                    .upperSleeveCircumference, .cuffCircumference,
                    .yokeRaglanDepth, .bodyLength, .sleeveLength,
                ]
            ),
            (
                .tops,
                .setInSleeve,
                [
                    .chestCircumference, .crossBackWidth, .upperArmCircumference,
                    .cuffCircumference, .bodyLength, .armholeDepthSetIn,
                    .sleeveLength, .sleeveCapDepth,
                ]
            ),
            (
                .tops,
                .dropShoulder,
                [
                    .chestCircumference, .upperSleeveCircumference,
                    .cuffCircumference, .bodyLength, .armholeDepthDrop,
                    .shoulderToCuffLength,
                ]
            ),
            (
                .bottoms,
                .skirt,
                [
                    .waistCircumference, .hipCircumference, .hemCircumference,
                    .waistToHipDepth, .bodyLength,
                ]
            ),
            (
                .bottoms,
                .pantsShortsLeggings,
                [
                    .waistCircumference, .hipCircumference, .thighCircumference,
                    .legOpeningCircumference, .waistToHipDepth, .rise, .legLength,
                ]
            ),
            (.headwear, nil, [.hatCircumference, .crownDepth]),
            (
                .footwear,
                nil,
                [
                    .footCircumference, .sockCuffCircumference,
                    .footLength, .sockHeight, .heelDepth,
                ]
            ),
            (.other, nil, [.customWidth, .customDepth]),
        ]

        for (type, construction, expected) in cases {
            var draft = validDraft(type: type, construction: construction)
            #expect(draft.measurementKinds == expected)
            #expect(draft.hasMeasurementValues)
            #expect(draft.isIdentityValid)
            #expect(draft.isConstructionValid)
            #expect(draft.isGaugeValid)
            #expect(draft.isMeasurementsValid)
            #expect(draft.makeProject() != nil)

            draft.measurementValues = [:]
            #expect(!draft.hasMeasurementValues)
            #expect(draft.enteredMeasurementKinds.isEmpty)
            #expect(draft.isMeasurementValid(expected[0]))
            #expect(draft.isMeasurementsValid)
            #expect(draft.makeProject()?.measurements.isEmpty == true)

            draft.measurementValues[expected[0]] = "invalid"
            #expect(!draft.isMeasurementsValid)
            #expect(draft.makeProject() == nil)
            draft.measurementValues[expected[0]] = "501"
            #expect(draft.isMeasurementsValid)
            draft.measurementValues[expected[0]] = "20.5"
            #expect(draft.isMeasurementsValid)
            draft.measurementValues[expected[0]] = "0"
            #expect(!draft.isMeasurementsValid)
            draft.measurementValues[expected[0]] = "-0.1"
            #expect(!draft.isMeasurementsValid)
        }
    }

    @Test func draftValidationRejectsInvalidIdentityGaugeAndConstruction() {
        var draft = ProjectDraft()
        #expect(!draft.isIdentityValid)
        draft.name = "Hat"
        draft.symbolName = "missing"
        #expect(!draft.isIdentityValid)

        draft = validDraft(type: .tops, construction: .skirt)
        #expect(!draft.isConstructionValid)
        draft = validDraft(type: .bottoms, construction: .setInSleeve)
        #expect(!draft.isConstructionValid)

        draft = validDraft(type: .headwear)
        draft.crownShape = .faceted
        draft.crownSections = 4
        #expect(!draft.isConstructionValid)
        draft.crownSections = 5
        #expect(draft.isConstructionValid)
        draft.crownSections = 6
        #expect(draft.isConstructionValid)

        draft = validDraft(type: .footwear)
        draft.gaugeValues.yourRows = "0"
        #expect(!draft.isGaugeValid)
        #expect(draft.measurementValue(for: .rise).isEmpty)
        draft = validDraft(type: .footwear)
        draft.measurementValues.removeValue(forKey: .heelDepth)
        #expect(draft.isMeasurementsValid)
        draft.measurementValues[.heelDepth] = "0"
        #expect(!draft.isMeasurementsValid)
    }

    @Test func selectingTypeResetsIncompatibleIcons() {
        var draft = ProjectDraft()
        draft.measurementValues[.yokeRaglanDepth] = "20"
        draft.selectType(.bottoms)
        #expect(draft.type == .bottoms)
        #expect(draft.construction == .skirt)
        #expect(draft.measurementValues.isEmpty)
        #expect(draft.symbolName == ProjectType.bottoms.defaultSymbolName)

        draft = ProjectDraft()
        draft.symbolName = "tshirt.fill"
        draft.selectType(.tops)
        #expect(draft.symbolName == "tshirt.fill")
        draft.selectType(.headwear)
        #expect(draft.symbolName == ProjectType.headwear.defaultSymbolName)
        #expect(draft.construction == nil)

        var legacyProject = validDraft(type: .tops).makeProject()
        legacyProject?.symbolName = "tshirt"
        if let legacyProject {
            #expect(ProjectDraft(project: legacyProject).symbolName == "tshirt.fill")
        }
    }

    @Test func projectCreationTrimsAndRoundTripsAllStoredValues() throws {
        let id = UUID()
        let now = Date(timeIntervalSince1970: 123)
        var draft = validDraft(type: .headwear)
        draft.name = "  Trail Hat  "
        draft.crownShape = .faceted
        draft.crownSections = 6
        draft.notes = "  Use the blue yarn.  "
        draft.countConstraint = .patternRepeat
        draft.stitchRepeat = "6"
        draft.rowRepeat = "8"
        let project = try #require(draft.makeProject(id: id, now: now))

        #expect(project.name == "Trail Hat")
        #expect(project.subtitle == "Headwear · Pentagon / Hexagon")
        #expect(project.crownSections == 6)
        #expect(project.notes == "Use the blue yarn.")
        #expect(project.measurementValue(for: .crownDepth) == "20")
        #expect(project.measurementValue(for: .rise).isEmpty)
        #expect(project.createdAt == now)
        #expect(project.gaugeInputs != nil)
        #expect(project.gaugeResult != nil)
        #expect(project.measurements.first?.id == .hatCircumference)
        #expect(project.countRules?.constraint == .patternRepeat)
        #expect(project.countRules?.stitchRepeat == 6)
        #expect(project.countRules?.rowRepeat == 8)
        #expect(project.measurementResults.first?.patternCount == 42)
        #expect(project.measurementResults.first?.requiredCount == 48)
        #expect(project.measurementResults.first?.resultLabel == "stitches")
        #expect(project.measurementResults.last?.patternCount == 48)
        #expect(project.measurementResults.last?.requiredCount == 56)
        #expect(project.measurementResults.last?.resultLabel == "rows")
        let restoredDraft = ProjectDraft(project: project)
        #expect(restoredDraft.countConstraint == .patternRepeat)
        #expect(restoredDraft.stitchRepeat == "6")
        #expect(restoredDraft.rowRepeat == "8")
        #expect(try JSONDecoder().decode(
            KnittingProject.self,
            from: JSONEncoder().encode(project)
        ) == project)
        var legacyObject = try #require(
            JSONSerialization.jsonObject(
                with: JSONEncoder().encode(project)
            ) as? [String: Any]
        )
        legacyObject.removeValue(forKey: "notes")
        legacyObject.removeValue(forKey: "countRules")
        let legacyProject = try JSONDecoder().decode(
            KnittingProject.self,
            from: JSONSerialization.data(withJSONObject: legacyObject)
        )
        #expect(legacyProject.notes == nil)
        #expect(legacyProject.countRules == nil)
        #expect(legacyProject.measurementResults.first?.patternCount == 40)
        #expect(legacyProject.measurementResults.first?.requiredCount == 44)
        #expect(ProjectDraft(project: legacyProject).countConstraint == .wholeNumber)
        expectFinite(ProjectOverviewCard(project: legacyProject))

        var top = try #require(
            validDraft(type: .tops, construction: .dropShoulder).makeProject()
        )
        #expect(top.subtitle == "Tops · Drop Shoulder")
        top.construction = nil
        #expect(top.subtitle == "Tops")
    }

    @Test func countConstraintsAlwaysRoundUpAcrossBothAxes() {
        for constraint in ProjectCountConstraint.allCases {
            #expect(constraint.id == constraint)
            #expect(!constraint.label.isEmpty)
            #expect(!constraint.pickerLabel.isEmpty)
            #expect(!constraint.explanation.isEmpty)
        }

        let whole = ProjectCountRules.wholeNumber
        #expect(whole.requiredCount(for: 44, axis: .horizontal) == 44)
        #expect(whole.requiredCount(for: 44.01, axis: .vertical) == 45)

        let even = ProjectCountRules(
            constraint: .evenNumber,
            stitchRepeat: nil,
            rowRepeat: nil
        )
        #expect(even.requiredCount(for: 44, axis: .horizontal) == 44)
        #expect(even.requiredCount(for: 44.01, axis: .vertical) == 46)
        #expect(even.summary == "Rounded up to even numbers")

        let repeatRules = ProjectCountRules(
            constraint: .patternRepeat,
            stitchRepeat: 6,
            rowRepeat: 8
        )
        #expect(repeatRules.requiredCount(for: 44.01, axis: .horizontal) == 48)
        #expect(repeatRules.requiredCount(for: 52.01, axis: .vertical) == 56)
        let missingRepeats = ProjectCountRules(
            constraint: .patternRepeat,
            stitchRepeat: nil,
            rowRepeat: nil
        )
        #expect(missingRepeats.summary == "Rounded up to 1-stitch and 1-row repeats")
        #expect(missingRepeats.requiredCount(for: 2.1, axis: .horizontal) == 3)
        #expect(missingRepeats.requiredCount(for: 2.1, axis: .vertical) == 3)
        #expect(ProjectCountRules.wholeNumber.requiredCount(
            for: 25 * 17.6 / 10,
            axis: .horizontal
        ) == 44)
        #expect(ProjectCountRules(
            constraint: .evenNumber,
            stitchRepeat: nil,
            rowRepeat: nil
        ).requiredCount(for: 25 * 17.6 / 10, axis: .horizontal) == 44)
        #expect(ProjectCountRules(
            constraint: .patternRepeat,
            stitchRepeat: 4,
            rowRepeat: 4
        ).requiredCount(for: 25 * 17.6 / 10, axis: .horizontal) == 44)

        guard var invalidProject = validDraft(type: .headwear).makeProject() else {
            Issue.record("Expected the valid draft to create a project")
            return
        }
        invalidProject.gaugeValues.yourStitches = "bad"
        #expect(invalidProject.measurementResults.isEmpty)
        guard let freshProject = validDraft(type: .headwear).makeProject() else {
            Issue.record("Expected the valid draft to create a project")
            return
        }
        invalidProject = freshProject
        invalidProject.measurements[0].centimeters = "bad"
        #expect(invalidProject.measurementResults.count == 1)
    }

    @Test func patternRepeatRequiresBothValidMultiples() {
        var draft = validDraft(type: .headwear)
        draft.countConstraint = .patternRepeat
        #expect(!draft.isMeasurementsValid)
        #expect(draft.makeProject() == nil)

        draft.stitchRepeat = "6"
        #expect(!draft.isMeasurementsValid)
        draft.rowRepeat = "8"
        #expect(draft.isMeasurementsValid)
        #expect(draft.validatedCountRules?.summary == "Rounded up to 6-stitch and 8-row repeats")

        draft.stitchRepeat = "0"
        #expect(!draft.isMeasurementsValid)
        draft.stitchRepeat = "1000"
        #expect(!draft.isMeasurementsValid)
    }

    @Test func optionalMeasurementsPreservePositiveDecimalsAcrossUnits() {
        let acceptedInches = [
            (display: "0.1", stored: "0.254"),
            (display: "25", stored: "63.5"),
            (display: "25.5", stored: "64.77"),
            (display: "500.125", stored: "1270.3175"),
            (display: "1000000.25", stored: "2540000.635"),
        ]
        let acceptedCentimeters = ["0.1", "25.5", "500.125", "1000000.25"]
        let rejected = ["0", "-0.1", "bad"]

        for kind in allMeasurementKinds {
            let inchBox = DraftBox(ProjectDraft())
            inchBox.value.measurementUnit = .inches
            let inchStep = CreateProjectMeasurementsStep(draft: inchBox.binding)
            #expect(
                inchStep.measurementValidationMessage(for: kind) ==
                    "Enter a number greater than 0 in, or leave this blank."
            )

            for testCase in acceptedInches {
                inchStep.measurementDisplayBinding(for: kind).wrappedValue = testCase.display
                #expect(
                    inchBox.value.measurementValues[kind] == testCase.stored,
                    "\(kind) stores \(testCase.display) inches canonically"
                )
                #expect(
                    inchStep.measurementDisplayValue(for: kind) == testCase.display,
                    "\(kind) displays \(testCase.display) inches"
                )
                #expect(
                    inchBox.value.isMeasurementValid(kind),
                    "\(kind) accepts \(testCase.display) inches"
                )
            }

            for value in rejected {
                inchStep.measurementDisplayBinding(for: kind).wrappedValue = value
                #expect(
                    inchStep.measurementDisplayValue(for: kind) == value,
                    "\(kind) preserves invalid input \(value)"
                )
                #expect(
                    !inchBox.value.isMeasurementValid(kind),
                    "\(kind) rejects \(value) inches"
                )
            }

            let centimeterBox = DraftBox(ProjectDraft())
            let centimeterStep = CreateProjectMeasurementsStep(draft: centimeterBox.binding)
            for value in acceptedCentimeters {
                centimeterStep.measurementDisplayBinding(for: kind).wrappedValue = value
                #expect(centimeterBox.value.measurementValues[kind] == value)
                #expect(centimeterStep.measurementDisplayValue(for: kind) == value)
                #expect(centimeterBox.value.isMeasurementValid(kind))
            }
            for value in rejected {
                centimeterStep.measurementDisplayBinding(for: kind).wrappedValue = value
                #expect(centimeterStep.measurementDisplayValue(for: kind) == value)
                #expect(!centimeterBox.value.isMeasurementValid(kind))
            }
        }

        let germanLocale = Locale(identifier: "de_DE")
        #expect(
            MeasurementUnit.inches.positiveMeasurementStorageText(
                from: "25,5",
                locale: germanLocale
            ) == "64.77"
        )
        #expect(
            MeasurementUnit.centimeters.positiveMeasurementStorageText(
                from: "25,5",
                locale: germanLocale
            ) == "25.5"
        )
        #expect(
            MeasurementUnit.inches.positiveMeasurementDisplayText(from: "64.77") == "25.5"
        )
    }

    @Test func decimalMeasurementsRoundTripThroughSwiftData() throws {
        let container = try inMemoryProjectContainer()
        var draft = validDraft(type: .other)
        draft.measurementUnit = .inches
        let box = DraftBox(draft)
        let step = CreateProjectMeasurementsStep(draft: box.binding)
        step.measurementDisplayBinding(for: .customWidth).wrappedValue = "25.5"
        step.measurementDisplayBinding(for: .customDepth).wrappedValue = "12.125"
        let project = try #require(box.value.makeProject())
        let store = ProjectStore(modelContainer: container)

        #expect(store.add(project))
        let reloaded = try #require(
            ProjectStore(modelContainer: container).project(id: project.id)
        )
        #expect(reloaded.measurementValue(for: .customWidth) == "64.77")
        #expect(reloaded.measurementValue(for: .customDepth) == "30.7975")

        let reloadedBox = DraftBox(ProjectDraft(project: reloaded))
        let reloadedStep = CreateProjectMeasurementsStep(draft: reloadedBox.binding)
        #expect(reloadedStep.measurementDisplayValue(for: .customWidth) == "25.5")
        #expect(reloadedStep.measurementDisplayValue(for: .customDepth) == "12.125")
        #expect(reloadedBox.value.isMeasurementsValid)
        #expect(
            reloaded.measurementResults.allSatisfy {
                $0.patternCount > 0 && $0.requiredCount > 0
            }
        )
    }

    @Test(arguments: [
        Double.greatestFiniteMagnitude,
        Double.infinity,
        Double.nan,
    ])
    func countRoundingRejectsValuesOutsideIntRange(_ rawCount: Double) {
        #expect(
            ProjectCountRules.wholeNumber.requiredCount(
                for: rawCount,
                axis: .horizontal
            ) == nil
        )
    }

    @Test func decimalMeasurementBoundsNeverReachTrappingIntConversion() throws {
        let extreme = NSDecimalNumber(decimal: Decimal.greatestFiniteMagnitude).stringValue
        let inchBox = DraftBox(validDraft(type: .other))
        inchBox.value.measurementUnit = .inches
        let inchStep = CreateProjectMeasurementsStep(draft: inchBox.binding)
        inchStep.measurementDisplayBinding(for: .customWidth).wrappedValue = extreme
        #expect(inchStep.measurementDisplayValue(for: .customWidth) == extreme)
        #expect(!inchBox.value.isMeasurementValid(.customWidth))

        let centimeterBox = DraftBox(validDraft(type: .other))
        let centimeterStep = CreateProjectMeasurementsStep(draft: centimeterBox.binding)
        centimeterStep.measurementDisplayBinding(for: .customWidth).wrappedValue = extreme
        #expect(
            centimeterStep.measurementValidationMessage(for: .customWidth) ==
                "This measurement is too large to calculate."
        )
        #expect(!centimeterBox.value.isMeasurementValid(.customWidth))
        #expect(centimeterBox.value.makeProject() == nil)

        var persisted = try #require(validDraft(type: .other).makeProject())
        persisted.measurements = [
            ProjectMeasurementValue(kind: .customWidth, centimeters: extreme),
        ]
        #expect(persisted.measurementResults.isEmpty)
    }

    @Test func storeLoadsPersistsUpdatesDeletesAndResets() throws {
        let container = try inMemoryProjectContainer()
        let project = try #require(validDraft(type: .footwear).makeProject())
        let store = ProjectStore(modelContainer: container)

        #expect(store.add(project))
        #expect(store.project(id: project.id) == project)
        let reloaded = ProjectStore(modelContainer: container)
        #expect(reloaded.projects == [project])

        var values = project.gaugeValues
        values.yourRows = "31"
        let updatedAt = Date(timeIntervalSince1970: 456)
        #expect(reloaded.updateWorkspace(
            id: project.id,
            gaugeValues: values,
            unit: .inches,
            patternDetailsExpanded: true,
            now: updatedAt
        ))
        #expect(reloaded.projects[0].gaugeValues == values)
        #expect(reloaded.projects[0].measurementUnit == .inches)
        #expect(reloaded.projects[0].patternDetailsExpanded)
        #expect(reloaded.projects[0].updatedAt == updatedAt)
        #expect(!reloaded.updateWorkspace(
            id: UUID(),
            gaugeValues: values,
            unit: .centimeters,
            patternDetailsExpanded: false
        ))

        var editedDraft = ProjectDraft(project: reloaded.projects[0])
        editedDraft.name = "Edited Project"
        let edited = try #require(editedDraft.makeProject(
            id: project.id,
            createdAt: project.createdAt,
            patternDetailsExpanded: true,
            now: updatedAt
        ))
        #expect(reloaded.update(edited))
        #expect(reloaded.projects[0].name == "Edited Project")
        #expect(reloaded.projects[0].createdAt == project.createdAt)
        #expect(!reloaded.update(try #require(validDraft(type: .other).makeProject())))

        reloaded.delete(at: IndexSet(integer: 0))
        #expect(reloaded.projects.isEmpty)
        reloaded.resetArchive()
        #expect(reloaded.issue == nil)
    }

    @Test func storeSurfacesCorruptionUnsupportedSchemasAndRollsBackFailedWrites() throws {
        let container = try inMemoryProjectContainer()
        let project = try #require(validDraft(type: .other).makeProject())
        #expect(ProjectStore(modelContainer: container).add(project))
        let failing = ProjectStore(
            modelContainer: container,
            beforeSave: { throw StubError.failed }
        )

        var values = project.gaugeValues
        values.patternRows = "40"
        #expect(!failing.updateWorkspace(
            id: project.id,
            gaugeValues: values,
            unit: .inches,
            patternDetailsExpanded: true
        ))
        #expect(failing.projects == [project])
        failing.delete(at: IndexSet(integer: 0))
        #expect(failing.projects == [project])
        #expect(failing.issue?.kind == .save)
        failing.resetArchive()
        #expect(failing.projects == [project])

        var shouldFail = true
        let recoveringContainer = try inMemoryProjectContainer()
        _ = ProjectStore(modelContainer: recoveringContainer)
        let recovering = ProjectStore(
            modelContainer: recoveringContainer,
            beforeSave: {
                if shouldFail {
                    shouldFail = false
                    throw StubError.failed
                }
            }
        )
        #expect(!recovering.add(project))
        #expect(recovering.issue?.kind == .save)
        #expect(recovering.add(project))
        #expect(recovering.issue == nil)
    }

    @Test func storeRejectsInvalidSwiftDataRowsAndUnavailableContainers() throws {
        let project = try #require(validDraft(type: .other).makeProject())
        let payload = try JSONEncoder().encode(project)

        let corruptContainer = try inMemoryProjectContainer()
        let corruptContext = ModelContext(corruptContainer)
        corruptContext.insert(
            StoredProjectRecord(
                key: project.id.uuidString,
                payload: Data([0xFF]),
                payloadVersion: ProjectStore.schemaVersion,
                createdAt: project.createdAt
            )
        )
        try corruptContext.save()
        let corrupt = ProjectStore(modelContainer: corruptContainer)
        #expect(corrupt.projects.isEmpty)
        #expect(corrupt.issue?.kind == .load)
        #expect(corrupt.issue?.id.contains("load") == true)

        let unsupportedContainer = try inMemoryProjectContainer()
        let unsupportedContext = ModelContext(unsupportedContainer)
        unsupportedContext.insert(
            StoredProjectRecord(
                key: project.id.uuidString,
                payload: payload,
                payloadVersion: ProjectStore.schemaVersion + 1,
                createdAt: project.createdAt
            )
        )
        try unsupportedContext.save()
        let unsupported = ProjectStore(
            modelContainer: unsupportedContainer
        )
        #expect(unsupported.projects.isEmpty)
        #expect(unsupported.issue?.kind == .load)

        let mismatchedContainer = try inMemoryProjectContainer()
        let mismatchedContext = ModelContext(mismatchedContainer)
        mismatchedContext.insert(
            StoredProjectRecord(
                key: UUID().uuidString,
                payload: payload,
                payloadVersion: ProjectStore.schemaVersion,
                createdAt: project.createdAt
            )
        )
        try mismatchedContext.save()
        let mismatched = ProjectStore(
            modelContainer: mismatchedContainer
        )
        #expect(mismatched.projects.isEmpty)
        #expect(mismatched.issue?.kind == .load)

        let unavailable = ProjectStore(
            makeModelContainer: { throw StubError.failed }
        )
        #expect(unavailable.issue?.kind == .load)
        #expect(!unavailable.add(project))
        unavailable.delete(at: [])
        unavailable.resetArchive()
        #expect(unavailable.issue?.kind == .save)
    }

    @Test func projectViewsHaveFiniteLayoutsAcrossWizardBranches() throws {
        let widths: [CGFloat] = [320, 390, 760]
        let drafts = [
            validDraft(type: .tops, construction: .circularYokeRaglan),
            validDraft(type: .tops, construction: .setInSleeve),
            validDraft(type: .tops, construction: .dropShoulder),
            validDraft(type: .bottoms, construction: .skirt),
            validDraft(type: .bottoms, construction: .pantsShortsLeggings),
            validDraft(type: .headwear),
            facetedHatDraft(),
            validDraft(type: .footwear),
            validDraft(type: .other),
        ]

        for width in widths {
            for step in CreateProjectFlow.Step.allCases {
                expectFinite(CreateProjectProgressHeader(step: step), width: width)
            }
            for draft in drafts {
                let box = DraftBox(draft)
                expectFinite(CreateProjectIdentityStep(draft: box.binding), width: width)
                expectFinite(CreateProjectConstructionStep(draft: box.binding), width: width)
                expectFinite(CreateProjectGaugeStep(draft: box.binding), width: width)
                expectFinite(CreateProjectMeasurementsStep(draft: box.binding), width: width)
                expectFinite(CreateProjectNotesStep(draft: box.binding), width: width)
                expectFinite(CreateProjectReviewStep(draft: draft), width: width)
            }
        }

        let project = try #require(drafts[0].makeProject())
        let store = try projectStore()
        #expect(store.add(project))
        expectFinite(ProjectRow(project: project))
        expectFinite(ProjectSymbol(symbolName: project.symbolName, color: .yellow, size: 48))
        expectFinite(ProjectResultsView(projectID: project.id, store: store))
        expectSceneRoot(ProjectLibraryView(store: store))
        expectSceneRoot(ProjectLibraryView(store: try projectStore()))
        expectFinite(ProjectOverviewCard(project: project))
        var skippableDraft = drafts[0]
        skippableDraft.measurementValues = [:]
        skippableDraft.notes = ""
        let skippableProject = try #require(skippableDraft.makeProject())
        expectFinite(ProjectOverviewCard(project: skippableProject))
        let facetedProject = try #require(facetedHatDraft().makeProject())
        expectFinite(ProjectOverviewCard(project: facetedProject))
        var notedDraft = drafts[0]
        notedDraft.notes = "Check the yarn lot."
        let notedProject = try #require(notedDraft.makeProject())
        expectFinite(ProjectOverviewCard(project: notedProject))
        expectFinite(
            CreateProjectSelectionCard(
                title: "Selected",
                detail: "A selected construction.",
                isSelected: true,
                action: {}
            )
        )
        expectSceneRoot(
            CreateProjectFlow(store: store, onCreated: { _ in })
        )
    }

    @Test func wizardActionsAndBindingsCoverEveryBranch() throws {
        let store = try projectStore()
        let valid = validDraft(type: .tops, construction: .circularYokeRaglan)

        for step in CreateProjectFlow.Step.allCases {
            expectSceneRoot(CreateProjectFlow(
                store: store,
                onCreated: { _ in },
                draft: step == .identity ? ProjectDraft() : valid,
                step: step
            ))
        }
        let discardState = CreateProjectFlowState(
            store: store,
            onCreated: { _ in },
            draft: valid,
            showDiscardConfirmation: true
        )
        expectSceneRoot(
            CreateProjectFlow(state: discardState),
            cleanup: { discardState.showDiscardConfirmation = false }
        )
        let saveFailureState = CreateProjectFlowState(
            store: store,
            onCreated: { _ in },
            draft: valid,
            showSaveFailure: true
        )
        expectSceneRoot(
            CreateProjectFlow(state: saveFailureState),
            cleanup: { saveFailureState.showSaveFailure = false }
        )
        var dismissCount = 0
        var createdID: UUID?
        for step in CreateProjectFlow.Step.allCases {
            let state = CreateProjectFlowState(
                store: store,
                onCreated: { createdID = $0 },
                onDismiss: { dismissCount += 1 },
                draft: step == .identity ? ProjectDraft() : valid,
                step: step,
                showDiscardConfirmation: true,
                showSaveFailure: true
            )
            _ = state.canAdvance
            _ = state.hasChanges
            state.moveBack()
            state.step = step
            state.advance()
        }
        #expect(createdID != nil)

        var skippableDraft = valid
        skippableDraft.measurementValues = [:]
        let measurementsState = CreateProjectFlowState(
            store: store,
            onCreated: { _ in },
            draft: skippableDraft,
            step: .measurements
        )
        #expect(measurementsState.canAdvance)
        #expect(measurementsState.primaryActionLabel == "Skip")
        #expect(measurementsState.primaryActionSystemImage == "chevron.forward")
        measurementsState.step = .notes
        #expect(measurementsState.primaryActionLabel == "Skip")
        measurementsState.draft.notes = "Keep this."
        #expect(measurementsState.primaryActionLabel == "Next")
        measurementsState.step = .review
        #expect(measurementsState.primaryActionLabel == "View Results")
        #expect(measurementsState.primaryActionSystemImage == "checkmark")

        let blankState = CreateProjectFlowState(
            store: store,
            onCreated: { _ in },
            onDismiss: { dismissCount += 1 }
        )
        expectSceneRoot(CreateProjectFlow(state: blankState))
        #expect(!blankState.hasChanges)
        blankState.cancel()
        blankState.moveBack()
        blankState.saveProject()
        blankState.discard()
        blankState.showDiscardConfirmation = true
        blankState.keepEditing()
        blankState.showSaveFailure = true
        blankState.acknowledgeSaveFailure()

        let changedState = CreateProjectFlowState(
            store: store,
            onCreated: { _ in },
            onDismiss: { dismissCount += 1 },
            draft: valid
        )
        changedState.cancel()
        #expect(changedState.showDiscardConfirmation)
        changedState.installEnvironmentDismiss { dismissCount += 100 }
        changedState.discard()

        let editingProject = try #require(valid.makeProject())
        let editingState = CreateProjectFlowState(
            store: store,
            onCreated: { _ in },
            draft: ProjectDraft(project: editingProject),
            editingProject: editingProject
        )
        #expect(editingState.navigationTitle == "Edit Project")
        #expect(!editingState.hasChanges)
        editingState.draft.name = "Updated"
        #expect(editingState.hasChanges)
        #expect(store.add(editingProject))
        editingState.saveProject()
        #expect(store.project(id: editingProject.id)?.name == "Updated")

        let environmentState = CreateProjectFlowState(
            store: store,
            onCreated: { _ in },
            onDismiss: { dismissCount += 1 },
            acceptsEnvironmentDismiss: true
        )
        environmentState.installEnvironmentDismiss { dismissCount += 10 }
        environmentState.discard()
        #expect(dismissCount > 0)
        CreateProjectFlowState(store: store, onCreated: { _ in }).discard()

        let failingStore = try projectStore(beforeSave: { throw StubError.failed })
        let failingState = CreateProjectFlowState(
            store: failingStore,
            onCreated: { _ in },
            draft: valid,
            step: .review
        )
        failingState.saveProject()
        #expect(failingState.showSaveFailure)

        let identityBox = DraftBox(valid)
        let identity = CreateProjectIdentityStep(draft: identityBox.binding)
        #expect(identity.projectTypeBinding.wrappedValue == .tops)
        identity.projectTypeBinding.wrappedValue = .other
        for color in ProjectColor.allCases {
            _ = identity.projectColorButton(color)
            let button = CreateProjectColorButton(draft: identityBox.binding, color: color)
            expectFinite(button)
            _ = button.checkmark
            _ = button.selectionOutline
            button.selectColor()
        }
        for type in ProjectType.allCases {
            identityBox.value.selectType(type)
            for symbol in ProjectIcons.symbols(for: type) {
                _ = identity.projectIconButton(symbol)
                let button = CreateProjectIconButton(
                    draft: identityBox.binding,
                    symbolName: symbol
                )
                expectFinite(button)
                _ = button.isSelected
                _ = button.selectionOutline
                button.selectIcon()
            }
        }

        let constructionBox = DraftBox(valid)
        for construction in ProjectConstruction.allCases {
            let step = CreateProjectConstructionStep(draft: constructionBox.binding)
            _ = step.constructionCard(construction)
            let card = CreateProjectConstructionCard(
                draft: constructionBox.binding,
                construction: construction
            )
            _ = card.body
            card.selectConstruction()
        }
        for type in [ProjectType.footwear, .other, .headwear] {
            constructionBox.value.selectType(type)
            let step = CreateProjectConstructionStep(draft: constructionBox.binding)
            _ = step.body
            _ = step.constructionSummary
            step.keepSelection()
        }

        let gaugeBox = DraftBox(ProjectDraft())
        gaugeBox.value.gaugeValues.patternStitches = "0"
        var gauge = CreateProjectGaugeStep(draft: gaugeBox.binding)
        expectFinite(gauge)
        #expect(gauge.gaugeInputs == nil)
        #expect(gauge.stitchDelta == nil)
        #expect(gauge.rowDelta == nil)
        #expect(!gauge.gaugeValidationMessages.isEmpty)
        gauge.gaugeBinding(for: .patternStitches).wrappedValue = "20"
        gaugeBox.value = valid
        gauge = CreateProjectGaugeStep(draft: gaugeBox.binding)
        #expect(gauge.gaugeInputs != nil)
        #expect(gauge.stitchDelta != nil)
        #expect(gauge.rowDelta != nil)
        #expect(gauge.gaugeValidationMessages.isEmpty)

        let measurementsBox = DraftBox(validDraft(type: .other))
        var measurements = CreateProjectMeasurementsStep(draft: measurementsBox.binding)
        _ = measurements.measurementField(for: .customDepth)
        #expect(measurements.measurementDisplayValue(for: .rise).isEmpty)
        measurements.measurementDisplayBinding(for: .customDepth).wrappedValue = "30"
        measurementsBox.value.measurementUnit = .inches
        measurements = CreateProjectMeasurementsStep(draft: measurementsBox.binding)
        let displayedInches = try #require(
            GaugeMath.parsedNumber(measurements.measurementDisplayValue(for: .customDepth))
        )
        #expect(abs(displayedInches - (30 / 2.54)) < 0.000_000_1)
        measurements.measurementDisplayBinding(for: .customDepth).wrappedValue = "bad"
        #expect(measurements.measurementDisplayValue(for: .customDepth) == "bad")
        #expect(measurements.measurementValidationMessage(for: .customDepth).contains("leave this blank"))
        measurementsBox.value.countConstraint = .wholeNumber
        expectFinite(measurements)
        measurementsBox.value.countConstraint = .evenNumber
        expectFinite(measurements)
        measurementsBox.value.countConstraint = .patternRepeat
        #expect(measurementsBox.value.validatedCountRules == nil)
        expectFinite(measurements)
        measurementsBox.value.stitchRepeat = "6"
        measurementsBox.value.rowRepeat = "8"
        #expect(measurementsBox.value.validatedCountRules != nil)
        expectFinite(measurements)

        let notes = CreateProjectNotesStep(draft: measurementsBox.binding)
        expectFinite(notes)
        measurementsBox.value.notes = "Remember the repeat."

        var incomplete = valid
        incomplete.measurementValues = [:]
        incomplete.notes = "Remember the repeat."
        let review = CreateProjectReviewStep(draft: incomplete)
        _ = review.body
        _ = review.reviewSubtitle
        _ = review.reviewSectionTitle("Gauge")
        _ = review.reviewRow("Pattern", value: "")
        _ = review.measurementReviewRow(.yokeRaglanDepth)
        #expect(review.gaugeSummary(pattern: true).contains("20 stitches"))
        #expect(review.gaugeSummary(pattern: false).contains("22 stitches"))
        #expect(review.measurementReviewValue(for: .yokeRaglanDepth).isEmpty)
        #expect(review.countRulesSummary == "Rounded up to whole numbers")
        incomplete.countConstraint = .patternRepeat
        let invalidReview = CreateProjectReviewStep(draft: incomplete)
        #expect(invalidReview.countRulesSummary == "Pattern Repeat")
    }

    @Test func libraryActionsBindingsAndDestinationsCoverEveryBranch() throws {
        let store = try projectStore()
        let project = try #require(validDraft(type: .other).makeProject())
        #expect(store.add(project))
        let state = ProjectLibraryState(store: store)
        expectSceneRoot(ProjectLibraryView(state: state))
        var searchableDraft = validDraft(type: .tops)
        searchableDraft.name = "Cable Cardigan"
        searchableDraft.notes = "Birthday gift"
        let searchableProject = try #require(searchableDraft.makeProject())
        #expect(store.add(searchableProject))
        state.searchText = "cardigan"
        #expect(state.visibleProjects.map(\.id) == [searchableProject.id])
        state.searchText = "Tops"
        #expect(state.visibleProjects.map(\.id) == [searchableProject.id])
        state.searchText = "birthday"
        #expect(state.visibleProjects.map(\.id) == [searchableProject.id])
        state.searchText = "No matching project"
        #expect(state.visibleProjects.isEmpty)
        expectSceneRoot(ProjectLibraryView(state: state))
        expectSceneRoot(ProjectLibraryView(state: ProjectLibraryState(
            store: store,
            isSearchPresented: true
        )))
        state.searchText = "birthday"
        state.deleteVisibleProjects(at: IndexSet(integer: 0))
        #expect(store.project(id: searchableProject.id) == nil)
        #expect(store.project(id: project.id) != nil)
        state.searchText = ""
        #expect(!state.isSearchPresented)
        state.presentSearch()
        #expect(state.isSearchPresented)
        #expect(!state.isSettingsPresented)
        state.presentSettings()
        #expect(state.isSettingsPresented)
        state.dismissSettings()
        #expect(!state.isSettingsPresented)
        let settingsButton = SettingsToolbarButton(isPresented: Binding(
            get: { state.isSettingsPresented },
            set: { state.isSettingsPresented = $0 }
        ))
        settingsButton.open()
        #expect(state.isSettingsPresented)
        expectFinite(settingsButton)
        let settings = SettingsView(version: "1.0 (1)")
        expectSceneRoot(settings)
        _ = settings.destination(.pro)
        _ = settings.destination(.about)
        _ = settings.destination(.privacy)
        expectFinite(StitchwiseProView())
        expectFinite(AboutSettingsView())
        expectFinite(PrivacySettingsView())
        #expect(SettingsView.versionText(version: "1.0", build: "1") == "1.0 (1)")
        #expect(SettingsView.versionText(version: "1.0", build: nil) == "1.0")
        #expect(SettingsView.versionText(version: nil, build: "1") == "Build 1")
        #expect(SettingsView.versionText(version: nil, build: nil) == "Unavailable")
        #expect(!SettingsView.currentVersion.isEmpty)
        #expect(!state.issuePresented)
        state.issuePresented = true
        state.presentProjectCreator()
        #expect(state.isCreatingProject)
        state.projectCreated(project.id)
        state.dismissProjectCreator()
        state.openCreatedProject()
        #expect(state.navigationPath == [project.id])
        state.openCreatedProject()

        _ = ProjectLibraryView(state: state).projectDestination(project.id)
        expectSceneRoot(ProjectLibraryView(state: ProjectLibraryState(
            store: store,
            navigationPath: [UUID()]
        )))
        let creationState = ProjectLibraryState(
            store: store,
            isCreatingProject: true
        )
        expectSceneRoot(
            ProjectLibraryView(state: creationState),
            cleanup: { creationState.isCreatingProject = false }
        )

        store.issue = ProjectStoreIssue(kind: .load, message: "Load failed")
        #expect(state.issuePresented)
        let issueView = ProjectLibraryView(state: state)
        _ = issueView.storageErrorActions()
        _ = issueView.storageErrorMessage()
        state.issuePresented = false
        #expect(store.issue == nil)
        _ = issueView.storageErrorMessage()
        store.issue = ProjectStoreIssue(kind: .save, message: "Save failed")
        _ = issueView.storageErrorActions()
        _ = issueView.storageErrorMessage()
        state.dismissIssue()
        #expect(store.issue == nil)

        let results = ProjectResultsView(projectID: project.id, store: store)
        results.startEditing()
        results.projectUpdated(UUID())
        results.projectUpdated(project.id)
        results.stopEditing()
        _ = results.editSheet()
        let unavailableResults = ProjectResultsView(
            projectID: UUID(),
            store: store
        )
        _ = unavailableResults.editSheet()
        expectFinite(results)
        expectFinite(unavailableResults)

        let overview = ProjectOverviewCard(project: project)
        #expect(overview.displayValue("bad") == "bad")
        #expect(overview.gaugeBasis == "10 cm")
        #expect(overview.gaugeValue(stitches: "20", rows: "24") == "20 stitches · 24 rows")

        var inchProject = project
        inchProject.measurementUnit = .inches
        #expect(ProjectOverviewCard(project: inchProject).gaugeBasis == "4 in")
    }

    private var allMeasurementKinds: [ProjectMeasurementKind] {
        [
            .neckOpeningCircumference, .chestCircumference,
            .upperSleeveCircumference, .cuffCircumference,
            .crossBackWidth, .upperArmCircumference,
            .waistCircumference, .hipCircumference, .hemCircumference,
            .thighCircumference, .legOpeningCircumference,
            .hatCircumference, .footCircumference,
            .sockCuffCircumference, .customWidth,
            .yokeRaglanDepth, .armholeDepthSetIn, .armholeDepthDrop,
            .bodyLength, .sleeveLength, .sleeveCapDepth,
            .shoulderToCuffLength, .waistToHipDepth, .rise, .legLength,
            .crownDepth, .footLength, .sockHeight, .heelDepth, .customDepth,
        ]
    }

    private func validDraft(
        type: ProjectType,
        construction: ProjectConstruction? = nil
    ) -> ProjectDraft {
        var draft = ProjectDraft()
        draft.name = "Project"
        draft.gaugeValues = GaugeFormValues(
            patternStitches: "20",
            patternRows: "24",
            yourStitches: "22",
            yourRows: "26"
        )
        draft.selectType(type)
        if let construction {
            draft.construction = construction
        }
        for kind in draft.measurementKinds {
            draft.measurementValues[kind] = "20"
        }
        return draft
    }

    private func facetedHatDraft() -> ProjectDraft {
        var draft = validDraft(type: .headwear)
        draft.crownShape = .faceted
        draft.crownSections = 6
        return draft
    }

    private func inMemoryProjectContainer() throws -> ModelContainer {
        try ModelContainer(
            for: StoredProjectRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private func projectStore(
        beforeSave: @escaping () throws -> Void = {}
    ) throws -> ProjectStore {
        ProjectStore(
            modelContainer: try inMemoryProjectContainer(),
            beforeSave: beforeSave
        )
    }

    private func expectFinite<Content: View>(
        _ content: Content,
        width: CGFloat = 390
    ) {
        let controller = UIHostingController(
            rootView: VStack {
                content.environment(\.dynamicTypeSize, .accessibility1)
            }
        )
        controller.loadViewIfNeeded()
        let size = controller.view.sizeThatFits(
            CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        )
        controller.view.frame = CGRect(
            x: 0,
            y: 0,
            width: width,
            height: max(100, size.height)
        )
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.01))
        let viewName = String(describing: Content.self)
        #expect(size.width.isFinite && size.height.isFinite, "\(viewName): \(size)")
        #expect(size.width > 0 && size.height > 0, "\(viewName): \(size)")
        #expect(size.width <= width + 0.5, "\(viewName): \(size)")
    }

    private func expectSceneRoot<Content: View>(
        _ content: Content,
        cleanup: (() -> Void)? = nil
    ) {
        let controller = UIHostingController(rootView: content)
        controller.loadViewIfNeeded()
        controller.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        Self.sceneHost?.1.addChild(controller)
        Self.sceneHost?.1.view.addSubview(controller.view)
        controller.didMove(toParent: Self.sceneHost?.1)
        controller.view.layoutIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.01))
        #expect(controller.view.bounds.size == CGSize(width: 390, height: 844))
        if let cleanup {
            cleanup()
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.4))
        }
        controller.willMove(toParent: nil)
        controller.view.removeFromSuperview()
        controller.removeFromParent()
    }

}

@MainActor
private final class DraftBox {
    var value: ProjectDraft
    var binding: Binding<ProjectDraft> {
        Binding(get: { self.value }, set: { self.value = $0 })
    }

    init(_ value: ProjectDraft) {
        self.value = value
    }
}

private enum StubError: Error {
    case failed
}
