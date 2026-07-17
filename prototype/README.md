# Knitting Gauge Reconciler — Prototype

**Idea slug:** `knitting-gauge-reconciler`
**Cycle:** 2026-05-18i
**Tagline:** *Two-axis gauge math for sweaters that actually fit.*
**Stack:** Vanilla HTML + JS + CSS · single file · no build step · no backend · no API calls
**Reviewer time:** 60–90 seconds

---

## What this is

A static HTML page that takes the pattern's stitch+row gauge per 10 cm AND the knitter's swatched stitch+row gauge per 10 cm, then shows:

- the **two-axis reconciliation** (stitch-wise % horizontal, row-wise % vertical, each with a colour-coded pill — Match / Looser / Tighter / Much denser / etc.),
- a **per-section adjustment table** for the four vertical dimensions that bite hardest — yoke depth, body length, sleeve length, increase-row spacing — each editable so the knitter types in *their* pattern's number and reads off the actual cm they should knit to,
- a plain-language **verdict** that names the drift in cm-and-% and tells them what to do about it.

The whole point is the dual-axis: every other gauge calculator in the App Store and on the web treats gauge as a single number. None of them tells you that a denser row gauge means knitting a 20 cm yoke to 15 cm to preserve its row count.

---

## Run it (≤ 2 steps)

1. `open prototypes/knitting-gauge-reconciler/index.html`
2. (Already showing the default mismatch — pattern 32×24 vs your 32×32 → stitches match, row gauge 33% denser → "Knit to 15.0 cm for a 20 cm yoke depth.")

That's it. No server. No `npm install`. No `python -m http.server`. No network.

---

## Click-through (what a reviewer should see in 60 seconds)

- On load, four gauge inputs are pre-filled with the **Ghost Hunter Sweater** mismatch from r/knitting Signal 1: pattern asks **32 st × 24 rows** per 10 cm; the knitter's swatch hits **32 st × 32 rows** per 10 cm.
- The two hero numbers above already say it: **"100%" Stitch-wise — Match** (green pill); **"133%" Row-wise — Much denser** (amber/alert pill). The verdict line reads: *"Your stitch gauge matches the pattern, but your row gauge is 33% denser than expected. Every vertical section (yoke, body length, sleeves, German short rows) needs the dimension correction below — read the 'Knit to ___' column."*
- The per-section table immediately below shows the pattern's defaults already adjusted: **Yoke 20 cm → knit to 15.0 cm · Body 50 cm → knit to 37.5 cm · Sleeve 45 cm → knit to 33.8 cm · Increase every 6 rows → space every 8 rows**.
- Edit **Yoke depth** from `20` to `25` — the "Knit to" cell re-renders to **18.8 cm** as you type. No submit.
- Change **Your rows** from `32` to `24` — every number snaps back to 100% / 100% / pattern-as-written ("Both gauges match — knit straight from the pattern"). The verdict updates to that copy.
- Change **Your stitches** from `32` to `28` and **Your rows** back to `32` — both axes are now off. The verdict surfaces both drifts in the same sentence and recommends picking a different pattern size to land at the right width.
- Expand **Show the math** — exact arithmetic appears, including the aspect ratios on each axis and the row-count scale calculation.
- Tap **Reset to defaults** to return to 32 / 24 / 32 / 32.
- Tap **Copy share link** — the URL hash already encodes the current gauge (e.g. `#ps=32&pr=24&ys=32&yr=32&py=20&pb=50&pl=45&pi=6`), and the button copies it to the clipboard for sharing on Reddit / Discord.
- Refresh the page — the gauge persists (localStorage). Open the share link in a fresh tab — the gauge loads from the hash and overrides whatever was in localStorage.

That's the full app surface.

---

## What's where in `index.html`

| Section | Purpose |
|---|---|
| `<style>` block | All visual styling. Cream `#FAF6F0` background + heather purple `#6B4A85` accent. Sage `#5E8B6B` / amber `#C68B2C` / magenta `#9B3F6C` for the three gauge-drift severity pills. Single-file CSS, no external sheet. |
| **Your two gauges** card | Four numeric inputs grouped into "Pattern gauge (per 10 cm)" and "Your swatch (per 10 cm)" — st/row each |
| **Reconciliation — both axes** card | Two hero values + drift pills + axis-context lines + verdict + per-section adjustment table (4 rows, each editable) + collapsed "Show the math" breakdown + Reset / Copy share link buttons |
| **About this calculator** card | Non-claims block — the Donatello-mitigation scope-boundary line + the Raphael-mitigation non-affiliation note. Both copies must persist verbatim in the iOS build. |
| **Privacy** card | No-backend statement — localStorage + URL hash only, zero network |
| `<script>` block | Vanilla JS (no dependencies) — compute, render, persist, hash, share — ~150 lines |

