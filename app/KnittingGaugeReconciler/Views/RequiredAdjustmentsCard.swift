// swiftlint:disable file_length
// Issue #65 keeps conditional result, reset, and share UI in this existing authorized file.
import SwiftUI

enum ResultSectionKind: String, CaseIterable {
    case gaugeSummary
    case yokeDepth
    case bodyAndSleeves
    case shapingRates
    case castOn
    case actions
}

enum ResultActionKind: CaseIterable, Hashable {
    case share
    case fullMath

    func label(isExpanded: Bool) -> String {
        switch self {
        case .share:
            return "Share results"
        case .fullMath:
            return isExpanded ? "Hide full math" : "Show full math"
        }
    }
}

struct ResultCardSemantics: Equatable {
    let sectionKinds: [ResultSectionKind]
    let stitchComparison: String
    let rowComparison: String
    let stitchSummary: String
    let rowSummary: String
    let castOnGuidance: String?

    init(
        inputs: GaugeInputs,
        result: GaugeMathResult,
        unit: MeasurementUnit = .centimeters
    ) {
        var kinds: [ResultSectionKind] = [.gaugeSummary]
        if inputs.patternYokeDepth != nil, result.adjustedYokeDepth != nil {
            kinds.append(.yokeDepth)
        }
        if inputs.patternBodyLength != nil || inputs.patternSleeveLength != nil {
            kinds.append(.bodyAndSleeves)
        }
        if inputs.patternIncreaseSpacing != nil, result.adjustedIncreaseSpacing != nil {
            kinds.append(.shapingRates)
        }
        if inputs.patternCastOn != nil {
            kinds.append(.castOn)
        }
        kinds.append(.actions)
        sectionKinds = kinds
        let gaugeBasis = unit == .centimeters ? "10 cm" : "4 in"
        let spokenGaugeBasis = unit == .centimeters ? "per 10 centimeters" : "per 4 inches"
        let stitchGaugeComparison =
            "Pattern \(plain(inputs.patternStitches)) st/\(gaugeBasis) · " +
            "Swatch \(plain(inputs.yourStitches)) st/\(gaugeBasis)"
        let rowGaugeComparison =
            "Pattern \(plain(inputs.patternRows)) rows/\(gaugeBasis) · " +
            "Swatch \(plain(inputs.yourRows)) rows/\(gaugeBasis)"
        stitchComparison = stitchGaugeComparison
        rowComparison = rowGaugeComparison
        stitchSummary =
            "Stitch-wise, horizontal. Pattern \(plain(inputs.patternStitches)) stitches \(spokenGaugeBasis). " +
            "Swatch \(plain(inputs.yourStitches)) stitches \(spokenGaugeBasis). " +
            "\(GaugeMath.fmtPct(result.stitchWidthScale))% of pattern width."
        rowSummary =
            "Row-wise, vertical. Pattern \(plain(inputs.patternRows)) rows \(spokenGaugeBasis). " +
            "Swatch \(plain(inputs.yourRows)) rows \(spokenGaugeBasis). " +
            "\(GaugeMath.fmtPct(result.rowCountScale))% of pattern row density."
        castOnGuidance = castOnGuidanceText(inputs: inputs, result: result)
    }
}

struct SharePreparationState {
    var payload: ShareSheetPayload?
    var isPreparing = false

    mutating func begin() {
        guard !isPreparing else { return }
        isPreparing = true
    }

    mutating func finish(items: [Any], cancelled: Bool) {
        if !cancelled {
            payload = ShareSheetPayload(items: items)
        }
        isPreparing = false
    }

    @MainActor mutating func prepare(
        result: GaugeMathResult,
        onShare: (GaugeMathResult) async -> [Any]
    ) async {
        guard isPreparing else { return }
        let items = await onShare(result)
        finish(items: items, cancelled: Task.isCancelled)
    }
}

struct RequiredAdjustmentsCard: View {
    @Binding private var showFullMath: Bool
    @State private var showResetConfirmation = false

