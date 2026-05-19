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

---

## Round 3 — User Research, Design Direction, and Excalidraw Flow (2026-05-19)

**Sponsors:** Ive (UX/Design), Mendel (Research), Jacquard (Craft Domain), Copilot (User Directive)

### A. BINDING USER DIRECTIVE — One Screen, One Press

**By:** yashasg (via Copilot) · 2026-05-19T01:54-07:00  
**Status:** Non-negotiable. Overrides design choices.

**What:** No step-by-step / wizard / multi-step data entry. ALL inputs (pattern gauge, your gauge, cast-on, anything else) must be visible on a single screen at once. The user fills the form, presses ONE Calculate button, and sees the result inline. No multiple screens, no "next" buttons, no tabbed flows, no modal sheets.

**Why:** The app is a single-page knitting gauge reconciler. Wizard flows add friction and break the one-handed mobile use case (Donal at 10pm, Birgitta with Dynamic Type +3). Concrete-action-in-one-shot is the product's reason for existing.

**Implications for all downstream work:** Excalidraw flow must show one phone frame with all input regions stacked vertically, one Calculate button, and the verdict region inline below it (revealed after press).

---

### B. DESIGN PRINCIPLES & DIRECTION

**Author:** Ive (UI/UX)  
**Status:** Inbox → Ready for Implementation

#### Current State Audit (3 findings in prototype/index.html)
1. **Fixed font sizes break Dynamic Type** — Labels (`13px`), hints (`11px`), verdict copy (`14px`), pills (`11px`) use hard-coded px; Birgitta's Dynamic Type +3 becomes illegible.
2. **Verdict block lacks visual dominance** — Post-compute verdict is indistinguishable from input cards; Donal on a dim couch cannot locate the answer.
3. **Color-only pills with no axis label** — Pills have only background-color at 11px; Reema (deuteranopia) cannot distinguish green from amber; VoiceOver announces "Match" with no gauge-axis context.

#### Four Binding Design Principles
- **Principle 1: One screen, one press** *(Highest binding)* — All inputs visible simultaneously on single scrollable screen. User fills any subset of fields, taps Calculate, verdict appears inline below. No wizards, no separate result screen.
- **Principle 2: Number First** — Every computed output surfaces concrete, unit-bearing integer before explanation; serves Miriam who needs "Cast on 118 stitches," not a scale factor.
- **Principle 3: Verdict Dominance** — After Compute, verdict is largest, highest-contrast element on screen, scannable in two seconds by Donal at low light — no scrolling required.
- **Principle 4: Text Before Color** — Every color signal carries co-located visible text label; color reinforces, never replaces; non-negotiable for Reema (deuteranopia) and Birgitta (VoiceOver).

#### Hero Layout (single page, top→bottom)
```
iPhone portrait (390×844)
Header: KNITTING GAUGE RECONCILER
PATTERN GAUGE  [Stitches ___][Rows ___]
YOUR SWATCH    [Stitches ___][Rows ___]
CAST-ON COUNT  [Pattern cast-on ___]
[          Calculate          ] 50pt
───────────────────────────────────
  (VERDICT REGION — 4 states)
  Before press: "Enter your gauge..."
  After press:  headline + reason + number
───────────────────────────────────
PER-SECTION ADJUSTMENTS
Yoke [20]→23.0 cm  Body [50]→66.7 cm
Sleeve[45]→60 cm   Inc[6]→every 8 rows
Cast-on [128] → 171 stitches
```

#### Verdict Block — Copy & VoiceOver (4 branches, concrete numbers always)
| Branch | Pill | Visible reason | VoiceOver announce |
|---|---|---|---|
| Perfect Match | "Match" | "Both axes within 2%. Cast on as written." | "Gauge match. Cast on [N] stitches." |
| Minor Drift | "Drift" | "One axis off [X]%. Adjusted: cast on [N] stitches." | "Minor drift. Cast on [N] stitches. Knit body to [Z] cm." |
| Significant Drift | "Drift" | "Stitches [X]% off, rows [Y]% off. Cast on [N]; check section targets." | "Significant drift. Cast on [N] instead of [M]. Review section targets." |
| Major Mismatch | "Mismatch" | "Over 15% drift on [axis]. Re-swatch or change needle size before proceeding." | "Major mismatch. Adjusted cast-on is [N] — needle change recommended." |

**Rule:** Every output is a concrete number, never a percentage in isolation.

#### Accessibility Floor (non-negotiable, ship-blocking)
- 44pt minimum touch targets on all interactive controls
- Text labels on every color pill — e.g., "Stitch gauge: Match"
- All numeric inputs: `<label for>` + `inputmode="decimal"` + `font-size: max(1rem, 18px)`
- VoiceOver semantic labels: "Pattern stitches, 32, number field" not "ps"
- Visible focus ring (`outline:2px solid var(--accent)`)
- Copy share link: `aria-label="Copy share link"` + `aria-live` confirm
- Replace all fixed `px` label/body sizes with `rem` or `clamp()`; pill text minimum `0.75rem`
- Compute and section inputs full-width on narrow viewports for one-handed thumb reach

