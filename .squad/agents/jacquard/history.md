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

### JS-to-Swift Gauge Math Port Sign-Off (2026-05-19)

**Sign-off:** ✅ **SIGNED OFF** — Swift implementation exactly matches decision spec and JS prototype. All craft logic verified correct.

**Formula verification:**
- **Formula 1 (Stitch count multiplier):** `count × (your_st / pattern_st)` ✅ 
  - JS: `patCastOn * (ys / ps)`
  - Swift: `patCastOn * stitchCountMultiplier` where `stitchCountMultiplier = ys / ps`
  
- **Formula 2 (Row count multiplier):** `rows × (your_row / pattern_row)` ✅
  - JS: `patIncs * rowCountScale` where `rowCountScale = yr / pr`
  - Swift: `patIncs * rowCountScale` where `rowCountScale = yr / pr`
  
- **Formula 3 (Section depth in cm):** `cm × (pattern_row / your_row)` ✅
  - JS: `patYoke * dimScale` where `dimScale = pr / yr`
  - Swift: `patYoke * dimensionScale` where `dimensionScale = pr / yr`
  
- **Formula 4 (Increase-row spacing):** `spacing × (your_row / pattern_row)` ✅
  - JS: `patIncs * rowCountScale`
  - Swift: `patIncs * rowCountScale`

**Craft logic validation:**
1. ✅ Denser row gauge → knit to SHALLOWER depth (fewer cm): `20 × (24/32) = 15 cm`
2. ✅ Denser row gauge → increase MORE frequently (more rows between increases): `6 × (32/24) = 8 rows`
3. ✅ Looser stitch gauge (bigger stitches) → cast on FEWER stitches: `128 × (28/32) = 112 stitches`

**Test scenario alignment:**
- All 6 primary scenarios verified: Perfect match, Denser row, Looser row, Denser stitch, Looser stitch (Hisahashisaka), Both denser
- All edge cases match (2× dense, 2× loose, rounding boundaries, floating-point precision)
- Swift test expected values exactly match JS test values
- Cast-on rounding logic identical between implementations

**Input sanitization:**
- JS `readNum()` → Swift `GaugeMath.sanitized()` — identical fallback logic for nil, zero, negative, NaN values

**Format functions:**
- `fmtCm()`: Both round to 0.1 cm precision ✅
- `fmtRows()`: Both round to nearest integer with minimum 1 ✅
- `fmtPct()`: Both round to whole-number percentage ✅

**Code quality notes:**
- Swift implementation is cleaner with explicit `stitchCountMultiplier` variable — makes intent clearer than JS's `ys/ps` inline
- Separation of display metric (`stitchWidthScale = ps/ys`) from count multiplier (`stitchCountMultiplier = ys/ps`) is well-designed
- Test structure mirrors JS test organization perfectly

**Files changed:** None — no corrections required.

**Blockers:** None — formula port is production-ready. (Earlier CI runner issue noted in 2026-05-19T10-44-03Z log was infrastructure, not code.)

---

## 2026-05-19 (Follow-up Review) — Craft-Truth Re-Verification

**Re-verification scope:** After Jacquard's initial sign-off, conducted a second line-by-line verification of the Swift-to-JS formula mapping against canonical specification and all 6 test scenarios. This was a due-diligence step to ensure no drift or edge-case misses.

**Verification checklist:**

1. **Formula 1 (Stitch count multiplier):** `count × (your_st / pattern_st)` ✓
   - JS: `patCastOn * (ys / ps)` ✓
   - Swift: `patCastOn * (ys / ps)` explicitly ✓
   - Logic verified: looser stitch gauge (28 st/10cm) → multiply by <1 → cast on FEWER stitches ✓

2. **Formula 2 (Row count multiplier):** `rows × (your_row / pattern_row)` ✓
   - JS: `patIncs * rowCountScale` where `rowCountScale = yr / pr` ✓
   - Swift: same ✓
   - Logic verified: denser row gauge → multiply by >1 → more rows between increases ✓

3. **Formula 3 (Section depth cm):** `cm × (pattern_row / your_row)` ✓
   - JS: `dimScale = pr / yr` ✓
   - Swift: `dimensionScale = pr / yr` ✓
   - Logic verified: denser row gauge → multiply by <1 → knit to SHALLOWER depth ✓

4. **Formula 4 (Increase spacing):** `spacing × (your_row / pattern_row)` ✓
   - JS & Swift: same ✓

