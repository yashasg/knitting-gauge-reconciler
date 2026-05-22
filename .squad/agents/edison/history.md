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

### 2026-05-22T03:02:54.927-07:00 — ContentView line_length fix

- **Files changed:** `app/KnittingGaugeReconciler/ContentView.swift`
- **Change:** Wrapped six long user-facing string literals in concatenated multi-line forms so the text stays identical while meeting the strict 200-character `line_length` cap.
- **Verification:** `cd /Users/yashasgujjar/dev/knitting-gauge-reconciler/app && bash build.sh build 2>&1; echo "EXIT: $?"` now ends with `EXIT: 0` and no `error:` output.
- **Decision:** Treat `bash build.sh build` as the required source of truth for frontend build verification instead of running `xcodebuild` directly.

### 2026-05-22T03:16:40.823-07:00 — App icon background removal

- **Files changed:** `app/KnittingGaugeReconciler/Assets.xcassets/AppIcon.appiconset/icon-1024.png` + all 8 derived sizes
- **Tool used:** `rembg[cpu]` (ML-based u2net model) for clean separation of knitting design from cream/white background. No manual tolerance-tuning needed — model handled the gradient background correctly.
- **Result:** Corner (0,0) = `(0,0,0,0)` (transparent), center (512,512) = `(128,124,48,255)` (opaque olive/design pixel).
- **All sizes regenerated:** icon-20@2x, icon-20@3x, icon-29@2x, icon-29@3x, icon-40@2x, icon-40@3x, icon-60@2x, icon-60@3x all re-derived from cleaned 1024px source via PIL LANCZOS resize.
- **Apple note:** The 1024px App Store marketing icon is left transparent per user request; App Store Connect may require a solid background at submission time.
- **Build verification:** `bash build.sh build` exits 0.

### 2026-05-22T03:21:32.372-07:00 — App icon replaced with sweater illustration

- **Files changed:** `app/KnittingGaugeReconciler/Assets.xcassets/AppIcon.appiconset/icon-1024.png` + all 8 derived sizes
- **Source:** `/Users/yashasgujjar/Downloads/ChatGPT Image May 22, 2026 at 02_19_13 AM.png` (974×972 RGBA, cream turtleneck sweater on solid blue background)
- **No background removal needed:** Source image already has a proper solid blue background; rounded corners are baked into the image as transparent pixels at the extremes — iOS will apply its own corner mask at render time.
- **All sizes regenerated:** PIL LANCZOS resize from RGBA source to all required icon sizes.
- **Build verification:** `bash build.sh build` exits 0.

### 2026-05-22T03:27:26.322-07:00 — Pattern instructions title hierarchy fix

- **Files changed:** `app/KnittingGaugeReconciler/Views/PatternInstructionsCard.swift`
- **Typography:** Promoted the header from the legacy uppercase `SectionTitle` treatment to the same `.title2.weight(.bold)` title styling used by the Pattern Gauge and Your Gauge cards.
- **Overflow handling:** Added `.minimumScaleFactor(0.7)` with a single-line constraint so “Pattern Instructions” shrinks before wrapping.
- **Verification:** `cd /Users/yashasgujjar/dev/knitting-gauge-reconciler/app && bash build.sh build 2>&1; echo "EXIT: $?"` returned build success.

### 2026-05-22T03:40:00.414-07:00 — Inline mismatch badge replaces triangle indicator

- **Files changed:** `app/KnittingGaugeReconciler/Components/GaugeStepperField.swift`
- **UI treatment:** Replaced the red warning triangle on mismatched gauge fields with a slim inline capsule badge reading `mismatch detected`, positioned beside the `Stitches` / `Rows` labels so the warning reads as metadata instead of a floating icon.
- **Consistency:** Applied the same capsule treatment in the wheel picker sheet header while preserving the existing mismatch summary copy and accessibility messaging.
- **Verification:** `cd /Users/yashasgujjar/dev/knitting-gauge-reconciler/app && bash build.sh build 2>&1; echo "EXIT: $?"` returned `EXIT: 0`.

## 2026-05-22 — Inline Mismatch Badge UI

- Replaced red triangle mismatch indicator with slim capsule badge ("mismatch detected") inline with Rows/Stitches labels
- Badge: `.caption2.weight(.semibold)`, cream text, mismatch-red bg, 8pt H / 3pt V padding, Capsule clipping
- Build: `EXIT: 0`
- Commit: dafd057

### 2026-05-22T03:46:18.853-07:00 — Mismatch badge single-line fix

- **Files changed:** `app/KnittingGaugeReconciler/Components/GaugeStepperField.swift`
- **UI fix:** Shortened the inline capsule label from `mismatch detected` to `mismatch` and enforced `.lineLimit(1)` plus `.fixedSize(horizontal: true, vertical: false)` so it stays on one line.
- **Verification:** `cd /Users/yashasgujjar/dev/knitting-gauge-reconciler/app && bash build.sh build 2>&1; echo "EXIT: $?"` completed successfully.
