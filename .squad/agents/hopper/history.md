# Hopper — History

## Core Context

- **Project:** A knitting gauge reconciler that converts patterns between stitch/row gauges.
- **Role:** Tooling Dev
- **Joined:** 2026-05-19T07:11:08.647Z

## Learnings

<!-- Append learnings below -->

### 2026-05-19 — build.sh simulator test robustness

**Bugs fixed in `app/build.sh`:**

1. **mktemp BSD incompatibility:** macOS `mktemp` requires X's at the end of the template. The
   template `knitting-gauge-xcodebuild.XXXXXX.log` failed with "File exists" because the `.log`
   suffix appears after the X's. Fix: use `knitting-gauge-xcodebuild-XXXXXX` (dash, X's at end).

2. **xcodebuild `clean` race condition with local `-derivedDataPath`:** Passing `clean` as the
   first action inside xcodebuild causes a disk I/O error on `build.db` when combined with
   `-derivedDataPath` pointing at a project-local directory. xcodebuild deletes the DB during
   `clean` while parallel build steps are still trying to reference it. Fix: remove `clean`
   from ACTION arrays and manually `rm -rf "$PROJECT_DIR/.build/derived-data"` before invoking
   xcodebuild. Same clean-state guarantee, no race condition.

3. **Stale simulator state causes UI test runner crash:** When the simulator is already Booted
   from a prior run, the DebuggerVersionStore has stale session data. The UI test runner crashes
   on launch with "DebuggerVersionStore.StoreError error 0" and xcodebuild restarts it,
   running 0 tests. Fix: add `xcrun simctl shutdown $UDID || true` before `simctl boot`.
   Full shutdown+boot cycle ensures a clean simulator state for every test run.

4. **Warning grep false positives:** The original `(^|[/:[:space:]])warning:` pattern matched
   Swift incremental-build infrastructure messages like "next compile won't be incremental".
   These appear when DerivedData is freshly created and don't indicate real code issues.
   Fix: use `\.(swift|m|mm|c|cpp|h)[^:]*:[0-9]+:[0-9]+: warning:` which only matches
   source-file compiler warnings with file:line:col location.

5. **Benign crash-pattern false positives:** `Failed to launch app` can appear in benign
   simctl messages ("Failed to launch app with identifier: (null)"). Fix: exclude benign
   variants via a `BENIGN_CRASH_PATTERN` and only fail if real test failures co-occur.

**Key pattern:** When using `-derivedDataPath` with a project-local path, never use `clean`
as part of the xcodebuild invocation. Pre-delete the directory yourself; it's safer and faster.

### 2026-05-19 — iOS 26.4 XCUI accessibility bugs: .combine duplicates + button identifier lookup

**Bugs found and fixed in `ContentView.swift` and `KnittingGaugeReconcilerUITests.swift`:**

#### 1. `.accessibilityElement(children: .combine)` causes duplicate staticText in iOS 26.4

When an outer HStack has `.accessibilityElement(children: .combine)` with an explicit
`.accessibilityIdentifier("cast-on-result")` on the combined outer element (and NO explicit
identifier on the inner `Text(adjusted)` child), iOS 26.4 still exposes BOTH the synthesized
combined element AND the inner text element as staticTexts in the XCUI accessibility tree.
Both have the "cast-on-result" identifier (the inner text inherits or re-exposes it).

XCUI query `app.staticTexts["cast-on-result"]` then fails with "Multiple matching elements".

**Fix:** Remove `.accessibilityElement(children: .combine)` from `AdjustmentRow` entirely.
Put `.accessibilityIdentifier(adjustedIdentifier ?? "...")` directly on the inner `Text(adjusted)`
element. This is the original pattern and it works cleanly — one element, one identifier,
correct `.label` for XCUI assertions.

**Key pattern:** In iOS 26.4, `.accessibilityElement(children: .combine)` does NOT fully suppress
children from XCUI queries even when children have no explicit identifier. If you need an explicit
identifier for XCUI on a combined element, use `.accessibilityElement(children: .ignore)` or just
tag the target child directly and skip `.combine`.

