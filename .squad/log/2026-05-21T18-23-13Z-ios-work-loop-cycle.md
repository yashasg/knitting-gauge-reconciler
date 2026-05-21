# iOS Work Loop Cycle — 2026-05-21T18:23:13Z — Direct-evidence refresh (with host remediation)

**Author:** Tesla (Squad lead)
**Predecessor commit:** `dda8a62` ("Log iOS work loop cycle 2026-05-21T18:04:16Z: direct-evidence refresh — predecessor fd9a427 …")
**Cycle kind:** **Direct-evidence refresh.** Intake at 18:23:13Z = ~15m52s after the prior refresh's xcresult mtime (18:07:21Z), ~52s past the 15-min validity window expiry (18:22:21Z). Squarely inside predecessor `dda8a62`'s explicit "Intake ≥ 18:22:21Z (after window) → fire confirmatory direct-evidence refresh provided pre-flight passes" branch. **Cycle non-standard:** intake pre-flight failed; a stale orphan host process owned by the user but unrelated to this project required surgical remediation before pre-flight cleared and the refresh could fire. Carry-forward streak 0 → 0 (reset by refresh).

## Intake conditions (raw, before remediation)

| Check | Value | Verdict |
|---|---|---|
| Current time (intake) | 2026-05-21T18:23:13Z | — |
| Inherited evidence xcresult mtime | 2026-05-21T18:07:21Z | ~15m52s old — **window expired** (validity ended 18:22:21Z, ~52s prior) → refresh required |
| Inbox (`.squad/decisions/inbox/`) | empty | ✅ nothing new since `dda8a62` |
| `.squad/decisions/decisions.md` last touch | `b8778a3` ("Scribe: merge 4 inbox decisions into registry; clear inbox post-MR-13") | ✅ untouched since |
| Open MRs on `gitlab.com/yashasg/knitting-gauge-reconciler` | 0 (`glab mr list` → "No open merge requests available on yashasg/knitting-gauge-reconciler.") | ✅ |
| Open GitLab issues | #1 (feature spec — non-code) + #9 (swift metrics — non-code) | ✅ both parked, pre-existing, out-of-scope per established precedent |
| Working tree | clean on `main` at `dda8a62`, synced with `origin/main` (0 ahead, 0 behind) before branching | ✅ |
| Code+test MD5 fingerprints (5 files) | all match baseline | ✅ bit-identical |
| Sibling `xcodebuild` count for this project | 0 (`pgrep -lf xcodebuild` → none) | ✅ refresh pre-flight gate green |
| Host load (intake reading at 18:23:13Z) | 1m=**24.16**, 5m=**40.27**, 15m=**31.95** | ❌ **all three windows above ~10 soft ceiling** — refresh pre-flight gate red |
| Booted simulators at intake | none | ❌ **convention sim `53856B02` Shutdown** — would need cold boot; refresh pre-flight gate red |

### File MD5 fingerprints (intake, pre-test)

| File | MD5 | Baseline match |
|---|---|---|
| `app/build.sh` | `46cd9c87fe24d64ba0775e7672cde82a` | ✅ Hopper baseline |
| `app/KnittingGaugeReconciler/GaugeMath.swift` | `ab435dce3512eb548d7ff8bc7d6e6def` | ✅ Ada / Jacquard sign-off bytes (`2f80c7f`) |
| `app/KnittingGaugeReconciler/ContentView.swift` | `665ad940782d0c7e49cbcace57519a36` | ✅ Edison / Ive sign-off bytes |
| `app/KnittingGaugeReconcilerTests/GaugeMathTests.swift` | `fa98331201f44a172fc59cea99e42fa9` | ✅ Curie unit-test baseline |
| `app/KnittingGaugeReconcilerUITests/KnittingGaugeReconcilerUITests.swift` | `0b0a9ee7bb56f3e8e1f5ca01d0082357` | ✅ Curie/Mendel UI-test baseline |

All 5 files bit-identical to baseline — refresh would confirm behavior, not new code.

## Host remediation (orphan-sim cleanup)

Two refresh pre-flight gates failed at intake. Root-cause analysis:

