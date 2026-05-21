# iOS Work Loop Cycle — 2026-05-21T17:44:56Z — Direct-Evidence Refresh

**Author:** Tesla (Squad lead)
**Predecessor commit:** `ded9c18` ("Log iOS work loop cycle 2026-05-21T17:40:23Z: log-only carry-forward (2nd post-refresh) — predecessor 9fcc396 …")
**Cycle kind:** **Direct-evidence refresh.** Intake at 17:44:56Z = ~14m35s after inherited xcresult mtime (17:30:21Z), leaving only ~25s of 15-min validity remaining before expiry at 17:45:21Z. Per predecessor `ded9c18`'s explicit next-cycle guidance — *"if intake is near 17:45:21Z (say ≥ 17:44:00Z) STRONGLY prefer firing a refresh anyway, even slightly inside the window, to keep audit trail healthy (matching the `2104116` precedent which fired a refresh with ~50s of validity remaining)"* — and with all refresh pre-flight gates green, a fresh `./app/build.sh test` was the correct action. Carry-forward streak 2 → 0 (reset by refresh).

## Intake conditions

| Check | Value | Verdict |
|---|---|---|
| Current time (intake) | 2026-05-21T17:44:56Z | — |
| Inherited evidence xcresult mtime | 2026-05-21T17:30:21Z | ~14m35s old at intake — **~25s validity remaining** (window expires 17:45:21Z) |
| Inbox (`.squad/decisions/inbox/`) | empty | ✅ nothing new since `ded9c18` |
| `.squad/decisions/decisions.md` last touch | `b8778a3` ("Scribe: merge 4 inbox decisions into registry; clear inbox post-MR-13") | ✅ untouched since |
| Open MRs on `gitlab.com/yashasg/knitting-gauge-reconciler` | 0 (`glab mr list` → "No open merge requests available on yashasg/knitting-gauge-reconciler.") | ✅ |
| Open GitLab issues | #1 (feature spec — non-code) + #9 (swift metrics — non-code) | ✅ both parked, pre-existing, out-of-scope per established precedent |
| Closed code-scope issues | #2–#8, #10–#19 all closed | ✅ no new code-scope tickets |
| Working tree | clean on `main` at `ded9c18`, synced with `origin/main` (0 ahead, 0 behind) before branching | ✅ |
| Code+test MD5 fingerprints (5 files) | all match baseline | ✅ bit-identical |
| Sibling `xcodebuild` count (intake) | 0 (`pgrep -lf xcodebuild` → no matches) | ✅ |
| Host load (intake) | 1m=7.61, 5m=8.85, 15m=9.16 | ✅ all <10 (≈within ~1 of soft ceiling; refresh-eligible) |
| Booted simulators at intake | none (`xcrun simctl list devices booted` → empty under iOS 26.4) | ⚠️ pre-flight required boot — performed below |

### File MD5 fingerprints (intake)

| File | MD5 | Baseline match |
|---|---|---|
| `app/build.sh` | `46cd9c87fe24d64ba0775e7672cde82a` | ✅ Hopper baseline |
| `app/KnittingGaugeReconciler/GaugeMath.swift` | `ab435dce3512eb548d7ff8bc7d6e6def` | ✅ Ada / Jacquard sign-off bytes (`2f80c7f`) |
| `app/KnittingGaugeReconciler/ContentView.swift` | `665ad940782d0c7e49cbcace57519a36` | ✅ Edison / Ive sign-off bytes |
| `app/KnittingGaugeReconcilerTests/GaugeMathTests.swift` | `fa98331201f44a172fc59cea99e42fa9` | ✅ Curie unit-test baseline |
| `app/KnittingGaugeReconcilerUITests/KnittingGaugeReconcilerUITests.swift` | `0b0a9ee7bb56f3e8e1f5ca01d0082357` | ✅ Curie/Mendel UI-test baseline |

All 5 files bit-identical to the baseline — refresh will be **confirmatory**, not regression-revealing.

## Decision: DIRECT-EVIDENCE REFRESH