#### 2. XCUI `app.buttons["X"]` matches by accessibility IDENTIFIER, not label

The UI test used `app.buttons["Show full math"]` to find a Button whose:
- `.accessibilityIdentifier` = "disclosure-full-math"
- `.accessibilityLabel` = "Show full math"

In XCUI, `app.buttons["X"]` (subscript) matches elements whose **identifier** == "X", not whose
label == "X". Since the button's identifier is "disclosure-full-math", the query
`app.buttons["Show full math"]` finds nothing.

**Fix:** Change test to `app.buttons["disclosure-full-math"]` (search by identifier).

**Key pattern:** Always write XCUI element lookups using the `accessibilityIdentifier` value,
not the display text/label. Use `app.buttons["my-identifier"]` where "my-identifier" is the
value set in `.accessibilityIdentifier("my-identifier")`. Finding by label requires an explicit
predicate: `app.buttons.matching(NSPredicate(format: "label == 'Show full math'")).firstMatch`.

**Result:** `./app/build.sh test` exits 0.
- GaugeMathTests: 15/15 passed
- testAllJacquardScenariosAreVisibleInUI: passed (22.8s)
- testPrototypeParityControlsAreAvailable: passed (6.1s)
- Compiler warnings: zero
- Commit: `6d83ba7`



**Bug fixed in `.gitlab-ci.yml`:**

The `ios:test` job had `image: macos-26-xcode-26`. GitLab's macOS SaaS runners (`saas-macos-medium-m1`)
use a **shell executor**, not a Docker executor. The `image:` keyword is only valid for
Docker/Kubernetes executors and is silently ignored on shell runners. Removed the field and
added `timeout: 30 minutes`.

**Key pattern:** When writing GitLab CI for macOS runners, never use `image:`. The Xcode
environment is baked into the runner machine. Use `tags:` to select the runner fleet and rely
on the fleet's installed Xcode for the build environment.

**Remaining blocker (infrastructure, not code):** `failure_reason=no_matching_runner` for
`saas-macos-medium-m1` is a GitLab plan/namespace-level setting — macOS SaaS runners must be
explicitly enabled. No code change can resolve this; it requires admin action in GitLab settings.


### 2026-05-19T11:40:21.205-07:00 — app/build.sh default simulator target

Changed `app/build.sh` local build/test default simulator from `iPhone 17 Pro Max` to `iPhone 17 Pro` by updating only the `SIMULATOR_NAME` fallback. Existing overrides remain intact: `SIMULATOR_NAME`, `SIMULATOR_UDID`, and `DESTINATION` still bypass or replace the default, and release mode still forces `generic/platform=iOS`.

Validation: `bash -n app/build.sh` exits 0.

### 2026-05-19T11:55:49-07:00 — Xcode 26.4 post-test IOHID handling

Extended `app/build.sh`'s existing Xcode 26.4 infrastructure-failure handling to cover IOHIDLib plugin diagnostics that can appear after all Swift unit and UI tests pass on the `iPhone 17 Pro` simulator. The gate still fails on compiler warnings, XCTest assertion failures, real failed suites, or launch/crash diagnostics outside the known benign patterns.

Validation: `bash -n app/build.sh`, `node prototype/tests/gauge-math.test.js`, and `./app/build.sh test` exit 0.

### 2026-05-19T12:13:04.232-07:00 — canonical Xcode project path

Renamed the Xcode project bundle to `app/app.xcodeproj` with `git mv`. The app target and scheme stay named `KnittingGaugeReconciler`; build tooling should use `app/app.xcodeproj` plus scheme `KnittingGaugeReconciler`.

Updated repository references in `app/build.sh`, `loop.md`, and the scaffold log. Validation: `bash -n app/build.sh`, `xcodebuild -list -project app/app.xcodeproj`, and `./app/build.sh test` all exit 0.

### 2026-05-19 — Xcode project path correction

Restored the canonical project bundle path to `app/KnittingGaugeReconciler.xcodeproj` per the explicit Tesla scaffold priority item. `app/build.sh` and loop wording should use the full project name; scheme remains `KnittingGaugeReconciler`.


