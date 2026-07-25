// swiftlint:disable file_length
import Observation
import SwiftUI
import UIKit

@MainActor
struct CreateProjectFlow: View {
    enum Step: Int, CaseIterable {
        case identity
        case construction
        case gauge
        case measurements
        case notes
        case review

        var title: String {
            switch self {
            case .identity: "New Project"
            case .construction: "Project Details"
            case .gauge: "Gauge"
            case .measurements: "Optional Measurements"
            case .notes: "Notes"
            case .review: "Review"
            }
        }
    }

    @State private var state: CreateProjectFlowState

    init(
        store: ProjectStore,
        onCreated: @escaping (KnittingProject.ID) -> Void,
        draft: ProjectDraft = ProjectDraft(),
        editingProject: KnittingProject? = nil,
        step: Step = .identity,
        showDiscardConfirmation: Bool = false,
        showSaveFailure: Bool = false,
        onDismiss: (() -> Void)? = nil
    ) {
        _state = State(
            initialValue: CreateProjectFlowState(
                store: store,
                onCreated: onCreated,
                onDismiss: onDismiss ?? {},
                acceptsEnvironmentDismiss: onDismiss == nil,
                draft: editingProject.map(ProjectDraft.init) ?? draft,
                editingProject: editingProject,
                step: step,
                showDiscardConfirmation: showDiscardConfirmation,
                showSaveFailure: showSaveFailure
            )
        )
    }

    init(state: CreateProjectFlowState) {
        _state = State(initialValue: state)
    }

    var body: some View {
        @Bindable var state = state

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.roomy) {
                    CreateProjectProgressHeader(step: state.step)
                    stepContent
                }
                .padding(Spacing.margin)
                .frame(maxWidth: Sizing.maximumContentWidth)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(AppTheme.background)
            .navigationTitle(state.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: cancellationToolbar)
            .safeAreaInset(edge: .bottom, content: actionBarContent)
        }
        .tint(AppTheme.sage)
        .interactiveDismissDisabled(state.hasChanges)
        .confirmationDialog(
            "Discard this project?",
            isPresented: $state.showDiscardConfirmation,
            titleVisibility: .visible,
            actions: discardActions,
            message: discardMessage
        )
        .alert(
            "Project Couldn’t Be Saved",
            isPresented: $state.showSaveFailure,
            actions: saveFailureActions,
            message: saveFailureMessage
        )
        .background(CreateProjectDismissInstaller(state: state))
    }

    @ToolbarContentBuilder
    func cancellationToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .cancellationAction, content: cancelButton)
    }

    func cancelButton() -> some View {
        Button("Cancel", action: state.cancel)
    }

    func actionBarContent() -> some View {
        actionBar
    }

    @ViewBuilder
    func discardActions() -> some View {
        Button("Discard Project", role: .destructive, action: state.discard)
        Button("Keep Editing", role: .cancel, action: state.keepEditing)
    }

    func discardMessage() -> some View {
        Text("Your entries have not been saved.")
    }

    func saveFailureActions() -> some View {
        Button("OK", action: state.acknowledgeSaveFailure)
    }

    func saveFailureMessage() -> some View {
        Text(state.store.issue?.message ?? "Try again.")
    }

    @ViewBuilder
    var stepContent: some View {
        @Bindable var state = state

        switch state.step {
        case .identity:
            CreateProjectIdentityStep(draft: $state.draft)
        case .construction:
            CreateProjectConstructionStep(draft: $state.draft)
        case .gauge:
            CreateProjectGaugeStep(draft: $state.draft)
        case .measurements:
            CreateProjectMeasurementsStep(draft: $state.draft)
        case .notes:
            CreateProjectNotesStep(draft: $state.draft)
        case .review:
            CreateProjectReviewStep(draft: state.draft)
        }
    }

    var actionBar: some View {
        HStack(spacing: Spacing.control) {
            if state.step != .identity {
                Button(
                    "Back",
                    systemImage: "chevron.backward",
                    action: state.moveBack
                )
                    .font(.satoshiBody.weight(.semibold))
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .tint(AppTheme.sage)
            }
            Spacer()
            Button(
                state.primaryActionLabel,
                systemImage: "chevron.forward",
                action: state.advance
            )
                .font(.satoshiBody.weight(.semibold))
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(AppTheme.sage)
                .disabled(!state.canAdvance)
        }
        .padding(.horizontal, Spacing.margin)
        .padding(.vertical, Spacing.control)
        .background(AppTheme.card)
        .overlay(actionBarDivider, alignment: .top)
    }

    var actionBarDivider: some View {
        Divider()
            .overlay(AppTheme.outline)
    }
}

