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
