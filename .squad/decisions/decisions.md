# Decisions Registry

## 2026-05-19: Gauge Math Inversion Fix

**Author:** Ada (Algorithms Dev)  
**Date:** 2026-05-19  
**Relevant agents:** Jacquard, Curie, Edison, Ive  

### Summary
Fixed critical inversion in `compute()` function in `prototype/index.html`. Row scale and dimension scale had inverted formulas, causing cm outputs to increase when they should decrease for denser swatches.

### The Bug

`compute()` used `yr / pr` (your_row / pattern_row) as the multiplier for vertical cm dimensions. For the default demo (yr=32, pr=24), this output:

```
actYoke = 20 × (32/24) = 26.7 cm   ← WRONG (tells denser-gauge knitter to knit MORE)
```

A denser swatch (more rows per cm) means each row is physically shorter. To match the pattern's intended row count, you knit *fewer* cm — not more.

### The Fix

Introduced a separate `dimScale = pr / yr` for cm-dimension corrections, keeping `rowCountScale = yr / pr` only for the hero display and increase-row spacing.

```js
const rowCountScale = yr / pr;   // density ratio — display + increase spacing
const dimScale      = pr / yr;   // dimension correction — all vertical cm outputs

const actYoke   = patYoke   * dimScale;      // 20 × 0.75 = 15.0 cm
const actBody   = patBody   * dimScale;      // 50 × 0.75 = 37.5 cm
const actSleeve = patSleeve * dimScale;      // 45 × 0.75 = 33.8 cm
const actIncs   = patIncs   * rowCountScale; // 6 × 1.333 = 8 rows  (unchanged — correct)
```

### Corrected Formula Direction

| Output | Formula | Direction rule |
|---|---|---|
| Vertical cm sections | `patDim × (pr / yr)` | denser swatch → fewer cm |
| Increase-row spacing | `patIncs × (yr / pr)` | denser swatch → more rows between increases |
| Stitch width display | `ps / ys` | unchanged |
| Row density display | `yr / pr` | unchanged (hero percentage) |

### UI / Text Also Updated

- `prototype/index.html` about-panel (line 212): now correctly names `dim_scale = pattern_row / your_row`
- Breakdown math show-full-math panel: now shows both density ratio AND dimension correction factor
- `pillRowFor` comment: corrected (`yr/pr`, not `pr/yr` as incorrectly stated before)

### Before / After (demo defaults: ps=32, pr=24, ys=32, yr=32)

| Output | Before (broken) | After (correct) |
|---|---|---|
| Yoke depth | 26.7 cm | 15.0 cm |
| Body length | 66.7 cm | 37.5 cm |
| Sleeve length | 60.0 cm | 33.8 cm |
| Increase spacing | 8 rows | 8 rows |

---

## Craft-Truth Reference: Gauge Math Specification

**Author:** Jacquard  
**Date:** 2026-05-19  
**Status:** Canonical craft-truth reference for algorithm correction

### Two Patterns of Pattern Instructions

Knitting patterns express dimensional targets in two distinct forms, each broken by a different gauge mismatch:

#### Pattern A: CM/Inch Targets (Measurement-Based)
**Example:** "Knit yoke until it measures 20 cm."

**How it breaks when row gauge is off:**
- Pattern specifies a *depth in cm*, not a row count.
- A knitter following this literally knits to the target cm regardless of how many rows land in that distance.
- **Effect:** If your row gauge is denser (more rows per 10cm), you knit MORE rows to reach 20 cm, producing a longer section than intended. If looser (fewer rows per 10cm), you knit FEWER rows, producing a shorter section.
- **Why this fails:** The pattern's author chose 20 cm because it *implies a specific row count* needed for shaping (decreases, increases, yoke depth). A knitter following the cm target but knitting a different row count disrupts the shaping rhythm and garment proportions.

#### Pattern B: Row Count Targets (Instruction-Based)
**Example:** "Knit 48 rounds, increasing every 6 rounds."

**How it breaks when row gauge is off:**
- Pattern specifies an explicit *row count*, not a depth in cm.
- A knitter following this literally knits exactly 48 rounds no matter their row gauge.
- **Effect:** If your row gauge is denser, those 48 rounds take up *fewer cm* than the pattern intends. If looser, those 48 rounds take up *more cm*.
- **Why this fails:** The finished garment ends up the wrong proportions — a denser knitter gets a shorter yoke, a looser knitter gets a longer one. The increase-row spacing (every 6 rounds) stays correct, but the overall section is out of proportion.

