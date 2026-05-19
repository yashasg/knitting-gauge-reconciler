import Foundation

struct GaugeInputs: Equatable {
    var patternStitches: Double = 32
    var patternRows: Double = 24
    var yourStitches: Double = 32
    var yourRows: Double = 32
    var patternYokeDepth: Double = 20
    var patternBodyLength: Double = 50
    var patternSleeveLength: Double = 45
    var patternIncreaseSpacing: Double = 6
    var patternCastOn: Double = 128
}

struct GaugeMathResult: Equatable {
    var stitchWidthScale: Double
    var stitchCountMultiplier: Double
    var rowCountScale: Double
    var dimensionScale: Double
    var adjustedYokeDepth: Double
    var adjustedBodyLength: Double
    var adjustedSleeveLength: Double
    var adjustedIncreaseSpacing: Double
    var adjustedCastOn: Int
    var castOnRoundingDriftPercent: Double
}

enum GaugeMath {
    static func compute(_ inputs: GaugeInputs) -> GaugeMathResult {
        let stitchWidthScale = inputs.patternStitches / inputs.yourStitches
        let stitchCountMultiplier = inputs.yourStitches / inputs.patternStitches
        let rowCountScale = inputs.yourRows / inputs.patternRows
        let dimensionScale = inputs.patternRows / inputs.yourRows
        let exactCastOn = inputs.patternCastOn * stitchCountMultiplier
        let adjustedCastOn = Int(exactCastOn.rounded())
        let castOnRoundingDriftPercent = ((Double(adjustedCastOn) - exactCastOn) / exactCastOn) * 100

        return GaugeMathResult(
            stitchWidthScale: stitchWidthScale,
            stitchCountMultiplier: stitchCountMultiplier,
            rowCountScale: rowCountScale,
            dimensionScale: dimensionScale,
            adjustedYokeDepth: inputs.patternYokeDepth * dimensionScale,
            adjustedBodyLength: inputs.patternBodyLength * dimensionScale,
            adjustedSleeveLength: inputs.patternSleeveLength * dimensionScale,
            adjustedIncreaseSpacing: inputs.patternIncreaseSpacing * rowCountScale,
            adjustedCastOn: adjustedCastOn,
            castOnRoundingDriftPercent: castOnRoundingDriftPercent
        )
    }

    static func sanitized(_ value: Double?, default defaultValue: Double) -> Double {
        guard let value, value.isFinite, value > 0 else {
            return defaultValue
        }
        return value
    }

    static func fmtCm(_ value: Double) -> String {
        String(format: "%.1f", (value * 10).rounded() / 10)
    }

    static func fmtRows(_ value: Double) -> Int {
        max(1, Int(value.rounded()))
    }

    static func fmtPct(_ value: Double) -> Int {
        Int((value * 100).rounded())
    }
}
