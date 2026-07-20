import Foundation
import MetricKit
import os

// MARK: - SignpostNames

/// Static-string name table for all MXSignpost call sites.
/// Names must be string literals — never runtime-interpolated.
enum SignpostNames {
    static let compute: StaticString                = "compute"                   // INTERVAL
    static let shareInvoked: StaticString           = "share.invoked"             // EVENT
    static let shareFallback: StaticString          = "share.fallback"            // EVENT
    static let resetTapped: StaticString            = "reset.tapped"              // EVENT
    static let verdictImproved: StaticString        = "verdict.improved"          // EVENT
    static let verdictDegraded: StaticString        = "verdict.degraded"          // EVENT
    static let sheetAboutHelpOpened: StaticString   = "sheet.aboutHelp.opened"    // EVENT
    static let castOnDriftBandShown: StaticString   = "cast_on.driftBandShown"    // EVENT
}

// MARK: - MetricsSubscriber

final class MetricsSubscriber: NSObject, MXMetricManagerSubscriber {

    /// Shared MetricKit log handle. All MXSignpost call sites use this handle.
    /// `MXMetricManager.makeLogHandle(category:)` is required — a plain OSLog
    /// will not aggregate through MetricKit's pipeline.
    static let log: OSLog = MXMetricManager.makeLogHandle(category: "user_actions")

    // MARK: MXMetricManagerSubscriber

    func didReceive(_ payloads: [MXMetricPayload]) {
        #if DEBUG
        for payload in payloads {
            print("[MetricsSubscriber] MXMetricPayload received:")
            print(String(data: payload.jsonRepresentation(), encoding: .utf8) ?? "<non-utf8 payload>")
        }
        #endif
    }

    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        #if DEBUG
        for payload in payloads {
            print("[MetricsSubscriber] MXDiagnosticPayload received:")
            print(String(data: payload.jsonRepresentation(), encoding: .utf8) ?? "<non-utf8 payload>")
        }
        #endif
    }
}