#### What This Rules Out
- No multi-step wizard
- No "Step 1 of 3" progress indicator
- No separate results page or modal
- No tab-bar segmentation of inputs
- No asking for needle size (already on needles)

---

### C. JOBS-TO-BE-DONE & PERSONAS (User Research Foundation)

**Author:** Mendel (User Researcher)  
**Status:** Inbox → Ready for Product Mapping

#### 5 Core JTBDs

**JTBD-1:** When I've swatched and confirmed my gauge differs from the pattern on one or both axes, I want to know the exact adjusted stitch count to cast on so I can start my project without guessing.  
→ Maps to: **Miriam** (Yarn-First). App feature: Cast-on stitch count row.

**JTBD-2:** When my row gauge differs, I want to see knit-to cm target for each vertical section (yoke, body, sleeve) so I can write them in my pattern booklet and not re-derive them at every section.  
→ Maps to: **Miriam**, **Reema** (Methodical Technician). App feature: Per-section cm targets.

**JTBD-3:** When I'm mid-project and suspect my gauge is producing wrong dimensions, I want to quickly check whether I need to keep knitting or rip back so I can make that decision while at my chair.  
→ Maps to: **Donal** (Mid-Project Worrier). App feature: Verdict block (most immediate read).

**JTBD-4:** When I need to space my increase rows correctly despite gauge difference, I want to see rescaled increase interval so my sleeve or body shaping has right physical proportions.  
→ Maps to: **Reema** (Methodical Technician). App feature: Increase-row spacing section row.

**JTBD-5:** When using a phone one-handed — yarn in one hand, phone in the other — I want to enter my gauge numbers without fighting tiny inputs or color-only feedback so I don't lose my place.  
→ Maps to: **Birgitta** (One-Handed Adapter with Dynamic Type +3 and VoiceOver), **Donal** (Mid-Project Worrier). App feature: All numeric inputs, verdict text, color pills.

#### Primary Personas (distilled)

**Miriam — "Yarn-First Knitter"**  
Commits to yarn before pattern; swatches with intent; wants cast-on number + per-section cm targets written in pattern before sitting down to knit. Desktop/mobile hybrid, unhurried context. Success = no second-guessing. Key quote: "I've got 800m of this yarn and I'm knitting this sweater — just tell me what number to cast on."

**Donal — "Mid-Project Worrier"**  
Swatches minimally, knits on impulse, second-guesses mid-project (typically at 10pm on couch, one thumb, marginal light). Needs one-line verdict with specific adjusted cm target. Success = 90-second interaction, no ripping back. Key quote: "I just need to know if I'm screwed or if I can keep knitting."

**Reema — "Methodical Technician"**  
Treats knitting as precision craft; cross-checks tool output against own arithmetic; wants to see "Show full math." Desktop-primary; has mild deuteranopia (red-green color deficit) — text-on-color labels are non-negotiable. Success = verifies formula, bookmarks tool, recommends it. Key quote: "I love when a tool shows its work — that's how I know I can trust it."

**Birgitta — "One-Handed Adapter"**  
Chronic wrist condition (fine-motor precision and prolonged grip limited); uses Dynamic Type +3 and VoiceOver. One-handed device operation is real constraint, not edge case. Success = tabs through, VoiceOver reads semantically correct labels, no spinners requiring precise tap-and-hold. Ship-blocking accessibility profile.

#### Accessibility Profile Summary
Birgitta's needs establish the floor: 44pt touch targets, Dynamic Type scaling (no fixed px), semantic VoiceOver labels, text labels on every color signal. This is not accommodation; it is baseline for this tool.

#### Anti-Patterns to Avoid (Jacquard's Domain Knowledge)
1. **Fractional stitches as final answers** — Always round to nearest whole stitch (ideally respecting stitch-pattern repeat).
2. **Ignoring stitch-pattern repeats** — Lace repeats every N stitches; output must be compatible or surface the risk.
3. **Assuming stockinette only** — Gauge is stitch-pattern-dependent; UI should prompt for correct stitch pattern context.
4. **Conflating row gauge with stitch gauge in UI** — Two independent axes; must always be shown separately.
5. **Asking for needle size** — Needle size is causally upstream (how you *get* gauge); once gauge is measured, it's irrelevant.
6. **Treating row gauge as less important** — Both axes have equal visual weight; row gauge governs yoke depth, shaping, increase spacing.
7. **Percentage-only results** — "133% of pattern row gauge" requires mental translation. Lead with adjusted measurement (e.g., "Knit to X cm"), percentage is supplementary.
8. **Assuming accurate measurement** — Recommend measuring over 15–20 cm window and dividing, not minimal 10 cm swatch.

