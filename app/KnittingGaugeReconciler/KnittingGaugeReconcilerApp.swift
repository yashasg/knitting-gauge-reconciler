import SwiftUI
import MetricKit

@main
struct KnittingGaugeReconcilerApp: App {

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
