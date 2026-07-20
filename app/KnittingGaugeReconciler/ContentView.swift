// swiftlint:disable file_length
import SwiftUI
import UIKit
import MetricKit
import os.signpost
// Components and Views are in separate files under Components/ and Views/

struct GaugeInputPresentation {
    let stitchMismatch: Bool
    let rowMismatch: Bool
    let stitchDelta: Double?
    let rowDelta: Double?
}

// swiftlint:disable:next type_body_length
struct ContentView: View {
    private static let defaults = GaugeTextDefaults()
    private static let sceneDraftActivityType = "com.stitchwise.scene-draft"

    // MARK: - Adaptive layout

    @Environment(\.scenePhase) private var scenePhase
    @ScaledMetric(relativeTo: .body) private var cardSpacing: CGFloat = 12

    // MARK: - State

    @State private var patternStitches = initialText("KGR_PS", defaultValue: "32")
    @State private var patternRows = initialText("KGR_PR", defaultValue: "24")
    @State private var yourStitches = initialText("KGR_YS", defaultValue: "32")
    @State private var yourRows = initialText("KGR_YR", defaultValue: "32")
    @State private var patternCastOn = initialText("KGR_CAST_ON", defaultValue: "")
    @State private var patternYoke = initialText("KGR_YOKE", defaultValue: "")
    @State private var patternBody = initialText("KGR_BODY", defaultValue: "")
    @State private var patternSleeve = initialText("KGR_SLEEVE", defaultValue: "")
    @State private var patternIncreases = initialText("KGR_INCREASES", defaultValue: "")
    @State private var patternDetailsExpanded = initialBool("KGR_SHOW_PATTERN_DETAILS")

    @State private var showFullMath = initialBool("KGR_SHOW_FULL_MATH")
    @State private var aboutHelp = AboutHelpState(
        isPresented: initialBool("KGR_SHOW_ABOUT_HELP")
    )
    @State private var driftBandSignpostFired = false
    @State private var resetSnapshot = GaugeFormDraft()
    @State private var canUndoReset = false
    @State private var focusedField: GaugeFormField?

    // MARK: - Persisted unit preference

    /// User's chosen measurement unit. Stored in UserDefaults; defaults to cm.
    /// INTERNAL MODEL IS ALWAYS CM — this controls display/entry conversion only.
    @AppStorage("measurementUnit") private var measurementUnit: MeasurementUnit = .centimeters

    // MARK: - Derived

    private var inputs: GaugeInputs? {
        formDraft.inputs
    }

    private var liveResult: GaugeMathResult? {
        Self.computeResult(inputs)
    }

    static func computeResult(_ inputs: GaugeInputs?) -> GaugeMathResult? {
        guard let inputs else { return nil }
        os_signpost(.begin, log: MetricsSubscriber.log, name: SignpostNames.compute)
        let result = GaugeMath.compute(inputs)
        os_signpost(.end, log: MetricsSubscriber.log, name: SignpostNames.compute)
        return result
    }

    static func inputPresentation(
        _ inputs: GaugeInputs?
    ) -> GaugeInputPresentation {
        guard let inputs else {
            return GaugeInputPresentation(
                stitchMismatch: false,
                rowMismatch: false,
                stitchDelta: nil,
                rowDelta: nil
            )
        }
        return GaugeInputPresentation(
            stitchMismatch: inputs.stitchMismatch,
            rowMismatch: inputs.rowMismatch,
            stitchDelta: inputs.yourStitches - inputs.patternStitches,
            rowDelta: inputs.yourRows - inputs.patternRows
        )
    }

    static func hasCastOnDrift(_ result: GaugeMathResult?) -> Bool {
        guard let drift = result?.castOnRoundingDriftPercent else { return false }
        return abs(drift) >= 3
    }

    // MARK: - Body

    var body: some View {
        navigationContent
            .userActivity(
                Self.sceneDraftActivityType,
                isActive: true,
                updateSceneRestorationActivity
            )
            .onContinueUserActivity(Self.sceneDraftActivityType, perform: restoreSceneDraft)
            .onChange(of: scenePhase, scenePhaseChanged)
    }

