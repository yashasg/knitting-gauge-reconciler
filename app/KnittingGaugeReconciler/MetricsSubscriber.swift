import MetricKit
import os

/// Static-string name table for all MXSignpost call sites.
/// Names must be string literals — never runtime-interpolated.
enum SignpostNames {
    static let log: OSLog = MXMetricManager.makeLogHandle(category: "user_actions")
    static let compute: StaticString                = "compute"                   // INTERVAL
    static let shareInvoked: StaticString           = "share.invoked"             // EVENT
    static let shareFallback: StaticString          = "share.fallback"            // EVENT
    static let resetTapped: StaticString            = "reset.tapped"              // EVENT
    static let verdictImproved: StaticString        = "verdict.improved"          // EVENT
    static let verdictDegraded: StaticString        = "verdict.degraded"          // EVENT
    static let sheetAboutHelpOpened: StaticString   = "sheet.aboutHelp.opened"    // EVENT
    static let castOnDriftBandShown: StaticString   = "cast_on.driftBandShown"    // EVENT
}
