# Jacquard — History

## Core Context

- **Owner:** yashasg
- **Project:** A knitting gauge reconciler that converts patterns between stitch/row gauges.
- **Role:** Knitting Domain Expert (subject matter expert)
- **Joined:** 2026-05-19T07:14:05Z

## Learnings

### Two-Axis Gauge Math (2026-05-19)

**Correct scaling direction (craft-truth):**
- **Stitch axis:** `multiplier = your_st / pattern_st`. If your stitches are bigger, cast on FEWER. 
  - Example: Pattern 32st/10cm, you 28st/10cm → multiply stitch count by 0.875.
- **Row axis (for cm depths):** `multiplier = pattern_row / your_row`. If you knit denser, knit SHALLOWER.
  - Example: Pattern 24rows/10cm, you 32rows/10cm → multiply cm depths by 0.75.
- **Row axis (for row counts):** `multiplier = your_row / pattern_row`. If you knit denser, knit MORE rows.

**Why the scaling can confuse:**
- Row-count multiplier and cm-depth multiplier are inverses of each other.
- The tool needs to show knitters both: "this many rows" and "knit to this cm" — and they scale in opposite directions.

**Pattern instructions and gauge mismatch:**
- **Pattern A (cm targets):** "Knit yoke until 20 cm." Breaks when row gauge is off — knitter ends up with wrong row count, wrong shaping depth.
- **Pattern B (row targets):** "Knit 48 rounds." Breaks when row gauge is off — same row count but wrong cm depth.
- **This tool helps with Pattern B**, which is most knitting patterns (even when they mention cm, the design logic is rows).

**The bug in the prototype:**
- Stitch scale uses `ps / ys` (backwards) instead of `ys / ps`.
- Row-depth scale uses `yr / pr` (backwards) instead of `pr / yr`.
- Result: tool tells knitters to knit deeper when denser (wrong), and to cast on more when their swatch is bigger (wrong).

**Spec review notes (2026-05-19):** Curie surfaced two doc-cleanup items in your six test scenarios: (1) Scenario 5 uses `ys/ps` (stitch count multiplier) instead of `ps/ys` (display ratio) — clarify spec column header; (2) Scenario 6 increase spacing expected 10.7 but formula yields 8.0 — update expected value to 8. Address in a future pass when you next touch the spec.
