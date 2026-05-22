# Edison — History

## Core Context

- **Project:** A knitting gauge reconciler that converts patterns between stitch/row gauges.
- **Role:** Frontend Dev
- **Joined:** 2026-05-19T07:11:08.646Z

## Current Session Learnings (2026-05-22)

- **Dark mode assetization:** Migrating hardcoded RGB colors to named Assets.xcassets unlocks adaptive light/dark appearances and clears `color_literal_rgb` HIG violations. Strategy: keep colors warm and textile-like; backgrounds shift to brown-black, cards lift lighter, semantic accents brighten, texture dots invert to low-opacity light specks.
- **VoiceOver text casing:** Use `.textCase(.uppercase)` instead of `.uppercased()` so VoiceOver reads the source string naturally rather than as an acronym.
- **Touch target + decorative fixes:** 44 pt minimum-height backstops at under-sized sites. Mark context-free SF Symbols as decorative. Hid warning triangles when adjacent text carries full meaning.
- **Title restoration:** App name heading was removed per HIG guidance (utility apps are self-evident), but `navigationTitle` must still be present for accessibility context — restored `.navigationTitle("Gauge Reconciler")` to ScrollView inside NavigationStack.

## Session Summary (2026-05-22)

- **ive-3:** Dark mode color spec delivered (16 tokens, warm palette, asset naming convention).
- **edison-5:** Non-color HIG fixes deployed (4 touch targets, VoiceOver casing, decorative symbols, accessibility trap).
- **edison-6:** AppTheme color assets migration complete (Assets.xcassets created, AppTheme.swift refactored, `color_literal_rgb` violations cleared).
- **Prior sessions:** Sheet polish, spacing tighten, title fix all logged and merged to decisions.md.

## Key Files Touched (2026-05-22)

- `app/KnittingGaugeReconciler/Components/AppTheme.swift` — Migrated to asset-based colors
- `app/KnittingGaugeReconciler/Components/SectionTitle.swift` — `.textCase(.uppercase)` fix
- `app/KnittingGaugeReconciler/Views/ShareableView.swift` — Decorative symbol hiding
- `app/KnittingGaugeReconciler/Views/RequiredAdjustmentsCard.swift` — Touch targets, symbol hiding
- `app/KnittingGaugeReconciler/Sheets/GaugeStepperWheelSheet.swift` — Accessibility trap fix
- `app/Assets.xcassets/` — Created with 16 Color Sets (light/dark appearances)
- `app/app.xcodeproj/project.pbxproj` — Asset catalog registered

## Verification Status

- **Lint:** SwiftLint non-color HIG rules and `color_literal_rgb` both clean (0 violations)
- **Tests:** 58/58 pass, 0 warnings
- **Build:** Succeeds on iPhone 17 Pro Max simulator
- **Blockers:** Pre-existing `AccessibilityAuditTests.swift` main-actor isolation (unrelated)

## See Also

- **Detailed archive:** `history-archive-2026-05-22.md` contains full prior session logs
- **Original archive:** `history-archive.md` from 2026-05-21
- **Decisions:** `.squad/decisions.md` contains all team decisions (merged 12 inbox files)

## Learnings

### 2026-05-22T02:25:03.715-07:00 — Stitchwise App Icon Setup

- **Files changed:** `app/KnittingGaugeReconciler/Assets.xcassets/AppIcon.appiconset/**`, `app/app.xcodeproj/project.pbxproj`
- **Asset packaging:** Generated the full iPhone + App Store icon matrix from the approved 1024×1024 source and added an `AppIcon.appiconset/Contents.json` mapping every required idiom/scale slot.
- **Build setting:** Pointed both Debug and Release at `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;` so simulator builds, TestFlight archives, and App Store uploads resolve the same icon set.
- **Verification:** `xcodebuild -project app/app.xcodeproj -scheme KnittingGaugeReconciler -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' build` succeeds.

### 2026-05-22T02:54:31.478-07:00 — identifier_name lint suppressions

- **Files changed:** `app/KnittingGaugeReconciler/Components/TexturedBackground.swift`, `app/KnittingGaugeReconciler/GaugeMath.swift`, `app/KnittingGaugeReconciler/Components/GaugeStepperField.swift`
- **Decision:** Kept idiomatic short math/loop locals (`x`, `y`, `d`, `i`) and added `// swiftlint:disable:next identifier_name` directly above each declaration instead of renaming them.
- **Targeted verification:** `swiftlint lint --path KnittingGaugeReconciler/Components/TexturedBackground.swift KnittingGaugeReconciler/GaugeMath.swift KnittingGaugeReconciler/Components/GaugeStepperField.swift | grep "identifier_name"` returns no matches.
- **Build verification:** Direct `xcodebuild ... build` succeeds; `bash build.sh build` still reports unrelated pre-existing strict SwiftLint errors in `ContentView.swift`, but no `identifier_name` errors remain.
