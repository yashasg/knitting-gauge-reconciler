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

struct GaugeLeadView: View {
    var body: some View {
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
    }
}

private final class ResetSnapshot {
    var draft: GaugeFormDraft?
}

struct SceneDraftLifecycleModifier: ViewModifier {
    let isEnabled: Bool
    let activityType: String
    let update: (NSUserActivity) -> Void
    let restore: (NSUserActivity) -> Void

    @ViewBuilder
    func body(content: Content) -> some View {
        modifiedContent(content)
    }

    @ViewBuilder
    func modifiedContent<Content: View>(_ content: Content) -> some View {
        if isEnabled {
            content
                .userActivity(activityType, isActive: true, update)
                .onContinueUserActivity(activityType, perform: restore)
        } else {
            content
        }
    }
}

// swiftlint:disable:next type_body_length
struct ContentView: View {
    private static let sceneDraftActivityType = "com.stitchwise.scene-draft"
    private let sceneLifecycleEnabled: Bool

    // MARK: - Adaptive layout

    @ScaledMetric(relativeTo: .body) private var cardSpacing: CGFloat = 12

    // MARK: - State

    @State private var patternStitches = GaugeTextDefaults().patternStitches
    @State private var patternRows = GaugeTextDefaults().patternRows
    @State private var yourStitches = GaugeTextDefaults().yourStitches
    @State private var yourRows = GaugeTextDefaults().yourRows
    @State private var patternCastOn = ""
    @State private var patternYoke = ""
    @State private var patternBody = ""
    @State private var patternSleeve = ""
    @State private var patternIncreases = ""
    @State private var patternDetailsExpanded = false

    @State private var showFullMath = false
    @State private var aboutHelp = AboutHelpState()
    @State private var resetSnapshot = ResetSnapshot()
    @State private var canUndoReset = false
    @State private var focusedField: GaugeFormField?

    // MARK: - Persisted unit preference

    /// User's chosen measurement unit. Stored in UserDefaults; defaults to cm.
    /// INTERNAL MODEL IS ALWAYS CM — this controls display/entry conversion only.
    @AppStorage("measurementUnit") private var measurementUnit: MeasurementUnit = .centimeters

    init(sceneLifecycleEnabled: Bool = true) {
        self.sceneLifecycleEnabled = sceneLifecycleEnabled
    }

    // MARK: - Derived

    private var inputs: GaugeInputs? {
        formDraft.inputs
    }

    private var liveResult: GaugeMathResult? {
        Self.computeResult(inputs)
    }

    static func computeResult(_ inputs: GaugeInputs?) -> GaugeMathResult? {
        guard let inputs else { return nil }
        os_signpost(.begin, log: SignpostNames.log, name: SignpostNames.compute)
        let result = GaugeMath.compute(inputs)
        os_signpost(.end, log: SignpostNames.log, name: SignpostNames.compute)
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
            .modifier(
                SceneDraftLifecycleModifier(
                    isEnabled: sceneLifecycleEnabled,
                    activityType: Self.sceneDraftActivityType,
                    update: updateSceneRestorationActivity,
                    restore: restoreSceneDraft
                )
            )
    }

