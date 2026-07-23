// swiftlint:disable file_length
import SwiftUI
import UIKit
import MetricKit
import os.signpost
// Components and Views are in separate files under Components/ and Views/

enum SignpostNames {
    static let log: OSLog = MXMetricManager.makeLogHandle(category: "user_actions")
    static let compute: StaticString = "compute"
    static let shareInvoked: StaticString = "share.invoked"
    static let shareFallback: StaticString = "share.fallback"
    static let resetTapped: StaticString = "reset.tapped"
    static let sheetAboutHelpOpened: StaticString = "sheet.aboutHelp.opened"
    static let castOnDriftBandShown: StaticString = "cast_on.driftBandShown"
}

struct GaugeInputPresentation {
    let stitchMismatch: Bool
    let rowMismatch: Bool
    let stitchDelta: Double?
    let rowDelta: Double?
}

private final class ResetSnapshot {
    var draft: GaugeFormDraft?
    var revealedValidationFields: Set<GaugeFormField> = []
}

struct ContentView: View {
    private let sceneStorageEnabled: Bool

    @SceneStorage(SceneDraftStore.patternStitchesKey)
    private var patternStitches = GaugeTextDefaults().patternStitches
    @SceneStorage(SceneDraftStore.patternRowsKey)
    private var patternRows = GaugeTextDefaults().patternRows
    @SceneStorage(SceneDraftStore.yourStitchesKey)
    private var yourStitches = GaugeTextDefaults().yourStitches
    @SceneStorage(SceneDraftStore.yourRowsKey)
    private var yourRows = GaugeTextDefaults().yourRows
    @SceneStorage(SceneDraftStore.patternCastOnKey) private var patternCastOn = ""
    @SceneStorage(SceneDraftStore.patternYokeKey) private var patternYoke = ""
    @SceneStorage(SceneDraftStore.patternBodyKey) private var patternBody = ""
    @SceneStorage(SceneDraftStore.patternSleeveKey) private var patternSleeve = ""
    @SceneStorage(SceneDraftStore.patternIncreasesKey) private var patternIncreases = ""
    @SceneStorage(SceneDraftStore.disclosureKey) private var patternDetailsExpanded = false

    /// User's chosen measurement unit. Stored in UserDefaults; defaults to cm.
    @AppStorage("measurementUnit") private var measurementUnit: MeasurementUnit = .centimeters

    init(sceneStorageEnabled: Bool = true) {
        self.sceneStorageEnabled = sceneStorageEnabled
    }

    var body: some View {
        let defaults = GaugeTextDefaults()
        GaugeFormView(
            patternStitches: Binding(
                get: { sceneStorageEnabled ? patternStitches : defaults.patternStitches },
                set: { if sceneStorageEnabled { patternStitches = $0 } }
            ),
            patternRows: Binding(
                get: { sceneStorageEnabled ? patternRows : defaults.patternRows },
                set: { if sceneStorageEnabled { patternRows = $0 } }
            ),
            yourStitches: Binding(
                get: { sceneStorageEnabled ? yourStitches : defaults.yourStitches },
                set: { if sceneStorageEnabled { yourStitches = $0 } }
            ),
            yourRows: Binding(
                get: { sceneStorageEnabled ? yourRows : defaults.yourRows },
                set: { if sceneStorageEnabled { yourRows = $0 } }
            ),
            patternCastOn: Binding(
                get: { sceneStorageEnabled ? patternCastOn : "" },
                set: { if sceneStorageEnabled { patternCastOn = $0 } }
            ),
            patternYoke: Binding(
                get: { sceneStorageEnabled ? patternYoke : "" },
                set: { if sceneStorageEnabled { patternYoke = $0 } }
            ),
            patternBody: Binding(
                get: { sceneStorageEnabled ? patternBody : "" },
                set: { if sceneStorageEnabled { patternBody = $0 } }
            ),
            patternSleeve: Binding(
                get: { sceneStorageEnabled ? patternSleeve : "" },
                set: { if sceneStorageEnabled { patternSleeve = $0 } }
            ),
            patternIncreases: Binding(
                get: { sceneStorageEnabled ? patternIncreases : "" },
                set: { if sceneStorageEnabled { patternIncreases = $0 } }
            ),
            patternDetailsExpanded: Binding(
                get: { sceneStorageEnabled ? patternDetailsExpanded : false },
                set: { if sceneStorageEnabled { patternDetailsExpanded = $0 } }
            ),
            measurementUnit: Binding(
                get: { sceneStorageEnabled ? measurementUnit : .centimeters },
                set: { if sceneStorageEnabled { measurementUnit = $0 } }
            )
        )
    }
}

// swiftlint:disable:next type_body_length
struct GaugeFormView: View {
    // MARK: - Adaptive layout

    @ScaledMetric(relativeTo: .body) private var cardSpacing: CGFloat = 12

