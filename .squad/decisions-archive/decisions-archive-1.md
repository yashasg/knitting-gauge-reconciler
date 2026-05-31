# Archived Decisions (pre-2026-05-24)

Archived on 2026-05-31. These decisions are older than 7 days.

---

## 2026-05-23T01:01:48-07:00: Hopper — Fastlane Integration — SHIPPED

**Author:** Hopper (Tooling Dev)  
**Date:** 2026-05-23T01:01:48-07:00  
**Status:** SHIPPED on branch `feat/fastlane-from-cocktail`  
**MR:** Draft MR !36  
**Commits:** 472c733, fdee865, abd6c9f, 477759a, de9575a, 914f01f, 537b6cb (ASC auth single-JSON-blob fixup)

### What shipped

Implemented all 5 Fastlane improvements from the cocktail-batch-dilution comparison:

1. ✅ Adopted cocktail's Team ID in `app/fastlane/Appfile`; kept KGR's bundle ID `com.yashasg.KnittingGaugeReconciler`.
2. ✅ Added preflight guard comparing Fastlane `app_identifier` against `project.pbxproj` `PRODUCT_BUNDLE_IDENTIFIER`; aborts release lanes on drift.
3. ✅ Added TestFlight build-number helper; falls back cleanly when current version has no prior TestFlight build.
4. ✅ Switched release auth to App Store Connect API key (env vars: `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_FILEPATH` / `ASC_KEY_CONTENT_B64`).
5. ✅ Ported release-signing hardening: CI temp keychain, optional WWDR import, `match`-derived signing context, manual export wiring.

### CI test shape (active)

The Fastlane CI test shape now follows cocktail's pattern:
- `ci` builds the shared `KnittingGaugeReconciler` scheme and runs tests from that scheme without lane-level `only_testing` filter.
- `test` also runs the scheme-defined test scope.
- The shared Xcode scheme is the source of truth for CI test participation.

### Superseded assumptions

This shipped shape supersedes prior accepted Fastlane CI assumptions:
- Release-config-build / Debug-test split (removed)
- Serial-UI CI policy (removed)
- Canceled-as-failed behavior (removed)

Tesla explicitly approved the override.

### CI env-var contract

**App Store Connect auth:**
- `ASC_KEY_ID`
- `ASC_ISSUER_ID`
- Exactly one of: `ASC_KEY_FILEPATH` or `ASC_KEY_CONTENT_B64`

**Signing / release lanes:**
- `MATCH_PASSWORD`
- `MATCH_KEYCHAIN_PASSWORD`
- Optional: `WWDR_CERT_PATH`
- Existing credentials for `fastlane_hisa` match repository

### Validation notes

- `ruby -c app/fastlane/Fastfile` after each commit (syntax verified)
- No lanes executed in-session (secrets intentionally not configured)
- MR !36 awaiting CI variables from Tesla before merge

---

# Hopper Fastlane Integration — shipped

**Date:** 2026-05-23T01:01:48-07:00  
**Author:** Hopper (Tooling Dev)  
**Requested by:** Tesla (human)


## 2026-05-23T01:01:48-07:00: User directive — Adopt cocktail-batch-dilution Fastlane patterns (all 5 items)

**By:** Tesla (via Copilot)  
**Status:** DIRECTIVE (approved for implementation)

### What

Implement all 5 Fastlane improvements identified in Hopper's cocktail comparison (2026-05-23):

1. **Bundle ID + Team ID contract:** Keep KGR's bundle ID (`com.yashasg.KnittingGaugeReconciler`). Adopt cocktail's Team ID pattern. Add preflight guard comparing Fastlane `app_identifier` against `app.xcodeproj` `PRODUCT_BUNDLE_IDENTIFIER`.
2. **ASC auth:** Switch from Apple ID session flow to App Store Connect API key (env vars: `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_FILEPATH` or `ASC_KEY_CONTENT_B64`).
3. **Build numbering:** Adopt cocktail's "no prior TestFlight build for this version" fallback handler.
4. **CI test shape:** Adopt cocktail's scheme-driven `ci` / `test` lanes. **⚠️ This explicitly overrides prior CI design choices** — Release-config-builds-Debug-tests split, serial UI policy dropped, canceled-as-failed behavior superseded.
5. **Signing hardening:** Adopt cocktail's temp keychain, optional WWDR import, manual signing block.

### Why

