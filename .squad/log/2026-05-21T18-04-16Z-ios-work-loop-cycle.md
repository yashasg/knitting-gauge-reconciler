# iOS Work Loop Cycle — 2026-05-21T18:04:16Z — Direct-evidence refresh

**Author:** Tesla (Squad lead)
**Predecessor commit:** `fd9a427` ("Log iOS work loop cycle 2026-05-21T17:58:11Z: log-only carry-forward (2nd post-refresh, late-window / refresh-prep) — predecessor de111b5 …")
**Cycle kind:** **Direct-evidence refresh.** Intake at 18:04:16Z = ~15m50s after the prior refresh's xcresult mtime (17:48:26Z), ~50s past the 15-min validity window expiry (18:03:26Z). Squarely inside predecessor `fd9a427`'s explicit "Intake ≥ 18:03:26Z (after window, expected case) → fire confirmatory direct-evidence refresh provided pre-flight passes" branch. Carry-forward streak 2 → 0 (reset by refresh).

## Intake conditions

| Check | Value | Verdict |
|---|---|---|
| Current time (intake) | 2026-05-21T18:04:16Z | — |
| Inherited evidence xcresult mtime | 2026-05-21T17:48:26Z | ~15m50s old — **window expired** (validity ended 18:03:26Z, ~50s prior) → refresh required |
| Inbox (`.squad/decisions/inbox/`) | empty | ✅ nothing new since `fd9a427` |
| `.squad/decisions/decisions.md` last touch | `b8778a3` ("Scribe: merge 4 inbox decisions into registry; clear inbox post-MR-13") | ✅ untouched since |
| Open MRs on `gitlab.com/yashasg/knitting-gauge-reconciler` | 0 (`glab mr list` → "No open merge requests available on yashasg/knitting-gauge-reconciler.") | ✅ |
| Open GitLab issues | #1 (feature spec — non-code) + #9 (swift metrics — non-code) | ✅ both parked, pre-existing, out-of-scope per established precedent |
| Working tree | clean on `main` at `fd9a427`, synced with `origin/main` (0 ahead, 0 behind) before branching | ✅ |
| Code+test MD5 fingerprints (5 files) | all match baseline | ✅ bit-identical |
| Sibling `xcodebuild` count for this project | 0 (`pgrep -lf xcodebuild` → none) | ✅ refresh pre-flight gate green |
| Host load (intake reading at 18:04:16Z) | 1m=2.45, 5m=5.25, 15m=8.50 | ✅ all < ~10 soft ceiling — refresh pre-flight gate green |
| Booted simulators at intake | `iPhone 17 Pro - knitting-inflight-56040 (53856B02-3D54-4AFB-B963-A60887D8C2DA)` Booted | ✅ convention sim still booted from refresh `93c84d4` (no cold-boot needed) |

### File MD5 fingerprints (intake, pre-test)

| File | MD5 | Baseline match |
|---|---|---|
| `app/build.sh` | `46cd9c87fe24d64ba0775e7672cde82a` | ✅ Hopper baseline |
| `app/KnittingGaugeReconciler/GaugeMath.swift` | `ab435dce3512eb548d7ff8bc7d6e6def` | ✅ Ada / Jacquard sign-off bytes (`2f80c7f`) |
| `app/KnittingGaugeReconciler/ContentView.swift` | `665ad940782d0c7e49cbcace57519a36` | ✅ Edison / Ive sign-off bytes |
| `app/KnittingGaugeReconcilerTests/GaugeMathTests.swift` | `fa98331201f44a172fc59cea99e42fa9` | ✅ Curie unit-test baseline |
| `app/KnittingGaugeReconcilerUITests/KnittingGaugeReconcilerUITests.swift` | `0b0a9ee7bb56f3e8e1f5ca01d0082357` | ✅ Curie/Mendel UI-test baseline |

All 5 files bit-identical to baseline — refresh confirms behavior, not new code.

## Decision: DIRECT-EVIDENCE REFRESH

Justification:

