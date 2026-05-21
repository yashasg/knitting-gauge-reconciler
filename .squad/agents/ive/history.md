# Ive — History

## Core Context

- **Owner:** yashasg
- **Project:** A knitting gauge reconciler that converts patterns between stitch/row gauges.
- **Role:** UI/UX Designer (Apple HIG, accessibility)
- **Joined:** 2026-05-19T07:14:05Z

## Learnings

<!-- Append learnings below -->
- 2026-05-19 (Compact Fields): Numeric field layout spec delivered with width guidance (92–156 pt range), accessibility Dynamic Type fallback, and focus order. Paired fields use 140 pt minimum columns. Decision merged to decisions.md.
- 2026-05-19: Lead with action before ratios — cast-on + verdict become the first read, percentages secondary.
- Palette tightened to 8 semantic tokens with AAA text on verdict surfaces and color never acting alone.
- Flow stays single-screen: inputs → cast-on → live verdict → expandable detail/about, with URL hash as the persistence side note.

### 2026-05-19 — Design Direction Audit

Delivered `.squad/decisions/inbox/ive-design-direction.md` with audit + direction. Key learnings: verdict block needs high-contrast inversion (`--verdict-bg: #1E1628`) to dominate post-compute; fixed `px` typography breaks Dynamic Type and must migrate to `rem`/`clamp()`; color-only pills violate a11y for deuteranopia — always pair with visible axis label. Open questions for Tesla/Jacquard on CSS custom property inheritance and whether to surface cast-on in Mismatch state.

### 2026-05-19 — Cast-On UX Spec

The prototype uses a well-structured design token vocabulary: `--bg`, `--card`, `--ink`, `--muted`, `--line`, `--accent`, `--accent-soft` for surfaces and text; `--good`, `--warn`, `--alert` for semantic status; `--mono` and `--sans` for typography. Pills use a shared `.pill` class with modifier classes (`pill-good`, `pill-warn`, `pill-alert`, `pill-neutral`) that map directly to the semantic colors. The `.section-row` component is the core input/output pattern — three-column grid with `.name`, `.pattern` (label + input), and `.actual` (computed value). I extended this pattern for the cast-on stitch count rather than creating a new component, maintaining visual consistency and predictable focus order. For accessibility, I specified `aria-describedby` linking the hint text to the input, ensured the new field lands at the end of the tab sequence (after increase-row spacing), and chose inline pill feedback over modals to avoid interrupting screen reader flow. The existing color contrast meets AA for pill text; no new colors needed.

### 2026-05-19 — Round 3: Design Direction + Excalidraw (5 iterations)

**Round 3 outcome:** 5 spawns, 1 failure (ive-1 opus wandering), 1 backup overlap kill (ive-3), 2 iteration refinements (ive-4 portrait reshape, ive-5 Principle 1 lock-in), 1 final delivery (ive-5). Total: Delivered design doc + Excalidraw portrait flow aligned to binding user directive "one screen, one press."

**Key deliverables:** Design doc elevated Principle 1 "One screen, one press" as TOP constraint (overrides design choices). 4 binding principles: Number First, Verdict Dominance, Text Before Color. Hero layout (single iPhone portrait, all inputs stacked, one Calculate button, verdict inline). Accessibility floor: 44pt targets, Dynamic Type scaling, semantic VoiceOver, text labels on every color pill. Excalidraw: 969×1494 portrait, 42 elements, 4 verdict state variants shown as "within same region" via dashed connectors (not separate screens).

**Iteration notes:** Opus (ive-1) over-analyzed; Sonnet respawn (ive-2) converged but produced desktop-aspect Excalidraw; ive-4 reshaped to portrait but verdict card layout created false wizard impression (fanned right); ive-5 baked Principle 1 into design doc (moved to top) and Excalidraw layout (vertical stacking, no fanning). Design now fully compliant with user directive.

**Open questions unresolved:** CSS custom property fallback for verdict slab dark mode; whether to surface adjusted cast-on in Mismatch branch (design asks; Mendel/Jacquard input needed).

### 2026-05-19 — iOS SwiftUI Review & Sign-Off

**Task:** Review SwiftUI screens against prototype/index.html for structure, labels, flow, accessibility.

**Findings & Fixes:**