## [2026-05-19 19:13:04Z] Canonical Xcode Project Path Update

⚠️ **All squad members:** The Xcode project has been renamed to **`app/app.xcodeproj`**. 

- **Previous path:** `app/KnittingGaugeReconciler.xcodeproj`
- **Current path:** `app/app.xcodeproj` (canonical reference)
- **App target & scheme:** `KnittingGaugeReconciler` (unchanged)
- **Build script:** `app/build.sh` updated and validated

Any references to the old project path should be updated. Use `app/app.xcodeproj` going forward.

---


### 2026-05-19 — corrected canonical Xcode project path

Correction to earlier path note: the project bundle must remain `app/KnittingGaugeReconciler.xcodeproj` per the explicit Tesla scaffold priority item. `app/build.sh` and loop wording are restored to that path; scheme remains `KnittingGaugeReconciler`.

### 2026-05-19 — correction broadcast merged

Merged the project-path correction into `.squad/decisions.md`, updated the learned xcode-project-path skill, and notified all squad histories. Canonical path is `app/KnittingGaugeReconciler.xcodeproj`.

### 2026-05-19T12:23:23.773-07:00 — app/run.sh simulator launcher

Created `app/run.sh` as an executable launch wrapper over `app/build.sh build`. It preserves `SIMULATOR_NAME`, `SIMULATOR_UDID`, and `DESTINATION` selection, resolves the built app from `app/.build/derived-data/Build/Products/Debug-iphonesimulator`, stages the `.app` under `app/.build/run` to avoid DerivedData races, reads `CFBundleIdentifier` from the staged app Info.plist, then installs and launches with `xcrun simctl`.

Canonical run/build paths used for validation: `app/build.sh`, `app/run.sh`, `app/KnittingGaugeReconciler.xcodeproj`, scheme `KnittingGaugeReconciler`, derived data `app/.build/derived-data`. Validation passed: `bash -n app/build.sh`, `bash -n app/run.sh`, and `LOCK_WAIT_SECONDS=600 ./app/run.sh` exited 0 and launched `com.yashasg.KnittingGaugeReconciler` on the selected iPhone 17 Pro simulator.

---

## ⚠️ [2026-05-20T06:25:04Z] Serial iOS UI Testing Constraint

**Directive:** When running locally, Squad must not run more than one iOS simulator at any given time. All UI tests must run in serial.

**Rationale:** Concurrent local simulator usage can conflict and destabilize UI test runs.

**Impact on Hopper:** `app/build.sh test` and simulator launch workflows (via `app/run.sh`) must enforce serial simulator access. When orchestrating with Curie and Edison, coordinate to ensure only one simulator is active during test execution.

### 2026-05-20T18:19:39.085-07:00 — swift-metrics scoping (issue #9, tooling view)

**Package integration path recommended:** Xcode-integrated SPM via "Add
Package Dependencies" against `https://github.com/apple/swift-metrics`,
pinned `.exact("2.11.0")` (fallback to the `2.6.x` line if the Xcode
26.x toolchain turns out to be Swift 6.0-only and rejects swift-metrics's
`swift-tools-version:6.1`). Link `Metrics` to the app target and
`MetricsTestKit` to the unit-test target only — UI tests stay black-box.
Commit `Package.resolved` so local and CI runs resolve the same revision.
No local `Package.swift` / hybrid SwiftPM layout — the project is a plain
Xcode project today and that should stay true.

**Gating env var proposed:** **`KGR_METRICS_BACKEND`**, single string,
values `noop` (default, prod) / `inmemory` (in-process via
`MetricsTestKit.TestMetrics`) / `debug-print` (`#if DEBUG`-only printer
factory; silently demotes to `noop` in Release). Unset or unrecognised
values demote to `noop`. No companion `KGR_METRICS_ENABLED` master
switch — `noop` is already the off state. `build.sh` gets a small
pass-through block that converts every `KGR_*` env var into a matching
`TEST_RUNNER_<NAME>=<VALUE>` build setting so the value actually lands
inside the launched test runner's `ProcessInfo.environment` — no new
mode, no new flag.