    private let result: GaugeMathResult?
    private let inputs: GaugeInputs?
    private let correctionMessage: String?
    private let unit: MeasurementUnit
    private let canUndoReset: Bool
    private let onCorrect: () -> Void
    private let onReset: () -> Void
    private let onUndoReset: () -> Void
    private let onShare: (GaugeMathResult) async -> [Any]

    init(
        result: GaugeMathResult?,
        inputs: GaugeInputs?,
        correctionMessage: String?,
        unit: MeasurementUnit,
        showFullMath: Binding<Bool>,
        canUndoReset: Bool,
        onCorrect: @escaping () -> Void,
        onReset: @escaping () -> Void,
        onUndoReset: @escaping () -> Void,
        onShare: @escaping (GaugeMathResult) async -> [Any]
    ) {
        self.result = result
        self.inputs = inputs
        self.correctionMessage = correctionMessage
        self.unit = unit
        self._showFullMath = showFullMath
        self.canUndoReset = canUndoReset
        self.onCorrect = onCorrect
        self.onReset = onReset
        self.onUndoReset = onUndoReset
        self.onShare = onShare
    }

    func requestReset() {
        showResetConfirmation = true
    }

    func keepEditing() {
        showResetConfirmation = false
    }

    func requestCorrection() {
        onCorrect()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: requestCorrection) {
                Label("View results", systemImage: "wand.and.stars")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.cream)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minWidth: 176, minHeight: 44)
                    .padding(.horizontal, 18)
                    .contentShape(Capsule())
                    .background(AppTheme.sage)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .center)
            .accessibilityLabel("View results")
            .accessibilityValue(correctionMessage ?? "")
            .accessibilityHint("Validates the form and focuses the first field that needs correction")

            if let result, let inputs {
                LiveResultsView(
                    result: result,
                    inputs: inputs,
                    unit: unit,
                    showFullMath: $showFullMath,
                    onShare: onShare
                )
            }

            resetActions
        }
        .alert("Reset all values?", isPresented: $showResetConfirmation) {
            Button("Reset values", role: .destructive, action: onReset)
            Button("Keep editing", role: .cancel, action: keepEditing)
        } message: {
            Text("This clears every entry.")
        }
    }

    @ViewBuilder
    private var resetActions: some View {
        if canUndoReset {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: 16) {
                    resetButton
                        .fixedSize(horizontal: true, vertical: false)
                    Spacer(minLength: 0)
                    undoResetButton
                        .fixedSize(horizontal: true, vertical: false)
                }

                VStack(alignment: .leading, spacing: 4) {
                    resetButton
                        .frame(maxWidth: .infinity, alignment: .leading)
                    undoResetButton
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        } else {
            resetButton
        }
    }

    private var resetButton: some View {
        Button("Reset values", action: requestReset)
            .buttonStyle(.plain)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppTheme.ink)
            .frame(minWidth: 44, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
            .accessibilityHint("Opens a confirmation before replacing every entry")
    }

    private var undoResetButton: some View {
        Button("Undo reset", action: onUndoReset)
            .buttonStyle(.plain)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
            .frame(minWidth: 44, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
            .accessibilityHint("Restores every value from before the last reset")
    }
}

// swiftlint:disable:next type_body_length
struct LiveResultsView: View {
    @State private var sharePreparation = SharePreparationState()

    private let result: GaugeMathResult
    private let inputs: GaugeInputs
    private let unit: MeasurementUnit
    @Binding private var showFullMath: Bool
    private let onShare: (GaugeMathResult) async -> [Any]

