import UIKit
import XCTest

@MainActor
final class KnittingGaugeReconcilerUITests: XCTestCase {
    private struct Scenario {
        var name: String
        var yourStitches: String
        var yourRows: String
        var stitchHero: String
        var rowHero: String
        var castOn: String
        var body: String
        var yoke: String
        var increases: String
    }

    private let scenarios = [
        Scenario(name: "Perfect Match", yourStitches: "32", yourRows: "24", stitchHero: "100%", rowHero: "100%", castOn: "128 stitches", body: "Knit to 50.0 cm · about 120 rows/rounds", yoke: "Knit to 20.0 cm · about 48 rows/rounds", increases: "Space every 6 rows/rounds"),
        Scenario(name: "Denser Row Only", yourStitches: "32", yourRows: "32", stitchHero: "100%", rowHero: "133%", castOn: "128 stitches", body: "Knit to 37.5 cm · about 120 rows/rounds", yoke: "Knit to 15.0 cm · about 48 rows/rounds", increases: "Space every 8 rows/rounds"),
        Scenario(name: "Looser Row Only", yourStitches: "32", yourRows: "20", stitchHero: "100%", rowHero: "83%", castOn: "128 stitches", body: "Knit to 60.0 cm · about 120 rows/rounds", yoke: "Knit to 24.0 cm · about 48 rows/rounds", increases: "Space every 5 rows/rounds"),
        Scenario(name: "Denser Stitch Only", yourStitches: "36", yourRows: "24", stitchHero: "89%", rowHero: "100%", castOn: "144 stitches", body: "Knit to 50.0 cm · about 120 rows/rounds", yoke: "Knit to 20.0 cm · about 48 rows/rounds", increases: "Space every 6 rows/rounds"),
        Scenario(name: "Looser Stitch Only", yourStitches: "28", yourRows: "24", stitchHero: "114%", rowHero: "100%", castOn: "112 stitches", body: "Knit to 50.0 cm · about 120 rows/rounds", yoke: "Knit to 20.0 cm · about 48 rows/rounds", increases: "Space every 6 rows/rounds"),
        Scenario(name: "Both Denser", yourStitches: "36", yourRows: "32", stitchHero: "89%", rowHero: "133%", castOn: "144 stitches", body: "Knit to 37.5 cm · about 120 rows/rounds", yoke: "Knit to 15.0 cm · about 48 rows/rounds", increases: "Space every 8 rows/rounds")
    ]

    func testAllJacquardScenariosAreVisibleInUI() {
        // Single-launch flow (resolves issue #18 — per-scenario app.terminate() →
        // app.launch() cycles exposed the test to multi-minute simulator stalls
        // on relaunch). Instead, launch once with scenario 0's values then drive
        // the remaining scenarios via in-app field input. This also exercises
        // the live-recalc path (goal #1) end-to-end.
        let app = XCUIApplication()
        useDefaultDynamicType(app)
        app.launchEnvironment = [
            "KGR_PS": "32",
            "KGR_PR": "24",
            "KGR_YS": scenarios[0].yourStitches,
            "KGR_YR": scenarios[0].yourRows,
            "KGR_CAST_ON": "128",
            "KGR_YOKE": "20",
            "KGR_BODY": "50",
            "KGR_SLEEVE": "45",
            "KGR_INCREASES": "6"
        ]
        app.launch()

        let yourStitchesField = app.textFields["your-stitches"]
        let yourRowsField = app.textFields["your-rows"]
        XCTAssertTrue(yourStitchesField.waitForExistence(timeout: 5))
        XCTAssertTrue(yourRowsField.waitForExistence(timeout: 5))

        let castOnElement = app.staticTexts["cast-on-result"]
        XCTAssertTrue(castOnElement.waitForExistence(timeout: 5))

        for (index, scenario) in scenarios.enumerated() {
            if index > 0 {
                setNumericField(yourStitchesField, to: scenario.yourStitches, in: app)
                setNumericField(yourRowsField, to: scenario.yourRows, in: app)
                dismissKeyboard(in: app)
            }

            let expectedCastOnLabel = "Cast on \(scenario.castOn)"
            waitUntil(timeout: 5) { castOnElement.label == expectedCastOnLabel }

            XCTAssertFalse(app.buttons["calculate-button"].exists, scenario.name)
            XCTAssertTrue(
                app.staticTexts[scenario.stitchHero].waitForExistence(timeout: 3),
                "\(scenario.name) stitchHero=\(scenario.stitchHero)"
            )
            XCTAssertTrue(
                app.staticTexts[scenario.rowHero].exists,
                "\(scenario.name) rowHero=\(scenario.rowHero)"
            )
            XCTAssertEqual(castOnElement.label, expectedCastOnLabel, scenario.name)
            XCTAssertTrue(
                app.staticTexts[scenario.body].exists,
                "\(scenario.name) body=\(scenario.body)"
            )
            XCTAssertTrue(
                app.staticTexts[scenario.yoke].exists,
                "\(scenario.name) yoke=\(scenario.yoke)"
            )
            XCTAssertTrue(
                app.staticTexts[scenario.increases].exists,
                "\(scenario.name) increases=\(scenario.increases)"
            )
        }
    }

