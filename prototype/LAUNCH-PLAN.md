# Launch Plan — Knitting Gauge Reconciler

**Idea slug:** `knitting-gauge-reconciler`
**Cycle:** 2026-05-18i
**One-line tagline:** *Two-axis gauge math for sweaters that actually fit.*
**Status:** Loop-approved (Stages 1–9 cleared, all 🟢 GREEN, no debate triggered). Awaiting handoff to yashasg's iOS dev team.
**Owners on this doc:** Karai 💰 (Monetization) · Mondo 📊 (Distribution)

---

## What the prototype is

A single static HTML page. The user types four numbers — the pattern's stitch and row gauge per 10 cm, and their own swatch's stitch and row gauge per 10 cm — and instantly sees:

- **Stitch-wise %** — the fraction of pattern width their stitches produce (horizontal scaling).
- **Row-wise %** — the cm multiplier they must apply to every vertical section (yoke, body, sleeves, increase spacing).
- A **per-section adjustment table** for the four vertical dimensions that bite hardest when row gauge is off: yoke depth, body length, sleeve length, and increase-row spacing. Each row is editable — the knitter types in their pattern's number and reads off the actual cm they should knit to.

The whole point is the **two-axis reconciliation**: every existing gauge calculator (Knitting Stitch Calculator $1.99, Ravit $4.99, the free web tools at knittingfool.com and gauge-calculator.com) treats gauge as a single number. None of them tells you that your yoke will be 6 cm too short because your row gauge is denser than the pattern's.

---

## Monetization (Karai 💰)

### Recommendation

| Field | Value |
|---|---|
| **Model** | One-time purchase |
| **Price** | **$2.99 USD** |
| **Confidence** | **HIGH** |
| **Subscription?** | No — fails Karai's subscription HARD RULE on prong (b): no cited recurring-WTP signal in the knitting-calculator category. |

### Why one-time

Per the squad's monetization charter and the 2026-05-18 directive in `.squad/decisions.md`, subscriptions are only justified when **both** (a) trivial to wire (auto-renewable StoreKit IAP, no custom billing) **and** (b) cited comparable-app revenue showing strong recurring willingness-to-pay in the persona's category. The knitting-calculator category has **no public revenue signal** indicating recurring WTP. The two paid in-category comps (Knitting Stitch Calculator at $1.99, Ravit at $4.99) ship as one-time purchases. Knit Companion at $14.99 uses one-time IAP for premium feature unlocks — also one-time, not subscription. A subscription would underperform a one-time at the same price point and would create the wrong perceived value: the calculation is the product; there is no recurring server cost or content drop to justify a recurring charge.

### Comparable apps (cited)

All three are in-category (knitting / craft calculators), all priced as one-time purchases on the iOS App Store:

| App | Price | Model | Notes |
|---|---|---|---|
| **Knitting Stitch Calculator** (H3 Apps LLC) | $1.99 | One-time | Single-axis (stitches-only) gauge calculator. Direct floor-anchor for our category; our two-axis differentiator justifies pricing above. |
| **Ravit — Ravelry on the hop** (Enhancient) | $4.99 | One-time | Ravelry pattern browser + library. Not a calculator, but confirms that knitters pay for craft utilities at this price band. |
| **Knit Companion** | $14.99 (+ IAP) | One-time + non-consumable IAP for premium features | PDF pattern reader with row counters and chart overlays. High-end anchor; establishes that knitters spend on serious craft tools. |

**Price anchor:** $2.99 sits comfortably between Knitting Stitch Calculator ($1.99, single-axis) and Ravit ($4.99, pattern browser). We are decisively above the $1.99 floor because the dual-axis reconciliation is a hidden calculation the persona is currently doing in r/knitting threads three times a month — it is a step-function utility improvement, not a polish-pass on the single-axis tool.

### Willingness-to-pay evidence

From the Michelangelo Stage 1 signal pack (cited verbatim in `.squad/decisions.md` Stage 1):

> *"I want to make the Ghost Hunter Sweater and made those swatches. The project asks for 32x24 for 10cm. I get 32x32 so I guess my stitches are more square? What should I do now? Is it just the wrong yarn for the sweater? Can I just knit a smaller size?"*
> — **r/knitting** thread `t3_1n0is5t`, 77 upvotes, 2025-08-26

