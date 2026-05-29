# Hopper — History

## Core Context

- **Project:** A knitting gauge reconciler that converts patterns between stitch/row gauges.
- **Role:** Tooling Dev
- **Joined:** 2026-05-19T07:11:08.647Z

## Current Learnings

<!-- Recent learnings; archive to history-archive.md when exceeding 15360 bytes -->

### Learnings

- **2026-05-23T03:28:48-07:00:** Bundle ID is now intentionally the ASC typo'd identifier `com.yashasg.knitting-guage-reconciler` (plus `Tests`/`UITests` suffixes for test bundles) so Fastlane Match/CD can sign against the existing KnitFit ASC app `6772098335`. Future correction to `gauge` would require creating a brand-new ASC app entry.
- **2026-05-23T03:01:49-07:00:** GitHub Actions `env:` scope is step-local unless promoted to job/workflow env or written via `GITHUB_ENV`. A secret wired only on the "Write App Store Connect API key" step is not visible to the later Fastlane upload step, so release tooling should prefer the already-written `app/fastlane/asc_api_key.json` file as the cross-step contract and keep `ASC_API_KEY_JSON` only as an optional override.
- **2026-05-23T01:52Z:** Bundler pin in `app/Gemfile.lock` (Bundler 4.0.11) requires Ruby 3.x; system macOS Ruby (2.6) cannot satisfy it, causing `find_spec_for_exe` errors at `bundle exec` time. Calling `fastlane` directly (Homebrew install on PATH via `brew install fastlane`) bypasses Bundler entirely and works on any Ruby version. CI keeps `bundle exec` because it provisions Ruby 3.4 + bundler-cache via `ruby/setup-ruby@v1` before invoking Fastlane.

**Last entry:** 2026-05-23T03:28:48-07:00 — Bundle ID pivoted to ASC's typo'd `com.yashasg.knitting-guage-reconciler`; future rename would require a new ASC app.

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


## Historical Sessions (Archived)

See history-archive.md for prior session logs (2026-05-22 onwards).

### 2026-05-29T02:00:20-07:00 — iOS/SwiftUI + Fastlane Template (Hopper-2)

**Task:** Build a reusable iOS/SwiftUI + fastlane template repo and push to GitLab.

**Destination:** `/Users/yashasgujjar/dev/ios-swiftui-fastlane-template`

**GitLab repo:** https://gitlab.com/yashas.gujjar/ios-swiftui-fastlane-template (private)

**Key paths in template:**
- `app/app.xcodeproj` — Xcode project, all three targets (app, unit tests, UI tests)
- `app/__APP_NAME__/` — SwiftUI source skeleton (ContentView.swift, __APP_NAME__App.swift, PrivacyInfo.xcprivacy, empty Components/ and Views/)
- `app/__APP_NAME__Tests/__APP_NAME__Tests.swift` — minimal unit test stub
- `app/__APP_NAME__UITests/` — AccessibilityAuditTests.swift (genericized) + minimal UITests stub
- `app/app.xcodeproj/xcshareddata/xcschemes/__APP_NAME__.xcscheme` — shared scheme
- `app/fastlane/` — Appfile, Fastfile, Matchfile all tokenized to __BUNDLE_ID__/__APP_NAME__
- `app/build.sh`, `app/run.sh` — build wrappers (SWIFT_TREAT_WARNINGS_AS_ERRORS=YES preserved)
- `bootstrap.sh` — one-shot rename/token-replace script; self-deletes after use
- `.squad/` — fully reset team (empty roster, blank casting registry)

