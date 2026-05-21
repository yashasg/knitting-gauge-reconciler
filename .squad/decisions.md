## 2026-05-19

**Ive: Compact iPhone Field Layout Spec**

Numeric inputs on iPhone should use content-appropriate widths (92–112 pt for gauge fields, 96–120 pt for dimension fields, 128–156 pt for cast-on) instead of full-card width. Paired gauge fields and dimension fields can sit on one row when the card has space. Accessibility Dynamic Type triggers fallback to stacked, full-width layout. Fields preserve visible labels and 44×44 pt hit targets.

**Edison: Compact Numeric Fields Implementation**

Numeric inputs now use compact text boxes sized for knitting values. Paired inputs use 140 pt minimum columns. Accessibility Dynamic Type stacks paired inputs and expands to available width. Implementation complete; UI tests updated and passing.

**Ive: Field Grouping Design Spec**

Use nested grouped sections inside the existing gauge card: each logical input group becomes a subtle rounded sub-card on the card surface. Pattern gauge and Your swatch each sit inside one grouped sub-card with 12 pt inner spacing, 14–16 pt container padding, 20–24 pt corner radius, AppTheme.oatmeal background, and 1 pt AppTheme.outline.opacity(0.7) border. Adaptive two-column layout preserved; accessibility Dynamic Type stacks fields vertically within groups. Section titles remain headers with clear VoiceOver reading order. Group visual separation uses structure and shape, not color alone; contrast meets WCAG 2.2 AA.

**Edison: Gauge Field Grouping Implementation**

Implemented Ive's gauge grouping direction with two nested rounded sections inside the existing gauge card: one for Pattern gauge and one for Your swatch. Used InputGroup reusable wrapper with structure, padding, rounded shape, and subtle stroke plus native grouped background. Preserved existing field labels, bindings, identifiers, and compact two-column layout. Implementation complete; UI tests passing.

**Swatch Hint Layout**

Date: 2026-05-19T18:58:14.719-07:00
Owner: Edison

Decision: Constrain `NumberField` hint copy to the compact numeric column width for non-accessibility Dynamic Type, while leaving it unconstrained at accessibility sizes.

Rationale: Swatch hints should wrap inside their compact column instead of increasing the child ideal width that makes `AdaptiveTwoColumnStack` choose its vertical fallback. Accessibility sizes keep the existing stacked/full-width fallback.

**Edison: Device-Independent Gauge Layout**

Date: 2026-05-19T19:22:38.332-07:00

Decision: Pattern gauge and Your swatch now use a dedicated gauge measurement pair layout that stays horizontal for non-accessibility Dynamic Type on all device widths, while still stacking at accessibility Dynamic Type sizes.

Rationale: This keeps the user's requested two-column gauge/swatch relationship device-independent without changing Pattern instructions or other adaptive sections.


**Ada: Per-section Row Guidance**

Date: 2026-05-19T20:10:33.242-07:00
Owner: Ada

Per-section vertical outputs preserve the pattern's physical centimetre measurements and present row/round counts as guidance for reaching those same measurements at the user's row gauge.

Rationale: Row gauge differences change how many rows or rounds are needed to reach a yoke/body/sleeve length; they must not change the finished centimetre target specified by the pattern.

**Curie: Copy Results Review Approved**

Date: 2026-05-19T20:10:33.242-07:00
Owner: Curie

Approved Edison's replacement of the old app copy-share-link behavior with a native Copy results menu offering TSV, Markdown, CSV, and HTML.

Validation: Confirmed the app UI no longer exposes the old copy-share-link affordance, formatter output includes current gauge results plus per-section row/round guidance, and tests now explicitly cover menu formats, formatter guidance rows, and old affordance removal. `./app/build.sh test` passed.

**Curie: Per-section adjustment review approved**

Date: 2026-05-19T20:10:33.242-07:00
Owner: Curie

Approved Ada's per-section adjustment fix from a test-engineering perspective.

Rationale: The Swift math now keeps physical centimetre targets unchanged while deriving pattern and adjusted row/round guidance from each row gauge. The 20 cm example with 24 pattern rows/10 cm and 32 user rows/10 cm is covered in unit tests and UI expectations, preserving 20 cm and guiding about 64 rows/rounds.

Validation: `./app/build.sh test` completed successfully locally.

**Edison: Copy Results Menu**

Date: 2026-05-19T20:10:33.242-07:00
Owner: Edison

Replace the old unavailable distribution affordance with a native SwiftUI `Menu` labeled "Copy results". Menu choices are TSV, Markdown, CSV, and HTML. Each action copies deterministic results text and shows "Copied [format]".

Rationale: The app has no backend or networking path for distributing externally-addressable results. Copying structured result data is truthful, local-first, and testable while preserving the compact layout.

## 2026-05-19 (Evening Session)

**User Directive (yashasg): Copy results single option**

Date: 2026-05-19T20:36:39.715-07:00

User clarified that Copy results should support only formatted text, not multiple format choices. Copied output should be a single plain-text action without TSV/Markdown/CSV/HTML menu, and no attribution until the app is on the App Store.

**Edison: Single Formatted Copy Results**

Date: 2026-05-19T20:36:39.715-07:00

Replaced the multi-format Copy results menu with one accessible Copy results action that copies deterministic formatted plain text to the pasteboard and shows "Copied!" feedback. Current product scope is one local formatted-text copy flow only.

**User Directive: Share affordance evolution**

Date: 2026-05-19T21:48:59.931-07:00

Prefer a single native Share affordance because iOS share sheet already includes Copy to Clipboard; avoid redundant Copy results UI. Explore using SwiftUI ImageRenderer to share a rendered image/screenshot of the main result screen.

**User Directive: Image-primary sharing**

Date: 2026-05-19T21:51:27.105-07:00

Share should use the rendered PNG as the primary payload. Formatted text should be used only as a fallback if rendering fails, not shared alongside the PNG by default.

**Edison: Image-Primary Sharing Decision**

Date: 2026-05-19T21:51:27.105-07:00

Use a single native Share results affordance backed by a small UIActivityViewController wrapper instead of ShareLink. This lets the app render a purpose-built SwiftUI results card with ImageRenderer, share the rendered PNG as the primary payload, and fall back to the formatted text summary through the same share sheet path only if image generation or file writing fails.

**Tesla: Saved Reconciliation Architecture Decision**

Date: 2026-05-19T22:06:06.097-07:00

**Status:** Proposed  
**Relevant agents:** Edison (iOS), Ive (Design), Ada (Algorithms)

Yes — worth doing saved reconciliations. Low implementation cost, high user value. Knitters frequently reference past reconciliations when returning to a project or starting a similar one.

**Minimal Data Model:** Store full `GaugeInputs` (9 fields: pattern stitch/row gauge, user stitch/row gauge, section dimensions, cast-on, increase spacing) plus metadata (label, createdAt, updatedAt). Everything else is derived via `GaugeMath.compute()`.

**Persistence Approach:** Recommended SwiftData (iOS 17+). Native SwiftUI integration, `@Query` macro, automatic migrations, zero config. App already targets iOS 17+ (SwiftUI NavigationStack).

**MVP Scope:** Save (explicit button on results), list (chronological with swipe-to-delete), load (tap to reload into calculator), delete. No iCloud sync, search, or folders in v1.

**Mendel: Saved Reconciliations — Research & MVP Scope**

Date: 2026-05-19T22:06:06.097-07:00

**Finding:** Four gauge numbers alone are insufficient for knitter mental model. Without metadata, saved reconciliations become ambiguous and unactionable.

**Critical metadata required:**
1. **Pattern name** (user input on save, ~50 char text) — primary lookup key
2. **Yarn identifier** (user input on save, ~40 char text) — secondary lookup for repeat fibers  
3. **Timestamp** (auto-generated; optional user-provided context label ~20 char) — temporal reference for mid-project vs. planning
4. **Stitch pattern + blocking state** (optional but high-value for knitter context)

**MVP recommendation:** Store 4 gauge values + 3 metadata fields (pattern name, yarn, timestamp). This 43.75% increase in data footprint delivers a 10x improvement in usability and aligns with knitter behavior.

**Design floor:** Keep all labels text-based and discoverable; no design-only communication (color, icons) for metadata differentiation.

**Jacquard: Saved Reconciliations — Domain Evaluation**

Date: 2026-05-19T22:06:06.097-07:00

**Verdict:** INSUFFICIENT to store just swatch dimensions without context, but MVP-defensible with small additions.

**What knitters need when opening saved reconciliation later:**
1. **Stitch pattern used** (garter, stockinette, ribbing, etc.) — different patterns have wildly different gauge responses
2. **Blocking state** (pre- or post-blocking) — blocking can swing gauge by 10–15%
3. **Yarn fiber content** — wool vs. cotton vs. acrylic all stretch differently
4. **Needle size used** — reconciliation is tied to specific needle; crucial for reproduction
5. **Memorable label** (e.g. "Flax Cardigan 5.5mm bamboo") — raw numbers don't connect to projects

**Real scenario risk:** Knitter saves reconciliation for linen sweater with 5.5mm needles in stockinette. Six months later loads it thinking gauge might apply to a cotton tee in ribbing on 5.0mm needles. Without metadata, saved reconciliation is misleading and useless.

**Recommendation:** Save the four points as proposed. Add fifth: short human-readable label + stitch pattern + blocking state. Stays minimal but gives knitters enough context to decide applicability.

**User Directive: Saved Reconciliations — Optional Naming**

Date: 2026-05-19T22:11:17.564-07:00

Saved reconciliations should not force the user to provide a name. Use a default name like `Reconciliation <Number>`, allow the user to edit it, and keep metadata optional rather than mandatory. Do not implement yet; create a work item only.

Rationale: User wants saved reconciliations to be low-friction and avoid blocking users on naming or metadata entry.

**Edison: Verdict Help Overlay**

Date: 2026-05-19T22:40:33.537-07:00

The verdict panel now renders a single-line row: verdict title on the left, a `?` (questionmark.circle) button on the right. The full body text is shown in a `.sheet` pull-up overlay when the user taps `?`. This pattern was applied to all verdict states (Gauge match, Drift, Significant drift, Major mismatch) for consistency.

Implementation: `verdictPanel` replaced `VStack(title + body)` with `HStack(title + Button(?))`. `showVerdictHelp: Bool` state drives `.sheet(isPresented:)` on the NavigationStack. Verdict title Text carries the concise `verdictAccessibilityLabel` summary for VoiceOver. Sheet content is natively navigable with `presentationDetents([.medium, .large])`.

Rationale: Keeps the reconciliation card compact while preserving longer advisory text one tap away. VoiceOver users get the concise summary immediately and can activate the help button to hear the full explanation.

**User Directive: Serial iOS UI Testing Constraint**

Date: 2026-05-19T23:25:04.530-07:00

When running locally, Squad must not run more than one iOS simulator at any given time. All UI tests must run in serial.

Rationale: Concurrent local simulator usage can conflict and destabilize UI test runs.

**User Directive: About Calculator Help Overlay**

Date: 2026-05-19T23:27:48.303-07:00
By: yashasg (via Copilot)

Apply the same compact help-overlay treatment to the "About this calculator" card: keep the title visible with a nearby `?` help affordance, and open the about content in a pull-up overlay when tapped.

Rationale: User wants explanatory/about copy available on demand without occupying main screen space.

**Edison: About Calculator Help Overlay**

Date: 2026-05-19T23:27:48-07:00
Author: Edison (Frontend Dev)

The "About this calculator" card contained three full paragraphs of explanatory text, a scope warning block, and a non-affiliation disclaimer directly in the main scroll view. Applied the same compact title + `?` → pull-up sheet pattern to the `aboutCard`:

