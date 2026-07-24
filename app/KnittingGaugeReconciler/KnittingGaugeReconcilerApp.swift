import SwiftUI
import UIKit

@main
struct KnittingGaugeReconcilerApp: App {
    init() {
        Self.configureNavigationBarTypography()
    }

    @MainActor
    static func content() -> some View {
        ProjectLibraryView()
            .font(.satoshiBody)
    }

    var body: some Scene {
        WindowGroup(content: Self.content)
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
