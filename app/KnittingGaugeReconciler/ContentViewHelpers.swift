import SwiftUI
import UIKit

func newValidationAnnouncement(
    previous: [GaugeFormField: String],
    current: [GaugeFormField: String]
) -> String? {
    GaugeFormField.allCases.first(where: {
        previous[$0] != current[$0] && current[$0] != nil
    }).flatMap { current[$0] }
}

// MARK: - SceneSessionReader

struct SceneSessionReader: UIViewRepresentable {
    let onResolve: (UISceneSession) -> Void

    func makeUIView(context: Context) -> SceneSessionReaderView {
        let view = SceneSessionReaderView(onResolve: onResolve)
        view.isUserInteractionEnabled = false
        view.isAccessibilityElement = false
        return view
    }

    func updateUIView(_ uiView: SceneSessionReaderView, context: Context) {
        uiView.onResolve = onResolve
    }
}

final class SceneSessionReaderView: UIView {
    var onResolve: (UISceneSession) -> Void
    private var resolvedSessionIdentifier: String?
    private var resolutionScheduled = false

    init(onResolve: @escaping (UISceneSession) -> Void) {
        self.onResolve = onResolve
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil, !resolutionScheduled else { return }
        resolutionScheduled = true
        Task { @MainActor [weak self] in
            guard let self else { return }
            resolutionScheduled = false
            guard let session = window?.windowScene?.session,
                  resolvedSessionIdentifier != session.persistentIdentifier else {
                return
            }
            resolvedSessionIdentifier = session.persistentIdentifier
            onResolve(session)
        }
    }
}

enum SceneDraftStore {
    static let rawValuesKey = "gauge.raw-values"
    static let disclosureKey = "gauge.pattern-details-expanded"
    private static let rawValueCount = 9
    private static let keyPrefix = "gauge.scene-draft."
    private static let singleSceneIdentifierKey = "gauge.single-scene-identifier"
    private static let singleSceneHandoffKey = "gauge.single-scene-handoff"

    static func serialize(values: [String], disclosure: Bool) -> [String: Any]? {
        guard values.count == rawValueCount else { return nil }
        return [
            rawValuesKey: values,
            disclosureKey: disclosure,
        ]
    }

    static func deserialize(
        _ serialization: [AnyHashable: Any]
    ) -> (values: [String], disclosure: Bool)? {
        guard let values = serialization[rawValuesKey] as? [String],
              values.count == rawValueCount,
              let disclosure = serialization[disclosureKey] as? Bool else {
            return nil
        }
        return (values, disclosure)
    }

    static func reconcileInvalidInchProvenance(
        in values: [String],
        for unit: MeasurementUnit
    ) -> [String] {
        guard unit == .centimeters, values.count == rawValueCount else { return values }
        var reconciled = values
        for index in 5...7 {
            reconciled[index] = MeasurementUnit.inches.storageText(
                values[index],
                transitioningTo: unit
            )
        }
        return reconciled
    }

    static func load(sceneID: String, defaults: UserDefaults = .standard) -> [String: Any]? {
        defaults.dictionary(forKey: keyPrefix + sceneID)
    }

    static func save(_ draft: [String: Any], sceneID: String, defaults: UserDefaults = .standard) {
        defaults.set(draft, forKey: keyPrefix + sceneID)
    }

    static func singleSceneID(defaults: UserDefaults = .standard) -> String? {
        defaults.string(forKey: singleSceneIdentifierKey)
    }

    static func setSingleSceneID(_ sceneID: String?, defaults: UserDefaults = .standard) {
        defaults.set(sceneID, forKey: singleSceneIdentifierKey)
    }

    static func singleSceneHandoff(defaults: UserDefaults = .standard) -> [String: Any]? {
        defaults.dictionary(forKey: singleSceneHandoffKey)
    }

    static func setSingleSceneHandoff(_ draft: [String: Any]?, defaults: UserDefaults = .standard) {
        defaults.set(draft, forKey: singleSceneHandoffKey)
    }

