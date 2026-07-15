import SwiftUI
import MetricKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didDiscardSceneSessions sceneSessions: Set<UISceneSession>
    ) {
        SceneDraftStore.discard(sceneIDs: sceneSessions.map(\.persistentIdentifier))
    }
}

@main
struct KnittingGaugeReconcilerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    // Retained for app lifetime; MXMetricManager holds a weak reference so
    // the stored property prevents premature deallocation.
    private let metricsSubscriber = MetricsSubscriber()

    init() {
        MXMetricManager.shared.add(metricsSubscriber)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
