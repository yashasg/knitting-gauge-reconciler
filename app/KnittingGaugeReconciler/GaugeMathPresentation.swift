import Foundation

// MARK: - Verdict presentation helpers (shared by ContentView + VerdictCard)

func verdictTitle(result: GaugeMathResult) -> String {
    let stitchDrift = abs(result.stitchWidthScale - 1)
    let rowDrift = abs(result.rowCountScale - 1)
    if stitchDrift < 0.03, rowDrift < 0.03 { return "Gauge match" }
    if stitchDrift >= 0.15 || rowDrift >= 0.15 { return "Major mismatch" }
    let stitchOffRange = stitchDrift >= 0.03 && stitchDrift < 0.15
    let rowOffRange = rowDrift >= 0.03 && rowDrift < 0.15
    if stitchOffRange && rowOffRange { return "Significant drift" }
    return "Drift"
}

func verdictBody(result: GaugeMathResult, patternCastOn: Double) -> String {
    let stitchDrift   = abs(result.stitchWidthScale - 1)
    let rowDrift      = abs(result.rowCountScale - 1)
    let stitchPercent = abs(GaugeMath.fmtPct(result.stitchWidthScale) - 100)
    let rowPercent    = abs(GaugeMath.fmtPct(result.rowCountScale) - 100)
    let stitchOff = stitchPercent >= 3
    let rowOff    = rowPercent >= 3
    let stitchDir = result.stitchWidthScale > 1 ? "wider" : "narrower"
    let rowDir    = result.rowCountScale > 1 ? "denser" : "looser"
    let majorNote = (stitchDrift >= 0.15 || rowDrift >= 0.15)
        ? " Over 15% drift. Consider re-swatching or changing needle size before proceeding."
        : ""
    if !stitchOff && !rowOff {
        return "Both gauges match. Cast on \(result.adjustedCastOn) stitches as written. " +
            "Knit straight from the pattern. No adjustments needed. Re-check after blocking."
    }
    if stitchOff && !rowOff {
        return (
            "Your row gauge matches, but your stitch gauge is \(stitchPercent)% \(stitchDir). " +
            "Cast on \(result.adjustedCastOn) stitches instead of the pattern's \(Int(patternCastOn)) " +
            "to hit the same width. Vertical sections need no adjustment.\(majorNote)"
        )
    }
    if !stitchOff {
        return (
            "Your stitch gauge matches. Cast on \(result.adjustedCastOn) stitches as written. " +
            "Your row gauge is \(rowPercent)% \(rowDir) than expected; use the row count guidance " +
            "for each vertical section.\(majorNote)"
        )
    }
    return (
        "Both axes are off: stitch gauge \(stitchPercent)% \(stitchDir), " +
        "row gauge \(rowPercent)% \(rowDir). " +
        "Cast on \(result.adjustedCastOn) stitches (not \(Int(patternCastOn))) and use the row " +
        "count guidance for vertical sections.\(majorNote)"
    )
}
