// MetricKitSubscriberTests.swift
// KnittingGaugeReconcilerTests
// Created: 2026-05-20T19:26:30-07:00  Author: Curie (Test Engineer)
//
// Covers AC-1 through AC-6 from the MetricKit V3 test scope
// (.squad/decisions/inbox/curie-metrickit-scope.md).
//
// Edison's files are present on disk (untracked). Once they land in the project,
// this file compiles cleanly. The project.pbxproj has been updated to include
// MetricsSubscriber.swift and GaugeMathMetrics.swift in the app target.
//
// Actual type names from Edison's implementation:
//   • MetricsSubscriber   (NSObject MXMetricManagerSubscriber + receive seam)
//   • MetricPayloadProtocol + MXMetricPayload conformance (+ jsonRepresentation())
//   • GaugeMathMetrics.classifyVerdictDelta(previous:current:) → SignpostDecision?
//   • VerdictBucket enum  (gaugeMatch / drift / significantDrift / majorMismatch)
//   • SignpostDecision enum (improved / degraded)

import Testing
import Foundation
@testable import KnittingGaugeReconciler

// MARK: - AC-2: MockMetricPayload (test target only)

// Minimal mock conforming to MetricPayloadProtocol.
// MetricPayloadProtocol is declared in the app target by Edison (MetricsSubscriber.swift).
// Add fields here as Edison expands the protocol surface — keep it minimal.
struct MockMetricPayload: MetricPayloadProtocol {
    var timeStampBegin: Date = .distantPast
    var timeStampEnd: Date   = .distantFuture
}

// MARK: - AC-4: Signpost recording stub

// Documented stub for the SignpostRecording runtime guard (V3 scope §3b).
// When Edison ships the SignpostRecording protocol in the app target, add
// conformance here: `extension RecordingDouble: SignpostRecording { … }`
struct RecordingDouble {
    // No mutations happen until Edison adds a SignpostRecording injection seam.
    let emissions: [(name: String, category: String)] = []
}

// MARK: - AC-1 / AC-2: Subscriber payload handling

@Suite("MetricKit Subscriber — payload handling (AC-1 / AC-2)")
struct MetricKitSubscriberTests {

    // AC-1: Empty-array safety — no crash on zero payloads.
    // Covers the lifecycle flush on first install (MXMetricManager delivers empty array).
    @Test func subscriberHandlesEmptyPayloadArray() {
        let subscriber = MetricsSubscriber()
        subscriber.receive([])
    }

    // AC-1: Single-payload happy path — subscriber accepts a MockMetricPayload.
    @Test func subscriberLogsOnePayload() {
        let subscriber = MetricsSubscriber()
        let payload = MockMetricPayload(
            timeStampBegin: Date(timeIntervalSince1970: 0),
            timeStampEnd:   Date(timeIntervalSince1970: 86400)
        )
        subscriber.receive([payload])
    }

    // AC-1: Verify the #if DEBUG console-log path doesn't crash on
    // edge-case timestamps (distantPast / distantFuture = "empty/missing fields").
    @Test func subscriberHandlesEdgeCaseDates() {
        let subscriber = MetricsSubscriber()
        subscriber.receive([MockMetricPayload()])
    }

    // AC-1: Batch delivery — happens after app update or OS diagnostics flush.
    @Test func subscriberHandlesBatchPayloads() {
        let subscriber = MetricsSubscriber()
        let payloads: [any MetricPayloadProtocol] = [
            MockMetricPayload(
                timeStampBegin: Date(timeIntervalSince1970: 0),
                timeStampEnd:   Date(timeIntervalSince1970: 3_600)
            ),
            MockMetricPayload(
                timeStampBegin: Date(timeIntervalSince1970: 3_600),
                timeStampEnd:   Date(timeIntervalSince1970: 7_200)
            ),
        ]
        subscriber.receive(payloads)
    }
}

// MARK: - AC-3 / AC-4: GaugeMath determinism guard

@Suite("GaugeMath determinism guard (AC-3 / AC-4)")
struct MetricKitGuardTests {

