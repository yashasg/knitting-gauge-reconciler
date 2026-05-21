# Edison — History

## Core Context

- **Project:** A knitting gauge reconciler that converts patterns between stitch/row gauges.
- **Role:** Frontend Dev
- **Joined:** 2026-05-19T07:11:08.646Z

## Learnings

### 2026-05-20T20:38:28-07:00 — Cleanup Round 2026-05-20

**Session:** cleanup-round (Edison audit + implementation)

**8 items shipped (all code cleanup + 1 P0 correctness fix):**
- **1.1:** TODO marker on MetricsSubscriber diagnostic seam asymmetry (V2 footgun).
- **2.1:** gaugeStatus/rowStatus dedupe (internal in GaugeMath, ContentView copies deleted, ~12 lines removed).
- **2.2:** plain/formatPlain dedupe (canonical plain() internal in GaugeMath, 14 call sites migrated). Divergence flag: `plain()` trims to 2dp; `formatPlain()` uses Swift default. For 3+ decimals: `24.333` → `"24.33"` vs `"24.333"`. All real knitting inputs are integers or 1dp, no user-visible regression.
- **2.3:** HeroMetric.pillBackground dedupe (deleted, all callers use free function sharePillBackground, ~7 lines removed).
- **4.1 (P0):** Signpost inflation fixed. `result` computed property fired `os_signpost(.begin/.end)` 15-20×/body render; now fires 1× per input change via cached `@State var cachedResult` + `.onChange(of: inputs, initial: true) { recomputeResult() }`. Bonus: eliminates per-keystroke GaugeMathResult recomputation.
- **4.2:** AppTheme.tertiary dead color removed (unused).
- **4.3:** AppTheme.warning{Text,Background,Accent} added for AboutHelpSheet scope callout (RGB values unchanged from inline literals).
- **4.4:** Redundant `= nil` stripped from `@State private var previousVerdictBucket: VerdictBucket?`.

**Build:** `./app/build.sh test` → exit 0, 0 warnings, 49/49 tests pass.

**4.1 fix shape choice (Option a):**
- Why `.onChange(of: inputs, initial: true)` over `.task(id: inputs)`: Avoids Swift 6 async/actor isolation; `.onChange` is synchronous main-actor. `initial: true` fires on first appear and every subsequent input change.
- Why option (a) over (b): (a) also eliminates per-keystroke recomputation cost. Bonus performance win beyond signpost correction.
- Signpost correctness verified: no input change → 0 fires; input change → exactly 1 fire.

**2.2 divergence flag:** `plain()` canonical (2dp trim trailing zeros); `formatPlain()` deleted (14 call sites migrated). Verified no real-knitting-value divergence via existing share-text formatter tests (all pass).

---

## 2026-05-20T19:26:30Z — MetricKit V1 Implementation

MetricKit V1 shipped. 9-name signpost roster locked by user directive (2026-05-20T19:26:30). Build: 49/49 tests (was 25). Files created: MetricsSubscriber.swift, GaugeMathMetrics.swift. ContentView.swift: 9 signpost call sites, 2 @State vars. PrivacyInfo.xcprivacy wired.

---

## Earlier Sessions

(See history-archive.md for full timeline of 2026-05-19 and earlier 2026-05-20 work.)
