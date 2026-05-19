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

### Knitter Taxonomy Decision (2026-05-19)

Settled on 7 archetypes anchored to real behavioral signatures, not skill-level tiers: Seamless Top-Down Sweater Knitter, Sock Architect, Lace/Shawl Builder, Technical Garment Knitter, Comfort Knitter, Yarn Substituter, and Pattern Modifier/Designer-in-Training. Key vocabulary call: use "gauge" (not "tension"), "per 10 cm" as the canonical unit, and "stitch gauge / row gauge" as the axis names — never conflate them in copy. Row gauge is not a second-class citizen; both axes must carry equal visual weight.

### 2026-05-19 — Round 3: Craft-Truth Foundation + Vocabulary Cheat Sheet (Delivered)

**Round 3 outcome:** Produced 7 knitter archetypes (distilled for decisions.md but full details preserved in git history), canonical vocabulary cheat sheet (13 terms with craft-authentic rationale), 8 anti-patterns guide with corrective approaches, and scenario library keyed to common failure modes.

**Key deliverable:** Vocabulary cheat sheet is the single source of truth for terminology in all UI copy, help text, and VoiceOver labels. Use these terms consistently across all implementations. Non-negotiable: "gauge" not "tension," "stitch gauge / row gauge" as independent axes, "per 10 cm" as canonical unit, "cast-on count" not "starting stitches."

**Anti-patterns as protective layer:** Each anti-pattern documents a real user failure mode (fractional stitches, ignoring stitch-pattern repeats, stockinette-only assumptions, conflating axes, asking for needle size, percentage-only results, assuming perfect measurement). These are not nice-to-haves; they are requirements derived from craft knowledge.

**Key insight on archetypes + personas:** Mendel's personas map cleanly to archetypes — Miriam is Seamless Top-Down, Reema is Technical Garment, Donal spans multiple. The 7 archetypes provide behavioral model for all use cases; the 4 personas focus implementation on the highest-value targets.