Justification:

1. **Predecessor explicit guidance:** `ded9c18` flagged the ≥17:44:00Z intake window as the "STRONGLY prefer firing a refresh anyway, even slightly inside the window" boundary, citing `2104116`'s precedent (refresh fired with ~50s of validity remaining).
2. **Validity window critically thin:** ~25s remaining at intake; almost certainly lapses before completion of any contemplated log-only path, and definitely lapses before next typical inter-cycle gap (4–10min).
3. **Streak boundary:** carry-forward streak at 2; a log-only this cycle would land at 3 (boundary of the "approaches the 4-cycle warning threshold" zone). Refreshing now resets to 0 and keeps audit trail healthy.
4. **All pre-flight gates green:** load 7.61/8.85/9.16 <10 (all three windows), 0 sibling `xcodebuild`, working tree clean, 5 MD5s bit-identical, inbox empty, 0 open MRs, no new code-scope issues. Only blocker was no booted sim — resolved below by booting convention sim `53856B02-…`.
5. **Confirmatory expectation:** since all 5 source/test files are bit-identical to baseline, expected outcome is 56/56 pass with 0 warnings, matching predecessor xcresult exactly. Any divergence would itself be high-value drift evidence.

## Pre-flight: simulator boot

`xcrun simctl list devices booted` showed no booted iOS 26.4 devices at intake. Per convention `53856B02-3D54-4AFB-B963-A60887D8C2DA` (`iPhone 17 Pro - knitting-inflight-56040`) was booted explicitly:

```
$ xcrun simctl boot 53856B02-3D54-4AFB-B963-A60887D8C2DA
$ xcrun simctl list devices booted
== Devices ==
-- iOS 26.4 --
    iPhone 17 Pro - knitting-inflight-56040 (53856B02-3D54-4AFB-B963-A60887D8C2DA) (Booted)
```

## Build command and outcome

```
$ SIMULATOR_UDID=53856B02-3D54-4AFB-B963-A60887D8C2DA ./app/build.sh test
```

Build wall: ~152.9s (xcresult `startTime` 1779385551.171 → `endTime` 1779385704.061 = **152.890s**). Within expected 140–180s envelope with cold-boot tax. Final stdout line: `** TEST SUCCEEDED **`, exit 0.

### Sealed xcresult

**Path:** `app/.build/derived-data/Logs/Test/KnittingGaugeReconciler.xcresult`
**mtime:** 2026-05-21T17:48:26Z (validity window through 2026-05-21T18:03:26Z)
**Device:** iPhone 17 Pro - knitting-inflight-56040 (`53856B02-3D54-4AFB-B963-A60887D8C2DA`), iOS 26.4, build 23E244, arm64
**Built with:** macOS 26.5

### Build summary (`xcrun xcresulttool get build-results summary`)

- `status` = `succeeded`
- `errorCount` = 0
- `warningCount` = 0
- `analyzerWarningCount` = 0
- `errors` = []
- `warnings` = []
- `analyzerWarnings` = []
- `destination.deviceId` = `53856B02-3D54-4AFB-B963-A60887D8C2DA`
- `destination.osVersion` = `26.4`, `osBuildNumber` = `23E244`, `platform` = `iOS Simulator`, `architecture` = `arm64`

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

### Suite breakdown (all `Passed`, walked via `xcresulttool get test-results tests`)

| Bundle | Suite | Tests | Result |
|---|---|---:|---|
| `KnittingGaugeReconcilerTests` (unit) | `GaugeMathTests` | 24 | ✅ Passed |
| `KnittingGaugeReconcilerTests` (unit) | `MetricKit Subscriber — payload handling (AC-1 / AC-2)` | 4 | ✅ Passed |
| `KnittingGaugeReconcilerTests` (unit) | `GaugeMath determinism guard (AC-3 / AC-4)` | 2 | ✅ Passed |
| `KnittingGaugeReconcilerTests` (unit) | `Verdict classifier correctness (AC-5)` | 17 | ✅ Passed |
| `KnittingGaugeReconcilerTests` (unit) | `Linker assertions — MetricKit only (AC-6)` | 1 | ✅ Passed |
| `KnittingGaugeReconcilerUITests` (UI) | `KnittingGaugeReconcilerUITests` | 8 | ✅ Passed |
| **Total** | — | **56** | **✅ Passed** |

