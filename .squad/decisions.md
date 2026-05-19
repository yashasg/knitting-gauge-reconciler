# Squad Decisions

## Active Decisions

### Cast-On Stitch Count UX & Implementation (2026-05-19)

**Authors:** Ive (UX), Ada (Implementation), Curie (QA)  
**Status:** Implemented and tested

#### Decision: Add actionable cast-on input and output (gitlab#1, comment 2)

Pattern's cast-on count is now adjustable per gauge. When stitch gauge differs from pattern, adjusted cast-on replaces vague "pick a different pattern size" advice.

**Formula:** `actStitches = patCastOn × (your_st / pattern_st)` with Math.round()

**Defaults:** `patCastOn: 128` stitches (40 cm at 32 st/10cm — typical small-to-medium sweater)

**Drift pill:** Shown when rounding causes ≥3% width variance (safety net for degenerate ratios only; normal use case < 2.5% drift).

**URL short:** `pc` (pattern cast-on)

**Verdict copy overhaul:** All four branches now name the specific adjusted stitch count instead of suggesting pattern size swap.

**Accessiblity:** VoiceOver reads "Pattern says, 128, stitches to cast on"; `aria-describedby` links hint text; focus order unchanged (cast-on input after increase-row spacing).

**Files:** prototype/index.html, prototype/tests/gauge-math.test.js

#### Spec Clarifications (Curie notes — action for Jacquard)

**Scenario 5 stitch scale:** Jacquard's test scenarios use `ps/ys` for display width ratio (matches code & Scenario 4). Scenario 5's expected value 0.875 is the *stitch count multiplier* `ys/ps` — a separate output. Recommend clarifying spec column header.

**Scenario 6 increase spacing:** Expected tuple lists 10.7 but formula yields 8.0. Likely copy error. Code correctly computes 8. Recommend spec update to 8.0.

Neither is a code bug; both are spec documentation items for Jacquard to resolve in a future pass.

## Governance

- All meaningful changes require team consensus
- Document architectural decisions here
- Keep history focused on work, decisions focused on direction
