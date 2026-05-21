# Edison — History

## Core Context

- **Project:** A knitting gauge reconciler that converts patterns between stitch/row gauges.
- **Role:** Frontend Dev
- **Joined:** 2026-05-19T07:11:08.646Z

## Learnings

- Gauge dimension formulas fixed in prototype/index.html: `dimScale = pr / yr` for vertical cm outputs, `rowCountScale = yr / pr` for hero display and increase spacing. Reference Jacquard spec (decisions.md: The Correct Math) for UI text matching.
- 2026-05-19 (Compact Fields): Implemented compact numeric fields (92–156 pt widths) with 140 pt minimum columns for paired fields. Accessibility Dynamic Type stacks fields and expands to full width. ContentView.swift updated; build passed.

- **2026-05-19 ContentView fidelity pass:**
  - Verdict copy must be axis-aware, not severity-only. The prototype branches on WHICH axes are off (stitch-only, row-only, both, neither); severity (`verdictTitle`) remains a useful headline but the body copy must reflect which axis needs attention.
  - `gaugeStatus()` and `rowStatus()` match prototype's `pillFor`/`pillRowFor`: "Match", "Looser/Tighter/Denser than pattern" (3–10%), "Much looser/tighter/denser" (≥10%).
  - Adjustment row labels must include an action verb: "Knit to X cm", "Space every X rows", "Cast on X stitches". UI test `scenario.body` and `scenario.increases` strings must be updated in lock-step with any label format change.
  - Cast-on drift pill (≥3% rounding error) is surfaced inline in `AdjustmentRow` via optional `driftPill: String?`, matching prototype's inline `pill-warn`.
  - `HeroMetric.pillBackground` has three branches: green (Match), amber (3–10% drift), alert-pink ("Much" ≥10%), matching prototype's `pill-good`/`pill-warn`/`pill-alert`.
  - XCTest `app.staticTexts["label"].exists` finds individual Text elements even inside `.accessibilityElement(children: .combine)` HStacks — adjust test expectations whenever `AdjustmentRow.adjusted` format changes.



## [2026-05-19 19:13:04Z] Canonical Xcode Project Path Update

⚠️ **All squad members:** The Xcode project has been renamed to **`app/app.xcodeproj`**. 

- **Previous path:** `app/KnittingGaugeReconciler.xcodeproj`
- **Current path:** `app/app.xcodeproj` (canonical reference)
- **App target & scheme:** `KnittingGaugeReconciler` (unchanged)
- **Build script:** `app/build.sh` updated and validated

Any references to the old project path should be updated. Use `app/app.xcodeproj` going forward.

---

### 2026-05-19 — corrected canonical Xcode project path

Correction to earlier path note: the project bundle must remain `app/KnittingGaugeReconciler.xcodeproj` per the explicit Tesla scaffold priority item. UI work remains under `app/KnittingGaugeReconciler/`; scheme remains `KnittingGaugeReconciler`.

---

## [2026-05-20T02:21:23Z] Swatch Hint Layout Fix

**Session:** swatch-hint-layout (Edison + Curie)
**Decision:** Constrain `NumberField` hint copy to the compact numeric column width for non-accessibility Dynamic Type, while leaving it unconstrained at accessibility sizes.

**Work:** Fixed swatch hint text wrapping by constraining NumberField hints to column width at non-accessibility sizes. Preserves accessibility fallback. Simulator build passed. Curie verified with UI tests — both Pattern gauge and Your swatch remain side-by-side when they fit.

## [2026-05-20T03:31:51Z] Copy Results Menu Implementation

**Session:** copy-results-menu

**Task:** Implement Ive's Copy results menu UX spec.

**Deliverable:** Native SwiftUI `Menu` with deterministic formatters for TSV, Markdown, CSV, HTML. Removed old unavailable share-link affordance. Added formatter and UI test coverage.

**Validation:** Ive approved design; Curie tightened tests for old affordance removal and per-section guidance coverage. `./app/build.sh test` passed.

**Status:** Approved and ready for deployment.

## [2026-05-19T22:40:33-07:00] Major Mismatch Help Overlay