**Which pattern does this tool target?** 
Most knitting patterns (especially fitted garments like yoked sweaters) are written as **Pattern B — row count targets**. Even when they say "knit until 20 cm," the underlying logic is "knit X rows" (calculated by the designer). This tool is most useful for knitters working from row-count-explicit patterns or patterns where they've counted rows and want to check their depth.

### The Correct Math: Formula by Formula

#### Key Principle
- **Stitch scale:** accounts for *horizontal* width mismatch. Tells you how many stitches to cast on.
- **Row scale:** accounts for *vertical* depth mismatch. Tells you how many rows to knit or what depth to expect.

Both scales answer: "If I knit [this many stitches / rows / cm], what will I actually get?"

#### Formula 1: Stitch Count Multiplier (Horizontal Adjustment)
```
stitch_count_multiplier = your_st / pattern_st
```

**Direction:** 
- If your stitch gauge is **denser** (more stitches per 10cm) than pattern: `multiplier < 1`. You need FEWER stitches to match the pattern's intended width.
- If your stitch gauge is **looser** (fewer stitches per 10cm) than pattern: `multiplier > 1`. You need MORE stitches to match the pattern's intended width.

**Plain language:** "Your stitches are [bigger/smaller] than the pattern's, so divide/multiply the cast-on number to hit the same finished width."

**Example (looser stitch gauge):**
- Pattern: 32 st/10cm, calls for 128 cast-on stitches (= 40 cm wide)
- You: 28 st/10cm (looser; each stitch is wider)
- Adjustment: 128 × (28/32) = 112 stitches
- Result: 112 stitches at 28 st/10cm = 40 cm ✓

#### Formula 2: Row Count Multiplier (Vertical Adjustment for Explicit Row Targets)
```
row_count_multiplier = your_row / pattern_row
```

**Direction:** 
- If your row gauge is **denser** (more rows per 10cm) than pattern: `multiplier > 1`. You must knit MORE rows to fill the same cm as the pattern's row count implies.
- If your row gauge is **looser** (fewer rows per 10cm) than pattern: `multiplier < 1`. You knit FEWER rows to fill the same cm.

**Plain language:** "The pattern's row counts land in different cms at your gauge, so scale the row counts to adjust."

