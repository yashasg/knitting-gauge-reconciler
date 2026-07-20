import SwiftUI
import UIKit
import XCTest
@testable import KnittingGaugeReconciler

@MainActor
final class ReplacementCoverageTests: XCTestCase {
    func testFormDraftPickerUnitValidationResetUndoAndPublicAdjustments() throws {
        var draft = GaugeFormDraft.defaults()
        draft.patternStitches = "0"
        draft.patternRows = "100"

        XCTAssertEqual(draft.rawText(for: .patternStitches), "0")
        XCTAssertEqual(draft.rawText(for: .patternRows), "100")
        XCTAssertEqual(draft.firstInvalidField, .patternStitches)
        XCTAssertEqual(
            draft.validationMessage(for: .patternStitches),
            "Pattern stitch gauge must be between 1 and 99 stitches."
        )
        XCTAssertNil(draft.inputs)

        draft.setRawText(GaugeStepperField.committedPickerText(1), for: .patternStitches)
        draft.setRawText(GaugeStepperField.committedPickerText(99), for: .patternRows)
        XCTAssertNotNil(draft.inputs)

        XCTAssertEqual(PatternInstructionsCard.title(for: .patternYoke, unit: .centimeters), "Yoke depth (cm)")
        XCTAssertEqual(PatternInstructionsCard.title(for: .patternYoke, unit: .inches), "Yoke depth (in)")
        let inches = try XCTUnwrap(MeasurementUnit.inches.displayIntToCmString(10))
        XCTAssertEqual(inches, "25.4")
        XCTAssertEqual(MeasurementUnit.inches.cmToDisplayInt(try XCTUnwrap(Double(inches))), 10)

        draft = GaugeFormDraft(
            patternStitches: "31",
            patternRows: "23",
            yourStitches: "29",
            yourRows: "21",
            patternCastOn: "141",
            patternYoke: "19",
            patternBody: "49",
            patternSleeve: "44",
            patternIncreases: "7",
            patternDetailsExpanded: true,
            unit: .centimeters
        )
        let original = draft
        let snapshot = draft.reset()
        XCTAssertEqual(snapshot, original)
        XCTAssertEqual(draft, .defaults())
        draft.undoReset(to: snapshot)
        XCTAssertEqual(draft, original)

        XCTAssertEqual(GaugeStepperField.adjustedText("32", in: 1...99, offset: 1), "33")
        XCTAssertEqual(GaugeStepperField.adjustedText("32", in: 1...99, offset: -1), "31")
        XCTAssertEqual(
            GaugeStepperField.accessibilityValue(
                text: "32",
                spokenUnit: "rows",
                mismatchLabel: "Row gauge mismatch detected",
                mismatchDelta: 8,
                validationMessage: nil
            ),
            "32 rows, row gauge mismatch detected, +8"
        )
    }

    func testAllSixJacquardScenariosAndExactSummaries() {
        let scenarios: [(String, Double, Double, Bool, Bool, String, String)] = [
            ("perfect match", 32, 24, false, false, "Stitch-wise width adjusted: 100%", "Row-wise density adjusted: 100%"),
            ("denser rows", 32, 32, false, true, "Stitch-wise width adjusted: 100%", "Row-wise density adjusted: 133%"),
            ("looser rows", 32, 20, false, true, "Stitch-wise width adjusted: 100%", "Row-wise density adjusted: 83%"),
            ("denser stitches", 36, 24, true, false, "Stitch-wise width adjusted: 89%", "Row-wise density adjusted: 100%"),
            ("looser stitches", 28, 24, true, false, "Stitch-wise width adjusted: 114%", "Row-wise density adjusted: 100%"),
            ("both denser", 36, 32, true, true, "Stitch-wise width adjusted: 89%", "Row-wise density adjusted: 133%"),
        ]

        for scenario in scenarios {
            let inputs = GaugeInputs(yourStitches: scenario.1, yourRows: scenario.2)
            let semantics = GaugeResultSemantics(inputs: inputs, result: GaugeMath.compute(inputs))
            XCTAssertEqual(semantics.stitchMismatch, scenario.3, scenario.0)
            XCTAssertEqual(semantics.rowMismatch, scenario.4, scenario.0)
            XCTAssertEqual(semantics.stitchSummary, scenario.5, scenario.0)
            XCTAssertEqual(semantics.rowSummary, scenario.6, scenario.0)
        }
    }