Cross-app convergence. The iOS apps should share tooling shape where it makes sense. The CI test choices previously accepted as design were actually workarounds; cocktail's pattern is the better baseline.

### Implementation order (lowest risk first)

1. Bundle ID guard + Team ID swap
2. Build numbering helper
3. ASC API key auth (new env vars required from CI)
4. CI test shape (overrides existing design — commits in this batch supersede prior CI decisions)
5. Signing hardening (final — temp keychain interacts with runner environment)

### Branch

`feat/fastlane-from-cocktail` off `main`. Each item is its own commit. Single MR.

### Secrets Tesla must provide

Before steps 3 + 5 ship:
- App Store Connect API key (ID, issuer ID, key file or base64)
- Match passphrase (if using `match`) or signing-cert env paths

### Affected prior decisions (to be updated post-merge)

- "Release config builds Debug tests" — superseded by item #4
- "Serial UI policy" — superseded by item #4
- "Canceled runs report as failed" — superseded by item #4

---


## 2026-05-23T01:00:00-07:00: Hopper — Fastlane Integration Plan (read-only analysis)

**Author:** Hopper (Tooling Dev)  
**Date:** 2026-05-23T00:00:00-07:00  
**Status:** PROPOSAL (no changes made, analysis only)

Hopper performed a read-only comparison of KGR's Fastlane setup against Tesla's external `cocktail-batch-dilution` Fastlane configuration. No edits were made to either project during this analysis.

### Summary

The external app's Fastfile adds substantial release-hardening that KGR lacks:
- App Store Connect API key auth (vs current Apple ID session-based flow)
- CI-only temp keychain setup and optional WWDR import
- Explicit signing-context extraction from `match`
- Release bundle-ID validation against Xcode project
- Build-number fallback logic for new-version uploads
- Shared `build_release_artifact` helper reducing duplication in `beta`/`release` lanes

CI lanes are structurally similar except the external app uses scheme-driven test selection and app-specific `trial_override` arguments (not applicable to KGR).

### Key differences

| Aspect | KGR | cocktail-batch-dilution | Recommendation |
|--------|-----|------------------------|-----------------|
| ASC auth | Apple ID session | API key + JSON | **WORTH STEALING** |
| Bundle-ID safety | No preflight check | `ensure_release_configuration_matches` | **WORTH STEALING** |
| CI signing | Inline `match` only | Temp keychain + optional WWDR + manual export | **WORTH STEALING** (selective pieces) |
| Build-number fallback | `latest_testflight_build_number(...)+1` | `next_testflight_build_number_for_release` with fallback | **WORTH STEALING** |
| Plugin layer | None | `fastlane-plugin-versioning` | Optional; KGR lacks `CURRENT_PROJECT_VERSION` |
| Appfile team_id | `team_id("YOUR_TEAM_ID")` placeholder | Omitted | **CONFLICTS** — KGR's placeholder is deliberate |
| CI test structure | Explicit `only_testing` filter in lane | Scheme-driven, no lane filter | **CONFLICTS** — KGR's explicit scoping is intentional |

### Proposed integration sequence (if approved)

1. Bundle-ID preflight guard (safest, isolated)
2. ASC API key auth + explicit lane plumbing
3. Build-number fallback helper
4. (Deferred) Plugin-backed Xcodeproj versioning
5. (Deferred) CI release-signing hardening

**Tesla decision required:** Appetite for adopting these improvements and handling new secret-store wiring for ASC API key.

---


## 2026-05-22T19:27:12-07:00: Tesla directive — Retire prototype-parity heuristic

**Status:** Applied directly to charters per Tesla (Lead) charter authority

### Charter edits applied

**Edison charter:** Added "The app is the source of truth. `prototype/` is archival/sketch only — not a UI, hierarchy, copy, or interaction spec. Drift audits are against `.squad/decisions.md` and Tesla directives, never against the prototype."

**Ive charter:** Added "The app is the source of truth. `prototype/` is archival/sketch only — not a UI, hierarchy, copy, or interaction spec. Drift audits are against `.squad/decisions.md` and Tesla directives, never against the prototype."

**Curie charter:** Added "The app is the source of truth. `prototype/` is archival/sketch only, except for the sanctioned §2.9 use of `prototype/tests/gauge-math.test.js` as a gauge-math test-vector reference. Drift audits are against `.squad/decisions.md` and Tesla directives, never against the prototype." (Note: This carveout is withdrawn by 2026-05-22T19:39:36-07:00 directive below.)