    private var navigationContent: some View {
        let inputPresentation = Self.inputPresentation(inputs)
        return NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: cardSpacing) {
                    ZStack(alignment: .leading) {
                        AppTheme.background
                        Text(GaugeFormContract.leadCopy)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                        .padding(.bottom, 8)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(.isStaticText)
                    .accessibilityIdentifier("gauge-lead")

                    GaugeInputsCard(
                        patternStitches: draftBinding($patternStitches, at: 0),
                        patternRows: draftBinding($patternRows, at: 1),
                        yourStitches: draftBinding($yourStitches, at: 2),
                        yourRows: draftBinding($yourRows, at: 3),
                        stitchMismatch: inputPresentation.stitchMismatch,
                        rowMismatch: inputPresentation.rowMismatch,
                        stitchDelta: inputPresentation.stitchDelta,
                        rowDelta: inputPresentation.rowDelta,
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
                        unit: measurementUnitBinding,
                        isExpanded: patternDetailsBinding,
                        validationMessages: validationMessages,
                        focusedField: $focusedField,
                        onSubmit: finishEditing
                    )
                    RequiredAdjustmentsCard(
                        result: liveResult,
                        inputs: inputs,
                        verdict: (title: verdictTitle, body: resultGuidanceBody),
                        unit: measurementUnit,
                        showFullMath: $showFullMath,
                        canUndoReset: canUndoReset,
                        onReset: resetToDefaults,
                        onUndoReset: undoReset,
                        onShare: shareItems
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
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
            .accessibilityHidden(aboutHelp.isPresented)
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
                    AboutHelpToolbarButton(state: $aboutHelp)
                }
            }
            .sheet(isPresented: $aboutHelp.isPresented, content: aboutHelpSheet)
            .onChange(of: aboutHelp.isPresented, helpPresentationChanged)
            .onChange(of: measurementUnit, measurementUnitChanged)
            .onChange(of: validationMessages, validationMessagesChanged)
            .onChange(of: verdictTitle, verdictChanged)
            .onChange(of: Self.hasCastOnDrift(liveResult), castOnDriftChanged)
        }
    }

    func aboutHelpSheet() -> some View {
        AboutHelpSheet {
            aboutHelp.close()
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    func castOnDriftChanged(_ oldValue: Bool, _ newValue: Bool) {
        driftVisibilityChanged(newValue)
    }

    func scenePhaseChanged(_ oldValue: ScenePhase, _ newValue: ScenePhase) {
        if newValue != .active {
            UserDefaults.standard.synchronize()
        }
    }

    func helpPresentationChanged(_ oldValue: Bool, _ newValue: Bool) {
        if newValue {
            os_signpost(.event, log: MetricsSubscriber.log, name: SignpostNames.sheetAboutHelpOpened)
        }
    }

    func measurementUnitChanged(_ previousUnit: MeasurementUnit, _ newUnit: MeasurementUnit) {
        reconcileSceneDraft(from: previousUnit, to: newUnit)
    }

    func validationMessagesChanged(
        _ previous: [GaugeFormField: String],
        _ current: [GaugeFormField: String]
    ) {
        announceValidation(previous: previous, current: current)
    }

    func announceValidation(
        previous: [GaugeFormField: String],
        current: [GaugeFormField: String],
        isVoiceOverRunning: Bool = UIAccessibility.isVoiceOverRunning
    ) {
        guard isVoiceOverRunning,
              let message = newValidationAnnouncement(previous: previous, current: current) else {
            return
        }
        UIAccessibility.post(notification: .announcement, argument: message)
    }

    func verdictChanged(_ oldValue: String, _ newValue: String) {
        let previous = oldValue.isEmpty ? nil : VerdictBucket(verdictTitle: oldValue)
        let current = newValue.isEmpty ? nil : VerdictBucket(verdictTitle: newValue)
        if let name = VerdictBucket.signpostName(
            previous: previous,
            current: current
        ) {
            os_signpost(.event, log: MetricsSubscriber.log, name: name)
        }
    }

    func driftVisibilityChanged(_ isVisible: Bool) {
        if isVisible, !driftBandSignpostFired {
            os_signpost(.event, log: MetricsSubscriber.log, name: SignpostNames.castOnDriftBandShown)
            driftBandSignpostFired = true
        } else if !isVisible {
            driftBandSignpostFired = false
        }
    }

    // MARK: - Verdict

    private var verdictTitle: String {
        Self.verdictTitle(inputs: inputs, result: liveResult)
    }

    private var resultGuidanceBody: String {
        Self.resultGuidanceBody(inputs: inputs, result: liveResult)
    }

    static func verdictTitle(inputs: GaugeInputs?, result: GaugeMathResult?) -> String {
        guard inputs != nil, let result else { return "" }
        return ContentView().verdictTitleComputed(result: result)
    }

    static func resultGuidanceBody(inputs: GaugeInputs?, result: GaugeMathResult?) -> String {
        guard let result, let inputs else {
            return "Correct the highlighted fields before viewing gauge guidance."
        }
        return ContentView().verdictBodyComputed(result: result, inputs: inputs)
    }

    func verdictTitleComputed(result: GaugeMathResult) -> String {
        let stitchDrift = abs(result.stitchWidthScale - 1)
        let rowDrift = abs(result.rowCountScale - 1)
        let stitchMatches = isGaugeMatch(scale: result.stitchWidthScale)
        let rowMatches = isGaugeMatch(scale: result.rowCountScale)
        if stitchMatches, rowMatches { return "Gauge match" }
        if isMajorDrift(stitchDrift) || isMajorDrift(rowDrift) { return "Major mismatch" }
        let stitchOffRange = !stitchMatches && stitchDrift < 0.15
        let rowOffRange = !rowMatches && rowDrift < 0.15
        if stitchOffRange && rowOffRange { return "Significant drift" }
        return "Drift"
    }

    func verdictBodyComputed(result: GaugeMathResult, inputs: GaugeInputs) -> String {
        let stitchDrift   = abs(result.stitchWidthScale - 1)
        let rowDrift      = abs(result.rowCountScale - 1)
        let stitchPercent = abs(GaugeMath.fmtPct(result.stitchWidthScale) - 100)
        let rowPercent    = abs(GaugeMath.fmtPct(result.rowCountScale) - 100)
        let stitchOff = !isGaugeMatch(scale: result.stitchWidthScale)
        let rowOff    = !isGaugeMatch(scale: result.rowCountScale)
        let stitchDir = result.stitchWidthScale > 1 ? "wider" : "narrower"
        let rowDir    = result.rowCountScale > 1 ? "denser" : "looser"
        let sectionDir = result.rowCountScale > 1 ? "shorter" : "longer"
        let majorNote = (isMajorDrift(stitchDrift) || isMajorDrift(rowDrift))
            ? " At least 15% drift. Consider re-swatching or changing needle size before proceeding."
            : ""
        let castOnGuidance = castOnGuidance(result: result, inputs: inputs)
        let stitchAction = if inputs.patternCastOn == nil {
            "If you want an adjusted cast-on count, add the pattern cast-on in Pattern details. "
        } else if result.adjustedCastOn == nil {
            "No usable whole-stitch cast-on can be calculated from these values. " +
                "Re-swatch before proceeding. "
        } else {
            "Use the cast-on guidance below to preserve the intended width. "
        }
        let hasSectionTargets = inputs.patternYokeDepth != nil ||
            inputs.patternBodyLength != nil ||
            inputs.patternSleeveLength != nil
        let rowAction = hasSectionTargets
            ? "Use the adjusted depth guidance below; pattern row counts stay unchanged."
            : "Open Pattern details and enter section targets for adjusted depth guidance."
        if !stitchOff && !rowOff {
            return "Both gauges are within the match range. \(castOnGuidance)" +
                "Re-check after blocking."
        }
        if stitchOff && !rowOff {
            return (
                "Your row gauge is within the match range. At the pattern stitch counts, the garment will be " +
                "\(stitchPercent)% \(stitchDir). \(stitchAction)" +
                "Vertical sections remain within the match range.\(majorNote)"
            )
        }
        if !stitchOff {
            return (
                "Your stitch gauge matches. \(castOnGuidance)" +
                "Your row gauge is \(rowPercent)% \(rowDir) than expected. At the pattern row counts, " +
                "vertical sections will be \(sectionDir). \(rowAction)\(majorNote)"
            )
        }
        return (
            "Both axes are off. At the pattern stitch counts, the garment will be \(stitchPercent)% \(stitchDir). " +
            "\(stitchAction)Your row gauge is \(rowPercent)% \(rowDir) than expected. At the pattern row counts, " +
            "vertical sections will be \(sectionDir). \(rowAction)\(majorNote)"
        )
    }

    private func castOnGuidance(result: GaugeMathResult, inputs: GaugeInputs) -> String {
        castOnGuidanceText(inputs: inputs, result: result).map { $0 + " " } ?? ""
    }

    // MARK: - Validation

    var rawTextValues: [String] {
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

    var formDraft: GaugeFormDraft {
        GaugeFormDraft(
            values: rawTextValues,
            unit: measurementUnit,
            patternDetailsExpanded: patternDetailsExpanded,
            focusedField: focusedField
        )
    }

    func draftBinding(_ binding: Binding<String>, at index: Int) -> Binding<String> {
        Binding(
            get: { binding.wrappedValue },
            set: { newValue in
                guard newValue != binding.wrappedValue else { return }
                var values = rawTextValues
                values[index] = newValue
                binding.wrappedValue = newValue
                resetResultMetrics()
            }
        )
    }

    var patternDetailsBinding: Binding<Bool> {
        Binding(
            get: { patternDetailsExpanded },
            set: { newValue in
                guard newValue != patternDetailsExpanded else { return }
                patternDetailsExpanded = newValue
            }
        )
    }

    var measurementUnitBinding: Binding<MeasurementUnit> {
        Binding(
            get: { measurementUnit },
            set: { newUnit in
                guard newUnit != measurementUnit else { return }
                let previousUnit = measurementUnit
                measurementUnit = newUnit
                reconcileSceneDraft(from: previousUnit, to: newUnit)
            }
        )
    }

    func reconcileSceneDraft(
        from previousUnit: MeasurementUnit,
        to newUnit: MeasurementUnit
    ) {
        guard previousUnit == .inches, newUnit == .centimeters else { return }
        let values = SceneDraftStore.reconcileInvalidInchProvenance(in: rawTextValues, for: newUnit)
        applySceneDraft(values: values, disclosure: patternDetailsExpanded)
    }

    private var validationMessages: [GaugeFormField: String] {
        formDraft.validationMessages
    }

    func finishEditing() {
        var draft = formDraft
        _ = draft.finishEditing()
        patternDetailsBinding.wrappedValue = draft.patternDetailsExpanded
        focusedField = draft.focusedField
    }

    // MARK: - Scene restoration

    func updateSceneRestorationActivity(_ activity: NSUserActivity) {
        let draft: [String: Any] = [
            SceneDraftStore.rawValuesKey: rawTextValues,
            SceneDraftStore.disclosureKey: patternDetailsExpanded,
        ]
        activity.addUserInfoEntries(from: draft)
    }

    func restoreSceneDraft(_ activity: NSUserActivity) {
        guard let userInfo = activity.userInfo,
              let draft = SceneDraftStore.deserialize(userInfo) else {
            return
        }
        applySceneDraft(values: draft.values, disclosure: draft.disclosure)
    }

    func applySceneDraft(
        values: [String],
        disclosure: Bool,
        synchronizingDefaults: Bool = false
    ) {
        let values = SceneDraftStore.reconcileInvalidInchProvenance(
            in: values,
            for: measurementUnit
        )
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
        resetResultMetrics()
        if synchronizingDefaults {
            UserDefaults.standard.synchronize()
        }
    }

    // MARK: - Actions

    func resetToDefaults() {
        var draft = formDraft
        resetSnapshot = draft.reset()
        canUndoReset = true
        os_signpost(.event, log: MetricsSubscriber.log, name: SignpostNames.resetTapped)
        applySceneDraft(
            values: draft.rawValues,
            disclosure: draft.patternDetailsExpanded,
            synchronizingDefaults: true
        )
        focusedField = nil
        showFullMath = false
    }

    func undoReset() {
        var draft = formDraft
        draft.restore(resetSnapshot)
        canUndoReset = false
        applySceneDraft(
            values: draft.rawValues,
            disclosure: draft.patternDetailsExpanded,
            synchronizingDefaults: true
        )
        focusedField = nil
        showFullMath = false
    }

    private func resetResultMetrics() {
        driftBandSignpostFired = false
    }

    @MainActor
    func shareItems(for result: GaugeMathResult) async -> [Any] {
        await Self.shareItems(
            for: result,
            inputs: inputs,
            unit: measurementUnit
        )
    }

    @MainActor
    static func shareItems(
        for result: GaugeMathResult,
        inputs: GaugeInputs?,
        unit: MeasurementUnit,
        exportDirectory: URL? = nil
    ) async -> [Any] {
        guard let inputs else { return [] }
        let summary = ResultsExportSummary(inputs: inputs, result: result, unit: unit)
        if let imageURL = await renderShareImageURL(
            summary: summary,
            exportDirectory: exportDirectory
        ) {
            os_signpost(.event, log: MetricsSubscriber.log, name: SignpostNames.shareInvoked)
            return [imageURL]
        }

        os_signpost(.event, log: MetricsSubscriber.log, name: SignpostNames.shareFallback)
        return [ResultsShareTextFormatter.string(inputs: inputs, result: result, unit: unit)]
    }

    /// Rasterizes and encodes the share card on the MainActor, then offloads the file
    /// write to a detached task so the main thread is never blocked by disk I/O.
    @MainActor
    static func renderShareImageURL(
        summary: ResultsExportSummary,
        exportDirectory: URL? = nil
    ) async -> URL? {
        let pngData = ShareableView.pngData(summary: summary)
        return await Task.detached(priority: .userInitiated) {
            do {
                let directory = try exportDirectory ?? FileManager.default.url(
                    for: .cachesDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: true
                ).appendingPathComponent("ShareExports", isDirectory: true)
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                let fileURL = directory.appendingPathComponent("knitting-gauge-results-\(UUID().uuidString).png")
                try pngData.write(to: fileURL, options: [.atomic])
                return fileURL
            } catch {
                return nil as URL?
            }
        }.value
    }
}

// MARK: - AboutHelpSheet

struct AboutHelpSheet: View {
    private let onClose: () -> Void

    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }

    var body: some View {
        VStack(spacing: 0) {
            HelpSheetHeader(closeIdentifier: AboutHelpContract.closeIdentifier) {
                onClose()
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(AboutHelpContract.openLabel)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(AppTheme.sage)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    Text(AboutHelpContract.explanation)
                        .font(.body)
                        .lineSpacing(4)
                        .foregroundStyle(AppTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(AboutHelpContract.math)
                        .font(.body)
                        .lineSpacing(4)
                        .foregroundStyle(AppTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(AboutHelpContract.scope)
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
                    Text(AboutHelpContract.nonAffiliation)
                        .font(.footnote.italic())
                        .lineSpacing(3)
                        .foregroundStyle(AppTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("about-non-affiliation")
                    Text("Privacy")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(AppTheme.sage)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    Text(AboutHelpContract.privacy)
                        .font(.body)
                        .lineSpacing(4)
                        .foregroundStyle(AppTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityIdentifier(AboutHelpContract.sheetIdentifier)
        }
        .background(AppTheme.background.ignoresSafeArea())
    }
}

// MARK: - HelpSheetHeader

/// Custom drag-handle-friendly header for help sheets. Avoids the
/// NavigationStack-in-sheet anti-pattern (#24) while providing a 44×44pt
/// trailing Close button (#25) so VoiceOver users can dismiss the sheet
/// without relying on the drag indicator.
struct HelpSheetHeader: View {
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
                    .frame(width: AboutHelpContract.closeHitTarget, height: AboutHelpContract.closeHitTarget)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel(AboutHelpContract.closeLabel)
            .accessibilityIdentifier(closeIdentifier)
        }
        .padding(.horizontal, 8)
        .padding(.top, 4)
    }
}