    func testOptionalResultSectionMatrix() {
        let scenarios: [(GaugeInputs, [GaugeResultSectionKind])] = [
            (GaugeInputs(yourRows: 24), []),
            (GaugeInputs(yourRows: 24, patternCastOn: 128), [.castOn]),
            (GaugeInputs(yourRows: 24, patternYokeDepth: 20), [.yokeDepth]),
            (GaugeInputs(yourRows: 24, patternIncreaseSpacing: 6), [.shapingRates]),
            (
                GaugeInputs(
                    yourRows: 24,
                    patternYokeDepth: 20,
                    patternBodyLength: 50,
                    patternSleeveLength: 45,
                    patternIncreaseSpacing: 6,
                    patternCastOn: 128
                ),
                [.yokeDepth, .bodyAndSleeves, .shapingRates, .castOn]
            ),
        ]

        for (inputs, expected) in scenarios {
            XCTAssertEqual(
                GaugeResultSemantics(inputs: inputs, result: GaugeMath.compute(inputs)).sections,
                expected
            )
        }
    }

    func testHostedAboutOpenExactCopyAndCloseAction() throws {
        try requireHostedAccessibility()
        let state = HelpState()
        let buttonProbe = HostedProbe(AboutHelpToolbarButton(showAboutHelp: state.binding))
        guard !buttonProbe.entries.isEmpty else {
            throw XCTSkip("SwiftUI public accessibility containers are unavailable on this simulator runtime")
        }
        let open = try buttonProbe.entry(identifier: "about-help-button")
        XCTAssertEqual(open.object.accessibilityLabel, "About this calculator")
        XCTAssertTrue(open.object.accessibilityTraits.contains(.button))
        XCTAssertFalse(buttonProbe.frame(for: open).isEmpty)
        XCTAssertTrue(open.object.accessibilityActivate())
        XCTAssertTrue(state.isPresented)

        let probe = HostedProbe(AboutHelpContent(), width: 390, height: 1_200)
        let exactCopy = [
            ("About this calculator", UIAccessibilityTraits.header),
            (
                "This tool reconciles a two-axis gauge mismatch, the kind that single-number " +
                "gauge calculators hide. When row gauge differs, it adjusts each supplied depth or length while " +
                "preserving the pattern's intended row count. Stitch-gauge differences are handled separately for width.",
                UIAccessibilityTraits.staticText
            ),
            (
                "The math is deterministic: dimension correction = pattern_row / your_row. A denser swatch " +
                "means fewer centimetres are needed to reach the pattern's intended row count; stitch_scale = " +
                "pattern_st / your_st describes horizontal width. Increase-row spacing is rescaled by your_row / " +
                "pattern_row so the physical gap between increases stays correct.",
                UIAccessibilityTraits.staticText
            ),
            (
                "Scope: This tool provides estimates based on your swatch measurements. Always test a " +
                "full-size gauge swatch (washed and blocked the way you'll wash and block the finished garment) " +
                "before starting your project. Numbers here are a starting point — your finished piece is the final word.",
                UIAccessibilityTraits.staticText
            ),
            (
                "Not affiliated with Ravelry, Knit Companion, or any pattern designer. Gauge math is " +
                    "conventional knitting arithmetic from open craft literature.",
                UIAccessibilityTraits.staticText
            ),
            ("Privacy", UIAccessibilityTraits.header),
            (
                "Your gauge values stay on this device. No account, ads, or third-party tracking. The app " +
                "includes no analytics SDK and makes no app-initiated network requests. Apple may receive crash and " +
                "performance diagnostics according to your device settings.",
                UIAccessibilityTraits.staticText
            ),
        ]
        let expectedLabels = exactCopy.map(\.0)
        XCTAssertEqual(probe.labels.filter(expectedLabels.contains), expectedLabels, "\(probe.labels)")
        for (label, trait) in exactCopy {
            let entry = try probe.entry(label: label)
            XCTAssertTrue(entry.object.accessibilityTraits.contains(trait))
            XCTAssertFalse(probe.frame(for: entry).isEmpty)
            XCTAssertTrue(probe.contains(entry))
            XCTAssertFalse(entry.object.accessibilityElementsHidden)
        }

        let sheetProbe = HostedProbe(AboutHelpSheet { state.isPresented = false }, width: 390, height: 1_300)
        XCTAssertEqual(sheetProbe.identifiers.filter { $0 == "about-help-close" }, ["about-help-close"])
        let close = try sheetProbe.entry(identifier: "about-help-close")
        XCTAssertEqual(close.object.accessibilityLabel, "Close")
        XCTAssertTrue(close.object.accessibilityTraits.contains(.button))
        XCTAssertEqual(HelpSheetHeader.hitTargetSize, 44)
        XCTAssertGreaterThanOrEqual(sheetProbe.frame(for: close).width, 44)
        XCTAssertGreaterThanOrEqual(sheetProbe.frame(for: close).height, 44)
        XCTAssertNotNil(sheetProbe.hitTarget(for: close))
        XCTAssertTrue(close.object.accessibilityActivate())
        XCTAssertFalse(state.isPresented)
    }

