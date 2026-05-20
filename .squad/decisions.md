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