@MainActor
@Observable
final class CreateProjectFlowState {
    let store: ProjectStore
    var draft: ProjectDraft
    var step: CreateProjectFlow.Step
    var showDiscardConfirmation: Bool
    var showSaveFailure: Bool

    private let editingProject: KnittingProject?
    private let initialDraft: ProjectDraft
    private let onCreated: (KnittingProject.ID) -> Void
    private let acceptsEnvironmentDismiss: Bool
    @ObservationIgnored private var onDismiss: () -> Void

    init(
        store: ProjectStore,
        onCreated: @escaping (KnittingProject.ID) -> Void,
        onDismiss: @escaping () -> Void = {},
        acceptsEnvironmentDismiss: Bool = false,
        draft: ProjectDraft = ProjectDraft(),
        editingProject: KnittingProject? = nil,
        step: CreateProjectFlow.Step = .identity,
        showDiscardConfirmation: Bool = false,
        showSaveFailure: Bool = false
    ) {
        self.store = store
        self.onCreated = onCreated
        self.onDismiss = onDismiss
        self.acceptsEnvironmentDismiss = acceptsEnvironmentDismiss
        self.draft = draft
        self.editingProject = editingProject
        initialDraft = editingProject.map(ProjectDraft.init) ?? ProjectDraft()
        self.step = step
        self.showDiscardConfirmation = showDiscardConfirmation
        self.showSaveFailure = showSaveFailure
    }

    var canAdvance: Bool {
        switch step {
        case .identity: draft.isIdentityValid
        case .construction: draft.isConstructionValid
        case .gauge: draft.isGaugeValid
        case .measurements: draft.isMeasurementsValid
        case .notes: true
        case .review: true
        }
    }

    var primaryActionLabel: String {
        switch step {
        case .measurements where !draft.hasMeasurementValues:
            "Skip"
        case .notes where draft.trimmedNotes.isEmpty:
            "Skip"
        case .review:
            "View Results"
        case .identity, .construction, .gauge, .measurements, .notes:
            "Next"
        }
    }

    var navigationTitle: String {
        editingProject != nil && step == .identity ? "Edit Project" : step.title
    }

    var hasChanges: Bool {
        draft != initialDraft || step != .identity
    }

    func installEnvironmentDismiss(_ dismiss: @escaping () -> Void) {
        guard acceptsEnvironmentDismiss else { return }
        onDismiss = dismiss
    }

    func cancel() {
        if hasChanges {
            showDiscardConfirmation = true
        } else {
            onDismiss()
        }
    }

    func discard() {
        onDismiss()
    }

    func keepEditing() {
        showDiscardConfirmation = false
    }

    func acknowledgeSaveFailure() {
        showSaveFailure = false
    }

    func moveBack() {
        switch step {
        case .identity:
            break
        case .construction:
            step = .identity
        case .gauge:
            step = .construction
        case .measurements:
            step = .gauge
        case .notes:
            step = .measurements
        case .review:
            step = .notes
        }
    }

    func advance() {
        switch step {
        case .identity:
            step = .construction
        case .construction:
            step = .gauge
        case .gauge:
            step = .measurements
        case .measurements:
            step = .notes
        case .notes:
            step = .review
        case .review:
            saveProject()
        }
    }

    func saveProject() {
        let now = Date()
        guard let project = draft.makeProject(
            id: editingProject?.id ?? UUID(),
            createdAt: editingProject?.createdAt,
            patternDetailsExpanded: editingProject?.patternDetailsExpanded ?? false,
            now: now
        ) else { return }
        let didSave = editingProject == nil ? store.add(project) : store.update(project)
        guard didSave else {
            showSaveFailure = true
            return
        }
        onCreated(project.id)
        onDismiss()
    }
}

