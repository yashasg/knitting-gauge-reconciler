// swiftlint:disable file_length
import SwiftUI
import UIKit
import MetricKit
import os.signpost
// Components and Views are in separate files under Components/ and Views/

// swiftlint:disable:next type_body_length
struct ContentView: View {
    private static let defaults = GaugeTextDefaults()
    private static let sceneDraftActivityType = "com.stitchwise.scene-draft"

    private struct ResetSnapshot {
        let patternStitches: String
        let patternRows: String
        let yourStitches: String
        let yourRows: String
        let patternCastOn: String
        let patternYoke: String
        let patternBody: String
        let patternSleeve: String
        let patternIncreases: String
        let patternDetailsExpanded: Bool
    }

    // MARK: - Adaptive layout

    @Environment(\.scenePhase) private var scenePhase
    @ScaledMetric(relativeTo: .body) private var cardSpacing: CGFloat = 12

    // MARK: - State

    @SceneStorage("gauge.pattern-stitches")
    private var patternStitches = initialText("KGR_PS", defaultValue: "32")
    @SceneStorage("gauge.pattern-rows")
    private var patternRows = initialText("KGR_PR", defaultValue: "24")
    @SceneStorage("gauge.swatch-stitches")
    private var yourStitches = initialText("KGR_YS", defaultValue: "32")
    @SceneStorage("gauge.swatch-rows")
    private var yourRows = initialText("KGR_YR", defaultValue: "32")
    @SceneStorage("gauge.pattern-cast-on")
    private var patternCastOn = initialText("KGR_CAST_ON", defaultValue: "")
    @SceneStorage("gauge.pattern-yoke")
    private var patternYoke = initialText("KGR_YOKE", defaultValue: "")
    @SceneStorage("gauge.pattern-body")
    private var patternBody = initialText("KGR_BODY", defaultValue: "")
    @SceneStorage("gauge.pattern-sleeve")
    private var patternSleeve = initialText("KGR_SLEEVE", defaultValue: "")
    @SceneStorage("gauge.pattern-increases")
    private var patternIncreases = initialText("KGR_INCREASES", defaultValue: "")
    @SceneStorage("gauge.pattern-details-expanded")
    private var patternDetailsExpanded = initialBool("KGR_SHOW_PATTERN_DETAILS")

    @State private var showFullMath = initialBool("KGR_SHOW_FULL_MATH")
    @State private var showVerdictHelp = initialBool("KGR_SHOW_VERDICT_HELP")
    @State private var showAboutHelp = initialBool("KGR_SHOW_ABOUT_HELP")
    @State private var showAdjustmentSheet = false
    @State private var previousVerdictBucket: VerdictBucket?
    @State private var driftBandSignpostFired = false
    /// Latest result presented from a "View Adjustments" tap.
    @State private var cachedResult: GaugeMathResult?
    @State private var resetSnapshot: ResetSnapshot?
    @State private var focusedField: GaugeFormField?
    @State private var sceneSessionIdentifier: String?
    @State private var sceneRestorationReady = false

    // MARK: - Persisted unit preference

    /// User's chosen measurement unit. Stored in UserDefaults; defaults to cm.
    /// INTERNAL MODEL IS ALWAYS CM — this controls display/entry conversion only.
    @AppStorage("measurementUnit") private var measurementUnit: MeasurementUnit = .centimeters

    // MARK: - Derived

    private var inputs: GaugeInputs? {
        guard case let .success(patternStitches?) = validationResult(for: .patternStitches),
              case let .success(patternRows?) = validationResult(for: .patternRows),
              case let .success(yourStitches?) = validationResult(for: .yourStitches),
              case let .success(yourRows?) = validationResult(for: .yourRows),
              case let .success(patternCastOn) = validationResult(for: .patternCastOn),
              case let .success(patternYoke) = validationResult(for: .patternYoke),
              case let .success(patternBody) = validationResult(for: .patternBody),
              case let .success(patternSleeve) = validationResult(for: .patternSleeve),
              case let .success(patternIncreases) = validationResult(for: .patternIncreases) else {
            return nil
        }
        return GaugeInputs(
            patternStitches: patternStitches,
            patternRows: patternRows,
            yourStitches: yourStitches,
            yourRows: yourRows,
            patternYokeDepth: patternYoke,
            patternBodyLength: patternBody,
            patternSleeveLength: patternSleeve,
            patternIncreaseSpacing: patternIncreases,
            patternCastOn: patternCastOn
        )
    }

