import Foundation

// MARK: - MeasurementUnit

/// The unit system for displaying and entering length measurements.
/// INTERNAL MODEL IS ALWAYS CENTIMETRES — this type is a display/entry concern only.
/// Conversion: 1 inch = 2.54 cm (exact).
///
/// Adjusted result text preserves one decimal place when needed.
enum MeasurementUnit: String, CaseIterable, Codable {
    case centimeters
    case inches

    private static let invalidInchesPrefix = "gauge.invalid-inches:"
    private static let centimetersPerInch = Decimal(254) / 100

    /// Short label used in field titles and unit toggle.
    var label: String {
        switch self {
        case .centimeters: return "cm"
        case .inches: return "in"
        }
    }

    /// Nominal gauge basis; craft convention treats 10 cm and 4 in as equivalent labels without density conversion.
    var gaugeBasis: String {
        switch self {
        case .centimeters: return "10 cm"
        case .inches: return "4 in"
        }
    }

    /// Natural wording for spoken gauge-basis text.
    var spokenGaugeBasis: String {
        switch self {
        case .centimeters: return "10 centimeters"
        case .inches: return "4 inches"
        }
    }

    // MARK: - Display conversion

    func positiveMeasurementStorageText(
        from displayText: String,
        locale: Locale = .current
    ) -> String {
        let trimmed = displayText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return displayText }
        guard let displayValue = Self.decimal(from: trimmed, locale: locale),
              displayValue > 0 else {
            return self == .inches ? Self.invalidInchesPrefix + displayText : displayText
        }
        guard self == .inches else {
            return NSDecimalNumber(decimal: displayValue).stringValue
        }
        var inches = displayValue
        var conversion = Self.centimetersPerInch
        var centimeters = Decimal()
        guard NSDecimalMultiply(&centimeters, &inches, &conversion, .plain) == .noError else {
            return Self.invalidInchesPrefix + displayText
        }
        return NSDecimalNumber(decimal: centimeters).stringValue
    }

    static func invalidInchesText(from storedText: String) -> String? {
        guard storedText.hasPrefix(invalidInchesPrefix) else { return nil }
        return String(storedText.dropFirst(invalidInchesPrefix.count))
    }

    func storageText(_ storedText: String, transitioningTo newUnit: MeasurementUnit) -> String {
        guard self == .inches, newUnit == .centimeters else { return storedText }
        return Self.invalidInchesText(from: storedText) ?? storedText
    }

    func positiveMeasurementDisplayText(from storedText: String) -> String {
        if let invalidInches = Self.invalidInchesText(from: storedText) {
            return invalidInches
        }
        guard self == .inches,
              let centimeters = Decimal(
                  string: storedText,
                  locale: Locale(identifier: "en_US_POSIX")
              ) else {
            return storedText
        }
        let inches = centimeters / Self.centimetersPerInch
        return NSDecimalNumber(decimal: inches).stringValue
    }

    func isValidStoredPositiveMeasurement(_ storedText: String) -> Bool {
        let trimmed = storedText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty || positiveStoredMeasurementValue(storedText) != nil
    }

    func positiveStoredMeasurementValue(_ storedText: String) -> Double? {
        guard Self.invalidInchesText(from: storedText) == nil else { return nil }
        guard let value = GaugeMath.parsedNumber(storedText),
              value.isFinite, value > 0 else {
            return nil
        }
        return value
    }

    private static func decimal(from text: String, locale: Locale) -> Decimal? {
        let separator = locale.decimalSeparator
        var normalized = ""
        var hasDigit = false
        var hasSeparator = false

        for (index, character) in text.enumerated() {
            if character.isWholeNumber {
                hasDigit = true
                normalized.append(character)
            } else if String(character) == separator || character == "." {
                guard !hasSeparator else { return nil }
                hasSeparator = true
                normalized.append(".")
            } else if (character == "-" || character == "+") && index == 0 {
                normalized.append(character)
            } else {
                return nil
            }
        }
        guard hasDigit else { return nil }
        return Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX"))
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

    func displayDecimalRange(from cmRange: ClosedRange<Double>) -> ClosedRange<Double> {
        switch self {
        case .centimeters:
            cmRange
        case .inches:
            (cmRange.lowerBound / 2.54)...(cmRange.upperBound / 2.54)
        }
    }

    // Formats an entered measurement with the same precision as adjusted results.
    // swiftlint:disable:next identifier_name
    func formatMeasurement(_ cm: Double) -> String {
        formatResultMeasurement(cm)
    }

    // Formats an adjusted result with at most one decimal place.
    // swiftlint:disable:next identifier_name
    func formatResultMeasurement(_ cm: Double) -> String {
        let displayValue = self == .centimeters ? cm : cm / 2.54
        let rounded = (displayValue * 10).rounded() / 10
        let format = rounded == rounded.rounded() ? "%.0f" : "%.1f"
        let value = String(format: format, locale: Locale(identifier: "en_US_POSIX"), rounded)
        return "\(value) \(label)"
    }
}
