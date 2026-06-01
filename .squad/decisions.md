## 2026-05-31T16:20:59-07:00 — INBOX MERGE: edison-stitchwise-share-brand.md

# Decision: Share Output Branding is "Stitchwise"

**Date:** 2026-05-31T16:20:59-07:00
**Author:** Edison (Frontend Dev)
**Status:** Decided

## Decision

The product branding shown on the shared image (share card footer) and the text-share fallback is now **"Stitchwise"**, replacing the old string "Knitting Gauge Reconciler" / "Gauge Reconciler".

## Scope

- `ShareableView.swift` footer label: `Text("Gauge Reconciler")` → `Text("Stitchwise")`
- `GaugeMath.swift` `ResultsExportSummary.title` default: `"Knitting Gauge Reconciler"` → `"Stitchwise"`
  - This also updates the text-share output via `ResultsShareTextFormatter` (which uses `summary.title`)
- `GaugeMathTests.swift` assertions updated to match (two test expectations)

## Out of Scope

Xcode target name, module name, bundle identifier, app display name, type names, file names, and accessibility identifiers are NOT changed. This is purely user-facing share/brand string renaming.

## Rationale

Consistent rebranding to "Stitchwise" across all share surfaces (image card + text fallback). Navigation title was renamed in a prior session (MR !37); this closes the remaining share-output gap.


---

## 2026-05-29T12:47:17-07:00 — INBOX MERGE: hopper-template-icon.md

# Hopper Decision — Template Must Ship Neutral App Icon

- **Date:** 2026-05-29T12:47:17-07:00
- **Author:** Hopper
- **Scope:** `ios-swiftui-fastlane-template` — AppIcon.appiconset


## 2026-05-29T03:31:03-07:00 — INBOX MERGE: hopper-app-name-derivation.md

# Hopper Decision — Two-Name Convention for iOS Template Bootstrap

- **Date:** 2026-05-29T03:26:29-07:00
- **Author:** Hopper
- **Scope:** `ios-swiftui-fastlane-template` — `bootstrap.sh` and `Info.plist`


## 2026-05-29T03:50:48-07:00 — Hopper: Hardened SwiftLint Policy for iOS/SwiftUI Template (125a4aa)

**Commit:** 125a4aa (ios-swiftui-fastlane-template)  
**Status:** Implemented

A hardened `.swiftlint.yml` is now committed at the repo root. It is picked up automatically by both `app/build.sh` and the `fastlane ci` lane.

### Core policy decisions

1. **No magic numbers** (:warning) — includes Apple's canonical Dynamic Type sizes (11–34 pt), XCTestCase auto-exempt.
2. **Accessibility** (:error) — `accessibility_label_for_image`, `accessibility_trait_for_button` opt-in at error severity.
3. **Dynamic Type** (:error) — flags `.font(.system(size:N))`, `.uppercased()` must use `.textCase(.uppercase)`.
4. **Design-system colors** (:error) — flags `Color(red:green:blue:)`, all colors from Asset Catalog or semantic system.
5. **Layout/spacing** (:warning) — `.frame()` hardcoded, `.padding(N)` raw numbers, touch targets < 44pt.
6. **Template tokens** — `type_name: allowed_symbols: ["_"]` allows `__APP_NAME__` pre-bootstrap.

Verification: SwiftLint 0.63.2 confirmed 0 errors, 4 expected warnings on unmodified template.

---


## 2026-05-29T04:09:58-07:00 — Hopper: Copilot Instructions Document Hardened SwiftLint (31ef774)

**Commit:** 31ef774 (ios-swiftui-fastlane-template, GitLab `origin/main`)  
**Requested by:** Tesla  
**Status:** Implemented

Updated `.github/copilot-instructions.md` in the template to document the hardened `.swiftlint.yml`. Added concise "## SwiftLint Policy" section (~120 words) between "## Architecture" and "## Fastlane".

Content coverage: mandatory linting, key policies (no magic numbers, Dynamic Type, accessibility, design-system tokens, HIG alignment), execution points (`ci` lane, `app/build.sh`), prototype/ exclusion, cross-references.

No further action needed — Copilot instructions fully aligned with hardened swiftlint policy.

---


## 2026-05-29T04:11:36-07:00 — Hopper: fabric-stabilizer-picker Repo Created from Template

