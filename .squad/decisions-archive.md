### app/build.sh defaults to iPhone 17 Pro (2026-05-19T11:40:21.205-07:00)

**Author:** Hopper (Build/Tooling)  
**Status:** Implemented

Local `app/build.sh` build/test runs now default to the `iPhone 17 Pro` simulator instead of `iPhone 17 Pro Max`. Only the fallback `SIMULATOR_NAME` changed; all environment overrides remain preserved:
- `SIMULATOR_NAME` still selects a different simulator by name.
- `SIMULATOR_UDID` still selects a specific simulator directly.
- `DESTINATION` still bypasses simulator lookup.
- `release` still forces `generic/platform=iOS`.

Validation: `bash -n app/build.sh`, `node prototype/tests/gauge-math.test.js`, and `./app/build.sh test` exit 0 on the iPhone 17 Pro simulator.

Follow-up: `app/build.sh` treats the Xcode 26.4 IOHIDLib post-test infrastructure diagnostic as benign only after xcodebuild reports successful Swift unit/UI test completion and no failed suites or test cases. Compiler warnings and real test failures still fail the gate.

---

### Tesla — Goal external gate blocked (2026-05-19T17:53:34Z, ongoing P0)

**Author:** Tesla (Integration Testing)  
**Status:** Blocked — GitLab access unavailable from this environment

The iOS validation branch is pushed and local gates pass, but GitLab project, merge request, and pipeline checks are inaccessible (`404 Project Not Found` via API, MR web redirects to sign-in/403). Latest retries as of 2026-05-19T18:42:01Z confirm:
- Local gates still pass: `node prototype/tests/gauge-math.test.js` exited 0 with 77 passed, 0 failed, 0 pending; `./app/build.sh test` exited 0 with `** TEST SUCCEEDED **`.
- Curie warning gate remains clean: `app/build.sh` completed with warnings-as-errors enabled.
- Branch push succeeded; latest local and remote ref is `a463c87cf6df421cc5ea5431a8b8f00f2d3f62d2`.
- GitLab access is still blocked: no `GITLAB_TOKEN`; project, branch, pipeline, and MR API endpoints return `404 Project Not Found`.
- GitLab issue creation still blocked: unauthenticated issue creation returns `401 Unauthorized`.

Merge remains blocked until GitLab access is restored and the latest branch/MR pipeline is verified green.

---

### Cast-On Stitch Count UX & Implementation (2026-05-19)

**Authors:** Ive (UX), Ada (Implementation), Curie (QA)  
**Status:** Implemented and tested

#### Decision: Add actionable cast-on input and output (gitlab#1, comment 2)

Pattern's cast-on count is now adjustable per gauge. When stitch gauge differs from pattern, adjusted cast-on replaces vague "pick a different pattern size" advice.

**Formula:** `actStitches = patCastOn × (your_st / pattern_st)` with Math.round()

**Defaults:** `patCastOn: 128` stitches (40 cm at 32 st/10cm — typical small-to-medium sweater)

**Drift pill:** Shown when rounding causes ≥3% width variance (safety net for degenerate ratios only; normal use case < 2.5% drift).

**URL short:** `pc` (pattern cast-on)

**Verdict copy overhaul:** All four branches now name the specific adjusted stitch count instead of suggesting pattern size swap.

**Accessiblity:** VoiceOver reads "Pattern says, 128, stitches to cast on"; `aria-describedby` links hint text; focus order unchanged (cast-on input after increase-row spacing).

**Files:** prototype/index.html, prototype/tests/gauge-math.test.js

#### Spec Clarifications (Curie notes — action for Jacquard)

**Scenario 5 stitch scale:** Jacquard's test scenarios use `ps/ys` for display width ratio (matches code & Scenario 4). Scenario 5's expected value 0.875 is the *stitch count multiplier* `ys/ps` — a separate output. Recommend clarifying spec column header.

**Scenario 6 increase spacing:** Expected tuple lists 10.7 but formula yields 8.0. Likely copy error. Code correctly computes 8. Recommend spec update to 8.0.

Neither is a code bug; both are spec documentation items for Jacquard to resolve in a future pass.

---

## Test Coverage Audit — Jacquard Scenario Mapping (2026-05-19)

**Author:** Mendel (User Researcher)  
**Status:** CONFIRMED — All 6 scenarios covered at unit and UI levels

### Xcode project path correction (2026-05-19T12:33:46-07:00)

**Author:** Hopper (Build/Tooling)
**Status:** Corrected

The Xcode project bundle remains `app/KnittingGaugeReconciler.xcodeproj` to honor Tesla's explicit scaffold work item and the current repository state. The earlier note naming `app/app.xcodeproj` is superseded.