---

## Math reference

Let `ps` = pattern stitches per 10 cm, `pr` = pattern rows per 10 cm, `ys` = your stitches per 10 cm, `yr` = your rows per 10 cm.

```
stitchWidthScale = ps / ys      // fraction of pattern's intended width your stitches occupy
rowCountScale    = yr / pr      // row-density display and shaping multiplier
dimensionCorrection = pr / yr  // multiplier on every vertical dimension
```

For any vertical dimension D the pattern names (yoke depth, body length, sleeve length, etc.) and any number of rows R it specifies between shaping rows:

```
actual_cm   = D × dimensionCorrection
actual_rows = R × rowCountScale   // rounded to nearest integer for "increase every N rows"
```

### Drift bands (the pill colours)

| Pill | Drift from 1.0 | Colour |
|---|---|---|
| Match | < 3% | sage-green `#5E8B6B` |
| Looser / Tighter (st) or Denser / Looser (row) | 3–10% | warm amber `#C68B2C` |
| Much looser / tighter / denser | ≥ 10% | deep magenta `#9B3F6C` |

The bands are pure UX colour — they are not a "you can't proceed" gate. A knitter with 12% drift can still knit the project, they just need to be more deliberate about the per-section adjustments.

---

## Suggested iOS build stack (for yashasg's iOS dev team)

This prototype proves the math, the layout, and the UX rhythm. The iOS version should be a thin, native version of the same single screen, plus saved-gauge history.