    static func discard(sceneIDs: [String], defaults: UserDefaults = .standard) {
        for sceneID in sceneIDs {
            defaults.removeObject(forKey: keyPrefix + sceneID)
        }
        if let singleSceneID = singleSceneID(defaults: defaults),
           sceneIDs.contains(singleSceneID) {
            setSingleSceneID(nil, defaults: defaults)
            setSingleSceneHandoff(nil, defaults: defaults)
        }
    }
}

// MARK: - ActivityView

struct ActivityView: UIViewControllerRepresentable {
    var activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - GaugeTextDefaults

struct GaugeTextDefaults {
    let patternStitches = "32"
    let patternRows = "24"
    let yourStitches = "32"
    let yourRows = "32"

    var resetSceneDraftValues: [String] {
        [
            patternStitches,
            patternRows,
            yourStitches,
            yourRows,
            "",
            "",
            "",
            "",
            "",
        ]
    }
}

// MARK: - GaugeFormDraft

struct GaugeFormDraft: Equatable {
    var patternStitches: String
    var patternRows: String
    var yourStitches: String
    var yourRows: String
    var patternCastOn: String
    var patternYoke: String
    var patternBody: String
    var patternSleeve: String
    var patternIncreases: String
    var patternDetailsExpanded: Bool
    var unit: MeasurementUnit

    var rawValues: [String] {
        [
            patternStitches,
            patternRows,
            yourStitches,
            yourRows,
            patternCastOn,
            patternYoke,
            patternBody,
            patternSleeve,
            patternIncreases,
        ]
    }

    var inputs: GaugeInputs? {
        guard case let .success(patternStitches?) = validationResult(for: .patternStitches),
              case let .success(patternRows?) = validationResult(for: .patternRows),
              case let .success(yourStitches?) = validationResult(for: .yourStitches),
              case let .success(yourRows?) = validationResult(for: .yourRows),
              case let .success(patternCastOn) = validationResult(for: .patternCastOn),
              case let .success(patternYoke) = validationResult(for: .patternYoke),
              case let .success(patternBody) = validationResult(for: .patternBody),
              case let .success(patternSleeve) = validationResult(for: .patternSleeve),
              case let .success(patternIncreases) = validationResult(for: .patternIncreases) else {
            return nil
        }
        return GaugeInputs(
            patternStitches: patternStitches,
            patternRows: patternRows,
            yourStitches: yourStitches,
            yourRows: yourRows,
            patternYokeDepth: patternYoke,
            patternBodyLength: patternBody,
            patternSleeveLength: patternSleeve,
            patternIncreaseSpacing: patternIncreases,
            patternCastOn: patternCastOn
        )
    }

    var validationMessages: [GaugeFormField: String] {
        Dictionary(
            uniqueKeysWithValues: GaugeFormField.allCases.compactMap { field in
                validationMessage(for: field).map { (field, $0) }
            }
        )
    }

    var firstInvalidField: GaugeFormField? {
        GaugeFormField.allCases.first(where: { validationMessage(for: $0) != nil })
    }

    static func defaults(unit: MeasurementUnit = .centimeters) -> Self {
        let defaults = GaugeTextDefaults()
        return Self(
            patternStitches: defaults.patternStitches,
            patternRows: defaults.patternRows,
            yourStitches: defaults.yourStitches,
            yourRows: defaults.yourRows,
            patternCastOn: "",
            patternYoke: "",
            patternBody: "",
            patternSleeve: "",
            patternIncreases: "",
            patternDetailsExpanded: false,
            unit: unit
        )
    }

    mutating func setRawText(_ text: String, for field: GaugeFormField) {
        switch field {
        case .patternStitches: patternStitches = text
        case .patternRows: patternRows = text
        case .yourStitches: yourStitches = text
        case .yourRows: yourRows = text
        case .patternCastOn: patternCastOn = text
        case .patternYoke: patternYoke = text
        case .patternBody: patternBody = text
        case .patternSleeve: patternSleeve = text
        case .patternIncreases: patternIncreases = text
        }
    }

    mutating func reset() -> Self {
        let snapshot = self
        self = .defaults(unit: unit)
        return snapshot
    }