**Jacquard charter:** Added "The app is the source of truth. `prototype/` is archival/sketch only — not a UI, hierarchy, copy, or interaction spec. Drift audits are against `.squad/decisions.md` and Tesla directives, never against the prototype."

**Ralph charter:** Added "The app is the source of truth. `prototype/` is archival/sketch only — not a UI, hierarchy, copy, or interaction spec. Reject or bounce issues whose rationale is primarily a prototype diff; drift audits are against `.squad/decisions.md` and Tesla directives, never against the prototype."

### Follow-up — 2026-05-22T19:39:36-07:00

Per directive 2026-05-22T19:39:36-07:00, the Curie §2.9 carveout for `prototype/tests/gauge-math.test.js` as a sanctioned test-vector source is **withdrawn**. Curie's scenario-coverage rule is re-anchored to Jacquard-defined craft scenarios sourced from Jacquard's charter and `.squad/decisions.md`. `docs/swift_coding_standards.md` §2.9 is updated accordingly.


---

### 2026-05-22T21:30:00-07:00: User directive — Remove VerdictCard from main UI
**By:** Tesla (via Copilot)
**What:** Tesla rejected the VerdictCard (the verdict copy area: "Perfect match" / "Slight drift" / "Significant drift" / "Major mismatch"). Remove from ContentView. The verdict logic, math tiers, and the underlying `Verdict` enum may stay in the model for now (other surfaces or future use), but the on-screen card goes.

**Why:** Visual quality / hierarchy. Same family of rejection as the hero tiles on 2026-05-22T19:23 — Tesla doesn't want this prominent verdict copy on the main screen. The card was added in MR !35 (commit dfb92c2) and partially survived the hero-tile revert because that revert explicitly kept VerdictCard. This directive completes the rollback of MR !35's main-screen additions.

**Implication:**
- ContentView no longer renders VerdictCard.
- Verdict math/types (`majorMismatch` tier, `Verdict` enum, `verdictTitle` computed property) stay in the code for ShareableView export and future use.
- This is now a **second instance** of the same pattern: prototype-parity sweep produced a UI addition Tesla didn't want. Reinforces the 2026-05-22T19:25 "UI changes need Tesla sign-off" rule.

---

### 2026-05-22T21:30:00-07:00: Edison — VerdictCard main-screen revert

**Requested by:** Tesla (human)

**What:** Removed the `VerdictCard(...)` call site from `app/KnittingGaugeReconciler/ContentView.swift`, completing the rollback of MR !35's always-visible main-screen additions after the earlier hero-tile revert.

**Kept:** `Verdict` math/types/tiering remain intact (`GaugeMathMetrics.swift` including `majorMismatch`, plus ContentView verdict computed properties/signpost logic). `app/KnittingGaugeReconciler/Views/VerdictCard.swift` stays in the codebase.

**Share/export note:** `ShareableView` still compiles after the revert and does not currently instantiate `VerdictCard`; the preserved view file is retained for export-related/future verdict presentation rather than main-screen placement.

**Why:** Tesla rejected the always-visible verdict copy on hierarchy/visual-quality grounds. Do not add prominent cards to `ContentView` without explicit Tesla sign-off.

---

# 2026-05-22T21:30:00-07:00: Ive — VerdictCard Rejection Postmortem

**Author:** Ive (UI/UX Designer)  
**Status:** Postmortem (VerdictCard removed)  
**Trigger:** Tesla directive rejecting VerdictCard from main screen; same design family as hero-tile rejection 2 hours earlier.

---


## 2026-05-22T19:23:34-07:00: Ive — Hero tile design rationale and postmortem

**Author:** Ive (UI/UX Designer)
**Status:** Postmortem (tiles removed)

### What the Hero Tiles Were Showing

The hero tiles displayed two percentage metrics in a 2-column grid on the main screen:
- **Stitch-wise (horizontal):** `stitchWidthScale × 100` — e.g., "100%", "95%"
- **Row-wise (vertical):** `rowCountScale × 100` — e.g., "75%", "120%"

Each tile paired the percentage with a semantic status badge ("Match", "Denser than pattern", "Looser than pattern") and occupied ~110pt of height. The prototype positioned them immediately after the gauge input cards and *before* the verdict paragraph, creating a visual hierarchy: inputs → scale metrics → narrative judgment.

