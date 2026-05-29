# Hopper — History Archive

## Archived Entries (2026-05-19 through 2026-05-20)

### 2026-05-19 — Early Phase: build.sh & Test Infrastructure

- Fixed mktemp BSD incompatibility (macOS X's at end of template)
- Resolved xcodebuild clean race condition with local -derivedDataPath
- Fixed stale simulator state causing UI test runner crash
- Corrected warning grep false positives
- Handled benign crash-pattern false positives

### 2026-05-19 — iOS 26.4 XCUI Accessibility Bugs

- `.accessibilityElement(children: .combine)` causes duplicate staticText in iOS 26.4; removed in favor of direct identifier tagging
- XCUI `app.buttons["X"]` matches by **accessibility identifier**, not label; updated test queries accordingly
- GitLab CI: Removed invalid `image:` field from macOS shell runner config

### 2026-05-19 — Configuration & Path Updates

- Changed default simulator from iPhone 17 Pro Max to iPhone 17 Pro
- Extended Xcode 26.4 post-test IOHID handling in build.sh
- Renamed Xcode project bundle (with corrections): final canonical path is `app/KnittingGaugeReconciler.xcodeproj`
- Created `app/run.sh` launcher wrapper with simulator target selection
- **Serial iOS UI Testing Constraint:** All local UI tests must run in serial; no concurrent simulator usage

### 2026-05-20 — swift-metrics Scoping (Issue #9)

- V1: Recommended Xcode-integrated SPM for swift-metrics 2.11.0 with `KGR_METRICS_BACKEND` env var
- V2: Independent review confirmed V1 with exact build.sh diff and CI YAML snippet
- V3: **Architecture Pivot** — Dropped swift-metrics SPM in favor of Apple's system MetricKit framework

### 2026-05-20 — MetricKit V3 Implementation

- PrivacyInfo.xcprivacy verified with plutil -lint
- pbxproj wiring applied: new IDs 000000000000000000000006 and 000000000000000000000106
- PrivacyInfo.xcprivacy confirmed in .app bundle after build
- Test results: 18/18 pass, zero compiler warnings
- Zero SPM deps confirmed; no Package.resolved or XCRemoteSwiftPackageReference
- Created docs/app-store-connect-privacy-setup.md
- MetricKit auto-links without explicit Frameworks build phase entry

**Key Pattern:** Project uses sequential zero-padded 24-char hex UUIDs; safe to edit as text with consistent ID usage.

---

**Session:** MetricKit V1 shipped 2026-05-20T19:26:30Z with 49/49 tests pass.



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

**Hopper-8:** Removed `bundle exec` from app/build.sh's run_fastlane() function. System Ruby 2.6 cannot satisfy Bundler 4.0.11 pin; Bundler 4.x requires Ruby 3.x. Direct fastlane invocation via Homebrew path works on local. CI workflow (cd.yml) retains `bundle exec fastlane` because Ruby 3.4 is properly provisioned by `ruby/setup-ruby@v1` action. Commit 003d8ea on feat/fastlane-from-cocktail.

### Key Technical Decisions

- **Build.sh as thin wrapper:** build.sh handles lock management, preflight checks (MetricKit, SwiftLint, foreign-app uninstall), and simulator UDID/name resolution, but delegates actual xcodebuild/test execution to Fastlane.
- **Scheme as test scope source of truth:** Fastlane's test scope is now driven by the shared `KnittingGaugeReconciler` Xcode scheme, eliminating lane-level `only_testing` filters.
- **Backwards compatibility:** `app/run.sh` continues to work unchanged; it sets `BUILD_DIR=$RUN_BUILD_DIR COMPILER_INDEX_STORE_ENABLE=NO DESTINATION=...` before calling `build.sh build`, and build.sh forwards those settings into Fastlane.
- **Local vs. CI Ruby mismatch:** System macOS Ruby cannot run modern Bundler versions. Local build.sh calls fastlane directly (Homebrew path); CI uses ruby/setup-ruby with Ruby 3.4 to provision proper Bundler support. Both paths are correct for their environments.

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

---

### 2026-05-23T02:12:30Z — MR !36 Merged; Cherry-Pick Escalation Resolved

**Status:** ✅ MR !36 shipped to main (commit 6d89671)

**Cherry-pick attempt (hopper-10):** Attempted direct cherry-pick of commit 7320a75 (Fastfile UI-test skip) onto main. Conflict detected: main's Fastfile predates the entire feat/fastlane-from-cocktail integration branch, making surgical cherry-pick impossible without resolving complex dependencies.

**Decision:** Escalated to full MR merge. tesla-3 merged the entire feat/fastlane-from-cocktail branch as MR !36 (11 commits, 6d89671), ensuring atomic Fastlane integration with all dependencies intact.

**Outcome:** Full Fastlane integration delivered atomically:
- Build.sh delegates to Fastlane (thin wrapper pattern preserved)
- Scheme-driven test scope
- App Store Connect API-key auth
- CI-only signing hardening
- GitHub Actions CD workflow ready

**Lesson:** When cherry-pick conflicts arise due to deep dependency trees, full branch merge is more reliable than manual conflict resolution — preserves all test/integration points and reduces hidden regressions.

---

### 2026-05-23T10:06Z — ASC Auth File Fallback (Hopper-11 background agent)

**Status:** ✅ Commit fbd5fd0 merged to main via MR !39

**Problem:** GitHub Actions CD workflow step-level environment variable scoping prevented Fastlane from accessing ASC_API_KEY_JSON in the release step. The env var was only visible in the write step, not in the later fastlane execution step.

**Solution:** Modified Fastlane to fall back to reading `app/fastlane/asc_api_key.json` when `ENV["ASC_API_KEY_JSON"]` is absent. Preserves local dev flows (env var override) while fixing CI execution (file-based fallback).

**Root cause:** Step-level `env:` directives in GitHub Actions do not carry forward automatically. The write-to-file action is the stable on-disk artifact that persists between steps.

**Consequence:** Fastlane release workflows now work in GitHub Actions. Main branch (commit e786f37) is ready for CD execution with correct ASC authentication handling.