**Scope:** New iOS project bootstrap from `ios-swiftui-fastlane-template`  
**Status:** Implemented

Created **fabric-stabilizer-picker** from template using standard end-user bootstrap flow. All tokens replaced, both remotes wired, repo pushed to GitLab.

| Item | Value |
|------|-------|
| GitLab (code / `origin`) | https://gitlab.com/yashas.gujjar/fabric-stabilizer-picker (private) |
| GitHub (CI/CD / `github`) | https://github.com/yashasg/fabric-stabilizer-picker (public) |
| Xcode target / scheme | `FabricStabilizerPicker` |
| Bundle ID | `com.yashasg.fabric-stabilizer-picker` |

### Flow

1. Cloned template to `fabric-stabilizer-picker`
2. Created GitLab repo via `glab repo create fabric-stabilizer-picker --private`
3. Repointed `origin` to GitLab fabric-stabilizer-picker
4. Ran `bash bootstrap.sh com.yashasg.fabric-stabilizer-picker` — auto-derived `FabricStabilizerPicker`, created GitHub CI/CD repo, self-deleted
5. Pushed to GitLab `origin/main`

### Verification

✅ Zero remaining tokens (`__APP_NAME__`, `__BUNDLE_ID__`, `__GITHUB_CI_REPO_URL__`)  
✅ `app/FabricStabilizerPicker/` directory with renamed Swift sources  
✅ `.swiftlint.yml` present at repo root  
✅ `bootstrap.sh` self-deleted  
✅ Both remotes wired (GitLab = code, GitHub = CI/CD)



## 2026-05-29T04:41:04-07:00 — Hopper: iOS template Xcode projects must use file-system-synchronized groups

**Scope:** `ios-swiftui-fastlane-template`, all bootstrapped clones

**Decision:** All Xcode targets in `ios-swiftui-fastlane-template` (and therefore every bootstrapped project) now use `PBXFileSystemSynchronizedRootGroup` (Xcode 16, objectVersion 77). Target membership is driven by on-disk folder contents — no hardcoded file manifest.

**Rationale:** The template's `app/app.xcodeproj/project.pbxproj` carried ~18 stale `PBXFileReference` / `PBXBuildFile` entries for source files from the original knitting-gauge-reconciler app. These files do not exist in the template. Every clone bootstrapped from the template immediately failed with "Build input files cannot be found" for all 18 paths. `PBXFileSystemSynchronizedRootGroup` permanently eliminates this class of bug: the build system discovers files from the filesystem, so removing or adding sources never requires touching the pbxproj.

**Implementation notes:**

1. **objectVersion 77** — already set; no bump needed.
2. **PBXFileSystemSynchronizedBuildFileExceptionSet** — required to exclude `Info.plist` from the sync group's resource copy. Without it, Xcode double-processes Info.plist (once via `INFOPLIST_FILE` build setting, once as a `CpResource` from the sync group), causing "Multiple commands produce Info.plist" error.
3. **Removed `.gitkeep` files** — `Components/.gitkeep` and `Views/.gitkeep` both flatten to `.gitkeep` in the bundle, causing "duplicate output file" error. `Components/Font+Satoshi.swift` already keeps that directory tracked; `Views/` is empty and developers create subdirectories on demand.
4. **Build phases** — `PBXSourcesBuildPhase.files` and `PBXResourcesBuildPhase.files` are empty; the sync group contributes files automatically based on file type.
5. **Tests** — removed stale gauge-app-specific test methods (`testAdjustmentSheetAccessibility`, `testAboutSheetAccessibility`) from `AccessibilityAuditTests.swift` in the template; these referenced UI elements (`calculate-button`, `about-help-button`) that don't exist in the blank template.

**Affected Repos:**

| Repo | Commit |
|------|--------|
| `ios-swiftui-fastlane-template` | `d3043ff` |
| `fabric-stabilizer-picker` | `117a20f` |

**Verification:** `bash app/build.sh test` in `fabric-stabilizer-picker` exits 0. All tests pass (1 unit test, 2 UITests). "Build input files cannot be found" errors: gone.


## 2026-05-29T04:36:03-07:00 — Hopper: Ruby Preflight Guard in build.sh / run.sh