---

### D. KNITTER ARCHETYPES & VOCABULARY CHEAT SHEET

**Author:** Jacquard (Knitting Domain Expert)  
**Status:** Inbox → Ready for Implementation & Copy Reference

#### 7 Knitter Archetypes (distilled)

1. **Seamless Top-Down Sweater Knitter** — 3–10+ yrs, swatches consistently, mid-project failure mode: "Why is my yoke 4 cm too short?" Success vector: "knit to 23 cm instead of 20 cm" in one screen.

2. **Sock Architect** — 5–15 yrs, often 50+ pairs knit, measures gauge from sock leg ("swatch on the sock"), mobile-first. Failure mode: yarn substitution mid-project. Success vector: adjusted stitch count + adjusted row counts (for leg length).

3. **Lace/Shawl Builder** — Charts-native, blocking ritual, row gauge awareness is low (shawls are "knit to a stitch count or until yarn runs out"). Rare user but high precision need — wants stitch-count proportionality, not just cm targets.

4. **Technical Garment Knitter** — 10–20+ yrs, spreadsheet-native, trusts only formulas they can verify. Failure mode: yarn substitution, needle-size drift over years. Success vector: "Show full math" panel is load-bearing for trust.

5. **Comfort Knitter** — Simple hats, scarves, bulky yarn; knits to relax, not challenge. Low gauge awareness; may wing projects. Lowest priority user but still valid — lowest friction design helps here.

6. **Inheritance/Stash Knitter** — Unknown yarn weight/fiber (inherited, mystery stash). Needs reconciliation for multi-project adaptations. Moderate user.

7. **Community Helper** — Experienced knitter answering questions for peers; may use tool to recommend to others. Share link usage is important.

#### Vocabulary Cheat Sheet (craft-authentic terminology)

| Use This | Avoid | Rationale |
|---|---|---|
| **Gauge** | Tension | US/modern standard; universally understood globally |
| **Stitch gauge** | Horizontal gauge, stitch count per unit | Conventional term knitters use |
| **Row gauge** | Vertical gauge, row count per unit | Same logic; "row tension" is old-fashioned |
| **Per 10 cm** | Per inch, per 4 inches | Modern standard; convert internally if supporting inches |
| **Swatch / Blocked swatch** | Sample / Washed swatch | "Blocked" covers wet-blocking and steam-blocking |
| **Cast-on count** | Starting stitches, initial stitch count | Specific knitting term; universally understood |
| **Stitch pattern** | Stitch type, knit type | "Stitch type" sounds like knitting machine interface |
| **In the round** | Circular knitting, tube knitting | Universal term; "circular" is ambiguous (refers to needles) |
| **Flat** | Back and forth, seamed knitting | Conventional opposite of "in the round" |
| **Increase-row spacing** | Shaping interval, rate of increase | "Increase every 6 rows" is what pattern says |
| **Depth** (yoke/body) | Length, height, size | "Yoke depth" and "body length" both conventional |

#### Vocabulary for Common Failure Scenarios
- *"I swatched flat, but the sweater is in the round — different tension."* → Suggest remeasuring in the round stitch pattern.
- *"Row gauge matched the pattern's stitches/10 cm but nobody checked rows/10 cm."* → This tool forces two-axis thinking.
- *"My DK knits at 28 rows/10 cm; pattern is written for 24 rows/10 cm."* → Concrete output: "Knit yoke to [X] cm instead of [Y] cm."
- *"I worked gauge swatch in flat; pattern is in the round."* → Gauge differs predictably; tool's adjusted numbers are protective.

---

### E. EXCALIDRAW ARTIFACT & VISUAL VALIDATION

**Author:** Ive (UI/UX), design iteration 5 (Sonnet-4.6 agent)  
**File:** `ui-flow.excalidraw` at repo root  
**Status:** Delivered · Portrait (969×1494 px) · 42 elements · Validated JSON

**Scope:** Single-page iOS portrait phone frame showing:
- Input region stacked vertically (pattern gauge, your gauge, cast-on, section inputs)
- One full-width Calculate button (50pt, high-contrast)
- Verdict region inline below button (4 state variants: before-press placeholder, Match, Drift-minor, Drift-significant, Mismatch)
- Dashed "same region" connectors showing verdict variants mapping to state-machine branches
- Per-section adjustments card positioned for reference

**Key constraints (all applied):**
- No wizard, no multiple screens, no "next" buttons
- All interactive targets ≥44pt
- Verdict pill includes text label, not color-only
- Font sizes respect baseline Dynamic Type (no fixed px in portrait display)
- VoiceOver semantic labels mapped to all interactive elements

---

## Governance

- All meaningful changes require team consensus
- Document architectural decisions here
- Keep history focused on work, decisions focused on direction
- Round 3 decisions are binding for implementation (Principles 1–4, Accessibility Floor, Excalidraw scope)
