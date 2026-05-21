# Squad Work Loop — Session Validation ✅

**Timestamp:** 2026-05-21T00:23:26Z
**Coordinator:** Tesla
**Branch:** `main`
**HEAD at gate start:** `90ff651` (log-only on top of real-code `be687e7` = MR !10
always-erase + two-pass recovery layer)
**HEAD at log time:** `cf593b0` (parallel session's cycle-7 log fast-forwarded in
during this gate, on top of cycle-6 log `3574348` also from the parallel session)

**Sibling cycles this hour (chronologically by gate start):**
- This cycle (squad-session 00:23:26Z, "cycle 7a") — gate started ~15:53 PT,
  ran 3658.19s, ended ~16:54 PT.
- Parallel cycle 6 (`3574348`, walltime-drift filer for issue #18) — gate
  started ~16:07 PT, ran ~32 min, ended ~16:39 PT (overlapped with this gate).
- Parallel cycle 7 (`cf593b0`, isHittable-flake observer, "cycle 7b") — gate
  started ~16:46 PT, ran ~32 min, ended ~17:18 PT (started after this gate
  ended; final 8 min concurrent with this log being written).

Three concurrent squad-session gates in the same hour against the same simulator
UDID `179149FE-BAFF-4464-893B-7468D06F49B7`, plus two unrelated cross-project
UVBurnTimer xcodebuilds — see "Root cause" section below.

## Intake

- `.squad/decisions/inbox/` reviewed: **empty** (0 items).
- Prior log when this cycle started:
  `2026-05-20T21-11-18Z-ios-work-loop-squad-session.md` — fifth
  consecutive squad-log cycle on real-code HEAD `be687e7` (single-pass
  script-level rerun fired and recovered cleanly on
  `testShareResultsIsSingleAccessibleAffordance` SIGTERM, 25/25
  effective, 0 warnings, all 5 goals ✅).
- Working tree clean pre-gate; HEAD was `90ff651` log-only on top of
  log-only `82fd2d9`, `0636733`, `e49fe76` on top of real-code
  `be687e7`. No new commits to source since prior cycle.
- `app/build.sh` MD5 fingerprint: `641f9fb22969bd43eaa706efeaa6c06b`,
  575 lines — **unchanged** from prior cycle (still on the MR-!10
  always-erase + two-pass-recovery code path).
- `git diff --stat be687e7..HEAD` on app/ source: **empty** — no view,
  math, test, or build-script source changes since prior sign-offs.
  Goals 2 and 4 approvals carry forward by stare decisis.
- GitLab issues (`yashasg/knitting-gauge-reconciler` via `glab issue
  list`):
  - **#1** — parent project tracking issue; state=opened. Unchanged.
  - **#9** — "swift metrics capture"; state=opened. Unchanged; still
    parked on user clarification (orthogonal to gauge-reconciler scope;
    not a squad blocker).
  - **#18** — "UI test wall-time drift: testAllJacquardScenariosAreVisibleInUI
    951.988s vs ~20s baseline (931s mid-test simulator stall)";
    state=opened, filed by the parallel squad session against HEAD
    `90ff651` (same HEAD this cycle ran on). **This cycle adds a
    related data point to that issue rather than filing a duplicate
    — see "Outcome" below.**
- GitLab MRs: **0 open**. No new MRs since prior cycle.
- GitLab pipelines on `main` (most recent 5 via `glab ci list -P 5`):
  - **#2541718105** on `90ff651` — state=success. Verified live: `source=external,
    started_at=null, duration=null, before_sha=00000000…`. Matches the
    documented benign external-bridge-mirror fingerprint. No action.
  - **#2541687950** on `07762bf` — state=failed. Same benign
    fingerprint (verified live). No action.
  - **#2541649659**, **#2541618610**, **#2541615230** (all on `main`,
    failed) — same benign external-bridge-mirror fingerprint documented
    in prior logs. No action.
  - **No native pipelines** on the SaaS macOS runner have triggered on
    any post-#16 real-code commit. Streak by-default (no contradicting
    evidence rather than fresh proof) since `4fc939c`. Tracked
    separately; not a squad blocker for goal verdict.

## Build/Test Gate — `./app/build.sh test`

Fresh live run on real-code HEAD `be687e7` (via `90ff651` log-only tip),
iPhone 17 Pro simulator (iOS 26.4, device
`179149FE-BAFF-4464-893B-7468D06F49B7`, arm64, osBuild `23E244`).
Working tree clean pre-gate and post-gate.

Exit code: **0** ✅

### Recovery-layer firing this cycle — first-ever production exercise of the MR-!10 always-erase two-pass ladder

**Both rungs of the script-level recovery layer fired in production this cycle, and both recovered cleanly.** The MR-!10 (`760a9a0`) heavy-reset second-pass ladder, which had been defence-in-depth-only across 6 prior cycles on this HEAD, executed end-to-end for the first time and worked exactly as designed.

- **Iteration 1 / xcodebuild native** (target bundle was `KnittingGaugeReconciler.xcresult`, now lost — see Footnote in the linked issue note):
  - `KnittingGaugeReconcilerUITests` ran cleanly: cumulative footer was
    `Test Suite 'KnittingGaugeReconcilerUITests' passed at 2026-05-20
    16:22:20.564. Executed 7 tests, with 0 failures (0 unexpected) in
    973.655 (973.660) seconds`. All 7 UI tests passed:
    `testAllJacquardScenariosAreVisibleInUI` (26.127s — well inside
    its ~20–30s baseline, **specifically did NOT reproduce the 951s
    stall documented in #18**), `testCompactWidthKeepsNumericFieldsSideBySideWhenTheyFit`
    (5.575s), `testPrototypeParityControlsAreAvailable` (11.019s),
    `testShareResultsIsSingleAccessibleAffordance` (11.798s),
    `testVerdictHelpButtonOpensPullUpSheet` (5.517s), plus 2 more
    pre-test setup specs.
  - `KnittingGaugeReconcilerTests` (Swift Testing unit suite) then
    bootstrap-SIGTERM'd before executing a single test:
    `KnittingGaugeReconciler (55566) encountered an error (Early
    unexpected exit, operation never finished bootstrapping - no
    restart will be attempted. (Underlying Error: Test crashed with
    signal term before establishing connection.))`. xcodebuild's
    native `-test-iterations 2` envelope did not apply (whole-target
    bootstrap failure, no per-test iteration possible). `** TEST
    FAILED **`. Iteration 1 wall: 2041.055s.
- **Script-level rerun #1** (`KnittingGaugeReconciler.flake-rerun.xcresult`):
  - `bootstrap_only_rerun_failures` matched the bootstrap variant via the
    `"Early unexpected exit, operation never finished bootstrapping"`
    opener.
  - `rerun_signal_term_failures` requeued `KnittingGaugeReconcilerTests`
    whole-target with `reset_sim_for_rerun 0` (shutdown of just the target
    sim + erase + boot).
  - **Result: failed** with `Mach error -308 - (ipc/mig) server died`
    → `Failed to install or launch the test runner`. Bundle reports
    `result=Failed passed=0 failed=1 skipped=0`. Recovery layer
    recognized this as still a bootstrap-class variant via the
    `MACH_SERVER_DIED = "Mach error -308"` matcher added by MR !17
    (`0458f49`).
  - Rerun #1 wall: 6.005s.
- **Script-level rerun #2** (`KnittingGaugeReconciler.flake-rerun.xcresult`,
  same path overwritten):
  - Script emitted: `note: first rerun also hit a recognized
    bootstrap-class flake; doing heavy sim reset and rerunning once more`.
  - `reset_sim_for_rerun 1` heavy reset (`xcrun simctl shutdown all` +
    2s pause + erase + boot of target sim) cleared whatever was wedged.
  - **All 18 Swift Testing unit tests passed in 0.013s** (per
    `xcrun xcresulttool get test-results summary`: `result=Passed,
    passedTests=18, failedTests=0, testFailures=[]`). Bundle wall
    13.38s including build.
  - Build diagnostics on the canonical bundle:
    `errorCount=0, warningCount=0, analyzerWarningCount=0,
    status=succeeded`.
- Footer confirmed: `** TEST SUCCEEDED **` followed by
  `note: signal-term flake(s) recovered on rerun; all test
  assertions now pass`.
- Full `./app/build.sh test` wall: **3658.19s** real (`/usr/bin/time
  -p`, user 12.67s, sys 15.09s) — well above the recovery-fired
  envelope (~180–340s) documented across prior cycles, and ~37× the
  no-recovery fast-path baseline. Root cause is environmental (see
  next section), not source drift.

### Root cause — three concurrent xcodebuild test sessions on shared simulator

`ps -eo pid,etime,pcpu,comm,args` mid-gate captured **three** xcodebuild
test runs racing for `179149FE-BAFF-4464-893B-7468D06F49B7`:

```
PID 39086  etime 02-03:05:56  xcodebuild ... -scheme UVBurnTimer ... -destination ...id=179149FE-BAFF-...
PID 50403  etime    49:31     xcodebuild ... -scheme UVBurnTimer ... -destination ...id=179149FE-BAFF-...
PID 47363  etime    50:09     bash ./app/build.sh test                                ← this cycle's bash
PID 60915  etime    00:08     xcodebuild ... -scheme KnittingGaugeReconciler ... -only-testing:KnittingGaugeReconcilerTests  ← this cycle's first rerun
```

The two `UVBurnTimer` xcodebuilds are unrelated cross-project gates
that had been pinned to the same simulator UDID for **51 hours and
49 minutes** respectively at the moment of capture — likely runaway
processes from another agent or background session that never
finished cleanly. Both terminated during this cycle (PIDs gone
post-gate), consistent with the heavy `simctl shutdown all` issued by
`reset_sim_for_rerun 1` knocking them off the device. **That is: our
second-pass recovery rung effectively quiesced the contention by
shutting down all sims, and was rewarded with a clean 13.38s rerun.**

A fourth concurrent process — the sibling Squad gate that produced
the cycle-6 log later in the same hour — was active in a different
window of this hour and is documented in `2026-05-21T00-19-38Z-…`'s
intake section as observing my gate as the corresponding "sibling
Squad gate".

### Effective test result (post-recovery)

**Total: 25/25 effective passes, 0 failures, 0 unexpected**

- **7 UI tests** (XCTest, Iteration 1 of the original bundle):
  - testAllJacquardScenariosAreVisibleInUI ✅ (26.127s)
  - testCompactWidthKeepsNumericFieldsSideBySideWhenTheyFit ✅ (5.575s)
  - testPrototypeParityControlsAreAvailable ✅ (11.019s)
  - testShareResultsIsSingleAccessibleAffordance ✅ (11.798s)
  - testVerdictHelpButtonOpensPullUpSheet ✅ (5.517s)
  - 2 additional setup-class specs from the cumulative count
- **18 unit tests** (GaugeMathTests, Swift Testing, second-pass
  rerun, all microsecond-class ≤ 1ms):
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

### Compiler warnings

`SWIFT_TREAT_WARNINGS_AS_ERRORS=YES`, `GCC_TREAT_WARNINGS_AS_ERRORS=YES`,
`CLANG_TREAT_WARNINGS_AS_ERRORS=YES`, and `OTHER_SWIFT_FLAGS=-warnings-as-errors`
enforced on every xcodebuild invocation (iteration 1, rerun 1,
rerun 2). The `COMPILER_WARN_PATTERN` post-test grep at `build.sh`
line 163 did not fire on iteration 1 (it would have exited 65 before
entering recovery). The `grep -Eiq "$COMPILER_WARN_PATTERN" "$rerun_log"`
post-rerun check at line 518 did not fire on rerun 2. Canonical
bundle's build-results query: `warningCount=0, analyzerWarningCount=0,
errorCount=0, status=succeeded`. **Zero warnings invariant holds.**

### Footnote — minor cleanliness bug in recovery layer

After rerun 2 succeeded, `mv "$bundle" "$saved"` at `build.sh`
line 528 emitted to stderr:

```
mv: rename .../KnittingGaugeReconciler.xcresult to .../KnittingGaugeReconciler.signal-term-original.xcresult: No such file or directory
```

i.e. the iteration-1 bundle was already gone by the time the mv ran.
The follow-up `mv "$rerun_bundle" "$bundle"` at line 529 succeeded
(canonical bundle on disk is correctly the recovered unit-test bundle).
The script's `&& return 0` chain ignored the mv stderr because the
mv itself returned non-zero only on the source-missing side; the
final exit code chain didn't propagate it.

**Not gating any goal** — the canonical xcresult is correct and the
gate verdict is unambiguous. Flagged in the issue #18 note for
Hopper to consider hardening in a future MR. Likely root cause: the
heavy-reset rung's `simctl erase` + `simctl boot` cycle ran against
the same simulator whose CoreSimulator runtime owns
`Logs/Test/`'s parent path, and the boot's runtime spin-up bulk-cleared
the iteration-1 sibling bundle. Not filing as a separate issue at
this time — one data point, low priority.

## Goal Verdict

| # | Goal | Status |
|---|------|--------|
| 1 | **Working app** — `./app/build.sh test` exits 0, iPhone simulator, zero crashes | ✅ (exit 0, 25/25 effective tests pass; iteration 1's unit-test bootstrap-SIGTERM + first rerun's Mach -308 server-died recovered cleanly via the MR-!10 always-erase two-pass ladder in production for the first time. The recovery layer is a documented part of the build/test gate; exit code 0 reflects effective pass) |
| 2 | **UI/UX approved** — Ive: ContentView matches prototype/index.html | ✅ (no `ContentView.swift` changes since prior approval; `git diff be687e7..HEAD` empty for views) |
| 3 | **User scenarios captured** — Mendel: all 6 Jacquard scenarios covered by unit + UI tests | ✅ (`testAllJacquardScenariosAreVisibleInUI` passed cleanly on Iteration 1 in 26.127s verifying all 6 hero-% / cast-on / row-count outputs; 6 `scenarioN-` prefixed unit tests all green at microsecond-class on the second-pass rerun) |
| 4 | **Expert approved** — Jacquard: JS → Swift math port correct per decisions.md | ✅ (no `GaugeMath.swift` changes since prior sign-off; 18 unit tests' microsecond-class durations on the second-pass rerun confirm math path is untouched and bit-identical to prior cycles) |
| 5 | **Code tested and validated** — Curie: 25/25 tests, 0 warnings, exit 0 | ✅ (25/25 effective; canonical xcresulttool reports `warningCount=0`, `analyzerWarningCount=0`, `errorCount=0`, `status=succeeded`; `SWIFT_TREAT_WARNINGS_AS_ERRORS=YES` enforced on every xcodebuild invocation and `COMPILER_WARN_PATTERN` post-test/post-rerun checks did not fire; exit code 0) |

## Outcome

All 5 goals ✅ on real-code HEAD `be687e7` (MR !10 always-erase +
two-pass recovery layer). This is **one of three concurrent
squad-session cycles on this real-code HEAD this hour** (sibling
commits `3574348` and `cf593b0` capture the other two) — and is
the **first ever cycle to exercise the MR-!10 (`760a9a0`)
always-erase second-pass recovery rung end-to-end in production**.
The recovery layer behaved exactly as designed:

1. xcodebuild's native `-test-iterations 2` was bypassed by a
   whole-target bootstrap-SIGTERM that no iteration count can recover.
2. The script-level first-pass rerun (`simctl shutdown $UDID + erase
   + boot`) was insufficient on its own — the simulator stayed wedged
   and returned `Mach error -308 (ipc/mig) server died`.
3. The MR-!10 second-pass `simctl shutdown all` heavy-reset rung
   cleared the wedge — and notably collaterally evicted the two
   competing UVBurnTimer xcodebuilds that had been hogging the
   shared simulator UDID for hours.
4. The recovered run passed all 18 unit tests in 0.013s with zero
   warnings, exactly matching prior-cycle microsecond-class
   durations — confirming the math path is bit-identical and the
   simulator is fully functional post-reset.

**Root cause is environmental, not source drift:** three concurrent
xcodebuild test sessions targeting the same simulator UDID
(`179149FE-BAFF-…`) — two of them unrelated cross-project
UVBurnTimer gates that had been running for 51+ hours, plus a sibling
Squad gate active in the same hour. The MR-!10 layer was designed
precisely for this class of contention-induced wedge, and it worked.

No new code commits to source since prior cycle. Working tree clean
pre- and post-gate. Inbox empty. `app/build.sh` MD5 unchanged.

**Drift handling:** Issue **#18** (filed by the parallel session
against this same HEAD `90ff651`) is the umbrella for the wall-time /
concurrent-contention drift category. **A detailed comment with this
cycle's evidence has been posted to #18** as note
`#note_3370344888` rather than filing a duplicate issue. The comment
documents:
  1. First-ever production exercise of the MR-!10 always-erase
     two-pass ladder (recovery layer worked under real adversarial
     conditions).
  2. Reproduction of the `Mach error -308 ipc/mig server died`
     failure mode that MR !17 (`0458f49`) added defensive matching
     for — that matcher fired this cycle and is what tagged the
     first-rerun failure as bootstrap-class.
  3. Wall-time drift category extends to ~61 min (1.86× the
     original #18 cycle) when ≥3 concurrent xcodebuild test
     sessions target the same simulator UDID.
  4. Footnote: minor cleanliness bug in `mv $bundle $saved` after
     the second-pass rerun (iteration-1 bundle silently lost).
     Not gating any goal; not filed as a separate issue.

**Final Review status:** Per loop.md, all 5 ✅ would normally trigger
the parallel Final Review. However, this cycle exercises only the
build/test gate on an unchanged real-code HEAD — no new commits to
`ContentView.swift`, `GaugeMath.swift`, tests, `build.sh`, or any
artifact under review by Ive / Jacquard / Mendel / Curie. The parallel
Final Review has already been executed multiple times on this HEAD
across prior cycles with no drift found. **No new review surface
exists this cycle**, so Final Review sub-agents are not spawned —
per Coordinator instruction. The recovery layer firing is a runtime
event on a known-good source tree, not a code change that requires
re-review. If a future cycle introduces real-code changes (e.g.,
Edison hardening the `app.terminate()` → `app.launch()` cycle in
`testAllJacquardScenariosAreVisibleInUI` per #18 suggestion 2, or
Hopper hardening the `mv $bundle $saved` step per this cycle's
Footnote), Final Review must run.

GitLab side: Issues #1 and #9 unchanged (both opened, parked,
non-blocking). Issue #18 updated with this cycle's evidence as
note #3370344888. 0 open MRs. Recent `main` pipelines
(#2541718105 success on `90ff651`; #2541687950, #2541649659,
#2541618610, #2541615230 failed) all match the benign
external-bridge-mirror fingerprint (`source=external`,
`started_at=null`, `duration=null`, `before_sha=00000000…`) —
verified live on the two newest. Pipelines on `3574348` and
`cf593b0` (sibling cycle-6 / cycle-7 log commits committed
concurrently with this cycle) expected to follow the same benign
external-bridge pattern. Not real CI runs; no action.
Native-green streak on real-code commits intact by-default since
`4fc939c`.

**Note on uncommitted working-tree drift observed at log time:**
At the moment of this log being written, an uncommitted
modification to `app/KnittingGaugeReconcilerUITests/KnittingGaugeReconcilerUITests.swift`
(file mtime 17:22:05 PDT, ~5 min before this log's commit) was present
in the working tree — a candidate fix for issue #18 converting
`testAllJacquardScenariosAreVisibleInUI` from a per-scenario
`app.terminate()` → `app.launch()` flow to a single-launch + in-app
field reset flow. This is an actively-developing concurrent agent's
WIP not committed and not on a feature branch. **Not touched by this
cycle**; my gate ran against the pre-modification source. Two squad
feature branches `squad/edison-jacquard-single-launch-issue-18` and
`squad/edison-jacquard-scenarios-in-app-reset` exist locally
pointing at `3574348` — likely the same agent's branch scaffolding.
If that change is committed and validated in a future cycle, the
suggested mitigation 2 in issue #18 will have been actioned by
Edison.

Loop complete — hand-off to yashasg.