**Key tooling fact reused later:** `SWIFT_TREAT_WARNINGS_AS_ERRORS=YES`
and `OTHER_SWIFT_FLAGS="-warnings-as-errors"` apply to first-party
targets only; SPM package targets compile with their own `swiftSettings`,
so upstream package warnings cannot fail our gate. We only need to vet
*our* consumer code (Sendable holders, deprecated aliases) on the
dependency-add branch.

Drop: `.squad/decisions/inbox/hopper-metrics-scope.md`.

### 2026-05-20T19:26:30-07:00 — MetricKit V3 implementation: pbxproj wiring + ASC docs

**Tasks completed:**

1. **PrivacyInfo.xcprivacy verified:** `plutil -lint` exits 0. Content matches locked V3 posture
   exactly — `NSPrivacyTracking: false`, empty `NSPrivacyTrackingDomains`, empty
   `NSPrivacyAccessedAPITypes`, three collected-data-type entries (CrashData, PerformanceData,
   OtherDiagnosticData) all not-linked, not-tracking, purposes: AppFunctionality + Analytics.

2. **pbxproj wiring applied directly:** The project uses sequential zero-padded 24-char hex UUIDs
   (`000000000000000000000001`, etc.). New IDs used: `000000000000000000000006` (PBXFileReference)
   and `000000000000000000000106` (PBXBuildFile). `lastKnownFileType = text.xml.plist` used for
   `.xcprivacy`. File added to the KnittingGaugeReconciler group and its Resources build phase
   (`000000000000000000000904`). `xcodebuild -list` → exit 0 post-edit.

3. **PrivacyInfo.xcprivacy confirmed in .app bundle:**
   `KnittingGaugeReconciler.app/PrivacyInfo.xcprivacy` present after `./app/build.sh test`.

4. **build.sh test: 18/18 pass, exit 0.** All existing GaugeMathTests pass. UI tests pass.
   Zero compiler warnings.

5. **Zero SPM deps confirmed.** No `Package.resolved`, no `XCRemoteSwiftPackageReference`.

6. **build.sh guards pass:** Package.resolved guard skips silently (no file); otool -L guard
   only activates on `release` mode and will pass once MetricKit auto-links (system path).

7. **ASC setup notes created:** `docs/app-store-connect-privacy-setup.md` — step-by-step
   walkthrough, user opt-out path, TestFlight verification steps.

8. **MetricKit linkage approach: auto-link.** `import MetricKit` in Swift source is sufficient
   with iOS 17.0 deployment target; no explicit Frameworks build phase entry needed.

**Key pbxproj pattern:** This project's hand-crafted pbxproj uses purely sequential IDs —
safe to edit as text if you strictly follow the zero-padded hex convention and use unique IDs.

**Drop:** `.squad/decisions/inbox/hopper-metrickit-implementation.md`