**Approach:**
1. rsync copy from source excluding .git, .build, .DS_Store, excalidraw artifacts, prototype/
2. Remove all .yml/.yaml files (including .swiftlint.yml — noted in README, add per project)
3. Rename KnittingGaugeReconciler dirs → __APP_NAME__ via `mv`
4. Token replace in pbxproj, xcscheme, Fastfile, scripts via `sed -i ''`
5. Delete knitting domain Swift files; write minimal stubs for ContentView, App, tests
6. Genericize fastlane: blank Appfile (apple_id/team_id), blank Matchfile (git_url/username)
7. Reset .squad/: clear registry, history, decisions, inbox, agent folders, routing table
8. Write new README as template usage guide
9. `git init -b main`, commit, `glab repo create` (private), push via HTTPS

**Learnings:**
- `glab repo create` (v1.97.0) does NOT support `--source`/`--push` flags; must `glab repo create`, then `git remote add origin`, then `git push -u origin main`.
- SSH keys not set up on this machine for gitlab.com; HTTPS push worked fine since glab is authenticated.
- `.swiftlint.yml` must be dropped per the no-yml rule; document in README that it should be re-added per project.
- `sed -i ''` (BSD/macOS) requires the empty string arg; GNU sed would use `sed -i` without the arg.
- The swiftlint `ci` lane call in Fastfile had `config_file` pointing to the now-dropped `.swiftlint.yml` — removed that param so the lane falls back to finding swiftlint config by convention.

- 2026-05-29T02:06:00-07:00 — Added `glab` CLI skill to ios-swiftui-fastlane-template Squad (.squad/skills/glab/SKILL.md); committed and pushed to GitLab main (9d5fd27).
\n- 2026-05-29: Wrote comprehensive setup-guide README for the iOS/SwiftUI + fastlane template repo at gitlab.com/yashas.gujjar/ios-swiftui-fastlane-template (commit 7fb1319). Covers prerequisites, bootstrap, build/test/release modes, code signing, release lanes with bump support, Squad+glab workflow, and troubleshooting.

- 2026-05-29: Added `.github/copilot-instructions.md` and `docs/DesignSystem.md` to the iOS/SwiftUI + fastlane template repo (ios-swiftui-fastlane-template). Copilot instructions cover project overview, Swift coding standards, Hearth design system, fastlane lanes, build/run scripts, App Store Connect, and Squad workflow conventions.

## 2026-05-29 — Satoshi font wired as app default in template

**Repo:** ios-swiftui-fastlane-template (GitLab)

**What was done:**
- Copied `Satoshi-Variable.ttf` + `Satoshi-VariableItalic.ttf` into `app/__APP_NAME__/Fonts/`
- Switched from `GENERATE_INFOPLIST_FILE = YES` to a physical `app/__APP_NAME__/Info.plist` (`GENERATE_INFOPLIST_FILE = NO`, `INFOPLIST_FILE = __APP_NAME__/Info.plist`). The plist carries all keys previously expressed via `INFOPLIST_KEY_*` build settings PLUS `UIAppFonts` listing both TTF filenames. This is the registration approach.
- Added font file references + Fonts group to `project.pbxproj`; fonts added to Copy Bundle Resources phase of the app target.
- Created `app/__APP_NAME__/Components/Font+Satoshi.swift` with a `Font` extension exposing `.satoshiBody`, `.satoshiTitle`, etc. for the full Apple text-style scale using `Font.custom("Satoshi Variable", size:relativeTo:)` (family name per nameID 1). Variable weight control via `.fontWeight()` modifier.
- Set `.font(.satoshiBody)` on the root `WindowGroup` in `__APP_NAME__App.swift` as the environment-wide default.
- Updated `ContentView.swift` to use `.satoshiTitle`.
- Documented in `docs/DesignSystem.md` (new "Typography / Fonts — iOS Native" section) and `.github/copilot-instructions.md`.

**Key detail for future work:** The font family name to use in `Font.custom` is `"Satoshi Variable"` (NOT `"Satoshi-Variable"` or `"SatoshiVariable-Bold"`). PostScript name of the default instance is `SatoshiVariable-Bold`.

---

## 2026-05-29 — iOS/SwiftUI + Fastlane Template Pushed to GitLab

