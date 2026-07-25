import Foundation
import ImageIO
import Testing

@Suite("Regression guardrails")
struct RegressionGuardrailTests {
    @Test func appIconReferencesExistAndMatchDeclaredPixelDimensions() throws {
        let iconDirectory = appDirectory
            .appendingPathComponent("KnittingGaugeReconciler/Assets.xcassets/AppIcon.appiconset")
        let contentsURL = iconDirectory.appendingPathComponent("Contents.json")
        let contents = try JSONDecoder().decode(
            AppIconContents.self,
            from: Data(contentsOf: contentsURL)
        )
        var referencedImageCount = 0

        for image in contents.images {
            guard let filename = image.filename else { continue }
            referencedImageCount += 1
            let imageURL = iconDirectory.appendingPathComponent(filename)
            #expect(
                FileManager.default.fileExists(atPath: imageURL.path),
                "AppIcon Contents.json references missing file \(filename)"
            )
            guard FileManager.default.fileExists(atPath: imageURL.path) else { continue }

            let expected = try image.expectedPixelDimensions()
            let source = try #require(CGImageSourceCreateWithURL(imageURL as CFURL, nil))
            let properties = try #require(
                CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
            )
            let width = try #require(properties[kCGImagePropertyPixelWidth] as? NSNumber)
            let height = try #require(properties[kCGImagePropertyPixelHeight] as? NSNumber)

            #expect(
                width.intValue == expected.width,
                "\(filename) width is \(width), expected \(expected.width)"
            )
            #expect(
                height.intValue == expected.height,
                "\(filename) height is \(height), expected \(expected.height)"
            )
        }

        #expect(referencedImageCount > 0)
    }

    @Test(
        "Production Swift excludes retired defect patterns",
        arguments: forbiddenProductionContracts
    )
    func productionSwiftExcludes(_ contract: SourceContract) throws {
        let sources = try productionSwiftSources()
        #expect(!sources.isEmpty)

        for source in sources {
            #expect(
                source.contents.range(
                    of: contract.pattern,
                    options: [.regularExpression, .caseInsensitive]
                ) == nil,
                "\(source.name) contains retired \(contract.name) plumbing"
            )
        }
    }

    @Test("SceneStorage keys remain migration-stable", arguments: sceneStorageKeys)
    func sceneStorageKeyRemainsStable(_ key: SceneStorageKey) throws {
        let source = try String(
            contentsOf: appDirectory
                .appendingPathComponent("KnittingGaugeReconciler/ContentViewHelpers.swift"),
            encoding: .utf8
        )
        let property = NSRegularExpression.escapedPattern(for: key.property)
        let literal = NSRegularExpression.escapedPattern(for: key.literal)
        let pattern = #"static\s+let\s+\#(property)\s*=\s*"\#(literal)""#
        let expression = try NSRegularExpression(pattern: pattern)
        let range = NSRange(source.startIndex..<source.endIndex, in: source)

        #expect(
            expression.numberOfMatches(in: source, range: range) == 1,
            "\(key.property) must remain \(key.literal) to preserve restored scenes"
        )
    }

    @Test("Shared layout regressions remain covered", arguments: sharedLayoutGuards)
    func sharedLayoutRegressionRemainsPresent(_ guardrail: SourceContract) throws {
        let source = try String(
            contentsOf: appDirectory
                .appendingPathComponent(
                    "KnittingGaugeReconcilerTests/DeterministicUIContractsTests.swift"
                ),
            encoding: .utf8
        )

        #expect(
            source.range(of: guardrail.pattern, options: .regularExpression) != nil,
            "Shared regression coverage is missing \(guardrail.name)"
        )
    }

    @Test func navigationControlsKeepHIGRolesSymbolsAndShapes() throws {
        let createFlow = try productionSource(
            "Views/CreateProjectFlow.swift"
        )
        #expect(createFlow.contains("ToolbarItem(placement: .cancellationAction"))
        #expect(createFlow.contains(#"Button("Close", systemImage: "xmark""#))
        #expect(
            createFlow.components(
                separatedBy: ".buttonBorderShape(.roundedRectangle(radius: Radius.small))"
            ).count == 3
        )
        #expect(createFlow.contains(#"step == .review ? "checkmark" : "chevron.forward""#))

        let settings = try productionSource("Views/HomeHeaderView.swift")
        #expect(settings.contains("ToolbarItem(placement: .confirmationAction)"))
        #expect(settings.contains(#"systemImage: "checkmark""#))

        let library = try productionSource("Views/ProjectLibraryView.swift")
        #expect(library.contains(#"systemImage: "square.and.pencil""#))
        #expect(library.contains(".tint(AppTheme.sage)"))

        let content = try productionSource("ContentView.swift")
        #expect(content.contains(#"Button(AboutHelpContract.closeLabel, systemImage: "xmark""#))
        #expect(content.contains(".buttonBorderShape(.circle)"))
        #expect(content.contains("minWidth: AboutHelpContract.closeHitTarget"))
        #expect(content.contains("minHeight: AboutHelpContract.closeHitTarget"))
    }

    @Test func projectTypePickerReflowsWithoutWrappingLabels() throws {
        let createFlow = try productionSource("Views/CreateProjectFlow.swift")
        let start = try #require(
            createFlow.range(of: "private var projectTypePicker: some View")?.lowerBound
        )
        let end = try #require(
            createFlow.range(
                of: "private var projectColorPicker: some View",
                range: start..<createFlow.endIndex
            )?.lowerBound
        )
        let picker = createFlow[start..<end]

        #expect(picker.contains("ViewThatFits(in: .horizontal)"))
        #expect(picker.contains("VStack(alignment: .leading"))
        #expect(
            picker.components(
                separatedBy: ".fixedSize(horizontal: true, vertical: false)"
            ).count == 3
        )
    }

    private var appDirectory: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private func productionSource(_ relativePath: String) throws -> String {
        try String(
            contentsOf: appDirectory
                .appendingPathComponent("KnittingGaugeReconciler")
                .appendingPathComponent(relativePath),
            encoding: .utf8
        )
    }

    private func productionSwiftSources() throws -> [SourceFile] {
        let directory = appDirectory.appendingPathComponent("KnittingGaugeReconciler")
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) else {
            throw GuardrailError.cannotEnumerate(directory.path)
        }

        var sources: [SourceFile] = []
        for case let fileURL as URL in enumerator where fileURL.pathExtension == "swift" {
            sources.append(
                SourceFile(
                    name: fileURL.lastPathComponent,
                    contents: try String(contentsOf: fileURL, encoding: .utf8)
                )
            )
        }
        return sources.sorted { $0.name < $1.name }
    }
}