5. **Display metrics vs. adjustment multipliers:**
   - `stitchWidthScale = ps / ys` (display metric) ✓
   - `rowCountScale = yr / pr` (used both for display AND as multiplier for row counts) ✓
   - Separation of concerns clear in both implementations ✓

6. **Rounding & formatting:**
   - `fmtCm()`: round to 0.1 cm → `Math.round(x * 10) / 10` (JS) = `(value * 10).rounded() / 10` (Swift) ✓
   - `fmtRows()`: round nearest integer, min 1 → identical ✓
   - `fmtPct()`: round to whole-number percentage → identical ✓

7. **Test scenario parity:**
   - All 6 primary scenarios tested and passing ✓
   - All 6 edge cases tested and passing (2× dense, 2× loose, FP precision, cast-on rounding) ✓
   - Expected values match canonical spec exactly ✓

**Knitter-facing implications verified:**
- Denser row gauge → shallower depths (fewer cm), more frequent increases ✓ **CORRECT FOR KNITTER**
- Denser stitch gauge → more stitches cast on (to hit same width) ✓ **CORRECT FOR KNITTER**
- Looser stitch gauge → fewer stitches cast on ✓ **CORRECT FOR KNITTER**

**Conclusion:** ✅ **NO CORRECTIONS NEEDED** — Swift implementation is a faithful, craft-correct port of the JS prototype. All formulas are correct, all test scenarios pass with canonical expected values, and knitter guidance is accurate.


## [2026-05-19 19:13:04Z] Canonical Xcode Project Path Update

⚠️ **All squad members:** The Xcode project has been renamed to **`app/app.xcodeproj`**. 

- **Previous path:** `app/KnittingGaugeReconciler.xcodeproj`
- **Current path:** `app/app.xcodeproj` (canonical reference)
- **App target & scheme:** `KnittingGaugeReconciler` (unchanged)
- **Build script:** `app/build.sh` updated and validated

Any references to the old project path should be updated. Use `app/app.xcodeproj` going forward.

---

### 2026-05-19 — corrected canonical Xcode project path

Correction to earlier path note: the project bundle must remain `app/KnittingGaugeReconciler.xcodeproj` per the explicit Tesla scaffold priority item. Math review remains against `GaugeMath.swift` in the `KnittingGaugeReconciler` scheme.

## [2026-05-20T05:06:06Z] Saved Reconciliations Domain Evaluation

**Session:** Evaluated knitting workflow fit for saved reconciliations  
**Participants:** Jacquard (domain expert), Tesla (architecture), Mendel (user research)  
**Output:** Domain evaluation, orchestration log, decision archive

**Verdict:** INSUFFICIENT storing just swatch dimensions. Context required for trust and reusability.

**Critical Context Needed:**
- **Stitch pattern** (garter, stockinette, ribbing — affect gauge differently)
- **Blocking state** (pre- or post-blocking; 10–15% gauge swing)
- **Yarn fiber content** (wool vs. cotton vs. acrylic; different stretch profiles)
- **Needle size** (reconciliation tied to specific needle; crucial for reproduction)
- **Memorable label** (e.g. "Flax Cardigan 5.5mm bamboo" vs. raw numbers)

**Risk:** Knitter saves linen reconciliation (5.5mm, stockinette, pre-blocked) and reuses for cotton tee (5.0mm, ribbing, post-blocked) without metadata context. Reconciliation becomes misleading and useless.

**Recommendation:** Save four gauge points as proposed. Add fifth: label + stitch pattern + blocking state. Minimal overhead, massive trust/UX improvement.

**Handoff status:** Ready for implementation (Edison) and design (Ive). See `.squad/decisions.md` (2026-05-19 Evening Session) and orchestration logs for full context.

### [2026-05-20T18:19:39-07:00] swift-metrics scope — domain signals vs vanity (issue #9)

Domain scoping for yashasg's observability checklist on the offline iOS
calculator. Decision drop: `.squad/decisions/inbox/jacquard-metrics-scope.md`.

**What I'd actually want to see locally, and why each is craft-meaningful
(not vanity):**

1. **Axis-mismatch shape** (counter: match / stitch-only / row-only / both).
   This is the app's distinctive thesis — row gauge as a peer axis, not an
   afterthought. The bucket distribution directly tests whether the
   two-axis UI is earning its weight or whether real users are
   overwhelmingly single-axis (in which case row-gauge prominence is
   over-indexed). Threshold matches the existing 3% verdict "Match" band so
   the metric and the UI agree on what counts as a mismatch.