**Session:** major-mismatch-help-overlay
**Task:** Move verdictPanel explanatory body text behind a tappable `?` affordance.

**What changed:**
- `verdictPanel` now shows only the verdict title + a `?` (`questionmark.circle`) button. The inline `Text(verdictBody)` was removed from the card.
- Added `@State private var showVerdictHelp = false` and a `.sheet(isPresented:)` presentation attached to the NavigationStack.
- New `VerdictHelpSheet` private struct renders the title + explanation in a scrollable pull-up sheet with `.presentationDetents([.medium, .large])` and `.presentationDragIndicator(.visible)`.
- VoiceOver: the `?` button carries `accessibilityLabel("More information")` + hint; the title Text carries the existing `verdictAccessibilityLabel` summary. Sheet content is fully navigable.
- Added `testVerdictHelpButtonOpensPullUpSheet` UI test: asserts the help button exists, that `re-swatching` text is NOT in the main view, taps button, asserts sheet appears with the text.
- All 18 unit tests pass; app builds successfully.

**Decision:** Applied to all verdict states (not just "Major mismatch") for consistent UX — the card is always compact with title + `?`.

---

## ⚠️ [2026-05-20T06:25:04Z] Serial iOS UI Testing Constraint

**Directive:** When running locally, Squad must not run more than one iOS simulator at any given time. All UI tests must run in serial.

**Rationale:** Concurrent local simulator usage can conflict and destabilize UI test runs.

**Impact on Edison:** Build and test scenarios coordinated with other agents must respect single-simulator access during local UI test execution.

## [2026-05-19T23:27:48-07:00] About Calculator Help Overlay

**Session:** about-calculator-help-overlay
**Task:** Apply the same compact `?` pull-up overlay pattern to the "About this calculator" card.

**What changed:**
- `aboutCard` now shows only a compact title + `?` (`questionmark.circle`) button. The long explanatory paragraphs, scope warning block, and non-affiliation disclaimer were removed from the main card.
- Added `@State private var showAboutHelp = false` and a new `.sheet(isPresented: $showAboutHelp)` attached to the NavigationStack.
- New `AboutHelpSheet` private struct renders all the about content (two explanation paragraphs, amber scope warning block, footnote disclaimer) in a scrollable pull-up sheet with `accessibilityIdentifier("about-help-sheet")`.
- VoiceOver: the `?` button carries `accessibilityLabel("About this calculator, more information")` + hint; sheet is fully navigable with Dynamic Type.
- Added `testAboutHelpButtonOpensPullUpSheet` UI test: asserts button exists with correct label, that `two-axis gauge mismatch` text is NOT in the main view, taps button, asserts sheet appears with the text.
- Build passed (exit code 0). No unrelated files touched.

**Pattern generalised:** Both `verdictPanel` and `aboutCard` now follow the same compact title + `?` → sheet convention for reducing clutter in the main scroll view.

## [2026-05-19T23:53:43.824-07:00] About `?` Moved to App Title — About Card Removed

**Session:** about-help-title
**Task:** Remove the standalone "About this calculator" card; place the `?` button directly beside the app title in the `header`.

**What changed:**
- Removed `aboutCard` from `ContentView.body` and deleted the property entirely.
- Updated `header` to wrap the app title + `?` button in an `HStack`. The button still shows `showAboutHelp = true`, triggering the same `AboutHelpSheet` pull-up sheet.
- Title `Text` carries `.fixedSize(horizontal: false, vertical: true)` to prevent truncation on small screens when the button is adjacent.
- Updated `testAboutHelpButtonOpensPullUpSheet`: removed `scrollToElement` (button is now at the top, always visible), replaced `.exists` assertion with `waitForExistence(timeout: 3)` for launch-timing robustness.
- Build succeeded (no compile errors).

**Key learning:** When promoting a contextual help button from a card at an arbitrary scroll position to the title area, always verify Dynamic Type wrapping of the adjacent title — `fixedSize(horizontal: false, vertical: true)` prevents the title from being truncated by the button's minimum tap target (44 pt).