**Example (denser row gauge):**
- Pattern: 24 rows/10cm, calls for 48 rows in the yoke
- You: 32 rows/10cm (denser)
- Adjustment: 48 × (32/24) = 64 rows (knit 16 extra rows)
- Result: 64 rows at 32 rows/10cm = 20 cm (matches pattern's intended depth) ✓

#### Formula 3: Section Depth in Centimeters (Vertical CM Translation)
When the pattern specifies a *cm target* (e.g., "knit until 20 cm"), and you're row-gauge mismatched, the actual depth you should knit to is:

```
actual_section_cm = pattern_section_cm × (pattern_row / your_row)
```

**Direction:**
- If your row gauge is **denser:** multiply the pattern cm by `< 1`, so knit to a SMALLER depth. (You knit fewer cm to lay down the same row count.)
- If your row gauge is **looser:** multiply the pattern cm by `> 1`, so knit to a LARGER depth. (You need more cm to lay down the same row count.)

**Plain language:** "If the pattern tells you a depth in cm, but you're row-gauge off, this is the actual depth to knit to so the shaping lands at the right row count."

**Example (denser row gauge):**
- Pattern: 24 rows/10cm, yoke depth 20 cm (= 48 rows)
- You: 32 rows/10cm
- Adjustment: 20 × (24/32) = 15 cm
- Result: Knit to 15 cm; at your gauge that's 48 rows ✓

#### Formula 4: Increase-Row Spacing (Adjust Shaping Rhythm)
```
adjusted_increment_spacing = pattern_increment_rows × (your_row / pattern_row)
```

**Direction:** Same as row count multiplier.
- **Denser row gauge:** multiply by `> 1`, so increase/decrease more frequently (in more rows between each step).
- **Looser row gauge:** multiply by `< 1`, so increase/decrease less frequently (in fewer rows).

**Plain language:** "The pattern says 'increase every 6 rows.' At your gauge, that rhythm becomes…"

**Example (denser row gauge):**
- Pattern: increase every 6 rows, row gauge 24 rows/10cm
- You: 32 rows/10cm
- Adjustment: 6 × (32/24) = 8 rows
- Result: Increase every 8 rows at your gauge (to keep increases spaced at the same vertical distance)

### Two Worked Examples, End to End

#### Case 1: Denser Row Gauge (32 rows/10cm vs. pattern's 24)

**Swatch:**
- Pattern: 32 st/10cm × 24 rows/10cm
- You: 32 st/10cm × 32 rows/10cm (row gauge denser)

**Pattern calls for:**
- Yoke depth: 20 cm
- Body length: 50 cm
- Sleeve length: 45 cm
- Yoke increases: every 6 rows, 6 times
- Cast-on: 32 stitches (as written)

**What pattern measurement implies:**
- Yoke 20 cm at pattern's 24 rows/10cm = 48 rows
- Body 50 cm at pattern's 24 rows/10cm = 120 rows
- Sleeve 45 cm at pattern's 24 rows/10cm = 108 rows
- Spacing: every 6 rows

**What happens if you blindly follow:**
1. Cast on 32 stitches ✓ (stitch gauge matches)
2. Knit yoke until 20 cm (checking ruler)
   - At 32 rows/10cm, 20 cm = 64 rows (not 48!)
   - Yoke is too long. It sits too high on the shoulders.
3. Knit body until 50 cm
   - At 32 rows/10cm, 50 cm = 160 rows (not 120!)
   - Body is too long. Waist seam hangs too low.
4. Increases happen every 6 rows as written
   - But they're compressed into too few centimeters because you knitted more rows than intended.

**What the tool should show:**
- **Stitch scale:** 32/32 = 1.0 (100%). Knit cast-on as written.
- **Row scale:** 32/24 = 1.33 (multiply row counts by 1.33, or multiply cm by 0.75).
- **Adjusted section depths:**
  - Yoke: 20 × (24/32) = **15 cm** (knit to here instead of 20 cm)
  - Body: 50 × (24/32) = **37.5 cm**
  - Sleeve: 45 × (24/32) = **33.75 cm**
- **Adjusted increase spacing:** every 6 rows becomes **every 8 rows** (6 × 32/24)
- **Verdict:** "Your row gauge is 33% denser. Knit shorter depths to lay down the same row counts. Increase spacing widens from every 6 to every 8 rows."

**Result if you follow tool guidance:**
- Cast on 32, knit yoke to 15 cm (= 48 rows) ✓
- Increases every 8 rows (6 times = 48 rows between increases land at 8, 16, 24, 32, 40, 48)
- Body to 37.5 cm (= 120 rows) ✓
- Sleeve to 33.75 cm (= 108 rows) ✓
- Finished garment matches pattern proportions ✓

#### Case 2: Looser Stitch Gauge (28 st/10cm vs. pattern's 32)

**Swatch:**
- Pattern: 32 st/10cm × 24 rows/10cm
- You: 28 st/10cm × 24 rows/10cm (stitch gauge looser; row gauge matches)

**Pattern calls for:**
- Yoke depth: 20 cm
- Body length: 50 cm
- Sleeve length: 45 cm
- Yoke increases: every 6 rows, 6 times
- Cast-on: 128 stitches (= 40 cm at pattern's 32 st/10cm)

**What happens if you blindly follow:**
1. Cast on 128 stitches (as written)
   - At 28 st/10cm, that's 45.7 cm wide (not 40 cm!)
   - Body is too wide. Garment won't fit.
2. Row counts work fine (row gauge matches)
   - Yoke to 20 cm = 48 rows ✓
   - But the body is the wrong width.

**Hisahashisaka's observation:** "If the swatch is bigger, the user needs to work less stitches to match the pattern gauge."
- Pattern stitch count: 128
- Adjustment: 128 × (28/32) = 112 stitches
- At 28 st/10cm, that's 40 cm ✓

**What the tool should show:**
- **Stitch scale:** 28/32 = 0.875 (87.5% of pattern width per stitch count). Multiply stitch counts by 0.875.
- **Row scale:** 24/24 = 1.0 (100%). No row adjustment needed.
- **Adjusted stitch counts:** 128 × 0.875 = **112 stitches**
- **Section depths:** No adjustment needed (row gauge matches).
- **Verdict:** "Your stitch gauge is looser (wider stitches). Cast on fewer stitches — multiply by 0.875 — to hit the pattern's intended width. Row counts stay as written."

**Result if you follow tool guidance:**
- Cast on 112, knit to finished width ✓
- Row counts as written (no adjustment) ✓
- Finished garment matches pattern proportions ✓

### The Bug in One Sentence

**The prototype's bug (in knitter language):**
The tool multiplies cm depths by a factor that makes them *larger* when your row gauge is denser, when it should make them *smaller* — you should knit to fewer centimeters to lay down the same row count, not more.

**The prototype's bug (concise):**
Row scale is inverted: uses `your_row / pattern_row` instead of `pattern_row / your_row`.
Stitch scale is also inverted: uses `pattern_st / your_st` instead of `your_st / pattern_st`.

### Test Scenarios

All scenarios use pattern: **32 st/10cm × 24 rows/10cm** (reference gauge).
Pattern specs: yoke 20 cm / 48 rows, body 50 cm / 120 rows, cast-on 32 stitches, increases every 6 rows.
Output: `(stitch_multiplier, row_multiplier, yoke_depth_cm, body_depth_cm, increase_spacing_rows)`.

#### Scenario 1: Perfect Match
**Your gauge:** 32 st/10cm × 24 rows/10cm  
**Expected:** `(1.0, 1.0, 20.0, 50.0, 6.0)`  
**Why:** No adjustment needed.

#### Scenario 2: Denser Row Gauge Only
**Your gauge:** 32 st/10cm × 32 rows/10cm  
**Expected:** `(1.0, 0.75, 15.0, 37.5, 8.0)`  
**Why:** Row scale = 24/32 = 0.75; multiply all depths by 0.75; increase spacing by 32/24 ≈ 1.33.

#### Scenario 3: Looser Row Gauge Only
**Your gauge:** 32 st/10cm × 20 rows/10cm  
**Expected:** `(1.0, 1.2, 24.0, 60.0, 5.0)`  
**Why:** Row scale = 24/20 = 1.2; multiply depths by 1.2; increase spacing by 20/24 ≈ 0.833 → round to 5.

#### Scenario 4: Denser Stitch Gauge Only
**Your gauge:** 36 st/10cm × 24 rows/10cm  
**Expected:** `(0.889, 1.0, 20.0, 50.0, 6.0)`  
**Why:** Stitch scale = 32/36 ≈ 0.889; no row adjustment.

#### Scenario 5: Looser Stitch Gauge Only (Hisahashisaka's case)
**Your gauge:** 28 st/10cm × 24 rows/10cm  
**Expected:** `(0.875, 1.0, 20.0, 50.0, 6.0)`  
**Why:** Stitch scale = 28/32 = 0.875 (cast on fewer stitches); no row adjustment.

#### Scenario 6: Both Denser (Both Axes)
**Your gauge:** 36 st/10cm × 32 rows/10cm  
**Expected:** `(0.889, 0.75, 15.0, 37.5, 10.7)`  
**Why:** Stitch scale = 32/36 ≈ 0.889; row scale = 24/32 = 0.75; increase spacing = 6 × 32/24 = 8 (but stated as 10.7 if using exact row count math, or 8 if rounding).

### Summary: The Correct Formulas

| Dimension | Formula | Direction |
|-----------|---------|-----------|
| **Stitch count** | `count × (your_st / pattern_st)` | If your gauge is denser, multiply by <1 (cast on fewer). |
| **Row count** | `rows × (your_row / pattern_row)` | If your gauge is denser, multiply by >1 (knit more rows). |
| **Section depth (cm)** | `cm × (pattern_row / your_row)` | If your gauge is denser, multiply by <1 (knit to shallower depth). |
| **Increase spacing** | `spacing × (your_row / pattern_row)` | If your gauge is denser, multiply by >1 (increase more frequently). |

### Implementation Notes for Ada

1. **Stitch scale should be `your_st / pattern_st`**, not the inverse.
2. **Row scale for cm-depth adjustment should be `pattern_row / your_row`** (inverse of row count multiplier).
3. **Display the row-count multiplier** (your_row / pattern_row) for reference, but apply the *depth multiplier* (pattern_row / your_row) to cm values.
4. **Pill labels:** 
   - Stitch scale <1: "Looser stitch gauge" (your stitches are bigger)
   - Stitch scale >1: "Tighter stitch gauge" (your stitches are smaller)
   - Row scale <1: "Looser row gauge" (you knit fewer rows per 10cm)
   - Row scale >1: "Tighter row gauge" (you knit more rows per 10cm) — currently says "Denser" which is correct.
5. **Verdict copy:** Clarify that denser row gauge means "knit to a *shallower* depth" — currently the prototype suggests knitting deeper.