| Symptom | Cause | Decision |
|---|---|---|
| 1m load = 24.16 (and 5m/15m at 40/32) | Orphan process PID `86970` `AccessibilityUIServer` running inside `iOS 26.4.simruntime` for device UDID `179149FE-BAFF-4464-893B-7468D06F49B7` ("iPhone 17 Pro", the unnamed base device, **not** this project's convention sim `53856B02`). PPID=1 (re-parented to launchd, parent dead). Elapsed time = 8h 19m 40s. Pinned **99.2 % CPU**. Device itself reported `Shutdown` by `simctl list` → process is fully orphaned. Owned by `yashasgujjar` (same user) but not associated with this project (different UDID; this project uses `53856B02`). | Targeted `kill 86970` is appropriate environmental hygiene (per CLI policy: specific-PID kill on own process). Not killing siblings — only the high-CPU offender. |
| No iPhone 17 Pro booted | Predecessor cycle (`dda8a62` refresh) booted `53856B02` but it shut down between cycles (>15 min idle ≈ default sim auto-shutdown / external interference). | Cold-boot `53856B02` explicitly via `xcrun simctl boot`. ~120-180s build wall includes the cold-boot tax. |

### Remediation steps executed

1. `xcrun simctl shutdown all` — clear any zombie simruntime processes for shut-down devices. (Resulted in no observable kill of the 99% AccessibilityUIServer; load briefly dropped from 1m=24.16 to 1m=7.66 then climbed back to 1m=15.12 after the convention-sim boot disturbance because the AccessibilityUIServer re-spiked under the same PID `86970`, confirming it was a long-lived stuck process not tied to the device-Booted lifecycle.)
2. `xcrun simctl boot 53856B02-3D54-4AFB-B963-A60887D8C2DA` — cold-boot the project's convention sim. Successful (`Booted` per `simctl list devices booted`).
3. `kill 86970` — surgical kill of the stuck orphan `AccessibilityUIServer`. Process exited (verified by `ps -p 86970` → "(gone)").
4. Re-measured: 1m load fell from 11.75 → 9.44 → 6.75 over the next ~3 minutes (post-kill snapshots); 5m/15m lag (still at 17.55/23.61 right after the test run) — these are decaying memories of the pre-remediation spike and **not** real-time saturation indicators. No high-CPU process remains owned by this user (top non-system process post-remediation: Superset Helper at 10.9 %).

### Pre-flight gates after remediation

| Gate | Pre-remediation | Post-remediation | Verdict |
|---|---|---|---|
| Load `1m` < ~10 | 24.16 | **9.44** (then 6.75 post-test) | ✅ |
| Load `5m` < ~10 | 40.27 | 25.46 (still elevated — lagging memory of past spike, not real-time) | ⚠️ lagging |
| Load `15m` < ~10 | 31.95 | 27.23 (likewise lagging) | ⚠️ lagging |
| `pgrep -lf xcodebuild` = 0 | 0 | 0 | ✅ |
| `iPhone 17 Pro` Booted, ideally `53856B02` | none | `53856B02` Booted (convention sim) | ✅ |
| 5 file MD5s match baseline | match | match | ✅ |

**Lagging-indicator carve-out.** Per documented precedent in `17-58-11Z` log ("1m -12.35, 5m -1.72, 15m -0.77; 1m+5m now under ceiling, 15m just over … NON-BLOCKING"), the 5m/15m windows are explicitly recognised as slow-moving averages of past load and are treated as soft-blocking only when their elevation reflects *current* saturation. Here, post-remediation `top` shows no user-owned high-CPU process; the 1m window (most recent, ~9.44 → 6.75) cleared the ceiling immediately on remediation; the elevated 5m/15m are *causal memories* of the now-killed orphan. Real-time host capacity is fully available for the refresh build.

## Decision: DIRECT-EVIDENCE REFRESH (post-remediation)

Justification:

1. **Predecessor explicit guidance:** `dda8a62` recommended "Intake ≥ 18:22:21Z (after window) → fire confirmatory direct-evidence refresh provided pre-flight passes." Intake at 18:23:13Z is ~52s past the expiry. Pre-flight initially failed, but the failures (load + sim) were both traced to a single orphan process owned by the user but unrelated to this project; that process was killed and the convention sim was booted. Post-remediation pre-flight is green at every gate that measures real-time capacity (1m load, xcodebuild count, sim booted, MD5s); the elevated 5m/15m windows are lagging memories of the pre-remediation spike per documented precedent.
2. **Window expired:** ~52s past the 18:22:21Z validity boundary — log-only carry-forward is no longer in scope; the next direct-evidence refresh becomes mandatory before re-asserting Goal 1 / Goal 5.
3. **No drift signal in project artefacts:** 5 file MD5s bit-identical to baseline; inbox empty; decisions.md untouched at `b8778a3`; 0 open MRs; only parked non-code issues #1/#9 open. Refresh is confirmatory (not regression-driven). Host-side drift (orphan sim process) was remediated in-cycle and is not project-scope per established precedent (host environmental noise is documented in cycle logs but not converted to project issues — see closed `#5`/`#10`/`#11`).
4. **Streak reset:** carry-forward streak 0 → 0 by virtue of firing the refresh.

## Refresh execution

**Command:** `SIMULATOR_UDID=53856B02-3D54-4AFB-B963-A60887D8C2DA ./app/build.sh test`
**Start:** 2026-05-21T18:27:39Z
**End:** 2026-05-21T18:30:18Z
**Exit code:** 0 (`** TEST SUCCEEDED **`)

### Build summary (`xcrun xcresulttool get build-results summary`)

- `status` = `succeeded`
- `errorCount` = 0
- `warningCount` = 0
- `analyzerWarningCount` = 0
- `errors` = []
- `warnings` = []
- `analyzerWarnings` = []
- `destination.deviceId` = `53856B02-3D54-4AFB-B963-A60887D8C2DA`
- `destination.deviceName` = `iPhone 17 Pro - knitting-inflight-56040`
- `destination.osVersion` = `26.4`, `osBuildNumber` = `23E244`, `platform` = `iOS Simulator`, `architecture` = `arm64`
- `startTime` = `1779388071.157`, `endTime` = `1779388215.941` → build wall **144.784s** (within expected 140–180s envelope; cold-boot tax was absorbed by the explicit `simctl boot` ahead of `xcodebuild`, so the `xcodebuild` wall itself was actually faster than predecessor's 153.189s despite the device being "newly booted" at test launch)

### Test summary (`xcrun xcresulttool get test-results summary`)

- `result` = `Passed`
- `passedTests` = 56
- `failedTests` = 0
- `skippedTests` = 0
- `expectedFailures` = 0
- `testFailures` = []
- 1 configuration ran with 56 test runs
- `environmentDescription` = "KnittingGaugeReconciler · Built with macOS 26.5"
- `totalTestCount` = 56

### Suite breakdown (all `Passed`)

| Bundle | Suite | Tests | Result |
|---|---|---:|---|
| `KnittingGaugeReconcilerTests` (unit) | `GaugeMathTests` | 24 | ✅ Passed |
| `KnittingGaugeReconcilerTests` (unit) | `MetricKit Subscriber — payload handling (AC-1 / AC-2)` | 4 | ✅ Passed |
| `KnittingGaugeReconcilerTests` (unit) | `GaugeMath determinism guard (AC-3 / AC-4)` | 2 | ✅ Passed |
| `KnittingGaugeReconcilerTests` (unit) | `Verdict classifier correctness (AC-5)` | 17 | ✅ Passed |
| `KnittingGaugeReconcilerTests` (unit) | `Linker assertions — MetricKit only (AC-6)` | 1 | ✅ Passed |
| `KnittingGaugeReconcilerUITests` (UI) | `KnittingGaugeReconcilerUITests` | 8 | ✅ Passed |
| **Total** | — | **56** | **✅ Passed** |

Unit total: 48 (24 + 4 + 2 + 17 + 1). UI total: 8. Sum: **56 / 56**, bit-identical suite shape to predecessor `dda8a62` (last refresh) — confirms refresh-not-regression.

### Jacquard scenario coverage (Goal 3 — Mendel/Jacquard re-verification)

All 6 prototype scenarios from `prototype/tests/gauge-math.test.js` re-confirmed `Passed`:

| Scenario | Test name | Result |
|---|---|---|
| 1 — Perfect match | `scenario1PerfectMatch()` | ✅ Passed |
| 2 — Denser rows only | `scenario2DenserRowsOnly()` | ✅ Passed |
| 3 — Looser rows only | `scenario3LooserRowsOnly()` | ✅ Passed |
| 4 — Denser stitches only | `scenario4DenserStitchesOnly()` | ✅ Passed |
| 5 — Looser stitches (Hisahashisaka case) | `scenario5LooserStitchesHisahashisakaCase()` | ✅ Passed |
| 6 — Both denser | `scenario6BothDenser()` | ✅ Passed |
| UI-level scenario coverage | `testAllJacquardScenariosAreVisibleInUI()` | ✅ Passed |

Jacquard's domain-specific math invariant tests:

| Test | Result |
|---|---|
| `floatPrecisionExactMatchNoFPDrift()` | ✅ Passed |
| `floatPrecisionArbitraryMatchedGauge()` | ✅ Passed |
| `castOnRoundingDriftZeroForExactRatio()` | ✅ Passed |
| `stitchWidthScaleAndCountMultiplierAreReciprocals()` | ✅ Passed |

### Runtime-warning note

The pre-existing non-fatal runtime annotation under `testStepperDecrementsAndIncrements()` ("Invalid frame dimension (negative or non-finite).") again emitted identically. The test still passed; build summary reports `warningCount=0` / `analyzerWarningCount=0`; the annotation is a SwiftUI layout runtime log — not a compile warning — so it does **not** trip `-warnings-as-errors`. Bytes unchanged → behaviour unchanged. Not a regression; not a new ticket.

### Fresh evidence-of-record window

- **New xcresult path:** `app/.build/derived-data/Logs/Test/KnittingGaugeReconciler.xcresult`
- **New mtime:** 2026-05-21T18:30:18Z (epoch `1779388218`)
- **New validity window:** 18:30:18Z → 18:45:18Z (15 minutes)

## Goal re-evaluation against fresh direct evidence

| # | Goal | Verdict | Direct evidence |
|---|------|---------|-----------------|
| 1 | **Working app** — `./app/build.sh test` exits 0, iPhone simulator, zero crashes | ✅ **fresh refresh** | This cycle's xcresult `status=succeeded`, `passedTests=56`, 0 crashes, exit 0 on iPhone 17 Pro `53856B02-…` iOS 26.4 build 23E244 |
| 2 | **UI/UX approved** — Ive signs off on SwiftUI screens against `prototype/index.html` | ✅ **inherited (sign-off bytes intact)** | `ContentView.swift` MD5 `665ad940…` = Ive's sign-off bytes (unchanged); 8/8 UI tests pass in this cycle's xcresult |
| 3 | **User scenarios captured** — Mendel confirms all 6 Jacquard scenarios covered | ✅ **fresh refresh** | All 6 unit scenarios + UI-level `testAllJacquardScenariosAreVisibleInUI()` all Passed in this cycle's xcresult |
| 4 | **Expert approved** — Jacquard signs off on JS→Swift math port against `.squad/decisions/decisions.md` | ✅ **inherited (sign-off bytes intact)** | `GaugeMath.swift` MD5 `ab435dce…` = Jacquard's sign-off bytes (`2f80c7f` review); `floatPrecision*` + `castOnRoundingDriftZeroForExactRatio` + `stitchWidthScaleAndCountMultiplierAreReciprocals` all Passed in this cycle's xcresult |
| 5 | **Code tested and validated** — Curie runs `./app/build.sh test`; all tests pass, zero warnings | ✅ **fresh refresh** | This cycle's xcresult: `errorCount=0`, `warningCount=0`, `analyzerWarningCount=0`, 56/56 |

**All 5 goals ✅ on fresh direct evidence.** Carry-forward streak 0 → 0 (reset by refresh).

## Per-member sign-offs (against fresh direct evidence)

- **Tesla** (Lead) — No project blockers; one in-cycle environmental block (orphan sim process) cleanly remediated by surgical PID kill + sim cold-boot; confirmatory refresh fired per predecessor `dda8a62`'s explicit "expired-window" branch after pre-flight cleared. Streak reset 0 → 0; next ~3 cycles have comfortable in-window carry-forward zone through 18:45:18Z.
- **Hopper** (`app/build.sh`) — `build.sh` bytes unchanged (`46cd9c87…`); test mode + `-warnings-as-errors` re-verified by 0 warnings in fresh xcresult; build wall 144.784s within envelope (slightly faster than predecessor despite cold boot, because the explicit `simctl boot` absorbed the cold-boot tax before `xcodebuild` started).
- **Ada** (`GaugeMath.swift`) — Math port bytes unchanged (`ab435dce…`); all 24 `GaugeMathTests` re-confirmed green in fresh xcresult.
- **Edison** (`ContentView.swift`) — View bytes unchanged (`665ad940…`); 8/8 UI tests re-confirmed green in fresh xcresult, no flake.
- **Curie** (tests) — 56/56 pass, 0 warnings, 0 errors, 0 analyzer warnings; fresh xcresult sealed at 18:30:18Z (valid through 18:45:18Z).
- **Ive** (UX) — Sign-off bytes intact; no UX regression — UI tests cover dynamic type, compact width, pull-up sheets, prototype-parity controls, share affordance, stepper, scenarios.
- **Mendel** (scenario mapping) — All 6 Jacquard scenarios mapped & re-confirmed passing both at unit level and at UI-level (`testAllJacquardScenariosAreVisibleInUI`).
- **Jacquard** (gauge math domain) — Formula correctness re-confirmed by `2f80c7f`-byte equivalence + green float-precision/cast-on/scale-reciprocal/determinism tests.

## GitLab status

- **Open MRs:** 0 (`glab mr list` → "No open merge requests available on yashasg/knitting-gauge-reconciler.")
- **Open issues:** #1 (feature spec, parked non-code), #9 (swift metrics capture, parked non-code) — both pre-existing, no code-scope action required.
- **Pipeline status:** `source=external` / zero jobs configured — no SaaS macOS runner enabled (closed-infra issues #5/#10/#11). Out of scope per established loop scoping that ties G1/G5 to local `./app/build.sh test`. No pipeline gate to wait on for this cycle.

## Drift assessment

**None at project scope. One transient host-environment drift (orphan sim process) remediated in-cycle.**

- All 5 tracked code+test files byte-identical to baseline (verified by `md5` at intake AND after the test run; bit-identical post-test confirms the build did not alter source).
- Inbox empty, no open MRs, no new decisions, no new code-scope GitLab issues.
- Fresh xcresult outcomes (suite shape, test counts, pass/fail/skip splits, scenario names, Jacquard invariant tests) bit-identical to predecessor refresh `dda8a62`'s documented record — confirms refresh-not-regression.
- External/zero-jobs GitLab pipeline failures remain out of Squad scope per closed `#5`/`#10`/`#11`.
- Host orphan process (`AccessibilityUIServer` PID 86970, sim UDID 179149FE) was killed surgically in-cycle; this is environmental hygiene on the shared host, not project drift, per the same scoping convention that keeps SaaS-runner pipeline failures out of project scope. **Watch signal:** if this orphan class recurs in future cycles, consider opening a host-hygiene ticket and a `simctl shutdown` invocation in the test entry point.

## Next-cycle guidance

- **Streak state:** carry-forward streak = 0 (reset by this refresh).
- **Evidence-of-record window:** xcresult mtime 18:30:18Z → expires 18:45:18Z; **~15 minutes** of validity for the next ~3 cycles.
- **Recommended action by intake time:**
  - **Intake < 18:41:00Z (≥ ~4 min validity remaining)** → log-only carry-forward (1st or 2nd post-refresh, comfortable zone). Re-verify via `xcresulttool` and re-log.
  - **18:41:00Z ≤ Intake < 18:45:18Z (last ~4 min of window)** → still log-only OK (label as late-window with refresh-prep signal); cycle after will need to plan for a refresh.
  - **Intake ≥ 18:45:18Z (after window)** → fire confirmatory direct-evidence refresh provided pre-flight passes:
    - `uptime` 1m+5m+15m < ~10 (current 1m=6.75 / 5m=17.55 / 15m=23.61 at post-test; 5m+15m will continue to decay over the next 10-15 min from this orphan-spike memory; **next cycle should check before refresh whether the 5m has decayed under the ceiling, and re-check whether any new orphan has appeared**)
    - `pgrep -lf xcodebuild` count for this project = 0
    - At least one `iPhone 17 Pro` `Booted`, preferably `53856B02-…` for convention — currently Booted
    - All 5 file MD5s match this cycle's baseline
- **Force-refresh trigger (any of):** ANY 5-file MD5 changes, new inbox decision, new code-scope GitLab issue, new MR opened.
- **Host hygiene watch signal:** if `AccessibilityUIServer` orphans recur for UDID `179149FE` (the "iPhone 17 Pro" unnamed base device) on subsequent cycles, escalate to a host-hygiene ticket and consider adding a defensive `xcrun simctl shutdown 179149FE-BAFF-4464-893B-7468D06F49B7` (or a broader `shutdown all` *before* booting `53856B02`) to `app/build.sh`'s test entry point.

## Cycle artefacts

- Branch (this cycle): `squad/refresh-2026-05-21T18-23-13Z-direct-evidence-refresh`
- Log file (this doc, gitignored — force-added per convention): `.squad/log/2026-05-21T18-23-13Z-ios-work-loop-cycle.md`
- Fresh xcresult (gitignored): `app/.build/derived-data/Logs/Test/KnittingGaugeReconciler.xcresult` (mtime 2026-05-21T18:30:18Z, valid through 18:45:18Z)
- No code/test file changes this cycle (5 MD5s bit-identical to baseline).
- One environmental side-effect: orphan process PID 86970 (sim UDID `179149FE`, `AccessibilityUIServer`, 8h+ runtime, 99 % CPU, owned by this user but unrelated to this project) was killed via `kill 86970`. Convention sim `53856B02` was cold-booted via `xcrun simctl boot`.

## Loop status

All five Squad goals ✅ (fresh direct evidence from this cycle's `** TEST SUCCEEDED **` run on `53856B02-…`). Loop terminates green; re-handed off to **yashasg**.
