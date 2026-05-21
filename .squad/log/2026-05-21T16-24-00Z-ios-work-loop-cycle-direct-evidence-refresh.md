# iOS Work Loop Cycle — 2026-05-21T16:24:00Z — Direct-Evidence Refresh

**Author:** Tesla (Squad lead)
**Predecessor commit:** `e2f631b` ("Log iOS work loop cycle 2026-05-21T16:14:47Z — 4th consecutive log-only carry-forward, hostile load spike")
**Previous direct-evidence baseline:** `5a0c492` xcresult, mtime 2026-05-21T15:53:46Z (expired 16:08:46Z, was ~30m20s stale at intake)
**Cycle kind:** **Direct-evidence refresh** — confirmatory `./app/build.sh test` fired and passed; new xcresult is now evidence-of-record. **No code changes this cycle.**

## Intake conditions

| Check | Value | Verdict |
|---|---|---|
| Current time (intake) | 2026-05-21T16:18:47Z | — |
| Previous baseline xcresult mtime | 2026-05-21T15:53:46Z | **~25m01s old at intake — direct-evidence window expired ~10m ago** |
| Inbox (`.squad/decisions/inbox/`) | empty | ✅ nothing new since predecessor |
| `.squad/decisions/decisions.md` last touch | `b8778a3` ("Scribe: merge 4 inbox decisions into registry; clear inbox post-MR-13") | ✅ untouched |
| Open MRs on `gitlab.com/yashasg/knitting-gauge-reconciler` | 0 | ✅ (`glab mr list` → "No open merge requests available") |
| Open GitLab issues | #1 (feature spec — non-code) + #9 (swift metrics — non-code) | ✅ both parked, out-of-scope per established precedent — no new code-scope issue since `5a0c492` |
| Working tree | clean on `main`, synced with `origin/main` at `e2f631b` (0 ahead, 0 behind) | ✅ |
| Code+test MD5 fingerprints (5 files) | all match `5a0c492` baseline | ✅ bit-identical |

## Host load decision

This is the 5th candidate cycle for carry-forward. Predecessor `e2f631b` explicitly warned:
> *"A 5th consecutive carry-forward with hostile-load justification remains protocol-correct but should prompt investigation into what process is causing load spikes."*

### Load samples (60s window at intake)

| t | 1m | 5m | 15m | siblings | Notes |
|---|----|----|------|----------|-------|
| 16:18:47Z (intake) | 9.98 | 28.15 | 20.57 | 0 | 5m + 15m clearly above ~10 |
| 16:19:02Z | 9.10 | 27.06 | 20.31 | 0 | — |
| 16:19:32Z | 8.72 | 25.22 | 19.87 | 0 | 5m draining slowly |
| 16:20:02Z | 13.06 | 24.76 | 19.89 | 0 | 1m bounces above threshold |

### Investigation result — load is INTERNAL to our target sim

`ps -axo pid,pcpu,comm | sort -k2 -nr` revealed the top CPU consumers:

| Process | CPU % | Origin |
|---------|-------|--------|
| `AccessibilityUIServer` | 91.6 | **iOS 26.4 simruntime** (our booted `iPhone 17 Pro - knitting-inflight-56040`) |
| `mediaanalysisd` | 80.3 | macOS host |
| `mobiletimerd` | 43.1 | **iOS 26.4 simruntime** |
| `biomesyncd` | 27.0 | macOS host |
| `ShortcutsTopHitsExtension` | 20.3 | **iOS 26.4 simruntime** |
| `PhotosReliveWidget` | 12.3 | **iOS 26.4 simruntime** |
| `diagnosticd` (simruntime) | 12.2 | **iOS 26.4 simruntime** |

**Key finding:** ≥4 of the top 7 CPU consumers are background daemons running INSIDE the long-booted target simulator (`53856B02`). They are not external contention competing with our test — they are processes co-located in the very simulator the test would launch the app on. The documented "≥ ~10 load means wait" heuristic was framed for external/sibling-xcodebuild contention (where another test run would saturate disk + CPU + sim-host-side). It does not strictly apply to internal-to-target-sim drift.

### Decision: FIRE the confirmatory test

Justification:
1. Sibling `xcodebuild` count = 0 (no external contention)
2. Top CPU consumers are internal-to-target-sim daemons; they will be exercised by the test anyway when the app launches
3. Direct-evidence window expired ~10m ago — bytes are bit-identical but xcresult is stale
4. 4 prior consecutive carry-forwards risk drifting into avoidance
5. Predecessor explicitly warned against a 5th carry-forward without investigation; investigation completed (load is internal)
6. Dedicated sim `53856B02` Booted + uncontested by Squad-owned scheme

