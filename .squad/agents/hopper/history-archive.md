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

