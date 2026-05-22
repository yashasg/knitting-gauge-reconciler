# Hopper — History

## Core Context

- **Project:** A knitting gauge reconciler that converts patterns between stitch/row gauges.
- **Role:** Tooling Dev
- **Joined:** 2026-05-19T07:11:08.647Z

## Current Learnings

<!-- Recent learnings; archive to history-archive.md when exceeding 15360 bytes -->

**Last entry:** 2026-05-20T19:26:30Z — MetricKit V1 shipped. Build: 49/49 tests pass. All MetricKit and swift-metrics work archived. See history-archive.md for comprehensive phase notes.

## Team Updates

- **2026-05-20T19:26:30Z:** MetricKit V1 shipped. Canonical tooling state locked: `app/KnittingGaugeReconciler.xcodeproj`, serial iOS UI testing enforced, zero SPM deps, PrivacyInfo.xcprivacy in Resources phase.
- **2026-05-21T14:15:00Z:** Curie confirmatory test cycle: 56/56 pass, 0 warnings, ~2m57s, committed 7cbdff4.
- **2026-05-22T15:15:26-07:00:** Added committed shared Xcode scheme `app/app.xcodeproj/xcshareddata/xcschemes/KnittingGaugeReconciler.xcscheme` for Fastlane/GitHub Actions CI. Scheme binds app target `000000000000000000000401`, unit tests `000000000000000000000402`, UI tests `000000000000000000000403`, and uses Xcode 26-style `LastUpgradeVersion = 2640`, `version = 1.7`.

## 2026-05-22T00:37:04-07:00 — HIG Automation Wired

**Task:** Wire SwiftLint HIG rules + XCUITest accessibility audit  
**Requested by:** Yashas

### What shipped

**Part 1 — SwiftLint**
- Created `.swiftlint.yml` at repo root with 5 custom HIG-targeted rules: `no_hardcoded_font_size`, `no_uppercased_in_code`, `navigation_stack_in_sheet`, `color_literal_rgb`, `missing_min_touch_target`. Enabled `accessibility_label_for_image` opt-in rule. Disabled `todo` and `trailing_comma`.
- Added lint step to `app/build.sh` (runs before every `run_xcodebuild` call). Gracefully skips if swiftlint not installed.
- Updated `docs/swift_coding_standards.md` §3 to document SwiftLint as official tooling, added §3.1 (pre-commit hook setup) and §3.2 (HIG rule table).

**Part 2 — Accessibility Audit Tests**
- Created `app/KnittingGaugeReconcilerUITests/AccessibilityAuditTests.swift` with 3 tests: `testMainScreenAccessibility`, `testAdjustmentSheetAccessibility`, `testAboutSheetAccessibility` — each calls `performAccessibilityAudit()`.
- Patched `app/app.xcodeproj/project.pbxproj` to register `AccessibilityAuditTests.swift` in the `KnittingGaugeReconcilerUITests` target (new IDs `000000000000000000000015` / `000000000000000000000115`).

**Part 3 — Build verified** — build passed post-changes.

### Run the audit in isolation
```bash
xcodebuild test \
  -scheme KnittingGaugeReconciler \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing KnittingGaugeReconcilerUITests/AccessibilityAuditTests \
  2>&1 | grep -E "(PASS|FAIL|warning|error|audit)"
```