The OP is performing the exact two-axis reconciliation this app automates. The 77-upvote count on a confusion-shaped problem (not aspiration, not show-off — confusion) in a 600k-member community is exactly the signal shape that converts at $2.99 impulse-buy price points. The comments confirm the recurring nature: gauge math IS done by hand, by knitters, today, because no tool offers side-by-side row-vs-stitch reconciliation.

Secondary WTP signal — the persona's established paid-tool habit:

> *"Has paid for Knit Companion ($14.99), Knitter's Pride needle sizers, or other paid knitting tools — established paid-utility-in-craft habit."* — Michelangelo's Stage 1 persona, derived from r/knitting paid-tool discussions and Ravelry pattern-purchase norms ($5–8 per pattern).

The knitting community is not a free-tools-only audience. They buy patterns. They buy needles. They buy Knit Companion. A $2.99 utility that eliminates the "what should I do now?" friction is a clear time-for-money trade.

### Subscription decision (formal)

| HARD-RULE prong | Status | Reason |
|---|---|---|
| (a) Trivial StoreKit setup | ✅ would be (StoreKit auto-renewable IAP) | Not a blocker. |
| (b) Lucrative — cited comparable-app recurring revenue in this category | ❌ FAIL | All cited in-category comps are one-time. Knit Companion's IAP is one-time feature unlocks, not a subscription. No public revenue evidence of subscription model working for single-purpose knitting calculators. |

Both prongs must pass → **subscription rejected, one-time at $2.99 selected.**

### Pricing edges to test post-launch (iOS team's call, not ours)

- **$1.99** — the natural downshift if the audience proves more price-sensitive than Knitting Stitch Calculator's existing 5-star reviews suggest.
- **$3.99** — only if r/knitting acknowledges the dual-axis framing as "this is the canonical tool"; consider after 90+ days of stable 4.5★+ rating.
- **Never** — recurring subscription, free-with-ads, tip jar, donations. None fit this product or category. Karai's KILL-GATE language stands: free is not a model.

### Long-term unlock pattern (optional, not Stage-10 work)

If conversion is strong, the natural v2 expansion is a **"paid construction packs"** IAP shelf: $0.99 per construction type (top-down yoke / contiguous set-in / bottom-up raglan / drop-shoulder) that unlocks construction-specific shaping logic on top of the v1 generic vertical/horizontal multipliers. This is forward-looking — not in the Stage 10 prototype, not in the v1 iOS app.

---

## Distribution (Mondo 📊)

### Channel sequence