    // MARK: - State

    @Binding private var patternStitches: String
    @Binding private var patternRows: String
    @Binding private var yourStitches: String
    @Binding private var yourRows: String
    @Binding private var patternCastOn: String
    @Binding private var patternYoke: String
    @Binding private var patternBody: String
    @Binding private var patternSleeve: String
    @Binding private var patternIncreases: String
    @Binding private var patternDetailsExpanded: Bool
    @Binding private var measurementUnit: MeasurementUnit

    @State private var showFullMath = false
    @State private var aboutHelp = AboutHelpState()
    @State private var resetSnapshot = ResetSnapshot()
    @State private var canUndoReset = false
    @State private var focusedField: GaugeFormField?
    @State private var revealedValidationFields: Set<GaugeFormField> = []

    init(
        patternStitches: Binding<String>,
        patternRows: Binding<String>,
        yourStitches: Binding<String>,
        yourRows: Binding<String>,
        patternCastOn: Binding<String>,
        patternYoke: Binding<String>,
        patternBody: Binding<String>,
        patternSleeve: Binding<String>,
        patternIncreases: Binding<String>,
        patternDetailsExpanded: Binding<Bool>,
        measurementUnit: Binding<MeasurementUnit>
    ) {
        _patternStitches = patternStitches
        _patternRows = patternRows
        _yourStitches = yourStitches
        _yourRows = yourRows
        _patternCastOn = patternCastOn
        _patternYoke = patternYoke
        _patternBody = patternBody
        _patternSleeve = patternSleeve
        _patternIncreases = patternIncreases
        _patternDetailsExpanded = patternDetailsExpanded
        _measurementUnit = measurementUnit
    }

    // MARK: - Derived

    private var inputs: GaugeInputs? {
        formDraft.inputs
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
        let currentInputs = inputs
        let currentResult = Self.computeResult(currentInputs)
        return navigationContent(
            currentInputs: currentInputs,
            currentResult: currentResult
        )
    }