    func testHostedRequiredOnlyResultsShareAndSemantics() throws {
        try requireHostedAccessibility()
        let inputs = GaugeInputs(patternRows: 24, yourRows: 32)
        let result = GaugeMath.compute(inputs)
        let counter = ShareCounter()
        let probe = HostedProbe(
            RequiredAdjustmentsCard(
                result: result,
                inputs: inputs,
                verdict: (title: "Significant drift", body: "Row guidance."),
                unit: .centimeters,
                showFullMath: .constant(false),
                canUndoReset: false,
                onReset: {},
                onUndoReset: {},
                onShare: { _ in
                    counter.count += 1
                    return ["Gauge result"]
                }
            ),
            width: 390,
            height: 1_100
        )

        guard !probe.entries.isEmpty else {
            throw XCTSkip("SwiftUI public accessibility containers are unavailable on this simulator runtime")
        }
        let shareEntries = probe.entries.filter { $0.object.accessibilityLabel == "Share results" }
        XCTAssertEqual(shareEntries.count, 1)
        let share = try XCTUnwrap(shareEntries.first)
        XCTAssertEqual(share.identifier, "share-results")
        XCTAssertTrue(share.object.accessibilityTraits.contains(.button))
        XCTAssertFalse(probe.frame(for: share).isEmpty)
        XCTAssertNotNil(probe.hitTarget(for: share))
        XCTAssertTrue(share.object.accessibilityActivate())
        waitUntil { counter.count == 1 }
        XCTAssertEqual(counter.count, 1)

        XCTAssertFalse(probe.labels.contains(where: {
            $0.hasPrefix("Copy") || ["TSV", "Markdown", "CSV", "HTML", "Export"].contains($0)
        }))
        let stitch = try probe.entry(label: "Stitch-wise width adjusted: 100%")
        let row = try probe.entry(label: "Row-wise density adjusted: 133%")
        XCTAssertFalse(probe.frame(for: stitch).isEmpty)
        XCTAssertFalse(probe.frame(for: row).isEmpty)
        for section in GaugeResultSectionKind.allCases {
            XCTAssertFalse(probe.labels.contains(section.rawValue))
        }
    }

    func testAccessibilityXXXLUsesOrderedVerticalReflow() throws {
        try requireHostedAccessibility()
        let inputs = GaugeInputs(patternRows: 24, yourRows: 32)
        let result = GaugeMath.compute(inputs)
        let probe = HostedProbe(
            HeroTilesView(
                result: result,
                semantics: GaugeResultSemantics(inputs: inputs, result: result)
            )
                .environment(\.dynamicTypeSize, .accessibility3),
            width: 390,
            height: 800
        )
        let labels = [
            "Stitch-wise width adjusted: 100%",
            "Row-wise density adjusted: 133%",
        ]
        guard !probe.entries.isEmpty else {
            throw XCTSkip("SwiftUI public accessibility containers are unavailable on this simulator runtime")
        }
        let entries = probe.entries.filter { labels.contains($0.object.accessibilityLabel ?? "") }
        XCTAssertEqual(entries.map(\.object.accessibilityLabel), labels.map(Optional.some), "\(probe.labels)")
        guard entries.count == labels.count else { return }
        for entry in entries {
            XCTAssertFalse(probe.frame(for: entry).isEmpty)
            XCTAssertTrue(probe.contains(entry))
        }
        XCTAssertGreaterThanOrEqual(probe.frame(for: entries[1]).minY, probe.frame(for: entries[0]).maxY)
        XCTAssertFalse(probe.frame(for: entries[0]).intersects(probe.frame(for: entries[1])))
        XCTAssertTrue(gaugeMeasurementPairsStack(at: .accessibility3))
        XCTAssertFalse(gaugeMeasurementPairsStack(at: .large))
    }

