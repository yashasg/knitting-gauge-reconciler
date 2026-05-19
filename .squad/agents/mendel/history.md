# Mendel — History

## Core Context

- **Owner:** yashasg
- **Project:** A knitting gauge reconciler that converts patterns between stitch/row gauges.
- **Role:** User Researcher (personas, jobs-to-be-done)
- **Joined:** 2026-05-19T07:14:05Z

## Learnings

- **Cast-on now adjustable per gauge (2026-05-19):** Knitters following a pattern but knitting at different gauge can now adjust the cast-on stitch count via formula `actCastOn = patCastOn × (your_st / pattern_st)` instead of picking a different pattern size.
- **Personas committed (2026-05-19):** Four behavioral archetypes produced: Miriam (Yarn-First), Donal (Mid-Project Worrier), Reema (Methodical Technician), Birgitta (One-Handed Adapter). Capped at 4; each drives at least one distinct design constraint. Jacquard archetypes doc was not available — synthesis pass needed in round 2.
- **Key JTBD committed (2026-05-19):** Five JTBD statements; the most critical are JTBD-1 (adjusted cast-on count before casting on) and JTBD-3 (mid-project quick-check verdict). Verdict block dominance and concrete actionable numbers (not percentages) are the two highest-stakes design implications.
- **Hypotheses flagged for validation:** Row-gauge as the more-commonly-mismatched axis; pre-cast-on vs. mid-project trigger split; one-handed operation frequency; 3% drift threshold for width-warning pill. All require real-world research to confirm.

### 2026-05-19 — Round 3: User Research Foundation + Personas (Delivered)

**Round 3 outcome:** Produced 5 JTBDs, 4 primary personas, 2 journey sketches, accessibility floor, anti-personas, and 10 open research questions. All personas + JTBDs now consolidated in `.squad/decisions.md` Round 3 section.

**Key insight on Birgitta:** Accessibility profile (44pt touch targets, Dynamic Type +3, semantic VoiceOver, text labels on every color pill) is non-negotiable baseline, not accommodation. Establishes ship-blocking floor for all implementation.

**Key insight on concrete numbers:** Miriam needs "Cast on 118 stitches," not "0.917 scale factor." Donal needs "Knit to 17.5 cm, not 20 cm," not "10% denser." Every output must lead with concrete, actionable integer before any explanation or percentage.

**Hypothesis validation gap:** Row gauge as the more-commonly-mismatched axis is plausible from community discussions but unconfirmed for this product's specific user base. Pre-cast-on vs. mid-project trigger split is directional only; no server-side analytics available. Birgitta's profile is constructed from published disability prevalence data, not interviews with knitters who have disabilities. All flagged for real-world research in future round.
