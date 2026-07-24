import Foundation
import Testing
@testable import KnittingGaugeReconciler

@Suite("GaugeMath determinism guard")
struct MetricKitGuardTests {
    private var contentViewSource: String {
        get throws {
            let testFileURL = URL(fileURLWithPath: #filePath)
            let contentViewURL = testFileURL
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent("KnittingGaugeReconciler")
                .appendingPathComponent("ContentView.swift")
            return try String(contentsOf: contentViewURL, encoding: .utf8)
        }
    }

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

    @Test func gaugeFormBodyComputesOneSnapshotAndReusesItEverywhere() throws {
        let source = try contentViewSource
        let formStart = try #require(source.range(of: "struct GaugeFormView: View {"))
        let bodyStart = try #require(
            source.range(
                of: "    var body: some View {",
                range: formStart.upperBound..<source.endIndex
            )
        )
        let navigationStart = try #require(
            source.range(
                of: "    private func workspaceContent(",
                range: bodyStart.upperBound..<source.endIndex
            )
        )
        let bodySource = source[bodyStart.lowerBound..<navigationStart.lowerBound]
        #expect(bodySource.contains("let currentInputs = inputs"))
        #expect(bodySource.contains("let currentResult = Self.computeResult(currentInputs)"))
        #expect(bodySource.count(of: "Self.computeResult(") == 1)

        let navigationEnd = try #require(
            source.range(
                of: "    static func aboutHelpSheet(",
                range: navigationStart.upperBound..<source.endIndex
            )
        )
        let navigationSource = source[navigationStart.lowerBound..<navigationEnd.lowerBound]
        #expect(navigationSource.contains("Self.inputPresentation(currentInputs)"))
        #expect(navigationSource.contains("result: currentResult"))
        #expect(navigationSource.contains("inputs: currentInputs"))
        #expect(
            navigationSource.contains(
                ".onChange(of: Self.hasCastOnDrift(currentResult), castOnDriftChanged)"
            )
        )
        #expect(!navigationSource.contains("computeResult("))
        #expect(!source.contains("liveResult"))
    }

    @Test func computeHelperKeepsOneBalancedSignpostSequence() throws {
        let source = try contentViewSource
        let helperStart = try #require(source.range(of: "    static func computeResult("))
        let helperEnd = try #require(
            source.range(
                of: "    static func inputPresentation(",
                range: helperStart.upperBound..<source.endIndex
            )
        )
        let helper = source[helperStart.lowerBound..<helperEnd.lowerBound]
        let begin = try #require(helper.range(of: "os_signpost(.begin"))
        let compute = try #require(helper.range(of: "GaugeMath.compute(inputs)"))
        let end = try #require(helper.range(of: "os_signpost(.end"))

        #expect(helper.count(of: "os_signpost(.begin") == 1)
        #expect(helper.count(of: "GaugeMath.compute(inputs)") == 1)
        #expect(helper.count(of: "os_signpost(.end") == 1)
        #expect(begin.lowerBound < compute.lowerBound)
        #expect(compute.lowerBound < end.lowerBound)
    }

    @Test func unitReconciliationHasOnlyLifecycleEntryPoints() throws {
        let source = try contentViewSource
        let bindingStart = try #require(source.range(of: "    var measurementUnitBinding:"))
        let bindingEnd = try #require(
            source.range(
                of: "    static func reconciledSceneDraft(",
                range: bindingStart.upperBound..<source.endIndex
            )
        )
        let binding = source[bindingStart.lowerBound..<bindingEnd.lowerBound]
        #expect(binding.contains("guard newUnit != measurementUnit else { return }"))
        #expect(binding.contains("measurementUnit = newUnit"))
        #expect(!binding.contains("reconcileSceneDraft("))
        #expect(!binding.contains("previousUnit"))

        #expect(
            source.count(
                of: ".onChange(of: measurementUnit, measurementUnitChanged)"
            ) == 1
        )

        let changeStart = try #require(source.range(of: "    func measurementUnitChanged("))
        let changeEnd = try #require(
            source.range(
                of: "    func fieldFocusChanged(",
                range: changeStart.upperBound..<source.endIndex
            )
        )
        let changeHandler = source[changeStart.lowerBound..<changeEnd.lowerBound]
        #expect(changeHandler.count(of: "reconcileSceneDraft(") == 1)

        let appearStart = try #require(source.range(of: "    func sceneDidAppear()"))
        let appearEnd = try #require(
            source.range(
                of: "    static func driftBandSignpostName(",
                range: appearStart.upperBound..<source.endIndex
            )
        )
        let appearHandler = source[appearStart.lowerBound..<appearEnd.lowerBound]
        #expect(appearHandler.contains("SceneDraftStore.reconcileInvalidInchProvenance("))
        #expect(!source.contains("UserDefaults.standard.synchronize()"))
        #expect(!source.contains("synchronizingDefaults"))
    }
}

private extension StringProtocol {
    func count(of token: String) -> Int {
        components(separatedBy: token).count - 1
    }
}