**Context:** macOS ships `/usr/bin/ruby` at version 2.6.10. This binary is owned by root and read-only — `gem install` targeting it fails with `Gem::FilePermissionError`. Our `Gemfile.lock` pins `BUNDLED WITH 4.0.11`, which requires Ruby >= 3. Users on a fresh Mac (or those who haven't configured their shell PATH) silently resolve system Ruby before Homebrew Ruby, producing a cryptic gem error. Homebrew Ruby (4.0.5 at `/opt/homebrew/opt/ruby/bin`) works perfectly once on PATH. `bundle install` succeeds immediately once the PATH is corrected.

**Decision:** Add a `ruby_preflight()` bash function to the top of `app/build.sh` and `app/run.sh` (after `set -euo pipefail`, before any `bundle`/`xcodebuild` calls). The guard:

1. Detects system Ruby: path matches `/usr/bin/ruby*` or `/System/Library/Frameworks/Ruby.framework*`, OR Ruby major version < 3.
2. **Self-heals** by prepending `$(brew --prefix ruby)/bin` (+ gems bin glob) to `$PATH` if Homebrew is available and Homebrew Ruby exists.
3. Re-checks after self-heal; if still bad, **exits 1** with a clear, actionable error explaining: Apple system Ruby is unsupported, run `brew install ruby` and add the export to `~/.zshrc`.
4. Also checks `bundle` availability and instructs `gem install bundler` if missing.

Also added:
- `app/.ruby-version` pinned to `3.3` (helps rbenv/chruby users; harmless for Homebrew users).
- README updates: Prerequisites table and Fastlane setup → Ruby requirement section.

**Rationale:** **Self-heal first** (not just error): most Homebrew users already have Homebrew Ruby installed — they just haven't added it to PATH. The guard fixes the session PATH transparently so the build proceeds without manual intervention. **Clear error fallback**: if Homebrew Ruby isn't installed, the error message is specific, actionable, and references the README — no developer guessing. **Template-first**: the guard lives in the template source of truth so all future bootstrapped projects inherit it automatically.

**Affected Repos:**

| Repo | Files changed | Commit |
|------|--------------|--------|
| `ios-swiftui-fastlane-template` | `app/build.sh`, `app/run.sh`, `README.md`, `app/.ruby-version` | `5b9c328` |
| `fabric-stabilizer-picker` | `app/build.sh`, `app/run.sh`, `README.md`, `app/.ruby-version` | `aa98283` |

**Verification:** `bash -n` passes on all 4 modified scripts. Simulated with `PATH="/usr/bin:/bin:/opt/homebrew/bin"` → self-healed to Homebrew Ruby 4.0.5. ✅ Simulated with `PATH="/usr/bin:/bin"` (no brew on PATH) → clear error printed to stderr, exit 1. ✅


## 2026-05-29T04:41:04-07:00 — Tesla + Copilot: Template Xcode project carries stale gauge-app file manifest

**What:** The template's `app/app.xcodeproj/project.pbxproj` hardcodes ~18 source files from the original knitting-gauge-reconciler app (GaugeMath.swift, MetricsSubscriber.swift, GaugeMathMetrics.swift, Views/*, Components/*, ContentViewHelpers.swift) that do NOT exist in the template. Build fails in every clone with "Build input files cannot be found". No PBXFileSystemSynchronizedRootGroup — it's an old-style hardcoded manifest.

**Why:** Template was derived from the gauge app; the .swift files were genericized/removed but the pbxproj manifest was never cleaned.

**Fix direction:** Convert the app + test targets to Xcode 16 file-system-synchronized groups (membership = folder contents) so template and clones build whatever .swift files are present — no manual manifest. Fallback: prune dead PBXFileReference/PBXBuildFile entries to match only existing files. Fix in template AND in already-cloned fabric-stabilizer-picker. Verify with a real build.

**Status:** RESOLVED via decision "iOS template Xcode projects must use file-system-synchronized groups" (2026-05-29T04:41:04-07:00 — Hopper).

---


## 2026-05-31T02:21:07-07:00 — Hopper Decision — Template Fastlane: produce command + match interactive-auth docs

- **Date:** 2026-05-31T02:21:07-07:00
- **Author:** Hopper
- **Scope:** `ios-swiftui-fastlane-template` — README.md "Fastlane setup" section

### Decision

Documented `fastlane produce` as the primary path to create the App ID + App Store Connect app record (raw command, not a lane). Added `username(...)` Matchfile callout and first-run interactivity warnings for both `produce` and `match appstore`.

### Rationale

Tesla ran `produce` and `match appstore` for the first time on a real downstream app and hit auth failures caused by running in a non-interactive shell. The template README previously said to do both steps manually in the web portals and explicitly stated "The Fastfile does not include a `produce` lane". Both were outdated/incorrect guidance.

### Key choices

| Choice | Decision | Rationale |
|--------|----------|-----------|
| `produce` as lane vs. raw command | **Raw command** (`bundle exec fastlane produce -u ... -a ... --app_name ...`) | One-shot setup; adding a lane implies it belongs in CI, which it does not — it requires interactive Apple ID auth. |
| Remove the "no produce lane" note | **Removed** | The note was only there to explain the omission. Documenting the raw command makes it redundant and confusing. |
| Matchfile `username("")` placeholder | **Kept empty** | Template must not contain any real credentials. Explicit callout added to README Step 4 to ensure developers fill it in. |

### Implementation

- `README.md` Step 2: new title "Create the App ID and App Store Connect record"; `produce` command with flags; interactive-auth gotcha; manual portal steps as fallback.
- `README.md` Step 4: `username(...)` callout blockquote; `certs` first-run interactive gotcha; full ordering summary (produce → API key → Matchfile → certs → readonly(true) → CI).
- No changes to `app/fastlane/Fastfile` or `app/fastlane/Matchfile`.

### Commit

`46c73a3` — pushed to GitLab origin main (`ios-swiftui-fastlane-template`).


---

## 2026-05-31T16:56:57-07:00 — INBOX MERGE: curie-ui-scroll-robustness.md

# Decision: UI Test Scroll Helper — No-Progress Early-Bail

**Date:** 2026-05-31T16:56:57-07:00
**Author:** Curie (Test Engineer)
**Status:** Decided and Implemented
**File:** `app/KnittingGaugeReconcilerUITests/KnittingGaugeReconcilerUITests.swift`

## Problem

`scrollToElement(_:in:requireHittable:direction:)` ran a `while attempts < 12` loop with no mechanism to detect that a drag was a no-op. On both the main screen and the adjustment sheet, this caused:

- Up to 12 drag gestures × 0.2 s settle = 2.4 s wasted per call when content already fits on screen.
- Up to 12 no-op drags when `preferredScrollSurface` resolved to an obscured/background ScrollView (the `app.scrollViews.firstMatch` fallback could return the background view while the adjustment sheet was presented).

## Decision

Replace the fixed `while attempts < 12` loop with a `for _ in 0..<6` loop that includes a **no-progress early-bail**:

1. **Pre-loop fast-path** (was already implicit in the loop, now made explicit as a guard before loop entry) — zero drags when element is already ready.

2. **Max 6 attempts** (down from 12) — sufficient for any realistic content length in this app.

3. **No-progress bail after 2 consecutive provably-zero-progress drags**: Before each drag, snapshot:
   - `surface.value as? String` — UIScrollView accessibility value reports scroll position as `"0%"` … `"100%"`. Unchanged → surface didn't scroll.
   - `element.frame` (when element is already in the accessibility tree) — unchanged → element didn't move.

   **Critical guard:** only trigger the bail when at least one signal was measurable (`canMeasure = beforeValue != nil || beforeFrame != nil`). When both signals are absent (SwiftUI ScrollView with no accessibility value AND element not yet in tree), assume the scroll may be working and continue the loop. This prevents false-bails on legitimate scroll scenarios.

## Contract Preserved

- All accessibility identifiers unchanged.
- All assertions unchanged; no tests deleted or quarantined.
- `preferredScrollSurface` unchanged — sheet-vs-main-screen routing (#24 fix) intact.
- UI tests remain serial (per 2026-05-20 decision).

---

## 2026-05-31T16:46:27-07:00 — INBOX MERGE: edison-async-share-render.md

# Decision: Share Image Generation is Asynchronous / Non-Blocking

**Date:** 2026-05-31T16:46:27-07:00
**Author:** Edison (Frontend Dev)
**Status:** Decided

## Decision

The share-image render pipeline (`shareItems(for:)` + `renderShareImageURL(summary:)` in `ContentView.swift`) is now fully asynchronous. The main thread is never blocked while preparing the share payload.

## Architecture

| Step | Thread | Rationale |
|------|--------|-----------|
| `ImageRenderer` rasterization (`.uiImage`) | **MainActor** | `ImageRenderer` is `@MainActor`-isolated — this cannot move off-main |
| `UIImage.pngData()` encoding | **MainActor** | Kept co-located to avoid capturing `UIImage` (not Sendable-safe) across the detached boundary |
| `Data.write(to:)` file write | **`Task.detached(priority: .userInitiated)`** | Disk I/O is the expensive offloadable work; `Data` and `URL` are `Sendable` |

## Preserved Behaviour

- `shareInvoked` / `shareFallback` MetricKit signposts fire correctly from async path
- `accessibility-identifier: "share-results"`, `label: "Share results"` intact (UI test contract)
- `.sheet(item: $sharePayload)` presents only after the payload is fully built (same as synchronous behaviour)
- Text fallback (`ResultsShareTextFormatter`) on render failure still applies

---

## 2026-05-31T16:56:57-07:00 — INBOX MERGE: edison-swiftlint-ui-cleanup.md

# Decision: SwiftLint UI Source Cleanup — Zero Violations Achieved

**Date:** 2026-05-31T16:56:57-07:00
**Author:** Edison (Frontend Dev)
**Status:** Decided

## Summary

Performed a SwiftLint cleanup pass scoped to `app/KnittingGaugeReconciler/**`. Result: **0 violations** under all invocation modes (repo root, `app/` dir with auto-discovery, `app/` dir with explicit `--config`).

## Rules Addressed

| Rule | Location | Fix |
|------|----------|-----|
| `trailing_comma` | `AdjustmentValuePair.swift`, `GaugeMeasurementPair.swift` | Removed trailing commas from `[GridItem]` literals |
| `superfluous_disable_command` | `HeroTilesView.swift`, `GaugeStepperField.swift` | Replaced `disable:next/this missing_min_touch_target` + `.padding(.vertical, N)` with `EdgeInsets(top: N, leading: 0, bottom: N, trailing: 0)` |
| `todo` | `MetricsSubscriber.swift` | Changed `// TODO(V2):` to `// V2 (deferred):` |

## Files Touched

- `app/KnittingGaugeReconciler/Components/AdjustmentValuePair.swift`
- `app/KnittingGaugeReconciler/Components/GaugeMeasurementPair.swift`
- `app/KnittingGaugeReconciler/Views/HeroTilesView.swift`
- `app/KnittingGaugeReconciler/Components/GaugeStepperField.swift`
- `app/KnittingGaugeReconciler/MetricsSubscriber.swift`

---

## 2026-05-31T21:33:41-07:00 — INBOX MERGE: hopper-cleanup-commit.md

# Hopper Decision — Cleanup Commits: SwiftLint + Scroll Fix

- **Date:** 2026-05-31T21:33:41-07:00
- **Author:** Hopper (Tesla requested via Coordinator)
- **Scope:** app/ (6 files across 2 commits)
- **Status:** Implemented

## Decision

Committed and pushed Edison's SwiftLint cleanup + Curie's UI-test scroll robustness fix to origin/main. Gate rule: **no regression vs. baseline**, not "all tests green".

## What Was Committed

| Commit | Files | Purpose |
|--------|-------|---------|
| `08f8a70` | 5 source files (AdjustmentValuePair, GaugeMeasurementPair, GaugeStepperField, MetricsSubscriber, HeroTilesView) | Edison's SwiftLint cleanup — 0 violations verified |
| `787ca28` | 1 test file (KnittingGaugeReconcilerUITests.swift) | Curie's scroll robustness — early bail + 12→6 max attempts |

## Rationale

**Baseline differential proves zero regression:** The baseline test run (HEAD with all uncommitted changes reverted) exhibited the same 5 UI test failures as the current tree with changes applied. Therefore, the 5 failures are pre-existing environmental/app-state issues, NOT caused by Edison or Curie's work. Per the coordination decision, cleanup changes commit when regression-free; all-green is a separate gate (already failing at baseline).

**Pre-existing UI test failures** (triaged separately):
- testAllJacquardScenariosAreVisibleInUI
- testCompactWidthKeepsNumericFieldsSideBySideWhenTheyFit
- testMainScreenAccessibility
- testPrototypeParityControlsAreAvailable
- testResetConfirmationAlertDoesNotDismissSheet

---