    func testHostedLeadAndCollapsedExpandedFormSemantics() throws {
        try requireHostedAccessibility()
        let leadProbe = HostedProbe(GaugeLeadView(), width: 390)
        guard !leadProbe.entries.isEmpty else {
            throw XCTSkip("SwiftUI public accessibility containers are unavailable on this simulator runtime")
        }
        let lead = try leadProbe.entry(label: GaugeLeadView.text)
        XCTAssertEqual(lead.object.accessibilityLabel, GaugeLeadView.text)
        XCTAssertTrue(lead.object.accessibilityTraits.contains(.staticText))
        XCTAssertFalse(lead.object.accessibilityElementsHidden)
        XCTAssertFalse(leadProbe.frame(for: lead).isEmpty)
        XCTAssertTrue(leadProbe.contains(lead))

        let collapsed = HostedProbe(PatternInstructionsLabel(isExpanded: false), width: 390)
        let disclosure = try collapsed.entry(identifier: "pattern-details-disclosure")
        XCTAssertEqual(disclosure.object.accessibilityLabel, "Pattern details (optional)")
        XCTAssertEqual(disclosure.object.accessibilityValue, "Collapsed")
        XCTAssertTrue(disclosure.object.accessibilityTraits.contains(.button))
        XCTAssertFalse(collapsed.frame(for: disclosure).isEmpty)

        let expanded = HostedProbe(PatternInstructionsLabel(isExpanded: true), width: 390)
        let expandedDisclosure = try expanded.entry(identifier: "pattern-details-disclosure")
        XCTAssertEqual(expandedDisclosure.object.accessibilityValue, "Expanded")
        XCTAssertFalse(expanded.frame(for: expandedDisclosure).isEmpty)
        XCTAssertEqual(PatternInstructionsCard.title(for: .patternCastOn, unit: .centimeters), "Cast-on stitches")
        XCTAssertEqual(PatternInstructionsCard.title(for: .patternYoke, unit: .centimeters), "Yoke depth (cm)")
    }

    func testAdaptiveContrastTokensRenderAndNoVerdictHelpTrigger() throws {
        for style in [UIUserInterfaceStyle.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: style)
            XCTAssertGreaterThanOrEqual(
                contrast(themeColor("app-theme-ink", traits), themeColor("app-theme-background", traits)),
                4.5
            )
            XCTAssertGreaterThanOrEqual(
                contrast(
                    themeColor("app-theme-warning-text", traits),
                    themeColor("app-theme-warning-background", traits)
                ),
                4.5
            )
            XCTAssertGreaterThanOrEqual(
                contrast(themeColor("app-theme-muted", traits), themeColor("app-theme-card", traits)),
                4.5
            )
        }

        let size = CGSize(width: 390, height: 100)
        let rendered = UIHostingController(rootView: GaugeLeadView().frame(width: size.width, height: size.height))
        rendered.view.frame = CGRect(origin: .zero, size: size)
        rendered.view.layoutIfNeeded()
        let context = try XCTUnwrap(
            CGContext(
                data: nil,
                width: Int(size.width),
                height: Int(size.height),
                bitsPerComponent: 8,
                bytesPerRow: Int(size.width) * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        )
        rendered.view.layer.render(in: context)
        XCTAssertNotNil(context.makeImage())

        let inputs = GaugeInputs(yourRows: 24)
        XCTAssertEqual(
            GaugeResultSemantics(inputs: inputs, result: GaugeMath.compute(inputs)).sections,
            []
        )
    }

    private func requireHostedAccessibility() throws {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        guard version.majorVersion > 26 || (version.majorVersion == 26 && version.minorVersion >= 5) else {
            throw XCTSkip("Public SwiftUI accessibility containers require iOS 26.5 or newer")
        }
    }

    private func waitUntil(
        timeout: TimeInterval = 2,
        condition: () -> Bool
    ) {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition(), RunLoop.main.run(mode: .default, before: Date().addingTimeInterval(0.01)), Date() < deadline {}
        XCTAssertTrue(condition())
    }

    private func contrast(_ foreground: UIColor, _ background: UIColor) -> Double {
        func luminance(_ color: UIColor) -> Double {
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            XCTAssertTrue(color.getRed(&red, green: &green, blue: &blue, alpha: &alpha))
            func linear(_ value: CGFloat) -> Double {
                value <= 0.04045
                    ? Double(value / 12.92)
                    : pow(Double((value + 0.055) / 1.055), 2.4)
            }
            return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
        }
        let values = [luminance(foreground), luminance(background)]
        return (values.max()! + 0.05) / (values.min()! + 0.05)
    }