| Concern | Recommended approach |
|---|---|
| **Language / framework** | Swift + SwiftUI. iOS 16+ minimum. No UIKit, no Catalyst. |
| **Math** | Pure Swift `struct ReconciledGauge` with computed properties. `Double` throughout. Round to 1 decimal for cm display; round increase-row spacing to nearest integer. |
| **State** | `@State` in the main view for the eight inputs (4 gauges + 4 pattern dims); `@AppStorage` (i.e. `UserDefaults`) for the persisted last-gauge (mirrors the prototype's localStorage). |
| **Saved-gauge library** | A second screen (`NavigationStack` push) that lists saved (pattern, swatch, name) triples. Free tier: last **3 gauges** auto-retained. Paid tier: unlimited library + manual naming. Use `SwiftData` or a tiny `Codable` array in `UserDefaults` — do not introduce CoreData for this scope. |
| **Monetization** | **StoreKit 2 non-consumable** IAP at **$2.99 USD**. v1: pay-once unlock of the whole app (matches the prototype's behaviour). Optional v2 freemium split: free tier limited to last 3 gauges, $2.99 unlocks unlimited library + construction-specific shaping packs. No subscription, no consumables, no ads. See `LAUNCH-PLAN.md` §Monetization for the full rationale. |
| **Share** | `ShareLink` with the same URL-hash format the prototype emits (`https://your-domain/?#ps=32&pr=24&ys=32&yr=32&py=20&pb=50&pl=45&pi=6`). If you host the web prototype on a free Pages instance, it becomes the canonical share-target. |
| **Accessibility** | Dynamic Type fully supported (the prototype already uses relative sizes). VoiceOver labels on every input. The hero numbers + drift pills + axis-context lines should be `accessibilityCombined` so VoiceOver reads each hero as one unit. |
| **Privacy** | App Privacy nutrition label: **Data Not Collected**. No analytics SDK. No crash reporter that phones home. No NSURLSession against any host. |
| **No-go list** | No Ravelry sync, no PDF pattern reader, no AI yarn suggestions, no social, no cloud sync, no progress tracker. Every one of those dilutes the single-job framing that the channel-fit depends on. |

### Single-screen layout (mirror the prototype)

```
NavigationStack {
  Form {
    Section("Pattern gauge (per 10 cm)") {
      GaugePairView(stitches: $patternStitches, rows: $patternRows)
    }
    Section("Your swatch (per 10 cm)") {
      GaugePairView(stitches: $yourStitches, rows: $yourRows)
    }
    Section("Reconciliation") {
      HStack {
        HeroView(label: "Stitch-wise", scale: stitchWidthScale)
        HeroView(label: "Row-wise",    scale: rowCountScale)
      }
      VerdictView(verdict: verdictFor(gauges))
      ForEach(sections) { s in
        SectionRowView(name: s.name, patternValue: $s.patternValue, actual: actual(s))
      }
      DisclosureGroup("Show the math") { BreakdownView(...) }
    }
    Section { ... About ... }
    Section { ... Privacy ... }
  }
  .navigationTitle("Knitting Gauge Reconciler")
}
```

The two heroes MUST stay in an `HStack` (side-by-side) on regular-width devices. Stacking them vertically weakens the value prop. See April's Stage 7 UX mitigation in `LAUNCH-PLAN.md`.

---

## Mitigation chain (from cycle 2026-05-18i Stages 3, 4, 7)

| Source | Mitigation | Where it lives |
|---|---|---|
| Donatello / Stage 3 | Scope-boundary line: *"This tool provides estimates based on your swatch measurements. Always test a full-size gauge swatch before starting your project."* | `index.html` § About → `.warn` block. iOS must keep verbatim. |
| Raphael / Stage 4 | Non-affiliation line: *"Not affiliated with Ravelry, Knit Companion, or any pattern designer."* Pattern names (Ghost Hunter Sweater, Jenny jacket) appear in dev artifacts only, never in app body. | `index.html` § About. iOS preserves descriptive framing. |
| Karai / Stage 6 | None — HIGH-confidence PASS. | n/a |
| April / Stage 7 UX | Hero numbers side-by-side at ≥520pt. Live recalculation on `oninput` — no Calculate button. | `index.html` `.heroes` grid; iOS `HStack` on regular width. |
| Mondo / Stage 7 Distribution | First seed post on r/knitting must be a useful answer on a gauge-mismatch thread, not a "Show /r/" promo. | `LAUNCH-PLAN.md` § Channel sequence. iOS team executes. |

No YELLOW flags survived to Stage 8. The cycle's cleanest GREEN-GREEN-GREEN idea — debate not triggered.

---

## Sample calculations

| ps | pr | ys | yr | Stitch-wise | Row-wise | Verdict shape |
|---|---|---|---|---|---|---|
| 32 | 24 | 32 | 32 | 100% (Match) | 133% (Much denser) | "stitch matches, row gauge 33% denser" — DEFAULT |
| 32 | 24 | 32 | 24 | 100% | 100% | "Both match — knit straight from the pattern" |
| 32 | 24 | 32 | 20 | 100% | 83% (Much looser) | "stitch matches, row gauge 17% looser — verticals longer" |
| 32 | 24 | 28 | 24 | 114% (Much looser) | 100% | "row matches, stitch gauge 14% looser — pick a smaller pattern size" |
| 32 | 24 | 28 | 32 | 114% | 133% | "Both axes off — both shaping AND vertical adjustments needed" |
| 22 | 30 | 24 | 30 | 92% (Tighter) | 100% | "stitch 8% tighter — pick a larger pattern size" |
| 22 | 30 | 22 | 28 | 100% | 93% (Looser) | "row gauge 7% looser — verticals slightly longer" |
| 22 | 30 | 22 | 30 | 100% | 100% | "match" (boundary at 0%) |
| 22 | 30 | 23 | 31 | 96% (Tighter) | 103% (Denser) | "both axes slightly off — stitch tighter, row gauge denser" |

Boundary behaviour: pill colour switches at drift = 0.03 (3%) and drift = 0.10 (10%). Reference values around these boundaries are `drift = 0.029, 0.030, 0.031, 0.099, 0.100, 0.101` on each axis.

### Per-section maths for the default 32/24 vs 32/32 case

| Section | Pattern says | Knit to |
|---|---|---|
| Yoke depth | 20 cm | **15.0 cm** (= 20 × 24/32) |
| Body length | 50 cm | **37.5 cm** (= 50 × 24/32) |
| Sleeve length | 45 cm | **33.8 cm** (= 45 × 24/32) |
| Increase spacing | every 6 rows | **every 8 rows** (= round(6 × 32/24)) |

---

## Scope boundary

This app reconciles a two-axis gauge mismatch into per-section cm adjustments. It does **not** read pattern PDFs, store finished-project measurements, track yarn inventory, suggest needles or yarn, schedule knitting sessions, or analyze finished-garment fit.

If a future feature is proposed, ask: "does this make the two-axis reconciliation sharper, or is it a different product?" If different — different product, new loop cycle. Don't drift.

---

## Squad references

- Approved in cycle `2026-05-18i` (1 KILL-GATE drop: `climbing-grade-cross-comparator`; 2 advanced: this idea and `one-rep-max-estimator`).
- Stage 9 approval verdict: `.squad/decisions/inbox/leonardo-loop-2026-05-18i-knitting-gauge-reconciler.md`.
- Demand signal: r/knitting `t3_1n0is5t`, 77 upvotes, 2025-08-26 — cited verbatim in `.squad/decisions.md` Stage 1 brief.
- Karai monetization: HIGH-confidence $2.99 one-time, 3 comps cited (Knitting Stitch Calculator $1.99, Ravit $4.99, Knit Companion $14.99).
- Inspiration: the dual-axis framing reuses the structural template from `sourdough-hydration-decoder` (cycle 2026-05-18h) — surface a hidden two-dimensional calculation that single-axis incumbents hide.