private struct AppIconContents: Decodable {
    let images: [AppIconImage]
}

private struct AppIconImage: Decodable {
    let filename: String?
    let scale: String
    let size: String

    func expectedPixelDimensions() throws -> (width: Int, height: Int) {
        let dimensions = size.split(separator: "x", omittingEmptySubsequences: false)
        guard dimensions.count == 2,
              let width = Double(dimensions[0]),
              let height = Double(dimensions[1]),
              scale.hasSuffix("x"),
              let multiplier = Double(scale.dropLast()) else {
            throw GuardrailError.invalidAppIconDeclaration(size: size, scale: scale)
        }
        let pixelWidth = width * multiplier
        let pixelHeight = height * multiplier
        guard pixelWidth.rounded() == pixelWidth,
              pixelHeight.rounded() == pixelHeight else {
            throw GuardrailError.invalidAppIconDeclaration(size: size, scale: scale)
        }
        return (width: Int(pixelWidth), height: Int(pixelHeight))
    }
}

private struct SourceFile {
    let name: String
    let contents: String
}

struct SourceContract: Sendable, CustomTestStringConvertible {
    let name: String
    let pattern: String

    var testDescription: String { name }
}

struct SceneStorageKey: Sendable, CustomTestStringConvertible {
    let property: String
    let literal: String

    var testDescription: String { property }
}

private enum GuardrailError: Error {
    case cannotEnumerate(String)
    case invalidAppIconDeclaration(size: String, scale: String)
}