1. **Predecessor explicit guidance:** `fd9a427` recommended "Intake ≥ 18:03:26Z (after window, expected case) → fire confirmatory direct-evidence refresh provided pre-flight passes." Intake at 18:04:16Z is ~50s past the expiry; all refresh pre-flight gates are green (load <10 across all three windows, 0 sibling xcodebuild, convention sim `53856B02` still booted, 5-file MD5s match baseline).
2. **Window expired:** ~50s past the 18:03:26Z validity boundary — log-only carry-forward is no longer in scope; the next direct-evidence refresh becomes mandatory before re-asserting Goal 1 / Goal 5.
3. **No drift signal:** 5 file MD5s bit-identical to baseline; inbox empty; decisions.md untouched at `b8778a3`; 0 open MRs; only parked non-code issues #1/#9 open. Refresh is confirmatory (not regression-driven).
4. **Streak reset:** carry-forward streak 2 → 0 by virtue of firing the refresh.

## Refresh execution

**Command:** `SIMULATOR_UDID=53856B02-3D54-4AFB-B963-A60887D8C2DA ./app/build.sh test`
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
- `startTime` = `1779386686.407`, `endTime` = `1779386839.596` → build wall **153.189s** (within expected 140–180s envelope; no cold-boot tax since `53856B02` already booted)

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

Unit total: 48 (24 + 4 + 2 + 17 + 1). UI total: 8. Sum: **56 / 56**, bit-identical suite shape to predecessor `93c84d4` (last refresh) — confirms refresh-not-regression.

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
- **New mtime:** 2026-05-21T18:07:21Z (epoch `1779386841`)
- **New validity window:** 18:07:21Z → 18:22:21Z (15 minutes)

## Goal re-evaluation against fresh direct evidence

| # | Goal | Verdict | Direct evidence |
|---|------|---------|-----------------|
| 1 | **Working app** — `./app/build.sh test` exits 0, iPhone simulator, zero crashes | ✅ **fresh refresh** | This cycle's xcresult `status=succeeded`, `passedTests=56`, 0 crashes, exit 0 on iPhone 17 Pro `53856B02-…` iOS 26.4 build 23E244 |
| 2 | **UI/UX approved** — Ive signs off on SwiftUI screens against `prototype/index.html` | ✅ **inherited (sign-off bytes intact)** | `ContentView.swift` MD5 `665ad940…` = Ive's sign-off bytes (unchanged); 8/8 UI tests pass in this cycle's xcresult |
| 3 | **User scenarios captured** — Mendel confirms all 6 Jacquard scenarios covered | ✅ **fresh refresh** | All 6 unit scenarios + UI-level `testAllJacquardScenariosAreVisibleInUI()` all Passed in this cycle's xcresult |
| 4 | **Expert approved** — Jacquard signs off on JS→Swift math port against `.squad/decisions/decisions.md` | ✅ **inherited (sign-off bytes intact)** | `GaugeMath.swift` MD5 `ab435dce…` = Jacquard's sign-off bytes (`2f80c7f` review); `floatPrecision*` + `castOnRoundingDriftZeroForExactRatio` + `stitchWidthScaleAndCountMultiplierAreReciprocals` all Passed in this cycle's xcresult |
| 5 | **Code tested and validated** — Curie runs `./app/build.sh test`; all tests pass, zero warnings | ✅ **fresh refresh** | This cycle's xcresult: `errorCount=0`, `warningCount=0`, `analyzerWarningCount=0`, 56/56 |

**All 5 goals ✅ on fresh direct evidence.** Carry-forward streak 2 → 0 (reset by refresh).

## Per-member sign-offs (against fresh direct evidence)

