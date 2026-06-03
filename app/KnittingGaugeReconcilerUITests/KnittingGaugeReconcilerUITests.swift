import UIKit
import XCTest

@MainActor
final class KnittingGaugeReconcilerUITests: XCTestCase {

    // UI tests routinely take 30–120 s on CI simulators.
    // Override the global -default-test-execution-time-allowance 30 xcarg
    // so xcodebuild does not record a spurious time-exceeded failure.
    override var executionTimeAllowance: TimeInterval {
        get { 300 }
        set { }
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

        XCTAssertTrue(app.otherElements["adjustment-sheet"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Adjustments"].firstMatch.waitForExistence(timeout: 3))

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

    // MARK: - Unit toggle (#50)

    /// The cm/in toggle at the top of the screen changes the measurement field
    /// titles. Toggling "in" makes the yoke field label contain "in";
    /// toggling back to "cm" reverts it. Verifies the `unit-toggle` accessibility
    /// identifier is present and the conversion is visible via accessibility tree.
    func testUnitToggleSwitchesFieldLabel() {
        let app = XCUIApplication()
        useDefaultDynamicType(app)
        app.launchEnvironment = Self.defaultLaunchEnvironment.merging([
            "KGR_YS": "32",
            "KGR_YR": "24",
        ]) { _, new in new }
        app.launch()

        let toggle = app.segmentedControls["unit-toggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 3), "Unit toggle segmented control should be present")

        // Default is cm: yoke field label contains "cm".
        // Query the child TextField (accessibilityIdentifier "pattern-yoke-field") which
        // carries an explicit accessibilityLabel — the parent container uses
        // .accessibilityElement(children: .contain) and does not expose a synthesized
        // label on iOS 26.4, making .label empty on the otherElement.
        let yokeField = app.textFields["pattern-yoke-field"]
        XCTAssertTrue(yokeField.waitForExistence(timeout: 3))
        XCTAssertTrue(
            yokeField.label.contains("cm"),
            "Yoke field label should contain 'cm' in default mode, got: \(yokeField.label)"
        )

        // Tap the "in" segment button.
        let inButton = toggle.buttons["in"]
        XCTAssertTrue(inButton.waitForExistence(timeout: 2))
        tapElement(inButton)

        // After toggle: yoke label should contain "in".
        waitUntil(timeout: 3) { yokeField.label.contains("in") }
        XCTAssertTrue(
            yokeField.label.contains("in"),
            "Yoke field label should contain 'in' after toggle to inches, got: \(yokeField.label)"
        )

        // Toggle back to cm: label reverts.
        let cmButton = toggle.buttons["cm"]
        tapElement(cmButton)
        waitUntil(timeout: 3) { yokeField.label.contains("cm") }
        XCTAssertTrue(
            yokeField.label.contains("cm"),
            "Yoke field label should contain 'cm' after toggling back, got: \(yokeField.label)"
        )
        app.terminate()
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
        // Fast path: element is already ready — skip all dragging.
        if element.exists && (!requireHittable || element.isHittable) { return }

        var noProgressStreak = 0
        for _ in 0..<12 {
            let surface = preferredScrollSurface(in: app)
            let lower = surface.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.72))
            let upper = surface.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.42))

            // Snapshot the scroll surface position before dragging.
            // UIScrollView exposes its position as a percentage string via
            // the accessibility value (e.g. "0%", "50%"). Comparing before/after
            // detects whether the drag actually moved the surface.
            // NOTE: on iOS 26.4, UIScrollView.accessibilityValue returns "" (empty
            // string) instead of a percentage. Treat "" the same as nil — it is not
            // a positional signal and must not drive the no-progress bail.
            let rawBeforeValue = surface.value as? String
            let beforeValue: String? = rawBeforeValue.flatMap { $0.isEmpty ? nil : $0 }
            // Secondary sentinel: target element frame if already in hierarchy.
            // EXCEPTION: on iOS 26.4+, elements inside a scroll view report their
            // position in content-space coordinates rather than screen coordinates.
            // When we are waiting for an already-existing element to become hittable
            // (requireHittable: true), its frame will be fixed in content space and
            // won't change across drags — using it as a bail signal would always
            // show "no progress" and exit the loop too early. Suppress the frame
            // sentinel in that case and let the loop run all iterations.
            let elementAlreadyExistsAndNeedsHittable = requireHittable && element.exists
            let beforeFrame: CGRect? = elementAlreadyExistsAndNeedsHittable ? nil : (element.exists ? element.frame : nil)

            switch direction {
            case .down:
                lower.press(forDuration: 0.01, thenDragTo: upper)
            case .up:
                upper.press(forDuration: 0.01, thenDragTo: lower)
            }
            waitForScrollingToSettle()

            if element.exists && (!requireHittable || element.isHittable) { return }

            // No-progress bail: bail after 2 consecutive drags that provably
            // moved nothing. "Provably" means we had at least one measurable
            // signal (surface position or element frame) and it did not change.
            // When both signals are absent we cannot tell — assume the scroll
            // may still be working and let the loop continue.
            let rawAfterValue = surface.value as? String
            let afterValue: String? = rawAfterValue.flatMap { $0.isEmpty ? nil : $0 }
            let afterFrame: CGRect? = elementAlreadyExistsAndNeedsHittable ? nil : (element.exists ? element.frame : nil)
            let canMeasure = beforeValue != nil || beforeFrame != nil
            let surfaceMoved = beforeValue != afterValue
            let elementMoved = beforeFrame != afterFrame
            let madeProgress = !canMeasure || surfaceMoved || elementMoved
            if madeProgress {
                noProgressStreak = 0
            } else {
                noProgressStreak += 1
                if noProgressStreak >= 2 { return }
            }
        }
    }

    /// Returns the most likely active scroll surface. When a modal sheet is
    /// presented (`adjustment-sheet`), the sheet's own ScrollView is the
    /// correct drag target — `app.scrollViews.firstMatch` may resolve to
    /// the obscured background ScrollView and scroll gestures there are
    /// no-ops (#24 follow-up).
    private func preferredScrollSurface(in app: XCUIApplication) -> XCUIElement {
        let sheet = app.otherElements["adjustment-sheet"]
        if sheet.exists {
            let sheetScroll = sheet.scrollViews.firstMatch
            if sheetScroll.exists { return sheetScroll }
            return sheet
        }
        let scroll = app.scrollViews.firstMatch
        return scroll.exists ? scroll : app
    }

    private func waitForScrollingToSettle() {
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.2))
    }

    /// Expands the adjustment sheet from `.medium` to `.large` by dragging from
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

    /// Taps a full-width element inside a UISheetPresentationController using a
}