private let forbiddenProductionContracts = [
    SourceContract(
        name: "persistent ShareExports or file-URL sharing",
        pattern: #"\bShareExports?\b|\b(?:share|export)\w*(?:file)?URL\b|\bfileURL\b|\bURL\s*\(\s*(?:fileURLWithPath|filePath)\s*:|\bFileManager\s*\.\s*default\s*\.\s*(?:temporaryDirectory|urls\s*\()"#
    ),
    SourceContract(
        name: "synchronous UserDefaults persistence",
        pattern: #"UserDefaults\s*\.\s*standard\s*\.\s*synchronize\s*\("#
    ),
    SourceContract(
        name: "dead onSubmit",
        pattern: #"\bonSubmit\b"#
    ),
    SourceContract(
        name: "positional numeric draft indexing",
        pattern: #"\b(?:\w*Draft\w*|formValues|fieldValues|rawValues|values)\s*\[\s*\d+\s*\]"#
    ),
    SourceContract(
        name: "unbranded semantic SwiftUI fonts",
        pattern: #"\.font\s*\(\s*\.(?:largeTitle|title[23]?|headline|body|callout|subheadline|footnote|caption2?)\b"#
    ),
    SourceContract(
        name: "unscaled UIKit preferred fonts",
        pattern: #"UIFont\s*\.\s*preferredFont\s*\("#
    ),
    SourceContract(
        name: "raw spacing and padding literals",
        pattern: #"\bpadding\(\s*(?:\.[A-Za-z]+,\s*)?[1-9][0-9]*\b|(?:VStack|HStack|LazyVStack|LazyHStack)\([^)]*spacing:\s*[1-9][0-9]*|Spacer\(minLength:\s*[1-9][0-9]*"#
    ),
    SourceContract(
        name: "raw corner radii",
        pattern: #"cornerRadius:\s*[1-9][0-9]*\b"#
    ),
    SourceContract(
        name: "raw fixed frame dimensions",
        pattern: #"\.frame\([^)]*(?:width|height|minWidth|minHeight|maxWidth|maxHeight):\s*[1-9][0-9]*\b"#
    ),
]

private let sceneStorageKeys = [
    SceneStorageKey(property: "patternStitchesKey", literal: "gauge.pattern-stitches"),
    SceneStorageKey(property: "patternRowsKey", literal: "gauge.pattern-rows"),
    SceneStorageKey(property: "yourStitchesKey", literal: "gauge.your-stitches"),
    SceneStorageKey(property: "yourRowsKey", literal: "gauge.your-rows"),
    SceneStorageKey(property: "patternCastOnKey", literal: "gauge.pattern-cast-on"),
    SceneStorageKey(property: "patternYokeKey", literal: "gauge.pattern-yoke"),
    SceneStorageKey(property: "patternBodyKey", literal: "gauge.pattern-body"),
    SceneStorageKey(property: "patternSleeveKey", literal: "gauge.pattern-sleeve"),
    SceneStorageKey(property: "patternIncreasesKey", literal: "gauge.pattern-increases"),
    SceneStorageKey(property: "disclosureKey", literal: "gauge.pattern-details-expanded"),
]

private let sharedLayoutGuards = [
    SourceContract(
        name: "validation-height stability",
        pattern: #"(?s)func\s+requiredValidationReservesStableInputHeight\(\).*?abs\(pristine\.size\.height\s*-\s*revealed\.size\.height\)\s*<=\s*0\.5"#
    ),
    SourceContract(
        name: "the 320/390/760 width matrix",
        pattern: #"(?s)func\s+adaptiveLayoutsHaveFiniteNaturalSizesAcrossWidthsAndTextSizes\(\).*?let\s+widths:\s*\[CGFloat\]\s*=\s*\[\s*320,\s*390,\s*760\s*\]"#
    ),
    SourceContract(
        name: "consecutive drift rows",
        pattern: #"(?s)func\s+adaptiveLayoutsHaveFiniteNaturalSizesAcrossWidthsAndTextSizes\(\).*?"Consecutive drift AdjustmentRows".*?AdjustmentRow\(.*?AdjustmentRow\("#
    ),
    SourceContract(
        name: "reset and undo behavior",
        pattern: #"(?s)func\s+resetUndoActionsRemainWiredAndMeetTouchTargetContract\(\).*?resetToDefaults\(\).*?undoReset\(\)"#
    ),
]