    private func setNumericField(
        _ field: XCUIElement,
        to newValue: String,
        in app: XCUIApplication
    ) {
        // Dismiss the keyboard if it's up so the target field isn't covered
        // when we tap it. Decimal-pad keyboards have no Return key, so the
        // app exposes a "Done" keyboard accessory (same affordance the user
        // gets — see ContentView's .toolbar(.keyboard) modifier).
        dismissKeyboard(in: app)
        field.tap()
        _ = app.keyboards.firstMatch.waitForExistence(timeout: 2)
        // Clear with generous backspaces; per-scenario values are 2–4 digits.
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

    func testPrototypeParityControlsAreAvailable() {
        let app = XCUIApplication()
        useDefaultDynamicType(app)
        app.launchEnvironment = [
            "KGR_PS": "32",
            "KGR_PR": "24",
            "KGR_YS": "32",
            "KGR_YR": "24",
            "KGR_CAST_ON": "128",
            "KGR_YOKE": "20",
            "KGR_BODY": "50",
            "KGR_SLEEVE": "45",
            "KGR_INCREASES": "6",
            "KGR_SHOW_FULL_MATH": "1"
        ]
        app.launch()

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

        let defaultApp = XCUIApplication()
        useDefaultDynamicType(defaultApp)
        defaultApp.launch()
        XCTAssertTrue(defaultApp.staticTexts["133%"].waitForExistence(timeout: 3))
        defaultApp.terminate()
    }


    func testAboutHelpButtonOpensPullUpSheet() {
        let app = XCUIApplication()
        useDefaultDynamicType(app)
        app.launchEnvironment = [
            "KGR_PS": "32",
            "KGR_PR": "24",
            "KGR_YS": "32",
            "KGR_YR": "24",
            "KGR_CAST_ON": "128",
            "KGR_YOKE": "20",
            "KGR_BODY": "50",
            "KGR_SLEEVE": "45",
            "KGR_INCREASES": "6",
            "KGR_SHOW_ABOUT_HELP": "1"
        ]
        app.launch()

        // Privacy card must not be present (privacy/non-tracking copy was removed)
        XCTAssertFalse(app.otherElements["privacy-card"].exists)

        // The ? opens a pull-up sheet with the full explanation
        let sheet = app.scrollViews["about-help-sheet"].firstMatch
        XCTAssertTrue(sheet.waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "two-axis gauge mismatch")).element.waitForExistence(timeout: 2))
    }

    func testVerdictHelpButtonOpensPullUpSheet() {
        let app = XCUIApplication()
        useDefaultDynamicType(app)
        app.launchEnvironment = [
            "KGR_PS": "32",
            "KGR_PR": "24",
            "KGR_YS": "36",
            "KGR_YR": "32",
            "KGR_CAST_ON": "128",
            "KGR_YOKE": "20",
            "KGR_BODY": "50",
            "KGR_SLEEVE": "45",
            "KGR_INCREASES": "6",
            "KGR_SHOW_VERDICT_HELP": "1"
        ]
        app.launch()

        // The ? button opens a pull-up sheet with the full explanation
        let sheet = app.scrollViews["verdict-help-sheet"].firstMatch
        XCTAssertTrue(sheet.waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "re-swatching")).element.waitForExistence(timeout: 2))
    }

    func testShareResultsIsSingleAccessibleAffordance() {
        let app = XCUIApplication()
        useDefaultDynamicType(app)
        app.launchEnvironment = [
            "KGR_PS": "32",
            "KGR_PR": "24",
            "KGR_YS": "32",
            "KGR_YR": "32",
            "KGR_CAST_ON": "128",
            "KGR_YOKE": "20",
            "KGR_BODY": "50",
            "KGR_SLEEVE": "45",
            "KGR_INCREASES": "6"
        ]
        app.launch()

        let shareButton = app.buttons["share-results"].firstMatch
        scrollToElement(shareButton, in: app, requireHittable: true)
        XCTAssertTrue(shareButton.exists)
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
        app.launchEnvironment = [
            "KGR_PS": "32",
            "KGR_PR": "24",
            "KGR_YS": "32",
            "KGR_YR": "32",
            "KGR_CAST_ON": "128",
            "KGR_YOKE": "20",
            "KGR_BODY": "50",
            "KGR_SLEEVE": "45",
            "KGR_INCREASES": "6"
        ]
        app.launch()

        let patternStitches = app.textFields["pattern-stitches"]
        let patternRows = app.textFields["pattern-rows"]
        XCTAssertTrue(patternStitches.waitForExistence(timeout: 2))
        XCTAssertTrue(patternRows.exists)
        assertSideBySide(patternStitches, patternRows)

        let yourStitches = app.textFields["your-stitches"]
        let yourRows = app.textFields["your-rows"]
        XCTAssertTrue(yourStitches.exists)
        XCTAssertTrue(yourRows.exists)
        assertSideBySide(yourStitches, yourRows)

        let stitchHeroValue = app.staticTexts["100%"].firstMatch
        XCTAssertTrue(stitchHeroValue.waitForExistence(timeout: 2))
        let rowHeroValue = app.staticTexts["133%"]
        scrollToElement(rowHeroValue, in: app)
        XCTAssertTrue(rowHeroValue.exists)
        assertStackedBelow(rowHeroValue, stitchHeroValue)

        let yokeAdjustment = app.staticTexts["adjustment-yoke-depth-value"]
        scrollToElement(yokeAdjustment, in: app)
        XCTAssertTrue(yokeAdjustment.exists)
        let patternYoke = app.staticTexts["Pattern: 20 cm · about 48 pattern rows"].firstMatch
        XCTAssertTrue(patternYoke.exists)
        assertStackedBelow(yokeAdjustment, patternYoke)
    }

    func testAccessibilityDynamicTypeStacksGaugeMeasurementPairs() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-UIPreferredContentSizeCategoryName",
            UIContentSizeCategory.accessibilityExtraExtraExtraLarge.rawValue
        ]
        app.launchEnvironment = [
            "KGR_PS": "32",
            "KGR_PR": "24",
            "KGR_YS": "32",
            "KGR_YR": "32",
            "KGR_CAST_ON": "128",
            "KGR_YOKE": "20",
            "KGR_BODY": "50",
            "KGR_SLEEVE": "45",
            "KGR_INCREASES": "6"
        ]
        app.launch()

        let patternStitches = app.textFields["pattern-stitches"]
        let patternRows = app.textFields["pattern-rows"]
        XCTAssertTrue(patternStitches.waitForExistence(timeout: 2))
        XCTAssertTrue(patternRows.exists)
        assertStackedBelow(patternRows, patternStitches)

        let yourStitches = app.textFields["your-stitches"]
        let yourRows = app.textFields["your-rows"]
        XCTAssertTrue(yourStitches.exists)
        XCTAssertTrue(yourRows.exists)
        assertStackedBelow(yourRows, yourStitches)
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

    private func tapElement(_ element: XCUIElement) {
        if element.isHittable {
            element.tap()
        } else {
            element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
    }

    private func scrollToTop(in app: XCUIApplication) {
        let surface = app.scrollViews.firstMatch.exists ? app.scrollViews.firstMatch : app
        let upper = surface.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.28))
        let lower = surface.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.74))
        for _ in 0..<4 {
            upper.press(forDuration: 0.01, thenDragTo: lower)
            waitForScrollingToSettle()
        }
    }
}
