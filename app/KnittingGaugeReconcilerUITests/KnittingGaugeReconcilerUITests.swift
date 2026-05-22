import UIKit
import XCTest

@MainActor
final class KnittingGaugeReconcilerUITests: XCTestCase {
    private struct Scenario {
        var name: String
        var yourStitches: String
        var yourRows: String
        /// String label of the adjusted yoke row count (e.g. "64" — shown in the
        /// dark-green "You Must Knit" block of AdjustmentValuePair).
        var castOn: String
        var body: String
        var yoke: String
        var increases: String
    }

    private static let defaultLaunchEnvironment: [String: String] = [
        "KGR_PS": "32",
        "KGR_PR": "24",
        "KGR_CAST_ON": "128",
        "KGR_YOKE": "20",
        "KGR_BODY": "50",
        "KGR_SLEEVE": "45",
        "KGR_INCREASES": "6",
    ]

    // yokeRowsAtYourGauge = (20/10)*yr, bodyRowsAtYourGauge = (50/10)*yr
    private let scenarios = [
        Scenario(name: "Perfect Match",    yourStitches: "32", yourRows: "24", castOn: "128 stitches", body: "120", yoke: "48",  increases: "Space every 6 rows/rounds"),
        Scenario(name: "Denser Row Only",  yourStitches: "32", yourRows: "32", castOn: "128 stitches", body: "160", yoke: "64",  increases: "Space every 8 rows/rounds"),
        Scenario(name: "Looser Row Only",  yourStitches: "32", yourRows: "20", castOn: "128 stitches", body: "100", yoke: "40",  increases: "Space every 5 rows/rounds"),
        Scenario(name: "Denser Stitch Only", yourStitches: "36", yourRows: "24", castOn: "144 stitches", body: "120", yoke: "48", increases: "Space every 6 rows/rounds"),
        Scenario(name: "Looser Stitch Only", yourStitches: "28", yourRows: "24", castOn: "112 stitches", body: "120", yoke: "48", increases: "Space every 6 rows/rounds"),
        Scenario(name: "Both Denser",      yourStitches: "36", yourRows: "32", castOn: "144 stitches", body: "160", yoke: "64",  increases: "Space every 8 rows/rounds")
    ]

    func testAllJacquardScenariosAreVisibleInUI() {
        for scenario in scenarios {
            let app = XCUIApplication()
            useDefaultDynamicType(app)
            app.launchEnvironment = Self.defaultLaunchEnvironment.merging([
                "KGR_YS": scenario.yourStitches,
                "KGR_YR": scenario.yourRows,
            ]) { _, new in new }
            app.launch()

            XCTAssertTrue(app.textFields["your-stitches-field"].waitForExistence(timeout: 5))
            XCTAssertTrue(app.textFields["your-rows-field"].waitForExistence(timeout: 5))

            let calculateBtn = app.buttons["calculate-button"]
            XCTAssertTrue(calculateBtn.waitForExistence(timeout: 3))
            scrollToElement(calculateBtn, in: app, requireHittable: true)
            tapElement(calculateBtn)

            let closeButton = app.buttons["Close"].firstMatch
            XCTAssertTrue(closeButton.waitForExistence(timeout: 3), scenario.name)

            let castOnElement = app.otherElements["cast-on-result"]
            scrollToElement(castOnElement, in: app)
            XCTAssertTrue(castOnElement.waitForExistence(timeout: 5), scenario.name)

            let expectedCastOnLabel = "Cast-on stitches adjusted: Cast on \(scenario.castOn)"
            waitUntil(timeout: 5) { castOnElement.label == expectedCastOnLabel }
            XCTAssertEqual(castOnElement.label, expectedCastOnLabel, scenario.name)

            let bodyValue = app.otherElements["body-your-rows"]
            scrollToElement(bodyValue, in: app)
            XCTAssertTrue(bodyValue.exists, "\(scenario.name) body=\(scenario.body)")
            XCTAssertTrue(
                bodyValue.label.contains(scenario.body),
                "\(scenario.name) body=\(scenario.body) label=\(bodyValue.label)"
            )
            let yokeValue = app.otherElements["yoke-your-rows"]
            scrollToElement(yokeValue, in: app)
            XCTAssertTrue(yokeValue.exists, "\(scenario.name) yoke=\(scenario.yoke)")
            XCTAssertTrue(
                yokeValue.label.contains(scenario.yoke),
                "\(scenario.name) yoke=\(scenario.yoke) label=\(yokeValue.label)"
            )
            let increasesValue = app.otherElements["increases-result"]
            XCTAssertTrue(
                increasesValue.exists,
                "\(scenario.name) increases=\(scenario.increases)"
            )
            XCTAssertTrue(
                increasesValue.label.contains(scenario.increases),
                "\(scenario.name) increases=\(scenario.increases) label=\(increasesValue.label)"
            )
            app.terminate()
        }
    }