**Date:** 2026-05-29T02:00:20-07:00  
**Status:** Completed

Created reusable template repo (`ios-swiftui-fastlane-template`) at `/Users/yashasgujjar/dev/ios-swiftui-fastlane-template` and pushed to GitLab (private).

### Template features
- Token-based genericization (`__APP_NAME__`, `__BUNDLE_ID__`, `__GITLAB_BOARD_URL__`)
- Bootstrap script for automated rename + setup
- Fastlane lanes intact (ci, build, test, certs, beta, release)
- Shared build standards (`SWIFT_TREAT_WARNINGS_AS_ERRORS=YES`, xcpretty, `-quiet`)
- Squad roster reset for fresh projects
- Zero `.yml` files shipped (per user directive)

### Documentation updates
- Added CI/CD architecture section (GitLab code repo, GitHub runner via webhooks)
- Added ignore directive for prototype/ folder
- Added glab CLI skill documentation
- Expanded design system docs (Hearth Design System, ~29.5KB)
- Updated font helpers and accent mechanism naming

### Orchestration logs
- 4 background hopper agents spawned (hopper-5, hopper-6, hopper-7 coordinated edits)
- All work pushed and merged

---

## 2026-05-29 — Template README Fastlane Setup Documentation (Hopper-9)

**Date:** 2026-05-29T03:25:00-07:00  
**Status:** Completed  
**Commit:** 1bf390d (ios-swiftui-fastlane-template)

Documented comprehensive Fastlane setup section in template README per Tesla's request. Added 6-step guide covering prerequisites, manual App ID registration, Appfile fields, ASC API key configuration, Matchfile cert management, and beta/release lanes with version bump support. Included real Fastfile/Appfile/Matchfile inspection notes and CI/CD architecture (GitHub webhooks, not GitLab yml). Cross-linked existing docs/app-store-connect-privacy-setup.md.

**Key sections added:**
- Prerequisites: `cd app && bundle install`, Xcode CLI tools
- Manual App ID + ASC registration (no produce lane)
- Appfile: app_identifier, apple_id, team_id
- ASC API key setup with linked privacy docs
- Matchfile: git_url, MATCH_PASSWORD, MATCH_KEYCHAIN_PASSWORD, real `certs` lane
- Release lanes: `beta` and `release` with configurable version bump (patch/minor/major)

---

## 2026-05-29 — Bootstrap App-Name Derivation & GitHub CI/CD Repo (Hopper-10/11/12)

**Date:** 2026-05-29T03:31:03-07:00  
**Status:** Completed  
**Commits:** Multiple (iOS template repo)

Three agents completed refinements to `bootstrap.sh` and template structure:

**Hopper-10** — Auto-derive Xcode app/target name from repo name in PascalCase (e.g., `knitting-gauge-reconciler` → `KnittingGaugeReconciler`). Removed user prompt; optional `--app-name` flag for override. Eliminates manual error-prone conversion step.

**Hopper-11** — SCOPE CORRECTION. Removed all App Store display-name handling from bootstrap (`__DISPLAY_NAME__` token, prompt, flag, CI defaults). Updated `Info.plist` to use `CFBundleDisplayName = $(PRODUCT_NAME)`. Display name now managed separately in App Store Connect / fastlane, not bootstrap.

**Hopper-12** — `bootstrap.sh` now creates public GitHub repo (matching GitLab repo name) as CI/CD runner. Added as `github` remote (GitLab origin untouched). Replaced `__GITHUB_CI_REPO_URL__` token in README with real URL. Skippable via `--no-github` or `SKIP_GITHUB=1`.

**Workflow:** GitLab = code repository (origin); GitHub = CI/CD runner (via webhooks).

**Key decisions archived:**
- Auto-derive app name; optional override only
- Separate display-name scope from bootstrap
- Dual-repo: GitLab code + GitHub CI/CD

---
