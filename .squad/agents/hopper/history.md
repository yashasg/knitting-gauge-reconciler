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
