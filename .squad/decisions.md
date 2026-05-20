## 2026-05-19

**Ive: Compact iPhone Field Layout Spec**

Numeric inputs on iPhone should use content-appropriate widths (92–112 pt for gauge fields, 96–120 pt for dimension fields, 128–156 pt for cast-on) instead of full-card width. Paired gauge fields and dimension fields can sit on one row when the card has space. Accessibility Dynamic Type triggers fallback to stacked, full-width layout. Fields preserve visible labels and 44×44 pt hit targets.

**Edison: Compact Numeric Fields Implementation**

Numeric inputs now use compact text boxes sized for knitting values. Paired inputs use 140 pt minimum columns. Accessibility Dynamic Type stacks paired inputs and expands to available width. Implementation complete; UI tests updated and passing.

**Ive: Field Grouping Design Spec**

Use nested grouped sections inside the existing gauge card: each logical input group becomes a subtle rounded sub-card on the card surface. Pattern gauge and Your swatch each sit inside one grouped sub-card with 12 pt inner spacing, 14–16 pt container padding, 20–24 pt corner radius, AppTheme.oatmeal background, and 1 pt AppTheme.outline.opacity(0.7) border. Adaptive two-column layout preserved; accessibility Dynamic Type stacks fields vertically within groups. Section titles remain headers with clear VoiceOver reading order. Group visual separation uses structure and shape, not color alone; contrast meets WCAG 2.2 AA.

**Edison: Gauge Field Grouping Implementation**

Implemented Ive's gauge grouping direction with two nested rounded sections inside the existing gauge card: one for Pattern gauge and one for Your swatch. Used InputGroup reusable wrapper with structure, padding, rounded shape, and subtle stroke plus native grouped background. Preserved existing field labels, bindings, identifiers, and compact two-column layout. Implementation complete; UI tests passing.