    mutating func undoReset(to snapshot: Self) {
        self = snapshot
    }

    func rawText(for field: GaugeFormField) -> String {
        switch field {
        case .patternStitches: return patternStitches
        case .patternRows: return patternRows
        case .yourStitches: return yourStitches
        case .yourRows: return yourRows
        case .patternCastOn: return patternCastOn
        case .patternYoke: return patternYoke
        case .patternBody: return patternBody
        case .patternSleeve: return patternSleeve
        case .patternIncreases: return patternIncreases
        }
    }

    func validationMessage(for field: GaugeFormField) -> String? {
        if let invalidInches = MeasurementUnit.invalidInchesText(from: rawText(for: field)) {
            let range = MeasurementUnit.inches.displayRange(from: 5...100)
            return "\(field.correctionName) must be a whole number between \(range.lowerBound) and " +
                "\(range.upperBound) in. Entered: \(invalidInches)."
        }
        guard case let .failure(error) = validationResult(for: field) else {
            return nil
        }
        switch error {
        case .required:
            return "\(field.correctionName) is required."
        case .invalidNumber:
            return "Enter \(field.correctionName.lowercased()) as a number."
        case .wholeNumberRequired:
            return "Enter \(field.correctionName.lowercased()) as a whole number."
        case .outOfRange:
            let bounds = displayedBounds(for: field)
            return "\(field.correctionName) must be between \(bounds.range.lowerBound) and " +
                "\(bounds.range.upperBound) \(bounds.unit)."
        }
    }

    private func validationResult(
        for field: GaugeFormField
    ) -> Result<Double?, GaugeMath.ValidationError> {
        GaugeMath.validate(rawText(for: field), for: field.mathField)
    }

    private func displayedBounds(for field: GaugeFormField) -> (range: ClosedRange<Int>, unit: String) {
        switch field {
        case .patternStitches, .yourStitches:
            return (1...99, "stitches")
        case .patternRows, .yourRows:
            return (1...99, "rows")
        case .patternCastOn:
            return (40...400, "stitches")
        case .patternYoke, .patternBody, .patternSleeve:
            return (unit.displayRange(from: 5...100), unit.label)
        case .patternIncreases:
            return (1...30, "rows")
        }
    }
}

// MARK: - GaugeFormField

enum GaugeFormField: CaseIterable, Hashable {
    case patternStitches
    case patternRows
    case yourStitches
    case yourRows
    case patternCastOn
    case patternYoke
    case patternBody
    case patternSleeve
    case patternIncreases

    var mathField: GaugeMath.Field {
        switch self {
        case .patternStitches: return .patternStitches
        case .patternRows: return .patternRows
        case .yourStitches: return .yourStitches
        case .yourRows: return .yourRows
        case .patternCastOn: return .patternCastOn
        case .patternYoke: return .patternYokeDepth
        case .patternBody: return .patternBodyLength
        case .patternSleeve: return .patternSleeveLength
        case .patternIncreases: return .patternIncreaseSpacing
        }
    }

    var correctionName: String {
        switch self {
        case .patternStitches: return "Pattern stitch gauge"
        case .patternRows: return "Pattern row gauge"
        case .yourStitches: return "Swatch stitch gauge"
        case .yourRows: return "Swatch row gauge"
        case .patternCastOn: return "Cast-on stitches"
        case .patternYoke: return "Yoke depth"
        case .patternBody: return "Body length"
        case .patternSleeve: return "Sleeve length"
        case .patternIncreases: return "Increase spacing"
        }
    }

    var isPatternDetail: Bool {
        switch self {
        case .patternStitches, .patternRows, .yourStitches, .yourRows:
            return false
        default:
            return true
        }
    }
}

// MARK: - Helpers

func initialText(_ environmentKey: String, defaultValue: String) -> String {
    ProcessInfo.processInfo.environment[environmentKey] ?? defaultValue
}

func initialBool(_ environmentKey: String) -> Bool {
    ProcessInfo.processInfo.environment[environmentKey] == "1"
}
