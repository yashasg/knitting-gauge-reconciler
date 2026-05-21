import Foundation
import MetricKit
import os

// MARK: - MetricPayloadProtocol

/// Minimal protocol surface for the testable receive seam.
/// Only add fields as the subscriber actually consumes them.
/// `jsonRepresentation()` is intentionally excluded — logging
/// uses the concrete `MXMetricPayload` in `didReceive`, keeping
/// the mock (Curie's MockMetricPayload) as a simple struct.
protocol MetricPayloadProtocol {
    var timeStampBegin: Date { get }
    var timeStampEnd: Date { get }
}

extension MXMetricPayload: MetricPayloadProtocol {}

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
    static let sheetVerdictHelpOpened: StaticString = "sheet.verdictHelp.opened"  // EVENT
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
        receive(payloads)
        // V1: rely on Apple's auto-flow to App Store Connect Analytics.
        // V2 (deferred): POST jsonRepresentation() to developer endpoint via receive().
    }

    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        #if DEBUG
        for payload in payloads {
            print("[MetricsSubscriber] MXDiagnosticPayload received:")
            print(String(data: payload.jsonRepresentation(), encoding: .utf8) ?? "<non-utf8 payload>")
        }
        #endif
        // V1: rely on Apple's auto-flow to App Store Connect Analytics.
        // V2 (deferred): POST jsonRepresentation() to developer endpoint.
    }

    // MARK: Internal seam (testable via Curie's MockMetricPayload)

    /// Routes payloads through the protocol seam so unit tests can inject
    /// mock payloads without constructing a real MXMetricPayload.
    /// V2: add developer-endpoint POST here.
    func receive(_ payloads: [any MetricPayloadProtocol]) {
        // V1: no-op. Apple's MetricKit pipeline handles delivery to App Store Connect.
        // V2 (deferred): POST to developer endpoint using jsonRepresentation()
        // (available on concrete MXMetricPayload, cast or re-receive as needed).
    }
}
