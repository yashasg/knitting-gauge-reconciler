import SwiftUI
import UIKit

@main
struct KnittingGaugeReconcilerApp: App {
    #if !TESTING
    @Environment(\.scenePhase) private var scenePhase
    private let scenePhaseOverride: ScenePhase?
    #endif
    @State private var stitchwiseProStore: StitchwiseProStore

    init() {
        _stitchwiseProStore = State(initialValue: StitchwiseProStore())
        #if !TESTING
        scenePhaseOverride = nil
        #endif
        Self.configureNavigationBarTypography()
    }

    init(scenePhaseOverride: ScenePhase) {
        _stitchwiseProStore = State(initialValue: StitchwiseProStore())
        #if !TESTING
        self.scenePhaseOverride = scenePhaseOverride
        #else
        _ = scenePhaseOverride
        #endif
        Self.configureNavigationBarTypography()
    }

    @MainActor
    static func content(store: StitchwiseProStore) -> some View {
        ProjectLibraryView()
            .font(.satoshiBody)
            .environment(store)
    }

    var body: some Scene {
        WindowGroup(content: sceneContent)
    }

    func sceneContent() -> some View {
        Self.content(store: stitchwiseProStore)
            .task(refreshStore)
            #if TESTING
            .onChange(of: ScenePhase.inactive, refreshStoreWhenActive)
            #else
            .onChange(of: scenePhaseOverride ?? scenePhase, refreshStoreWhenActive)
            #endif
    }

    @MainActor
    func refreshStore() async {
        await stitchwiseProStore.refresh()
        await stitchwiseProStore.loadProduct()
    }

    func refreshStoreWhenActive(_: ScenePhase, _ phase: ScenePhase) {
        guard phase == .active else { return }
        Task {
            await refreshStore()
        }
    }

    private static func configureNavigationBarTypography() {
        let titleFont = SatoshiVariableFont.scaledFont(
            size: 17,
            textStyle: .headline,
            weight: .semibold
        )
        let largeTitleFont = SatoshiVariableFont.scaledFont(
            size: 34,
            textStyle: .largeTitle,
            weight: .bold
        )
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.titleTextAttributes[.font] = titleFont
        appearance.largeTitleTextAttributes[.font] = largeTitleFont

        let navigationBar = UINavigationBar.appearance()
        navigationBar.standardAppearance = appearance
        navigationBar.compactAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactScrollEdgeAppearance = appearance
    }
}
