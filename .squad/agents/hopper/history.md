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

## Status

✅ Complete. Cleanup work committed and pushed. All app/ changes in main. Ready for Scribe merge + session archival.

## See Also

- **Archive:** `history-archive.md` — prior sessions (template sync groups, Ruby guard, iOS bootstrap, Fastlane docs)
- **Decisions:** `.squad/decisions.md`
