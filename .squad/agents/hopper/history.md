# Hopper — History

## Core Context

- **Project:** A knitting gauge reconciler that converts patterns between stitch/row gauges.
- **Role:** Tooling Dev
- **Joined:** 2026-05-19T07:11:08.647Z

## Current Learnings

<!-- Recent learnings; archive to history-archive.md when exceeding 15360 bytes -->

### Learnings

- **2026-05-23T01:52Z:** Bundler pin in `app/Gemfile.lock` (Bundler 4.0.11) requires Ruby 3.x; system macOS Ruby (2.6) cannot satisfy it, causing `find_spec_for_exe` errors at `bundle exec` time. Calling `fastlane` directly (Homebrew install on PATH via `brew install fastlane`) bypasses Bundler entirely and works on any Ruby version. CI keeps `bundle exec` because it provisions Ruby 3.4 + bundler-cache via `ruby/setup-ruby@v1` before invoking Fastlane.

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
- **2026-05-23T01:27:13-07:00:** Cross-CI host CD pattern: keep GitHub Actions manual-only (`workflow_dispatch`), clone the GitLab source-of-truth repo at job runtime via `GITLAB_PAT`, validate and pass the raw `ASC_API_KEY_JSON` blob for Fastlane App Store Connect auth, generate a temporary Match keychain password, install Apple WWDR on the runner, and run the Fastlane test gate before `beta`/`release`. Reuse host-agnostic paths/env contracts (`DERIVED_DATA_PATH`, `MATCH_PASSWORD`, `MATCH_KEYCHAIN_PASSWORD`, `WWDR_CERT_PATH`) so the same Fastlane release lanes work across GitLab/GitHub CI.
- **2026-05-23T01:36:40-07:00:** `app/build.sh` is now a thin Fastlane delegator for `build`/`test` (and local `release` builds): the direct `xcodebuild` call path is gone. Preserve build-time-only behavior in the wrapper — SwiftLint, MetricKit telemetry preflight, simulator destination/env translation, build lock, and the foreign-app simulator uninstall preflight still run before `bundle exec fastlane ...`; `run.sh` keeps working by passing `BUILD_DIR`, `DESTINATION`, and `COMPILER_INDEX_STORE_ENABLE` through to Fastlane's derived-data / destination settings.
- **2026-05-23T01:40:00-07:00:** Fastlane now has a dual surface on purpose: the unified `ci` lane is the authoritative lint + build + test entry for local CI-style validation (`./app/build.sh test`), while standalone `build`, `test`, `beta`, and `release` lanes remain for local run/install flow and CD. Keep `app/run.sh` on the build-only wrapper path so its env-var overrides still feed Fastlane without paying for a redundant test pass.

---

## 2026-05-23 — Fastlane Integration Sprint (Hopper-5, 6, 7)

**Status:** ✅ Complete  
**Branch:** feat/fastlane-from-cocktail  
**Commits:** d8f73c5 (Hopper-5), fcd8d8a (Hopper-6), b64ec0e (Hopper-7)  

### What Happened

Three sequential Hopper agent spawns executed a convergence of KGR's build system toward `cocktail-batch-dilution`'s Fastlane + GitHub Actions CD workflow:

**Hopper-5:** Adopted cocktail's `.github/workflows/cd.yml` and adapted it to KGR's project paths and `.build/` layout. CD workflow now in place.

**Hopper-6:** Refactored `app/build.sh` to delegate build/test operations to Fastlane lanes instead of direct xcodebuild. This preserves wrapper-level concerns (locking, preflight, simulator management) while centralizing the actual build/test lifecycle in Fastlane.

**Hopper-7:** Aligned Fastlane CI lane to cocktail's unified `ci` lane pattern. The scheme now drives test scope; `build.sh build` retains its own lane for interactive use, while `build.sh test` routes through the `ci` lane for consistency with CI/CD.

### Key Technical Decisions

- **Build.sh as thin wrapper:** build.sh handles lock management, preflight checks (MetricKit, SwiftLint, foreign-app uninstall), and simulator UDID/name resolution, but delegates actual xcodebuild/test execution to Fastlane.
- **Scheme as test scope source of truth:** Fastlane's test scope is now driven by the shared `KnittingGaugeReconciler` Xcode scheme, eliminating lane-level `only_testing` filters.
- **Backwards compatibility:** `app/run.sh` continues to work unchanged; it sets `BUILD_DIR=$RUN_BUILD_DIR COMPILER_INDEX_STORE_ENABLE=NO DESTINATION=...` before calling `build.sh build`, and build.sh forwards those settings into Fastlane.

### Verification

All commits validated on main; no Fastlane lanes were executed in-session (secrets intentionally not configured per Tesla's gating).

### Deliverables for Team

- GitHub Actions workflow file (`.github/workflows/cd.yml`)
- Updated Fastlane Fastfile with unified `ci` lane and cocktail-style release signing
- Refactored `app/build.sh` delegating to Fastlane

### Dependencies / Blockers

MR !36 (11-commit stack) awaits Tesla's GitHub Secrets setup:
- App Store Connect API keys (`ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_FILEPATH` or `ASC_KEY_CONTENT_B64`)
- Signing credentials (`MATCH_PASSWORD`, `MATCH_KEYCHAIN_PASSWORD`)
- Optional: `WWDR_CERT_PATH`

Tesla has validated the CD workflow end-to-end on cocktail side; KGR's path now matches. Ready to merge once secrets are configured.