private struct CreateProjectDismissInstaller: View {
    @Environment(\.dismiss) private var dismiss
    let state: CreateProjectFlowState

    var body: some View {
        Color.clear
            .onAppear(perform: installDismiss)
    }

    private func installDismiss() {
        state.installEnvironmentDismiss(dismiss.callAsFunction)
    }
}

struct CreateProjectProgressHeader: View {
    let step: CreateProjectFlow.Step

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.inner) {
            Text("Step \(step.rawValue + 1) of \(CreateProjectFlow.Step.allCases.count)")
                .font(.satoshiSubheadline.weight(.semibold))
                .foregroundStyle(AppTheme.muted)
            ProgressView(
                value: Double(step.rawValue + 1),
                total: Double(CreateProjectFlow.Step.allCases.count)
            )
            .tint(AppTheme.sage)
            .accessibilityLabel("Project creation progress")
            .accessibilityValue(
                "Step \(step.rawValue + 1) of \(CreateProjectFlow.Step.allCases.count)"
            )
        }
    }
}

struct CreateProjectIdentityStep: View {
    @Binding var draft: ProjectDraft
    @FocusState private var nameIsFocused: Bool
    @ScaledMetric(relativeTo: .body) private var projectTypeIconSize = Sizing.stepBadge

    init(draft: Binding<ProjectDraft>) {
        _draft = draft
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.margin) {
            VStack(spacing: Spacing.margin) {
                ProjectSymbol(symbolName: draft.symbolName, color: draft.color, size: Sizing.projectHeroSymbol)
                TextField("Project Name", text: $draft.name)
                    .font(.satoshiTitle3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.next)
                    .focused($nameIsFocused)
                    .defaultFocus($nameIsFocused, true)
                    .padding(.horizontal, Spacing.margin)
                    .frame(minHeight: Sizing.textFieldMinimumHeight)
                    .background(AppTheme.oatmeal)
                    .clipShape(.rect(cornerRadius: Radius.small))
                    .tint(AppTheme.sage)
            }
            .padding(Spacing.roomy)
            .frame(maxWidth: .infinity)
            .background(AppTheme.card)
            .clipShape(.rect(cornerRadius: Radius.medium))

            projectTypePicker
            projectColorPicker
            projectIconPicker
        }
    }

    private var projectTypePicker: some View {
        HStack(spacing: Spacing.control) {
            ProjectIconImage(symbolName: draft.type.defaultSymbolName)
                .font(.satoshiBody.weight(.semibold))
                .foregroundStyle(AppTheme.sage)
                .frame(width: projectTypeIconSize, height: projectTypeIconSize)
                .background(AppTheme.accentSoft)
                .clipShape(.circle)
                .accessibilityHidden(true)
            Text("Project Type")
                .font(.satoshiHeadline)
                .foregroundStyle(AppTheme.ink)
            Spacer(minLength: Spacing.inner)
            Picker("Project Type", selection: projectTypeBinding) {
                ForEach(ProjectType.allCases) { type in
                    Text(type.label).tag(type)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .tint(AppTheme.ink)
            .accessibilityHint(draft.type.description)
        }
        .projectSetupCard()
    }

    private var projectColorPicker: some View {
        VStack(alignment: .leading, spacing: Spacing.control) {
            Text("Project Color")
                .font(.satoshiHeadline)
                .foregroundStyle(AppTheme.ink)
            LazyVGrid(
                columns: [
                    GridItem(
                        .adaptive(minimum: Sizing.minimumTouchTarget),
                        spacing: Spacing.control
                    ),
                ],
                spacing: Spacing.control
            ) {
                ForEach(ProjectColor.selectableCases, content: projectColorButton)
            }
        }
        .projectSetupCard()
    }

    private var projectIconPicker: some View {
        VStack(alignment: .leading, spacing: Spacing.control) {
            Text("Project Icon")
                .font(.satoshiHeadline)
                .foregroundStyle(AppTheme.ink)
            LazyVGrid(
                columns: [
                    GridItem(
                        .adaptive(minimum: Sizing.projectRowSymbol),
                        spacing: Spacing.control
                    ),
                ],
                spacing: Spacing.control
            ) {
                ForEach(ProjectIcons.symbols(for: draft.type), id: \.self, content: projectIconButton)
            }
        }
        .projectSetupCard()
    }

    var projectTypeBinding: Binding<ProjectType> {
        Binding(
            get: { selectedProjectType() },
            set: { selectProjectType($0) }
        )
    }

    func selectedProjectType() -> ProjectType {
        draft.type
    }

    func selectProjectType(_ type: ProjectType) {
        draft.selectType(type)
    }

    func projectColorButton(_ color: ProjectColor) -> some View {
        CreateProjectColorButton(draft: $draft, color: color)
    }

    func projectIconButton(_ symbolName: String) -> some View {
        CreateProjectIconButton(draft: $draft, symbolName: symbolName)
    }
}

struct CreateProjectColorButton: View {
    @Binding var draft: ProjectDraft
    let color: ProjectColor
    @ScaledMetric(relativeTo: .body) private var swatchSize = Sizing.colorSwatch
    @ScaledMetric(relativeTo: .body) private var touchTargetSize = Sizing.minimumTouchTarget

    init(draft: Binding<ProjectDraft>, color: ProjectColor) {
        _draft = draft
        self.color = color
        _swatchSize = ScaledMetric(
            wrappedValue: Sizing.colorSwatch,
            relativeTo: .body
        )
        _touchTargetSize = ScaledMetric(
            wrappedValue: Sizing.minimumTouchTarget,
            relativeTo: .body
        )
    }

    var body: some View {
        Button(action: selectColor) {
            Circle()
                .fill(color.color)
                .frame(width: swatchSize, height: swatchSize)
                .overlay(checkmark)
                .overlay(selectionOutline)
                .frame(width: touchTargetSize, height: touchTargetSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(color.label) project color")
        .accessibilityAddTraits(draft.color == color ? .isSelected : [])
    }

    @ViewBuilder
    var checkmark: some View {
        if draft.color == color {
            Image(systemName: "checkmark")
                .font(.satoshiBody.weight(.bold))
                .foregroundStyle(color.symbolColor)
                .accessibilityHidden(true)
        }
    }

    var selectionOutline: some View {
        Circle()
            .stroke(draft.color == color ? AppTheme.ink : .clear, lineWidth: 2)
            .padding(-4)
    }

    func selectColor() {
        draft.color = color
    }
}

enum ProjectIcons {
    private static func metadata(
        for type: ProjectType
    ) -> [(symbolName: String, label: String)] {
        switch type {
        case .headwear: [
            ("crown", "Crown"), ("hat.cap", "Cap"),
            ("hat.widebrim", "Wide-brim hat"), ("graduationcap", "Graduation cap"),
        ]
        case .tops: [
            ("tshirt.fill", "Shirt"), ("coat.fill", "Coat"),
        ]
        case .bottoms: [
            ("figure.stand", "Pants or leggings"), ("figure.stand.dress", "Skirt or dress"),
        ]
        case .footwear: [
            ("shoe", "Shoe"), ("shoe.fill", "Filled shoe"), ("shoe.2", "Pair of shoes"),
            ("shoe.2.fill", "Filled pair of shoes"), ("shoeprints.fill", "Footprints"),
        ]
        case .other: [
            ("square.grid.2x2", "Blanket blocks"), ("handbag", "Bag"),
            ("backpack", "Backpack"), ("teddybear", "Toy"), ("gift", "Gift"),
        ]
        }
    }

    static var all: [String] { ProjectType.allCases.flatMap(symbols) }

    static func symbols(for type: ProjectType) -> [String] {
        symbols(for: type) { UIImage(systemName: $0) != nil }
    }

    static func symbols(
        for type: ProjectType,
        availableWhere isAvailable: (String) -> Bool
    ) -> [String] {
        metadata(for: type).map(\.symbolName).filter(isAvailable)
    }

    static func label(for symbolName: String) -> String {
        ProjectType.allCases
            .flatMap(metadata)
            .first { $0.symbolName == symbolName }?
            .label ?? "Project icon"
    }

    static func clipsTopHalf(_ symbolName: String) -> Bool {
        symbolName == "figure.stand" || symbolName == "figure.stand.dress"
    }
}

struct ProjectIconImage: View {
    let symbolName: String

    @ViewBuilder
    var body: some View {
        if ProjectIcons.clipsTopHalf(symbolName) {
            Image(systemName: symbolName)
                .clipShape(BottomHalfShape())
                .accessibilityHidden(true)
        } else {
            Image(systemName: symbolName)
                .accessibilityHidden(true)
        }
    }
}

struct BottomHalfShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path(CGRect(x: rect.minX, y: rect.midY, width: rect.width, height: rect.height / 2))
    }
}

struct CreateProjectIconButton: View {
    @Binding var draft: ProjectDraft
    let symbolName: String
    @ScaledMetric(relativeTo: .body) private var touchTargetSize = Sizing.minimumTouchTarget

    init(draft: Binding<ProjectDraft>, symbolName: String) {
        _draft = draft
        self.symbolName = symbolName
        _touchTargetSize = ScaledMetric(
            wrappedValue: Sizing.minimumTouchTarget,
            relativeTo: .body
        )
    }

    var body: some View {
        Button(action: selectIcon) {
            ProjectIconImage(symbolName: symbolName)
                .font(.satoshiTitle3.weight(.semibold))
                .foregroundStyle(draft.color.color)
                .frame(width: touchTargetSize, height: touchTargetSize)
                .background(AppTheme.oatmeal)
                .clipShape(.circle)
                .overlay(selectionOutline)
                .accessibilityHidden(true)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(ProjectIcons.label(for: symbolName))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    var isSelected: Bool {
        draft.symbolName == symbolName
    }

    var selectionOutline: some View {
        Circle()
            .stroke(isSelected ? draft.color.color : .clear, lineWidth: 2)
    }

    func selectIcon() {
        draft.symbolName = symbolName
    }
}

struct CreateProjectConstructionStep: View {
    @Binding var draft: ProjectDraft

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.margin) {
            Text(draft.type.description)
                .font(.satoshiBody)
                .foregroundStyle(AppTheme.muted)

            if !draft.type.constructions.isEmpty {
                ForEach(draft.type.constructions, content: constructionCard)
            } else if draft.type == .headwear {
                crownOptions
            } else {
                CreateProjectSelectionCard(
                    title: draft.type.label,
                    detail: constructionSummary,
                    isSelected: true,
                    action: keepSelection
                )
            }
        }
    }

    private var crownOptions: some View {
        VStack(alignment: .leading, spacing: Spacing.control) {
            Text("Crown Shape")
                .font(.satoshiHeadline)
                .foregroundStyle(AppTheme.ink)
            Picker("Crown Shape", selection: $draft.crownShape) {
                ForEach(ProjectCrownShape.allCases) { shape in
                    Text(shape.label)
                }
            }
            .pickerStyle(.segmented)

            if draft.crownShape == .faceted {
                Picker("Crown Sections", selection: $draft.crownSections) {
                    Text("5 sections").tag(5)
                    Text("6 sections").tag(6)
                }
                .pickerStyle(.segmented)
            }
        }
        .projectSetupCard()
    }

    var constructionSummary: String {
        switch draft.type {
        case .footwear:
            "Heel depth captures the shaping around the heel turn."
        case .other:
            "Define a useful depth and name its start and end landmarks."
        case .headwear, .tops, .bottoms:
            draft.type.description
        }
    }

    func constructionCard(_ construction: ProjectConstruction) -> some View {
        CreateProjectConstructionCard(draft: $draft, construction: construction)
    }

    func keepSelection() {}
}

struct CreateProjectConstructionCard: View {
    @Binding var draft: ProjectDraft
    let construction: ProjectConstruction

    var body: some View {
        CreateProjectSelectionCard(
            title: construction.label,
            detail: construction.detail,
            isSelected: draft.construction == construction,
            action: selectConstruction
        )
    }

    func selectConstruction() {
        draft.construction = construction
        draft.measurementValues = [:]
    }
}

struct CreateProjectGaugeStep: View {
    @Binding var draft: ProjectDraft
    @State private var focusedField: GaugeFormField?

    init(draft: Binding<ProjectDraft>) {
        _draft = draft
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.control) {
            GaugeInputsCard(
                patternStitches: gaugeBinding(for: .patternStitches),
                patternRows: gaugeBinding(for: .patternRows),
                yourStitches: gaugeBinding(for: .yourStitches),
                yourRows: gaugeBinding(for: .yourRows),
                unit: $draft.measurementUnit,
                stitchMismatch: gaugeInputs?.stitchMismatch ?? false,
                rowMismatch: gaugeInputs?.rowMismatch ?? false,
                stitchDelta: stitchDelta,
                rowDelta: rowDelta,
                validationMessages: gaugeValidationMessages,
                focusedField: $focusedField
            )
            if !draft.isGaugeValid {
                Text("Complete all four gauge fields to continue.")
                    .font(.satoshiFootnote)
                    .foregroundStyle(AppTheme.muted)
            }
        }
    }

    var gaugeInputs: GaugeInputs? {
        GaugeFormDraft(values: draft.gaugeValues, unit: draft.measurementUnit).inputs
    }

    var stitchDelta: Double? {
        guard let gaugeInputs else { return nil }
        return gaugeInputs.yourStitches - gaugeInputs.patternStitches
    }

    var rowDelta: Double? {
        guard let gaugeInputs else { return nil }
        return gaugeInputs.yourRows - gaugeInputs.patternRows
    }

    var gaugeValidationMessages: [GaugeFormField: String] {
        let formDraft = GaugeFormDraft(values: draft.gaugeValues, unit: draft.measurementUnit)
        var messages: [GaugeFormField: String] = [:]
        for (field, message) in formDraft.validationMessages
        where !field.isPatternDetail && !draft.gaugeValues[field].isEmpty {
            messages[field] = message
        }
        return messages
    }

    func gaugeBinding(for field: GaugeFormField) -> Binding<String> {
        Binding(
            get: { gaugeValue(for: field) },
            set: { setGaugeValue($0, for: field) }
        )
    }

    func gaugeValue(for field: GaugeFormField) -> String {
        draft.gaugeValues[field]
    }

    func setGaugeValue(_ value: String, for field: GaugeFormField) {
        draft.gaugeValues[field] = value
    }
}