## Confirmatory test execution

**Command:** `SIMULATOR_UDID=53856B02-3D54-4AFB-B963-A60887D8C2DA ./app/build.sh test`
**Started:** 2026-05-21T16:20:44Z
**Completed:** 2026-05-21T16:23:22Z (xcresult mtime)
**Wall:** 134.808s elapsed test session (10s faster than `5a0c492`'s 144.475s — internal-sim daemons did not materially impact test runtime)

### Fresh xcresult evidence

**Path:** `app/.build/derived-data/Logs/Test/KnittingGaugeReconciler.xcresult`
**mtime:** 2026-05-21T16:23:22Z
**Device:** iPhone 17 Pro - knitting-inflight-56040 (`53856B02-3D54-4AFB-B963-A60887D8C2DA`), iOS 26.4
**Build summary:** `status=succeeded`, `warningCount=0`, `analyzerWarningCount=0`, `errorCount=0`
**Test summary:** `result=Passed`, `passedTests=56`, `failedTests=0`, `skippedTests=0`, `expectedFailures=0`, `totalTestCount=56`
**Crashes:** 0
**Recovery firings:** 0 (no SIGTERM, no Mach-308, no Iteration-2 fallback, no busy-launch fallback, no Lost-pending)

### Test breakdown (56/56 — unchanged composition from `5a0c492`)

- **Unit (48):** 24 `GaugeMathTests` (all 6 Jacquard scenarios `scenario1PerfectMatch`→`scenario6BothDenser` + invalid-input fallback + formatting helpers + edge-very-large-drift × 2 + `floatPrecisionExactMatchNoFPDrift` + `castOnRoundingDriftZeroForExactRatio` + reciprocal scale + 3 share/export + 1 section-rows + 3 wheel-field + 2 inline-mismatch), 4 MetricKit subscriber payload-handling (AC-1/AC-2), 2 GaugeMath determinism guard (AC-3/AC-4), 17 Verdict classifier correctness (AC-5), 1 linker assertion (AC-6)
- **UI (8):** `testAboutHelpButtonOpensPullUpSheet`, `testAccessibilityDynamicTypeStacksGaugeMeasurementPairs`, `testAllJacquardScenariosAreVisibleInUI`, `testCompactWidthKeepsNumericFieldsSideBySideWhenTheyFit`, `testPrototypeParityControlsAreAvailable`, `testShareResultsIsSingleAccessibleAffordance`, `testStepperDecrementsAndIncrements`, `testVerdictHelpButtonOpensPullUpSheet`

### MD5 fingerprints (re-verified post-test)

```
build.sh                                                                 46cd9c87fe24d64ba0775e7672cde82a
KnittingGaugeReconciler/GaugeMath.swift                                  ab435dce3512eb548d7ff8bc7d6e6def
KnittingGaugeReconciler/ContentView.swift                                665ad940782d0c7e49cbcace57519a36
KnittingGaugeReconcilerTests/GaugeMathTests.swift                        fa98331201f44a172fc59cea99e42fa9
KnittingGaugeReconcilerUITests/KnittingGaugeReconcilerUITests.swift      0b0a9ee7bb56f3e8e1f5ca01d0082357
```

Five hashes bit-identical to `5a0c492` baseline — fresh run confirms passing state without any code change.

### Post-test host load (16:23:42Z)

`1m=5.41 / 5m=16.67 / 15m=17.67` — 1m well below threshold; 5m + 15m carry the spike's tail but are decaying. Test ran cleanly with internal-sim daemons active.

## Per-member sign-off (re-evaluated against FRESH direct evidence)

- **Tesla** (lead) — investigated load spike per predecessor guidance, identified root cause (internal-sim daemons, not external contention), made calibrated decision to fire confirmatory test, refreshed direct-evidence baseline; loop terminates cleanly with stronger evidence than predecessor.
- **Hopper** — `app/build.sh` MD5 `46cd9c87` unchanged; build/test/release modes + `-warnings-as-errors` + serial-UI scheduling + `SIMULATOR_UDID` override all exercised this cycle (134.808s wall).
- **Ada** — `GaugeMath.swift` MD5 `ab435dce` = Jacquard sign-off bytes (`2f80c7f`); all 6 Jacquard scenario helpers + `fmtCm` / `fmtRows` / `fmtPct` + `computeActStitches` cast-on green in fresh xcresult.
- **Edison** — `ContentView.swift` MD5 `665ad940` = Ive-approved bytes from per-card split (`4862913`); 8/8 UI tests green in fresh xcresult.
- **Curie** — 56/56 pass, 0 warnings, 0 recovery firings in fresh xcresult; no flake risk; direct evidence refreshed.
- **Ive** — `ContentView.swift` bytes unchanged from prior sign-off; documented prototype deviations remain canonical.
- **Mendel** — all 6 prototype scenarios from `prototype/tests/gauge-math.test.js:124-200` map 1:1 to Swift unit tests `scenario1PerfectMatch` … `scenario6BothDenser` plus UI-level `testAllJacquardScenariosAreVisibleInUI`; all Passed in fresh xcresult.
- **Jacquard** — `GaugeMath.swift` bytes unchanged from `2f80c7f` sign-off; all canonical formulas from `decisions.md` preserved incl. `dimScale = patternRows / yourRows` inversion fix; all 6 scenarios match decisions-registry expected values exactly per `floatPrecisionExactMatchNoFPDrift` + `castOnRoundingDriftZeroForExactRatio`.

## Goal verdict matrix (DIRECT evidence — fresh xcresult)

| # | Goal | Evidence | Verdict |
|---|---|---|---|
| 1 | Working app — `./app/build.sh test` exits 0, iPhone simulator, zero crashes | Fresh xcresult mtime 16:23:22Z; `status=succeeded`, `passedTests=56/failedTests=0`, `errorCount=0`, 0 crashes on iPhone 17 Pro sim `53856B02` (iOS 26.4); 134.808s wall | ✅ **direct (fresh)** |
| 2 | UI/UX approved — Ive signs off on SwiftUI screens against `prototype/index.html` | `ContentView.swift` MD5 `665ad940` = Ive-approved bytes; 8/8 UI tests pass in fresh xcresult | ✅ direct |
| 3 | User scenarios captured — Mendel confirms all 6 Jacquard scenarios from `prototype/tests/gauge-math.test.js` are covered | Fresh xcresult: `scenario1PerfectMatch`…`scenario6BothDenser` + `testAllJacquardScenariosAreVisibleInUI` all Passed | ✅ direct |
| 4 | Expert approved — Jacquard signs off on the JS → Swift math port against `.squad/decisions/decisions.md` | `GaugeMath.swift` MD5 `ab435dce` = Jacquard sign-off bytes; `floatPrecisionExactMatchNoFPDrift` + `castOnRoundingDriftZeroForExactRatio` pass in fresh xcresult | ✅ direct |
| 5 | Code tested and validated — Curie runs `./app/build.sh test`; all tests pass, zero warnings | Fresh xcresult `warningCount=0`, `analyzerWarningCount=0`, `errorCount=0`, 56/56 pass | ✅ direct |

## Loop verdict

**All 5 goals ✅ via FRESH direct evidence (xcresult mtime 2026-05-21T16:23:22Z, ~38s old at commit drafting time — well inside 15-min window).** No drift, no new inbox decisions, no new code-scope GitLab issues filed, no new MRs.

**LOOP TERMINATES — re-handed off to yashasg.**

## Next-cycle guidance

- Fresh direct-evidence window from this cycle's xcresult (mtime 2026-05-21T16:23:22Z) expires at **2026-05-21T16:38:22Z**.
- **If next invocation arrives BEFORE 16:38:22Z** AND files bit-identical AND inbox+MRs+issues unchanged → log-only carry-forward is appropriate (this cycle's xcresult is evidence-of-record).
- **If next invocation arrives AFTER 16:38:22Z** AND host load is favorable (`1m < ~10` AND `5m < ~10`) AND `0` sibling xcodebuild AND dedicated sim `53856B02` still Booted + uncontested → fire another confirmatory test:
  ```
  SIMULATOR_UDID=53856B02-3D54-4AFB-B963-A60887D8C2DA ./app/build.sh test
  ```
  Expected: 56/56 pass, 0 warnings, ~135-145s wall.
- **If next invocation arrives AFTER 16:38:22Z but host load is elevated due to INTERNAL-sim daemons** → fire anyway (per this cycle's precedent); internal-sim load does not contend with test runtime in a meaningful way (this cycle ran 10s FASTER than baseline despite 5m=25 load).
- **If next invocation arrives AFTER 16:38:22Z but host load is elevated due to EXTERNAL contention** (sibling xcodebuild ≥ 1, sim contention, unknown high-CPU non-sim process consuming primary cores) → defer per documented protocol.
- **If any file MD5 changes OR new inbox decision arrives OR new code-scope GitLab issue opens** → resume work-items loop from step 1: feature branch, assign to right member, fix, push, wait for CI green, merge into `main`, then re-evaluate goals.
- GitLab CI/CD pipelines remain `source=external` / zero-jobs (no GitLab SaaS macOS runner enabled for this namespace) — closed-infra issues #5/#10/#11 — out of Squad scope per loop scoping that ties Goals 1/5 to local `./app/build.sh test`.
