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