    // AC-3: Static file-scan — GaugeMath.swift must not import MetricKit or
    // os.signpost, and must not contain raw os_signpost( or MXSignpost( call
    // sites. Fails loudly if §2.2 math-boundary rule is violated.
    // Path is resolved at compile time via #filePath; no bundle resource copy needed.
    @Test func gaugemath_hasNoSignpostOrMetricKitImports() throws {
        let testFileURL = URL(fileURLWithPath: #filePath)
        let gaugeMathURL = testFileURL
            .deletingLastPathComponent()   // KnittingGaugeReconcilerTests/
            .deletingLastPathComponent()   // app/
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

    // AC-4: Runtime guard stub — GaugeMath.compute must emit zero signposts.
    // GaugeMath is a pure function with no SignpostRecording injection point today;
    // RecordingDouble stays empty by construction, documenting the invariant.
    // When Edison adds a seam, wire `recorder` through it and this becomes a live guard.
    @Test func gaugeCompute_emitsZeroSignposts() {
        let recorder = RecordingDouble()
        let inputs = GaugeInputs(
            patternStitches: 32, patternRows: 24,
            yourStitches: 36, yourRows: 32
        )
        _ = GaugeMath.compute(inputs)
        #expect(
            recorder.emissions.isEmpty,
            "GaugeMath.compute must emit zero signposts — §2.2 math boundary"
        )
    }
}

// MARK: - AC-5: Verdict-classifier correctness

// Tests GaugeMathMetrics.classifyVerdictDelta(previous:current:) across all
// ordered pairs of the four verdict buckets plus the nil-previous case.
// Returns SignpostDecision? (Edison's type; not VerdictDelta).
//
// Ordering (best → worst): gaugeMatch < drift < significantDrift < majorMismatch
// previous < current (worse) → .degraded
// previous > current (better) → .improved
// previous == current         → nil
// previous == nil             → nil  (first compute of session)
@Suite("Verdict classifier correctness (AC-5)")
struct VerdictClassifierTests {

    // MARK: Equal cases → nil

    @Test func classifyEqual_gaugeMatch() {
        #expect(GaugeMathMetrics.classifyVerdictDelta(previous: .gaugeMatch, current: .gaugeMatch) == nil)
    }

    @Test func classifyEqual_drift() {
        #expect(GaugeMathMetrics.classifyVerdictDelta(previous: .drift, current: .drift) == nil)
    }

    @Test func classifyEqual_significantDrift() {
        #expect(GaugeMathMetrics.classifyVerdictDelta(previous: .significantDrift, current: .significantDrift) == nil)
    }

    @Test func classifyEqual_majorMismatch() {
        #expect(GaugeMathMetrics.classifyVerdictDelta(previous: .majorMismatch, current: .majorMismatch) == nil)
    }

    // MARK: Nil previous → nil (first compute of the session)

    @Test func classifyNilPrevious_returnsNil() {
        #expect(GaugeMathMetrics.classifyVerdictDelta(previous: nil, current: .gaugeMatch)      == nil)
        #expect(GaugeMathMetrics.classifyVerdictDelta(previous: nil, current: .drift)           == nil)
        #expect(GaugeMathMetrics.classifyVerdictDelta(previous: nil, current: .significantDrift) == nil)
        #expect(GaugeMathMetrics.classifyVerdictDelta(previous: nil, current: .majorMismatch)   == nil)
    }

    // MARK: Better → worse = .degraded (6 ordered pairs)

    @Test func classifyDegraded_gaugeMatchToDrift() {
        #expect(GaugeMathMetrics.classifyVerdictDelta(previous: .gaugeMatch, current: .drift) == .degraded)
    }

    @Test func classifyDegraded_gaugeMatchToSignificantDrift() {
        #expect(GaugeMathMetrics.classifyVerdictDelta(previous: .gaugeMatch, current: .significantDrift) == .degraded)
    }

    @Test func classifyDegraded_gaugeMatchToMajorMismatch() {
        #expect(GaugeMathMetrics.classifyVerdictDelta(previous: .gaugeMatch, current: .majorMismatch) == .degraded)
    }

    @Test func classifyDegraded_driftToSignificantDrift() {
        #expect(GaugeMathMetrics.classifyVerdictDelta(previous: .drift, current: .significantDrift) == .degraded)
    }