Unit total: 48 (24 + 4 + 2 + 17 + 1). UI total: 8. Sum: **56 / 56**, bit-identical to predecessor inheritance counts — refresh confirmed predecessor evidence.

### Jacquard scenario coverage (Goal 3 — Mendel/Jacquard direct verification)

All 6 prototype scenarios from `prototype/tests/gauge-math.test.js` present and `Passed`:

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

One non-fatal runtime annotation surfaced under `testStepperDecrementsAndIncrements()`: *"Invalid frame dimension (negative or non-finite)."* — the test still passed, and the build summary reports `warningCount=0` / `analyzerWarningCount=0`. This is a SwiftUI layout runtime log, not a compile warning, and does **not** trip `-warnings-as-errors`. The annotation is pre-existing (observed in prior cycles' xcresults of the same files; bytes unchanged → behaviour unchanged). Not a regression; not a new ticket.

## Goal re-evaluation against fresh direct evidence

| # | Goal | Verdict | Direct evidence |
|---|------|---------|-----------------|
| 1 | **Working app** — `./app/build.sh test` exits 0, iPhone simulator, zero crashes | ✅ **direct (fresh)** | This cycle's xcresult `status=succeeded`, `passedTests=56`, 0 crashes, exit 0 on iPhone 17 Pro `53856B02-…` iOS 26.4 build 23E244 |
| 2 | **UI/UX approved** — Ive signs off on SwiftUI screens against `prototype/index.html` | ✅ **direct (fresh)** | `ContentView.swift` MD5 `665ad940…` = Ive's sign-off bytes (unchanged); 8/8 UI tests pass in fresh xcresult |
| 3 | **User scenarios captured** — Mendel confirms all 6 Jacquard scenarios covered | ✅ **direct (fresh)** | All 6 unit scenarios + UI-level `testAllJacquardScenariosAreVisibleInUI()` all Passed in fresh xcresult |
| 4 | **Expert approved** — Jacquard signs off on JS→Swift math port against `.squad/decisions/decisions.md` | ✅ **direct (fresh)** | `GaugeMath.swift` MD5 `ab435dce…` = Jacquard's sign-off bytes (`2f80c7f` review); `floatPrecision*` + `castOnRoundingDriftZeroForExactRatio` + `stitchWidthScaleAndCountMultiplierAreReciprocals` all Passed in fresh xcresult |
| 5 | **Code tested and validated** — Curie runs `./app/build.sh test`; all tests pass, zero warnings | ✅ **direct (fresh)** | Fresh xcresult: `errorCount=0`, `warningCount=0`, `analyzerWarningCount=0`, 56/56 |

**All 5 goals ✅ on fresh direct evidence.** Carry-forward streak 2 → 0 (reset by refresh).

## Per-member sign-offs (against fresh evidence)

- **Tesla** (Lead) — No blockers; no drift; direct-evidence refresh fired per predecessor `ded9c18`'s explicit ≥17:44:00Z guidance, hitting the recommended refresh window with all pre-flight gates green. Streak reset to 0; next ~3 cycles can comfortably carry forward inside the new validity window through 18:03:26Z.
- **Hopper** (`app/build.sh`) — `build.sh` bytes unchanged (`46cd9c87…`); test mode + `-warnings-as-errors` re-verified by 0 warnings in fresh xcresult; ~152.9s build wall within expected 140–180s envelope.
- **Ada** (`GaugeMath.swift`) — Math port bytes unchanged (`ab435dce…`); all 24 `GaugeMathTests` re-confirmed green in fresh xcresult.
- **Edison** (`ContentView.swift`) — View bytes unchanged (`665ad940…`); 8/8 UI tests re-confirmed green in fresh xcresult, no flake.
- **Curie** (tests) — 56/56 pass, 0 warnings, 0 errors, 0 analyzer warnings; fresh xcresult sealed at 17:48:26Z (valid through 18:03:26Z).
- **Ive** (UX) — Sign-off bytes intact; no UX regression — UI tests cover dynamic type, compact width, pull-up sheets, prototype-parity controls, share affordance, stepper, scenarios.
- **Mendel** (scenario mapping) — All 6 Jacquard scenarios mapped & re-confirmed passing both at unit level and at UI-level (`testAllJacquardScenariosAreVisibleInUI`).
- **Jacquard** (gauge math domain) — Formula correctness re-confirmed by `2f80c7f`-byte equivalence + green float-precision/cast-on/scale-reciprocal/determinism tests.

## GitLab status

- **Open MRs:** 0 (`glab mr list` → "No open merge requests available on yashasg/knitting-gauge-reconciler.")
- **Open issues:** #1 (feature spec, parked non-code), #9 (swift metrics capture, parked non-code) — both pre-existing, no code-scope action required.
- **Closed issues (recent):** #2–#8, #10–#19 all closed (per predecessor logs).
- **Pipeline status:** `source=external` / zero jobs configured — no SaaS macOS runner enabled (closed-infra issues #5/#10/#11). Out of scope per established loop scoping that ties G1/G5 to local `./app/build.sh test`. No pipeline gate to wait on for this cycle.

## Drift assessment

**None.**

- All 5 tracked code+test files byte-identical to baseline (verified by `md5` this cycle, re-confirmed by `xcresult` outcomes).
- Inbox empty, no open MRs, no new decisions, no new code-scope GitLab issues.
- Fresh xcresult outcomes (suite shape, test counts, pass/fail/skip splits, scenario names, Jacquard invariant tests) bit-identical to predecessor inheritance counts — confirming refresh.
- External/zero-jobs GitLab pipeline failures remain out of Squad scope per closed `#5`/`#10`/`#11`.

## Next-cycle guidance

- **Streak state:** carry-forward streak = 0 (after this refresh).
- **Evidence-of-record window:** xcresult mtime 17:48:26Z → expires 18:03:26Z; **15min full validity** available for the next ~3 cycles.
- **Recommended action by intake time:**
  - **Intake < 18:03:26Z (inside window) AND files bit-identical AND inbox+MRs+issues unchanged** → log-only carry-forward (1st post-refresh — comfortable carry-forward zone). Re-verify via `xcresulttool` and re-log.
  - **Intake ≥ 17:58:00Z but < 18:03:26Z (last ~5min of window)** → still log-only OK, but signal that the cycle after will need to plan for a refresh.
  - **Intake ≥ 18:03:26Z (after window)** → fire confirmatory refresh provided pre-flight passes:
    - `uptime` 1m+5m+15m < ~10
    - `pgrep -lf xcodebuild` = 0
    - At least one `iPhone 17 Pro` (preferably `53856B02-…` for convention) `Booted` — currently `53856B02-…` is booted as of this cycle; it may stay booted into the next cycle if the runtime doesn't shut it down
    - All 5 file MD5s match this cycle's baseline
- **Force-refresh trigger (any of):** ANY 5-file MD5 changes, new inbox decision, new code-scope GitLab issue, new MR opened.

## Cycle artefacts

- Branch (this cycle): `squad/refresh-2026-05-21T17-44-56Z-direct-evidence-refresh`
- Log file (this doc, gitignored — force-added per convention): `.squad/log/2026-05-21T17-44-56Z-ios-work-loop-cycle.md`
- Sealed xcresult (gitignored): `app/.build/derived-data/Logs/Test/KnittingGaugeReconciler.xcresult` (mtime 2026-05-21T17:48:26Z, valid through 18:03:26Z)
- No code/test file changes this cycle (5 MD5s bit-identical to baseline).

## Loop status

All five Squad goals ✅ (direct evidence, fresh this cycle on convention sim `53856B02-…`). Loop terminates green; re-handed off to **yashasg**.
