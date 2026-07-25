// swiftlint:disable file_length
import Observation
import SwiftUI

@MainActor
@Observable
final class ProjectLibraryState {
    let store: ProjectStore
    var isCreatingProject: Bool
    var createdProjectID: KnittingProject.ID?
    var navigationPath: [KnittingProject.ID]
    var searchText: String
    var isSearchPresented: Bool
    var isSettingsPresented: Bool

    init(
        store: ProjectStore = ProjectStore(),
        isCreatingProject: Bool = false,
        createdProjectID: KnittingProject.ID? = nil,
        navigationPath: [KnittingProject.ID] = [],
        searchText: String = "",
        isSearchPresented: Bool = false,
        isSettingsPresented: Bool = false
    ) {
        self.store = store
        self.isCreatingProject = isCreatingProject
        self.createdProjectID = createdProjectID
        self.navigationPath = navigationPath
        self.searchText = searchText
        self.isSearchPresented = isSearchPresented
        self.isSettingsPresented = isSettingsPresented
    }

    var visibleProjects: [KnittingProject] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return store.projects }
        return store.projects.filter {
            $0.name.localizedStandardContains(query)
                || $0.subtitle.localizedStandardContains(query)
                || $0.notes?.localizedStandardContains(query) == true
        }
    }

    var issuePresented: Bool {
        get { store.issue != nil }
        set {
            if !newValue {
                store.issue = nil
            }
        }
    }

    func presentProjectCreator() {
        isCreatingProject = true
    }

    func projectCreated(_ projectID: KnittingProject.ID) {
        createdProjectID = projectID
    }

    func dismissProjectCreator() {
        isCreatingProject = false
    }

    func openCreatedProject() {
        guard let createdProjectID else { return }
        navigationPath.append(createdProjectID)
        self.createdProjectID = nil
    }

    func dismissIssue() {
        store.issue = nil
    }

    func presentSettings() {
        isSettingsPresented = true
    }

    func dismissSettings() {
        isSettingsPresented = false
    }

    func presentSearch() {
        isSearchPresented = true
    }

    func deleteVisibleProjects(at offsets: IndexSet) {
        let ids = Set(offsets.map { visibleProjects[$0].id })
        let storeOffsets = IndexSet(store.projects.indices.filter {
            ids.contains(store.projects[$0].id)
        })
        store.delete(at: storeOffsets)
    }
}

@MainActor
struct ProjectLibraryView: View {
    @State var state: ProjectLibraryState
    private let model: ProjectLibraryState

    init(
        store: ProjectStore = ProjectStore(),
        isCreatingProject: Bool = false,
        createdProjectID: KnittingProject.ID? = nil,
        navigationPath: [KnittingProject.ID] = []
    ) {
        let state = ProjectLibraryState(
            store: store,
            isCreatingProject: isCreatingProject,
            createdProjectID: createdProjectID,
            navigationPath: navigationPath
        )
        model = state
        _state = State(initialValue: state)
    }

    init(state: ProjectLibraryState) {
        model = state
        _state = State(initialValue: state)
    }

