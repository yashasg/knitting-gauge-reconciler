# Hopper — History

## Core Context

- **Project:** A knitting gauge reconciler that converts patterns between stitch/row gauges.
- **Role:** Tooling Dev
- **Joined:** 2026-05-19T07:11:08.647Z

## Current Learnings

<!-- Summarized: older entries (2026-05-23 and earlier) moved to history-archive.md -->

### Latest Tasks (2026-05-29)

#### **Hopper-15 & 16 & 17 — Template Hardening & New Project Bootstrap**

**Timeframe:** 2026-05-29T03:50:48 — 04:11:36-07:00

**What:** 
1. (Hopper-15) Added hardened `.swiftlint.yml` to template root (commit 125a4aa) — enforces no magic numbers, Dynamic Type, accessibility, design-system tokens, HIG alignment. Verified: 0 errors, 4 expected warnings.
2. (Hopper-16) Documented `.swiftlint.yml` policy in `.github/copilot-instructions.md` (commit 31ef774) — concise section covering rules, execution points, cross-references.
3. (Hopper-17) Bootstrapped new project `fabric-stabilizer-picker` from template (com.yashasg.fabric-stabilizer-picker, auto-derived FabricStabilizerPicker target). Verified zero tokens, both remotes wired (GitLab origin private, GitHub CI/CD public).

**Key gotchas:**
- SwiftLint custom rules via regex require careful rule ID naming (e.g. `accessibility_trait_for_button` is valid in v0.63.2).
- `glab repo create` prompts interactively even inside an existing working copy — answer "No" and delete spurious subdirectories.
- bootstrap.sh auto-derives Xcode target name from remote origin slug; repoint origin BEFORE running bootstrap.

**Verification:** All three tasks verified complete; both repos pushed to GitLab/GitHub.

### Prior Learnings (Summarized)

**2026-05-23 window:** ASC bundle ID (typo'd `com.yashasg.knitting-guage-reconciler` to match existing app), GitHub Actions env scope (step-local unless promoted), Bundler 4.0.11 Ruby 3.x pin (workaround: call fastlane directly on dev; CI uses ruby/setup-ruby@v1).

**2026-05-22 window:** run.sh GUI surfacing (`open -a Simulator`), derived-data cleanup isolation (`COMPILER_INDEX_STORE_ENABLE=NO`, `.build/run-build` separate from `.build/derived-data`).

*Full historical context: See history-archive.md*

## Team Updates

- **2026-05-20T19:26:30Z:** MetricKit V1 shipped. Canonical tooling state locked: `app/KnittingGaugeReconciler.xcodeproj`, serial iOS UI testing enforced, zero SPM deps, PrivacyInfo.xcprivacy in Resources phase.
- **2026-05-21T14:15:00Z:** Curie confirmatory test cycle: 56/56 pass, 0 warnings, ~2m57s, committed 7cbdff4.
- **2026-05-22T15:15:26-07:00:** Added committed shared Xcode scheme `app/app.xcodeproj/xcshareddata/xcschemes/KnittingGaugeReconciler.xcscheme` for Fastlane/GitHub Actions CI. Scheme binds app target `000000000000000000000401`, unit tests `000000000000000000000402`, UI tests `000000000000000000000403`, and uses Xcode 26-style `LastUpgradeVersion = 2640`, `version = 1.7`.

---

See history-archive.md for detailed session logs from prior days.