struct CreateProjectMeasurementsStep: View {
    @Binding var draft: ProjectDraft

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.margin) {
            VStack(alignment: .leading, spacing: Spacing.inner) {
                Text("Add finished dimensions after blocking")
                    .font(.satoshiHeadline)
                    .foregroundStyle(AppTheme.ink)
                Text(
                    "Horizontal measurements calculate stitches. " +
                        "Vertical measurements calculate rows. Skip anything you don’t need."
                )
                .font(.satoshiSubheadline)
                .foregroundStyle(AppTheme.muted)
            }
            .projectSetupCard()

            ForEach(draft.measurementKinds, content: measurementField)

            if draft.type == .other {
                VStack(alignment: .leading, spacing: Spacing.compact) {
                    Text("Landmarks")
                        .font(.satoshiHeadline)
                        .foregroundStyle(AppTheme.ink)
                    TextField(
                        "For example, edge to edge",
                        text: $draft.customLandmarks,
                        axis: .vertical
                    )
                    .lineLimit(2...4)
                    Text("Optionally describe the landmarks for your custom dimensions.")
                        .font(.satoshiCaption)
                        .foregroundStyle(AppTheme.muted)
                }
                .projectSetupCard()
            }

            countConstraint
        }
    }

    private var countConstraint: some View {
        VStack(alignment: .leading, spacing: Spacing.control) {
            Text("Required Count Rounding")
                .font(.satoshiHeadline)
                .foregroundStyle(AppTheme.ink)
            Picker("Required count rounding", selection: $draft.countConstraint) {
                ForEach(ProjectCountConstraint.allCases) { constraint in
                    Text(constraint.pickerLabel)
                }
            }
            .pickerStyle(.segmented)
            Text(draft.countConstraint.explanation)
                .font(.satoshiCaption)
                .foregroundStyle(AppTheme.muted)

            if draft.countConstraint == .patternRepeat {
                repeatField("Stitch repeat", text: $draft.stitchRepeat)
                repeatField("Row repeat", text: $draft.rowRepeat)
                if draft.validatedCountRules == nil {
                    Text(
                        "Enter both repeat multiples from " +
                            "\(ProjectCountRules.repeatRange.lowerBound) to " +
                            "\(ProjectCountRules.repeatRange.upperBound)."
                    )
                    .font(.satoshiCaption)
                    .foregroundStyle(AppTheme.mismatchText)
                }
            }
        }
        .projectSetupCard()
    }

    private func repeatField(_ label: String, text: Binding<String>) -> some View {
        LabeledContent(label) {
            TextField(label, text: text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .textFieldStyle(.roundedBorder)
                .frame(minWidth: Sizing.minimumTouchTarget)
        }
        .font(.satoshiBody)
        .foregroundStyle(AppTheme.ink)
    }

    func measurementField(for kind: ProjectMeasurementKind) -> some View {
        VStack(alignment: .leading, spacing: Spacing.inner) {
            Text(kind.label)
                .font(.satoshiHeadline)
                .foregroundStyle(AppTheme.ink)
            Text(kind.axis == .horizontal ? "Calculates stitches" : "Calculates rows")
                .font(.satoshiCaption.weight(.semibold))
                .foregroundStyle(AppTheme.sage)
            HStack {
                TextField(kind.label, text: measurementDisplayBinding(for: kind))
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                Text(draft.measurementUnit.label)
                    .font(.satoshiBody.monospacedDigit())
                    .foregroundStyle(AppTheme.muted)
            }
            Text(
                kind == .customWidth || kind == .customDepth
                    ? "Use your own landmarks below."
                    : kind.landmarks
            )
                .font(.satoshiCaption)
                .foregroundStyle(AppTheme.muted)
            if !draft.isMeasurementValid(kind) {
                Text(measurementValidationMessage(for: kind))
                    .font(.satoshiCaption)
                    .foregroundStyle(AppTheme.mismatchText)
            }
        }
        .projectSetupCard()
    }

    func measurementDisplayBinding(
        for kind: ProjectMeasurementKind
    ) -> Binding<String> {
        Binding(
            get: { measurementDisplayValue(for: kind) },
            set: { setMeasurementDisplayValue($0, for: kind) }
        )
    }

    func measurementDisplayValue(for kind: ProjectMeasurementKind) -> String {
        let stored = draft.measurementValues[kind] ?? ""
        if let invalidInches = MeasurementUnit.invalidInchesText(from: stored) {
            return invalidInches
        }
        guard draft.measurementUnit == .inches, let value = Double(stored) else {
            return stored
        }
        return "\(draft.measurementUnit.cmToDisplayInt(value))"
    }

    func setMeasurementDisplayValue(
        _ value: String,
        for kind: ProjectMeasurementKind
    ) {
        draft.measurementValues[kind] = draft.measurementUnit.centimeterStorageText(
            from: value,
            cmRange: kind.valueRange
        )
    }

    func measurementValidationMessage(for kind: ProjectMeasurementKind) -> String {
        let range = draft.measurementUnit.displayRange(from: kind.valueRange)
        return "Enter a whole number from \(range.lowerBound) to \(range.upperBound) " +
            "\(draft.measurementUnit.label), or leave this blank."
    }
}

