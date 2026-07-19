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