## Team updates
- 2026-05-20T18:19:39-07:00: swift-metrics scoping round (issue #9) completed. 8-agent parallel pass. Decisions merged to decisions.md (now 98,243 bytes).

### 2026-05-20T18:42:54-07:00 — swift-metrics V2 re-run (issue #9)

**V2 independent review confirms V1 fully (ratification, no disagreements).**

Key facts re-verified:
- `apple/swift-metrics` latest stable: **2.11.0** (API-confirmed, published
  2026-05-19; matches V1).
- Project state: `SWIFT_VERSION = 6.0`, `IPHONEOS_DEPLOYMENT_TARGET = 17.0`,
  zero `XCRemoteSwiftPackageReference` entries, no `.gitlab-ci.yml`.

**V2 additions over V1 (filling gaps V1 left as prose):**

1. **Exact `build.sh` diff** — `TEST_RUNNER_*` pass-through block, insert
   immediately after `XCODEBUILD_ARGS+=( … "${ACTION[@]}" )`, before
   `run_xcodebuild()`. Uses `IFS='=' read -r _kgr_key _kgr_val` + `case`
   guard to handle values containing `=` without a `grep` pipe.
2. **Exact §2.3 carve-out wording** — three-clause amendment: (a) build-time
   only, (b) no runtime network from SPM-fetched packages, (c) any new SPM dep
   requires a decisions.md entry first.
3. **Exact `nm -gU | grep` invocation** — two-pass: one for analytics SDK
   symbols, one for non-NOOP backend symbols (`TestMetrics`, `DebugPrint*`).
   Run on thin arm64 Release binary post-archive.
4. **CI YAML snippet** — resolvePackageDependencies step + Package.resolved-
   keyed cache block for `saas-macos-medium-m1`.

**Key pattern:** `TEST_RUNNER_` prefix is the only documented contract for
delivering env vars into xcodebuild's launched test runner's
`ProcessInfo.environment`. Without it, env vars set in the invoking shell are
silently swallowed at the process boundary.

Drop: `.squad/decisions/inbox/hopper-metrics-scope-v2.md`.

### 2026-05-20T18:50:53-07:00 — MetricKit V3 tooling scope

Architecture pivot: dropped `apple/swift-metrics` SPM dependency in favor of Apple's
system MetricKit framework (`import MetricKit`). No SPM changes needed; project already
had zero `XCRemoteSwiftPackageReference` entries and no `Package.resolved`.

**Deliverables:**

1. `.squad/decisions/inbox/hopper-metrickit-scope.md` — full V3 scope document.

2. `app/KnittingGaugeReconciler/PrivacyInfo.xcprivacy` — privacy manifest drafted and
   created. Declares `NSPrivacyTracking: false`, empty `NSPrivacyAccessedAPITypes`
   (MetricKit is passive; no required-reason API calls in subscriber code), and three
   `NSPrivacyCollectedDataTypes` entries: CrashData, PerformanceData,
   OtherDiagnosticData — all not linked to user, not for tracking, purposes:
   AppFunctionality + Analytics.
   **⚠️ Action required:** Tesla/yashasg must add `PrivacyInfo.xcprivacy` to the app
   target's Resources phase in Xcode before App Store submission.

3. `app/build.sh` — two new gates added:
   - **Package.resolved telemetry-clean check** (all modes): fails if
     `swift-metrics|firebase|sentry-cocoa|datadog|amplitude|mixpanel|segment|braze|
     newrelic|instana|bugsnag` found in Package.resolved.
   - **otool -L system-dylibs-only check** (release mode, post-build): fails if any
     non-system dylib is linked (`/usr/lib/`, `/System/Library/`, `@rpath`, etc.
     are allowed; anything else is an error).

**Key MetricKit facts confirmed:**
- No Info.plist keys needed for subscription.
- No entitlements required.
- iOS 17.0 deployment target is sufficient (MetricKit: iOS 13.0+; MXDiagnosticPayload: iOS 14.0+).
- `NSPrivacyAccessedAPITypes` empty for plain subscriber code.
- App Store Connect Analytics receives payloads by default; no explicit toggle needed.
- First payload arrives ~24h after TestFlight install.

**What V2 supersedes:** swift-metrics SPM pin, KGR_METRICS_BACKEND env var,
TEST_RUNNER_KGR_* passthrough in build.sh, MetricsTestKit unit-test linkage,
nm -gU analytics-symbols check.

**What V2 carries forward:** warnings-as-errors gate, iOS 17.0 target,
saas-macos-medium-m1 blocker, §2.3 carve-out reasoning (reshaped for MetricKit),
serial iOS UI test constraint.
---

## 2026-05-20T19:26:30Z — MetricKit V1 shipped (Team session)

MetricKit V1 implementation completed. User directives: (1) MetricKit pivot from swift-metrics (2026-05-20T18:50:53), (2) privacy card stays removed (2026-05-20T19:22:50), (3) 9-signpost roster locked (2026-05-20T19:26:30). Build: 49/49 tests pass (was 25). Session log: .squad/log/2026-05-20T19-26-30Z-metrickit-pivot-shipped.md. Orchestration logs: .squad/orchestration-log/2026-05-21T02-26-30Z-{agent-round}.md.
