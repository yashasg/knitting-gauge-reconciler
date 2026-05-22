# Edison — History

## Core Context

- **Project:** A knitting gauge reconciler that converts patterns between stitch/row gauges.
- **Role:** Frontend Dev
- **Joined:** 2026-05-19T07:11:08.646Z

## Learnings

### 2026-05-22T01:45:35-07:00 — AppTheme Color Assets Migration

**Session:** edison-color-assets-migration

- **Files changed:** `app/KnittingGaugeReconciler/Components/AppTheme.swift`, `app/KnittingGaugeReconciler/Assets.xcassets/**`, `app/app.xcodeproj/project.pbxproj`
- **Theme assetization:** Replaced all structural `AppTheme` RGB literals with named color assets so light and dark appearances now come from the asset catalog instead of inline SwiftUI colors.
- **Texture-dot handling:** Moved the textured background dot opacity into the asset itself (`0.300` light / `0.100` dark), which let `surfaceTextureDot` drop the extra `.opacity(...)` call.
- **Verification:** Filtered `swiftlint lint` is clean for `color_literal_rgb`. `xcodebuild build -scheme KnittingGaugeReconciler` succeeds on `iPhone 17 Pro Max`; the requested `iPhone 16 Pro` simulator destination is unavailable in this environment.

### 2026-05-22T08:50:01Z — Non-color HIG SwiftLint Cleanup

**Session:** edison-hig-code-fixes

- **Files changed:** `app/KnittingGaugeReconciler/Components/SectionTitle.swift`, `app/KnittingGaugeReconciler/Components/AdjustmentValuePair.swift`, `app/KnittingGaugeReconciler/Components/GaugeInputGroup.swift`, `app/KnittingGaugeReconciler/Components/GaugeStepperField.swift`, `app/KnittingGaugeReconciler/Views/ShareableView.swift`, `app/KnittingGaugeReconciler/Views/RequiredAdjustmentsCard.swift`
- **Accessibility text casing:** Replaced `title.uppercased()` with `.textCase(.uppercase)` in `SectionTitle` so assistive tech reads the real string rather than an acronym-like transformed copy.
- **Touch-target cleanup:** Added 44 pt minimum-height backstops at each reported `missing_min_touch_target` site and split exact `.padding(.vertical, N)` calls into equivalent top/bottom padding where the custom SwiftLint regex required it.
- **Image semantics:** Hid decorative SF Symbols from accessibility in header/footer/CTA/status contexts and hid the wheel-sheet warning icon because the adjacent mismatch sentence already communicates the warning.
- **Verification:** Filtered `swiftlint lint` output is clean for the requested non-color HIG rules. Direct `xcodebuild test -scheme KnittingGaugeReconciler -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' -quiet` is currently blocked by pre-existing `AccessibilityAuditTests.swift` main-actor isolation errors unrelated to this pass.

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

### 2026-05-22T00:14:45-07:00 — Main Screen Vertical Spacing Tightened

**Session:** edison-spacing-tighten

- **Files changed:** `app/KnittingGaugeReconciler/ContentView.swift`, `app/KnittingGaugeReconciler/Components/AppTheme.swift`
- **Scroll layout:** Reduced the main card stack spacing from 18 pt to 12 pt and trimmed the scroll content top/bottom padding from 24 pt vertical to 8 pt top / 16 pt bottom so the first card sits much closer to the large navigation title.
- **Shared card chrome:** Tightened the shared `.cardStyle()` inset down to a 12 pt padding so `PatternGaugeCard`, `YourGaugeCard`, and `PatternInstructionsCard` all shrink through the shared wrapper without touching their colors, borders, corners, or internal grid layout.
- **Validation:** `cd app && xcodebuild test -scheme KnittingGaugeReconciler -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'` passed on rerun (58/58, 0 warnings).

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

### 2026-05-21T23:46:07-07:00 — Sheet Title + Share Flow Repair

**Session:** edison-sheet-share-fix

- **Files changed:** `app/KnittingGaugeReconciler/ContentView.swift`, `app/KnittingGaugeReconciler/Views/RequiredAdjustmentsCard.swift`, `app/KnittingGaugeReconciler/Views/ShareableView.swift`, `app/KnittingGaugeReconcilerUITests/KnittingGaugeReconcilerUITests.swift`, `app/app.xcodeproj/project.pbxproj`
- **Sheet navigation:** Restored a real sheet navigation bar by keeping the adjustment content inside its own `NavigationStack`, adding the inline `Adjustments` title, and leaving the toolbar Close action in the natural trailing slot.
- **Share flow:** Moved the public `share-results` affordance into the sheet toolbar and presented `UIActivityViewController` from inside the sheet view hierarchy so share no longer queues behind the existing adjustments sheet.
- **Export image:** Replaced the old live-card snapshot path with a dedicated off-screen `ShareableView` rendered via `ImageRenderer` at a fixed 390 pt width, covering your gauge, pattern gauge, reconciliation metrics, required adjustments, and app branding.
- **Final test result:** `cd app && xcodebuild test -scheme KnittingGaugeReconciler -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'` passed (58/58, 0 warnings).

