// Issue #134 keeps the small form/help contracts beside the state helpers they exercise.
import SwiftUI

func newValidationAnnouncement(
    previous: [GaugeFormField: String],
    current: [GaugeFormField: String]
) -> String? {
    GaugeFormField.allCases.first(where: {
        previous[$0] != current[$0] && current[$0] != nil
    }).flatMap { current[$0] }
}

enum SceneDraftStore {
    static let rawValuesKey = "gauge.raw-values"
    static let disclosureKey = "gauge.pattern-details-expanded"
    private static let rawValueCount = 9

    static func serialize(values: [String], disclosure: Bool) -> [String: Any] {
        precondition(values.count == rawValueCount)
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

// MARK: - GaugeFormDraft

struct GaugeFormDraft: Equatable {
    private var values: [GaugeFormField: String]
    var unit: MeasurementUnit
    var patternDetailsExpanded: Bool
    var focusedField: GaugeFormField?

    init(
        values: [String] = GaugeTextDefaults().resetSceneDraftValues,
        unit: MeasurementUnit = .centimeters,
        patternDetailsExpanded: Bool = false,
        focusedField: GaugeFormField? = nil
    ) {
        precondition(values.count == GaugeFormField.allCases.count)
        self.values = Dictionary(uniqueKeysWithValues: zip(GaugeFormField.allCases, values))
        self.unit = unit
        self.patternDetailsExpanded = patternDetailsExpanded
        self.focusedField = focusedField
    }

    var rawValues: [String] {
        GaugeFormField.allCases.map { values[$0]! }
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
        var messages: [GaugeFormField: String] = [:]
        for field in GaugeFormField.allCases {
            if let message = validationMessage(for: field) {
                messages[field] = message
            }
        }
        return messages
    }

    subscript(field: GaugeFormField) -> String {
        get { values[field]! }
        set { values[field] = newValue }
    }

    func validationResult(for field: GaugeFormField) -> Result<Double?, GaugeMath.ValidationError> {
        GaugeMath.validate(self[field], for: field.mathField)
    }

    func validationMessage(for field: GaugeFormField) -> String? {
        if let invalidInches = MeasurementUnit.invalidInchesText(from: self[field]) {
            let range = MeasurementUnit.inches.displayRange(from: 5...100)
            return "\(field.correctionName) must be a whole number between \(range.lowerBound) and " +
                "\(range.upperBound) in. Entered: \(invalidInches)."
        }
        guard case let .failure(error) = validationResult(for: field) else { return nil }
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

    mutating func finishEditing() -> String? {
        focusedField = GaugeFormField.allCases.first { validationMessage(for: $0) != nil }
        if focusedField?.isPatternDetail == true {
            patternDetailsExpanded = true
        }
        return focusedField.flatMap { validationMessage(for: $0) }
    }

    mutating func commitPicker(_ value: Int, for field: GaugeFormField) {
        switch field {
        case .patternYoke, .patternBody, .patternSleeve:
            self[field] = unit.centimeterStorageText(from: "\(value)", cmRange: 5...100)
        default:
            self[field] = "\(value)"
        }
    }

    mutating func reset() -> GaugeFormDraft {
        let snapshot = self
        values = Dictionary(
            uniqueKeysWithValues: zip(GaugeFormField.allCases, GaugeTextDefaults().resetSceneDraftValues)
        )
        patternDetailsExpanded = false
        focusedField = nil
        return snapshot
    }

    mutating func restore(_ snapshot: GaugeFormDraft) {
        self = snapshot
        focusedField = nil
    }

    func lengthFieldLabel(_ field: GaugeFormField) -> String {
        "\(field.correctionName) (\(unit.label))"
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

struct AboutHelpState: Equatable {
    var isPresented = false

    mutating func open() {
        isPresented = true
    }

    mutating func close() {
        isPresented = false
    }
}

enum GaugeFormContract {
    static let leadCopy =
        "Compare your pattern gauge with your swatch to see how stitch and row differences affect the garment."
}

enum AboutHelpContract {
    static let openLabel = "About this calculator"
    static let openHint = "Opens an explanation of how this calculator works"
    static let closeLabel = "Close"
    static let closeHitTarget: CGFloat = 44
    static let privacyHeading = "Privacy"
    static let explanation =
        "This tool reconciles a two-axis gauge mismatch, " +
        "the kind that single-number gauge calculators hide. " +
        "When row gauge differs, it adjusts each supplied depth or length " +
        "while preserving the pattern's intended row count. " +
        "Stitch-gauge differences are handled separately for width."
    static let math =
        "The math is deterministic: dimension correction = pattern_row / your_row. " +
        "A denser swatch means fewer " +
        "centimetres are needed to reach the pattern's intended row count; " +
        "stitch_scale = pattern_st / your_st " +
        "describes horizontal width. " +
        "Increase-row spacing is rescaled by your_row / pattern_row so the physical gap " +
        "between increases stays correct."
    static let scope =
        "Scope: This tool provides estimates based on your swatch measurements. " +
        "Always test a full-size gauge " +
        "swatch (washed and blocked the way you'll wash and block the finished garment) " +
        "before starting your " +
        "project. Numbers here are a starting point — your finished piece is the final word."
    static let nonAffiliation =
        "Not affiliated with Ravelry, Knit Companion, or any pattern designer." +
        " Gauge math is conventional knitting arithmetic from open craft literature."
    static let privacy =
        "Your gauge values stay on this device. No account, ads, or third-party tracking. " +
        "The app includes no analytics SDK and makes no app-initiated network requests. " +
        "Apple may receive crash and performance diagnostics according to your device settings."

}