    private func themeColor(_ name: String, _ traits: UITraitCollection) -> UIColor {
        guard let color = UIColor(
            named: name,
            in: Bundle(for: MetricsSubscriber.self),
            compatibleWith: traits
        ) else {
            XCTFail("Missing app-owned color token \(name)")
            return .clear
        }
        return color.resolvedColor(with: traits)
    }
}

@MainActor
private final class HostedProbe {
    @MainActor
    struct Entry {
        let object: NSObject
        let parent: NSObject
        let index: Int

        var identifier: String? {
            if let identified = object as? UIAccessibilityIdentification {
                return identified.accessibilityIdentifier
            }
            let selector = #selector(getter: UIAccessibilityIdentification.accessibilityIdentifier)
            guard object.responds(to: selector) else { return nil }
            return object.perform(selector)?.takeUnretainedValue() as? String
        }
    }

    private let window: UIWindow
    private let controller: UIViewController

    init<Content: View>(
        _ content: Content,
        width: CGFloat = 390,
        height: CGFloat? = nil
    ) {
        let hosting = UIHostingController(rootView: content)
        controller = hosting
        let fitted = hosting.sizeThatFits(in: CGSize(width: width, height: 4_000))
        let resolvedHeight = height ?? max(100, fitted.height)
        let frame = CGRect(x: 0, y: 0, width: width, height: resolvedHeight)
        if let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first,
           let existingWindow = scene.windows.first(where: \.isKeyWindow) ?? scene.windows.first {
            window = existingWindow
            window.frame = frame
        } else {
            window = UIWindow(frame: frame)
        }
        window.rootViewController = hosting
        hosting.view.frame = window.bounds
        window.makeKeyAndVisible()
        hosting.view.setNeedsLayout()
        hosting.view.layoutIfNeeded()
        window.setNeedsLayout()
        window.layoutIfNeeded()
        UIAccessibility.post(notification: .screenChanged, argument: hosting.view)
        RunLoop.main.run(until: Date().addingTimeInterval(0.5))
    }

    var entries: [Entry] {
        let viewEntries = collect(from: controller.view)
        return viewEntries.isEmpty ? collect(from: window) : viewEntries
    }

    var identifiers: [String] {
        entries.compactMap(\.identifier)
    }

    var refreshedIdentifiers: [String] {
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        return identifiers
    }

    var labels: [String] {
        entries.compactMap(\.object.accessibilityLabel)
    }

    var refreshedLabels: [String] {
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        return labels
    }

    func frame(for entry: Entry) -> CGRect {
        entry.object.accessibilityFrame
    }

    func contains(_ entry: Entry) -> Bool {
        window.convert(window.bounds, to: nil).contains(frame(for: entry))
    }

    func entry(identifier: String) throws -> Entry {
        try XCTUnwrap(entries.first(where: { $0.identifier == identifier }), identifier)
    }

    func entry(label: String, traits: UIAccessibilityTraits = []) throws -> Entry {
        try XCTUnwrap(
            entries.first(where: {
                $0.object.accessibilityLabel == label && $0.object.accessibilityTraits.contains(traits)
            }),
            "\(label); labels=\(labels)"
        )
    }

    func hitTarget(for entry: Entry) -> UIView? {
        window.hitTest(window.convert(frame(for: entry).center, from: nil), with: nil)
    }

    private func collect(from root: NSObject) -> [Entry] {
        var result: [Entry] = []
        var visited = Set<ObjectIdentifier>()

        func visit(_ container: NSObject) {
            guard visited.insert(ObjectIdentifier(container)).inserted else { return }
            let children: [Any]
            if let explicit = container.accessibilityElements, !explicit.isEmpty {
                children = explicit
            } else if container.responds(to: NSSelectorFromString("accessibilityElementsBlock")),
                      let generated = container.accessibilityElementsBlock?(),
                      !generated.isEmpty {
                children = generated
            } else {
                let count = container.accessibilityElementCount()
                guard count > 0, count < 4_096 else { return }
                children = (0..<count).compactMap { container.accessibilityElement(at: $0) }
            }

            for (index, child) in children.enumerated() {
                guard let object = child as? NSObject else { continue }
                if object.isAccessibilityElement {
                    result.append(Entry(object: object, parent: container, index: index))
                }
                visit(object)
            }
        }

        visit(root)
        return result
    }
}

@MainActor
private final class HelpState {
    var isPresented = false

    var binding: Binding<Bool> {
        Binding(get: { self.isPresented }, set: { self.isPresented = $0 })
    }
}

@MainActor
private final class ShareCounter {
    var count = 0
}

private extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}