### 2026-05-22T08:50:01Z — Non-Color HIG SwiftLint Fixes (edison-5)

**Session:** edison-5

- **Files changed:** `app/KnittingGaugeReconciler/Components/SectionTitle.swift`, `app/KnittingGaugeReconciler/Components/GaugeInputGroup.swift`, `app/KnittingGaugeReconciler/Views/ShareableView.swift`, `app/KnittingGaugeReconciler/Views/RequiredAdjustmentsCard.swift`, `app/KnittingGaugeReconciler/Sheets/GaugeStepperWheelSheet.swift`
- **SectionTitle:** Changed `.uppercased()` → `.textCase(.uppercase)` so VoiceOver reads the source string naturally instead of spelling uppercase variant as an acronym.
- **Touch targets:** Added 44 pt minimum-height backstops at 4 under-sized tap-target sites while preserving existing visual padding by splitting vertical padding modifiers.
- **Decorative symbols:** Marked context-free SF Symbols as decorative with `.accessibilityHidden(true)` in `GaugeInputGroup`, `ShareableView`, and `RequiredAdjustmentsCard`.
- **Accessibility trap fix:** Hid the warning triangle in `GaugeStepperWheelSheet` from accessibility because the adjacent mismatch text already carries the full meaning.
- **Left untouched:** `AppTheme.swift` and all color-literal violations per request (waiting for Ive's dark mode spec).
- **Verification:** SwiftLint non-color HIG check returned 0 violations in targeted files. (xcodebuild test blocked by pre-existing `AccessibilityAuditTests.swift` main-actor isolation unrelated to these changes.)

### 2026-05-22T01:57:32Z — AppTheme Color Assets Migration (edison-6)

**Session:** edison-6

- **Files changed:** `app/KnittingGaugeReconciler/Components/AppTheme.swift`, `app/Assets.xcassets/` (created with 16 named Color Sets), `app/app.xcodeproj/project.pbxproj`
- **Strategy:** Migrate all structural `AppTheme` colors from hardcoded `Color(red:green:blue:)` to named `Assets.xcassets` color sets with light/dark appearances.
- **Color Sets created:** 16 named assets using kebab-case naming (e.g., `app-theme-background`, `app-theme-card`, `app-theme-sage`, etc.) mapped 1:1 from Ive's dark mode spec.
- **AppTheme.swift refactor:** Updated every color definition from inline `Color(r,g,b)` to `Color("asset-name")` so SwiftUI automatically adapts light/dark via trait collection.
- **Texture dot handling:** Baked the 0.10 alpha directly into the `app-theme-surface-texture-dot` asset so no runtime `.opacity(...)` modifier is needed.
- **Project integration:** Registered `Assets.xcassets` in `app.xcodeproj` resources.
- **Verification:** SwiftLint `color_literal_rgb` violations dropped to 0. xcodebuild succeeds on iPhone 17 Pro Max simulator. (Requested iPhone 16 Pro unavailable in environment.)
- **Impact:** Clears all `color_literal_rgb` HIG violations and enables full dark mode support with adaptive color per iOS appearance settings.

### 2026-05-22T23:07:19-07:00 — Sheet Polish Summary Update

**Session:** edison-sheet-polish (prior session reference)

- Already logged in prior history; referenced here for context. Trimmed `RequiredAdjustmentsCard` in-body title/intro to surface adjustment rows first, maintained sheet affordances, moved state-aware guidance to smaller summary card, reduced top padding for tighter medium detent.

### 2026-05-22T00:37:32Z — Spacing Tighten

**Session:** edison-spacing-tighten (prior reference)

- Already logged. Reduced ContentView stack spacing (18 pt → 12 pt), trimmed scroll padding (8 pt top / 16 pt bottom), tightened cardStyle inset (12 pt).

### 2026-05-22T04:00:32Z — Navigation Title Restoration

**Session:** edison-title-fix

- Added `.navigationTitle("Gauge Reconciler")` back to main ScrollView inside NavigationStack in ContentView.swift. Confirmed title restoration and zero warnings.

### 2026-05-22T01:59:32Z — Decisions Merged

All decisions from this and prior sessions merged to `.squad/decisions.md` (inbox cleared). Cross-agent context updated in ive/history.md and edison/history.md.