## [2026-05-19T23:53:43-07:00] Removed Privacy Card from About

**Session:** remove-about-privacy-copy
**Task:** Remove privacy/non-tracking card from the main scroll view — analytics are being added so the "no analytics" claim would become false.

**What changed:**
- Removed `privacyCard` reference from `ContentView.body` VStack.
- Deleted the `privacyCard` computed property (SectionTitle "Privacy" + "This app collects nothing…" text).
- Added negative UI assertion in `testAboutHelpButtonOpensPullUpSheet`: `XCTAssertFalse(app.otherElements["privacy-card"].exists)`.
- No replacement privacy/analytics copy added.

**Key learning:** When a truthfulness-limited piece of copy must be removed (not just hidden), delete both the view and its property; a negative assertion in an existing test is sufficient to guard against accidental re-introduction without making the test brittle.

## [2026-05-20T18:19:39-07:00] Metrics scope — SwiftUI view perspective (issue #9)

**Session:** swift-metrics-scope (parallel scoping with 7 other members)
**Deliverable:** `.squad/decisions/inbox/edison-metrics-scope.md`

### Learnings — UI hooks suitable for metrics

- `GaugeMath.compute` is invoked from one site in ContentView (the
  `result` computed property). That single line is the right wrap point
  for a duration timer + invocation counter while keeping §2.2's math
  boundary intact. Note: it fires on every `body` re-eval, not only on
  user edits — document the metric semantics accordingly.
- Input fields: nine `@State` text bindings. `.onChange(of:)` per field
  is the natural hook, but raw-keystroke events leak typing cadence and
  flood cardinality on the event axis. The right debounce is
  **parsed-value-change** (compare `read(text, default:)` Double output
  to prior), which collapses mistype-and-correct to net-zero.
- Sheet open events are best caught via `.onChange(of: <Bool flag>)`
  false→true rather than inside the button action, so launch-arg
  pre-opened sheets (used by UI tests) still count consistently. We
  don't track close events — iOS native dismiss has no clean callback
  through `.sheet(isPresented:)`.
- Share path: wrap the image-vs-text-fallback branch inside
  `shareResults()` with a `payload` label so we can see `ImageRenderer`
  failure rates without instrumenting the renderer itself.
- Verdict bucket: `verdictTitle`'s four-way switch (Gauge match / Drift /
  Significant drift / Major mismatch) already classifies the result —
  hook a counter on `.onChange(of: verdictTitle)` for transitions plus
  a gauge for current state. Extreme-input signal is free.
- Cast-on drift pill: same trick — `.onChange` on the `abs(drift) >= 3`
  predicate matches the existing UI threshold and gives a "rounding
  drift surfaced" counter without recomputing thresholds.
- Compact-vs-regular size class is **not** worth tracking on this
  iPhone-only target; it would be ~100% `.compact` and signal nothing.

### Accessibility-ID stability — non-negotiables

- The 2026-05-19 privacy-card deletion left `privacy-card` as a
  *negative* identifier asserted in `testAboutHelpButtonOpensPullUpSheet`.
  No instrumentation may resurrect a view with that ID or with any
  "Privacy"/"Analytics" copy.
- `testShareResultsIsSingleAccessibleAffordance` asserts no button label
  begins with `"Copy"` and no button has identifier `copy-results`,
  `copy-share-link`, `share-results-link`. Forbids any "Copy
  diagnostics" / "Export counters" UI — counter inspection goes through
  Xcode/`po`, never a visible button.
