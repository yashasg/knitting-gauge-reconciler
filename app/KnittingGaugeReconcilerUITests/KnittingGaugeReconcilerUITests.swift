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
        Scenario(name: "Perfect Match", yourStitches: "32", yourRows: "24", stitchHero: "100%", rowHero: "100%", castOn: "128 stitches", body: "50.0 cm", increases: "Every 6 rows"),
        Scenario(name: "Denser Row Only", yourStitches: "32", yourRows: "32", stitchHero: "100%", rowHero: "133%", castOn: "128 stitches", body: "37.5 cm", increases: "Every 8 rows"),
        Scenario(name: "Looser Row Only", yourStitches: "32", yourRows: "20", stitchHero: "100%", rowHero: "83%", castOn: "128 stitches", body: "60.0 cm", increases: "Every 5 rows"),
        Scenario(name: "Denser Stitch Only", yourStitches: "36", yourRows: "24", stitchHero: "89%", rowHero: "100%", castOn: "144 stitches", body: "50.0 cm", increases: "Every 6 rows"),
        Scenario(name: "Looser Stitch Only", yourStitches: "28", yourRows: "24", stitchHero: "114%", rowHero: "100%", castOn: "112 stitches", body: "50.0 cm", increases: "Every 6 rows"),
        Scenario(name: "Both Denser", yourStitches: "36", yourRows: "32", stitchHero: "89%", rowHero: "133%", castOn: "144 stitches", body: "37.5 cm", increases: "Every 8 rows")
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
            app.buttons["calculate-button"].tap()

            XCTAssertTrue(app.staticTexts[scenario.stitchHero].exists, scenario.name)
            XCTAssertTrue(app.staticTexts[scenario.rowHero].exists, scenario.name)
            XCTAssertTrue(app.staticTexts["Cast on \(scenario.castOn)"].exists, scenario.name)
            XCTAssertTrue(app.staticTexts[scenario.body].exists, scenario.name)
            XCTAssertTrue(app.staticTexts[scenario.increases].exists, scenario.name)
            app.terminate()
        }
    }
}