### Information Hierarchy Rationale from the Prototype

The prototype logic was: **diagnostic numbers first, human-readable verdict second.** The percentages serve as numerical precision (useful for pattern designers or experienced knitters who think in scale ratios), while the verdict card supplies narrative context ("Your row gauge is 33% denser — every vertical section will come out shorter"). By surfacing both, the prototype aimed to serve two user types: precision-focused and narrative-focused.

However, this ordering assumes the knitter will *read and understand* the percentages before the verdict explains what they mean. The prototype's small-screen, left-to-right flow naturally cascades visual attention downward, so the order worked defensibly there.

### Prototype-to-iOS Hierarchy Drift (Issue #46)

The iOS implementation initially *reversed* the hierarchy: the hero tiles were surfaced only inside `ShareableView` (the export/results screen), appearing *after* the verdict card and the per-section adjustments. This was an accidental hierarchy inversion — the diagnostic numbers ended up as trailing detail rather than primary context.

Commit `dfb92c2` corrected this by wiring `HeroTilesView` into `ContentView`, restoring the prototype order: inputs → heroes → verdict. The change achieved prototype parity on information order.

### Why "Prototype Parity" Alone Predicted Tesla's Reaction

The flaw in reasoning: **achieving prototype parity without a product gut-check.** The prototype's hero-first ordering is defensible on a web form with unlimited scrolling, but it relies on assumptions that don't hold in iOS HIG practice:

1. **Percentages are diagnostic, not actionable.** The knitter does not *do* anything with "75%". They use the verdict ("your row gauge is denser") to *decide* whether to adjust row counts. The percentage is machine-readable precision; the verdict is human-actionable instruction. Leading with a diagnostic number delays the actionable insight.

2. **Clinical tone in a textile context.** A knitting pattern is a craft artifact with narrative voice ("cast on with waste yarn," "knit until the yoke measures 20 cm"). Surfacing large percentage readouts in a grid format reads like a diagnostic report, not a knitting tool. The design carries unintended authority (cold, mechanical) instead of the craft-aligned tone the verdict card establishes.

3. **No screen-space tradeoff analysis.** On the prototype (browser, arbitrary height), the tiles are "free." On iPhone, every 110pt of hero tiles competes with input fields and verdict copy for above-the-fold placement. The prototype never faced the real estate pressure that makes iOS designers evaluate every surface ruthlessly.

4. **Percentage isn't the user's primary question.** User research affirms the primary question is: "Is my gauge close enough to knit the pattern?" (verdict) or "How many rows should I knit?" (adjustments). The secondary curiosity is "By how much am I off?" — which the percentage addresses, but that's not the first thing a knitter needs to know.

### Signals That Should Have Triggered a Design Review

- **Information order mismatch:** Why are diagnostic numbers prioritized over actionable judgment in a craft tool? Run this against HIG principles for iOS utilities (Calculator shows the result, not intermediate precision metrics; Compass shows the heading, not the raw magnetic-field vector).
- **Knitter mental model:** Consult domain expertise (Jacquard) on whether percentages are a natural entry point for someone reading a pattern. The answer is likely "no — a knitter sees 'denser' first, then asks 'by how much?' on demand, not the reverse."
- **Vertical real estate:** On iPhone, measure the actual height cost of hero tiles on the default input state. Does it push the verdict card below the fold? If yes, the hierarchy is inverted by layout pressure, not information importance.
- **Copy tone:** Hero percentages stripped of narrative context feel like a diagnostic screen, not a knitting assistant. The verdict card's conversational tone ("Your stitch gauge matches the pattern, but your row gauge is 33% denser than expected") establishes the app's voice — percentages should integrate into that voice, not compete with it.

### Alternative: Percentages in Context (Not as Standalone Tiles)

Now that the hero tiles are removed, the percentages should migrate to where they will be *requested* by the knitter, not forced on them:

1. **Inline in the verdict copy** (preferred): Integrate percentages into the narrative verdict. Example: "Your stitch gauge matches the pattern (100%), but your row gauge is 33% denser than expected (75%)." This keeps the number paired with its meaning and respects the action-first information order.

2. **Accessibility disclosure:** VoiceOver users who need precision metrics can access them through expanded accessibility labels on the verdict card. Example: `accessibilityLabel: "Row gauge 33% denser than pattern, you hit 32 rows per 10cm, pattern expects 24 rows per 10cm."` This surfaces precision for users who explicitly ask (AX navigation) without cluttering the visual hierarchy.

