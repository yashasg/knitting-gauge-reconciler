# Ada — History

## Core Context

- **Project:** A knitting gauge reconciler that converts patterns between stitch/row gauges.
- **Role:** Algorithms Dev
- **Joined:** 2026-05-19T07:11:08.646Z

## Learnings

<!-- Append learnings below -->

### 2026-05-19 — Gauge math inversion fix

**Diagnosis:** The original `compute()` used `rowCountScale = yr / pr` as the multiplier for all vertical cm dimensions (actYoke, actBody, actSleeve), producing `20 × (32/24) = 26.7 cm` for a denser swatch — the wrong direction. A knitter whose rows are denser (more rows per cm) needs to knit *fewer* cm to match the pattern's intended row count, not more. The correct cm-dimension multiplier is `dimScale = pr / yr = 24/32 = 0.75`, giving `actYoke = 20 × 0.75 = 15.0 cm`. Increase-row spacing is a separate case: it is measured in rows and uses `yr / pr` (correctly) so the physical gap between increase events is preserved.

**Corrected formulas (math notation):**
- `dim_scale = pr / yr`  
- `actDim = patDim × dim_scale`  (all vertical cm: yoke, body, sleeve)  
- `actIncs = patIncs × (yr / pr)`  (row-count spacing — unchanged, already correct)

**Before/after (demo defaults — ps=32, pr=24, ys=32, yr=32):**
| | Before | After |
|---|---|---|
| actYoke | 26.7 cm | 15.0 cm |
| actBody | 66.7 cm | 37.5 cm |
| actSleeve | 60.0 cm | 33.8 cm |
| actIncs | 8 rows | 8 rows (unchanged) |

**Key file:** `prototype/index.html` — `compute()` function, ~lines 284–300; about panel line 212; breakdown lines 344–351.

### 2026-05-19 — Cast-on stitch count implementation

**Formula (Jacquard Formula 1):**
```
actStitches = patCastOn × (your_st / pattern_st)
```
This is the *forward* scaling: multiply the pattern's cast-on by the ratio of your stitch gauge to the pattern's stitch gauge. A looser gauge (fewer stitches/cm) produces a smaller ratio, yielding fewer stitches to maintain the same fabric width.

**Rounding rule:** `Math.round(exactStitches)` — nearest integer. No fractional stitches.

**Drift threshold:** `Math.abs(driftPct) >= 3` triggers `#pill-cast-on` (class `pill pill-warn`). For realistic knitting values (ps/ys in 20–40 range, cast-on ≥ 20 stitches), rounding at most 0.5 stitches against a cast-on ≥ 20 yields < 2.5% drift, so the pill is effectively a safety net for degenerate inputs only.

**URL hash short name:** `pc` (maps to `patCastOn` key)

**Default:** `patCastOn: 128` (128 ÷ 32 st/10cm = 40 cm half-circumference, typical small-medium sweater at demo gauge)

**Key DOM elements:** `#pat-cast-on` (input), `#act-cast-on` (output span), `#pill-cast-on` (drift pill, hidden by default), `#hint-cast-on` (aria-describedby hint)