1. **Verdict State Machine Bug** — iOS used OR logic for drift thresholds (either >= 15% = mismatch), but decisions.md specifies 4 distinct branches:
   - Perfect Match: Both < 3%
   - Minor Drift: ONE axis off (3-15%)
   - Significant Drift: BOTH axes off (3-15%)
   - Major Mismatch: Either >= 15%
   
   Fixed `verdictTitle` to check `stitchOffRange && rowOffRange` for dual-axis detection.

2. **Pill Styling Contrast** — HeroMetric pills used `opacity(0.18)` and `opacity(0.22)` backgrounds, too faint for sufficient contrast. Changed to solid colors with white text (matching prototype #5E8B6B green, #C68B2C amber) and added `pillBackground()` helper function.

3. **Verdict Copy Refinement** — Updated `verdictBody` to align with prototype's concise tone and axis-specific messaging (e.g., "Row gauge is off" vs generic "One axis is off").

**Verification:**
- All 77 prototype test scenarios pass ✅
- Math logic matches prototype exactly (stitch scale, row scale, dimension scale, cast-on rounding)
- Single-screen layout adheres to "One screen, one press" binding directive
- All inputs ≥44pt touch targets
- Verdict card dominates post-compute with high-contrast inverted background
- Pills have text labels (no color-only signals) + solid semantic colors
- VoiceOver labels semantic and comprehensive

**Status:** SIGNED OFF — iOS app structure, labels, flow, and accessibility expectations closely match prototype. No additional changes needed.

### 2026-05-19 — Final UI/UX Approval Review

**Task:** Confirm SwiftUI implementation meets prototype against four inputs, live recalc, hero percentages, results table, accessibility, Dynamic Type, and crash-prone patterns.

**Verification Completed:**
- ✅ Four gauge inputs (pattern stitch/row, your stitch/row) with proper labels, units, hints
- ✅ Live recalc: `@State` → `inputs` → `GaugeMath.compute()` reactive chain
- ✅ Hero percentages displayed with semantic text-based status pills (Match, Denser/Looser/Much*); no color-only signals
- ✅ Results table: `AdjustmentRow` renders yoke, body, sleeve, increases, cast-on with pattern/adjusted values; responsive layout collapses on compact width + accessibility text sizes
- ✅ Accessibility: Semantic labels throughout (inputs with spoken units, verdict panel combined, buttons ≥44pt); all section titles marked as headers; adjustment rows auto-identified for test automation
- ✅ Dynamic Type: `AdaptiveTwoColumnStack` and `AdjustmentRow` both guard on `dynamicTypeSize.isAccessibilitySize`; all text semantic font sizes (no hardcoded `px`); hero value has `minimumScaleFactor(0.7)` for large text
- ✅ No crash patterns: Zero force unwraps, safe Optional handling, `GaugeMath.sanitized()` guards input

**No UX Blockers Found.** All verification complete.

**Approval:** iOS UI/UX **APPROVED** against prototype. Implementation matches HIG, a11y floor, and "one screen, one press" principle. Delivered `.squad/decisions/inbox/ive-ui-approval.md` for team record.


## [2026-05-19 19:13:04Z] Canonical Xcode Project Path Update

⚠️ **All squad members:** The Xcode project has been renamed to **`app/app.xcodeproj`**. 

- **Previous path:** `app/KnittingGaugeReconciler.xcodeproj`
- **Current path:** `app/app.xcodeproj` (canonical reference)
- **App target & scheme:** `KnittingGaugeReconciler` (unchanged)
- **Build script:** `app/build.sh` updated and validated

Any references to the old project path should be updated. Use `app/app.xcodeproj` going forward.

---

### 2026-05-19 — corrected canonical Xcode project path

Correction to earlier path note: the project bundle must remain `app/KnittingGaugeReconciler.xcodeproj` per the explicit Tesla scaffold priority item. UX review remains against the SwiftUI app in that project; scheme remains `KnittingGaugeReconciler`.

## [2026-05-20T03:31:51Z] Copy Results Menu UX Specification

**Session:** copy-results-menu

**Task:** Define UX specification for replacing the old share-link affordance with a native Copy results menu.

**Deliverable:** UX spec for native `Menu` labeled "Copy results" with TSV, Markdown, CSV, and HTML format options; accessible labels and copied-status feedback; no share/link/URL wording.

**Status:** Approved and implemented by Edison; validated by Curie.

## [2026-05-20T18:19:39-07:00] swift-metrics UX scope (issue #9)

**Session:** swift-metrics-scope (parallel scoping with 7 other members)

**Task:** Scope whether any user-visible UX surface should exist for the
swift-metrics capture work in issue #9.

**Recommendation:** **NONE.** No user-visible metrics surface in v1. No new
disclosure copy. Edison's 2026-05-19 privacy-card removal stays; do not add
replacement copy in this ticket.

**Why (UX rationale):**
- Single-screen, 30-second calculator. Every new surface competes with the
  hero numbers and verdict card. A stats/session counter delivers nothing the
  user came for and reads as surveilling on a local-first app.
- Math layer sanitises invalid input silently (`GaugeMath.sanitized()`).
  There is no current failure state worth a toast. Adding one purely to fire
  a metric event would interrupt the live recalc path that April's issue #1
  mitigation #3 protected.
- Debug-only `#if DEBUG`-gated counters are fine **only** if they never ship
  release, carry no `accessibilityIdentifier` / `accessibilityLabel`, and
  are reachable only via a hidden gesture. The moment a metric surfaces in a
  release build with any a11y handle, it re-enters my review.
- Silence in the UI is honest while nothing is recorded or uploaded. Hedged
  disclosure copy ("we may capture local metrics…") would re-create exactly
  the trust-erosion problem that triggered the privacy-card removal.

**Constraint compliance verified:**
- No conflict with issue #1 (no network egress, no analytics upload).
- Verbatim non-affiliation line ("Not affiliated with Ravelry, Knit
  Companion, or any pattern designer…") in `AboutHelpSheet` untouched.
- Donatello's scope-boundary line untouched.
- 30-second first-use path preserved — no Calculate button, no modal,
  no toast.
- Edison's privacy-card removal reinforced.

**Open guardrail for future tickets:** Any proposal to surface a metric as
user-visible UI (extreme-input toast, session counter, recompute hint) is a
fresh UX request, not a metrics-implementation detail. Route it through
`.squad/decisions/inbox/` with me on the loop.

**Deliverable:** `.squad/decisions/inbox/ive-metrics-scope.md`.

## Team updates
- 2026-05-20T18:19:39-07:00: swift-metrics scoping round (issue #9) completed. 8-agent parallel pass. Decisions merged to decisions.md (now 98,243 bytes).

## [2026-05-20T18:42:54-07:00] swift-metrics UX scope V2 (issue #9)

**Session:** swift-metrics-scope-v2 (independent re-run, claude-sonnet-4.6)

**Task:** Independent V2 re-pass on swift-metrics UX scope. Confirm or push back on V1 "NONE" recommendation.

**V2 verdict:** **RATIFY V1. NONE confirmed.** No user-visible metrics surface. No new disclosure copy. No chrome.

**V2 additions over V1 (precision, not corrections):**
- Explicit negative-assertion identifier contract table (privacy-card, analytics, telemetry, metrics in release)
- Debug overlay containment rule: `.overlay`/`.safeAreaInset` under `#if DEBUG`; must not be a first-class VStack member or alter layout metrics for surrounding production views
- Full opt-in UX ruleset for future proposals: native Toggle, Diagnostics section only, default OFF, UserDefaults persistence key documented, full a11y spec
- Confirmed `share-results` identifier and label must not be renamed if metrics are wired to share call site

**Deliverable:** `.squad/decisions/inbox/ive-metrics-scope-v2.md`
---

## 2026-05-20T19:26:30Z — MetricKit V1 shipped (Team session)

MetricKit V1 implementation completed. User directives: (1) MetricKit pivot from swift-metrics (2026-05-20T18:50:53), (2) privacy card stays removed (2026-05-20T19:22:50), (3) 9-signpost roster locked (2026-05-20T19:26:30). Build: 49/49 tests pass (was 25). Session log: .squad/log/2026-05-20T19-26-30Z-metrickit-pivot-shipped.md. Orchestration logs: .squad/orchestration-log/2026-05-21T02-26-30Z-{agent-round}.md.