    init(
        result: GaugeMathResult,
        inputs: GaugeInputs,
        unit: MeasurementUnit,
        showFullMath: Binding<Bool>,
        onShare: @escaping (GaugeMathResult) async -> [Any]
    ) {
        self.result = result
        self.inputs = inputs
        self.unit = unit
        self._showFullMath = showFullMath
        self.onShare = onShare
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reconciliation — both axes")
                .font(.title2.weight(.bold))
                .foregroundStyle(AppTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            HeroTilesView(result: result, semantics: semantics)

            if semantics.sectionKinds.contains(.yokeDepth),
               let patternDepth = inputs.patternYokeDepth,
               let adjustedDepth = result.adjustedYokeDepth,
               let patternRows = result.patternYokeRows,
               let adjustedRows = result.adjustedYokeRows {
                sectionCard(title: "Yoke Depth", subtitle: "Keep the requested length") {
                    AdjustmentRow(
                        name: "Yoke depth",
                        pattern: "\(unit.formatMeasurement(patternDepth)) / \(GaugeMath.fmtRows(patternRows)) rows",
                        adjusted: "\(unit.formatResultMeasurement(adjustedDepth)) / " +
                            "\(GaugeMath.fmtRows(adjustedRows)) rows"
                    )
                }
            }

            if semantics.sectionKinds.contains(.bodyAndSleeves) {
                sectionCard(title: "Body & Sleeves", subtitle: "Rows at your gauge") {
                    VStack(spacing: 12) {
                        if let patternLength = inputs.patternBodyLength,
                           let adjustedLength = result.adjustedBodyLength,
                           let patternRows = result.patternBodyRows,
                           let adjustedRows = result.adjustedBodyRows {
                            AdjustmentRow(
                                name: "Body length",
                                pattern: "\(unit.formatMeasurement(patternLength)) / " +
                                    "\(GaugeMath.fmtRows(patternRows)) rows",
                                adjusted: "\(unit.formatResultMeasurement(adjustedLength)) / " +
                                    "\(GaugeMath.fmtRows(adjustedRows)) rows"
                            )
                        }
                        if let patternLength = inputs.patternSleeveLength,
                           let adjustedLength = result.adjustedSleeveLength,
                           let patternRows = result.patternSleeveRows,
                           let adjustedRows = result.adjustedSleeveRows {
                            AdjustmentRow(
                                name: "Sleeve length",
                                pattern: "\(unit.formatMeasurement(patternLength)) / " +
                                    "\(GaugeMath.fmtRows(patternRows)) rows",
                                adjusted: "\(unit.formatResultMeasurement(adjustedLength)) / " +
                                    "\(GaugeMath.fmtRows(adjustedRows)) rows"
                            )
                        }
                    }
                }
            }

            if semantics.sectionKinds.contains(.shapingRates),
               let patternSpacing = inputs.patternIncreaseSpacing,
               let adjustedSpacing = result.adjustedIncreaseSpacing {
                sectionCard(title: "Shaping Rates", subtitle: "Increases / decreases") {
                    AdjustmentRow(
                        name: "Increase-row spacing",
                        pattern: "Every \(plain(patternSpacing)) rows",
                        adjusted: "Every \(GaugeMath.fmtRows(adjustedSpacing)) rows"
                    )
                }
            }

            if semantics.sectionKinds.contains(.castOn),
               let patternCastOn = inputs.patternCastOn {
                let adjustedCastOn = result.adjustedCastOn
                let castOnSubtitle = gaugeStatus(scale: result.stitchWidthScale) == "Match" &&
                    adjustedCastOn.map { Double($0) != patternCastOn } == true
                    ? "Optional width refinement"
                    : "To preserve pattern width"
                sectionCard(title: "Cast-on", subtitle: castOnSubtitle) {
                    if let adjustedCastOn {
                        VStack(alignment: .leading, spacing: 8) {
                            AdjustmentRow(
                                name: "Cast-on stitches",
                                pattern: "\(plain(patternCastOn)) stitches",
                                adjusted: "\(adjustedCastOn) stitches",
                                driftPill: castOnDriftPill
                            )
                            Text("Reconcile this rounded stitch count with your pattern's stitch-repeat multiple.")
                                .font(.caption)
                                .foregroundStyle(AppTheme.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    } else if let guidance = semantics.castOnGuidance {
                        Text(guidance)
                            .font(.callout)
                            .foregroundStyle(AppTheme.warningText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            actionsCard
        }
        .sheet(item: $sharePreparation.payload, content: activityView)
        .task(id: sharePreparation.isPreparing, prepareShare)
        .accessibilityElement(children: .contain)
        .accessibilityHidden(false)
    }

    private var semantics: ResultCardSemantics {
        ResultCardSemantics(inputs: inputs, result: result, unit: unit)
    }

    func activityView(_ payload: ShareSheetPayload) -> some View {
        ActivityView(activityItems: payload.items)
            .presentationDetents([.medium, .large])
    }

    func beginSharing() {
        sharePreparation.begin()
    }

    func prepareShare() async {
        var preparation = sharePreparation
        await preparation.prepare(result: result, onShare: onShare)
        sharePreparation = preparation
    }

    func toggleFullMath() {
        showFullMath.toggle()
    }

    var castOnDriftPill: String? {
        guard let drift = result.castOnRoundingDriftPercent, abs(drift) >= 3 else {
            return nil
        }
        return GaugeMath.fmtSignedPct(drift)
    }

    private func sectionCard<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(nil)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityAddTraits(.isHeader)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted)
                    .lineLimit(nil)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            content()
        }
        .cardStyle()
    }

    private var actionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(ResultActionKind.allCases, id: \.self) { action in
                actionView(action)
            }
        }
        .cardStyle()
    }

    @ViewBuilder
    private func actionView(_ action: ResultActionKind) -> some View {
        switch action {
        case .share:
            Button(action: beginSharing) {
                HStack {
                    Text(action.label(isExpanded: showFullMath))
                    Spacer()
                    Image(systemName: "square.and.arrow.up")
                        .accessibilityHidden(true)
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppTheme.ink)
            .disabled(sharePreparation.isPreparing)
            .accessibilityHint("Opens the share sheet with an image of the current results")
        case .fullMath:
            VStack(alignment: .leading, spacing: 12) {
                Button(
                    action: toggleFullMath,
                    label: {
                    HStack {
                        Text(action.label(isExpanded: showFullMath))
                        Spacer()
                        Image(systemName: showFullMath ? "chevron.up" : "chevron.down")
                            .font(.caption.weight(.bold))
                    }
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                    }
                )
                .buttonStyle(.plain)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.ink)
                .accessibilityLabel(action.label(isExpanded: showFullMath))

                if showFullMath {
                    Text(fullMathBreakdown)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(AppTheme.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(AppTheme.accentSoft)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                }
            }
        }
    }

    // swiftlint:disable line_length
    var fullMathBreakdown: String {
        let gaugeBasis = unit == .centimeters ? "10 centimeters" : "4 inches"
        var lines = [
            "pattern: \(plain(inputs.patternStitches)) st x \(plain(inputs.patternRows)) rows per \(gaugeBasis) (aspect \(String(format: "%.2f", inputs.patternStitches / inputs.patternRows)))",
            "you:     \(plain(inputs.yourStitches)) st x \(plain(inputs.yourRows)) rows per \(gaugeBasis) (aspect \(String(format: "%.2f", inputs.yourStitches / inputs.yourRows)))",
            "stitch width scale = pattern_st / your_st = \(plain(inputs.patternStitches)) / \(plain(inputs.yourStitches)) = \(String(format: "%.3f", result.stitchWidthScale))",
            "row density ratio  = your_row / pattern_row = \(plain(inputs.yourRows)) / \(plain(inputs.patternRows)) = \(String(format: "%.3f", result.rowCountScale))",
            "section rows       = section cm x your_row / 10",
            "for any horizontal dim, your stitch count produces \(String(format: "%.1f", result.stitchWidthScale * 100))% of the pattern's intended width"
        ]
        if let patternDepth = inputs.patternYokeDepth,
           let adjustedDepth = result.adjustedYokeDepth,
           let patternRows = result.patternYokeRows,
           let adjustedRows = result.adjustedYokeRows {
            lines.append(
                "yoke: \(unit.formatMeasurement(patternDepth)) / \(GaugeMath.fmtRows(patternRows)) rows → " +
                    "\(unit.formatResultMeasurement(adjustedDepth)) / \(GaugeMath.fmtRows(adjustedRows)) rows"
            )
        }
        if let patternLength = inputs.patternBodyLength,
           let adjustedLength = result.adjustedBodyLength,
           let patternRows = result.patternBodyRows,
           let adjustedRows = result.adjustedBodyRows {
            lines.append(
                "body: \(unit.formatMeasurement(patternLength)) / \(GaugeMath.fmtRows(patternRows)) rows → " +
                    "\(unit.formatResultMeasurement(adjustedLength)) / \(GaugeMath.fmtRows(adjustedRows)) rows"
            )
        }
        if let patternLength = inputs.patternSleeveLength,
           let adjustedLength = result.adjustedSleeveLength,
           let patternRows = result.patternSleeveRows,
           let adjustedRows = result.adjustedSleeveRows {
            lines.append(
                "sleeve: \(unit.formatMeasurement(patternLength)) / \(GaugeMath.fmtRows(patternRows)) rows → " +
                    "\(unit.formatResultMeasurement(adjustedLength)) / \(GaugeMath.fmtRows(adjustedRows)) rows"
            )
        }
        if let spacing = inputs.patternIncreaseSpacing, let adjusted = result.adjustedIncreaseSpacing {
            lines.append("increase spacing = \(plain(spacing)) x row density = \(GaugeMath.fmtRows(adjusted)) rows")
        }
        if let castOn = inputs.patternCastOn {
            if let adjusted = result.adjustedCastOn {
                lines.append("cast-on adjust = your_st / pattern_st x \(plain(castOn)) = \(adjusted) stitches")
                lines.append("reconcile the rounded stitch count with the pattern stitch-repeat multiple")
            } else if let guidance = semantics.castOnGuidance {
                lines.append("cast-on adjust = your_st / pattern_st x \(plain(castOn)); \(guidance)")
            }
        }
        return lines.joined(separator: "\n")
    }
    // swiftlint:enable line_length
}

struct HeroTilesView: View {
    var result: GaugeMathResult
    var semantics: ResultCardSemantics

    var body: some View {
        GaugeMeasurementPair(spacing: 12) {
            HeroTile(
                label: "Stitch-wise (horizontal)",
                value: "\(GaugeMath.fmtPct(result.stitchWidthScale))%",
                status: gaugeStatus(scale: result.stitchWidthScale),
                detail: semantics.stitchComparison,
                accessibilityLabel: semantics.stitchSummary
            )
        } trailing: {
            HeroTile(
                label: "Row-wise (vertical)",
                value: "\(GaugeMath.fmtPct(result.rowCountScale))%",
                status: rowStatus(scale: result.rowCountScale),
                detail: semantics.rowComparison,
                accessibilityLabel: semantics.rowSummary
            )
        }
        .accessibilityElement(children: .contain)
    }
}

private struct HeroTile: View {
    @Environment(\.colorScheme) private var colorScheme

    var label: String
    var value: String
    var status: String
    var detail: String
    var accessibilityLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.muted)
            Text(value)
                .font(.system(.title2, design: .monospaced).weight(.bold))
                .foregroundStyle(AppTheme.ink)
            statusBadge
            Text(detail)
                .font(.caption2)
                .foregroundStyle(AppTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        .padding(14)
        .background(AppTheme.oatmeal)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(status)
    }

    private var statusBadge: some View {
        ViewThatFits(in: .horizontal) {
            statusText
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .clipShape(Capsule())

            statusText
                .fixedSize(horizontal: false, vertical: true)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var statusText: some View {
        Text(status)
            .font(.caption.weight(.semibold))
            .foregroundStyle(colorScheme == .dark && status != "Match" ? .black : .white)
            .padding(.horizontal, 10)
            .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
            .frame(minHeight: 44)
            .background(tileBackground(status))
    }

    // swiftlint:disable:next identifier_name
    private func tileBackground(_ s: String) -> Color {
        if s == "Match" { return AppTheme.sage }
        if s.hasPrefix("Much") { return AppTheme.terracotta }
        return AppTheme.secondary
    }
}