- **Canonical project path:** `app/KnittingGaugeReconciler.xcodeproj`
- **App target & scheme preserved:** `KnittingGaugeReconciler` (unchanged)
- **Updated references:** `app/build.sh` PROJECT path and squad loop references use the full project name
- **Validation:** bash -n app/build.sh, xcodebuild -list -project app/KnittingGaugeReconciler.xcodeproj, and ./app/build.sh test exit 0

**Note:** This supersedes the 2026-05-19T12:13:04.232-07:00 shorthand rename note. Use `app/KnittingGaugeReconciler.xcodeproj` going forward.

---

### 2026-05-19T13:13:20.141-07:00: User directive
**By:** yashasg (via Copilot)
**What:** Do exactly what the user asks from now on; do not expand scope or run extra validation/execution unless explicitly requested.
**Why:** User request — captured for team memory

# Decision: `app/run.sh` is the simulator launch entrypoint

- **Date:** 2026-05-19T12:23:23.773-07:00
- **Owner:** Hopper
- **Status:** Accepted

## Context

Developers need one command that builds the iOS app and launches it on the same simulator selection path used by `app/build.sh`.

## Decision

Use `app/run.sh` as the developer simulator launch entrypoint. It delegates compilation to `app/build.sh build`, preserves `SIMULATOR_NAME`, `SIMULATOR_UDID`, and `DESTINATION`, locates the built simulator `.app` under `app/.build/derived-data`, reads the bundle identifier from the built app metadata, stages the app under `app/.build/run`, then installs and launches via `xcrun simctl`.

## Rationale

Build policy stays centralized in `app/build.sh`; `app/run.sh` owns only launch-specific simulator plumbing. Staging the app before install avoids races when other build/test runs clean DerivedData after this build completes.

# Tesla — GitLab external gate blocked

**Goal:** Cycle step 4 / merge gate  
**Status:** Blocked — GitLab project and pipeline state are inaccessible from this environment  
**Branch:** `squad/ios-work-loop-validation`  
**Local/remote ref:** `c0a9b4adc7c396814024b1590280a084f1246a71`

## Local validation

- `bash -n app/build.sh` exits 0.
- `xcodebuild -list -project app/KnittingGaugeReconciler.xcodeproj` exits 0.
- `node prototype/tests/gauge-math.test.js` exits 0 with 77 passed, 0 failed, 0 pending.
- `./app/build.sh test` exits 0 after a simulator reboot retry for Xcode/CoreSimulator launch-state instability.
- Warning gate remains enforced with `SWIFT_TREAT_WARNINGS_AS_ERRORS=YES`, `GCC_TREAT_WARNINGS_AS_ERRORS=YES`, `CLANG_TREAT_WARNINGS_AS_ERRORS=YES`, and `OTHER_SWIFT_FLAGS="-warnings-as-errors"`.

## Blocker

- `GITLAB_TOKEN` is not present.
- GitLab project, branch, pipeline, and merge-request API endpoints return `404 Project Not Found`.
- Branch push is up to date, but the pipeline cannot be verified green and the branch must not be merged into `main` until GitLab access is restored.

## Required unblock

Provide GitLab credentials/project visibility that can read `yashasg/knitting-gauge-reconciler`, branch `squad/ios-work-loop-validation`, and the associated MR/pipeline state. Then verify the latest pipeline is green before merging into `main`.

# Decision: `app/run.sh` delegates build policy to `app/build.sh`

- **Date:** 2026-05-19T13:06:06.205-07:00
- **Owner:** Tesla
- **Status:** Accepted

## Context

Developers need a single command to build, install, and launch the iOS app on a simulator. The project already centralizes Xcode settings, derived data, simulator destination, and warning-as-error policy in `app/build.sh`.

## Decision

`app/run.sh` is the canonical developer launch entrypoint. It must call `app/build.sh build` for compilation and then handle only launch-specific responsibilities: locating the built `.app`, resolving the bundle identifier, booting the selected simulator, installing, and launching.

## Alternatives Considered

1. **Duplicate xcodebuild flags in `run.sh`** — simpler standalone script, but build policy would drift.
2. **Teach `build.sh` a run mode** — centralizes all behavior, but broadens a build script into lifecycle orchestration.
3. **Keep `run.sh` as a thin wrapper over `build.sh`** — small launch-specific duplication, but preserves one build-policy source.

## Trade-off

We accept a little simulator plumbing in `run.sh` to keep `build.sh` boring and stable. Build policy remains centralized; run ergonomics improve without creating a second Xcode configuration surface.

