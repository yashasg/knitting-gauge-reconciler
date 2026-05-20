# Squad Work Loop — Session Validation ✅

**Timestamp:** 2026-05-20T20:43:30Z
**Coordinator:** Tesla
**Branch:** `main` (HEAD: `be687e7` — `Merge branch 'squad/hopper-two-pass-erase-rerun' into 'main'`)

## Intake

- `.squad/decisions/inbox/` reviewed: **empty**.
- Prior log reviewed: `2026-05-20T20-28-24Z-ios-work-loop-squad-session.md` —
  all 5 goals ✅ on `390621c` (first squad-log cycle on the post-#17 / MR-!9
  HEAD); variant-aware recovery layer fired and recovered cleanly on
  `testShareResultsIsSingleAccessibleAffordance` via `simctl shutdown` +
  `simctl boot` only (no `simctl erase`, per the prior variant-aware
  escalation policy). That cycle also flagged a parallel-session
  observation (always-erase WIP hit Mach -308 after erase on
  `testPrototypeParityControlsAreAvailable`) and recommended Hopper either
  keep variant-aware escalation or pair an always-erase change with an
  additional defence before merging.
- **HEAD has advanced** from prior-cycle `390621c` to `be687e7`. Two new
  commits land between the prior log and this cycle:
  - `1715144` — log-only commit (prior cycle's squad-log entry).
  - `760a9a0` — **Hopper · follow-on to #17** · `app/build.sh` —
    "always erase before rerun + two-pass recovery for wedged-sim case".
    Replaces the variant-aware `needs_full_erase` branch with an
    always-erase path (both per-test variant a and whole-target b/c/d
    reruns now get a clean device via `simctl shutdown` + `simctl erase`
    + `simctl boot` + `simctl bootstatus`), and adds a second-pass
    rerun ladder gated by a new `bootstrap_only_rerun_failures()`
    detector that escalates to a heavier reset (shutdown-all-sims +
    2s settle + erase + boot) if the first rerun bundle reports
    **only** recognized bootstrap-class failures. Max two rerun
    attempts total. Strictly narrow second-pass eligibility — any
    per-test SIGTERM, real `XCTAssert` failure, or unknown failure
    shape in the rerun bundle refuses the second pass and the
    original failure stands. (Commit body cites local validation on
    iPhone 17 Pro / iOS 26.4 against this branch HEAD: Run 1 290.24s
    cold-recovery with first-attempt SIGTERM.)
  - `be687e7` — **MR !10** merge of `squad/hopper-two-pass-erase-rerun`
    into `main`. No open MR remains.
  This is the **first squad-log cycle on the post-MR-!10 HEAD** `be687e7`,
  so this gate exercises Hopper's new always-erase + two-pass recovery
  layer in production and directly tests the prior-cycle parallel-session
  concern (always-erase → Mach -308) against real-code.
- `app/build.sh` MD5 fingerprint this cycle: `641f9fb22969bd43eaa706efeaa6c06b`,
  575 lines (vs prior cycle's `b3f369ac9eb672c323293de9ef116587`, 615 lines
  — the new logic is net-negative on lines because the variant-aware
  escalation branches collapsed into a single always-erase code path).
- GitLab issues (`yashasg/knitting-gauge-reconciler`) reviewed (live
  `glab issue list`):
  - **#1** — parent project tracking issue; state=opened. Unchanged
    substantively since prior cycle.
  - **#9** — "swift metrics capture"; state=opened. Unchanged; still
    parked on user clarification (orthogonal to gauge-reconciler scope;
    not a squad blocker).
  - **#17** — closed (MR !9 → `0458f49`); remains closed. The MR !10
    follow-on does not re-open or escalate.
- GitLab MRs: **0 open** (live `glab mr list` → "No open merge requests
  available"). MR !10 merged this cycle window.
- GitLab pipelines on `main` (most recent verified live via `glab ci list`
  and `glab api`):
  - **#2541586496** on `390621c` — **success** (`source=external`,
    `started_at=null`, `duration=null`, `before_sha=00000000`,
    `committed_at=null`, **0 jobs** — `/jobs` API returned `[]` live).
    Same external-bridge-mirror fingerprint as the documented failed
    variants — this is a `state=success` instance of the same benign
    bridge ping. Per the long-running precedent set in prior cycles,
    this is not a real CI run and the `state` field varies independently
    on these bridge pings. No action.
  - **#2541576815** on `0458f49`, **#2541547703** on `e03e10b`,
    **#2541477992** / **#2541420542** / **#2541405293** / **#2541361635**
    / **#2541297975** on prior logs — same benign external-bridge-mirror
    fingerprint (state=failed), no action.
  - No pipelines triggered on `760a9a0` or HEAD `be687e7`
    (verified live: `pipelines?sha=760a9a0…` → `[]`,
    `pipelines?sha=be687e7…` → `[]`). Consistent with the documented
    CI rule: the GitLab SaaS macOS runner (`saas-macos-medium-m1`)
    remains unavailable as a real CI executor; only the external bridge
    occasionally fires (sha-agnostic, state-agnostic).
  - Native-green streak on real-code commits remains unbroken since
    `4fc939c` (MR !8, Curie's #16) — no native GitLab pipeline has run
    on a real-code commit in the post-#16 window, so the streak is
    by-default (no contradicting evidence rather than fresh proof).

## Concurrent-environment notes (informational)

- A separate concurrent local copilot session was running `xcodebuild`
  on `app/app.xcodeproj` with `-scheme UVBurnTimer` and a non-overlapping
  derived-data path (`/tmp/uv-loop7-dd`) and a different simulator UDID
  (`F0ED0452-DA45-43DF-AB30-1D5DD1BB09B3`). That session targets a
  different project entirely (UVBurnTimer is not part of this repo's
  schemes — note this session's `-project app/app.xcodeproj` resolves
  via a relative path from a different cwd). It does not share our
  simulator UDID and does not hold `app/.build/build.lock`, so it does
  not contend with our gate.
- A different concurrent `./app/build.sh test` from another copilot
  session held `app/.build/build.lock` for ~120s at the start of this
  cycle's first gate attempt; our first try timed out at the standard
  120s wait (exit 65). When that concurrent gate completed, the lock
  released; this cycle's gate ran on the canonical `app/build.sh`
  from `be687e7` (MD5 `641f9fb22969bd43eaa706efeaa6c06b`) on the
  second attempt. **Working tree was clean both pre-gate and post-gate**
  — no uncommitted modifications to tracked files (any concurrent
  session's WIP `build.sh` edits live on their own local branches and
  not on the working tree at the time of this gate's execution).

## Build/Test Gate — `./app/build.sh test`

Fresh live run on HEAD `be687e7`, iPhone 17 Pro simulator (iOS 26.4,
device `179149FE-BAFF-4464-893B-7468D06F49B7`, arm64). Working tree
clean.

Exit code: **0** ✅

- **18 unit tests** (GaugeMathTests, Swift Testing): all ✅
  (all sub-3ms; longest `scenario5LooserStitchesHisahashisakaCase` 3.4ms,
  rest microsecond-class):
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
  (recovery rerun fired for one spec — see "Recovery layer notes" below):
  - testAboutHelpButtonOpensPullUpSheet ✅ (~5s)
  - testAccessibilityDynamicTypeStacksGaugeMeasurementPairs ✅ (~4s)
  - **testAllJacquardScenariosAreVisibleInUI** ✅ (initial run: signal-term
    flake → recovery layer fired always-erase rerun → rerun completed in
    **23.189s** with 0 failures; see "Recovery layer notes" below)
  - testCompactWidthKeepsNumericFieldsSideBySideWhenTheyFit ✅ (~5s)
  - testPrototypeParityControlsAreAvailable ✅ (~11s) — **note**:
    this is the spec that hit Mach -308 on the prior cycle's parallel
    always-erase WIP run; on this real-code merged-into-main always-erase
    cycle, the spec passed cleanly on Iteration 1 (no recovery needed for
    it this cycle).
  - testShareResultsIsSingleAccessibleAffordance ✅ (~12s) — **inside the
    original 12.085–12.206s envelope** (the long-running natural-variance
    band documented across the recent steady-state window); the prior
    cycle's recovery-rerun path for this same spec did not recur this
    cycle.
  - testVerdictHelpButtonOpensPullUpSheet ✅ (~5s)
- **Total: 25/25 passed, 0 failures, 0 unexpected**
- Full `./app/build.sh test` wall: **331.49s** real (`/usr/bin/time -p`)
  — substantially above prior steady-state (~91–97s) because the
  recovery layer fired this cycle (cold rerun cost ≈ +240s vs no-recovery
  baseline; ≈ +120s above prior cycle's variant-a recovery wall of
  ~211s, attributable to the new always-erase policy adding an
  ~20s `simctl erase` even on per-test reruns where the prior policy
  used cheaper shutdown/boot only).
- **Build diagnostics** (xcresulttool build-results, post-recovery
  canonical bundle): errorCount=0, **warningCount=0**,
  analyzerWarningCount=0, status=`succeeded`.
  `SWIFT_TREAT_WARNINGS_AS_ERRORS=YES` enforced ✅
- **Test results** (xcresulttool test-results summary):
  - Canonical (post-rerun) bundle: result=Passed, passed=1, failed=0,
    skipped=0 (the rerun bundle, 1 test).
  - Preserved original bundle (`*.signal-term-original.xcresult`):
    result=Failed, passed=24, failed=1, skipped=0 — the 1 failed
    case is `testAllJacquardScenariosAreVisibleInUI` (signal-term,
    no duration recorded by XCTest as the runner died).
  - Combined as the script semantics intend: 24 + 1 rerun-pass = 25/25.
- `** TEST SUCCEEDED **` confirmed after recovery rerun.
- Script footer message: `note: signal-term flake(s) recovered on
  rerun; all test assertions now pass`.

## Recovery layer notes

- This cycle **the recovery layer fired on the new MR-!10 always-erase
  path** and **successfully recovered the gate on the first rerun
  attempt** (no second-pass / heavier-reset ladder needed). The
  triggering spec was `testAllJacquardScenariosAreVisibleInUI` — the
  6-scenario marathon (Mendel's all-scenarios UI test, which sequentially
  launches the app 6 times to verify every Jacquard scenario; this is
  the longest UI spec at ~23s steady-state and the highest-load on
  the runner's launch/terminate cycle, making it the most natural
  candidate for runner-process SIGTERM flakes).
- Per the new policy in MR !10's `app/build.sh`:
  1. Initial xcodebuild exited with `** TEST FAILED **`;
     `verify_xcresult_summary` reported "result=Failed passed=24
     failed=1 skipped=0" (mismatch with success heuristic) and the
     `rerun_signal_term_failures` extractor classified the single
     failure as a per-test SIGTERM flake (variant a in #17 nomenclature).
  2. **Always-erase pre-rerun reset fired** (no longer gated by
     `needs_full_erase` — the variant-aware branch was removed by
     `760a9a0`): `simctl shutdown` + `simctl erase` + `simctl boot`
     + `simctl bootstatus`. **Mach -308 did NOT manifest** on the
     real-code always-erase path this cycle. The prior cycle's
     parallel-session WIP-on-`testPrototypeParityControlsAreAvailable`
     Mach -308 concern is not reproduced on real-code; the new path
     is, this cycle, empirically clean.
  3. Rerun produced `result=Passed`, 0 failures, duration 23.189s
     (the spec's normal end-to-end time). Rerun bundle was renamed
     to canonical (`KnittingGaugeReconciler.xcresult`) and the
     original was preserved alongside as
     `KnittingGaugeReconciler.signal-term-original.xcresult` for
     triage. Standard recovery flow.
  4. `bootstrap_only_rerun_failures()` (the new second-pass
     detector added by `760a9a0`) was **not invoked** — the first
     rerun's bundle reported `Passed`, so no second-pass eligibility
     check fired. The two-pass ladder remains untested in production
     (this cycle exercises only the first half of the new logic);
     it stays as a defence-in-depth path against future wedged-sim
     cases that the first always-erase doesn't clear.
- **Validation of MR !10's design choice**: prior cycle's parallel-session
  observation warned that always-erase might provoke Mach -308 on
  install/launch (the WIP run hit it on a different spec). This cycle
  is the first real-code production exercise of the merged
  always-erase path on a per-test (variant-a) rerun, and **the policy
  worked cleanly** — clean erase, clean reboot via `simctl bootstatus`,
  clean rerun pass on the first attempt. One cycle is not statistically
  definitive, but the prior-cycle parallel-session Mach -308 did not
  recur here. Continued monitoring recommended (Hopper); if a future
  cycle does hit Mach -308 on the always-erase path, the second-pass
  ladder is in place to escalate to the heavier "shutdown-all-sims +
  2s settle + erase + boot" reset.
- **Two-cycles-in-a-row recovery firings, on different specs**:
  - Prior cycle (`1715144`): `testShareResultsIsSingleAccessibleAffordance`
    variant-a SIGTERM, recovered via shutdown+boot only.
  - This cycle (this log): `testAllJacquardScenariosAreVisibleInUI`
    variant-a SIGTERM, recovered via always-erase+boot.
  Different specs each cycle, so no per-spec pattern is forming — the
  flake class is "any UI spec can hit runner SIGTERM under iOS 26.4 /
  Xcode test-runner on iPhone 17 Pro simulator", and the recovery
  layer absorbs it each time. The recovery firing rate has nonetheless
  jumped from "1 in ~20 cycles" (the long quiet steady-state) to
  "2 cycles in a row" — this could be sampling noise (recovery firings
  are rare independent events; two adjacent firings have non-trivial
  probability) or the start of a real environmental degradation. **No
  GitLab issue is opened this cycle** (recovery layer is doing its
  job, all assertions still pass), but Curie / Edison should jointly
  watch the next 3–4 cycles; if a third consecutive cycle requires
  recovery, open an issue to investigate underlying test-stability
  drift on the UI suite. Owners: Curie (test stability), Edison
  (test target if a code-side fix is needed), Hopper (recovery layer
  if its envelope needs widening).
- xcodebuild's native `-retry-tests-on-failure -test-iterations 2`
  retry was not fired this cycle (the signal-term failure mode
  appears as a runner crash, not a test assertion failure, so the
  native retry didn't engage — the script-level recovery layer is
  the correct catcher and it worked).

## Goal Verdict

| # | Goal | Status |
|---|------|--------|
| 1 | **Working app** — `./app/build.sh test` exits 0, iPhone simulator, zero crashes | ✅ (via always-erase rerun on the new MR-!10 build.sh; 0 user-visible crashes; runner SIGTERM was a test-harness flake on `testAllJacquardScenariosAreVisibleInUI`, recovered) |
| 2 | **UI/UX approved** — Ive: ContentView matches prototype/index.html | ✅ (no UI changes since prior approval; this cycle's only commit on `main` is Hopper's `app/build.sh` follow-on, which does not touch `ContentView.swift` or any view) |
| 3 | **User scenarios captured** — Mendel: all 6 Jacquard scenarios covered by unit + UI tests | ✅ (`testAllJacquardScenariosAreVisibleInUI` passed cleanly on rerun, verifying all 6 hero-% / cast-on / row-count outputs end-to-end; 6 scenarioN-prefixed unit tests all green) |
| 4 | **Expert approved** — Jacquard: JS → Swift math port correct per decisions.md | ✅ (no `GaugeMath.swift` changes this cycle; prior sign-off stands; the 18 unit tests' microsecond-class durations confirm the math path is untouched) |
| 5 | **Code tested and validated** — Curie: 25/25 tests, 0 warnings, exit 0 | ✅ (combined 24 initial-pass + 1 rerun-pass = 25/25; xcresulttool reports warningCount=0 + analyzerWarningCount=0; exit code 0) |

## Outcome

All 5 goals ✅ on the **post-MR-!10 HEAD `be687e7`** — the first
squad-log cycle on this HEAD. No new drift on `main`; working tree
clean; no open inbox items; Hopper's follow-on to #17 is live in
the canonical `app/build.sh`.

The recovery layer fired this cycle and behaved correctly: a variant-a
per-test SIGTERM flake on `testAllJacquardScenariosAreVisibleInUI`
was caught and recovered cleanly via the new always-erase policy
(`simctl shutdown` + `simctl erase` + `simctl boot` + `simctl bootstatus`)
on the **first** rerun attempt. The second-pass ladder added by
`760a9a0` was not exercised (first rerun was sufficient) and remains
as defence-in-depth. Gate exit 0, `** TEST SUCCEEDED **`, 25/25,
0 warnings, post-recovery wall 331.49s (≈ +240s vs no-recovery
baseline ~91s; ≈ +120s vs prior cycle's variant-a recovery wall,
attributable to the new always-erase adding an `simctl erase` step
on per-test reruns where the prior policy used cheaper shutdown/boot).

The prior cycle's parallel-session warning that always-erase might
provoke Mach -308 on install/launch (`testPrototypeParityControls`-WIP
observation) **did not reproduce** this cycle on real-code. The
spec passed cleanly on Iteration 1 (~11s, no recovery needed for it).
That said, one cycle is not statistically conclusive; Hopper should
continue to monitor for Mach -308 occurrences on future recovery
firings — if it manifests, the second-pass ladder is in place to
absorb it.

Two consecutive cycles have now exercised the recovery layer on
**different** UI specs (`testShareResults…` prior cycle, `testAllJacquard…`
this cycle). No per-spec pattern, but the firing rate has stepped
up from "1-in-~20" (the long quiet steady-state) to "2-in-a-row".
Could be sampling noise (recovery firings are rare independent events)
or early environmental drift. **No issue opened this cycle**
(recovery absorbs it, all assertions pass), but escalate to a GitLab
issue if a third consecutive cycle requires recovery (Curie / Edison
co-owners).

GitLab side: MR !10 merged `760a9a0` into `main` as `be687e7`; no
open MRs remain. Pipeline #2541586496 on `390621c` is `state=success`
but matches the benign external-bridge-mirror fingerprint
(`source=external`, `started_at=null`, `duration=null`, 0 jobs,
`before_sha=00000000`) — confirms the bridge ping's `state` is
independent of the underlying ref and varies. No native pipelines
triggered on `760a9a0` or `be687e7` (verified live `pipelines?sha=…`
→ `[]` on both), consistent with the macOS-runner-unavailability
external blocker (tracked separately; not a squad blocker for the
goal-verdict). Issues #1 and #9 unchanged substantively. Native-green
streak on real-code commits intact since `4fc939c` (by-default,
no contradicting evidence).

Loop complete — ready for yashasg.