    func testStepperFieldOpensWheelAndKeyboard() {
        // The user-facing stepper has two affordances:
        //   1) Tap the value/text area → numeric keyboard opens (direct entry).
        //   2) Tap the chevron (⇅) → wheel picker sheet opens.
        // The wheel sheet's Done button commits the picked value back to the
        // field. This test exercises both paths. The legacy 8pt-tall ± button
        // strip has been removed; the previous off-by-one assertions were
        // testing a UI-test scaffold, not a user-facing affordance.
        let app = XCUIApplication()
        useDefaultDynamicType(app)
        app.launchEnvironment = Self.defaultLaunchEnvironment.merging([
            "KGR_YS": "20",
            "KGR_YR": "24",
        ]) { _, new in new }
        app.launch()

        let valueField = app.textFields["your-stitches-field"].firstMatch
        XCTAssertTrue(valueField.waitForExistence(timeout: 3))
        XCTAssertEqual(numericFieldValue(valueField), 20, "Field should reflect launch env KGR_YS=20")

        // Tapping the value field opens the keyboard.
        scrollToElement(valueField, in: app, requireHittable: true)
        tapElement(valueField)
        XCTAssertTrue(
            app.keyboards.firstMatch.waitForExistence(timeout: 3),
            "Tapping the value field should open the keyboard"
        )
        dismissKeyboard(in: app)

        // Tapping the chevron opens the wheel picker sheet; Done commits.
        let chevron = app.buttons["your-stitches-chevron"].firstMatch
        XCTAssertTrue(chevron.waitForExistence(timeout: 3))
        scrollToElement(chevron, in: app, requireHittable: true)
        tapElement(chevron)

        let wheelDone = app.buttons["your-stitches-wheel-done"].firstMatch
        XCTAssertTrue(wheelDone.waitForExistence(timeout: 3), "Wheel picker sheet should open")
        tapElement(wheelDone)

        waitUntil(timeout: 2) { self.numericFieldValue(valueField) != nil }
        XCTAssertNotNil(numericFieldValue(valueField), "Field should expose a numeric value after wheel commit")
    }

    func testPrototypeParityControlsAreAvailable() {
        let app = XCUIApplication()
        useDefaultDynamicType(app)
        app.launchEnvironment = Self.defaultLaunchEnvironment.merging([
            "KGR_YS": "32",
            "KGR_YR": "24",
            "KGR_SHOW_FULL_MATH": "1",
        ]) { _, new in new }
        app.launch()

        // Tap Calculate to surface the adjustments section.
        let calculateBtn = app.buttons["calculate-button"]
        XCTAssertTrue(calculateBtn.waitForExistence(timeout: 3))
        scrollToElement(calculateBtn, in: app, requireHittable: true)
        tapElement(calculateBtn)

        let showFullMath = app.buttons["disclosure-full-math"].firstMatch
        scrollToElement(showFullMath, in: app)
        XCTAssertTrue(showFullMath.exists)
        let breakdown = app.staticTexts["show-full-math"].firstMatch
        scrollToElement(breakdown, in: app, direction: .down)
        XCTAssertTrue(breakdown.waitForExistence(timeout: 5))
        XCTAssertTrue(breakdown.label.contains("dim correction"))

        let reset = app.buttons["reset-defaults"].firstMatch
        scrollToElement(reset, in: app)
        XCTAssertTrue(reset.exists)
        waitForScrollingToSettle()
        tapElement(reset)

        // After reset, cachedResult is cleared — Calculate button should be present.
        let defaultApp = XCUIApplication()
        useDefaultDynamicType(defaultApp)
        defaultApp.launch()
        XCTAssertTrue(defaultApp.buttons["calculate-button"].waitForExistence(timeout: 3))
        defaultApp.terminate()
    }