    private var liveResult: GaugeMathResult? {
        guard let inputs else { return nil }
        return cachedResult ?? GaugeMath.compute(inputs)
    }

    @discardableResult
    private func recomputeResult() -> GaugeMathResult? {
        guard let inputs else {
            invalidateResults()
            return nil
        }
        os_signpost(.begin, log: MetricsSubscriber.log, name: SignpostNames.compute)
        let result = GaugeMath.compute(inputs)
        cachedResult = result
        os_signpost(.end, log: MetricsSubscriber.log, name: SignpostNames.compute)
        return result
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: cardSpacing) {
                    Text(
                        "Compare your pattern gauge with your swatch to see how stitch and row differences " +
                            "affect the garment."
                    )
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.background)
                    .accessibilityIdentifier("gauge-lead")

                    GaugeInputsCard(
                        patternStitches: draftBinding($patternStitches, at: 0),
                        patternRows: draftBinding($patternRows, at: 1),
                        yourStitches: draftBinding($yourStitches, at: 2),
                        yourRows: draftBinding($yourRows, at: 3),
                        stitchMismatch: inputs?.stitchMismatch ?? false,
                        rowMismatch: inputs?.rowMismatch ?? false,
                        stitchDelta: roundedDelta(
                            inputs.map { $0.yourStitches - $0.patternStitches }
                        ),
                        rowDelta: roundedDelta(
                            inputs.map { $0.yourRows - $0.patternRows }
                        ),
                        validationMessages: validationMessages,
                        focusedField: $focusedField,
                        onSubmit: finishEditing
                    )
                    PatternInstructionsCard(
                        patternCastOn: draftBinding($patternCastOn, at: 4),
                        patternYoke: draftBinding($patternYoke, at: 5),
                        patternBody: draftBinding($patternBody, at: 6),
                        patternSleeve: draftBinding($patternSleeve, at: 7),
                        patternIncreases: draftBinding($patternIncreases, at: 8),
                        unit: $measurementUnit,
                        isExpanded: patternDetailsBinding,
                        validationMessages: validationMessages,
                        focusedField: $focusedField,
                        onSubmit: finishEditing
                    )
                    RequiredAdjustmentsCard(
                        cachedResult: cachedResult,
                        inputs: inputs,
                        unit: measurementUnit,
                        showFullMath: $showFullMath,
                        showAdjustmentSheet: $showAdjustmentSheet,
                        canUndoReset: resetSnapshot != nil,
                        onRecalculate: recomputeResult,
                        onReset: resetToDefaults,
                        onUndoReset: undoReset,
                        onShare: { result in await shareItems(for: result) }
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)
                .opacity(sceneRestorationReady ? 1 : 0)
                .accessibilityHidden(!sceneRestorationReady)
            }
            // While a help sheet is presented, the underlying view is still rendered
            // (dimmed) behind the sheet. Apple's accessibility audit traverses every
            // visible element — including bare body paragraphs that legitimately
            // render in full width. Mark the main content inert to a11y while a
            // *help* sheet is up so the audit focuses on the sheet itself.
            //
            // Modal sheets own accessibility focus while presented. Their roots
            // explicitly opt back in below so underlying controls are not audited
            // through the system dimming layer.
            .accessibilityHidden(showVerdictHelp || showAboutHelp || showAdjustmentSheet)
            .navigationTitle("Stitchwise")
            .background(
                ZStack {
                    AppTheme.background
                    TexturedBackground()
                }
                .ignoresSafeArea()
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    AboutHelpToolbarButton(showAboutHelp: $showAboutHelp)
                }
            }
            .sheet(isPresented: $showVerdictHelp) {
                VerdictHelpSheet(title: sheetVerdictTitle, explanation: sheetVerdictBody)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showAboutHelp) {
                AboutHelpSheet()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .onChange(of: showVerdictHelp) { _, newValue in
                if newValue {
                    os_signpost(.event, log: MetricsSubscriber.log, name: SignpostNames.sheetVerdictHelpOpened)
                }
            }
            .onChange(of: showAboutHelp) { _, newValue in
                if newValue {
                    os_signpost(.event, log: MetricsSubscriber.log, name: SignpostNames.sheetAboutHelpOpened)
                }
            }
            // verdict.improved / verdict.degraded fire only when cachedResult changes (i.e. on
            // View Adjustments tap), because verdictTitle returns "" while cachedResult is nil.
            .onChange(of: verdictTitle) { _, newValue in
                guard !newValue.isEmpty else {
                    previousVerdictBucket = nil
                    return
                }
                let current = VerdictBucket(verdictTitle: newValue)
                if let decision = GaugeMathMetrics.classifyVerdictDelta(
                    previous: previousVerdictBucket,
                    current: current
                ) {
                    switch decision {
                    case .improved:
                        os_signpost(.event, log: MetricsSubscriber.log, name: SignpostNames.verdictImproved)
                    case .degraded:
                        os_signpost(.event, log: MetricsSubscriber.log, name: SignpostNames.verdictDegraded)
                    }
                }
                previousVerdictBucket = current
            }
            .onChange(
                of: cachedResult?.castOnRoundingDriftPercent.map { abs($0) >= 3 } ?? false
            ) { _, isVisible in
                if isVisible, !driftBandSignpostFired {
                    os_signpost(.event, log: MetricsSubscriber.log, name: SignpostNames.castOnDriftBandShown)
                    driftBandSignpostFired = true
                } else if !isVisible {
                    driftBandSignpostFired = false
                }
            }
        }
        .background {
            SceneSessionReader(onResolve: connectToSceneSession)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active {
                UserDefaults.standard.synchronize()
            }
        }
    }

    // MARK: - Verdict (signpost-only; derived from cachedResult so it changes only on sheet presentation)

    /// Returns "" when no result exists — prevents spurious signpost fires before first sheet presentation.
    private var verdictTitle: String {
        guard inputs != nil, let result = cachedResult else { return "" }
        return verdictTitleComputed(result: result)
    }

    private var sheetVerdictTitle: String {
        guard let liveResult else { return "Correct your gauge values" }
        return verdictTitleComputed(result: liveResult)
    }

    private var sheetVerdictBody: String {
        guard let liveResult, let inputs else {
            return "Correct the highlighted fields before viewing gauge guidance."
        }
        return verdictBodyComputed(result: liveResult, inputs: inputs)
    }

    private func verdictTitleComputed(result: GaugeMathResult) -> String {
        let stitchDrift = abs(result.stitchWidthScale - 1)
        let rowDrift = abs(result.rowCountScale - 1)
        if stitchDrift < 0.03, rowDrift < 0.03 { return "Gauge match" }
        if stitchDrift >= 0.15 || rowDrift >= 0.15 { return "Major mismatch" }
        let stitchOffRange = stitchDrift >= 0.03 && stitchDrift < 0.15
        let rowOffRange = rowDrift >= 0.03 && rowDrift < 0.15
        if stitchOffRange && rowOffRange { return "Significant drift" }
        return "Drift"
    }

    private func verdictBodyComputed(result: GaugeMathResult, inputs: GaugeInputs) -> String {
        let stitchDrift   = abs(result.stitchWidthScale - 1)
        let rowDrift      = abs(result.rowCountScale - 1)
        let stitchPercent = abs(GaugeMath.fmtPct(result.stitchWidthScale) - 100)
        let rowPercent    = abs(GaugeMath.fmtPct(result.rowCountScale) - 100)
        let stitchOff = stitchPercent >= 3
        let rowOff    = rowPercent >= 3
        let stitchDir = result.stitchWidthScale > 1 ? "wider" : "narrower"
        let rowDir    = result.rowCountScale > 1 ? "denser" : "looser"
        let majorNote = (stitchDrift >= 0.15 || rowDrift >= 0.15)
            ? " Over 15% drift. Consider re-swatching or changing needle size before proceeding."
            : ""
        let castOnGuidance = castOnGuidance(result: result, inputs: inputs)
        if !stitchOff && !rowOff {
            return "Both gauges match. \(castOnGuidance)" +
                "No gauge adjustments are needed. Re-check after blocking."
        }
        if stitchOff && !rowOff {
            return (
                "Your row gauge matches, but your stitch gauge is \(stitchPercent)% \(stitchDir). " +
                "\(castOnGuidance)Vertical sections need no adjustment.\(majorNote)"
            )
        }
        if !stitchOff {
            return (
                "Your stitch gauge matches. \(castOnGuidance)" +
                "Your row gauge is \(rowPercent)% \(rowDir) than expected; use the row count guidance " +
                "for each vertical section.\(majorNote)"
            )
        }
        return (
            "Both axes are off: stitch gauge \(stitchPercent)% \(stitchDir), row gauge \(rowPercent)% \(rowDir). " +
            "\(castOnGuidance)Use the row count guidance for any supplied vertical sections.\(majorNote)"
        )
    }

    private func castOnGuidance(result: GaugeMathResult, inputs: GaugeInputs) -> String {
        guard let patternCastOn = inputs.patternCastOn,
              let adjustedCastOn = result.adjustedCastOn else {
            return ""
        }
        if Double(adjustedCastOn) == patternCastOn {
            return "Cast on \(adjustedCastOn) stitches as written. "
        }
        return "Cast on \(adjustedCastOn) stitches instead of \(plain(patternCastOn)). "
    }

    // MARK: - Validation

    private var rawTextValues: [String] {
        [
            patternStitches,
            patternRows,
            yourStitches,
            yourRows,
            patternCastOn,
            patternYoke,
            patternBody,
            patternSleeve,
            patternIncreases
        ]
    }

    private func draftBinding(_ binding: Binding<String>, at index: Int) -> Binding<String> {
        Binding(
            get: { binding.wrappedValue },
            set: { newValue in
                guard newValue != binding.wrappedValue else { return }
                var values = rawTextValues
                values[index] = newValue
                binding.wrappedValue = newValue
                invalidateResults()
                updateSceneRestorationActivity(
                    values: values,
                    disclosure: patternDetailsExpanded
                )
            }
        )
    }

    private var patternDetailsBinding: Binding<Bool> {
        Binding(
            get: { patternDetailsExpanded },
            set: { newValue in
                guard newValue != patternDetailsExpanded else { return }
                patternDetailsExpanded = newValue
                updateSceneRestorationActivity(
                    values: rawTextValues,
                    disclosure: newValue
                )
            }
        )
    }

    private var validationMessages: [GaugeFormField: String] {
        Dictionary(
            uniqueKeysWithValues: GaugeFormField.allCases.compactMap { field in
                validationMessage(for: field).map { (field, $0) }
            }
        )
    }

    private func validationResult(
        for field: GaugeFormField
    ) -> Result<Double?, GaugeMath.ValidationError> {
        GaugeMath.validate(rawText(for: field), for: field.mathField)
    }

    private func rawText(for field: GaugeFormField) -> String {
        switch field {
        case .patternStitches: return patternStitches
        case .patternRows: return patternRows
        case .yourStitches: return yourStitches
        case .yourRows: return yourRows
        case .patternCastOn: return patternCastOn
        case .patternYoke: return patternYoke
        case .patternBody: return patternBody
        case .patternSleeve: return patternSleeve
        case .patternIncreases: return patternIncreases
        }
    }

    private func validationMessage(for field: GaugeFormField) -> String? {
        if let invalidInches = MeasurementUnit.invalidInchesText(from: rawText(for: field)) {
            let range = MeasurementUnit.inches.displayRange(from: 5...100)
            return "\(field.correctionName) must be a whole number between \(range.lowerBound) and " +
                "\(range.upperBound) in. Entered: \(invalidInches)."
        }
        guard case let .failure(error) = validationResult(for: field) else {
            return nil
        }
        switch error {
        case .required:
            return "\(field.correctionName) is required."
        case .invalidNumber:
            return "Enter \(field.correctionName.lowercased()) as a number."
        case .outOfRange:
            let bounds = displayedBounds(for: field)
            return "\(field.correctionName) must be between \(bounds.range.lowerBound) and " +
                "\(bounds.range.upperBound) \(bounds.unit)."
        }
    }

    private func displayedBounds(for field: GaugeFormField) -> (range: ClosedRange<Int>, unit: String) {
        switch field {
        case .patternStitches, .yourStitches:
            return (1...99, "stitches")
        case .patternRows, .yourRows:
            return (1...99, "rows")
        case .patternCastOn:
            return (40...400, "stitches")
        case .patternYoke, .patternBody, .patternSleeve:
            return (measurementUnit.displayRange(from: 5...100), measurementUnit.label)
        case .patternIncreases:
            return (1...30, "rows")
        }
    }

    private func finishEditing() {
        let firstInvalidField = GaugeFormField.allCases.first(where: {
            validationMessage(for: $0) != nil
        })
        if firstInvalidField?.isPatternDetail == true {
            patternDetailsBinding.wrappedValue = true
        }
        focusedField = firstInvalidField

        if let firstInvalidField,
           let message = validationMessage(for: firstInvalidField) {
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }

    // MARK: - Scene restoration

    private func connectToSceneSession(_ session: UISceneSession) {
        guard sceneSessionIdentifier != session.persistentIdentifier else { return }
        sceneSessionIdentifier = session.persistentIdentifier
        if Self.ignoresPersistentState {
            restoreLaunchDraft(for: session)
        } else {
            var restored = session.stateRestorationActivity.map {
                restoreSceneDraft(from: $0, for: session)
            } ?? false
            if !restored, let userInfo = session.userInfo {
                restored = restoreSceneDraft(from: userInfo, for: session)
            }
            if !restored,
               let userInfo = SceneDraftStore.load(sceneID: session.persistentIdentifier) {
                restored = restoreSceneDraft(from: userInfo, for: session)
            }
            if !restored,
               Self.isOnlyOpenSession(session),
               let previousIdentifier = SceneDraftStore.singleSceneID(),
               let userInfo = SceneDraftStore.load(sceneID: previousIdentifier) {
                restored = restoreSceneDraft(from: userInfo, for: session)
            }
            if !restored,
               Self.isOnlyOpenSession(session),
               let userInfo = SceneDraftStore.singleSceneHandoff() {
                restored = restoreSceneDraft(from: userInfo, for: session)
            }
            if !restored {
                updateSceneRestorationActivity(
                    values: rawTextValues,
                    disclosure: patternDetailsExpanded,
                    for: session
                )
            }
        }
        sceneRestorationReady = true
    }

    private func restoreLaunchDraft(for session: UISceneSession) {
        applySceneDraft(
            values: [
                initialText("KGR_PS", defaultValue: Self.defaults.patternStitches),
                initialText("KGR_PR", defaultValue: Self.defaults.patternRows),
                initialText("KGR_YS", defaultValue: Self.defaults.yourStitches),
                initialText("KGR_YR", defaultValue: Self.defaults.yourRows),
                initialText("KGR_CAST_ON", defaultValue: ""),
                initialText("KGR_YOKE", defaultValue: ""),
                initialText("KGR_BODY", defaultValue: ""),
                initialText("KGR_SLEEVE", defaultValue: ""),
                initialText("KGR_INCREASES", defaultValue: ""),
            ],
            disclosure: initialBool("KGR_SHOW_PATTERN_DETAILS"),
            for: session
        )
    }

    private static var ignoresPersistentState: Bool {
        launchArgumentEnabled("-ApplePersistenceIgnoreState")
    }

    private static func launchArgumentEnabled(_ key: String) -> Bool {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.lastIndex(of: key),
              arguments.indices.contains(index + 1) else {
            return false
        }
        return arguments[index + 1].caseInsensitiveCompare("YES") == .orderedSame
    }

    private static func isOnlyOpenSession(_ session: UISceneSession) -> Bool {
        let openSessions = UIApplication.shared.openSessions
        return openSessions.count == 1 && openSessions.contains(session)
    }

    @discardableResult
    private func restoreSceneDraft(from activity: NSUserActivity, for session: UISceneSession) -> Bool {
        guard let userInfo = activity.userInfo else { return false }
        return restoreSceneDraft(from: userInfo, for: session)
    }

    @discardableResult
    private func restoreSceneDraft(
        from userInfo: [AnyHashable: Any],
        for session: UISceneSession
    ) -> Bool {
        guard let draft = SceneDraftStore.deserialize(userInfo) else { return false }
        applySceneDraft(values: draft.values, disclosure: draft.disclosure, for: session)
        return true
    }

    private func applySceneDraft(
        values: [String],
        disclosure: Bool,
        for session: UISceneSession? = nil,
        synchronizingDefaults: Bool = false
    ) {
        patternStitches = values[0]
        patternRows = values[1]
        yourStitches = values[2]
        yourRows = values[3]
        patternCastOn = values[4]
        patternYoke = values[5]
        patternBody = values[6]
        patternSleeve = values[7]
        patternIncreases = values[8]
        patternDetailsExpanded = disclosure
        invalidateResults()
        updateSceneRestorationActivity(
            values: values,
            disclosure: disclosure,
            for: session,
            synchronizingDefaults: synchronizingDefaults
        )
    }

    private func updateSceneRestorationActivity(
        values: [String],
        disclosure: Bool,
        for resolvedSession: UISceneSession? = nil,
        synchronizingDefaults: Bool = false
    ) {
        let session: UISceneSession?
        if let resolvedSession {
            session = resolvedSession
        } else if let sceneSessionIdentifier {
            session = UIApplication.shared.connectedScenes.first(where: {
                $0.session.persistentIdentifier == sceneSessionIdentifier
            })?.session
        } else {
            session = nil
        }
        guard let session else { return }

        // Namespace process-loss snapshots by scene; the single-scene alias is removed when another scene exists.
        guard let draft = SceneDraftStore.serialize(values: values, disclosure: disclosure) else {
            return
        }
        let activity = session.stateRestorationActivity
            ?? NSUserActivity(activityType: Self.sceneDraftActivityType)
        activity.addUserInfoEntries(from: draft)
        session.stateRestorationActivity = activity
        var userInfo = session.userInfo ?? [:]
        for (key, value) in draft {
            userInfo[key] = value
        }
        session.userInfo = userInfo
        SceneDraftStore.save(draft, sceneID: session.persistentIdentifier)
        if Self.isOnlyOpenSession(session) {
            SceneDraftStore.setSingleSceneID(session.persistentIdentifier)
            SceneDraftStore.setSingleSceneHandoff(draft)
        } else {
            SceneDraftStore.setSingleSceneID(nil)
            SceneDraftStore.setSingleSceneHandoff(nil)
        }
        if synchronizingDefaults {
            UserDefaults.standard.synchronize()
        }
    }

    private func roundedDelta(_ value: Double?) -> Int? {
        value.flatMap { Int(exactly: $0.rounded()) }
    }

    // MARK: - Actions

    private func resetToDefaults() {
        resetSnapshot = ResetSnapshot(
            patternStitches: patternStitches,
            patternRows: patternRows,
            yourStitches: yourStitches,
            yourRows: yourRows,
            patternCastOn: patternCastOn,
            patternYoke: patternYoke,
            patternBody: patternBody,
            patternSleeve: patternSleeve,
            patternIncreases: patternIncreases,
            patternDetailsExpanded: patternDetailsExpanded
        )
        os_signpost(.event, log: MetricsSubscriber.log, name: SignpostNames.resetTapped)
        applySceneDraft(
            values: Self.defaults.resetSceneDraftValues,
            disclosure: false,
            synchronizingDefaults: true
        )
        focusedField = nil
        showFullMath = false
    }

    private func undoReset() {
        guard let snapshot = resetSnapshot else { return }
        resetSnapshot = nil
        applySceneDraft(
            values: [
                snapshot.patternStitches,
                snapshot.patternRows,
                snapshot.yourStitches,
                snapshot.yourRows,
                snapshot.patternCastOn,
                snapshot.patternYoke,
                snapshot.patternBody,
                snapshot.patternSleeve,
                snapshot.patternIncreases,
            ],
            disclosure: snapshot.patternDetailsExpanded,
            synchronizingDefaults: true
        )
        focusedField = nil
        showFullMath = false
    }

    private func invalidateResults() {
        previousVerdictBucket = nil
        cachedResult = nil
        showAdjustmentSheet = false
        driftBandSignpostFired = false
    }

    @MainActor
    private func shareItems(for result: GaugeMathResult) async -> [Any] {
        guard let inputs else { return [] }
        let summary = ResultsExportSummary(inputs: inputs, result: result, unit: measurementUnit)
        if let imageURL = await renderShareImageURL(summary: summary) {
            os_signpost(.event, log: MetricsSubscriber.log, name: SignpostNames.shareInvoked)
            return [imageURL]
        }

        os_signpost(.event, log: MetricsSubscriber.log, name: SignpostNames.shareFallback)
        return [ResultsShareTextFormatter.string(inputs: inputs, result: result, unit: measurementUnit)]
    }

    /// Rasterizes the share card on the MainActor (ImageRenderer requirement), then
    /// encodes to PNG on the MainActor and offloads the file write to a detached task
    /// so the main thread is never blocked by disk I/O.
    @MainActor
    private func renderShareImageURL(summary: ResultsExportSummary) async -> URL? {
        let renderer = ImageRenderer(content: ShareableView(summary: summary))
        renderer.proposedSize = .init(width: 390, height: nil)
        renderer.scale = 3

        // ImageRenderer.uiImage must be accessed on the MainActor.
        // pngData() is kept here too — do NOT capture UIImage across the detached boundary.
        guard let image = renderer.uiImage, let pngData = image.pngData() else {
            return nil
        }

        // Offload only the disk write; Data and URL are Sendable.
        return await Task.detached(priority: .userInitiated) {
            do {
                let caches = try FileManager.default.url(
                    for: .cachesDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: true
                )
                let directory = caches.appendingPathComponent("ShareExports", isDirectory: true)
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                let fileURL = directory.appendingPathComponent("knitting-gauge-results.png")
                try pngData.write(to: fileURL, options: [.atomic])
                return fileURL
            } catch {
                return nil as URL?
            }
        }.value
    }
}

