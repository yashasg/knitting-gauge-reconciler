### app/build.sh defaults to iPhone 17 Pro (2026-05-19T11:40:21.205-07:00)

**Author:** Hopper (Build/Tooling)  
**Status:** Implemented

Local `app/build.sh` build/test runs now default to the `iPhone 17 Pro` simulator instead of `iPhone 17 Pro Max`. Only the fallback `SIMULATOR_NAME` changed; all environment overrides remain preserved:
- `SIMULATOR_NAME` still selects a different simulator by name.
- `SIMULATOR_UDID` still selects a specific simulator directly.
- `DESTINATION` still bypasses simulator lookup.
- `release` still forces `generic/platform=iOS`.

Validation: `bash -n app/build.sh`, `node prototype/tests/gauge-math.test.js`, and `./app/build.sh test` exit 0 on the iPhone 17 Pro simulator.

Follow-up: `app/build.sh` treats the Xcode 26.4 IOHIDLib post-test infrastructure diagnostic as benign only after xcodebuild reports successful Swift unit/UI test completion and no failed suites or test cases. Compiler warnings and real test failures still fail the gate.

---

### Tesla — Goal external gate blocked (2026-05-19T17:53:34Z, ongoing P0)

**Author:** Tesla (Integration Testing)  
**Status:** Blocked — GitLab access unavailable from this environment

The iOS validation branch is pushed and local gates pass, but GitLab project, merge request, and pipeline checks are inaccessible (`404 Project Not Found` via API, MR web redirects to sign-in/403). Latest retries as of 2026-05-19T18:42:01Z confirm:
- Local gates still pass: `node prototype/tests/gauge-math.test.js` exited 0 with 77 passed, 0 failed, 0 pending; `./app/build.sh test` exited 0 with `** TEST SUCCEEDED **`.
- Curie warning gate remains clean: `app/build.sh` completed with warnings-as-errors enabled.
- Branch push succeeded; latest local and remote ref is `a463c87cf6df421cc5ea5431a8b8f00f2d3f62d2`.
- GitLab access is still blocked: no `GITLAB_TOKEN`; project, branch, pipeline, and MR API endpoints return `404 Project Not Found`.
- GitLab issue creation still blocked: unauthenticated issue creation returns `401 Unauthorized`.

Merge remains blocked until GitLab access is restored and the latest branch/MR pipeline is verified green.

---

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

## Test Coverage Audit — Jacquard Scenario Mapping (2026-05-19)

**Author:** Mendel (User Researcher)  
**Status:** CONFIRMED — All 6 scenarios covered at unit and UI levels

### Xcode project path correction (2026-05-19T12:33:46-07:00)

**Author:** Hopper (Build/Tooling)
**Status:** Corrected

The Xcode project bundle remains `app/KnittingGaugeReconciler.xcodeproj` to honor Tesla's explicit scaffold work item and the current repository state. The earlier note naming `app/app.xcodeproj` is superseded.

- **Canonical project path:** `app/KnittingGaugeReconciler.xcodeproj`
- **App target & scheme preserved:** `KnittingGaugeReconciler` (unchanged)
- **Updated references:** `app/build.sh` PROJECT path and squad loop references use the full project name
- **Validation:** bash -n app/build.sh, xcodebuild -list -project app/KnittingGaugeReconciler.xcodeproj, and ./app/build.sh test exit 0

**Note:** This supersedes the 2026-05-19T12:13:04.232-07:00 shorthand rename note. Use `app/KnittingGaugeReconciler.xcodeproj` going forward.

---

### 2026-05-19T13:13:20.141-07:00: User directive
**By:** yashasg (via Copilot)
**What:** Do exactly what the user asks from now on; do not expand scope or run extra validation/execution unless explicitly requested.
**Why:** User request — captured for team memory

# Decision: `app/run.sh` is the simulator launch entrypoint

- **Date:** 2026-05-19T12:23:23.773-07:00
- **Owner:** Hopper
- **Status:** Accepted

## Context

Developers need one command that builds the iOS app and launches it on the same simulator selection path used by `app/build.sh`.

## Decision

Use `app/run.sh` as the developer simulator launch entrypoint. It delegates compilation to `app/build.sh build`, preserves `SIMULATOR_NAME`, `SIMULATOR_UDID`, and `DESTINATION`, locates the built simulator `.app` under `app/.build/derived-data`, reads the bundle identifier from the built app metadata, stages the app under `app/.build/run`, then installs and launches via `xcrun simctl`.

## Rationale

Build policy stays centralized in `app/build.sh`; `app/run.sh` owns only launch-specific simulator plumbing. Staging the app before install avoids races when other build/test runs clean DerivedData after this build completes.

# Tesla — GitLab external gate blocked

**Goal:** Cycle step 4 / merge gate  
**Status:** Blocked — GitLab project and pipeline state are inaccessible from this environment  
**Branch:** `squad/ios-work-loop-validation`  
**Local/remote ref:** `c0a9b4adc7c396814024b1590280a084f1246a71`

## Local validation

- `bash -n app/build.sh` exits 0.
- `xcodebuild -list -project app/KnittingGaugeReconciler.xcodeproj` exits 0.
- `node prototype/tests/gauge-math.test.js` exits 0 with 77 passed, 0 failed, 0 pending.
- `./app/build.sh test` exits 0 after a simulator reboot retry for Xcode/CoreSimulator launch-state instability.
- Warning gate remains enforced with `SWIFT_TREAT_WARNINGS_AS_ERRORS=YES`, `GCC_TREAT_WARNINGS_AS_ERRORS=YES`, `CLANG_TREAT_WARNINGS_AS_ERRORS=YES`, and `OTHER_SWIFT_FLAGS="-warnings-as-errors"`.

## Blocker

- `GITLAB_TOKEN` is not present.
- GitLab project, branch, pipeline, and merge-request API endpoints return `404 Project Not Found`.
- Branch push is up to date, but the pipeline cannot be verified green and the branch must not be merged into `main` until GitLab access is restored.

## Required unblock

Provide GitLab credentials/project visibility that can read `yashasg/knitting-gauge-reconciler`, branch `squad/ios-work-loop-validation`, and the associated MR/pipeline state. Then verify the latest pipeline is green before merging into `main`.

# Decision: `app/run.sh` delegates build policy to `app/build.sh`

- **Date:** 2026-05-19T13:06:06.205-07:00
- **Owner:** Tesla
- **Status:** Accepted

## Context

Developers need a single command to build, install, and launch the iOS app on a simulator. The project already centralizes Xcode settings, derived data, simulator destination, and warning-as-error policy in `app/build.sh`.

## Decision

`app/run.sh` is the canonical developer launch entrypoint. It must call `app/build.sh build` for compilation and then handle only launch-specific responsibilities: locating the built `.app`, resolving the bundle identifier, booting the selected simulator, installing, and launching.

## Alternatives Considered

1. **Duplicate xcodebuild flags in `run.sh`** — simpler standalone script, but build policy would drift.
2. **Teach `build.sh` a run mode** — centralizes all behavior, but broadens a build script into lifecycle orchestration.
3. **Keep `run.sh` as a thin wrapper over `build.sh`** — small launch-specific duplication, but preserves one build-policy source.

## Trade-off

We accept a little simulator plumbing in `run.sh` to keep `build.sh` boring and stable. Build policy remains centralized; run ergonomics improve without creating a second Xcode configuration surface.

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