    func testAboutHelpButtonOpensPullUpSheet() {
        let app = XCUIApplication()
        useDefaultDynamicType(app)
        app.launchEnvironment = Self.defaultLaunchEnvironment.merging([
            "KGR_YS": "32",
            "KGR_YR": "24",
            "KGR_SHOW_ABOUT_HELP": "1",
        ]) { _, new in new }
        app.launch()

        // Privacy card must not be present (privacy/non-tracking copy was removed)
        XCTAssertFalse(app.otherElements["privacy-card"].exists)

        // The ? opens a pull-up sheet with the full explanation
        let sheet = app.scrollViews["about-help-sheet"].firstMatch
        XCTAssertTrue(sheet.waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "two-axis gauge mismatch")).element.waitForExistence(timeout: 2))
    }

    func testVerdictHelpButtonOpensPullUpSheet() {
        // sheetVerdictBody uses liveResult (always-live compute) so it has content
        // even before the user taps Calculate.
        let app = XCUIApplication()
        useDefaultDynamicType(app)
        app.launchEnvironment = Self.defaultLaunchEnvironment.merging([
            "KGR_YS": "36",
            "KGR_YR": "32",
            "KGR_SHOW_VERDICT_HELP": "1",
        ]) { _, new in new }
        app.launch()

        // The sheet opens via the launch env; content is live from inputs.
        let sheet = app.scrollViews["verdict-help-sheet"].firstMatch
        XCTAssertTrue(sheet.waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "re-swatching")).element.waitForExistence(timeout: 2))
    }

    /// Issue #25: VoiceOver users must be able to dismiss help sheets without
    /// the drag-to-dismiss gesture. Both help sheets expose a Close button
    /// with a ≥44pt hit target.
    func testHelpSheetsExposeAccessibleCloseButton() {
        let app = XCUIApplication()
        useDefaultDynamicType(app)
        app.launchEnvironment = Self.defaultLaunchEnvironment.merging([
            "KGR_YS": "32",
            "KGR_YR": "24",
            "KGR_SHOW_ABOUT_HELP": "1",
        ]) { _, new in new }
        app.launch()

        let aboutSheet = app.scrollViews["about-help-sheet"].firstMatch
        XCTAssertTrue(aboutSheet.waitForExistence(timeout: 3))

        let aboutClose = app.buttons["about-help-close"].firstMatch
        XCTAssertTrue(aboutClose.waitForExistence(timeout: 2), "About sheet must expose a Close button (#25)")
        XCTAssertTrue(aboutClose.isHittable, "About sheet Close button must be hittable (#38)")
        // HIG 44×44pt hit region is enforced source-side via
        // .frame(width:44, height:44).contentShape(Rectangle()) on the Button.
        // XCUITest on iOS 26 reports the SF Symbol's visible glyph bounds
        // (~42×42pt) regardless of the wrapping layout frame, so we cannot
        // assert the hit-region size from .frame here. Functional dismissal
        // (below) and the AccessibilityAuditTests hit-region audit
        // (with "Close" exemption via systemToolbarLabels) cover the rest.
        tapElement(aboutClose)
        XCTAssertFalse(app.scrollViews["about-help-sheet"].waitForExistence(timeout: 2),
                       "Tapping Close must dismiss the About sheet")
    }

    func testVerdictHelpSheetExposesAccessibleCloseButton() {
        let app = XCUIApplication()
        useDefaultDynamicType(app)
        app.launchEnvironment = Self.defaultLaunchEnvironment.merging([
            "KGR_YS": "36",
            "KGR_YR": "32",
            "KGR_SHOW_VERDICT_HELP": "1",
        ]) { _, new in new }
        app.launch()

        let verdictSheet = app.scrollViews["verdict-help-sheet"].firstMatch
        XCTAssertTrue(verdictSheet.waitForExistence(timeout: 3))

        let verdictClose = app.buttons["verdict-help-close"].firstMatch
        XCTAssertTrue(verdictClose.waitForExistence(timeout: 2), "Verdict sheet must expose a Close button (#25)")
        XCTAssertTrue(verdictClose.isHittable, "Verdict sheet Close button must be hittable")
        // See testHelpSheetsExposeAccessibleCloseButton for rationale: HIG hit
        // region is enforced source-side; XCUITest reports glyph bounds, not
        // the layout/hit-test frame, so we rely on functional dismissal.
        tapElement(verdictClose)
        XCTAssertFalse(app.scrollViews["verdict-help-sheet"].waitForExistence(timeout: 2),
                       "Tapping Close must dismiss the Verdict sheet")
    }

    func testShareResultsIsSingleAccessibleAffordance() {
        let app = XCUIApplication()
        useDefaultDynamicType(app)
        app.launchEnvironment = Self.defaultLaunchEnvironment.merging([
            "KGR_YS": "32",
            "KGR_YR": "32",
        ]) { _, new in new }
        app.launch()

        // Tap Calculate to surface the share button (inside actionsCard).
        let calculateBtn = app.buttons["calculate-button"]
        XCTAssertTrue(calculateBtn.waitForExistence(timeout: 3))
        scrollToElement(calculateBtn, in: app, requireHittable: true)
        tapElement(calculateBtn)

        XCTAssertTrue(app.navigationBars["Adjustments"].firstMatch.waitForExistence(timeout: 3))

        let shareButton = app.buttons["share-results"].firstMatch
        XCTAssertTrue(shareButton.waitForExistence(timeout: 3))
        XCTAssertTrue(shareButton.isHittable)
        XCTAssertEqual(shareButton.label, "Share results")
        XCTAssertFalse(app.buttons["copy-results"].exists)
        XCTAssertFalse(app.staticTexts["copy-results-status"].exists)
        XCTAssertFalse(app.buttons["copy-share-link"].exists)
        XCTAssertFalse(app.buttons["share-results-link"].exists)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Copy")).count, 0)
        for item in ["TSV", "Markdown", "CSV", "HTML"] {
            XCTAssertFalse(app.buttons[item].exists, item)
        }
    }

    func testCompactWidthKeepsNumericFieldsSideBySideWhenTheyFit() {
        let app = XCUIApplication()
        useDefaultDynamicType(app)
        app.launchEnvironment = Self.defaultLaunchEnvironment.merging([
            "KGR_YS": "32",
            "KGR_YR": "32",
        ]) { _, new in new }
        app.launch()

        // Gauge input fields must be side-by-side (not stacked) on a compact phone width.
        let patternStitches = app.textFields["pattern-stitches-field"]
        let patternRows = app.textFields["pattern-rows-field"]
        XCTAssertTrue(patternStitches.waitForExistence(timeout: 2))
        XCTAssertTrue(patternRows.exists)
        assertSideBySide(patternStitches, patternRows)

        let yourStitches = app.textFields["your-stitches-field"]
        let yourRows = app.textFields["your-rows-field"]
        XCTAssertTrue(yourStitches.exists)
        XCTAssertTrue(yourRows.exists)
        assertSideBySide(yourStitches, yourRows)

        // Tap Calculate to show the adjustments section.
        let calculateBtn = app.buttons["calculate-button"]
        XCTAssertTrue(calculateBtn.waitForExistence(timeout: 3))
        scrollToElement(calculateBtn, in: app, requireHittable: true)
        tapElement(calculateBtn)

        // Yoke value pair's "You Must Knit" block should be visible after Calculate.
        let yokeValue = app.otherElements["yoke-your-rows"]
        scrollToElement(yokeValue, in: app)
        XCTAssertTrue(yokeValue.waitForExistence(timeout: 5))

        // Cast-on result must exist and carry the expected label.
        let castOnElement = app.otherElements["cast-on-result"]
        scrollToElement(castOnElement, in: app)
        XCTAssertTrue(castOnElement.exists)
        XCTAssertTrue(castOnElement.label.contains("Cast on 128 stitches"), castOnElement.label)
    }

    func testAccessibilityDynamicTypeStacksGaugeMeasurementPairs() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-UIPreferredContentSizeCategoryName",
            UIContentSizeCategory.accessibilityExtraExtraExtraLarge.rawValue
        ]
        app.launchEnvironment = Self.defaultLaunchEnvironment.merging([
            "KGR_YS": "32",
            "KGR_YR": "32",
        ]) { _, new in new }
        app.launch()

        let patternStitches = app.textFields["pattern-stitches-field"]
        let patternRows = app.textFields["pattern-rows-field"]
        XCTAssertTrue(patternStitches.waitForExistence(timeout: 2))
        XCTAssertTrue(patternRows.exists)
        assertStackedBelow(patternRows, patternStitches)

        let yourStitches = app.textFields["your-stitches-field"]
        let yourRows = app.textFields["your-rows-field"]
        XCTAssertTrue(yourStitches.exists)
        XCTAssertTrue(yourRows.exists)
        assertStackedBelow(yourRows, yourStitches)
    }

    func testMismatchStatesKeepYourGaugeFieldsEqualWidth() {
        let scenarios: [(yourStitches: String, yourRows: String, stitchMismatch: Bool, rowMismatch: Bool)] = [
            ("32", "24", false, false),
            ("36", "24", true, false),
            ("32", "32", false, true),
            ("36", "32", true, true),
        ]
        var baselineCalculateButtonY: CGFloat?

        for scenario in scenarios {
            let app = launchApp(yourStitches: scenario.yourStitches, yourRows: scenario.yourRows)
            let yourStitches = app.textFields["your-stitches-field"]
            let yourRows = app.textFields["your-rows-field"]
            let calculateButton = app.buttons["calculate-button"]
            XCTAssertTrue(yourStitches.waitForExistence(timeout: 2))
            XCTAssertTrue(yourRows.exists)
            XCTAssertTrue(calculateButton.exists)

            assertApproximatelyEqualWidth(yourStitches, yourRows)
            if let baselineCalculateButtonY {
                XCTAssertLessThanOrEqual(
                    abs(calculateButton.frame.minY - baselineCalculateButtonY),
                    1,
                    "Mismatch state should not add vertical growth"
                )
            } else {
                baselineCalculateButtonY = calculateButton.frame.minY
            }

            XCTAssertFalse(app.staticTexts["your-stitches-mismatch"].exists)
            XCTAssertFalse(app.staticTexts["your-rows-mismatch"].exists)
            XCTAssertEqual((yourStitches.value as? String)?.contains("stitch gauge mismatch detected"), scenario.stitchMismatch)
            XCTAssertEqual((yourRows.value as? String)?.contains("row gauge mismatch detected"), scenario.rowMismatch)
            XCTAssertEqual(app.buttons["your-stitches-chevron"].value as? String, scenario.stitchMismatch ? "Warning" : "")
            XCTAssertEqual(app.buttons["your-rows-chevron"].value as? String, scenario.rowMismatch ? "Warning" : "")
            app.terminate()
        }
    }

    func testMismatchWarningSummaryAppearsInWheelSheet() {
        let app = launchApp(yourStitches: "32", yourRows: "32")
        let warningButton = app.buttons["your-rows-chevron"]
        XCTAssertTrue(warningButton.waitForExistence(timeout: 2))

        tapElement(warningButton)
        let warningSummary = app.staticTexts["your-rows-warning-summary"]
        XCTAssertTrue(warningSummary.waitForExistence(timeout: 2))
        XCTAssertEqual(warningSummary.label, "Row gauge mismatch detected")
        XCTAssertEqual(app.textFields["your-rows-field"].value as? String, "32 rows, row gauge mismatch detected")

        tapElement(app.buttons["your-rows-wheel-done"])
        app.terminate()
    }

    private func setNumericField(
        _ field: XCUIElement,
        to newValue: String,
        in app: XCUIApplication
    ) {
        dismissKeyboard(in: app)
        field.tap()
        _ = app.keyboards.firstMatch.waitForExistence(timeout: 2)
        let backspaces = String(repeating: XCUIKeyboardKey.delete.rawValue, count: 8)
        field.typeText(backspaces + newValue)
    }

    private func dismissKeyboard(in app: XCUIApplication) {
        let done = app.toolbars.buttons["keyboard-done"]
        if done.exists && done.isHittable {
            done.tap()
            _ = waitUntil(timeout: 1.5) { !app.keyboards.firstMatch.exists }
        }
    }

    private func assertSideBySide(
        _ leading: XCUIElement,
        _ trailing: XCUIElement,
        timeout: TimeInterval = 3,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        waitUntil(timeout: timeout) {
            trailing.frame.minX > leading.frame.maxX
                && abs(trailing.frame.midY - leading.frame.midY) < max(leading.frame.height, trailing.frame.height)
        }
        XCTAssertGreaterThan(trailing.frame.minX, leading.frame.maxX, file: file, line: line)
        XCTAssertLessThan(
            abs(trailing.frame.midY - leading.frame.midY),
            max(leading.frame.height, trailing.frame.height),
            file: file,
            line: line
        )
    }

    private func assertStackedBelow(
        _ lower: XCUIElement,
        _ upper: XCUIElement,
        timeout: TimeInterval = 3,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        waitUntil(timeout: timeout) { lower.frame.minY > upper.frame.maxY }
        XCTAssertGreaterThan(lower.frame.minY, upper.frame.maxY, file: file, line: line)
    }

    private func assertApproximatelyEqualWidth(
        _ lhs: XCUIElement,
        _ rhs: XCUIElement,
        tolerance: CGFloat = 1,
        timeout: TimeInterval = 3,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        waitUntil(timeout: timeout) {
            abs(lhs.frame.width - rhs.frame.width) <= tolerance
        }
        XCTAssertLessThanOrEqual(
            abs(lhs.frame.width - rhs.frame.width),
            tolerance,
            "Expected equal widths, got \(lhs.frame.width) and \(rhs.frame.width)",
            file: file,
            line: line
        )
    }

    private func numericFieldValue(_ element: XCUIElement) -> Int? {
        guard let value = element.value as? String else { return nil }
        let digits = value.split(whereSeparator: { !$0.isNumber }).first
        return digits.flatMap { Int(String($0)) }
    }

    @discardableResult
    private func waitUntil(
        timeout: TimeInterval = 3,
        interval: TimeInterval = 0.1,
        _ condition: () -> Bool
    ) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            RunLoop.current.run(until: Date(timeIntervalSinceNow: interval))
        }
        return condition()
    }

    private enum ScrollDirection {
        case down
        case up
    }

    private func scrollToElement(
        _ element: XCUIElement,
        in app: XCUIApplication,
        requireHittable: Bool = false,
        direction: ScrollDirection = .down
    ) {
        var attempts = 0
        while attempts < 12 {
            if element.exists && (!requireHittable || element.isHittable) {
                return
            }
            let surface = app.scrollViews.firstMatch.exists ? app.scrollViews.firstMatch : app
            let lower = surface.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.72))
            let upper = surface.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.42))
            switch direction {
            case .down:
                lower.press(forDuration: 0.01, thenDragTo: upper)
            case .up:
                upper.press(forDuration: 0.01, thenDragTo: lower)
            }
            waitForScrollingToSettle()
            attempts += 1
        }
    }

    private func waitForScrollingToSettle() {
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.2))
    }

    private func useDefaultDynamicType(_ app: XCUIApplication) {
        app.launchArguments += [
            "-UIPreferredContentSizeCategoryName",
            UIContentSizeCategory.large.rawValue
        ]
    }

    private func launchApp(yourStitches: String, yourRows: String) -> XCUIApplication {
        let app = XCUIApplication()
        useDefaultDynamicType(app)
        app.launchEnvironment = Self.defaultLaunchEnvironment.merging([
            "KGR_YS": yourStitches,
            "KGR_YR": yourRows,
        ]) { _, new in new }
        app.launch()
        return app
    }

    private func tapElement(_ element: XCUIElement) {
        if element.isHittable {
            element.tap()
        } else {
            element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
    }
}
