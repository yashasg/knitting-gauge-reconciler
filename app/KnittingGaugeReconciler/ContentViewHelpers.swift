// Issue #134 keeps the small form/help contracts beside the state helpers they exercise.
import SwiftUI

enum SceneDraftStore {
    static let patternStitchesKey = "gauge.pattern-stitches"
    static let patternRowsKey = "gauge.pattern-rows"
    static let yourStitchesKey = "gauge.your-stitches"
    static let yourRowsKey = "gauge.your-rows"
    static let patternCastOnKey = "gauge.pattern-cast-on"
    static let patternYokeKey = "gauge.pattern-yoke"
    static let patternBodyKey = "gauge.pattern-body"
    static let patternSleeveKey = "gauge.pattern-sleeve"
    static let patternIncreasesKey = "gauge.pattern-increases"
    static let disclosureKey = "gauge.pattern-details-expanded"

    static func reconcileInvalidInchProvenance(
        in values: GaugeFormValues,
        for unit: MeasurementUnit
    ) -> GaugeFormValues {
        guard unit == .centimeters else { return values }
        var reconciled = values
        reconcileInvalidInchProvenance(for: .patternYoke, in: &reconciled, unit: unit)
        reconcileInvalidInchProvenance(for: .patternBody, in: &reconciled, unit: unit)
        reconcileInvalidInchProvenance(for: .patternSleeve, in: &reconciled, unit: unit)
        return reconciled
    }

    private static func reconcileInvalidInchProvenance(
        for field: GaugeFormField,
        in values: inout GaugeFormValues,
        unit: MeasurementUnit
    ) {
        guard field.storageClassification == .centimeterLength else { return }
        values[keyPath: field.valueKeyPath] = MeasurementUnit.inches.storageText(
            values[keyPath: field.valueKeyPath],
            transitioningTo: unit
        )
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
    let values = GaugeFormValues()

    var patternStitches: String { values.patternStitches }
    var patternRows: String { values.patternRows }
    var yourStitches: String { values.yourStitches }
    var yourRows: String { values.yourRows }

}

// MARK: - GaugeFormField

enum GaugeFormField: CaseIterable, Hashable {
    enum StorageClassification: Equatable {
        case text
        case centimeterLength
    }

    case patternStitches
    case patternRows
    case yourStitches
    case yourRows
    case patternCastOn
    case patternYoke
    case patternBody
    case patternSleeve
    case patternIncreases

    var valueKeyPath: WritableKeyPath<GaugeFormValues, String> {
        switch self {
        case .patternStitches: return \.patternStitches
        case .patternRows: return \.patternRows
        case .yourStitches: return \.yourStitches
        case .yourRows: return \.yourRows
        case .patternCastOn: return \.patternCastOn
        case .patternYoke: return \.patternYoke
        case .patternBody: return \.patternBody
        case .patternSleeve: return \.patternSleeve
        case .patternIncreases: return \.patternIncreases
        }
    }

    var storageClassification: StorageClassification {
        switch self {
        case .patternYoke, .patternBody, .patternSleeve:
            return .centimeterLength
        case .patternStitches, .patternRows, .yourStitches, .yourRows,
             .patternCastOn, .patternIncreases:
            return .text
        }
    }

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

    var isRequired: Bool {
        !isPatternDetail
    }
}

// MARK: - GaugeFormValues

struct GaugeFormValues: Codable, Equatable {
    var patternStitches: String
    var patternRows: String
    var yourStitches: String
    var yourRows: String
    var patternCastOn: String
    var patternYoke: String
    var patternBody: String
    var patternSleeve: String
    var patternIncreases: String

    init(
        patternStitches: String = "",
        patternRows: String = "",
        yourStitches: String = "",
        yourRows: String = "",
        patternCastOn: String = "",
        patternYoke: String = "",
        patternBody: String = "",
        patternSleeve: String = "",
        patternIncreases: String = ""
    ) {
        self.patternStitches = patternStitches
        self.patternRows = patternRows
        self.yourStitches = yourStitches
        self.yourRows = yourRows
        self.patternCastOn = patternCastOn
        self.patternYoke = patternYoke
        self.patternBody = patternBody
        self.patternSleeve = patternSleeve
        self.patternIncreases = patternIncreases
    }

    subscript(field: GaugeFormField) -> String {
        get { self[keyPath: field.valueKeyPath] }
        set { self[keyPath: field.valueKeyPath] = newValue }
    }

}

// MARK: - GaugeFormDraft

struct GaugeFormDraft: Equatable {
    private var values: GaugeFormValues
    var unit: MeasurementUnit
    var patternDetailsExpanded: Bool
    var focusedField: GaugeFormField?

    init(
        values: GaugeFormValues = GaugeTextDefaults().values,
        unit: MeasurementUnit = .centimeters,
        patternDetailsExpanded: Bool = false,
        focusedField: GaugeFormField? = nil
    ) {
        self.values = values
        self.unit = unit
        self.patternDetailsExpanded = patternDetailsExpanded
        self.focusedField = focusedField
    }

    var formValues: GaugeFormValues {
        values
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
        get { values[field] }
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
        values = GaugeTextDefaults().values
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

enum AboutHelpContract {
    static let openLabel = "About this calculator"
    static let openHint = "Opens an explanation of how this calculator works"
    static let closeLabel = "Close"
    static let closeHitTarget: CGFloat = 44
    static let privacyHeading = "Privacy"
    static let explanation =
        "This tool reconciles a two-axis gauge mismatch, " +
        "the kind that single-number gauge calculators hide. " +
        "When row gauge differs, section centimetres remain unchanged; " +
        "it calculates the row count you need to knit at your gauge for each section. " +
        "Stitch-gauge differences are handled separately for width."
    static let math =
        "The math is deterministic: adjusted rows = cm × your_row / 10. " +
        "Section centimetres stay fixed; a denser row gauge produces more rows per cm — " +
        "the row count adapts, not the dimension; " +
        "stitch_scale = pattern_st / your_st describes horizontal width. " +
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
