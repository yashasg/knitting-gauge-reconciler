import MetricKit
import os

enum SignpostNames {
    static let log: OSLog = MXMetricManager.makeLogHandle(category: "user_actions")
    static let compute: StaticString = "compute"
    static let shareInvoked: StaticString = "share.invoked"
    static let shareFallback: StaticString = "share.fallback"
    static let resetTapped: StaticString = "reset.tapped"
    static let verdictImproved: StaticString = "verdict.improved"
    static let verdictDegraded: StaticString = "verdict.degraded"
    static let sheetAboutHelpOpened: StaticString = "sheet.aboutHelp.opened"
    static let castOnDriftBandShown: StaticString = "cast_on.driftBandShown"
}

// MARK: - VerdictBucket

/// Ordered distance from gaugeMatch. Lower index = closer to ideal.
/// The ordering is: gaugeMatch < drift < significantDrift < majorMismatch.
/// `GaugeMath.swift` must NOT import this file or reference these types.
enum VerdictBucket: Int, Sendable {
    case gaugeMatch       = 0
    case drift            = 1
    case significantDrift = 2
    case majorMismatch    = 3

    /// Maps the `verdictTitle` string (from ContentView) to a bucket.
    init(verdictTitle: String) {
        switch verdictTitle {
        case "Gauge match":       self = .gaugeMatch
        case "Drift":             self = .drift
        case "Significant drift": self = .significantDrift
        default:                  self = .majorMismatch
        }
    }

    static func signpostName(
        previous: VerdictBucket?,
        current: VerdictBucket?
    ) -> StaticString? {
        guard let previous, let current, previous != current else { return nil }
        return current.rawValue < previous.rawValue
            ? SignpostNames.verdictImproved
            : SignpostNames.verdictDegraded
    }
}
