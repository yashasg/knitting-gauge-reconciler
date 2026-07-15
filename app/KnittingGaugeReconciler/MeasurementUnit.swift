import Foundation

// MARK: - MeasurementUnit

/// The unit system for displaying and entering length measurements.
/// INTERNAL MODEL IS ALWAYS CENTIMETRES — this type is a display/entry concern only.
/// Conversion: 1 inch = 2.54 cm (exact).
///
/// Rounding strategy (Phase 1): cm↔in conversions round to the nearest whole inch.
/// This matches the integer-only wheel-picker UX and is consistent with how knitters
/// communicate measurements. Precision loss on inch entry (~1%) is equivalent to
/// entering whole centimetres, and is acceptable for knitting purposes.
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

    // Converts a user-entered whole display-unit integer back to a centimetre
    // integer string. The cm value is rounded to the nearest whole centimetre,
    // which is the canonical storage format for length inputs.
    func displayIntToCmString(_ displayInt: Int) -> String? {
        switch self {
        case .centimeters: return "\(displayInt)"
        case .inches:
            return Int(exactly: (Double(displayInt) * 2.54).rounded()).map(String.init)
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
}
