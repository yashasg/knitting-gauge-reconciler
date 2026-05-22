import XCTest

/// Runs Apple's built-in XCUIApplication.performAccessibilityAudit() on every
/// major screen in the app. Requires Xcode 15+ / iOS 17+ simulator.
///
/// Run from the command line:
///   xcodebuild test \
///     -scheme KnittingGaugeReconciler \
///     -destination 'platform=iOS Simulator,name=iPhone 16' \
///     -only-testing KnittingGaugeReconcilerUITests/AccessibilityAuditTests \
///     2>&1 | grep -E "(PASS|FAIL|warning|error|audit)"
@MainActor
final class AccessibilityAuditTests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchEnvironment = [
            "KGR_PS": "32", "KGR_PR": "24",
            "KGR_YS": "32", "KGR_YR": "32",
            "KGR_CAST_ON": "128", "KGR_YOKE": "20",
            "KGR_BODY": "50", "KGR_SLEEVE": "45",
            "KGR_INCREASES": "6"
        ]
        app.launch()
    }

    override func tearDown() async throws {
        app = nil
    }

    /// Audits the main screen (all input cards + View Adjustments button visible).
    func testMainScreenAccessibility() throws {
        // Allow the view to settle
        _ = app.buttons["calculate-button"].waitForExistence(timeout: 3)

        // Run the full audit — catches missing labels, contrast, hit targets, etc.
        try app.performAccessibilityAudit()
    }

    /// Opens the Adjustments sheet and audits it.
    func testAdjustmentSheetAccessibility() throws {
        let viewAdjustments = app.buttons["calculate-button"]
        XCTAssertTrue(viewAdjustments.waitForExistence(timeout: 3))
        viewAdjustments.tap()

        // Wait for sheet
        _ = app.otherElements["adjustment-sheet"].waitForExistence(timeout: 3)

        try app.performAccessibilityAudit()
    }

    /// Opens the About help sheet and audits it.
    func testAboutSheetAccessibility() throws {
        let aboutButton = app.buttons["about-help-button"]
        XCTAssertTrue(aboutButton.waitForExistence(timeout: 3))
        aboutButton.tap()

        _ = app.otherElements["about-help-sheet"].waitForExistence(timeout: 3)

        try app.performAccessibilityAudit()
    }
}
