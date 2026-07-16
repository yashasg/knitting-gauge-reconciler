import SwiftUI
import UIKit

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
        DispatchQueue.main.async { [weak self] in
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
