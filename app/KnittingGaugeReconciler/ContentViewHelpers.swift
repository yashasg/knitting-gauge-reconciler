import SwiftUI
import UIKit

// MARK: - ActivityView

struct ActivityView: UIViewControllerRepresentable {
    var activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - GaugeTextDefaults

struct GaugeTextDefaults {
    let patternStitches = "32"
    let patternRows = "24"
    let yourStitches = "32"
    let yourRows = "32"
    let patternCastOn = "128"
    let patternYoke = "20"
    let patternBody = "50"
    let patternSleeve = "45"
    let patternIncreases = "6"
}

// MARK: - Helpers

func initialText(_ environmentKey: String, defaultValue: String) -> String {
    ProcessInfo.processInfo.environment[environmentKey] ?? defaultValue
}

func initialBool(_ environmentKey: String) -> Bool {
    ProcessInfo.processInfo.environment[environmentKey] == "1"
}

func read(_ text: String, defaultValue: Double) -> Double {
    GaugeMath.sanitized(Double(text), default: defaultValue)
}
