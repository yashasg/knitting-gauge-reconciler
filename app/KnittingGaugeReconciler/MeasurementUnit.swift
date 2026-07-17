import Foundation

// MARK: - MeasurementUnit

/// The unit system for displaying and entering length measurements.
/// INTERNAL MODEL IS ALWAYS CENTIMETRES — this type is a display/entry concern only.
/// Conversion: 1 inch = 2.54 cm (exact).
///
/// Entries remain whole numbers in the selected unit. Adjusted result text
/// preserves one decimal place when needed.
enum MeasurementUnit: String, CaseIterable {
    case centimeters
    case inches

    private static let invalidInchesPrefix = "gauge.invalid-inches:"

    /// Short label used in field titles and unit toggle.
    var label: String {
        switch self {
        case .centimeters: return "cm"
        case .inches: return "in"
        }
    }

    // MARK: - Display conversion

    // Converts a centimetre value to the nearest whole display-unit integer.
    // Used for text-field and wheel-picker display.
    // swiftlint:disable:next identifier_name
    func cmToDisplayInt(_ cm: Double) -> Int {
        switch self {
        case .centimeters: return Int(cm.rounded())
        case .inches: return Int((cm / 2.54).rounded())
        }
    }

    // Converts a user-entered whole display-unit integer back to a centimetre string.
    func displayIntToCmString(_ displayInt: Int) -> String? {
        switch self {
        case .centimeters: return "\(displayInt)"
        case .inches:
            let (hundredths, overflow) = displayInt.multipliedReportingOverflow(by: 254)
            guard !overflow else { return nil }
            return NSDecimalNumber(decimal: Decimal(hundredths) / 100).stringValue
        }
    }

    func centimeterStorageText(
        from displayText: String,
        cmRange: ClosedRange<Int>
    ) -> String {
        guard self == .inches else { return displayText }
        let trimmed = displayText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return displayText }
        let displayRange = displayRange(from: cmRange)
        guard let displayValue = Int(trimmed),
              displayRange.contains(displayValue),
              let centimeters = displayIntToCmString(displayValue) else {
            return Self.invalidInchesPrefix + displayText
        }
        return centimeters
    }

    static func invalidInchesText(from storedText: String) -> String? {
        guard storedText.hasPrefix(invalidInchesPrefix) else { return nil }
        return String(storedText.dropFirst(invalidInchesPrefix.count))
    }

    // Returns the equivalent display-unit range for a cm-calibrated closed range.
    func displayRange(from cmRange: ClosedRange<Int>) -> ClosedRange<Int> {
        switch self {
        case .centimeters: return cmRange
        case .inches:
            let lowerInches = max(1, Int((Double(cmRange.lowerBound) / 2.54).rounded()))
            let upperInches = max(lowerInches, Int((Double(cmRange.upperBound) / 2.54).rounded()))
            return lowerInches...upperInches
        }
    }

    // Formats a cm measurement value as a display string with unit label,
    // e.g. "20 cm" or "8 in". Used in text output (full-math breakdown, share).
    // swiftlint:disable:next identifier_name
    func formatMeasurement(_ cm: Double) -> String {
        "\(cmToDisplayInt(cm)) \(label)"
    }

    // Formats an adjusted result with at most one decimal place.
    // swiftlint:disable:next identifier_name
    func formatResultMeasurement(_ cm: Double) -> String {
        let displayValue = self == .centimeters ? cm : cm / 2.54
        let rounded = (displayValue * 10).rounded() / 10
        let value = rounded.formatted(.number.precision(.fractionLength(0...1)))
        return "\(value) \(label)"
    }
}
