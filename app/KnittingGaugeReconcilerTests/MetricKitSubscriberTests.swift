import Foundation
import Testing
@testable import KnittingGaugeReconciler

@Suite("GaugeMath determinism guard")
struct MetricKitGuardTests {
    @Test func gaugeMathHasNoSignpostOrMetricKitImports() throws {
        let testFileURL = URL(fileURLWithPath: #filePath)
        let gaugeMathURL = testFileURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("KnittingGaugeReconciler")
            .appendingPathComponent("GaugeMath.swift")

        let source = try String(contentsOf: gaugeMathURL, encoding: .utf8)
        let banned = [
            "import os.signpost",
            "import MetricKit",
            "os_signpost(",
            "MXSignpost(",
        ]

        for token in banned {
            #expect(
                !source.contains(token),
                "GaugeMath.swift must not contain '\(token)' — §2.2 math boundary"
            )
        }
    }
}

@Suite("Verdict telemetry")
struct VerdictTelemetryTests {
    @Test func transitionsMapToSignposts() {
        let cases: [(previous: VerdictBucket?, current: VerdictBucket?, expected: String?)] = [
            (nil, .gaugeMatch, nil),
            (.gaugeMatch, nil, nil),
            (.drift, .drift, nil),
            (.majorMismatch, .gaugeMatch, "verdict.improved"),
            (.gaugeMatch, .majorMismatch, "verdict.degraded"),
        ]

        for testCase in cases {
            let actual = VerdictBucket.signpostName(
                previous: testCase.previous,
                current: testCase.current
            )
            #expect(actual?.description == testCase.expected)
        }
    }
}