    private var navigationContent: some View {
        let inputPresentation = Self.inputPresentation(inputs)
        let aboutSheet = SheetContentProvider(
            content: Self.aboutHelpSheet(state: $aboutHelp)
        )
        return NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: cardSpacing) {
                    GaugeLeadView()

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
            .sheet(isPresented: $aboutHelp.isPresented, content: aboutSheet.contentView)
            .onChange(of: aboutHelp.isPresented, helpPresentationChanged)
            .onChange(of: measurementUnit, measurementUnitChanged)
            .onChange(of: validationMessages, validationMessagesChanged)
            .onChange(of: verdictTitle, verdictChanged)
            .onChange(of: Self.hasCastOnDrift(liveResult), castOnDriftChanged)
        }
    }

    static func aboutHelpSheet(state: Binding<AboutHelpState>) -> some View {
        AboutHelpSheet(state: state)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    func castOnDriftChanged(_ oldValue: Bool, _ newValue: Bool) {
        if let name = Self.driftBandSignpostName(previous: oldValue, current: newValue) {
            os_signpost(.event, log: SignpostNames.log, name: name)
        }
    }

    static func helpSignpostName(previous: Bool, current: Bool) -> StaticString? {
        !previous && current ? SignpostNames.sheetAboutHelpOpened : nil
    }

    func helpPresentationChanged(_ oldValue: Bool, _ newValue: Bool) {
        if let name = Self.helpSignpostName(previous: oldValue, current: newValue) {
            os_signpost(.event, log: SignpostNames.log, name: name)
        }
    }

    func measurementUnitChanged(_ previousUnit: MeasurementUnit, _ newUnit: MeasurementUnit) {
        reconcileSceneDraft(from: previousUnit, to: newUnit)
    }

    func validationMessagesChanged(
        _ previous: [GaugeFormField: String],
        _ current: [GaugeFormField: String]
    ) {
        validationMessagesChanged(
            previous,
            current,
            isVoiceOverRunning: UIAccessibility.isVoiceOverRunning
        )
    }

    @discardableResult
    func validationMessagesChanged(
        _ previous: [GaugeFormField: String],
        _ current: [GaugeFormField: String],
        isVoiceOverRunning: Bool
    ) -> String? {
        guard let message = Self.validationAnnouncement(
            previous: previous,
            current: current,
            isVoiceOverRunning: isVoiceOverRunning
        ) else { return nil }
        UIAccessibility.post(notification: .announcement, argument: message)
        return message
    }

    static func validationAnnouncement(
        previous: [GaugeFormField: String],
        current: [GaugeFormField: String],
        isVoiceOverRunning: Bool
    ) -> String? {
        guard isVoiceOverRunning else { return nil }
        return newValidationAnnouncement(previous: previous, current: current)
    }

    static func verdictSignpostName(
        previous oldValue: String,
        current newValue: String
    ) -> StaticString? {
        let previous = oldValue.isEmpty ? nil : VerdictBucket(verdictTitle: oldValue)
        let current = newValue.isEmpty ? nil : VerdictBucket(verdictTitle: newValue)
        return VerdictBucket.signpostName(
            previous: previous,
            current: current
        )
    }

    func verdictChanged(_ oldValue: String, _ newValue: String) {
        if let name = Self.verdictSignpostName(previous: oldValue, current: newValue) {
            os_signpost(.event, log: SignpostNames.log, name: name)
        }
    }

    static func driftBandSignpostName(previous: Bool, current: Bool) -> StaticString? {
        !previous && current ? SignpostNames.castOnDriftBandShown : nil
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
                binding.wrappedValue = newValue
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

    static func reconciledSceneDraft(
        values: [String],
        from previousUnit: MeasurementUnit,
        to newUnit: MeasurementUnit
    ) -> [String]? {
        guard previousUnit == .inches, newUnit == .centimeters else { return nil }
        return SceneDraftStore.reconcileInvalidInchProvenance(in: values, for: newUnit)
    }

    @discardableResult
    func reconcileSceneDraft(
        from previousUnit: MeasurementUnit,
        to newUnit: MeasurementUnit
    ) -> [String]? {
        guard let values = Self.reconciledSceneDraft(
            values: rawTextValues,
            from: previousUnit,
            to: newUnit
        ) else { return nil }
        applySceneDraft(values: values, disclosure: patternDetailsExpanded)
        return values
    }

    private var validationMessages: [GaugeFormField: String] {
        formDraft.validationMessages
    }

    func finishEditing() {
        var draft = formDraft
        Self.finishEditing(&draft)
        patternDetailsBinding.wrappedValue = draft.patternDetailsExpanded
        focusedField = draft.focusedField
    }

    static func finishEditing(_ draft: inout GaugeFormDraft) {
        let message = draft.finishEditing()
        if let message {
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }

    // MARK: - Scene restoration

    func updateSceneRestorationActivity(_ activity: NSUserActivity) {
        let draft = SceneDraftStore.serialize(
            values: rawTextValues,
            disclosure: patternDetailsExpanded
        )
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
        if synchronizingDefaults {
            UserDefaults.standard.synchronize()
        }
    }

    // MARK: - Actions

    func resetToDefaults() {
        var draft = formDraft
        resetSnapshot.draft = draft.reset()
        canUndoReset = true
        os_signpost(.event, log: SignpostNames.log, name: SignpostNames.resetTapped)
        applySceneDraft(
            values: draft.rawValues,
            disclosure: draft.patternDetailsExpanded,
            synchronizingDefaults: true
        )
        focusedField = nil
        showFullMath = false
    }

    func undoReset() {
        guard let snapshot = resetSnapshot.draft else { return }
        var draft = formDraft
        draft.restore(snapshot)
        resetSnapshot.draft = nil
        canUndoReset = false
        applySceneDraft(
            values: draft.rawValues,
            disclosure: draft.patternDetailsExpanded,
            synchronizingDefaults: true
        )
        focusedField = nil
        showFullMath = false
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
            os_signpost(.event, log: SignpostNames.log, name: SignpostNames.shareInvoked)
            return [imageURL]
        }

        os_signpost(.event, log: SignpostNames.log, name: SignpostNames.shareFallback)
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
    @Binding private var state: AboutHelpState

    init(state: Binding<AboutHelpState>) {
        _state = state
    }

    func close() {
        state.close()
    }

    var body: some View {
        VStack(spacing: 0) {
            HelpSheetHeader(onClose: close)
            ScrollView {
                AboutHelpContent()
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
    }
}

struct AboutHelpContent: View {
    var body: some View {
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
            Text(AboutHelpContract.nonAffiliation)
                .font(.footnote.italic())
                .lineSpacing(3)
                .foregroundStyle(AppTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
            Text(AboutHelpContract.privacyHeading)
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
}

// MARK: - HelpSheetHeader

/// Custom drag-handle-friendly header for help sheets. Avoids the
/// NavigationStack-in-sheet anti-pattern (#24) while providing a 44×44pt
/// trailing Close button (#25) so VoiceOver users can dismiss the sheet
/// without relying on the drag indicator.
struct HelpSheetHeader: View {
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
        }
        .padding(.horizontal, 8)
        .padding(.top, 4)
    }
}