- `testAllJacquardScenariosAreVisibleInUI` depends on the literal hero
  percent strings and guidance copy. `.onChange` modifiers are safe
  (they don't change the accessibility tree); wrapping views with extra
  containers is not.
- Instrumentation must add zero new `accessibilityIdentifier` values.
  All metric hooks are pure `.onChange` / inline call-site closures
  with no view-tree footprint.

### Gating strategy recommendation

- **Double-gate every metric call site:** compile-time `#if DEBUG` (so
  release binaries are *physically* free of analytics surface area) AND
  runtime `ProcessInfo.processInfo.environment["KGR_METRICS_ENABLED"]
  == "1"` (so DEBUG runs — including Curie's UI test fleet — stay
  inert by default).
- The combined defence preserves the 2026-05-19 privacy-card-removal
  intent: a release build from the App Store contains zero
  instrumentation, even though we deleted the copy that used to claim
  this. We get the truthful posture without having to write a brittle
  claim again.
- In-memory counters only. No `UserDefaults`, no caches dir, no
  SwiftData table. No `URLSession`, no third-party SDK, no remote
  config (§2.3). No `print`/`os_log`/`Logger` in non-DEBUG branches
  (§2.12).
- If we ever want Instruments-grade timing, use `os_signpost` — also
  `#if DEBUG`-gated.

## [2026-05-20T00:00:00Z] Final Help Overlay UI Changes — Reviewed and Approved

**Session:** help-overlays (Help Overlay UI Finalization)
**Reviewer:** Curie (QA)
**Status:** APPROVED

**Summary:** Completed final help overlay UI changes as directed by yashasg:
1. **About `?` Help Overlay** — Applied compact title + `?` → pull-up sheet pattern to About card
2. **About `?` Repositioned** — Removed standalone About card; moved `?` button next to app title in header
3. **Privacy Card Removed** — Eliminated misleading "no analytics" copy; no replacement

**Verification by Curie:**
- Build successful (exit code 0)
- Accessibility verified: VoiceOver labels intact, Dynamic Type support preserved
- UI tests updated and passing
- Share/export functionality preserved
- Math and layout unchanged
- No misleading privacy claims

**Status:** Ready for deployment. All decisions documented in decisions.md.

## Team updates
- 2026-05-20T18:19:39-07:00: swift-metrics scoping round (issue #9) completed. 8-agent parallel pass. Decisions merged to decisions.md (now 98,243 bytes).
- 2026-05-20T18:50:53-07:00: MetricKit V3 scope completed (issue #9). Architecture pivot from swift-metrics to MetricKit. Deliverable: `.squad/decisions/inbox/edison-metrickit-scope.md`.

## [2026-05-20T18:50:53-07:00] MetricKit V3 Instrumentation Scope (issue #9)

**Session:** metrickit-v3-scope
**Deliverable:** `.squad/decisions/inbox/edison-metrickit-scope.md`

### Summary

- Architecture pivot: dropped `apple/swift-metrics`; MetricKit (`import MetricKit`) is the
  backend. Custom user-behavior events ride `MXSignpost(_:log:name:)`.
- `MetricsSubscriber`: new file `app/KnittingGaugeReconciler/MetricsSubscriber.swift`.
  `final class MetricsSubscriber: NSObject, MXMetricManagerSubscriber`. Payload handler
  uses option (b) — `#if DEBUG` console log only in V1; developer endpoint deferred to V2.
- Bootstrap: `KnittingGaugeReconcilerApp.init()` adds stored `let metricsSubscriber` and
  calls `MXMetricManager.shared.add(metricsSubscriber)`.
- Signpost roster trimmed to 11 names (10 confirmed; 1 pending Jacquard/Tesla call):
  `compute` (INTERVAL), `share.invoked`, `share.fallback`, `reset.tapped`, 4 verdict
  names, `sheet.verdictHelp.opened`, `sheet.aboutHelp.opened`, `cast_on.driftBandShown`.
- Gating decision: signpost calls unconditional in release (no-ops when user opted out);
  `#if DEBUG` only in `didReceive` console log. No app-level env gate needed.
- Accessibility ID invariance preserved; zero new identifiers; all three critical UI
  test contracts unchanged.
- Skill written: `.squad/skills/metrickit-subscriber-bootstrap/SKILL.md`.

### Key learnings V3 over V2

- `MXSignpost` has no dimension/metadata aggregation; `verdict.transition` with
  `from`/`to` dimensions collapses to 4 named COUNT signposts.
- MetricKit's iOS Settings opt-in gate removes the need for `KGR_METRICS_ENABLED`
  env var; app-level env gating would kill production signals from opted-in users.
- Signpost names must be static string literals; runtime interpolation is invisible
  to MetricKit's aggregation pipeline.
- `MetricsSubscriber` must be stored as a `let` property on the App struct —
  `MXMetricManager` holds a weak reference; without the stored property, the
  subscriber would be immediately deallocated.

## [2026-05-20T18:42:54-07:00] Metrics scope V2 — re-run (issue #9)

**Session:** swift-metrics-scope-v2 (independent V2 pass; model: claude-sonnet-4.6)
**Deliverable:** `.squad/decisions/inbox/edison-metrics-scope-v2.md`

### Learnings — V2 additions and corrections over V1

- **Compute metric semantics hazard:** `result` (line 36, ContentView.swift) fires on every SwiftUI `body` re-evaluation, not only on user edits. Label the counter `gauge.compute.invocations` and document as "re-evaluations" — not "user interactions". For user-intent signal, rely on the debounced `field.edit.debounced` events instead. Duration timer is only useful for regression detection (sub-ms CPU time), not UX latency.

- **Bootstrap site is explicit:** `KnittingGaugeReconcilerApp.init()` is the only safe location. The current app struct has no `init()` — adding one is required. Bootstrap before any `body`/`Scene` evaluates. `@main` singleton guarantees single-call; no additional idempotency guard needed.

- **Reset tapped is its own event:** `resetToDefaults()` writes all nine `@State` fields atomically. Using `.onChange` debounce for reset would emit nine `field.edit.debounced` events for one user action, double-counting intent. Hook the counter directly in the `resetToDefaults()` function body inside `#if DEBUG`.

- **Disclosure toggle needs `expanded` dimension:** `disclosure.full_math.toggle` with `expanded: Bool` dimension is the right shape — open/close rate is calculable as a ratio from one event type rather than two.

- **Final event list:** 12 events across 9 trigger sites. All `.onChange`/action-closure hooks; zero new `accessibilityIdentifier` values; zero view-tree footprint.

## [2026-05-20T19:26:30-07:00] MetricKit V1 Implementation (issue #9)

**Session:** metrickit-v1-implementation
**Files created:** `MetricsSubscriber.swift`, `GaugeMathMetrics.swift`
**Files modified:** `KnittingGaugeReconcilerApp.swift`, `ContentView.swift`, `MetricKitSubscriberTests.swift` (AC-6 guard), `app.xcodeproj`

### Key learnings

- **`os_signpost` not `MXSignpost`:** `MXSignpost` does not resolve in Swift 6 with `import MetricKit` (compiler error: "cannot find 'MXSignpost' in scope"). The correct API is `os_signpost` from `import os.signpost`. MetricKit aggregates `os_signpost` events on a `MXMetricManager.makeLogHandle(category:)` OSLog handle identically.

- **Protocol minimal surface:** `MetricPayloadProtocol` must NOT include `jsonRepresentation()` — Curie's `MockMetricPayload` has only `timeStampBegin`/`timeStampEnd`. JSON logging uses the concrete `MXMetricPayload` in `didReceive` before bridging to `receive()`.

- **GaugeMathMetrics OSLog handle:** `MXMetricManager.makeLogHandle(category: "user_actions")` is the correct log handle for MetricKit aggregation. A plain `OSLog(subsystem:category:)` will NOT route through MetricKit's pipeline.

- **Verdict-improved/degraded via `.onChange(of: verdictTitle)`:** The per-session `@State private var previousVerdictBucket: VerdictBucket?` lives in ContentView; updated in the `.onChange` callback. `GaugeMathMetrics.classifyVerdictDelta(previous:current:)` returns nil for first compute (nil previous) and for equal buckets — no spurious signposts.

- **Cast-on drift band guard:** `@State private var driftBandSignpostFired = false` prevents re-firing on re-renders. Set to `true` when band becomes visible; cleared when it goes away. `.onChange(of: abs(result.castOnRoundingDriftPercent) >= 3)` is the observation hook.

- **AC-6 otool on iOS:** `Process` is macOS-only. Added `#if os(macOS) || targetEnvironment(macCatalyst)` guard; iOS fallback uses `dlopen("/System/Library/Frameworks/MetricKit.framework/MetricKit", RTLD_LAZY | RTLD_NOLOAD)` to verify MetricKit is loaded in process.

- **Build result:** `./app/build.sh` exit code 0. All 42 tests passed (18 GaugeMathTests + 24 new MetricKit tests from Curie). GaugeMath.swift confirmed zero MetricKit/signpost references by AC-3 file-scan.

### Signpost roster — as shipped (9 names)

| Name | Type | ContentView.swift line |
|------|------|------------------------|
| `compute` | INTERVAL | 40, 42 |
| `sheet.verdictHelp.opened` | EVENT | 90 |
| `sheet.aboutHelp.opened` | EVENT | 95 |
| `verdict.improved` | EVENT | 106 |
| `verdict.degraded` | EVENT | 108 |
| `cast_on.driftBandShown` | EVENT | 115 |
| `reset.tapped` | EVENT | 417 |
| `share.invoked` | EVENT | 433 |
| `share.fallback` | EVENT | 436 |


---

## [2026-05-20T20:38:28-07:00] Codebase Cleanup Audit (analysis-only pass)

**Session:** cleanup-audit
**Deliverable:** `.squad/decisions/inbox/edison-cleanup-audit.md`
**Scope:** All production `.swift`, tests, build.sh — read-only pass, zero code changes

### Summary

13 findings (DEDUPE: 4, REMOVE: 2, CLEANUP: 7) + 2 deferred items. Full audit in inbox.

### Key learnings from this pass

- **`result` computed property is a signpost trap.** In my MetricKit V1 implementation, I put `os_signpost(.begin/.end)` inside the `result` computed property. Because `result` is accessed ~15–20 times per body evaluation (directly + through `verdictTitle`, `verdictBody`, `verdictAccessibilityLabel`, `fullMathBreakdown`), MetricKit receives 15–20 `compute` interval samples per user keystroke instead of 1. The `compute` interval distribution in App Store Connect Analytics will be ~15–20× inflated until this is fixed. **Rule: never put signpost instrumentation inside a computed property that is accessed multiple times per render cycle. Use `.task`, `.onChange(of:)`, or a captured `let` at the top of `body` instead.**

- **Deduplication across same-module files is easy to miss when both copies are `private`.** `gaugeStatus()` and `rowStatus()` both live in `GaugeMath.swift` and `ContentView.swift` as `private` free functions. Because they're `private`, the compiler doesn't complain. The fix is simply dropping `private` on the GaugeMath.swift definitions — same module, zero imports needed in ContentView. Lesson: scan for `private func` in multiple files when the function is domain-logic (not view-specific).

- **Identical method + free function at different scopes is a stealth dedup.** `HeroMetric.pillBackground(status:)` (instance method) and `sharePillBackground(_ status:)` (free function) are identical but one is scoped to a struct and the other is file-scope. They'll never conflict or warn. Only a manual audit catches them. Lesson: when writing a free function helper for a share/export component, always check whether the same color/style logic already exists inside a sibling view struct.

- **String coupling via `init(verdictTitle:)` is a latent bug.** `VerdictBucket.init(verdictTitle: String)` silently maps unknown strings to `.majorMismatch` (via `default:`). This means any typo in the display string or a rename of a verdict label would cause the verdict comparator to always emit `.majorMismatch` without any compiler or runtime error. Future work: flip the derivation direction — compute `VerdictBucket` first, derive `verdictTitle` from it.

- **`AppTheme` discipline breaks down in sheets.** The `AboutHelpSheet` scope warning callout box uses three inline `Color(red:green:blue:)` literals that aren't in `AppTheme`. Every other color goes through `AppTheme`. When adding callout/warning styling, always reach for named theme constants even if they're new additions.

- **`scrollToTop(in:)` is a UI test helper that survived a refactor it wasn't needed for.** The single-launch UI test rewrite (issue #18) eliminated the multiple per-scenario relaunches that originally needed scroll-to-top reset. The method stayed behind. Lesson: when refactoring a test flow, grep for helpers that only existed to support the removed pattern.

