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
- **All 6 Jacquard scenarios confirmed covered (2026-05-19):** Prototype tests (77 passing), Swift unit tests (6 scenarios), and Swift UI tests (6 scenarios all visible) provide complete coverage. Gap found and fixed: Scenario 3 sleeve formatting assertion added to Swift tests. No blockers remain for test coverage.

### 2026-05-19 — Round 3: User Research Foundation + Personas (Delivered)

**Round 3 outcome:** Produced 5 JTBDs, 4 primary personas, 2 journey sketches, accessibility floor, anti-personas, and 10 open research questions. All personas + JTBDs now consolidated in `.squad/decisions.md` Round 3 section.

**Key insight on Birgitta:** Accessibility profile (44pt touch targets, Dynamic Type +3, semantic VoiceOver, text labels on every color pill) is non-negotiable baseline, not accommodation. Establishes ship-blocking floor for all implementation.

**Key insight on concrete numbers:** Miriam needs "Cast on 118 stitches," not "0.917 scale factor." Donal needs "Knit to 17.5 cm, not 20 cm," not "10% denser." Every output must lead with concrete, actionable integer before any explanation or percentage.

**Hypothesis validation gap:** Row gauge as the more-commonly-mismatched axis is plausible from community discussions but unconfirmed for this product's specific user base. Pre-cast-on vs. mid-project trigger split is directional only; no server-side analytics available. Birgitta's profile is constructed from published disability prevalence data, not interviews with knitters who have disabilities. All flagged for real-world research in future round.


## [2026-05-19 19:13:04Z] Canonical Xcode Project Path Update

⚠️ **All squad members:** The Xcode project has been renamed to **`app/app.xcodeproj`**. 

- **Previous path:** `app/KnittingGaugeReconciler.xcodeproj`
- **Current path:** `app/app.xcodeproj` (canonical reference)
- **App target & scheme:** `KnittingGaugeReconciler` (unchanged)
- **Build script:** `app/build.sh` updated and validated

Any references to the old project path should be updated. Use `app/app.xcodeproj` going forward.

---

### 2026-05-19 — corrected canonical Xcode project path

Correction to earlier path note: the project bundle must remain `app/KnittingGaugeReconciler.xcodeproj` per the explicit Tesla scaffold priority item. Scenario mapping remains tied to the `KnittingGaugeReconciler` test/UI-test targets.

## [2026-05-20T05:06:06Z] Saved Reconciliations User Value Research

**Session:** Evaluated knitter mental model for saved reconciliations  
**Participants:** Mendel (user research), Tesla (architecture), Jacquard (domain)  
**Output:** Research documentation, orchestration log, decision archive

**Finding:** Four gauge numbers alone are insufficient. Knitters think in "pattern + yarn + needle" triples.

**Critical Metadata Required:**
- **Pattern name** (user input, ~50 char) — primary lookup key
- **Yarn identifier** (user input, ~40 char) — secondary lookup for fiber comparison
- **Timestamp** (auto-generated, optional user label ~20 char) — temporal context
- **Stitch pattern + blocking state** (optional but high-value)

**MVP Recommendation:** Store 4 gauge values + 3 metadata fields. 43.75% data increase → 10x usability improvement. All labels text-based and discoverable; no design-only communication.

**Handoff status:** Ready for design (Ive) and implementation (Edison). See `.squad/decisions.md` (2026-05-19 Evening Session) and orchestration logs for full context.

## [2026-05-20T18:19:39-07:00] Swift metrics scope (GitLab issue #9) — research view

**Session:** Scoping which research questions a local-only counter/gauge/timer could illuminate for issue #9. Constraint: no off-device upload, no PII, no aggregated cross-user data; 30-second first-use path is sacred.

**Deliverable:** `.squad/decisions/inbox/mendel-metrics-scope.md` (5 on-device research questions + scenario-coverage table + out-of-scope list + slippery-slope risks).

### Learnings — questions that DO map to on-device-only signals

- **Q1 — Scenario distribution across the 6 Jacquard branches.** A 6-slot counter keyed by `(stitchWidthScale, rowCountScale)` buckets validates whether row-only drift (Scenarios 2/3) dominates, as the Round-3 persona hypothesis predicted, vs. two-axis (Scenario 6) being a niche. Pure scalar counter, no inputs persisted.
- **Q2 — Cast-on path engagement (Scenarios 4/5/6).** Counter on `computeActStitches ≠ patStitches` sessions vs. no-change sessions tells us whether Miriam (pre-cast-on, JTBD-1) is a real user path on yashasg's device or whether everything is Donal (mid-project, cast-on already done). Directly tests an unconfirmed Round-3 persona hypothesis.
- **Q3 — Time-to-first-compute timer.** Elapsed-ms timer from `ContentView` appear to first non-default verdict gives an objective regression alarm for the 30-second sacred path without needing beta complaints. Currently we have only Ive's subjective review.
- **Q4 — Field re-edit churn per input field.** 4-slot counter for `(ps, pr, ys, yr)` re-edits within ~10s of previous commit identifies confusing field labelling. Tests Donal-persona-derived hypothesis that knitters confuse "pattern" vs "your" and stitch vs row axes.
- **Q5 — Verdict-help `?` engagement by verdict state.** 4-slot counter keyed by verdict state (Match, Drift, Significant, Major) validates the compact-title-plus-`?` pattern Edison shipped 2026-05-19, and tells us which verdict copy actually deserves elaboration.

### Learnings — questions that DO NOT map to local signals (out of scope)

- **Per-user abandonment / retention** — on-device counter cannot separate yashasg dogfooding from real abandonment.
- **Wild-population skew** (denser-row vs looser-row prevalence; persona prevalence between Miriam / Donal / Reema / Birgitta) — needs cross-user sample; flagged in Round 3 as unconfirmed and stays unconfirmed.
- **Share-sheet outcome** (did the PNG actually get sent vs cancelled) — needs OS-level hooks we are not adding plus aggregation.
- **Outcome metrics** (do users reknit less after using the app) — longitudinal cross-user data + self-report; explicitly NOT achievable from on-device counters.
- **Time-of-day / day-of-week patterns** — would need wall-clock logging that itself is a privacy/slippery-slope risk; refused.
- **Accessibility-cohort success rates** (Birgitta — one-handed, low-vision) — must be answered via recruited research, not metrics.

### Slippery-slope items flagged for Tesla / Hopper / privacy review

Raw gauge values stored alongside counters; wall-clock timestamps finer than per-launch; any session/install ID even "anonymous"; capturing free-text inputs (saved-reconciliation labels, pattern/yarn names from Tesla's saved-reconciliations work); a separate on-disk metrics file that survives uninstall via iCloud; `Logger`/`os_log` calls inside `GaugeMath.compute` (already banned by Tesla §2.2 + §2.12); a "diagnostics export" affordance that would naturally pick up metrics. Each is a **risk**, not a recommendation.

### Sacred-path constraint

Metric instrumentation must add zero blocking work on launch — no consent prompt, no first-run dialog, no synchronous I/O. Counters fire on user compute actions, not on launch. The Q3 timer **measures** the 30s path; it must not **gate** it. If a metric ever requires a first-run consent screen, that metric is out of scope by definition.

## Team updates
- 2026-05-20T18:19:39-07:00: swift-metrics scoping round (issue #9) completed. 8-agent parallel pass. Decisions merged to decisions.md (now 98,243 bytes).
