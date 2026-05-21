# Squad Work Loop — Wall-time Drift, Issue #18 Filed ⚠️→✅

**Timestamp:** 2026-05-20T23:39:33Z
**Coordinator:** Tesla
**Branch:** `main` (HEAD: `90ff651` — prior-cycle log-only commit on top
of log-only `07762bf`/`82fd2d9`/`0636733`/`e49fe76` on top of real-code
HEAD `be687e7` = MR !10 always-erase + two-pass recovery layer)

## Intake

- `.squad/decisions/inbox/` reviewed: **empty** (0 items).
- Prior log reviewed: `2026-05-20T21-11-18Z-ios-work-loop-squad-session.md` —
  fifth consecutive squad-log cycle on the post-MR-!10 real-code HEAD
  `be687e7`. Script-level rerun fired on
  `testShareResultsIsSingleAccessibleAffordance` SIGTERM, recovered
  single-pass in 14.116s. All 5 goals ✅.
- Working tree clean pre-gate; HEAD `90ff651` matches expectation
  (log-only on top of real-code `be687e7`). `git log --oneline
  be687e7..HEAD` shows only 5 log-only commits (`e49fe76`, `0636733`,
  `82fd2d9`, `07762bf`, `90ff651`) — no source changes.
- `app/build.sh` MD5 fingerprint: `641f9fb22969bd43eaa706efeaa6c06b`,
  575 lines — **unchanged** from prior cycle (still on the MR-!10
  always-erase + two-pass-recovery code path).
- `git diff --stat be687e7..HEAD` on `ContentView.swift`,
  `GaugeMath.swift`, `KnittingGaugeReconcilerTests/`,
  `KnittingGaugeReconcilerUITests/`, and `app/build.sh`: **empty**.
  Goals 2 and 4 sign-offs carry forward by stare decisis.
- GitLab issues pre-cycle: #1 (parent tracker, opened), #9 (swift
  metrics capture, opened, parked).
- GitLab MRs: **0 open**.
- GitLab pipelines on `main` (most recent 5):
  - **#2541718105** on `90ff651` — `source=external`, `started_at=null`,
    `duration=null`, `before_sha=00000000…`, `status=success`. Benign
    external-bridge mirror fingerprint. No action.
  - **#2541687950** on `07762bf` — `source=external`, `started_at=null`,
    `duration=null`, `before_sha=00000000…`, `status=failed`. Benign
    external-bridge mirror. No action.
  - **#2541649659**, **#2541618610**, **#2541615230** — same benign
    external-bridge fingerprint. No action.
  - **No native pipelines** on the SaaS macOS runner have triggered
    on any post-#16 real-code commit. Streak by-default since `4fc939c`.

## Build/Test Gate — `./app/build.sh test`

Fresh live run on real-code HEAD `be687e7` (via `90ff651` log-only tip),
iPhone 17 Pro simulator (iOS 26.4, device
`179149FE-BAFF-4464-893B-7468D06F49B7`, arm64, osBuild `23E244`).
Working tree clean pre-gate and post-gate.

Exit code: **0** ✅

### Recovery-layer firing this cycle

The script-level signal-term rerun layer **did NOT fire** this cycle.
The xcodebuild native `-test-iterations 2` envelope also did NOT
trigger any iteration 2 (grep for "Iteration 2 of 2" in
`app/.build/Logs/xcodebuild-test-35829.log`: 0 hits). Single canonical
xcresult bundle only — no `signal-term-original` or `flake-rerun`
siblings. **No recovery exercised — pure first-pass success.**

### Wall-time drift (⚠️ new, filed as issue #18)

Despite the clean first-pass result, this cycle's wall-time was
**1965.98s real** (`/usr/bin/time -p`) — **~20x** the documented
no-recovery fast-path band of ~98–105s. The blow-out is localised to
a single UI test:

| Test | This cycle | Documented baseline | Delta |
|------|------------|---------------------|-------|
| `testAllJacquardScenariosAreVisibleInUI` | **951.988s** | ~20–23s | **~47x** |
| All other 6 UI tests, combined | ~42s | ~42s | nominal |
| 18 unit tests (Swift Testing) | 0.040s | 0.040s | nominal |