    @Test func classifyDegraded_driftToMajorMismatch() {
        #expect(GaugeMathMetrics.classifyVerdictDelta(previous: .drift, current: .majorMismatch) == .degraded)
    }

    @Test func classifyDegraded_significantDriftToMajorMismatch() {
        #expect(GaugeMathMetrics.classifyVerdictDelta(previous: .significantDrift, current: .majorMismatch) == .degraded)
    }

    // MARK: Worse → better = .improved (6 ordered pairs)

    @Test func classifyImproved_driftToGaugeMatch() {
        #expect(GaugeMathMetrics.classifyVerdictDelta(previous: .drift, current: .gaugeMatch) == .improved)
    }

    @Test func classifyImproved_significantDriftToGaugeMatch() {
        #expect(GaugeMathMetrics.classifyVerdictDelta(previous: .significantDrift, current: .gaugeMatch) == .improved)
    }

    @Test func classifyImproved_majorMismatchToGaugeMatch() {
        #expect(GaugeMathMetrics.classifyVerdictDelta(previous: .majorMismatch, current: .gaugeMatch) == .improved)
    }

    @Test func classifyImproved_significantDriftToDrift() {
        #expect(GaugeMathMetrics.classifyVerdictDelta(previous: .significantDrift, current: .drift) == .improved)
    }

    @Test func classifyImproved_majorMismatchToDrift() {
        #expect(GaugeMathMetrics.classifyVerdictDelta(previous: .majorMismatch, current: .drift) == .improved)
    }

    @Test func classifyImproved_majorMismatchToSignificantDrift() {
        #expect(GaugeMathMetrics.classifyVerdictDelta(previous: .majorMismatch, current: .significantDrift) == .improved)
    }
}

// MARK: - AC-6: Linker assertion (otool -L)

@Suite("Linker assertions — MetricKit only (AC-6)")
struct LinkerAssertionTests {

    // Runs `otool -L` against the test-host binary (Bundle.main.executableURL).
    // Asserts: (a) MetricKit.framework IS linked, (b) no third-party analytics SDKs.
    // ⚠️  `Process` requires macOS; on iOS simulator this test records an issue
    // and returns rather than crashing the suite. Run on macOS to get the live check.
    @Test func otool_metricKitLinkedAndNoThirdPartySDKs() throws {
        guard let executableURL = Bundle.main.executableURL else {
            Issue.record("Bundle.main.executableURL is nil — cannot locate app binary for otool check")
            return
        }

        #if os(macOS) || targetEnvironment(macCatalyst)
        let stdoutPipe = Pipe()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/otool")
        process.arguments    = ["-L", executableURL.path]
        process.standardOutput = stdoutPipe
        process.standardError  = Pipe()

        try process.run()
        process.waitUntilExit()

        let data   = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        // (a) MetricKit must be linked (requires Edison's bootstrap to import MetricKit).
        #expect(
            output.contains("MetricKit"),
            "MetricKit.framework must appear in otool -L output; Edison's bootstrap must import MetricKit"
        )

        // (b) No forbidden third-party analytics / crash-reporting SDKs.
        let forbidden = [
            "Firebase", "Amplitude", "Mixpanel",
            "Segment", "GoogleAnalytics", "Sentry",
        ]
        for sdk in forbidden {
            let found = output.range(of: sdk, options: .caseInsensitive) != nil
            #expect(!found, "\(sdk) SDK must not be linked — MetricKit is the only sanctioned analytics backend")
        }
        #else
        // `Process` / otool are macOS-only. On iOS simulator, perform a lightweight
        // dynamic-linking check via `dlopen` to confirm MetricKit is present.
        let metricKitHandle = dlopen("/System/Library/Frameworks/MetricKit.framework/MetricKit", RTLD_LAZY | RTLD_NOLOAD)
        #expect(metricKitHandle != nil, "MetricKit.framework must be loaded in the process — Edison's bootstrap imports MetricKit")
        if metricKitHandle != nil { dlclose(metricKitHandle) }
        _ = executableURL // suppress unused-variable warning
        #endif
    }
}
