# Hopper — History

## Core Context

- **Project:** A knitting gauge reconciler that converts patterns between stitch/row gauges.
- **Role:** Tooling Dev
- **Joined:** 2026-05-19T07:11:08.647Z

## Current Learnings

<!-- Recent learnings; archive to history-archive.md when exceeding 15360 bytes -->

**Last entry:** 2026-05-22T21:50Z — run.sh GUI fix completed (Hopper-1); VerdictCard removed from main UI (Edison-1). Inbox decisions merged and orchestration logs written.

### 2026-05-22T21:00:32-07:00 — run.sh GUI surfacing (Hopper-1)

**Commit:** bf311a9

**What:** Added `open -a Simulator` to `app/run.sh` to bring the iOS Simulator GUI to foreground. Prior `simctl launch` returned a PID but did not surface Simulator.app, leaving the user with no visible output or interactive surface.

**Context:** App runs but user sees nothing — silent appearance of success is indistinguishable from a hang if the Simulator window is not brought to focus.

**Verification:** Two back-to-back simulator launches on iPhone 17 Pro; all tests pass (62/62).

**Cross-ref:** Edison-1 (VerdictCard revert, 515ab51) and Ive-1 (design postmortem). All work merged to decisions.md and orchestration logs written.

**Last entry:** 2026-05-22T21:18Z — run.sh silent hang fix completed (Hopper). Inbox decisions merged (copilot-runsh-must-call-buildsh.md + hopper-run-build-isolation.md). Orchestration log + session log written.

- **2026-05-22T21:00:32-07:00:** `./app/run.sh` could appear frozen before any build output because it delegated into `app/build.sh`'s shared `.build/derived-data` cleanup and got stuck deleting a bloated `Index.noindex/DataStore/v5` tree (observed 65535 entries). Fix pattern in commits `2b7e1da` + `5cdbc67`: keep `run.sh` delegating to `build.sh`, but isolate it onto `.build/run-build` and set `COMPILER_INDEX_STORE_ENABLE=NO`; verified two consecutive simulator launches on iPhone 17 Pro.

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

---

## 2026-05-22T22:08:27Z — Reviewer Self-Correction Note

**Session:** CI review postmortem  
**Topic:** Grounding reviewer findings against actual artifacts

In this session, Hopper flagged several findings as blockers for the Fastlane-based CI workflow. On postmortem verification:

- **MR clone failure** (blocker) — Found to be factually incorrect. Actual CI runs using `gitlab_mr` succeed.
- **Warnings-as-errors dropped** (blocker) — Found to be factually incorrect. `app/app.xcodeproj/project.pbxproj` enforces warnings-as-errors directly (6 occurrences).
- **SwiftLint cache blocker** — Found to be speculative pattern-matching against generic GitHub Actions footguns, not grounded in this project's macos-26 runner setup.
- **`CONFIGURATION` propagation issue** — Found to be factually incorrect. GitHub Actions *does* expose `GITHUB_ENV` writes in expression contexts on the same job.

**Lesson for future reviews:** Before flagging blockers, verify claims against the actual repo artifacts:
- Run logs and CI history (success/failure patterns)
- Build settings (project.pbxproj, Fastfile, build.sh)
- Infrastructure state (runner image contents, preinstalled tools)
- User directives and decisions (repo is not a generic CI/CD setup)

Pattern-matching against generic best practices is less reliable than grounding in this project's specific codebase, configuration, and user intent.

**Recommendation:** On next CI/infra review, include a verification step that cross-references flagged findings against actual artifacts before finalizing the verdict.

- **2026-05-22T21:25:37-07:00:** Follow-up on `app/run.sh`: a returned `simctl launch` PID is necessary but not sufficient for user-visible success. If `Simulator.app` is not opened first, the app can launch into a headless booted simulator and look like the script "just builds." Preferred verification for run-script fixes: process/GUI evidence (Simulator running, device window/screenshot visible) over PID-only checks.
- **2026-05-23T00:52:25-07:00:** Compared KGR `app/fastlane/Fastfile` against Tesla's read-only `cocktail-batch-dilution/app/fastlane/Fastfile`. Reusable cross-project patterns: App Store Connect API-key auth is cleaner than Apple-ID/session auth for CI release lanes; release bundle-ID preflight checks catch Fastlane↔pbxproj drift early; CI-only keychain/WWDR import plus explicit `match` signing context can harden release lanes. Keep KGR's explicit CI test selection and `team_id` safeguard — do not inherit cocktail's scheme-driven test scope or Appfile omission verbatim.
- **2026-05-23T01:01:48-07:00:** Shipped the cocktail Fastlane integration into KGR in five commits. Reusable pattern: first align `Appfile`/`Matchfile` identifiers and add a pbxproj-vs-Appfile preflight guard, then layer in TestFlight build-number fallback, ASC API-key auth (`ASC_KEY_ID`, `ASC_ISSUER_ID`, plus exactly one of `ASC_KEY_FILEPATH` / `ASC_KEY_CONTENT_B64`), and finally CI-only signing hardening (`MATCH_PASSWORD`, `MATCH_KEYCHAIN_PASSWORD`, optional `WWDR_CERT_PATH`). Active CI Fastlane shape is now scheme-driven `ci`/`test`; it replaces the earlier Release/Debug-split / serial-UI / canceled-as-failed assumptions for this workflow.