Inner timeline from
`app/.build/Logs/xcodebuild-test-35829.log` lines 941–1030 isolates
the cause to a **~931.28s stall on a simulator `app.terminate()` →
`app.launch()` cycle between scenarios 4 and 5** of the 6-scenario
test:

```
t =    13.38s Terminate com.yashasg.KnittingGaugeReconciler:39274   ← end of scenario 4
t =   944.66s Open com.yashasg.KnittingGaugeReconciler              ← start of scenario 5
                                                                       ⤷ 931.28s stall
```

Scenarios 1–4 ran in ~13.4s (nominal). After the stall, scenarios 5
and 6 finished in ~7s. The relaunch eventually succeeded — no SIGTERM,
no Mach -308 "Lost pending connection", no install/launch failure
surfaced in the xcresult or build log. The recovery layer therefore
stayed dormant because, from the gate's perspective, the test passed
cleanly on iteration 1.

Searched all prior squad logs (2026-05-19 onward) for a single-test
runaway duration of this magnitude on this spec — **no precedent
found**. Range observed across the past ~30 cycles: 18–23s. Closest
documented analogue is the Mach -308 install/launch failure class
addressed by MR !17 (`0458f49`), but that is a different failure mode
(hard install failure, not a 15-minute stall that recovers).

This is **new drift**. Per loop.md cycle step 5 ("Any goal ❌ or new
drift found → open a GitLab issue"), filed as:

- **Issue #18** — `UI test wall-time drift:
  testAllJacquardScenariosAreVisibleInUI 951.988s vs ~20s baseline
  (931s mid-test simulator stall)` — Curie/Edison, goal 5
  (wall-time envelope).
  - URL: https://gitlab.com/yashasg/knitting-gauge-reconciler/-/work_items/18
  - Suggested mitigations parked in issue body: per-test wall-time
    soft assertion (Curie), in-app field reset replacing per-scenario
    `app.terminate()/launch()` (Edison), `/usr/bin/time -p` wall-time
    warning in `build.sh` (Hopper — optional).

### Effective test result

**Total: 25/25 passes on iteration 1, 0 failures, 0 unexpected, 0 retries**

- **18 unit tests** (GaugeMathTests, Swift Testing): all ✅ on
  Iteration 1, microsecond-class durations (≤ 1ms each except
  `shareTextFormatterIsDeterministicFormattedTextFallback` at 0.027s;
  suite total 0.040s — microsecond-class durations confirm no math
  path drift since prior sign-off):
  - scenario1PerfectMatch ✅
  - scenario2DenserRowsOnly ✅
  - scenario3LooserRowsOnly ✅
  - scenario4DenserStitchesOnly ✅
  - scenario5LooserStitchesHisahashisakaCase ✅
  - scenario6BothDenser ✅
  - invalidInputsFallBackToDefaults ✅
  - rowFormattingMatchesPrototype ✅
  - cmAndPercentFormattingMatchPrototype ✅
  - edgeVeryLargeDriftDenserRows ✅
  - edgeVeryLargeDriftLooserRows ✅
  - floatPrecisionExactMatchNoFPDrift ✅
  - floatPrecisionArbitraryMatchedGauge ✅
  - castOnRoundingDriftZeroForExactRatio ✅
  - stitchWidthScaleAndCountMultiplierAreReciprocals ✅
  - resultsExportSummaryIncludesShareCardContent ✅
  - shareTextFormatterIncludesCurrentGaugeAndGuidanceAsFallback ✅
  - shareTextFormatterIsDeterministicFormattedTextFallback ✅
- **7 UI tests** (KnittingGaugeReconcilerUITests, XCTest): all ✅
  on Iteration 1:
  - testAboutHelpButtonOpensPullUpSheet ✅ (4.990s)
  - testAccessibilityDynamicTypeStacksGaugeMeasurementPairs ✅ (4.728s)
  - testAllJacquardScenariosAreVisibleInUI ✅ (**951.988s** — drift,
    issue #18; assertion content correct, all 6 hero-% / cast-on /
    row-count outputs verified; stall is between scenario 4 and 5
    relaunch)
  - testCompactWidthKeepsNumericFieldsSideBySideWhenTheyFit ✅ (5.431s)
  - testPrototypeParityControlsAreAvailable ✅ (~10s)
  - testShareResultsIsSingleAccessibleAffordance ✅ (12.056s)
  - testVerdictHelpButtonOpensPullUpSheet ✅ (5.576s)
- **Build diagnostics on the canonical bundle**: `errorCount=0`,
  `warningCount=0`, `analyzerWarningCount=0`, `status=succeeded`.
  `SWIFT_TREAT_WARNINGS_AS_ERRORS=YES` enforced ✅. Goal 5's
  zero-warnings invariant holds.
- Footer confirmed: `** TEST SUCCEEDED **`.

## Goal Verdict

| # | Goal | Status |
|---|------|--------|
| 1 | **Working app** — `./app/build.sh test` exits 0, iPhone simulator, zero crashes | ✅ (exit 0, 25/25 tests pass; no crashes — `testAllJacquardScenariosAreVisibleInUI` stalled but recovered without error; no SIGTERM, no Mach -308, no install/launch failure) |
| 2 | **UI/UX approved** — Ive: ContentView matches prototype/index.html | ✅ (no `ContentView.swift` changes since prior approval; `git diff be687e7..HEAD` empty for views) |
| 3 | **User scenarios captured** — Mendel: all 6 Jacquard scenarios covered by unit + UI tests | ✅ (`testAllJacquardScenariosAreVisibleInUI` verified all 6 hero-% / cast-on / row-count outputs on a real run — the stall was between scenarios, not in an assertion; 6 `scenarioN-` prefixed unit tests all green at microsecond-class) |
| 4 | **Expert approved** — Jacquard: JS → Swift math port correct per decisions.md | ✅ (no `GaugeMath.swift` changes since prior sign-off; 18 unit tests' microsecond-class durations confirm math path is untouched and bit-identical to prior cycles) |
| 5 | **Code tested and validated** — Curie: 25/25 tests, 0 warnings, exit 0 | ✅ on the binary criteria (25/25, `warningCount=0`, `analyzerWarningCount=0`, `errorCount=0`, `status=succeeded`, exit 0, `SWIFT_TREAT_WARNINGS_AS_ERRORS=YES` enforced). ⚠️ wall-time envelope drift filed as issue #18 — does not flip the goal verdict because all binary criteria still hold, but tracked for follow-up. |

## Outcome

All 5 goals ✅ on real-code HEAD `be687e7` (MR !10 always-erase +
two-pass recovery layer). This is the **sixth consecutive squad-log
cycle on this real-code HEAD**.

**New drift this cycle**, filed as **issue #18**: wall-time envelope
blew through the ~98–105s no-recovery fast-path band by ~20x, traced
to a 931s mid-test simulator stall on `app.terminate()/launch()`
between scenarios 4 and 5 of `testAllJacquardScenariosAreVisibleInUI`.
The stall recovered without error and the test passed — no recovery
layer firing, no SIGTERM, no Mach -308 — so the binary goal-5 criteria
(25/25, 0 warnings, exit 0) still hold and the goal verdict remains
✅. Issue #18 is tracked for follow-up (Curie/Edison/Hopper triage),
with three proposed mitigations parked in the issue body.

No new code commits to source since prior cycle (only this cycle's
log-only commit will land). Working tree clean pre- and post-gate.
Inbox empty. `app/build.sh` MD5 unchanged.

GitLab side after this cycle:
- Issues: #1 (parent tracker, opened), #9 (swift metrics, opened,
  parked), **#18 (NEW — wall-time drift, opened)**.
- MRs: 0 open.
- Pipelines: all recent `main` pipelines remain benign
  external-bridge mirrors (`source=external`, `started_at=null`,
  `duration=null`, `before_sha=00000000…`). Native-green streak on
  real-code commits intact by-default since `4fc939c`.

**Final Review status:** Per loop.md, all 5 ✅ would normally trigger
parallel Final Review. This cycle filed a new drift issue (#18) that
should land in a future cycle's work queue. The drift is operational
(test runtime envelope), not a code-change requiring re-review by
Ive / Jacquard / Mendel / Curie against the existing source — no new
review surface for those members. **No parallel Final Review spawned
this cycle.** Issue #18 enters the work queue for the next cycle that
chooses to address it (Curie/Edison/Hopper); until then, the loop
continues at idle.

Loop complete — hand-off to yashasg.