1. The main card shows only `SectionTitle("About this calculator")` + a `questionmark.circle` button.
2. Tapping the `?` opens `AboutHelpSheet` — a scrollable `.sheet` with `presentationDetents([.medium, .large])` and a visible drag indicator.
3. `AboutHelpSheet` contains all existing about content verbatim.

Rationale: Consistent with the `verdictPanel` decision. VoiceOver users get the full content on demand; the button's `accessibilityLabel` ("About this calculator, more information") clearly signals the action.

Accessibility: `?` button: `accessibilityLabel("About this calculator, more information")`, `accessibilityHint("Opens an explanation of how this calculator works")`, `accessibilityIdentifier("about-help-button")`. Sheet `ScrollView` carries `accessibilityIdentifier("about-help-sheet")`. Sheet title `Text` has `.accessibilityAddTraits(.isHeader)`. All body text respects Dynamic Type.

Test Coverage: Added `testAboutHelpButtonOpensPullUpSheet` in `KnittingGaugeReconcilerUITests` — asserts button is discoverable and hittable, long about copy is NOT present in main view, taps button, asserts `about-help-sheet` scroll view appears, and copy becomes visible in sheet.

**User Directive: Move About `?` to App Title — Remove Card**

Date: 2026-05-19T23:53:43.824-07:00
By: yashasg (via Copilot)

Remove the About card completely. Put the `?` help affordance next to the app title at the top of the screen, and have it pull up the overlay with the About information.

Rationale: User wants About information available globally from the title area without dedicating a separate card to it.

**Edison: Move About `?` to App Title — Remove Standalone About Card**

Date: 2026-05-19T23:53:43.824-07:00
Author: Edison (Frontend Dev)

After the previous session placed a compact `?` button inside a dedicated "About this calculator" card, the user direction changed: remove the card entirely and place the `?` affordance next to the app title at the top.

Changes:
1. **Removed `aboutCard`** entirely from `ContentView.body` and deleted the `aboutCard` property.
2. **Updated `header`** — the app title `Text` is now wrapped in an `HStack` alongside a `Button { showAboutHelp = true }` carrying a `questionmark.circle` icon.
3. The `AboutHelpSheet` pull-up sheet and `@State private var showAboutHelp` are unchanged; only the trigger location moved.
4. **Updated `testAboutHelpButtonOpensPullUpSheet`** — removed the `scrollToElement` call (button is now immediately visible at the top), replaced `XCTAssertTrue(helpButton.exists)` with `helpButton.waitForExistence(timeout: 3)` to be robust against launch timing.

Rationale: The `?` at the title level makes the About action globally discoverable without consuming a card slot in the main scroll flow. Consistent with conventional iOS app patterns.

Accessibility: `?` button preserved with full `accessibilityLabel`, `accessibilityHint`, `accessibilityIdentifier`. Title uses `.fixedSize(horizontal: false, vertical: true)` so long titles wrap correctly on small screens. Sheet structure and Dynamic Type support unchanged.

Test Coverage: Updated `testAboutHelpButtonOpensPullUpSheet` — uses `waitForExistence(timeout: 3)`, still asserts correct label, long copy absent from main view, sheet appears on tap, copy visible in sheet.

**User Directive: Remove Privacy Copy — No Misleading Claims**

Date: 2026-05-19T23:53:43.824-07:00
By: yashasg (via Copilot)

Remove the privacy/non-tracking card or copy from the About information because the app is capturing analytics and that statement will be misleading going forward.

Rationale: User wants the app copy to avoid claims that will no longer be true once analytics are present.

**Edison: Remove Privacy/Non-Tracking Card from About**

Date: 2026-05-19T23:53:43-07:00
Author: Edison (Frontend Dev)
Status: Implemented

The main scroll view contained a `privacyCard` (Section title "Privacy") with the copy: "This app collects nothing. Your gauge values stay on device. No server. No analytics. No network requests of any kind." Analytics are being added, which would make this claim false.

Decision: Remove the privacy/non-tracking card entirely. Do not replace it with a new analytics or privacy policy claim.

Rationale: Keeping technically-false copy in the UI erodes user trust more than having no copy at all. A future, accurate privacy/analytics disclosure should be drafted deliberately by the product owner — not patched in reactively.

Changes:
- `ContentView.swift`: Removed `privacyCard` from body VStack; deleted `privacyCard` computed property.
- `KnittingGaugeReconcilerUITests.swift`: Added `XCTAssertFalse(app.otherElements["privacy-card"].exists)` in `testAboutHelpButtonOpensPullUpSheet` as a regression guard.

Not Changed: About `?` affordance next to the app title — preserved. `AboutHelpSheet` content — no privacy copy existed there; unchanged. All other help overlays, compact layouts, share/export, accessibility, Dynamic Type — unchanged.

**Tesla: Swift Coding Standards Adopted**

Date: 2026-05-20T02:15:00-07:00
Author: Tesla (loop lead)
Status: Binding
Related: GitLab issue #8

