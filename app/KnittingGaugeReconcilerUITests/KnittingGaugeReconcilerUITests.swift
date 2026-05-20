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
        Scenario(name: "Perfect Match", yourStitches: "32", yourRows: "24", stitchHero: "100%", rowHero: "100%", castOn: "128 stitches", body: "Keep 50.0 cm · about 120 rows/rounds", yoke: "Keep 20.0 cm · about 48 rows/rounds", increases: "Space every 6 rows/rounds"),
        Scenario(name: "Denser Row Only", yourStitches: "32", yourRows: "32", stitchHero: "100%", rowHero: "133%", castOn: "128 stitches", body: "Keep 50.0 cm · about 160 rows/rounds", yoke: "Keep 20.0 cm · about 64 rows/rounds", increases: "Space every 8 rows/rounds"),
        Scenario(name: "Looser Row Only", yourStitches: "32", yourRows: "20", stitchHero: "100%", rowHero: "83%", castOn: "128 stitches", body: "Keep 50.0 cm · about 100 rows/rounds", yoke: "Keep 20.0 cm · about 40 rows/rounds", increases: "Space every 5 rows/rounds"),
        Scenario(name: "Denser Stitch Only", yourStitches: "36", yourRows: "24", stitchHero: "89%", rowHero: "100%", castOn: "144 stitches", body: "Keep 50.0 cm · about 120 rows/rounds", yoke: "Keep 20.0 cm · about 48 rows/rounds", increases: "Space every 6 rows/rounds"),
        Scenario(name: "Looser Stitch Only", yourStitches: "28", yourRows: "24", stitchHero: "114%", rowHero: "100%", castOn: "112 stitches", body: "Keep 50.0 cm · about 120 rows/rounds", yoke: "Keep 20.0 cm · about 48 rows/rounds", increases: "Space every 6 rows/rounds"),
        Scenario(name: "Both Denser", yourStitches: "36", yourRows: "32", stitchHero: "89%", rowHero: "133%", castOn: "144 stitches", body: "Keep 50.0 cm · about 160 rows/rounds", yoke: "Keep 20.0 cm · about 64 rows/rounds", increases: "Space every 8 rows/rounds")
    ]

    func testAllJacquardScenariosAreVisibleInUI() {
        for scenario in scenarios {
            let app = XCUIApplication()
            app.launchEnvironment = [
                "KGR_PS": "32",
                "KGR_PR": "24",
                "KGR_YS": scenario.yourStitches,
                "KGR_YR": scenario.yourRows,
                "KGR_CAST_ON": "128",
                "KGR_YOKE": "20",
                "KGR_BODY": "50",
                "KGR_SLEEVE": "45",
                "KGR_INCREASES": "6"
            ]
            app.launch()

            XCTAssertFalse(app.buttons["calculate-button"].exists, scenario.name)
            XCTAssertTrue(app.staticTexts[scenario.stitchHero].exists, scenario.name)
            XCTAssertTrue(app.staticTexts[scenario.rowHero].exists, scenario.name)
            XCTAssertEqual(app.staticTexts["cast-on-result"].label, "Cast on \(scenario.castOn)", scenario.name)
            XCTAssertTrue(app.staticTexts[scenario.body].exists, scenario.name)
            XCTAssertTrue(app.staticTexts[scenario.yoke].exists, scenario.name)
            XCTAssertTrue(app.staticTexts[scenario.increases].exists, scenario.name)
            app.terminate()
        }
    }

    func testPrototypeParityControlsAreAvailable() {
        let app = XCUIApplication()
        app.launchEnvironment = [
            "KGR_PS": "32",
            "KGR_PR": "24",
            "KGR_YS": "32",
            "KGR_YR": "24",
            "KGR_CAST_ON": "128",
            "KGR_YOKE": "20",
            "KGR_BODY": "50",
            "KGR_SLEEVE": "45",
            "KGR_INCREASES": "6"
        ]
        app.launch()

        let showFullMath = app.buttons["disclosure-full-math"].firstMatch
        scrollToElement(showFullMath, in: app, requireHittable: true)
        XCTAssertTrue(showFullMath.exists)
        XCTAssertTrue(showFullMath.isHittable)
        waitForScrollingToSettle()
        showFullMath.tap()
        let breakdown = app.staticTexts["show-full-math"].firstMatch
        XCTAssertTrue(breakdown.waitForExistence(timeout: 5))
        XCTAssertTrue(breakdown.label.contains("section rows"))

        let reset = app.buttons["reset-defaults"].firstMatch
        scrollToElement(reset, in: app, requireHittable: true)
        XCTAssertTrue(reset.exists)
        XCTAssertTrue(reset.isHittable)
        waitForScrollingToSettle()
        reset.tap()
        XCTAssertTrue(app.staticTexts["133%"].waitForExistence(timeout: 2))
    }


    func testAboutHelpButtonOpensPullUpSheet() {
        let app = XCUIApplication()
        app.launchEnvironment = [
            "KGR_PS": "32",
            "KGR_PR": "24",
            "KGR_YS": "32",
            "KGR_YR": "24",
            "KGR_CAST_ON": "128",
            "KGR_YOKE": "20",
            "KGR_BODY": "50",
            "KGR_SLEEVE": "45",
            "KGR_INCREASES": "6"
        ]
        app.launch()

        // The ? help button sits next to the app title at the top — no scrolling needed
        let helpButton = app.buttons["about-help-button"].firstMatch
        XCTAssertTrue(helpButton.waitForExistence(timeout: 3))
        XCTAssertTrue(helpButton.isHittable)
        XCTAssertEqual(helpButton.label, "About this calculator, more information")

        // Long about copy must NOT be directly visible in the main content
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "two-axis gauge mismatch")).element.exists)

        // Privacy card must not be present (privacy/non-tracking copy was removed)
        XCTAssertFalse(app.otherElements["privacy-card"].exists)

        // Tapping the ? opens the pull-up sheet with the full explanation
        waitForScrollingToSettle()
        helpButton.tap()
        let sheet = app.scrollViews["about-help-sheet"].firstMatch
        XCTAssertTrue(sheet.waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "two-axis gauge mismatch")).element.waitForExistence(timeout: 2))
    }

    func testVerdictHelpButtonOpensPullUpSheet() {
        let app = XCUIApplication()
        app.launchEnvironment = [
            "KGR_PS": "32",
            "KGR_PR": "24",
            "KGR_YS": "36",
            "KGR_YR": "32",
            "KGR_CAST_ON": "128",
            "KGR_YOKE": "20",
            "KGR_BODY": "50",
            "KGR_SLEEVE": "45",
            "KGR_INCREASES": "6"
        ]
        app.launch()

        // The help button must be discoverable on the verdict panel
        let helpButton = app.buttons["verdict-help-button"].firstMatch
        scrollToElement(helpButton, in: app, requireHittable: true)
        XCTAssertTrue(helpButton.exists)
        XCTAssertTrue(helpButton.isHittable)
        XCTAssertEqual(helpButton.label, "More information")

        // Explanatory body text must NOT be directly visible in the main card
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "re-swatching")).element.exists)

        // Tapping the ? button opens the pull-up sheet with the full explanation
        waitForScrollingToSettle()
        helpButton.tap()
        let sheet = app.scrollViews["verdict-help-sheet"].firstMatch
        XCTAssertTrue(sheet.waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "re-swatching")).element.waitForExistence(timeout: 2))
    }

    func testShareResultsIsSingleAccessibleAffordance() {
        let app = XCUIApplication()
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

    private func assertSideBySide(_ leading: XCUIElement, _ trailing: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertGreaterThan(trailing.frame.minX, leading.frame.maxX, file: file, line: line)
        XCTAssertLessThan(abs(trailing.frame.midY - leading.frame.midY), max(leading.frame.height, trailing.frame.height), file: file, line: line)
    }

    private func assertStackedBelow(_ lower: XCUIElement, _ upper: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertGreaterThan(lower.frame.minY, upper.frame.maxY, file: file, line: line)
    }

    private func scrollToElement(_ element: XCUIElement, in app: XCUIApplication, requireHittable: Bool = false) {
        var attempts = 0
        while attempts < 8 {
            if element.exists && (!requireHittable || element.isHittable) {
                return
            }
            app.swipeUp()
            waitForScrollingToSettle()
            attempts += 1
        }
    }

    private func waitForScrollingToSettle() {
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.2))
    }
}