- **Tesla** (Lead) — No blockers; no drift; confirmatory refresh fired per predecessor `fd9a427`'s explicit "expired-window" branch. Streak reset 2 → 0; next ~3 cycles have comfortable in-window carry-forward zone through 18:22:21Z.
- **Hopper** (`app/build.sh`) — `build.sh` bytes unchanged (`46cd9c87…`); test mode + `-warnings-as-errors` re-verified by 0 warnings in fresh xcresult; build wall 153.189s within envelope.
- **Ada** (`GaugeMath.swift`) — Math port bytes unchanged (`ab435dce…`); all 24 `GaugeMathTests` re-confirmed green in fresh xcresult.
- **Edison** (`ContentView.swift`) — View bytes unchanged (`665ad940…`); 8/8 UI tests re-confirmed green in fresh xcresult, no flake.
- **Curie** (tests) — 56/56 pass, 0 warnings, 0 errors, 0 analyzer warnings; fresh xcresult sealed at 18:07:21Z (valid through 18:22:21Z).
- **Ive** (UX) — Sign-off bytes intact; no UX regression — UI tests cover dynamic type, compact width, pull-up sheets, prototype-parity controls, share affordance, stepper, scenarios.
- **Mendel** (scenario mapping) — All 6 Jacquard scenarios mapped & re-confirmed passing both at unit level and at UI-level (`testAllJacquardScenariosAreVisibleInUI`).
- **Jacquard** (gauge math domain) — Formula correctness re-confirmed by `2f80c7f`-byte equivalence + green float-precision/cast-on/scale-reciprocal/determinism tests.

## GitLab status

- **Open MRs:** 0 (`glab mr list` → "No open merge requests available on yashasg/knitting-gauge-reconciler.")
- **Open issues:** #1 (feature spec, parked non-code), #9 (swift metrics capture, parked non-code) — both pre-existing, no code-scope action required.
- **Pipeline status:** `source=external` / zero jobs configured — no SaaS macOS runner enabled (closed-infra issues #5/#10/#11). Out of scope per established loop scoping that ties G1/G5 to local `./app/build.sh test`. No pipeline gate to wait on for this cycle.

## Drift assessment

**None.**

- All 5 tracked code+test files byte-identical to baseline (verified by `md5` at intake, re-confirmed by `xcresult` outcomes after fresh test run).
- Inbox empty, no open MRs, no new decisions, no new code-scope GitLab issues.
- Fresh xcresult outcomes (suite shape, test counts, pass/fail/skip splits, scenario names, Jacquard invariant tests) bit-identical to predecessor refresh `93c84d4`'s documented record — confirms refresh-not-regression.
- External/zero-jobs GitLab pipeline failures remain out of Squad scope per closed `#5`/`#10`/`#11`.

## Next-cycle guidance

- **Streak state:** carry-forward streak = 0 (reset by this refresh).
- **Evidence-of-record window:** xcresult mtime 18:07:21Z → expires 18:22:21Z; **~15 minutes** of validity for the next ~3 cycles.
- **Recommended action by intake time:**
  - **Intake < 18:18:00Z (≥ ~4 min validity remaining)** → log-only carry-forward (1st or 2nd post-refresh, comfortable zone). Re-verify via `xcresulttool` and re-log.
  - **18:18:00Z ≤ Intake < 18:22:21Z (last ~4 min of window)** → still log-only OK (label as late-window with refresh-prep signal); cycle after will need to plan for a refresh.
  - **Intake ≥ 18:22:21Z (after window)** → fire confirmatory direct-evidence refresh provided pre-flight passes:
    - `uptime` 1m+5m+15m < ~10 (current 1m=2.45 / 5m=5.25 / 15m=8.50 at 18:04:16Z — comfortably under ceiling)
    - `pgrep -lf xcodebuild` count for this project = 0
    - At least one `iPhone 17 Pro` `Booted`, preferably `53856B02-…` for convention — currently Booted
    - All 5 file MD5s match this cycle's baseline
- **Force-refresh trigger (any of):** ANY 5-file MD5 changes, new inbox decision, new code-scope GitLab issue, new MR opened.

## Cycle artefacts

- Branch (this cycle): `squad/refresh-2026-05-21T18-04-16Z-direct-evidence-refresh`
- Log file (this doc, gitignored — force-added per convention): `.squad/log/2026-05-21T18-04-16Z-ios-work-loop-cycle.md`
- Fresh xcresult (gitignored): `app/.build/derived-data/Logs/Test/KnittingGaugeReconciler.xcresult` (mtime 2026-05-21T18:07:21Z, valid through 18:22:21Z)
- No code/test file changes this cycle (5 MD5s bit-identical to baseline).

## Loop status

All five Squad goals ✅ (fresh direct evidence from this cycle's `** TEST SUCCEEDED **` run on `53856B02-…`). Loop terminates green; re-handed off to **yashasg**.