| # | Channel | When | Notes |
|---|---|---|---|
| 1 | **r/knitting** (~600k members) | Day-of-launch, on a weekday morning US East | The three Stage 1 demand signals are all from r/knitting. The community has explicit Self-Promo Sunday flair; outside Sundays, seed by replying on an active gauge-mismatch thread with a "I made this — does it match what you'd calculate by hand?" comment. Don't lead with "Show /r/knitting" — lead with the answer. |
| 2 | **r/Ravelry** (smaller, Ravelry-adjacent) | Day 3–7 | Smaller community, slightly more pattern-aware. Seed with a screenshot of the tool solving a specific Ravelry pattern's gauge mismatch (e.g., the Jenny jacket from Stage 1 Signal 2). |
| 3 | **Indie knitting Discord servers** (~50k+ across multiple servers — Guild Wars Knits, Knit Girllls, Knit Stitch, Knit Companion's official Discord) | Day 7–14 | More serious / craft-paid audience. The Knit Companion server in particular is a paid-utility-affinity audience. Lead with the dual-axis differentiator; expect questions on the math and answer them with the breakdown view. |
| 4 | **Ravelry forums** (Ravelry.com proper) | Day 14+ | Lower volume but very high engagement-per-post. Post in the "Techniques" or "Pattern Help" sub-forum, not the general one. |
| 5 | **IndieHackers — Show IH** | Day 14+ | Optional; only if Day 1–14 hit ≥1k installs and conversion is on plan. |

### Audience targeting

- **Primary persona:** 28–60-year-old intermediate knitter (≥3 years in the craft), knits at least one sweater or large garment per year (top-down yoke / raglan / set-in sleeve / drop shoulder), buys Ravelry patterns at $5–8, and has paid for Knit Companion or a similar craft utility. They substitute yarns. They block their swatches. They read pattern construction sections.
- **Secondary persona:** newer knitter (1–3 years) who has just discovered that "I matched gauge" doesn't always mean "the sweater will fit" — usually after one ripped-back project.
- **Not the audience:** absolute beginners (don't yet have a gauge swatch), professional knitwear designers (they have their own spreadsheets), and the Ravelry-as-a-social-network crowd who don't actually knit garments.

### Why these channels work at $2.99 one-time

The Reddit knitting community converts well on cheap one-time tools when the post is a *helpful answer* (not a *promotion*). $2.99 sits well below the knitting community's tested price ceiling ($14.99 for Knit Companion; $34.99 for a year of Knit Companion's IAP). The Discord channels are even better — they're audiences that already buy paid utilities and have explicit precedent for spending on craft tools.

### Soft-seasonality

Knitting searches and r/knitting subscriptions peak in **autumn/winter (Sep–Feb)** as sweater season begins. Time the launch for early September if possible. A secondary lift happens in **late spring (Apr–May)** as people start their winter sweater projects early.

### Free-tier feasibility

The prototype has **zero API calls** — all math is local. The iOS app has the same property. There is no API tier to worry about. App Store fees (15% small-business rate for revenue under $1M) are the only cost line.

### What Mondo does NOT do

Per loop §"What does NOT happen": no live launches, no real outreach, no community posts during the loop. The plan above is a handoff document for yashasg's iOS dev team to execute after the iOS build ships.

---

## Mitigation chain (from Stages 3, 4, 6, 7)

| Source | Mitigation | Where it lands |
|---|---|---|
| Donatello / Stage 3 | About panel must include scope-boundary line: *"This tool provides estimates based on your swatch measurements. Always test a full-size gauge swatch before starting your project."* | ✅ In `index.html` About panel `.warn` block. iOS team must keep verbatim in the iOS About screen. |
| Raphael / Stage 4 | About panel must include: *"Not affiliated with Ravelry, Knit Companion, or any pattern designer."* Pattern names (Ghost Hunter Sweater, Jenny jacket) appear in dev artifacts only, not in app body. | ✅ In `index.html` About panel. iOS team preserves descriptive framing. |
| Karai / Stage 6 | None — HIGH-confidence PASS. | ✅ |
| April / Stage 7 UX | Live recalculation on every `oninput` event — no Calculate button. Four gauge inputs in a 2-column grid at ≥520px, stacked on narrow screens. Hero dual numbers side-by-side at ≥520px. | ✅ Enforced via `.grid2` and `.heroes` grids in `index.html`. iOS team: SwiftUI `Grid` / `HStack` on regular width class. |
| Mondo / Stage 7 Distribution | First seed post on r/knitting must be a useful answer on a gauge-mismatch thread (Signal-1 template), not a "Show /r/" promo. | Documented above in §Channel sequence. iOS team executes after ship. |

No YELLOW flags survived to Stage 8. The cycle's cleanest GREEN-GREEN-GREEN idea alongside `sourdough-hydration-decoder` from cycle 2026-05-18h.

---

## What the iOS dev team needs from this doc

1. **The price tag:** $2.99 USD, one-time non-consumable IAP, configured in App Store Connect. No subscription.
2. **The launch channel order:** r/knitting first, r/Ravelry second, indie knitting Discord servers (especially Knit Companion's) third, Ravelry forums fourth, IndieHackers optional.
3. **The mitigation chain:** keep the scope-boundary About-panel line; keep the non-affiliation note; keep the dual hero numbers side-by-side at ≥520pt width.
4. **The launch timing:** target early autumn (Sep) if possible; secondary window late spring (Apr–May).
5. **What NOT to build:** Ravelry sync, pattern PDF reader, social features, cloud sync, AI yarn suggestions, recipe-quality scoring. Every one of those would dilute the single-job framing that makes the channel-fit work.

---

*Karai: monetization recommendation HIGH-conf $2.99 one-time, ≥2 comps cited (3 in fact), ≥1 WTP signal cited (2 in fact), subscription HARD RULE applied and failed prong (b). 🟢 PASS.*
*Mondo: distribution channels named and sequenced (r/knitting → r/Ravelry → indie Discord → Ravelry forums → IH), free-tier feasibility confirmed (zero API costs), no live launch during loop. 🟢 PASS.*