    // swiftlint:disable:next function_body_length
    private func navigationContent(
        currentInputs: GaugeInputs?,
        currentResult: GaugeMathResult?
    ) -> some View {
        let inputPresentation = Self.inputPresentation(currentInputs)
        let aboutSheet = SheetContentProvider(
            content: Self.aboutHelpSheet(state: $aboutHelp)
        )
        return NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: cardSpacing) {
                    GaugeInputsCard(
                        patternStitches: draftBinding(for: .patternStitches),
                        patternRows: draftBinding(for: .patternRows),
                        yourStitches: draftBinding(for: .yourStitches),
                        yourRows: draftBinding(for: .yourRows),
                        unit: measurementUnitBinding,
                        stitchMismatch: inputPresentation.stitchMismatch,
                        rowMismatch: inputPresentation.rowMismatch,
                        stitchDelta: inputPresentation.stitchDelta,
                        rowDelta: inputPresentation.rowDelta,
                        validationMessages: validationMessages,
                        focusedField: $focusedField,
                    )
                    PatternInstructionsCard(
                        patternCastOn: draftBinding(for: .patternCastOn),
                        patternYoke: draftBinding(for: .patternYoke),
                        patternBody: draftBinding(for: .patternBody),
                        patternSleeve: draftBinding(for: .patternSleeve),
                        patternIncreases: draftBinding(for: .patternIncreases),
                        unit: measurementUnitBinding,
                        isExpanded: patternDetailsBinding,
                        validationMessages: validationMessages,
                        focusedField: $focusedField,
                    )
                    RequiredAdjustmentsCard(
                        result: currentResult,
                        inputs: currentInputs,
                        correctionMessage: firstValidationMessage,
                        unit: measurementUnit,
                        showFullMath: $showFullMath,
                        canUndoReset: canUndoReset,
                        onCorrect: finishEditing,
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
            .onChange(of: focusedField, fieldFocusChanged)
            .onChange(of: Self.hasCastOnDrift(currentResult), castOnDriftChanged)
            .onAppear(perform: sceneDidAppear)
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

    func fieldFocusChanged(_ previousField: GaugeFormField?, _ currentField: GaugeFormField?) {
        guard let previousField, previousField != currentField else { return }
        revealedValidationFields.insert(previousField)
    }

    func sceneDidAppear() {
        let values = formValues
        let reconciledValues = SceneDraftStore.reconcileInvalidInchProvenance(
            in: values,
            for: measurementUnit
        )
        if reconciledValues != values {
            applySceneDraft(values: reconciledValues, disclosure: patternDetailsExpanded)
        }
    }

    static func driftBandSignpostName(previous: Bool, current: Bool) -> StaticString? {
        !previous && current ? SignpostNames.castOnDriftBandShown : nil
    }

    // MARK: - Validation

    var formValues: GaugeFormValues {
        GaugeFormValues(
            patternStitches: patternStitches,
            patternRows: patternRows,
            yourStitches: yourStitches,
            yourRows: yourRows,
            patternCastOn: patternCastOn,
            patternYoke: patternYoke,
            patternBody: patternBody,
            patternSleeve: patternSleeve,
            patternIncreases: patternIncreases
        )
    }

    var formDraft: GaugeFormDraft {
        GaugeFormDraft(
            values: formValues,
            unit: measurementUnit,
            patternDetailsExpanded: patternDetailsExpanded,
            focusedField: focusedField
        )
    }

    func draftBinding(for field: GaugeFormField) -> Binding<String> {
        let keyPath = field.valueKeyPath
        return Binding(
            get: { formValues[keyPath: keyPath] },
            set: { newValue in
                guard newValue != formValues[keyPath: keyPath] else { return }
                switch field {
                case .patternStitches: patternStitches = newValue
                case .patternRows: patternRows = newValue
                case .yourStitches: yourStitches = newValue
                case .yourRows: yourRows = newValue
                case .patternCastOn: patternCastOn = newValue
                case .patternYoke: patternYoke = newValue
                case .patternBody: patternBody = newValue
                case .patternSleeve: patternSleeve = newValue
                case .patternIncreases: patternIncreases = newValue
                }
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
                measurementUnit = newUnit
            }
        )
    }

    static func reconciledSceneDraft(
        values: GaugeFormValues,
        from previousUnit: MeasurementUnit,
        to newUnit: MeasurementUnit
    ) -> GaugeFormValues? {
        guard previousUnit == .inches, newUnit == .centimeters else { return nil }
        return SceneDraftStore.reconcileInvalidInchProvenance(in: values, for: newUnit)
    }

    @discardableResult
    func reconcileSceneDraft(
        from previousUnit: MeasurementUnit,
        to newUnit: MeasurementUnit
    ) -> GaugeFormValues? {
        guard let values = Self.reconciledSceneDraft(
            values: formValues,
            from: previousUnit,
            to: newUnit
        ) else { return nil }
        applySceneDraft(values: values, disclosure: patternDetailsExpanded)
        return values
    }

    private var validationMessages: [GaugeFormField: String] {
        formDraft.validationMessages.filter { revealedValidationFields.contains($0.key) }
    }

    private var firstValidationMessage: String? {
        GaugeFormField.allCases.lazy.compactMap { validationMessages[$0] }.first
    }

    func finishEditing() {
        var draft = formDraft
        revealedValidationFields.formUnion(draft.validationMessages.keys)
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

    func applySceneDraft(
        values: GaugeFormValues,
        disclosure: Bool
    ) {
        let values = SceneDraftStore.reconcileInvalidInchProvenance(
            in: values,
            for: measurementUnit
        )
        patternStitches = values.patternStitches
        patternRows = values.patternRows
        yourStitches = values.yourStitches
        yourRows = values.yourRows
        patternCastOn = values.patternCastOn
        patternYoke = values.patternYoke
        patternBody = values.patternBody
        patternSleeve = values.patternSleeve
        patternIncreases = values.patternIncreases
        patternDetailsExpanded = disclosure
    }

    // MARK: - Actions

    func resetToDefaults() {
        var draft = formDraft
        resetSnapshot.draft = draft.reset()
        resetSnapshot.revealedValidationFields = revealedValidationFields
        canUndoReset = true
        os_signpost(.event, log: SignpostNames.log, name: SignpostNames.resetTapped)
        applySceneDraft(
            values: draft.formValues,
            disclosure: draft.patternDetailsExpanded
        )
        focusedField = nil
        revealedValidationFields.removeAll()
        showFullMath = false
    }

    func undoReset() {
        guard let snapshot = resetSnapshot.draft else { return }
        var draft = formDraft
        draft.restore(snapshot)
        resetSnapshot.draft = nil
        canUndoReset = false
        applySceneDraft(
            values: draft.formValues,
            disclosure: draft.patternDetailsExpanded
        )
        focusedField = nil
        revealedValidationFields = resetSnapshot.revealedValidationFields
        resetSnapshot.revealedValidationFields.removeAll()
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
        imageFactory: (Data) -> UIImage? = { UIImage(data: $0) }
    ) async -> [Any] {
        guard let inputs else { return [] }
        let summary = ResultsExportSummary(inputs: inputs, result: result, unit: unit)
        if let image = imageFactory(ShareableView.pngData(summary: summary)) {
            os_signpost(.event, log: SignpostNames.log, name: SignpostNames.shareInvoked)
            return [image]
        }

        os_signpost(.event, log: SignpostNames.log, name: SignpostNames.shareFallback)
        return [ResultsShareTextFormatter.string(inputs: inputs, result: result, unit: unit)]
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