// MARK: - VerdictHelpSheet

private struct VerdictHelpSheet: View {
    var title: String
    var explanation: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HelpSheetHeader(closeIdentifier: "verdict-help-close") { dismiss() }
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(AppTheme.sage)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    Text(explanation)
                        .font(.body)
                        .lineSpacing(4)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityIdentifier("verdict-help-sheet")
        }
        .background(AppTheme.background.ignoresSafeArea())
    }
}

// MARK: - AboutHelpSheet

private struct AboutHelpSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HelpSheetHeader(closeIdentifier: "about-help-close") { dismiss() }
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("About this calculator")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(AppTheme.sage)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    Text(
                        "This tool reconciles a two-axis gauge mismatch, " +
                        "the kind that single-number gauge calculators hide. " +
                        "When your stitch gauge matches the pattern " +
                        "but your row gauge is off (or vice versa), every vertical " +
                        "section ends up the wrong length unless you adjust the row counts."
                    )
                        .font(.body)
                        .lineSpacing(4)
                        .foregroundStyle(AppTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(
                        "The math is deterministic: dimension correction = pattern_row / your_row. " +
                        "A denser swatch means fewer " +
                        "centimetres are needed to reach the pattern's intended row count; " +
                        "stitch_scale = pattern_st / your_st " +
                        "describes horizontal width."
                    )
                        .font(.body)
                        .lineSpacing(4)
                        .foregroundStyle(AppTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(
                        "Scope: This tool provides estimates based on your swatch measurements. " +
                        "Always test a full-size gauge " +
                        "swatch (washed and blocked the way you'll wash and block the finished garment) " +
                        "before starting your " +
                        "project. Numbers here are a starting point; your finished piece is the final word."
                    )
                        .font(.body.weight(.semibold))
                        .lineSpacing(4)
                        .foregroundStyle(AppTheme.warningText)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.warningBackground)
                        .overlay(alignment: .leading) {
                            Rectangle()
                                .frame(width: 3)
                                .foregroundStyle(AppTheme.warningAccent)
                                .accessibilityHidden(true)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .accessibilityIdentifier("about-scope")
                    Text(
                        "Not affiliated with Ravelry, Knit Companion, or any pattern designer." +
                        " Gauge math is conventional knitting arithmetic from open craft literature."
                    )
                        .font(.footnote.italic())
                        .lineSpacing(3)
                        .foregroundStyle(AppTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("about-non-affiliation")
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityIdentifier("about-help-sheet")
        }
        .background(AppTheme.background.ignoresSafeArea())
    }
}

// MARK: - HelpSheetHeader

/// Custom drag-handle-friendly header for help sheets. Avoids the
/// NavigationStack-in-sheet anti-pattern (#24) while providing a 44×44pt
/// trailing Close button (#25) so VoiceOver users can dismiss the sheet
/// without relying on the drag indicator.
private struct HelpSheetHeader: View {
    let closeIdentifier: String
    let onClose: () -> Void

    var body: some View {
        HStack {
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .imageScale(.medium)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppTheme.sage)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Close")
            .accessibilityIdentifier(closeIdentifier)
        }
        .padding(.horizontal, 8)
        .padding(.top, 4)
    }
}
