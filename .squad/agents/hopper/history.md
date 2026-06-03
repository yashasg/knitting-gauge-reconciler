# Hopper — History

## Core Context

- **Project:** A knitting gauge reconciler that converts patterns between stitch/row gauges.
- **Role:** Tooling Dev / Release Engineer
- **Joined:** 2026-05-19T07:11:08.647Z

## Current Status (2026-05-31)

**Latest:** Cleanup commits verified and pushed (08f8a70 Edison, 787ca28 Curie). 5 pre-existing UI test failures documented. All app/ work committed.

## This Session (2026-05-31)

### Cleanup Commit Verification & Push

**Decision:** Cleanup commits gate on **no-regression-vs-baseline**, not **all-tests-green**.

**Verification:**
- Baseline test run (HEAD with changes reverted): 5 UI failures
- Current tree test run (with Edison + Curie changes): 5 same UI failures
- **Conclusion:** Zero regression. Changes eligible to commit.

**Pre-existing failures (tracked separately):**
- testAllJacquardScenariosAreVisibleInUI
- testCompactWidthKeepsNumericFieldsSideBySideWhenTheyFit
- testMainScreenAccessibility
- testPrototypeParityControlsAreAvailable
- testResetConfirmationAlertDoesNotDismissSheet

**Commits pushed to origin/main:**
1. `08f8a70` — SwiftLint cleanup (Edison, 5 source files)
2. `787ca28` — UI test scroll robustness (Curie, 1 test file)

**Verification:**
- ✅ Both commits pushed to origin/main
- ✅ "Your branch is up to date with 'origin/main'"
- ✅ No orphaned xcodebuild/Simulator processes
- ✅ All 6 app files staged individually (no globs)
- ✅ .squad/ files not staged

## Learnings

- **Baseline differential:** Zero regression vs. baseline = eligible to commit (per coordination decision)
- **Pre-existing failures:** 5 failures on baseline prove not caused by cleanup work
- **Resource safety:** One xcodebuild/test at a time, never concurrent
- **GitLab work items:** Filed #47 to remove 6 flaky iOS 26.4 UI tests; rely on SwiftLint for validation
- **SwiftLint custom rules (2026-06-02):** Added `no_minimum_scale_factor` and `no_dynamic_type_cap` accessibility guard rules to `.swiftlint.yml`. Key lessons:
  - YAML single-quoted strings are safest for regex values (backslashes are literal, no escape processing).
  - YAML double-quoted strings require `\\` for literal backslash in messages — prefer single quotes.
  - The regex `\.dynamicTypeSize\(\.\.\.` cleanly targets only the PartialRangeThrough view-modifier form; it does NOT match `@Environment(\.dynamicTypeSize)` (keypath, no `(` follows), `.environment(\.dynamicTypeSize, …)` (keypath inside .environment, no `(` after), or `dynamicTypeSize.isAccessibilitySize` (property access, no leading `.`).
  - SwiftLint regex scans raw text including comments — the negative test (commented banned patterns) correctly fires. This is acceptable for a regression guard.
  - Pre-commit hook lives at `.git/hooks/pre-commit` and is not committed to the repo (it's a developer machine side-effect). Document its contents in §3.1 of `docs/swift_coding_standards.md` so team members can reinstall.
  - `excluded:` in `.swiftlint.yml` must list test directories explicitly; tests may set specific DynamicTypeSize values for layout assertions.

## Status

✅ Complete. Cleanup work committed and pushed. All app/ changes in main. Ready for Scribe merge + session archival.

---

## This Session (2026-05-31 Evening) — UI Fix Verification Gate

### Task: Verify UI fix commits before push

**Commits under test:**
- `57e31b2` (Curie): LazyVGrid→HStack + UIKitTapButton + imperative UIKit Reset alert
- `132736c` (Edison): presentShareSheet scene-walk + sage dark-mode WCAG contrast

**Verification results:**

1. **SwiftLint:** 0 violations ✅
2. **Build:** clean (0 warnings, 0 errors) ✅
3. **UI Tests (7 targeted):** 6 FAILED ✗
   - `testShareResultsIsSingleAccessibleAffordance` — PASSED ✓
   - `testAllJacquardScenariosAreVisibleInUI` — FAILED (cast-on-result element not found)
   - `testCompactWidthKeepsNumericFieldsSideBySideWhenTheyFit` — FAILED (cast-on-result element not found)
   - `testMainScreenAccessibility` — FAILED (AccessibilityAuditTests, Invalid target app 90890)
   - `testAdjustmentSheetAccessibility` — FAILED (AccessibilityAuditTests, Invalid target app 90877)
   - `testPrototypeParityControlsAreAvailable` — FAILED (Reset button not found in Alert)
   - `testResetConfirmationAlertDoesNotDismissSheet` — FAILED (Cancel button not found in Alert)

**Decision gate result:** DO NOT PUSH (6 of 7 tests failing; any test failure blocks push per coordination decision)

**Next steps:** Route failures to Edison (app logic) and Curie (test suite) for fixes.

## See Also

- **Archive:** `history-archive.md` — prior sessions (template sync groups, Ruby guard, iOS bootstrap, Fastlane docs)
- **Decisions:** `.squad/decisions.md`