3. **Optional detail sheet** (if future research affirms demand): Add a "See details" disclosure button on the verdict card that opens a sheet with a breakdown: "Pattern asks: 24 rows/10cm (100%), You hit: 32 rows/10cm (133%), Scale: 133% of pattern = 33% denser." This defers the diagnostic numbers until the knitter explicitly requests them, honoring the narrative-first reading path.

4. **Export/Copy surfaces:** The "Copy results" menu (TSV, Markdown, CSV, HTML) can include full precision metrics without cluttering the main screen. Knitters who want to log their results in a spreadsheet or forward them to a pattern designer get the numbers there.

### Lesson for Future Prototype-Parity Work

**Prototype parity is not an end state; it's a starting point.** Achieving visual and structural alignment with a prototype is valuable for testing core mechanics, but it must be validated against:
- **Platform conventions** (iOS HIG single-screen utilities do not lead with diagnostic detail).
- **Domain mental models** (knitters think in actions—cast on, knit, adjust—not percentages).
- **Actual real-estate tradeoffs** (web prototypes don't face mobile vertical pressure).
- **Information hierarchy first principles** (actionable instruction before diagnostic precision).

A design review gate should ask: *"Why does the user encounter this information at this moment?"* If the answer is "because the prototype put it there," that's not a sufficient rationale. If the answer is "because the user needs it to make a decision," then integrate it into the decision-making flow, not as a parallel visual track.

**Signed:** Ive (UI/UX Designer)

---


## 2026-05-22T19:23:34-07:00: Edison — Hero tile revert

- **Requested by:** Tesla
- **Decision:** Revert the always-visible HeroTilesView stitch/row percentage tiles from `ContentView`.
- **Scope:** Keep `VerdictCard` on the main screen. Keep `HeroTilesView.swift` on disk, but remove its main-screen wiring. Hero percentage presentation remains live in `ShareableView` export output only.
- **Verification:** `./app/build.sh build` succeeds warning-free when run with an explicit simulator destination override; `./app/build.sh test` currently reports 59 passed / 5 failed, with failures matching pre-existing UI coverage outside the hero-tile scope.

---


## 2026-05-22T19:39:36-07:00: User directive — Squad looks ahead. Prototype is irrelevant, not a test oracle.

**By:** Tesla (via Copilot)

**What:** Extends the 2026-05-22T19:27:12 "prototype is not the spec" directive. The squad's orientation is forward, toward the finished app. The prototype is a proof of concept, period. **It is not a reference, not a test oracle, not an authority for any decision.** Tesla does not care whether the prototype passes its own tests, whether the app's behavior matches the prototype's, or whether prototype-defined scenarios are mirrored in Swift.

**Specifically supersedes / corrects the earlier carveout for Curie §2.9:**

- The previous "prototype/tests/gauge-math.test.js test-vector reference" carveout is **withdrawn**.
- Curie §2.9 must be rewritten to source test vectors and scenario coverage from Jacquard's domain decisions and `.squad/decisions.md` — NOT from `prototype/tests/gauge-math.test.js`.
- Any existing "every Jacquard scenario in prototype/tests has a matching Swift test" language is removed. The standard becomes: every Jacquard-defined craft scenario (sourced from Jacquard's charter / decision drops) has a matching Swift test.

**Forward-looking orientation rules:**

1. **Roadmap thinking:** When planning work, the question is "what should the app do next" — not "what gaps exist vs the prototype."
2. **Loop input sources:** Work-loop inputs are (a) Tesla-stated requests, (b) decisions.md, (c) Jacquard's domain knowledge, (d) real bugs found through testing or use. Never a prototype diff.
3. **Archival treatment:** `prototype/` is archival. No agent reads it as part of their normal loop. If an agent needs historical context for math behavior, they read `.squad/decisions.md` first — only fall back to `prototype/` if a decision explicitly references it.
4. **No prototype audits, full stop.** No "sweeps," no "parity checks," no "drift reviews against the prototype." The pattern is fully retired.

**Follow-up actions Tesla (Lead agent) must execute after current charter purge:**
- Strip the §2.9 prototype/tests carveout from Curie's charter.
- Rewrite §2.9 to reference Jacquard scenarios sourced from team memory, not from `prototype/tests/`.
- Update `docs/swift_coding_standards.md` if §2.9 lives there.
- Verify no other agent charter references prototype as a test/spec authority.

---


## 2026-05-22T19:27:12-07:00: User directive — Prototype is NOT the spec. App is the source of truth.

**By:** Tesla (via Copilot)

**What:** The `prototype/` directory is a one-day sketch built to prove the gauge math. It is NOT a spec, NOT a design reference, and NOT a parity target. The iOS app is the finished product. The app has weeks of domain decisions, accessibility work, HIG conformance, real-device testing, and explicit Tesla/Ive sign-offs (e.g., the cm→rows correction) layered on top of the prototype. **Diffing the app against the prototype to find "drift" is regression — it means undoing improvements.**

**Rules going forward:**

1. **No more "final-review parallel sweeps" against the prototype.** That pattern is retired. Agents must not file drift issues whose evidence is "prototype has X, app doesn't" or "prototype hierarchy is Y, app's is Z." Those are not bugs.
2. **The prototype's role is limited to:** (a) historical context when investigating math behavior; (b) archival reference only. **That's it.** Not UI. Not hierarchy. Not copy. Not interaction model.
3. **The app's `ContentView`, screens, hierarchy, copy, and interaction model are the spec.** If anything looks like it needs to change, the gate is: does Tesla want it? Not: does the prototype have it?
4. **Drift reviews, if they happen at all, audit the app against `.squad/decisions.md` and Tesla-stated requirements** — never against the prototype.
5. **`prototype/index.html` should be considered read-only / archival.** No agent edits it. No agent treats new prototype additions as authority. If someone needs to change knitting math, they amend a decision, not the prototype.

**Charters to amend:** Edison, Ive, Curie, Jacquard (their charters or recurring loop prompts likely contain prototype-parity heuristics). Tesla (Lead) owns the amendment pass.

**Loop scope change:** Ralph's auto-pickup queue must reject issues whose body is essentially a prototype diff. Any such issues already filed (#44 hero tiles, #46 information hierarchy) are invalidated as work items — they exist only as artifacts of the misframe, not as bugs to fix.

**Why this matters:** Combined with "Ralph, go — merge if green," the prototype-parity heuristic created an auto-approval pipeline for regressing the finished app back toward an unfinished sketch. The hero stitch/row tiles incident on 2026-05-22 is the canonical example. This rule prevents the next one.

---


## 2026-05-22T19:25:30-07:00: User directive — Tesla sign-off required for visible UI/UX changes

**By:** Tesla (via Copilot)

**What:** Any change to the visible main UI (adding/removing components from ContentView, hierarchy changes in the primary screen, new prominent visual elements) requires explicit Tesla sign-off recorded in decisions.md BEFORE implementation. Self-filed drift reports from Edison/Ive against the prototype are NOT sufficient authorization — prototype parity is a heuristic, not a license to ship UI changes.

**Why:** Tesla learned on 2026-05-22 that the hero stitch/row % tiles were added to the main screen via auto-loop pickup of issues #44 (Edison) and #46 (Ive), with no human approval gate. Tesla was satisfied with the prior design and would have rejected the change had it been surfaced.

**Rule going forward (Coordinator enforces):**

1. Before dispatching any agent for work that modifies the visible primary UI (ContentView, top-level screens, navigation, hero areas), the Coordinator MUST surface the proposed change to Tesla in plain language and wait for explicit approval.
2. Issues self-filed by squad members during "final-review sweeps" against the prototype count as PROPOSALS, not as approved work. They cannot be auto-picked up by Ralph for implementation if they touch main UI.
3. Ralph loop scope for "auto-merge if green" excludes visible UI changes — those always pause for Tesla.
4. Backend, tooling, tests, accessibility fixes, warning cleanup, and bug fixes that don't change visible layout remain auto-pickup-eligible.

**Affected lanes:** Edison, Ive (UI-side), Coordinator routing logic. Tooling/test/algo work (Hopper, Curie, Ada, Jacquard, Mendel) unchanged.

---


## 2026-05-22T19:23:34-07:00: User directive — No hero stitch/row % tiles on main screen

**By:** Tesla (via Copilot)

**What:** Tesla rejected the new HeroTilesView (stitch-width-scale % and row-density-scale % large-format tiles) added on the main screen by MR !35 (commit dfb92c2). Tiles are to be removed from ContentView. Issues #44 and #46 fix paths are reversed for the hero-tile portion; the verdict-card hierarchy fix may stay pending separate review.

**Why:** Visual quality — Tesla judged the tiles inappropriate for the main UI. Prototype parity is not by itself sufficient justification for surfacing these numbers prominently.

**Implication:** Hero stitch/row % readouts remain reachable only via the "Show full math" disclosure and the share/export image (ShareableView). Do not re-add to the always-visible main scroll without explicit Tesla sign-off.

---


## 2026-05-22T10:40:00Z — Edison: Inline mismatch badge

- **Date:** 2026-05-22T10:40:00Z
- **Author:** Edison
- **Area:** SwiftUI / gauge input affordances

**Decision:** Replace the red triangle mismatch indicator with a slim inline capsule badge that reads `mismatch detected` beside the `Stitches` and `Rows` labels.

**Why:** The floating triangle read like a generic alert glyph rather than field metadata. Inline placement makes the mismatch state immediately attributable to the specific measurement label. A compact pill preserves emphasis without introducing a chunky, button-like control.

**Implementation notes:** Badge styling: `.caption2.weight(.semibold)`, cream text, mismatch-red background, compact 8pt horizontal / 3pt vertical padding, `Capsule()` clipping. The same mismatch conditional logic remains in place; only the visual treatment changed. The wheel picker sheet header uses the same inline badge treatment while retaining the existing explanatory summary text below.

**Verification:** `cd app && bash build.sh build 2>&1; echo "EXIT: $?"` → Result: `EXIT: 0`



## 2026-05-22T03:48:45-07:00 — Edison: Delta pill mismatch indicator

- **Date:** 2026-05-22T03:48:45-07:00
- **Author:** Edison
- **Area:** SwiftUI / gauge input affordances

**Decision:** Replace the inline `mismatch` capsule beside `Stitches` and `Rows` with a signed numeric delta pill that shows `patternValue - userValue` (for example `+2` or `-2`).

**Why:** The numeric delta communicates the exact gauge difference at a glance while preserving the compact, non-growing inline treatment the user already approved.

**Implementation notes:** Keep the existing capsule styling (`.caption2.weight(.semibold)`, cream text, mismatch-red background, 8pt horizontal / 3pt vertical padding, `Capsule()` clipping). Only render the pill when the values differ. Continue exposing the full mismatch sentence through accessibility and the wheel-sheet warning summary; only the visual pill text changes.

**Verification:** `cd app && bash build.sh build 2>&1; echo "EXIT: $?"` → `EXIT: 0`


## 2026-05-22T04:17:35-07:00 — Edison: Delta pill final shape & color (supersedes circular olive spec)

- **Date:** 2026-05-22T04:17:35-07:00
- **Author:** Edison (recorded by Scribe)
- **Area:** SwiftUI / gauge input affordances
- **Supersedes:** The inbox proposal `edison-pill-style.md` (circular 32×32, olive `app-theme-delta-pill` color asset) — never shipped.

**Decision:** Final implemented form of the signed mismatch indicator is a **capsule** badge filled with the existing warm-brown `AppTheme.secondary` tone (aliased as `AppTheme.deltaPill = secondary`), white `.caption2.weight(.semibold)` text, 8pt horizontal / 3pt vertical padding. Rendered only when `patternValue != userValue`.

**Why:** Three iterations were attempted on top of the circular olive proposal: (a) the circular shape pushed the adjacent text field down because the 32×32 frame exceeded the inline label baseline; (b) the bespoke `app-theme-delta-pill` color asset duplicated tokens already covered by `AppTheme.secondary`. Collapsing the badge back to a capsule and reusing the existing secondary brown removed the layout regression and shrank the palette surface area.

**Implementation notes:**
- `DeltaPillBadge` in `app/KnittingGaugeReconciler/Components/GaugeStepperField.swift` uses `.clipShape(Capsule())` with `.fixedSize(horizontal: true, vertical: false)` so wide labels like `+10` extend horizontally without wrapping.
- `AppTheme.deltaPill` is now a semantic alias of `AppTheme.secondary`; no standalone color asset is required.
- Component is reused in the field header, wheel-picker header, and adjustment summary delta for consistency.

**Verification:** Commits `bde2d87`, `80f14b8`, `673a578`, `3c48771` on `main`. Latest `bash app/build.sh build` → `EXIT: 0`.

---