2. **Drift magnitude buckets per axis** (<3% / 3–10% / 10–25% / >25%).
   Aligned with existing verdict copy (Match / Drift / Significant drift /
   Major mismatch). Tells us whether the calculator is mostly a
   reassurance tool (small drift) or a yarn-substitution tool (large
   drift) — those imply very different next-feature priorities (rounding
   refinements vs. blocking advice vs. yarn-fiber metadata). Two axes must
   stay separate; combining defeats signal #1.

3. **Implausible-input counter** (<10 or >50 st/10 cm; <12 or >70 rows/10
   cm). Math still produces a number (correct, §2.2 determinism intact),
   but the answer isn't useful. Fingerprint of the most common typo:
   stitches-per-inch typed into stitches-per-10cm (5× factor → values
   cluster near ~5 or ~150). Actionable: a soft input hint or
   unit-confusion guard.

4. **Cast-on rounding drift bucket** (read off the existing
   `castOnRoundingDriftPercent` field, buckets <0.5% / 0.5–2% / >2%).
   The single cast-on-level signal worth capturing. A real population in
   the >2% bucket is the trigger to add stitch-pattern-repeat-aware
   rounding — a real math change I'd want to spec before Ada touches it.

5. **Section inspected** (yoke / body / sleeve / increase-spacing) — only
   if Edison's UI distinguishes them via expand/collapse or similar. Tied
   directly to the 7 archetypes: top-down vs bottom-up vs raglan/yoke
   shaping each privilege a different section. If `increase-spacing`
   traffic is near-zero while row-axis drift is common, that's a UX
   placement problem, not a math problem.

6. **Saved-reconciliation context completeness** (label edited?
   stitch-pattern set? blocking state set? etc.) — once Tesla/Edison ship
   that feature. Direct test of my 2026-05-19 evening stance that raw
   four-numbers are insufficient. If users overwhelmingly leave defaults
   blank, we're in the misleading-saved-entry failure mode and should
   nudge harder or accept it and drop the pretense of reusability.

**Vanity I explicitly rejected:**

- Compute duration, recompute count, render time — perf/tooling signals,
  Tesla/Hopper's domain, tell me nothing about craft correctness.
- Raw input values stored as metrics — bucketed signals are enough; raw
  storage is the saved-rec feature's job (opt-in, explicit user intent).
- Verdict-copy variant displayed — duplicates the drift-magnitude buckets.
- Format-function call counts — derivative of `compute()` calls.
- Time-of-day / day-of-week — lifestyle, not knitting.
- Toggle-between-adjusted-and-pattern — no such toggle exists; both are
  shown together by design (row gauge as peer axis, vocabulary cheat
  sheet).

**Why I keep insisting "domain vs vanity":** in a 0-network offline tool,
every signal that's not actionable is purely a cost on cognitive load
and code surface. The bar is: "if this counter spiked, would I change the
math or change the UI?" — if no, the signal is decorative. Every signal I
proposed has an explicit named recommendation if it trends.

**Constraints:** every signal is captured at the `ContentView` boundary
from inputs-as-typed or fields already on `GaugeMathResult`. None require
touching `GaugeMath.compute` or its helpers — §2.2 determinism intact.
30-second first-use path safe: O(1) bucket checks; implausible-input
bucketing must run on the same debounce as live-recalc, otherwise
mid-keystroke partial values (`3` before the `2` lands) would trip it
spuriously.

### [2026-05-19 19:58:36Z] Per-Section Adjustment Semantics — Knitter-Facing Validation

**Task:** Review knitting domain semantics for per-section adjustment guidance.

**Validation confirmed:** The app should NOT tell a user that "a 20 cm yoke should be 15 cm." Instead:
- **Rows/rounds change** to match the user's gauge
- **Finished garment measurements stay the same** across all gauge variations
- User's gauge determines how many rows/rounds are needed to hit the cm target
- The finished measurement target is fixed; rows/rounds are the computed output

**Domain principle:** Knitters think in finished garment dimensions (20 cm yoke width). Their gauge determines the row count needed. This tool preserves that mental model.

## Team updates
- 2026-05-20T18:19:39-07:00: swift-metrics scoping round (issue #9) completed. 8-agent parallel pass. Decisions merged to decisions.md (now 98,243 bytes).