struct CreateProjectNotesStep: View {
    @Binding var draft: ProjectDraft

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.inner) {
            Text("Add anything you’ll want beside the results.")
                .font(.satoshiHeadline)
                .foregroundStyle(AppTheme.ink)
            TextField(
                "Pattern details, yarn, size, reminders…",
                text: $draft.notes,
                axis: .vertical
            )
            .lineLimit(5...10)
            .textInputAutocapitalization(.sentences)
            .padding(Spacing.control)
            .background(AppTheme.oatmeal)
            .clipShape(.rect(cornerRadius: Radius.small))
            Text("Notes stay with this project and can be edited later.")
                .font(.satoshiCaption)
                .foregroundStyle(AppTheme.muted)
        }
        .projectSetupCard()
    }
}

struct CreateProjectReviewStep: View {
    let draft: ProjectDraft

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.margin) {
            HStack(spacing: Spacing.margin) {
                ProjectSymbol(symbolName: draft.symbolName, color: draft.color, size: Sizing.projectCardSymbol)
                VStack(alignment: .leading, spacing: Spacing.tight) {
                    Text(draft.name.trimmingCharacters(in: .whitespacesAndNewlines))
                        .font(.satoshiTitle2.weight(.bold))
                        .foregroundStyle(AppTheme.ink)
                    Text(reviewSubtitle)
                        .font(.satoshiSubheadline)
                        .foregroundStyle(AppTheme.muted)
                }
            }
            .projectSetupCard()

            VStack(alignment: .leading, spacing: Spacing.control) {
                reviewSectionTitle("Gauge")
                reviewRow("Pattern", value: gaugeSummary(pattern: true))
                reviewRow("Your swatch", value: gaugeSummary(pattern: false))
            }
            .projectSetupCard()

            VStack(alignment: .leading, spacing: Spacing.control) {
                reviewSectionTitle("Optional Measurements")
                if draft.enteredMeasurementKinds.isEmpty {
                    Text("No optional measurements added.")
                        .font(.satoshiBody)
                        .foregroundStyle(AppTheme.muted)
                }
                ForEach(draft.enteredMeasurementKinds, content: measurementReviewRow)
                if draft.type == .other, !draft.customLandmarks.isEmpty {
                    reviewRow("Landmarks", value: draft.customLandmarks)
                }
                reviewRow("Count rounding", value: countRulesSummary)
            }
            .projectSetupCard()

            if !draft.trimmedNotes.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.control) {
                    reviewSectionTitle("Notes")
                    Text(draft.trimmedNotes)
                        .font(.satoshiBody)
                        .foregroundStyle(AppTheme.ink)
                }
                .projectSetupCard()
            }
        }
    }

    var reviewSubtitle: String {
        if let construction = draft.construction {
            return "\(draft.type.label) · \(construction.label)"
        }
        if draft.type == .headwear {
            return "\(draft.type.label) · \(draft.crownShape.label)"
        }
        return draft.type.label
    }

    func reviewSectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.satoshiHeadline)
            .foregroundStyle(AppTheme.ink)
    }

    func reviewRow(_ label: String, value: String) -> some View {
        LabeledContent(label, value: value)
            .foregroundStyle(AppTheme.ink)
    }

    func measurementReviewRow(_ kind: ProjectMeasurementKind) -> some View {
        reviewRow(kind.label, value: measurementReviewValue(for: kind))
    }

    func gaugeSummary(pattern: Bool) -> String {
        let stitches = pattern
            ? draft.gaugeValues.patternStitches
            : draft.gaugeValues.yourStitches
        let rows = pattern ? draft.gaugeValues.patternRows : draft.gaugeValues.yourRows
        return "\(stitches) stitches, \(rows) rows / \(draft.measurementUnit.gaugeBasis)"
    }

    func measurementReviewValue(for kind: ProjectMeasurementKind) -> String {
        let stored = draft.measurementValues[kind] ?? ""
        guard let value = Double(stored) else { return stored }
        return draft.measurementUnit.formatMeasurement(value)
    }

    var countRulesSummary: String {
        draft.validatedCountRules?.summary ?? draft.countConstraint.label
    }
}

struct CreateProjectSelectionCard: View {
    let title: String
    let detail: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: Spacing.control) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.satoshiTitle3)
                    .foregroundStyle(isSelected ? AppTheme.sage : AppTheme.muted)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: Spacing.tight) {
                    Text(title)
                        .font(.satoshiHeadline)
                        .foregroundStyle(AppTheme.ink)
                    Text(detail)
                        .font(.satoshiSubheadline)
                        .foregroundStyle(AppTheme.muted)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .projectSetupCard()
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private extension View {
    func projectSetupCard() -> some View {
        padding(Spacing.margin)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.card)
            .clipShape(.rect(cornerRadius: Radius.medium))
    }
}
