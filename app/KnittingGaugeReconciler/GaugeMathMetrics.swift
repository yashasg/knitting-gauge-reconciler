import Foundation

// MARK: - VerdictBucket

/// Ordered distance from gaugeMatch. Lower index = closer to ideal.
/// The ordering is: gaugeMatch < drift < significantDrift < majorMismatch.
/// `GaugeMath.swift` must NOT import this file or reference these types.
enum VerdictBucket: Int, Comparable, Sendable {
    case gaugeMatch       = 0
    case drift            = 1
    case significantDrift = 2
    case majorMismatch    = 3

    static func < (lhs: VerdictBucket, rhs: VerdictBucket) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// Maps the `verdictTitle` string (from ContentView) to a bucket.
    init(verdictTitle: String) {
        switch verdictTitle {
        case "Gauge match":       self = .gaugeMatch
        case "Drift":             self = .drift
        case "Significant drift": self = .significantDrift
        default:                  self = .majorMismatch
        }
    }
}

// MARK: - SignpostDecision

enum SignpostDecision: Sendable {
    case improved
    case degraded
}

// MARK: - GaugeMathMetrics

/// Verdict-improved / verdict-degraded comparator. Per-session in-memory
/// state only — no persistence. Lives outside GaugeMath per Ada's V2
/// boundary requirement (GaugeMath.swift must stay instrumentation-free).
enum GaugeMathMetrics {

    /// Compares `current` verdict bucket against the `previous` one.
    /// Returns `.improved` when `current` is closer to gaugeMatch than
    /// `previous`, `.degraded` when farther, or `nil` when equal or when
    /// there is no prior observation (first compute in the session).
    static func classifyVerdictDelta(
        previous: VerdictBucket?,
        current: VerdictBucket
    ) -> SignpostDecision? {
        guard let previous, previous != current else { return nil }
        return current < previous ? .improved : .degraded
    }
}
