# Edison — History

## Core Context

- **Project:** A knitting gauge reconciler that converts patterns between stitch/row gauges.
- **Role:** Frontend Dev
- **Joined:** 2026-05-19T07:11:08.646Z

## Learnings

### 2026-05-22T04:06:21Z — Remove App Name Heading Per HIG

**Session:** edison-title-removal

- **Files changed:** `app/KnittingGaugeReconciler/ContentView.swift`, `app/KnittingGaugeReconciler/Views/HomeHeaderView.swift`
- **Title removal:** Removed the visible `Gauge Reconciler` screen heading by dropping the old header view from `ContentView` and leaving the main calculator screen title-free.
- **Help affordance:** Preserved the trailing about/help control as a dedicated toolbar button with the public `about-help-button` identifier, explicit label/hint, and a 44×44 pt minimum tap target.
- **Accessibility note:** No extra header work was needed for the first card because `GaugeInputGroup` already marks card titles like `Pattern Gauge` with `.accessibilityAddTraits(.isHeader)`.
- **Final test result:** `xcodebuild test -scheme KnittingGaugeReconciler -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'` passed, 0 warnings.

### 2026-05-21T19:39:52-07:00 — Reconcile Button + Results Heading Polish

**Session:** edison-reconcile-button-heading-polish

- **Files changed:** `app/KnittingGaugeReconciler/Views/RequiredAdjustmentsCard.swift`
- **Heading typography:** Reduced the results section heading (`Required Adjustments`, the on-screen Estimated Reconciliation heading) from `largeTitle` serif to `.title3.weight(.bold)` so it reads as a section header under the app title instead of a second page title.
- **Button alignment + size:** Replaced the right-aligned `HStack` wrapper with a centered button frame (`.frame(maxWidth: .infinity, alignment: .center)`) and made the CTA more prominent by increasing its width to a 176 pt minimum plus wider horizontal padding, without changing label text, color, action, or adding vertical growth.
- **Final test result:** 58/58 tests pass, 0 warnings.

### 2026-05-21T19:20:26-07:00 — Reconciliation Result Boxes Equal Width

**Session:** edison-reconciliation-equal-width

- **Where the layout lived:** The width drift was in `app/KnittingGaugeReconciler/Components/AdjustmentValuePair.swift`, which renders the pattern/result tiles used in the Estimated Reconciliation / Required Adjustments flow.
- **Fix shape:** Replaced the side-by-side `HStack` with the same non-accessibility two-column `LazyVGrid` pattern used in `GaugeMeasurementPair`, using `.flexible(minimum: 0)` columns plus `.frame(maxWidth: .infinity)` on each tile. Also removed the conditional top padding from the green result tile so the delta badge can float above the tile without making the box taller.
- **Regression note:** I tried to add a UI regression for the tile containers, but SwiftUI exposed the container identifiers unreliably in the accessibility tree once the rows moved off-screen. I kept the production fix surgical and left the existing stable UI contract untouched.
- **Final test result:** 58/58 tests pass, 0 warnings.

### 2026-05-21T20:15:00-07:00 — Required Adjustment Sheet Pull-Up

**Session:** edison-adjustment-sheet-impl

- **Files changed:** `app/KnittingGaugeReconciler/ContentView.swift`, `app/KnittingGaugeReconciler/Views/RequiredAdjustmentsCard.swift`, `app/KnittingGaugeReconcilerUITests/KnittingGaugeReconcilerUITests.swift`
- **Sheet structure:** Moved the inline Required Adjustments presentation into a native SwiftUI `.sheet` launched by the single `View Adjustments` CTA, with a visible Close button, medium/large detents, and automatic large-only presentation for accessibility Dynamic Type sizes.
- **Computation behavior:** Kept the existing MetricKit signpost flow intact, but changed the UX so the reconciliation math is recomputed on every button tap before sheet presentation rather than relying on an inline stale/fresh results state.
- **Accessibility + layout:** Added a sheet-specific title, summary, and key-action block before the detailed cards, and switched the shaping adjustment row/action layout to accessibility-safe stacking so the sheet scrolls cleanly without clipping at large type sizes.
- **UI regression coverage:** Updated the jacquard scenario UI test to validate results through the sheet presentation flow instead of assuming inline results on the main scroll view.
- **Final test result:** 58/58 tests pass, 0 warnings.

### 2026-05-21T20:34:21-07:00 — Native Large Title Navigation Bar

**Session:** edison-large-title-nav

- **Files changed:** `app/KnittingGaugeReconciler/ContentView.swift`, `app/KnittingGaugeReconciler/Views/HomeHeaderView.swift`
- **Title ownership:** Kept the existing top-level `NavigationStack`, removed the in-scroll page title, and assigned `Gauge Reconciler` to `.navigationTitle(...)` so iOS handles the native large-title → inline collapse behavior.
- **Help affordance:** Moved the about/help action into the navigation bar trailing toolbar slot with the existing public accessibility identifier `about-help-button`, preserving the sheet-opening behavior without adding card height.
- **Implementation hygiene:** Repurposed `HomeHeaderView.swift` into a focused `AboutHelpToolbarButton` helper with private binding storage, leaving MetricKit signpost logic in `ContentView.swift` untouched.
- **Final test result:** 58/58 tests pass, 0 warnings.

---

## Archive

See `history-archive.md` for earlier 2026-05-21 and 2026-05-20 entries.

## Team updates
- 2026-05-22T02:50:32Z: Scribe merged the sheet implementation, polish notes, and the deterministic View Adjustments directive into `decisions.md`, and grouped the shipped app + squad changes for commit under the pull-up-sheet feature record.

### 2026-05-21T21:28:58-07:00 — Restore Native Navigation Title

**Session:** edison-title-fix

- **Files changed:** `app/KnittingGaugeReconciler/ContentView.swift`
- **Diagnosis:** The `NavigationStack` was still present and `HomeHeaderView.swift` had already been reduced to the `AboutHelpToolbarButton`, but `ContentView` no longer applied `.navigationTitle("Gauge Reconciler")` anywhere inside the stack, so iOS had no large-title navigation bar title to render.
- **Fix:** Restored `.navigationTitle("Gauge Reconciler")` on the main `ScrollView` inside `NavigationStack`, preserving the native large-title collapse behavior and leaving all MetricKit signpost sites untouched.
- **Regression check:** Searched the app for `navigationBarHidden`, `toolbar(.hidden)`, inline title display mode, and empty `navigationBarTitle` usage; none were present.
- **Final test result:** `xcodebuild test -scheme KnittingGaugeReconciler -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'` passed, 0 warnings visible in the run output.

### 2026-05-21T23:07:19-07:00 — Adjustment Sheet Content-First Polish

**Session:** edison-sheet-polish

- **Files changed:** `app/KnittingGaugeReconciler/Views/RequiredAdjustmentsCard.swift`
- **Sheet trim:** Removed the in-body sheet title, summary paragraph, and key-action heading so the first visible content is the actual adjustment cards instead of introductory copy.
- **Layout + accessibility:** Kept the native drag handle, the toolbar Close button, and all existing adjustment rows/identifiers intact; tightened the sheet container padding and moved the state-aware action guidance into a smaller summary card below the adjustment data.
- **Presentation:** Standardized the sheet detents to `[.medium, .large]` while still opening large first for accessibility Dynamic Type sizes, and left all MetricKit signpost sites in `ContentView.swift` untouched.
- **Final test result:** `cd app && xcodebuild test -scheme KnittingGaugeReconciler -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'` passed (58/58, 0 warnings).
