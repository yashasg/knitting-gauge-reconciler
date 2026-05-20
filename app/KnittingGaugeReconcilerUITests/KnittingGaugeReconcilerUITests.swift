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
        var increases: String
    }

    private let scenarios = [
        Scenario(name: "Perfect Match", yourStitches: "32", yourRows: "24", stitchHero: "100%", rowHero: "100%", castOn: "128 stitches", body: "Knit to 50.0 cm", increases: "Space every 6 rows"),
        Scenario(name: "Denser Row Only", yourStitches: "32", yourRows: "32", stitchHero: "100%", rowHero: "133%", castOn: "128 stitches", body: "Knit to 37.5 cm", increases: "Space every 8 rows"),
        Scenario(name: "Looser Row Only", yourStitches: "32", yourRows: "20", stitchHero: "100%", rowHero: "83%", castOn: "128 stitches", body: "Knit to 60.0 cm", increases: "Space every 5 rows"),
        Scenario(name: "Denser Stitch Only", yourStitches: "36", yourRows: "24", stitchHero: "89%", rowHero: "100%", castOn: "144 stitches", body: "Knit to 50.0 cm", increases: "Space every 6 rows"),
        Scenario(name: "Looser Stitch Only", yourStitches: "28", yourRows: "24", stitchHero: "114%", rowHero: "100%", castOn: "112 stitches", body: "Knit to 50.0 cm", increases: "Space every 6 rows"),
        Scenario(name: "Both Denser", yourStitches: "36", yourRows: "32", stitchHero: "89%", rowHero: "133%", castOn: "144 stitches", body: "Knit to 37.5 cm", increases: "Space every 8 rows")
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

        let showFullMath = app.buttons["disclosure-full-math"]
        scrollToElement(showFullMath, in: app)
        XCTAssertTrue(showFullMath.exists)
        showFullMath.tap()
        let breakdown = app.staticTexts["show-full-math"]
        XCTAssertTrue(breakdown.waitForExistence(timeout: 2))
        XCTAssertTrue(breakdown.label.contains("dim correction"))

        let reset = app.buttons["reset-defaults"]
        scrollToElement(reset, in: app)
        XCTAssertTrue(reset.exists)
        reset.tap()
        XCTAssertTrue(app.staticTexts["133%"].waitForExistence(timeout: 2))
    }

    func testCompactWidthStacksGaugeHeroesAndAdjustmentRowsVertically() {
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
        XCTAssertGreaterThan(patternRows.frame.minY, patternStitches.frame.maxY)

        let stitchHeroValue = app.staticTexts["100%"].firstMatch
        XCTAssertTrue(stitchHeroValue.waitForExistence(timeout: 2))
        let rowHeroValue = app.staticTexts["133%"]
        scrollToElement(rowHeroValue, in: app)
        XCTAssertTrue(rowHeroValue.exists)
        XCTAssertGreaterThan(rowHeroValue.frame.minY, stitchHeroValue.frame.maxY)

        let yokeAdjustment = app.staticTexts["adjustment-yoke-depth-value"]
        scrollToElement(yokeAdjustment, in: app)
        XCTAssertTrue(yokeAdjustment.exists)
        let patternYoke = app.staticTexts["Pattern: 20 cm"].firstMatch
        XCTAssertTrue(patternYoke.exists)
        XCTAssertGreaterThan(yokeAdjustment.frame.minY, patternYoke.frame.maxY)
    }

    private func scrollToElement(_ element: XCUIElement, in app: XCUIApplication) {
        var attempts = 0
        while !element.exists && attempts < 6 {
            app.swipeUp()
            attempts += 1
        }
    }
}