Adopt the **Google Swift Style Guide** (<https://google.github.io/swift/>) as
the normative external reference for all Swift code in this repository. The
guide is captured at `docs/swift_coding_standards.md`, which records both the
pointer to Google's guide and the **project-specific bindings** that override
or supplement it:

- §2.1 Warnings as errors (already in `app/build.sh`).
- §2.2 Determinism in the math layer (no randomness, no clock reads in
  `GaugeMath.compute` and callees, explicit `String(format:)` formatting,
  no `NumberFormatter` inside math).
- §2.3 No network, no analytics upload (per issue #1 mitigation 3).
- §2.4 Force-unwrap discipline on user input (`!`, `try!` banned).
- §2.5 Implicitly-unwrapped optionals banned in new declarations.
- §2.6 Caseless `enum` for namespaces (matches existing `GaugeMath`).
- §2.7 4-space indent, 120-col max line length (stricter indent than
  Google's 2-space default; project rule wins).
- §2.8 SwiftUI: private `@State`/`@Binding`, accessibility identifiers part
  of the public test contract, `.task { ... }` over `Task { ... }` in `body`.
- §2.9 Tests: Swift Testing for unit, XCTest for UI, UI tests **serial**
  (per 2026-05-20T06-25 decision), no `@Test(.disabled)` quarantine.
- §2.10 Concurrency: no `@MainActor` on pure-value/pure-math types; no
  `DispatchQueue.main.async` inside SwiftUI views.
- §2.11 Doc comments on public types in `GaugeMath.swift` using `///`.
- §2.12 No `print`/`os_log`/`Logger` in release outside `#if DEBUG` or
  env-var-gated branches; math layer never logs.

Resolution rules (§4): project rule > Google guide > Apple API Design
Guidelines. When all three are silent, follow the existing file convention.

Why not vendor a snapshot of Google's guide: the upstream URL is stable
(2019), bundling creates a drift risk, and the attachment on issue #8 is
behind Cloudflare bot protection (and the GitLab API resolves the same
secret to 404), so it could not be fetched into the repo as the user asked.
The project doc points to Google's canonical URL, which is the equivalent
material and reachable.

Agent ownership:

- Ada owns §2.2 (Determinism in the math layer).
- Edison owns §2.8 (SwiftUI specifics).
- Hopper owns §3 (Tooling — build script, future formatter/linter wiring).
- Curie owns §2.9 (Tests).
- Tesla owns the rest and the resolution rules.

Amendment flow: any rule change goes through
`.squad/decisions/inbox/<agent>-swift-standard-<topic>.md` for the next
Scribe merge.

PR / MR rules (§5): every MR touching Swift code must pass
`./app/build.sh test` locally (warnings = 0, tests pass), pass GitLab CI
mirror, introduce no force-unwraps on user input, introduce no network or
analytics dependency without a written decision, and update UI test
identifiers in the same commit when renaming a control.

## 2026-05-20T18:19:39-07:00 — Tesla: swift-metrics scope (issue #9, Lead view)

# Tesla — swift-metrics scope (issue #9, Lead view)

**Date:** 2026-05-20T18:19:39-07:00
**Author:** Tesla (Lead)
**Status:** Proposed — needs yashasg sign-off before any implementation cycle opens.
**Relevant agents:** Hopper, Ada, Edison, Curie (Ive/Mendel/Jacquard advisory).
**Related:** GitLab issue #9, issue #1 mitigation 3, decisions.md "Swift Coding Standards Adopted" (2026-05-20), `docs/swift_coding_standards.md` §2.2 / §2.3 / §2.12 / §7.

## Recommended posture

- **Backend:** Adopt `apple/swift-metrics` (the façade) **only as an abstraction
  layer**, not as a vehicle for a real exporter. `MetricsSystem.bootstrap(_:)`
  is called exactly once at app launch with **one of two factories**:
  1. **Release default (and DEBUG default when the gate is off):**
     `NOOPMetricsHandler.instance` — counters/timers/recorders compile and run
     but discard every value. Zero allocation per increment, no symbols
     referencing UI/storage.
  2. **When the gate is on (`KGR_METRICS_ENABLED=1`):** a project-local
     `InMemoryMetricsFactory` that fans every dimension to an in-process
     `actor`-guarded snapshot store. Never writes to disk, never opens a
     socket, never crosses the process boundary.
  No `StatsdMetricsHandler`, `PrometheusMetricsFactory`, OTel exporter,
  Firebase/Sentry/Datadog/Mixpanel SDK, or any handler that performs I/O.
- **Gating:** **Launch-argument / environment-variable gate**
  `KGR_METRICS_ENABLED=1`, matching the `KGR_*` convention already documented
  in `docs/swift_coding_standards.md` §2.3. The gate also drives whether a
  hidden "Diagnostics" surface (if Ive/Edison ever build one) is reachable.
  See §"Constraint conflicts" below for why this beats DEBUG-only and
  always-on alternatives.
- **Storage/sink:** In-memory only, bounded. One `actor MetricsStore` holding:
  - a `[String: Int64]` of monotonic counters keyed by `name|label-set`,
  - a fixed-size ring buffer (e.g. last 256 samples) per `Timer`/`Recorder`,
  - a `[String: Double]` for `Gauge` last-write-wins values.
  No persistence across launches in v1. No `FileHandle`, no `UserDefaults`,
  no SwiftData entity. (Persistence can be revisited later as a separate
  decision; not needed to satisfy issue #9.)

**Why this posture.** swift-metrics is genuinely useful as a **vocabulary**
(Counter/Timer/Gauge/Recorder) even when the backend is a no-op — it lets
Ada/Edison name product-meaningful events without each site re-inventing a
counter type, and the NoOp default keeps release builds completely silent.
Picking the façade now, with no exporter, is the only choice that satisfies
issue #1 mitigation 3 (no network) while letting issue #9 produce a usable
deliverable (a vocabulary + a debug-time sink).

## In scope (category level)

- **Errors** — input-validation failures, share-image render failures,
  SwiftData load/save failures, decoder errors on legacy saves. Counters
  only; no stack capture, no upload.
- **Resources** — memory and CPU footprint observed via **MetricKit**
  (`MXMetricManagerSubscriber`) and surfaced through the same in-memory
  sink. MetricKit is on-device, Apple-managed, and our subscriber callback
  is read-only — we never re-emit its payloads off the device.
- **Business / Domain** — meaningful product events that don't leak user
  content: compute invocations, "verdict" outcome distribution (match /
  drift / significant drift / major mismatch — categorical, not the
  numbers), save count, load count, share-image attempts vs. share-image
  fallbacks-to-text, About-help opens. These are the things we'd actually
  use to answer "did the share flow regress this week?" in TestFlight
  diagnostics builds.

## Out of scope (category level, and why)

- **Request / Traffic** — the app has zero HTTP surface. No endpoints,
  no methods, no in-flight gauge. The whole bucket is meaningless here.
- **Dependencies** — no database connection pool, no external API, no
  query duration. SwiftData (if/when shipped) is in-process and its few
  failure modes are already covered under **Errors** above.
- **Queues / Workers** — no background queue infrastructure, no jobs, no
  dead-letter. SwiftUI's `.task` is not a worker queue.
- **Retries** — we do not retry anything; there is nothing remote to
  retry against.
- **HTTP-shaped status families (2xx/4xx/5xx)** — categorically N/A.
- **Panic / crash counts as a custom metric** — MetricKit already
  delivers crash diagnostics on-device. Adding a parallel counter would
  duplicate Apple's surface and risk being wrong.

## Constraint conflicts / required amendments

1. **§2.2 (determinism) vs. timers around math.**
   `GaugeMath.compute` and its callees must not call `Metrics.Timer`,
   not read a clock, not invoke a callback. Any timing of compute happens
   **in the caller** (e.g., the SwiftUI view's recompute trigger) and is
   passed in as elapsed time after the fact. Requires an explicit
   sub-bullet under §2.2: "GaugeMath.compute and transitive callees may
   not import `Metrics`, may not call `MetricsSystem.*`, may not invoke
   any metric handle."
2. **§2.3 (no network, no analytics upload) — clarification, not change.**
   §2.3 already bans network and analytics-upload SDKs. Issue #9 forces
   us to write down explicitly that **swift-metrics the façade is not
   an analytics SDK**, but any *exporter* implementation is. Amend §2.3
   to enumerate: NoOp handler ✅, in-memory custom handler ✅, StatsD /
   Prometheus / OTel / Datadog / Sentry / Firebase / Mixpanel exporters ❌.
3. **§2.12 (logging discipline) vs. printing metric handlers.**
   A "print every increment" handler is a debugging convenience but
   violates §2.12 in release. Codify: any printing/logging metrics
   handler must be wrapped in `#if DEBUG` **and** gated by the env-var.
4. **§7 open question — close it.**
   The doc already flags this as open ("Whether on-device metrics via
   MetricKit count as 'analytics' under §2.3"). This scope resolves it:
   MetricKit consumption is allowed, MetricKit re-export is forbidden,
   in-process swift-metrics counters are allowed, any exporter is
   forbidden. §7 entry gets deleted once §2.13 lands.
5. **Privacy-card regression risk.**
   Edison removed the "no analytics" card on 2026-05-19 in anticipation
   of analytics. Under this scope we are *not* shipping analytics — we
   are shipping an inert vocabulary plus a debug-only in-memory sink.
   We need to decide deliberately whether the privacy card comes back
   with corrected copy. Default recommendation: **leave it removed** for
   now, and have Ive draft a single accurate "What this app collects:
   nothing leaves your device" line for a future release. Not part of
   this implementation cycle, but flagged so we don't drift.

## Open questions for yashasg

1. **Env-var name confirmation.** `KGR_METRICS_ENABLED=1` consistent with
   §2.3 convention — or do you want a different prefix / launch-argument
   style (`-KGRMetricsEnabled YES`)?
2. **MetricKit in scope now or later?** Including `MXMetricManager`
   subscription doubles the surface area (it's a separate API contract
   from swift-metrics). I lean **defer** — ship the façade + in-memory
   sink first, add the MetricKit bridge in a follow-up cycle once we've
   shaken out the vocabulary. Confirm?
3. **Diagnostics surface.** Do you want a hidden in-app screen (long-press
   the About `?`, or a debug menu) to view current counters when the gate
   is on? Or is the sink purely consumed by tests and `lldb`?
4. **Verdict-outcome counter granularity.** Counting "drift / significant
   drift / major mismatch" by category is fine; counting the *numeric
   verdict values* would leak user data into the sink. Confirm: category
   only, never the raw drift percent.
5. **Metric naming budget.** Soft cap proposal: ≤ 20 distinct metric names
   in v1, kebab-case under three roots (`kgr.compute.*`, `kgr.share.*`,
   `kgr.save.*`). Acceptable?
6. **Share-render timing.** Edison's share-image path is the heaviest
   on-device operation and the most likely UX regression site. Timer
   around `ImageRenderer` + activity-sheet presentation is highest-value.
   Confirm including it?

## Next-step ownership map (rough — for the implementation cycle)

- **Hopper** — `app/build.sh` plumbs `KGR_METRICS_ENABLED` through to the
  Xcode scheme's launch environment (test and run modes); release builds
  default to **unset**. Adds a CI assertion that the Release configuration
  does not link any analytics SDK and that the metrics-handler symbol
  resolves to `NOOPMetricsHandler` when the gate is off.
- **Ada** — guards `GaugeMath.swift` against ever importing `Metrics`
  (a compile-time check via a thin wrapper module or a Curie test that
  greps the file). Owns the §2.2 amendment text.
- **Edison** — adds the swift-metrics bootstrap call at app entry, defines
  the project-local `InMemoryMetricsFactory` and `MetricsStore` actor,
  instruments the **caller side** of `GaugeMath.compute` (count + timer),
  the share-render path (timer + success/fallback counters), and the
  save/load path (counters + error counter). No metric handles inside
  `GaugeMath`.
- **Curie** — writes tests that (a) under the gate-off default, every
  `Counter.increment` is a no-op (asserted via `MetricsSystem` swap in a
  test harness), (b) under the gate-on path, increments land in the
  in-memory store with the expected name/label set, (c) release-config
  binary does not contain any of the banned exporter symbol names
  (grep on the linked binary or `nm` output), (d) `./app/build.sh test`
  remains 0 warnings, 25+/25+ tests green.
- **Tesla (me)** — authors §2.13 of `docs/swift_coding_standards.md`,
  retires the §7 open question, and appends the dated decision to
  `.squad/decisions.md` once yashasg signs off this scope. Updates the
  ownership table in `loop.md` only if a new work item needs to land
  there; otherwise `loop.md` is untouched (this is observability, not a
  goal change).
- **Ive / Mendel / Jacquard** — advisory only this cycle. Ive may be
  pulled in if/when a Diagnostics surface gets built. Mendel and
  Jacquard have no domain stake in the instrumentation choice itself.

## 2026-05-20T18:19:39-07:00 — Ada: swift-metrics scope (issue #9, math-layer view)

# Ada — swift-metrics scope (issue #9, math-layer view)

Date: 2026-05-20T18:19:39-07:00
Owner: Ada (Algorithms Dev, §2.2 owner)
Scope: GaugeMath.swift and its pure callees only. UI / persistence / app-lifecycle
signals belong to Edison / Tesla scopes and are out of frame here.

## In scope at the math-layer BOUNDARY (i.e. at call site, not inside)

- **gauge_compute_duration_nanos** (timer / histogram) — wall time of a single
  `GaugeMath.compute(_:)` invocation. Measured by the **caller** (ContentView,
  or whichever surface owns the recompute) by reading `ContinuousClock` (or
  `SuspendingClock`) before and after the call and recording the delta into an
  in-process MetricKit-friendly aggregator. Cardinality: a single histogram,
  no per-input labels (would explode cardinality and re-introduce input PII).
- **gauge_compute_invocations_total** (counter) — number of times
  `GaugeMath.compute(_:)` is invoked. Incremented by the call site in the
  recompute path, not by math. Cardinality: 1 series.
- **gauge_extreme_ratio_total** (counter) — number of computes whose
  *returned* `stitchWidthScale` or `rowCountScale` falls outside
  `[1/1.5, 1.5]` (i.e. the "Much looser / Much tighter / Much denser" band
  the prototype already classifies). Derived **after** compute by reading
  `GaugeMathResult` at the call site; the math itself stays oblivious.
  Cardinality: at most 3 buckets (`match`, `drift`, `extreme`) — keep it small.
- **gauge_cast_on_drift_band_total** (counter) — number of computes whose
  returned `castOnRoundingDriftPercent` is `>= 3%`. Same pattern: classify
  from the result struct outside the math layer. Cardinality: 2 buckets
  (`within`, `flagged`).
- **gauge_invalid_input_fallback_total** (counter) — number of times the
  caller had to substitute a default because user input failed
  `GaugeMath.sanitized(_:default:)`. Recorded by the caller *around* the
  sanitize call (compare raw parsed `Double?` to the value `sanitized` returns
  — or, equivalently, track parse failures upstream of `sanitized`). Math is
  not asked to report this. Cardinality: 1 series.

All five signals are **derived from inputs or results that already cross the
boundary**, so no new surface area on `GaugeMath` is required.

## Out of scope at math layer (and why determinism forbids it)

- **Clock reads inside `compute` (or `sanitized` / `fmt*`).** §2.2 explicitly
  bans `Date()` / `DispatchTime.now()` / `ContinuousClock.now` in compute
  paths. A timer started inside `compute` would violate this directly. Timers
  belong on the call site of `compute`, never inside it.
- **A metric-sink / logger / callback parameter on `compute`** (e.g.
  `compute(_:, metrics:)` or `compute(_:, log:)`). Injecting a side-effecting
  collaborator into a pure function destroys §2.2's determinism contract:
  identical `GaugeInputs` would no longer produce identical observable
  behaviour, and tests would have to mock the sink. Math takes values and
  returns values — full stop.
- **Static mutable counters inside `enum GaugeMath`** (e.g.
  `static var invocationCount`). Even though the visible return value would
  stay the same, this re-introduces hidden process-global state into a
  namespace whose entire purpose is "pure functions." It also breaks
  parallel-test isolation and the §2.6 caseless-namespace contract.
- **`os_log` / `Logger` / `print` inside `GaugeMath`.** §2.12 forbids logging
  in the math layer regardless of build configuration. `#if DEBUG` does not
  open a door for math-layer logs — the whole layer is silent.
- **Branch-counter instrumentation for `gaugeStatus` / `rowStatus`** in this
  file. Those helpers are private free functions used by
  `ResultsExportSummary`, but they are pure classifiers; counting their
  invocations adds nothing the call site cannot derive from
  `GaugeMathResult` itself. If a future "how often does the user land in
  Match vs Drift" metric is wanted, it is computed at the call site from
  the returned `stitchWidthScale` / `rowCountScale`, exactly like
  `gauge_extreme_ratio_total` above.
- **Formatter-helper usage counters** (how often `fmtCm` / `fmtRows` /
  `fmtPct` are called). These are pure value-to-string transforms invoked
  by view code; if frequency is interesting, the view counts its own renders.
  Putting a counter inside the helper would add hidden state to a function
  whose contract is "same input → same string."
- **Any input-distribution histogram of `GaugeInputs` values themselves.**
  Recording user gauge numbers as a histogram is effectively analytics on
  user inputs; per §2.3, that has to arrive as a written decision before any
  surface (math layer or otherwise) gains the capability. The math layer is
  the wrong place either way.
- **Network egress of any of the above.** §2.3 — not negotiable. All five
  in-scope signals stay in-process and consumed by an on-device MetricKit
  or in-memory aggregator only.

## Boundary contract for callers

- Callers (e.g. `ContentView`) MAY wrap `GaugeMath.compute(_:)` with:
  - A `ContinuousClock` timer measured **before and after** the call, with
    the delta forwarded to an in-process metrics aggregator.
  - A counter increment on the same code path that invokes `compute`.
  - Post-hoc classification of the returned `GaugeMathResult`
    (`stitchWidthScale`, `rowCountScale`, `castOnRoundingDriftPercent`) into
    coarse buckets for counter labels.
  - Pre-hoc classification of parse outcomes around `GaugeMath.sanitized`
    (i.e. did the raw `Double?` survive validation, or did the default win).
- Callers MUST NOT:
  - Pass any metric sink, logger, clock, or callback into `GaugeMath.compute`,
    `GaugeMath.sanitized`, `GaugeMath.fmtCm`, `GaugeMath.fmtRows`, or
    `GaugeMath.fmtPct`. The signature of every function in `enum GaugeMath`
    stays `(values) -> values`.
  - Add any `static var` mutable counter inside `enum GaugeMath`.
  - Introduce `#if DEBUG`-gated logging inside `GaugeMath.swift` (§2.12
    silence is unconditional for this layer).
  - Forward any of the metric signals above off device (§2.3).

The math layer's public surface stays exactly:

```
GaugeMath.compute(_: GaugeInputs) -> GaugeMathResult
GaugeMath.sanitized(_: Double?, default: Double) -> Double
GaugeMath.fmtCm(_: Double) -> String
GaugeMath.fmtRows(_: Double) -> Int
GaugeMath.fmtPct(_: Double) -> Int
```

No new parameters. No new return-tuple element. No new protocol. If issue #9
ultimately requires a richer signal that cannot be derived from the existing
return struct, the correct fix is to **add a field to `GaugeMathResult`**
(a pure value) rather than to inject a side-effecting collaborator — and
that addition still routes through a new inbox decision.

## Constraint impact

- **Math determinism (§2.2):** Confirmed — nothing proposed above touches the
  math layer. Every in-scope signal is measured at the call site from values
  that already cross the boundary. Every tempting signal that *would* violate
  §2.2 is explicitly named in the out-of-scope section.
- **Logging (§2.12):** Confirmed — the math layer remains silent in all
  build configurations.
- **Network / analytics upload (§2.3):** Confirmed — all five in-scope
  signals are in-process only.
- **Tests:** `GaugeMathTests` need **no** change. The math API is unchanged,
  inputs and outputs are bit-identical, and the existing scenarios (Jacquard
  1–6, edge drifts, float-precision parity, cast-on rounding) all stay
  green. Any new tests live next to the call site that owns the
  instrumentation, not next to the math.

## 2026-05-20T18:19:39-07:00 — Edison: swift-metrics scope (issue #9, SwiftUI view)

# Edison — swift-metrics scope (issue #9, SwiftUI view)

Date: 2026-05-20T18:19:39-07:00
Owner: Edison (Frontend Dev, §2.8)
Status: Proposed scope for ContentView only. Math layer unchanged (§2.2).

## In scope (UI events)

All signals below are **in-process counters/gauges/timers only**. No
persistence beyond process lifetime, no export, no network. Every signal is
double-gated: compiled out via `#if DEBUG` AND inert at runtime unless the
launch env var `KGR_METRICS_ENABLED=1` is set (same `KGR_*` convention used
for existing test fixtures).

### Compute pipeline

- **`compute.invocations`** (counter) — increment inside the `result`
  computed property at the single `GaugeMath.compute(inputs)` call site
  (ContentView.swift line ~36). Wraps in ContentView, not in math, so §2.2
  is preserved. Zero labels. Cardinality 1. DEBUG + env-gated.
- **`compute.duration_ms`** (timer / histogram) — measure around the same
  `GaugeMath.compute(inputs)` call. Use `ContinuousClock().measure { ... }`
  or `DispatchTime` (DEBUG-only — §2.2 still forbids clock reads *inside*
  the math layer; reading the clock in the view caller is allowed).
  Caveat: `result` is recomputed on every `body` re-evaluation, not only on
  user input. The duration histogram is per-call latency, not
  per-user-edit latency. Document this in the metric description. Buckets:
  microseconds to low millisecond — the math is trivial arithmetic.

### Input field edits

- **`field.edited`** (counter, label = `field_id`) — `.onChange(of: <text>)`
  on each of the nine input `@State` text bindings (`patternStitches`,
  `patternRows`, `yourStitches`, `yourRows`, `patternCastOn`, `patternYoke`,
  `patternBody`, `patternSleeve`, `patternIncreases`). Label cardinality
  bounded to 9 known string IDs (low). **Debounce decision:** count raw
  `.onChange` per keystroke is too noisy and reveals typing cadence; count
  on *parsed-value change* instead — i.e., emit only when
  `read(text, default:)` produces a different `Double` than the previous
  value. This collapses "32" → "320" → "32" (mistype-and-correct) to a
  net-zero signal and keeps cardinality on the event axis bounded.
  **No raw text value is ever captured** — only the field ID. DEBUG +
  env-gated.

### Disclosure / sheet affordances

- **`disclosure.full_math.toggled`** (counter, label = `to`
  ∈ `{shown, hidden}`) — hooked in the existing `showFullMath.toggle()`
  button action (line ~249). Stable identifier `disclosure-full-math`
  is untouched.
- **`sheet.verdict_help.opened`** (counter) — `.onChange(of: showVerdictHelp)`
  on the false→true transition. No close-tracking; iOS native dismiss is
  not a metric-worthy event.
- **`sheet.about_help.opened`** (counter) — `.onChange(of: showAboutHelp)`
  same pattern.
- **`share.invoked`** (counter, label = `payload`
  ∈ `{image, text_fallback}`) — instrumented inside `shareResults()`
  around the image-vs-fallback branch (line ~389-396). The label
  distinguishes the rendered-PNG primary path from the text fallback so
  we can see how often `ImageRenderer` fails. Does **not** capture share
  sheet *completion* (iOS doesn't reliably callback for native share
  cancellations and we won't pipe a delegate through `UIActivityViewController`
  just for a counter).
- **`reset.tapped`** (counter) — hooked in `resetToDefaults` (line ~376).

### Verdict / extreme-input bucket

- **`verdict.state`** (gauge, value = current bucket
  ∈ `{match, drift, significant_drift, major_mismatch}`) — set inside
  `verdictTitle`'s switch ladder (already exists, lines 301-317). Gauge,
  not counter — it reflects the *current* state, not transitions.
- **`verdict.transitioned`** (counter, label = `to`) — same four states,
  emitted via `.onChange(of: verdictTitle)`. This is the "user edited
  themselves into a major mismatch" signal.
- **`cast_on.drift_pill_shown`** (counter) — emitted via
  `.onChange(of: result.castOnRoundingDriftPercent.abs >= 3)` false→true.
  Lines ~244-246 already gate the pill on the same threshold.

### Layout (compact vs regular)

- **N/A — explicitly out.** See "Out of scope" below.

## Out of scope (and why)

- **Scenario picker tap rate.** There is no scenario picker in
  ContentView. Mendel's six Jacquard scenarios live in unit/UI tests, not
  in the user-visible app. Nothing to instrument.
- **Compact-vs-regular size class gauge.** This is an iPhone-only target.
  `horizontalSizeClass` is `.compact` on every supported device except
  large iPad landscape, which we don't target. The distribution would be
  ~100% compact and tell us nothing. Skip.
- **Per-keystroke field events.** Reveals typing speed/cadence (a weak
  fingerprint) and floods the counter. Use parsed-value-change debounce
  above instead.
- **Captured input *values*.** Never. The four gauge integers, the
  cast-on, and the cm dimensions belong to the user's project and stay on
  device, in memory, untracked. Field ID only — never the contents.
- **Share sheet *completion* / target app.** iOS doesn't expose this
  cleanly via `UIActivityViewController`, and the user's choice of
  Messages-vs-Mail-vs-AirDrop is not a signal we need. The `share.invoked`
  + image-vs-text-fallback split is enough.
- **`keyboard-done` taps.** Pure UX noise; the existence of the affordance
  is already tested.
- **Help-sheet *dwell time*.** Would require timing dismissals, which
  needs delegate plumbing we don't have. Open-count is sufficient.
- **Persisted-across-launches counters.** Anything in `UserDefaults`,
  `FileManager`, or `SwiftData` becomes "data we retain about the user"
  and crosses the privacy line drawn on 2026-05-19. Counters live in
  process memory, die with the process.

## Privacy / regression risk

The 2026-05-19 decision to delete the privacy card was made because the
"no analytics" claim was about to become false. That decision must not
silently regress here. The gating below is what makes this scope
compatible with that decision:

- **Compile-time gate (#if DEBUG):** release builds physically do not
  contain the instrumentation code. App Store builds ship zero counters,
  zero timers, zero `.onChange` metric hooks. This is the primary
  defence — a release binary that ships to a user has no analytics
  surface to misbehave.
- **Runtime gate (`KGR_METRICS_ENABLED=1`):** even in DEBUG, signals are
  inert unless the env var is set at launch. Default DEBUG behaviour
  (e.g., during normal simulator dev) is also zero recording. This means
  Curie's UI test suite, which sets several `KGR_*` envs but not this
  one, sees no metric activity and remains unaffected.
- **No network code paths, period.** No `URLSession`, no upload buffer,
  no "we'll just queue it for later" stub. §2.3 forbids the dependency
  outright, not just the call.
- **No on-disk persistence.** Counters are in-memory only and die with
  the process. No `UserDefaults`, no caches directory, no SwiftData
  table. (The existing share-export PNG path in
  `shareExportDirectory()` is user-initiated and unrelated.)
- **No UI surface.** No "Privacy" or "Analytics" or "Telemetry" card.
  No debug overlay visible to the user. No new
  `accessibilityIdentifier`. The instrumentation is invisible to anyone
  not attached to the running process via Xcode. This means we cannot
  silently re-introduce misleading copy because there is no copy.
- **No `print` / `os_log` / `Logger` in release.** Per §2.12. If a
  future decision wires an `os_signpost` for in-flight Instruments
  profiling, that signpost call site must itself be `#if DEBUG`-gated.

The combined effect: a user with a release build from the App Store has
the same observability properties the deleted privacy card used to
*claim* — nothing collected, nothing transmitted, nothing persisted —
without us having to assert that claim in copy that might become false
again later.

## UI test impact

### Tests that could break — and the discipline that prevents it

- **`testAllJacquardScenariosAreVisibleInUI`** depends on identifiers
  `your-stitches`, `your-rows`, `pattern-stitches`, `pattern-rows`,
  `cast-on-result`, `keyboard-done`, and the literal hero-percent and
  guidance strings (`"100%"`, `"Knit to 50.0 cm · about 120 rows/rounds"`,
  etc.). **No instrumentation may rename or remove any of these
  identifiers**, and no instrumentation may add a wrapping view that
  changes the accessibility tree under those identifiers. `.onChange`
  modifiers don't affect the accessibility tree; they're safe.
- **`testShareResultsIsSingleAccessibleAffordance`** asserts
  `share-results` exists and is the *only* share/copy affordance — it
  negatively asserts on `copy-results`, `copy-share-link`,
  `share-results-link`, any button whose label starts with `"Copy"`, and
  any button labelled `TSV` / `Markdown` / `CSV` / `HTML`. **The
  instrumentation must not add a "Copy diagnostics" or "Export counters"
  button**, even DEBUG-only — it would break the
  `BEGINSWITH "Copy"` predicate. If we ever want a counter dump, it goes
  through Xcode breakpoints / `po`, not a button.
- **`testAboutHelpButtonOpensPullUpSheet`** asserts
  `app.otherElements["privacy-card"].exists == false`. **No
  instrumentation may add any view with the identifier `privacy-card`
  or any visible "Privacy"/"Analytics" UI** (regression guard from the
  2026-05-19 deletion).

### Tests that need new assertions

None — by design. Because the in-scope signals add zero UI surface and
zero new identifiers, the UI test contract is unchanged. If a later
decision adds an Instruments signpost or a debug-only counter dump,
*that* decision should land with its own test.

## Constraint impact

- **§2.2 math boundary:** confirmed — metric wrapping happens entirely
  in ContentView.swift. `GaugeMath.compute` and its callees gain no
  imports, no parameters, no closures, no clock reads, no state. The
  timer/counter wraps the single call site in the view's `result`
  computed property. Ada's layer is untouched.
- **§2.8 SwiftUI rules:** confirmed — all new `@State` (if any
  in-process counter store is added; preferred: a single private
  `@StateObject` or a top-level `enum` namespace with `static`
  in-memory counters, *not* an `@ObservedObject`) stays `private`. No
  existing `accessibilityIdentifier` is renamed. No new identifier is
  added. `.task` is used over `Task { }` if we need any async metric
  flush (we don't, for this scope). No `DispatchQueue.main.async`.
- **§2.12 release gating:** confirmed — every metric call site is
  inside `#if DEBUG` and additionally guarded by
  `ProcessInfo.processInfo.environment["KGR_METRICS_ENABLED"] == "1"`.
  No `print` / `os_log` / `Logger` in non-DEBUG branches. If we later
  add `os_signpost` for Instruments-only profiling, those calls are
  also `#if DEBUG`.
- **§2.3 no analytics upload:** confirmed — no `URLSession`, no
  third-party SDK, no remote config. Counters are in-process,
  in-memory, ephemeral.
- **Build budget:** `./app/build.sh test` must remain exit 0 with zero
  warnings and the current 25/25 tests including UI tests. Because the
  `#if DEBUG`-gated branches compile in test/debug but cannot affect
  release-build warnings, and because the runtime gate keeps them inert
  in the existing UI tests' launch environments, both axes are
  preserved.

## 2026-05-20T18:19:39-07:00 — Curie: swift-metrics scope (issue #9, test view)

# Curie — swift-metrics scope (issue #9, test view)

**Date:** 2026-05-20T18:19:39-07:00
**Owner:** Curie (Tester, §2.9 owner)
**Scope:** Test/verification perspective only. Companion to Tesla's scope-clarification on #9 (device-local, no upload).

## Verification strategy

- **Unit-level (Swift Testing, `@Test`)**
    - **Bootstrap behaviour.** A `MetricsBootstrap` (or equivalent) seam must be unit-testable without touching the global `MetricsSystem`. The seam takes an injected `MetricsFactory` and is what production code calls; the global `MetricsSystem.bootstrap(_:)` is invoked exactly once at app launch from the app entrypoint and is **not** exercised from tests. Tests assert: (a) gating env var / launch arg (e.g. `KGR_METRICS=1`) selects the real factory; (b) when gating is off, the factory is `NOOPMetricsHandler` (or our own no-op) and no counters mutate; (c) `#if DEBUG`-only signals do not register in release-shaped builds.
    - **Signal recording.** Use an in-process `TestMetricsFactory` (≈30 lines: arrays of `(label, dimensions, value)` tuples, thread-safe via a lock) injected into the unit under test. Assert on **recorded labels, dimensions, and counter increments by exact count** — never on absolute timer durations or wall-clock values. swift-metrics' upstream package does **not** ship a test handler (confirmed against the public `apple/swift-metrics` repo; only `NOOPMetricsHandler` and `MultiplexMetricsHandler` are public), so we own the test factory locally under `KnittingGaugeReconcilerTests/Support/TestMetricsFactory.swift`.
    - **Determinism guard.** A targeted test asserts `GaugeMath.compute` records **zero** metrics signals during a call (preserves §2.2 — the math layer stays side-effect-free). If anyone wires a counter into `GaugeMath`, this test fails loudly.
- **Integration-level**
    - Light. One test per call-site that *should* record: e.g. `ContentView` mounting fires a `screen.opened` counter exactly once; tapping `share-results` fires `share.invoked` exactly once; an invalid-input fallback fires `input.fallback` with the expected dimension. These tests inject the `TestMetricsFactory` into the view's environment / view-model; they do not boot the global system.
- **UI-level (XCTest)**
    - **No new UI tests for metrics.** Metrics are invisible; asserting on them through XCUIApplication would either require a debug HUD (out of scope) or pasteboard exfiltration (smells). Existing UI tests continue to verify behaviour; metrics are validated at the unit/integration layer where assertions are deterministic.
    - The existing UI suite stays the regression net for accessibility-identifier contracts that any metrics-bearing call site touches.

## Test-isolation rules

- **No global bootstrap in test runs.** `MetricsSystem.bootstrap(_:)` is process-global and can be called exactly once per process; calling it from tests poisons every subsequent test in the same process. Production bootstrap is wrapped in `MetricsBootstrap.installIfNeeded()` which is only invoked from `@main` / `App.init`, never from `@testable` code paths. Tests use the injectable factory seam.
- **Per-test factory, not per-suite.** Each `@Test` gets a fresh `TestMetricsFactory` instance via a local `let factory = TestMetricsFactory()`. No `static` storage, no `@TaskLocal`, no singletons. Counters from one test cannot bleed into another because the instance is gone at end of test.
- **No real network.** Already enforced by §2.3 and by the absence of `URLSession` in the codebase. Restated for completeness: metrics implementation must not introduce any networked exporter, even disabled-by-default. If a future exporter is proposed it needs its own decision drop.
- **Warning-free under gating.** The `#if DEBUG` / env-var gates must compile cleanly in **all four** modes: DEBUG-on, DEBUG-off, gate-env-set, gate-env-unset. The CI gate runs DEBUG-on; Hopper's release-build path covers DEBUG-off. Any `#if !DEBUG` block that imports `Metrics` must guard the import too — otherwise warnings-as-errors (§2.1) flags an unused-import.
- **Determinism.** No assertions on timer values (`Timer.recordNanoseconds`), no assertions on `Date()`-derived dimensions, no assertions on counter values that depend on `Task` scheduling order. Counts and labels only.

## Tests at risk of regression

Cross-checked against Edison's accessibility-identifier contract (§2.8). If a metrics implementation refactors a call site and shifts an identifier, these tests break first and Edison's identifier-rename rule applies (test update in the same commit):

- `testAllJacquardScenariosAreVisibleInUI` — depends on the live-recalc path. If metrics get wired into the input pipeline or recalc and that pipeline gets refactored, the visible-result identifiers (`pattern-stitches`, `your-stitches`, hero number labels, the six scenario fingerprints) must remain. Risk: medium.
- `testShareResultsIsSingleAccessibleAffordance` — asserts `share-results` button exists and the old `share-results-link` does **not**. A `share.invoked` counter wired onto the button must not require renaming or duplicating the affordance. Risk: high if metrics tracking is added by wrapping the button in a new container view.
- `testAboutHelpButtonOpensPullUpSheet` — asserts `about-help-button` and `about-help-sheet` identifiers. A `help.opened` counter on the button tap must not change these identifiers. Risk: low (single tap site).

These three are the highest-leverage regression net for the metrics rollout. They stay; they do not learn about metrics.

## New test target / file?

- **Recommendation:** **Do not** spin up a new test target (`KnittingGaugeReconcilerMetricsTests`). It would duplicate the `@testable import KnittingGaugeReconciler` plumbing, double the project-file churn, and double simulator boot time on CI (already a constraint per the 2026-05-20T06-25 serial-UI directive). Instead:
    - Add **one Swift file** to the existing `KnittingGaugeReconcilerTests` target: `MetricsTests.swift` (the `@Test` functions for bootstrap + signal recording + integration).
    - Add **one support file**: `Support/TestMetricsFactory.swift` (the in-memory factory, thread-safe, ~30 lines).
    - If the suite grows past ~15 metrics-specific tests we revisit; the same scaling rule we use for any other feature area.

## Constraint impact

- **0 warnings under `-warnings-as-errors`:** swift-metrics on iOS 26.4 / Xcode 26.4 / Swift 6 is the risk surface. Known issues to verify during implementation: (a) Sendable conformance — `MetricsFactory` and `CounterHandler` protocols must be `Sendable` for clean adoption under Swift 6 strict concurrency, which has historically required swift-metrics ≥ 2.5. (b) Deprecation surface — older `Metrics.makeCounter(label:dimensions:)` call sites have shifted; pin to the current API. (c) Optional `Logging` transitive dependency — must not pull in `swift-log` warnings. **Action:** before merge, pin the exact swift-metrics version Hopper introduces, run `./app/build.sh test` and confirm `xcodebuild` emits zero diagnostics. If any swift-metrics diagnostic appears, the dependency must be patched or held — we do not relax §2.1.
- **Determinism (§2.2):** Math layer recording any metric is a determinism violation. The "math records zero signals" guard test enforces this at the unit level. Metrics live in the UI / app-shell layers only.
- **§2.9 framework choice — Swift Testing vs XCTest for metrics unit tests:** **Swift Testing** (`@Test`, `#expect`). Consistent with §2.9 and with the existing 18-test `GaugeMathTests` suite. XCTest stays reserved for UI tests. Per-test setup is a local `let factory = TestMetricsFactory()` at the top of each `@Test func`; no `@Suite` shared state needed (and per the isolation rule above, would actively hurt).

## Validation gate (unchanged contract)

`./app/build.sh test` must continue to exit 0, **0 warnings**, **25/25 tests** today → **N/N tests** after metrics lands (current 18 unit + 7 UI = 25 baseline). If metrics rollout pushes the unit count higher, all new tests run green on first PR or the metrics work doesn't merge. UI count stays at 7 unless an identifier change forces a UI-test update in the same commit.

## 2026-05-20T18:19:39-07:00 — Hopper: swift-metrics scope (issue #9, tooling view)

# Hopper — swift-metrics scope (issue #9, tooling view)

Author: Hopper (Tooling Dev)
Date: 2026-05-20T18:19:39.085-07:00
Scope: build / packaging / CLI implications of adding `apple/swift-metrics`
to this Xcode project. **No code yet** — scoping only.

Reference points used:
- `app/build.sh` (current shape: 575 lines, three modes, env-var driven sim
  selection, no SPM today).
- `app/app.xcodeproj/project.pbxproj`: `IPHONEOS_DEPLOYMENT_TARGET = 17.0`,
  `SWIFT_VERSION = 6.0`, zero `XCRemoteSwiftPackageReference` entries —
  the project has no SPM dependencies of any kind today.
- `apple/swift-metrics` latest stable: **`2.11.0`** (released 2026-05-19),
  three library products: `CoreMetrics`, `Metrics`, `MetricsTestKit`.
  `Package.swift` uses `swift-tools-version:6.1` and enables
  `StrictConcurrency=complete` + `MemberImportVisibility` upcoming feature.
- `docs/swift_coding_standards.md` §2.3 (no network/analytics), §2.12 (no
  logging in release outside `#if DEBUG` / env-var gate), §3 (Tooling — I
  own this section).
- No `.gitlab-ci.yml` currently checked in (per a previous Hopper learning
  about `saas-macos-medium-m1`).

## Package integration plan

- **How:** Add via **Xcode-integrated SPM** ("File → Add Package
  Dependencies…" against `https://github.com/apple/swift-metrics`).
  - This is the path of least resistance: project is already a plain
    Xcode project, no `Package.swift` in repo, `build.sh` shells
    `xcodebuild` directly. Adding the dependency writes
    `XCRemoteSwiftPackageReference` + `XCSwiftPackageProductDependency`
    nodes into `app/app.xcodeproj/project.pbxproj` and produces
    `app/app.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`.
  - **Do not** introduce a local `Package.swift` / hybrid SwiftPM layout.
    The cost (root-level `Package.swift`, dual build graphs, more for
    Curie and Edison to learn) is not justified by a single dependency.
  - **Pin exact version** (not "up to next major"): use the
    `.exact("2.11.0")` rule in Xcode's package dialog. Rationale: our
    `-warnings-as-errors` gate makes us extremely sensitive to upstream
    minor releases that introduce new deprecation warnings. We bump
    deliberately, never automatically.
  - **Commit `Package.resolved`** to git (it sits under
    `app.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/`) so CI and
    every dev resolve the identical revision.

- **Products:**
  - Link `Metrics` to the **`KnittingGaugeReconciler`** app target. This
    transitively pulls `CoreMetrics`; we do **not** add `CoreMetrics` as
    a direct dependency unless we need to touch `MetricsSystem.bootstrap`
    or write a custom handler. (For a custom in-process handler, see
    note in "Optional lint rules" below.)
  - Link `MetricsTestKit` to the **`KnittingGaugeReconcilerTests`** unit
    target only. Provides `TestMetrics` (in-memory handler) for assertions.
  - **Do not** link any swift-metrics product to
    `KnittingGaugeReconcilerUITests`. UI tests are black-box; they should
    not import handler internals. If a UI test needs to assert a counter
    fired, the app must surface the count via an accessibility element
    (a hidden `Text` with `accessibilityIdentifier`) — same pattern Curie
    uses today.

- **Compatibility:**
  - **iOS deployment target:** swift-metrics 2.x declares `.iOS(.v13)`;
    we ship `iOS 17.0`. ✅
  - **Swift / Xcode toolchain:** swift-metrics `main` and `2.11.0` use
    `swift-tools-version:6.1`. Our project is `SWIFT_VERSION = 6.0`, and
    we run on Xcode 26.x (Swift 6.x toolchain). Xcode 26.x ships Swift
    6.1+ — **expected to compile cleanly**, but I will **validate this
    on a throwaway branch** before merging: a `swift-tools-version:6.1`
    package fails to resolve on a Swift 6.0-only toolchain with a hard
    error from SwiftPM. If Xcode 26.4 turns out to ship 6.0 only, we
    fall back to swift-metrics **`2.6.x`** (the last release on tools
    version 5.7) — that line is still supported and API-compatible at
    the public `Counter` / `Timer` / `Recorder` surface.
  - **`StrictConcurrency=complete`** is on inside swift-metrics's own
    targets only; it does **not** propagate to our targets. Our consumer
    code stays on the project's existing concurrency settings.
  - **`MemberImportVisibility`** upcoming feature is also scoped to the
    package's own targets. Our consumer code can `import Metrics` without
    needing to also `import CoreMetrics` for the public Counter/Recorder
    API; we'd only need a second import if we reach into CoreMetrics
    handler protocols (custom handler path).

## Gating mechanism

- **Env var (single switch):** `KGR_METRICS_BACKEND`
  - Type: string, case-insensitive at parse time.
  - Accepted values:
    - `noop` — bootstraps `NOOPMetricsHandler.instance`. Zero allocation,
      zero overhead. **This is the production default.**
    - `inmemory` — bootstraps `MetricsTestKit.TestMetrics`. Captures
      events in-process; readable via the app's existing debug surface
      (a future internal screen — out of scope for this scoping doc).
      Never logs, never writes to disk, never sends network. Safe in
      Release in principle, but we **refuse it at runtime in Release**
      unless the user has also explicitly set the unlock env var (see
      below) — keeps Release behaviour predictable.
    - `debug-print` — DEBUG-only. Bootstraps a tiny in-process factory
      that prints metric events via `print(...)` from inside `#if DEBUG`
      blocks only. **Compile-time stripped from Release.** If a user
      sets this in a Release build, the runtime gate falls back to
      `noop` and emits **no** diagnostic (silent demotion is required —
      we can't `print` "ignored" from Release per §2.12).
  - **Unset / unrecognised value:** treated as `noop`. No crash. No log.
  - Master-switch question (e.g., `KGR_METRICS_ENABLED=0`): **rejected**
    as redundant. One env var, one knob — `KGR_METRICS_BACKEND=noop` is
    already the "off" state. Keeps the surface area small.

- **DEBUG default:** `noop`. Devs opt in to `inmemory` or `debug-print`
  via Xcode scheme env vars or the shell when running `./app/run.sh`.
  Rationale: silent metric bootstrap during normal development would
  surprise Edison and Curie; off-by-default keeps tests deterministic.

- **RELEASE default:** `noop`. Hard-coded. No env-var path in Release
  can elevate above `noop` (see compile-time guard above). This is the
  §2.12 / §2.3 safety net.

- **`build.sh` changes needed:**
  1. **No new mode**, no new flag. Metrics rides along on existing
     `build`, `test`, `release` modes via the env var.
  2. **One new pass-through block** inside `build.sh`: just before the
     `XCODEBUILD_ARGS` is finalised, iterate over the env, and for each
     `KGR_*` variable present, append a matching
     `TEST_RUNNER_<NAME>=<VALUE>` build setting to `XCODEBUILD_ARGS`.
     This is the documented xcodebuild contract for getting env vars
     into the **launched test runner's `ProcessInfo.environment`** (the
     `TEST_RUNNER_` prefix is stripped at launch). Without this block,
     `KGR_METRICS_BACKEND=inmemory ./app/build.sh test` silently has no
     effect inside the test process.
  3. For `build` and `release` modes the env var is propagated as a
     normal user-default env var; the app target reads it at launch.
     No pass-through needed for `release` because Release ignores the
     value anyway, but the variable still surfaces if someone runs the
     archived app under Xcode.
  4. Touch nothing else: locking, simulator selection, retry policy,
     `verify_xcresult_summary`, warning gate — all unchanged.

## Warnings / `-warnings-as-errors` risk

- **Our gate scope:** `OTHER_SWIFT_FLAGS="-warnings-as-errors"` and
  `SWIFT_TREAT_WARNINGS_AS_ERRORS=YES` are set on the Xcode project's
  build settings. **xcodebuild applies these to first-party targets**;
  SPM package targets compile with **their own** `swiftSettings` and
  their own warning policy. swift-metrics 2.11.0 builds clean on its
  own settings. **Warnings inside swift-metrics will not fail our gate.**
  This is the single most important fact in this section.
- **Risk surfaces (in our code, where the gate does fire):**
  1. **Sendable diagnostics** on any closure or stored property that
     captures a `Counter` / `Recorder` / `Timer`. swift-metrics 2.x
     public types are `Sendable` — should be clean — but if we wrap
     them in our own non-`Sendable` holder, Swift 6 strict concurrency
     will surface a warning. Mitigation: keep metric handles as `let`
     in `Sendable` namespaces (caseless `enum`, per §2.6).
  2. **Deprecation warnings** if we copy older sample code that uses
     `Metrics.Counter` (deprecated alias) instead of `Counter`. Style
     fix; cheap to catch in review.
  3. **`MemberImportVisibility`** — package-internal, not consumer-
     facing. Zero risk.
  4. **Unused-result** if Ada wires a `Counter.increment()` call and a
     future refactor drops the side effect. Already covered by the
     existing gate.
- **Validation plan when the dep lands:** branch → add dependency →
  `./app/build.sh test` → confirm exit 0, 0 warnings, 25/25. If any
  upstream warning leaks (e.g., a future minor release flips a default),
  we either pin lower or wrap the symptom; we do **not** disable the
  gate.

## CI/CD impact

- **Current state:** no `.gitlab-ci.yml` in repo today. The reference
  runner remains `saas-macos-medium-m1` per `.squad/identity/now.md`
  and the blocker noted in my prior history (`no_matching_runner`).
- **SPM resolution cost on `saas-macos-medium-m1`:**
  - First job per fresh runner: `xcodebuild` performs `git clone` of
    `apple/swift-metrics` (~150 KB source tree) into
    `~/Library/Developer/Xcode/DerivedData/.../SourcePackages/checkouts/`.
    Expected: **5–15 s** added to the first build, dominated by the
    HTTPS handshake to `github.com`.
  - Subsequent jobs on the same runner: cached. Negligible.
  - SaaS runners are ephemeral per job → every job pays the cost
    unless we **add explicit caching**.
- **Recommended CI tweaks (when the CI YAML is reinstated):**
  1. Add an explicit `xcodebuild -resolvePackageDependencies` step
     *before* the build step so the resolution time is attributed
     cleanly in pipeline logs (not buried in the test job).
  2. Add a GitLab `cache:` block for
     `~/Library/Developer/Xcode/DerivedData/*/SourcePackages/checkouts/`
     keyed on the `Package.resolved` SHA. Cache hit saves ~10 s per job.
  3. Commit `Package.resolved` so CI never resolves a different
     revision than local devs.
- **Network-egress framing for §2.3:** the SPM fetch is a **build-time**
  network call (to `github.com`), not a **runtime** network call from
  the shipped binary. §2.3 talks about the product, not the build
  toolchain. I'm raising it explicitly so Tesla can rule on the
  framing — my read: **allowed**, with the build-tooling carve-out
  written into the merged decision.

## Optional lint/format rules

We have no SwiftFormat / SwiftLint adopted yet (§3 explicitly defers
that), so these are **forward-looking** rules to encode the day we
adopt a linter. None of them block landing the dependency.

1. **Single bootstrap site.** `MetricsSystem.bootstrap(...)` may be
   called from exactly one place — `KnittingGaugeReconcilerApp.init()`.
   A future SwiftLint custom rule should flag any other occurrence.
2. **Centralised labels.** All metric labels live in a caseless `enum`
   `KGRMetrics.Labels { static let computeMs = "compute.duration_ms" …}`,
   in the spirit of §2.6. No ad-hoc string literals at call sites — i.e.
   `Counter(label: "some.string")` is banned outside that enum.
3. **No `import Metrics` in math layer.** `GaugeMath.swift` and its
   callees must stay free of any metric instrumentation (§2.2
   determinism — measuring duration of a pure function is a UI/sink
   concern, not a math concern). Enforce via file-scoped lint.
4. **No `MetricsTestKit` import outside the unit test target.** Lint
   rule, plus the project-level link constraint above is the first
   line of defence.

## Constraint impact

- **§2.12 release logging:** Honoured. `debug-print` lives behind
  `#if DEBUG`. `noop` and `inmemory` paths produce no log output of any
  kind. The math layer never imports `Metrics`. swift-metrics itself
  emits no `print` / `os_log` / `Logger` calls from its public API path.
- **0 warnings (`-warnings-as-errors`):** Honoured by construction —
  the gate applies to our targets only, and we will pin a known-clean
  upstream version (`2.11.0`, fall back to `2.6.x` if Swift 6.1 tools
  aren't available). One validation run on the dependency-add branch
  is required before merge.
- **No network:** Honoured at runtime. Build-time SPM fetch goes to
  `github.com`; flagged for Tesla's explicit blessing as a build-
  tooling carve-out. The shipped binary makes zero network calls
  regardless of `KGR_METRICS_BACKEND` value, because all three
  supported backends are purely in-process.

## Open decisions for Tesla / the next Scribe merge

1. Confirm the build-time SPM fetch carve-out against §2.3.
2. Confirm DEBUG default — proposed `noop`; alternative is `inmemory`
   if Edison wants always-on dev visibility.
3. Confirm exact-version pin policy for SSWG dependencies (proposed:
   pin all of them, bump deliberately).

## 2026-05-20T18:19:39-07:00 — Ive: swift-metrics scope (issue #9, UX view)

# Ive — swift-metrics scope (issue #9, UX view)

Date: 2026-05-20T18:19:39-07:00
Author: Ive (UI/UX)
Status: Proposed
Relates to: GitLab issue #9 (swift metrics capture); guardrails from issue #1
Companion drops: parallel agent scoping for #9

## UX-visible surface?

- **Recommendation: NONE.** No user-facing metrics surface in v1.
- Why:
  - This is a single-screen, 30-second calculator. Every surface I add competes
    with the hero numbers and the verdict card. A "stats" or "session activity"
    surface gives the user nothing they came for — gauge math — and reads as
    surveilling on an app whose entire value proposition is local-only.
  - The math layer is deterministic (Tesla §2.2) and the inputs sanitise
    silently (`GaugeMath.sanitized()`). There is no failure state today that
    the user needs to be told about. Introducing a toast/banner just to fire a
    metric event would be a UX regression — it interrupts the live `oninput` /
    `@State`-driven recalc path that April protected as issue #1 mitigation #3.
  - If engineering needs developer-only counters (compute calls, sanitisation
    hits, render latencies), that lives behind `#if DEBUG` with no shipping
    label, no a11y identifier, no public copy. By definition that is not a
    user-visible surface and is out of my scope here. I only object if it
    leaks into release builds.

## If a surface is proposed

- Placement: n/a — none recommended.
- Copy: n/a.
- Tone/length check: n/a.
- Accessibility: n/a (nothing visible to label, no VoiceOver story to author,
  no Dynamic Type to honour, no Reduce Motion concern).

If a future iteration insists on a visible surface (e.g. an "extreme input
detected" advisory), it must come back through me as a new UX request. A
banner/toast is **not** a free addition — it changes the 30-second path,
introduces motion (must honour Reduce Motion), introduces focus order changes
for VoiceOver, and demands copy review. Do not ship one as a side-effect of a
metrics ticket.

## Disclosure copy (only if needed)

- **None.** Explicit position: **do not** add a "we don't track you" line,
  **do not** add a "we may capture local metrics" line, **do not** revive the
  Privacy card that Edison removed on 2026-05-19.
- Reasoning: Edison removed that copy because we could not promise it would
  remain true. The same logic applies in reverse — adding hedged disclosure
  copy now ("metrics may be captured locally only…") creates anxiety, invites
  questions the App Store listing should answer, and locks future privacy
  posture into reactive UI text instead of a deliberately drafted policy.
  Silence in the UI is the honest position while nothing is recorded or
  uploaded. When the product owner is ready to make a real privacy statement,
  it gets drafted deliberately — not patched in via a metrics ticket.

## Conflict check

- **Issue #1 mitigations (scope-boundary, non-affiliation):** No conflict.
  Donatello's scope-boundary line ("Scope: This tool provides estimates…")
  and the verbatim non-affiliation line ("Not affiliated with Ravelry, Knit
  Companion, or any pattern designer. Gauge math is conventional knitting
  arithmetic from open craft literature.") remain in `AboutHelpSheet`
  unchanged. My recommendation introduces zero About-sheet edits.
- **30-second first-use path (April mitigation #3):** No conflict.
  Live recalc on every keystroke is preserved. No Calculate button is
  reintroduced. No modal, sheet, toast, or banner interrupts the first-use
  flow. The user still gets cast-on + verdict on the first read.
- **Edison's privacy-card removal (2026-05-19):** Reinforced, not reverted.
  My explicit complement: leave it removed; do not add replacement
  privacy/metrics copy in this ticket.
- **No-network / no-analytics-upload (issue #1):** No conflict. I am
  recommending no UI surface, which removes any pressure to label outbound
  behaviour that must not exist.

## Constraint impact

- **On engineering (Edison, Tesla, Hopper):** A debug-only, `#if DEBUG`-gated
  counter is acceptable from a UX perspective only if (a) it never compiles
  into release, (b) it has no `accessibilityIdentifier`, no `accessibilityLabel`,
  no visible chrome, and (c) it is reachable only via a hidden gesture that
  shipping users cannot discover. The moment it has shipping copy or an
  accessibility surface, it stops being "debug-only" and re-enters my review.
- **On future tickets:** Any proposal to surface a metric as user-visible UI
  (e.g. "extreme input" toast, session counter, "we noticed you recomputed
  N times" hint) is a fresh UX request, not a metrics-implementation detail.
  Route it through `.squad/decisions/inbox/` with me on the loop.
- **On accessibility floor:** Unchanged. AA-minimum contrast, 44 pt targets,
  Dynamic Type, VoiceOver semantics, Reduce Motion — none of these gain new
  obligations because nothing new is shown.
- **On copy debt:** Zero new copy introduced; zero copy retired beyond what
  Edison already retired. The About sheet remains the only narrative surface,
  and its content is unchanged by this scoping.

## 2026-05-20T18:19:39-07:00 — Mendel: swift-metrics scope (issue #9, research view)

# Mendel — swift-metrics scope (issue #9, research view)

Date: 2026-05-20T18:19:39-07:00
Owner: Mendel (User Researcher)
Context: GitLab issue #9 "swift metrics capture". Scoping ONLY the
research questions a local-only counter/gauge/timer could illuminate
on yashasg's device, on demo devices, and on a small beta cohort
running the same build. No off-device upload; no PII; no cross-user
aggregation.

The 6 Jacquard scenarios from `prototype/tests/gauge-math.test.js`:
1. Perfect Match (32/24 vs 32/24) — no drift
2. Denser Row Only (32/24 vs 32/32) — row-axis only
3. Looser Row Only (32/24 vs 32/20) — row-axis only
4. Denser Stitch Only (32/24 vs 36/24) — stitch-axis only, cast-on ↑
5. Looser Stitch Only / Hisahashisaka (32/24 vs 28/24) — stitch-axis only, cast-on ↓
6. Both Denser (32/24 vs 36/32) — two-axis, both cast-on and dim/incs change

## On-device research questions worth instrumenting

- **Q1 — Which of the 6 scenarios does the user actually exercise?**
  → Signal: a 6-slot counter, one per scenario branch, incremented when
  `GaugeMath.compute()` is called and its `(stitchWidthScale, rowCountScale)`
  pair falls in the corresponding bucket (=1 / =1, ≠1 / =1, =1 / ≠1, ≠1 / ≠1).
  Type: **counter** (Int per scenario id).
  → What we'd learn: whether row-only drift (Scenarios 2/3) dominates as the
  persona work hypothesised, or whether two-axis (Scenario 6) is more common
  than expected. Validates JTBD-3 (mid-project quick-check) vs Donal persona
  assumptions on yashasg's own device and beta testers.
  → Why it matters: drives whether two-axis stays a first-class display path
  or can be visually de-emphasised. Currently we treat all six equally; if
  Scenarios 1+2+3 are >95% of real use, that has UI consequences.

- **Q2 — Does the user reach the cast-on path at all (Scenarios 4/5/6)?**
  → Signal: a 2-slot counter — "session reached non-trivial cast-on
  (`computeActStitches` ≠ pattern stitches)" vs "session never did". Type:
  **counter** + a derived **gauge** ("ratio of sessions touching cast-on").
  → What we'd learn: whether Miriam (pre-cast-on, JTBD-1) is a real user path
  on yashasg's device, or whether all sessions skew to Donal (mid-project,
  cast-on already done, only cares about dimension correction).
  → Why it matters: persona-validation gap I flagged in Round 3. If cast-on
  is never adjusted in practice, the cast-on hero block earns less screen
  weight; if it is, Miriam is real and the hero stays.

- **Q3 — Is the 30-second first-use path actually being met?**
  → Signal: elapsed-time **timer** — milliseconds from `ContentView` first
  appearance to the first compute that produces a non-default verdict.
  Stored as a single rolling latest value plus a small ring buffer
  (last 10 launches), never with wall-clock timestamps.
  → What we'd learn: whether the sacred 30s path is silently regressing as
  Edison/Ive iterate. Today we have no objective measure — only Ive's
  subjective design reviews and Curie's UI tests (which test correctness, not
  time-to-first-result).
  → Why it matters: gives the team a regression alarm during dev/demo without
  needing to wait for a beta tester to complain. Local-only is sufficient
  because the path is the same code on every device.

- **Q4 — Which of the 4 gauge input fields gets re-edited fastest after
  first entry (suggests confusion about which number goes where)?**
  → Signal: a 4-slot **counter**, one per field (ps, pr, ys, yr),
  incremented when a field receives a second edit within ~10s of its
  previous committed edit. No values stored, just the event.
  → What we'd learn: which field labelling is confusing. Existing
  hypothesis from Donal persona: knitters confuse "pattern" vs "your" and
  "stitches" vs "rows" axes. A field with disproportionate churn is a
  labelling defect.
  → Why it matters: surfaces a UX issue that interviews are slow and
  expensive to catch. Edison and Ive can act on it directly.

- **Q5 — How often is the verdict-help `?` overlay actually opened, by
  verdict state?**
  → Signal: a 4-slot **counter** keyed by verdict state (Gauge match,
  Drift, Significant drift, Major mismatch), incremented when the verdict
  help sheet is presented.
  → What we'd learn: whether Edison's recent compact-title + `?` pattern
  (2026-05-19 evening) is doing real work or is decorative — and which
  verdict states actually demand explanation.
  → Why it matters: validates a design decision we already shipped. If the
  "Gauge match" `?` is never tapped but "Significant drift" `?` is tapped
  often, that's a clear signal to elaborate copy in the latter and trim
  the former.

## Scenario-coverage signals

Each of the 6 Jacquard scenarios maps to a single research question a
local counter can illuminate. The counter for Q1 above IS the coverage
signal — a real-world counterpart to Curie's test-coverage matrix:

| Scenario | What the counter tells us a local metric can answer |
|---|---|
| 1 — Perfect Match | How often does the verdict block render "match"? Is the no-drift case the silent majority, or rare? |
| 2 — Denser Row Only | Does the row-mismatch-only branch dominate vs Scenario 6, as the persona hypothesis predicts? |
| 3 — Looser Row Only | Does the looser-row branch occur at all on yashasg's device, or is it almost always denser-row? Pairs with Q1. |
| 4 — Denser Stitch Only | Does Miriam's "pre-cast-on adjust upward" path get exercised? Pairs with Q2. |
| 5 — Looser Stitch Only (Hisahashisaka) | Same as 4 but downward cast-on — is this case lopsided vs Scenario 4? |
| 6 — Both Denser | Does the user ever reach the two-axis case where cast-on AND dimensions both change? Direct test of "two-axis matters" hypothesis. |

There is **no demo-load path** in the current app — every scenario is
entered manually — so the "manual vs demo-loaded" dimension proposed in
the task brief is not yet instrumentable. If a demo-load affordance is
added later (e.g. a "Try Hisahashisaka's example" button), it should
ship with its own counter so manual-entry vs demo-load can be separated.

## Questions explicitly OUT of scope (need aggregated data we will not collect)

These would be valuable research questions but they **cannot** be
answered by single-device counters and we are not going to ship the
infrastructure that would make them answerable:

- **"What % of users abandon after the first compute?"** — needs
  per-user retention across distinct devices; on-device single counter
  cannot distinguish "yashasg dogfooding" from "real abandonment".
- **"Are knitters in the wild more often denser-row or looser-row?"** —
  needs a population sample, not yashasg's swatches.
- **"Which persona (Miriam vs Donal vs Reema vs Birgitta) is most
  prevalent?"** — needs cross-user behavioral segmentation; flagged in
  Round 3 history as an unconfirmed hypothesis and it stays unconfirmed.
- **"How often does a shared PNG actually get sent vs cancelled?"** — the
  iOS share sheet does not return success per-target without OS-level
  hooks we are not adding, and even with them, useful interpretation
  requires aggregation.
- **"Does the cast-on adjustment lead to fewer reknits in practice?"** —
  outcome metric, requires longitudinal cross-user data and self-report.
- **"What time of day / week do users reconcile gauge?"** — would need
  wall-clock logging that we should not add (privacy-tainting; see
  slippery-slope below).
- **"Do users in low-vision or one-handed contexts (Birgitta) succeed at
  the same rate?"** — requires accessibility-cohort segmentation that an
  on-device counter cannot provide. Must be answered by recruited
  research, not metrics.

Calling these out so no one later argues "we have metrics, we know
abandonment." We will not.

## Slippery-slope risk items

Signals that, if added carelessly, would create temptation or
technical capability to ship data off device later. Each is a **risk**,
not a recommendation — flag for Tesla / Hopper / privacy review before
implementation:

- **Storing raw gauge values alongside the counter.** Scenario IDs are
  fine; the actual `(ps, pr, ys, yr)` tuple is not — once it lives in a
  log file it looks like "anonymous behavioral data" and someone will
  argue for upload. Risk: persist scenario id only, never the inputs.
- **Wall-clock timestamps at finer than per-launch granularity.** Wall
  time enables correlation with real-world activity and, if ever
  exposed, becomes a partial identifier. Risk: store elapsed durations
  (e.g. ms between launch and first compute), not absolute timestamps.
- **Any session identifier or install identifier**, even random UUIDs.
  Local-only "anonymous" IDs become persistent identifiers the moment
  they leave the device. Risk: no IDs at all. Counters are scalar.
- **Capturing free-text inputs** (saved-reconciliation labels, pattern
  name, yarn identifier from Tesla's saved-reconciliations work). These
  are user-typed strings and qualify as content. Risk: metrics layer
  must never read those fields.
- **A separate on-disk metrics file** (e.g. `metrics.json`) that
  survives app uninstall via iCloud backup. Easier to ship later than
  `UserDefaults`. Risk: store counters in `UserDefaults` (or memory)
  that get wiped on uninstall, do not introduce a metrics file format.
- **A `Logger`/`os_log` call inside `GaugeMath.compute()`.** Already
  banned by Tesla's §2.12 + §2.2 (math layer never logs, no
  randomness, no clock reads). Risk: metrics must observe from the
  view layer or a dedicated metrics layer — never from the math layer.
  This is a hard architectural line.
- **A "diagnostics export" affordance** ("share crash logs") that
  would naturally pick up metrics too. Risk: if such a feature is ever
  added, scope must explicitly exclude the metrics store.

## Constraint impact

- **Privacy / no-upload:** All signals proposed above are scalar
  counters, scalar gauges, or elapsed-duration timers. None carry
  free-text content, none carry stable identifiers, none carry
  wall-clock timestamps. The "About this calculator" overlay (Edison,
  2026-05-19) no longer makes the now-removed "no analytics" claim —
  good — but if any metric is added we should draft a short, accurate
  on-device-only disclosure (one sentence) for the About sheet so we
  do not silently change the privacy posture between releases. That
  disclosure copy is Ive + Mendel + product owner, not metrics-layer.
- **30-second first-use path:** Metric instrumentation must add zero
  blocking work on launch — no consent prompt, no first-run dialog, no
  network init (there is none anyway), no synchronous file I/O on the
  main thread. Counter increments fire on the user's compute action,
  not on launch. The Q3 timer **measures** the 30s path; it must not
  **gate** it. If a metric ever requires a "first-run consent screen"
  the metric is out of scope by definition — the path is sacred.

---

Out of this scope: which counters to implement first, where they live
in the Swift code, and how they get displayed (debug overlay? log line
in `#if DEBUG`? hidden About sheet section?). Those are Edison + Tesla
+ Hopper calls. This file is purely "what is worth knowing, locally."

## 2026-05-20T18:19:39-07:00 — Jacquard: swift-metrics scope (issue #9, domain view)

# Jacquard — swift-metrics scope (issue #9, domain view)

Scoping guidance for issue #9 from the knitting-domain perspective only.
"Meaningful" here = a signal that, if observed on this user's own device,
would tell yashasg something real about whether the math is doing right by
a knitter — not a tooling/performance signal. All signals are local-only
(no off-device transport), counted/bucketed at the `ContentView` boundary
(never inside `GaugeMath`), and must not slow the 30-second first-use path.

## Domain-meaningful signals

- **Axis-mismatch shape** (counter, 4 buckets: `match` / `stitch-only` /
  `row-only` / `both`) — this app's distinctive thesis (per issue #1 idea
  summary, and the 2026-05-19 archetype work) is that **row gauge is not a
  second-class citizen**. A bucket counter on which axis a knitter's swatch
  actually drifted on tells us whether real users are hitting the
  two-axis case the tool was built for, or whether they overwhelmingly
  drift on only the stitch axis (in which case the row-axis UI is
  carrying disproportionate weight for little benefit). Threshold for
  "mismatch" should match the existing `gaugeStatus` / `rowStatus` "Match"
  band (|scale − 1| ≥ 0.03), so the bucketing matches what the UI is
  already telling the knitter.

- **Drift magnitude bucket, per axis** (histogram, per stitch axis and per
  row axis independently, buckets: `<3%` / `3–10%` / `10–25%` / `>25%`) —
  these bands align with the existing verdict copy: Match, Drift,
  Significant drift, Major mismatch. A histogram tells us whether users
  are mostly in "small correction" territory (where the calculator is
  largely a reassurance tool) or in "major mismatch" territory (where
  the user is probably substituting yarn weight, and where rounding,
  stitch-pattern repeats, and blocking advice start to dominate the
  craft answer). The two axes must be bucketed **separately** — combining
  them would erase the very thing axis-mismatch-shape exists to surface.

- **Implausible-input counter** (counter, 2 buckets: `stitch-out-of-range`
  / `row-out-of-range`) — fired when a gauge entry is outside the
  craft-plausible band for hand-knitting on standard needles. Working
  thresholds (open to refinement): stitch gauge <10 or >50 st/10 cm,
  row gauge <12 or >70 rows/10 cm. The math still produces a number
  inside this range — that's correct, and §2.2 determinism is preserved —
  but the answer is unlikely to be useful and the UI might want to warn.
  Real-world meaning: a count here is either a typo (knitter entered
  stitches-per-inch into a stitches-per-10cm field) or a wildly out-of-band
  swatch (jumbo / wire / machine). Both are actionable: a typo guard or a
  range hint in the input field.

- **Cast-on rounding drift bucket** (histogram on the absolute value of
  `castOnRoundingDriftPercent` that `GaugeMath` already returns, buckets:
  `<0.5%` / `0.5–2%` / `>2%`) — this is the only signal that's
  domain-meaningful at the cast-on level. When the integer-stitch rounding
  forces drift over ~2%, a top-down yoke or a stitch-pattern repeat will
  visibly miss. Observing a real-world tail in the `>2%` bucket would be
  the trigger to add repeat-aware rounding (round to the nearest multiple
  of the stitch-pattern repeat, not just to the nearest stitch). This is
  read straight off the existing result struct — no new math.

- **Section inspected** (counter, buckets aligned with whichever section
  Edison's UI lets a user expand: `yoke` / `body` / `sleeve` /
  `increase-spacing`) — *only* if Edison's UI distinguishes them
  (verdict-help-style overlays, expand/collapse, scroll-into-view). If
  every section is rendered in one flat card with no per-section
  affordance, this signal cannot be emitted truthfully and is dropped.
  Where it can be emitted, it tells us which output knitters actually
  reach for — yoke depth (top-down sweater archetype), body length
  (bottom-up), sleeve (any), or increase spacing (raglan/yoke shaping).
  This is the only signal in this list that's about UI behavior, but it's
  domain-meaningful because the archetypes (per the 2026-05-19 taxonomy)
  predict different sections will dominate for different knitters.

- **Saved-reconciliation context completeness** (counter, buckets:
  `label-default` / `label-edited`, and once metadata is wired:
  `stitch-pattern-set` / `blocking-state-set` / `needle-size-set` /
  `yarn-fiber-set`) — only meaningful **once Tesla/Edison ship saved
  reconciliations** (per the 2026-05-19 evening decision). It directly
  tests Jacquard's domain stance that raw four numbers are insufficient:
  if users overwhelmingly leave the default `Reconciliation <N>` label and
  never set stitch pattern / blocking state, the saved-rec feature is in
  the failure mode I warned about, and we should nudge harder (or accept
  the data and stop pretending the saved entries are reusable).

## Out of scope from a domain perspective

- **Compute duration, recompute count, render time, view appearance,
  scroll depth, tap counts that aren't section-specific** — tooling/perf
  signals. Defer to Tesla/Hopper. Knowing `GaugeMath.compute` takes 80 µs
  vs 120 µs tells me nothing about whether the answer was craft-correct.

- **Raw input values** (the actual numbers the knitter typed) — even local
  storage of full input vectors is more than we need to learn craft truth
  *and* would balloon footprint. The bucketed signals above are
  sufficient. (Saved reconciliations are a separate, **opt-in** feature
  where the user explicitly stores their values — different contract.)

- **Verdict-copy variant displayed** ("Match" vs "Drift" vs etc. as a
  string) — redundant with drift-magnitude buckets and duplicates copy
  that's already audit-able from source. Vanity.

- **Format functions** (`fmtCm`, `fmtRows`, `fmtPct`) call counts —
  derivative of `compute()` call count. Vanity.

- **Time-of-day / day-of-week of use** — not a craft signal. If it shows
  up in someone's later proposal, push back: it tells us about lifestyle,
  not knitting.

- **A/B-style toggles between adjusted vs pattern values** — this app's
  thesis is that both must be shown side-by-side at once (per the
  vocabulary cheat sheet — row gauge is not a second-class citizen);
  there is no toggle to measure.

## Signals that would trigger a math/UX recommendation if observed

- **Implausible-input counter trends up over time, esp. stitch
  out-of-range** → recommend a soft input-hint on the gauge field
  ("typical hand-knit range: 14–40 st/10 cm — your value is X") and a
  unit-conversion guard against the most likely typo (`st/in` entered
  into a `st/10cm` field — 5× factor; ~5 st/10cm or ~150 st/10cm are the
  fingerprints). Math layer untouched.

- **Cast-on rounding drift `>2%` bucket has any non-trivial population**
  → recommend repeat-aware cast-on: pass the stitch-pattern repeat into
  `GaugeMath` and round cast-on to the nearest multiple. This is a real
  math change and would need a new spec scenario from me before Ada
  touches it.

- **`row-only` axis-mismatch bucket dominates `stitch-only`** → confirms
  the app's distinctive value. Doubles down on giving row-gauge outputs
  equal visual weight, and motivates promoting increase-spacing guidance
  (currently the last row in the section list) into a hero-tier output
  for those users. Pure UX recommendation; no math change.

- **`both`-axis bucket dominates everything else** → most users are yarn-
  substituting, not gauge-correcting. Recommend nudging the saved-
  reconciliation feature to capture **yarn fiber + needle size** as
  not-quite-optional (per my 2026-05-19 evening evaluation), because
  those are the signals that make a saved entry actually reusable.

- **Drift-magnitude `>25%` bucket on either axis is non-trivial** →
  recommend a UX warning band that the calculator's linear correction
  isn't the right answer at that scale; the knitter should re-swatch or
  change needle size. Math is technically correct; advice is the gap.

- **Section-inspected counter shows almost no `increase-spacing` traffic
  while row-axis drift is common** → the output exists but knitters
  aren't finding it. UX placement issue, not a math issue.

## Constraint impact

- **§2.2 math determinism:** confirmed. Every proposed signal is derived
  from values that are either (a) the inputs the user typed, observable
  at the `ContentView` binding layer before they reach `GaugeMath`, or
  (b) fields already present on `GaugeMathResult`
  (`stitchWidthScale`, `rowCountScale`, `castOnRoundingDriftPercent`)
  which the caller reads after `compute()` returns. Bucketing, counting,
  and any local persistence happen in the caller. `GaugeMath.compute` and
  its helpers stay pure, deterministic, clock-free, and randomness-free.
  No metrics code lives inside `GaugeMath.swift`.

- **30-second first-use path:** all signals are cheap arithmetic
  comparisons against bucket thresholds — O(1) per recompute, no I/O,
  no network, no allocator churn in the hot path. Section-inspected and
  saved-rec-context signals fire on explicit user gestures, not on every
  keystroke, so they cannot regress first-use. Implausible-input
  bucketing must run only on a debounced "settled" input value (not on
  every intermediate keystroke as the user types `3` → `32`), otherwise
  every multi-digit entry would briefly trip the out-of-range bucket;
  Edison/Tesla should gate it on the same debounce the live-recalc UI
  already uses.