    var body: some View {
        @Bindable var state = state

        NavigationStack(path: $state.navigationPath) {
            searchableProjectList(
                text: $state.searchText,
                isPresented: $state.isSearchPresented
            )
                .overlay(alignment: .bottomTrailing) {
                    floatingCreateButton
                }
            .navigationTitle("Projects")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button(action: state.presentSearch) {
                        Image(systemName: "magnifyingglass")
                            .font(.satoshiBody.weight(.medium))
                            .foregroundStyle(AppTheme.sage)
                            .frame(
                                minWidth: Sizing.minimumTouchTarget,
                                minHeight: Sizing.minimumTouchTarget
                            )
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Search Projects")
                    .accessibilityHint("Shows project search")

                    SettingsToolbarButton(isPresented: $state.isSettingsPresented)
                }
            }
            .navigationDestination(
                for: KnittingProject.ID.self,
                destination: projectDestination
            )
        }
        .sheet(
            isPresented: $state.isCreatingProject,
            onDismiss: state.openCreatedProject,
            content: projectCreator
        )
        .sheet(isPresented: $state.isSettingsPresented) {
            SettingsView()
        }
        .alert(
            "Project Storage Error",
            isPresented: $state.issuePresented,
            actions: storageErrorActions,
            message: storageErrorMessage
        )
    }

    @ViewBuilder
    private func searchableProjectList(
        text: Binding<String>,
        isPresented: Binding<Bool>
    ) -> some View {
        if isPresented.wrappedValue {
            projectList
                .searchable(
                    text: text,
                    isPresented: isPresented,
                    placement: .navigationBarDrawer(displayMode: .automatic),
                    prompt: "Search Projects"
                )
        } else {
            projectList
        }
    }

    private var floatingCreateButton: some View {
        Button(
            "New Project",
            systemImage: "plus",
            action: state.presentProjectCreator
        )
        .labelStyle(.iconOnly)
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.circle)
        .controlSize(.large)
        .tint(AppTheme.sage)
        .shadow(color: AppTheme.ink.opacity(0.18), radius: 12, x: 0, y: 6)
        .padding(.trailing, Spacing.margin)
        .padding(.bottom, Spacing.inner)
    }

    private var projectList: some View {
        List {
            ForEach(state.visibleProjects, content: projectLink)
                .onDelete(perform: state.deleteVisibleProjects)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .contentMargins(
            .bottom,
            Sizing.minimumTouchTarget + Spacing.roomy,
            for: .scrollContent
        )
        .background(AppTheme.background)
        .overlay {
            if state.store.projects.isEmpty {
                ContentUnavailableView {
                    Label("No Projects Yet", systemImage: "rectangle.stack")
                } description: {
                    Text("Create a project to save its gauge, construction, and measurements.")
                }
            } else if state.visibleProjects.isEmpty {
                ContentUnavailableView.search(text: state.searchText)
            }
        }
    }

    @ViewBuilder
    func projectLink(_ project: KnittingProject) -> some View {
        NavigationLink(value: project.id) {
            ProjectRow(project: project)
        }
        .listRowBackground(AppTheme.card)
    }

    @ViewBuilder
    func projectDestination(_ projectID: KnittingProject.ID) -> some View {
        if model.store.project(id: projectID) != nil {
            ProjectResultsView(projectID: projectID, store: model.store)
        } else {
            ContentUnavailableView(
                "Project Unavailable",
                systemImage: "exclamationmark.triangle",
                description: Text("Return to Projects and choose another item.")
            )
        }
    }

    @ViewBuilder
    func projectCreator() -> some View {
        CreateProjectFlow(
            store: model.store,
            onCreated: model.projectCreated,
            onDismiss: model.dismissProjectCreator
        )
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    func storageErrorActions() -> some View {
        if model.store.issue?.kind == .load {
            Button(
                "Reset Saved Projects",
                role: .destructive,
                action: model.store.resetArchive
            )
        }
        Button("OK", action: model.dismissIssue)
    }

    @ViewBuilder
    func storageErrorMessage() -> some View {
        Text(model.store.issue?.message ?? "An unknown storage error occurred.")
    }
}

struct ProjectRow: View {
    let project: KnittingProject

    var body: some View {
        HStack(spacing: Spacing.margin) {
            ProjectSymbol(
                symbolName: project.symbolName,
                color: project.color,
                size: 48
            )

            VStack(alignment: .leading, spacing: Spacing.tight) {
                Text(project.name)
                    .font(.satoshiHeadline)
                    .foregroundStyle(AppTheme.ink)
                Text(project.subtitle)
                    .font(.satoshiSubheadline)
                    .foregroundStyle(AppTheme.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(project.name), \(project.subtitle)")
    }
}

struct ProjectSymbol: View {
    let symbolName: String
    let color: ProjectColor
    let size: CGFloat
    @ScaledMetric(relativeTo: .body) private var scale = 1.0

    init(symbolName: String, color: ProjectColor, size: CGFloat) {
        self.symbolName = symbolName
        self.color = color
        self.size = size
        _scale = ScaledMetric(wrappedValue: 1.0, relativeTo: .body)
    }

    var body: some View {
        ProjectIconImage(symbolName: symbolName)
            .font(.satoshiTitle3.weight(.semibold))
            .foregroundStyle(color.color)
            .frame(width: size * scale, height: size * scale)
            .background(AppTheme.oatmeal)
            .clipShape(.circle)
            .accessibilityHidden(true)
    }
}

@MainActor
struct ProjectResultsView: View {
    let projectID: KnittingProject.ID
    let store: ProjectStore
    @State private var isEditing = false

    init(
        projectID: KnittingProject.ID,
        store: ProjectStore,
        isEditing: Bool = false
    ) {
        self.projectID = projectID
        self.store = store
        _isEditing = State(initialValue: isEditing)
    }

    var body: some View {
        if let project = store.project(id: projectID),
           project.gaugeInputs != nil {
            ScrollView {
                ProjectOverviewCard(project: project)
                .padding(.horizontal, Spacing.margin)
                .padding(.top, Spacing.inner)
                .padding(.bottom, Spacing.margin)
                .frame(maxWidth: Sizing.maximumCalculatorWidth)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle(project.name)
            .background(
                ZStack {
                    AppTheme.background
                    TexturedBackground()
                }
                .ignoresSafeArea()
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit", action: startEditing)
                }
            }
            .sheet(isPresented: $isEditing, content: editSheet)
        } else {
            ContentUnavailableView(
                "Results Unavailable",
                systemImage: "exclamationmark.triangle",
                description: Text("Edit this project and complete its gauge details.")
            )
        }
    }

    func startEditing() {
        isEditing = true
    }

    func stopEditing() {
        isEditing = false
    }

    func projectUpdated(_ projectID: KnittingProject.ID) {
        guard projectID == self.projectID else { return }
        stopEditing()
    }

    @ViewBuilder
    func editSheet() -> some View {
        if let project = store.project(id: projectID) {
            CreateProjectFlow(
                store: store,
                onCreated: projectUpdated,
                editingProject: project,
                onDismiss: stopEditing
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        } else {
            ContentUnavailableView(
                "Project Unavailable",
                systemImage: "exclamationmark.triangle"
            )
        }
    }

}

struct ProjectOverviewCard: View {
    let project: KnittingProject

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.margin) {
            HStack(spacing: Spacing.control) {
                ProjectSymbol(
                    symbolName: project.symbolName,
                    color: project.color,
                    size: 44
                )
                VStack(alignment: .leading, spacing: Spacing.hairline) {
                    Text(project.name)
                        .font(.satoshiTitle3.weight(.bold))
                        .foregroundStyle(AppTheme.ink)
                    Text(project.subtitle)
                        .font(.satoshiSubheadline)
                        .foregroundStyle(AppTheme.muted)
                }
            }

            Divider()
                .overlay(AppTheme.outline)

            VStack(alignment: .leading, spacing: Spacing.control) {
                sectionTitle("Project Details")
                detailRow("Project type", value: project.type.label)
                if let construction = project.construction {
                    detailRow("Construction", value: construction.label)
                }
                if let crownShape = project.crownShape {
                    detailRow("Crown shape", value: crownShape.label)
                }
                if let crownSections = project.crownSections {
                    detailRow("Crown sections", value: "\(crownSections)")
                }
            }

            if let notes = project.notes, !notes.isEmpty {
                Divider()
                    .overlay(AppTheme.outline)
                VStack(alignment: .leading, spacing: Spacing.control) {
                    sectionTitle("Notes")
                    Text(notes)
                        .font(.satoshiBody)
                        .foregroundStyle(AppTheme.ink)
                }
            }

            Divider()
                .overlay(AppTheme.outline)

            VStack(alignment: .leading, spacing: Spacing.control) {
                sectionTitle("Gauge Inputs")
                Text("Counts per \(gaugeBasis)")
                    .font(.satoshiCaption)
                    .foregroundStyle(AppTheme.muted)
                detailRow(
                    "Pattern gauge",
                    value: gaugeValue(
                        stitches: project.gaugeValues.patternStitches,
                        rows: project.gaugeValues.patternRows
                    )
                )
                detailRow(
                    "Swatch gauge",
                    value: gaugeValue(
                        stitches: project.gaugeValues.yourStitches,
                        rows: project.gaugeValues.yourRows
                    )
                )
            }

            Divider()
                .overlay(AppTheme.outline)

            VStack(alignment: .leading, spacing: Spacing.control) {
                sectionTitle("Reconciled Counts")
                Text((project.countRules ?? .wholeNumber).summary)
                    .font(.satoshiCaption)
                    .foregroundStyle(AppTheme.muted)
                if project.measurementResults.isEmpty {
                    Text("Add measurements to calculate required stitch and row counts.")
                        .font(.satoshiBody)
                        .foregroundStyle(AppTheme.muted)
                }
                ForEach(project.measurementResults, content: measurementRow)
            }
        }
        .cardStyle()
    }

    var gaugeBasis: String {
        project.measurementUnit == .centimeters ? "10 cm" : "4 in"
    }

    func gaugeValue(stitches: String, rows: String) -> String {
        "\(stitches) stitches · \(rows) rows"
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.satoshiHeadline.weight(.bold))
            .foregroundStyle(AppTheme.sage)
            .accessibilityAddTraits(.isHeader)
    }

    private func detailRow(_ label: String, value: String) -> some View {
        LabeledContent(label, value: value)
            .font(.satoshiBody)
            .foregroundStyle(AppTheme.ink)
    }

    private func measurementRow(_ result: ProjectMeasurementResult) -> some View {
        let measurement = result.measurement
        return ProjectMeasurementComparisonRow(
            result: result,
            measurementValue: displayValue(measurement.centimeters),
            landmarks: landmarks(for: measurement.kind),
            projectColor: project.color.color
        )
    }

    func displayValue(_ centimeters: String) -> String {
        guard let value = Double(centimeters) else { return centimeters }
        return project.measurementUnit.formatMeasurement(value)
    }

    func landmarks(for kind: ProjectMeasurementKind) -> String {
        if kind == .customWidth || kind == .customDepth,
           !project.customLandmarks.isEmpty {
            return project.customLandmarks
        }
        return kind.landmarks
    }
}

private struct ProjectMeasurementComparisonRow: View {
    let result: ProjectMeasurementResult
    let measurementValue: String
    let landmarks: String
    let projectColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.inner) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.control) {
                Text(result.measurement.kind.label)
                    .font(.satoshiBody.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                Spacer(minLength: Spacing.inner)
                Text(measurementValue)
                    .font(.satoshiCaption.monospacedDigit())
                    .foregroundStyle(AppTheme.muted)
            }

            Text(landmarks)
                .font(.satoshiCaption)
                .foregroundStyle(AppTheme.muted)

            comparisonLayout
        }
        .padding(.vertical, Spacing.tight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(result.measurement.kind.label), \(measurementValue), " +
                "before reconciliation \(result.patternCount) \(result.resultLabel), " +
                "after reconciliation \(result.requiredCount) \(result.resultLabel), " +
                landmarks
        )
    }

    private var comparisonLayout: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: Spacing.control) {
                comparisonValue("Before reconciliation", count: result.patternCount)
                comparisonArrow("arrow.right")
                comparisonValue(
                    "After reconciliation",
                    count: result.requiredCount,
                    isTrailing: true,
                    color: projectColor
                )
            }

            VStack(alignment: .leading, spacing: Spacing.inner) {
                comparisonValue("Before reconciliation", count: result.patternCount)
                comparisonArrow("arrow.down")
                comparisonValue(
                    "After reconciliation",
                    count: result.requiredCount,
                    color: projectColor
                )
            }
        }
    }

    private func comparisonValue(
        _ caption: String,
        count: Int,
        isTrailing: Bool = false,
        color: Color = AppTheme.ink
    ) -> some View {
        VStack(alignment: isTrailing ? .trailing : .leading, spacing: Spacing.tight) {
            Text(caption)
                .font(.satoshiCaption)
                .foregroundStyle(AppTheme.muted)
            Text("\(count) \(result.resultLabel)")
                .font(.satoshiHeadline.weight(.bold))
                .foregroundStyle(color)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: isTrailing ? .trailing : .leading)
    }

    private func comparisonArrow(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.satoshiCaption.weight(.bold))
            .foregroundStyle(AppTheme.muted)
            .accessibilityHidden(true)
    }
}
