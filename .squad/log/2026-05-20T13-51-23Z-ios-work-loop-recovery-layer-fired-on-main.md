# iOS work loop — recovery layer fired natively on `main` HEAD,
# all 5 ✅, no drift, gate green after one auto-rerun

**Date:** 2026-05-20T13:51:23Z
**Owner:** Tesla (loop lead)
**Status:** Idle on goals. Cycle re-validation passed on current HEAD
`46e4d98` (the prior cycle's log commit). All 5 goals ✅. **First
post-MR !7 cycle on `main` HEAD where the layered gate's rerun
path actually fired** — the per-test signal-term recovery (the
older MR !4 variant, not the new runner-bootstrap / FBSApplicationLibrary
variants added by MR !7) absorbed a single UI-test signal-term flake on
the first attempt, the rerun passed cleanly, and the gate ended
`** TEST SUCCEEDED **` exit 0. No new GitLab issue opened: this is
exactly the behavior the recovery layer was designed for, and prior
cycle logs (12:05:59Z, 13:34:30Z) already cover the failure shape.

## Cycle entry (loop.md step 1)

- `.squad/decisions/inbox/` → **empty** (`ls -la` shows only
  `.` and `..`; unchanged since 2026-05-20T00:08Z, now 13h43m).
- `.squad/log/` top of stack on entry →
  `2026-05-20T13-43-00Z-ios-work-loop-idle-no-drift.md`
  at commit `46e4d98` (the prior cycle's log file, pushed at
  2026-05-20T13:44:54Z per the issue-#9 system note timestamp).
- Commit graph since the prior log cycle (`c837f36`):
  `c837f36` (prior cycle's HEAD, gate-validated) ←
  `46e4d98` (HEAD, prior cycle's log commit; this-cycle entry).
- Working tree on `main` at `46e4d98` → clean; in sync with
  `origin/main` (`git status` empty; one branch deletion on fetch:
  `origin/squad/hopper-runner-bootstrap-signal-term-recovery`
  pruned now that MR !7 is merged).
- Open GitLab issues on entry: **#9** (`state=opened`,
  `user_notes_count=1`, `updated_at=2026-05-20T09:13:39.684Z` —
  unchanged; Tesla's 09:13Z scope-clarification comment now
  awaiting yashasg reply for **~4h38m**. All 16 notes added since
  then are auto-generated `system=true` "mentioned in commit / MR"
  entries, so `user_notes_count` correctly stays at 1) and **#1**
  (charter, intentionally open). **#15** still **closed** by MR !7.
- Open MRs on entry: **none** (`glab mr list` → "No open merge
  requests available on yashasg/knitting-gauge-reconciler.").
- Open work items 1–10 from `loop.md` → all delivered in prior
  cycles.

## Loop step 2 — pick top work item

Work-items list empty. No new actionable item. Proceeded directly
to loop step 3 (re-validation) and loop step 5 (re-evaluate goals).

## Loop step 3 — re-validation on current HEAD

`./app/build.sh test` on iPhone 17 Pro simulator (iOS 26.4 runtime,
build 23E244, UDID `179149FE-BAFF-4464-893B-7468D06F49B7`,
already booted; host macOS 26.5, Xcode 26.4 build 17E192) against
`46e4d98`:

```
real    2m54.923s
** TEST SUCCEEDED **
BUILD_SH_EXIT=0
```

The wall is ~94s longer than the prior cycle's 1m32.8s because
**one signal-term rerun fired** this cycle. The original attempt
took ~111s (per the `IDETestOperationsObserverDebug: 111.153
elapsed` marker), the recovery layer then rebooted the simulator
and reran the single failed test (~64s including reboot), for a
total of ~175s gate-side time matching the `time` wall.

### Two xcresult bundles produced this run

```
app/.build/derived-data/Logs/Test/
├── KnittingGaugeReconciler.signal-term-original.xcresult   ← original first attempt
├── KnittingGaugeReconciler.xcresult                        ← canonical (= flake-rerun, copied/renamed by recovery)
└── KnittingGaugeReconciler.flake-rerun.xcresult            ← rerun source bundle
```

`KnittingGaugeReconciler.signal-term-original.xcresult` summary:

```
result:           Failed
passedTests:      24
failedTests:       1
skippedTests:      0
expectedFailures:  0
totalTestCount:   25                  (24 unique + 1 retried by -retry-tests-on-failure)
statistics:       "25 test runs"      "1 configuration ran with test repetitions"
testFailures[0]:
  testName:         testShareResultsIsSingleAccessibleAffordance()
  targetName:       KnittingGaugeReconcilerUITests
  failureText:      "Test crashed with signal term."
  testIdentifierURL: test://com.apple.xcode/app/KnittingGaugeReconcilerUITests/
                    KnittingGaugeReconcilerUITests/testShareResultsIsSingleAccessibleAffordance
device:           iPhone 17 Pro (iOS 26.4, build 23E244, arm64)
host:             KnittingGaugeReconciler · Built with macOS 26.5
```

`KnittingGaugeReconciler.xcresult` (canonical, = the rerun bundle)
summary:

```
result:           Passed
passedTests:      1                    (the single reran test)
failedTests:       0
skippedTests:      0
expectedFailures:  0
totalTestCount:   1
testFailures:     []
device:           iPhone 17 Pro (iOS 26.4, build 23E244, arm64)
host:             KnittingGaugeReconciler · Built with macOS 26.5
```

Aggregate across both bundles → **25 unique tests, all pass**:
the 24 that passed on the first attempt + the 1 that recovered
on the targeted rerun. The recovery's scoped rerun command
(captured verbatim from stdout):

```
xcodebuild ... -only-testing:KnittingGaugeReconcilerUITests/KnittingGaugeReconcilerUITests/testShareResultsIsSingleAccessibleAffordance \
               SWIFT_TREAT_WARNINGS_AS_ERRORS=YES GCC_TREAT_WARNINGS_AS_ERRORS=YES \
               CLANG_TREAT_WARNINGS_AS_ERRORS=YES OTHER_SWIFT_FLAGS=-warnings-as-errors test
```

The rerun retains the `-warnings-as-errors` flags exactly as the
first attempt does, so a "rerun green" is genuinely warnings-clean,
not a quiet-mode reattempt.

### Which recovery shape fired?

This was the **per-test signal-term** shape (failure shape (a) per
`app/build.sh` lines 234–243 — the variant present since MR !4 /
pre-MR !6). Not the runner-bootstrap shape (b) (added in MR !7,
lines 245–262) and not the FBSApplicationLibrary nil-bundle shape.
The classifier was unambiguous: the original bundle reports exactly
one `testFailures[]` entry with a fully-qualified
`testIdentifierURL`, and the rerun spec emitted by
`rerun_signal_term_failures()` was the per-test triplet
`KnittingGaugeReconcilerUITests/KnittingGaugeReconcilerUITests/testShareResultsIsSingleAccessibleAffordance`.

The MR !7-added paths (runner-bootstrap signal-term collapse into
target-level rerun spec, FBSApplicationLibrary nil-bundle install
recovery) **did not fire** this cycle — there was no
"could not bootstrap runner" message in stdout and no install/launch
failure prior to test execution. Those remain not-yet-exercised
on `main` HEAD; today's run only exercised the older MR !4 path.

### Where the original failure surfaced in stdout

`testShareResultsIsSingleAccessibleAffordance` started "Iteration
1 of 2" (per `-retry-tests-on-failure 1`) at
`2026-05-20 06:48:43.181` and ran past `Wait for
com.yashasg.KnittingGaugeReconciler to idle` at t=0.71s, then the
process exited with the classic signal-term marker:

```
Restarting after unexpected exit, crash, or test timeout;
summary will include totals from previous launches.
```

The `-retry-tests-on-failure` machinery then ran a different test
(`testVerdictHelpButtonOpensPullUpSheet`, iteration 1 of 2) on the
post-restart launch, which passed in 5.024s — but the original
target's xcresult still recorded the signal-term failure for
`testShareResultsIsSingleAccessibleAffordance` because the in-flight
test was already aborted. The gate then printed:

```
error: xcresult summary disagrees with success heuristic — bundle reports
       result=Failed passed=24 failed=1 skipped=0
note: 1 signal-term flake spec(s) detected; rerunning on fresh simulator:
       KnittingGaugeReconcilerUITests/KnittingGaugeReconcilerUITests/testShareResultsIsSingleAccessibleAffordance
```

and invoked the rerun, which passed on the first attempt
(`Executed 1 test, with 0 failures (0 unexpected) in 9.294 (9.294)
seconds`), followed by the final layered-gate marker:

```
note: signal-term flake(s) recovered on rerun; all test assertions now pass
```

This is exactly the documented behavior in the 12:05:59Z cycle log
(which also recovered a per-test signal-term, prior to MR !7) — the
mechanism is unchanged, just newly observed on post-MR !7 `main`.

### Other UI-runner noise (already-known, not the failure cause)

- `IDELaunchParametersSnapshot: The operation couldn't be completed.
  (DebuggerLLDB.DebuggerVersionStore.StoreError error 0.)` /
  `[MT] IDELaunchParametersSnapshot: no debugger version` — Xcode
  26.4 cosmetic noise on every simulator app launch; documented in
  earlier cycle logs (e.g., 12:29:00Z).
- `objc[…]: Class UIAccessibilityLoaderWebShared is implemented in
  both …/WebCore.axbundle/WebCore and …/WebKit.axbundle/WebKit. This
  may cause spurious casting failures and mysterious crashes.` —
  iOS 26.4 simulator runtime duplicate-class warning; benign from
  Apple's side, hits every UI-test launch (documented 12:18Z and
  earlier).
- `Failed: Not hittable: Button … identifier: 'reset-defaults'`
  during `testPrototypeParityControlsAreAvailable` — XCUITest hit
  the button mid-layout, then the test's built-in retry (`Retrying
  Tap "reset-defaults" Button (attempt #2)`) succeeded ~1s later
  and the test passed in 11.884s. This is XCUITest's own per-action
  retry, not the layered-gate rerun layer; it is unrelated to the
  signal-term flake on the next test.

None of these flagged as the rerun's trigger (the trigger was
strictly the bundle's `result=Failed` + a single per-test signal-term
`testFailures[]` entry, which is exactly the per-test shape).

### Compiler-warning scan

```
grep -cE "^(/.+\.swift:[0-9]+:[0-9]+: warning:|warning: )" /tmp/build_test_run.log
→ 0
```

(`grep` exits 1 on zero matches, which is the expected/desired
state.) All other `warning` occurrences in the captured stdout are
flag names (`-warnings-as-errors`, `SWIFT_TREAT_WARNINGS_AS_ERRORS`,
`GCC_TREAT_WARNINGS_AS_ERRORS`, `CLANG_TREAT_WARNINGS_AS_ERRORS`)
printed as part of the two `xcodebuild` invocations (first attempt
and rerun) — not actual warnings.

**Zero compiler warnings across both attempts.**

### Run-streak counters

- **Native first-attempt streak since MR !6:** broken this cycle.
  The prior 11 cycles (`331733d` → `c837f36`) all ran natively
  green on the first attempt. This cycle (`46e4d98`) is the 1st
  cycle since MR !6 to require the rerun path — but the rerun
  succeeded, so the **gate-green streak** (gate exit 0 regardless
  of rerun) extends to 12 consecutive cycles.
- **Post-MR !7 cycles on `main`:** 2 total (`c837f36` native-green
  in the 13:43Z idle cycle, `46e4d98` rerun-recovered this cycle).
- **Post-MR !7 cycles where the MR !7-added recovery paths fired:**
  still **0**. Today's recovery was the older MR !4 per-test path.

### Source-tree diff `c837f36..46e4d98`

```
.squad/log/2026-05-20T13-43-00Z-ios-work-loop-idle-no-drift.md | 378 +++++++++++++++++++++++++++++++++++++++++++++++++++++  (46e4d98)
```

Net code change since the prior cycle: **none**. Only the prior
cycle's log file was added. No Swift source touched, no `build.sh`
touched.

## Loop step 4 — branch / CI / pipeline state

Nothing to push for a feature branch this cycle:

- No Swift source file edited since `c50c6f7` (2026-05-20T07:55:50Z
  UTC) for `ContentView.swift` (997 lines) and `GaugeMath.swift`
  (233 lines).
- `app/build.sh` (456 lines) unchanged since `1452918`
  (2026-05-20T13:22:45Z UTC), the MR !7 merge content.

### No new bridge POST since prior cycle

CI snapshot at re-check (latest 5 on `main`, sorted newest first;
IIDs shown):

```
#134  1452918c  failed  src=external  upd=2026-05-20T13:41:36.296Z  ← last new POST (prior cycle's #134)
#133  16c5be12  failed  src=external  upd=2026-05-20T13:29:02.822Z
#132  eea0f277  failed  src=external  upd=2026-05-20T12:59:41.356Z
#131  a22ec4e6  failed  src=external  upd=2026-05-20T12:52:15.540Z
#130  f8803ee0  success src=external  upd=2026-05-20T12:37:41.407Z
```

Verification of `#134`'s fingerprint (re-fetched from the project
pipelines endpoint, ID `2540658963`):

```
sha:             1452918c7df5ccdc4a9088bcab4d615ddcdc3688
status:          failed
source:          external
before_sha:      0000000000000000000000000000000000000000
started_at:      None         ← null
finished_at:     2026-05-20T13:41:36.295Z
duration:        None         ← null
queued_duration: None         ← null
created_at:     2026-05-20T13:41:36.066Z
ref:            main
jobs count:     0  ([])
```

All four fingerprint flags (`source=external`, `before_sha=000…`,
`started_at=null`, `jobs=[]`) fire. The four-flag classifier
established in the 12:57Z log lines 178–204 continues clean —
eight bridge POSTs total (#125, #126, #127, #128, #131, #132, #133,
#134), zero false positives, zero false negatives.

### HEAD-filter check (authoritative HEAD CI rule)

- HEAD `46e4d98e25cebf6c781f1501ce1b85ded1ef0fdc`:
  `glab api .../pipelines?ref=main&sha=46e4d98…` → `[]`. **Zero
  rows = "no signal"**, not failure. The bridge has not POST'd
  for this SHA in the ~6m31s since `c837f36` ← `46e4d98` was
  pushed (push timestamp 2026-05-20T13:44:54Z per the issue-#9
  system note, current cycle entry 2026-05-20T13:51:23Z).
- Per the bridge's prior behavior of POSTing roughly every 6–13
  minutes after a push, a POST for `46e4d98` is likely incoming
  within the next few minutes; it will match the four-flag
  fingerprint and remain non-actionable.

### No new GitLab issue opened

The per-test signal-term flake on
`testShareResultsIsSingleAccessibleAffordance` is a known
intermittent Xcode 26.4 / iOS 26.4 simulator issue and is
**explicitly the failure mode the layered gate is designed to
absorb**. The recovery layer:

1. Detected the failure (xcresult summary + heuristic disagreement
   classifier).
2. Identified it as a per-test signal-term (single `testFailures[]`
   entry with fully-qualified `testIdentifierURL`).
3. Rebooted the simulator and reran only the affected test.
4. Confirmed the rerun was natively warnings-clean (`-warnings-as-errors`
   flags carried).
5. Emitted the layered-gate success marker and exited 0.

Filing a new issue for "the recovery layer worked correctly" would
contradict the loop's drift-only issue policy. Prior cycle logs
(12:05:59Z, 13:34:30Z) already document the failure shape, and
issue **#15** (closed by MR !7) is the canonical record for the
runner-bootstrap variant. **No new issue.**

## Loop step 5 — goal re-evaluation

1. **Working app:** ✅ Local gate exit 0 on `46e4d98` (iPhone 17
   Pro sim, iOS 26.4 build 23E244, host macOS 26.5, zero crashes
   in canonical bundle, 2m54.9s wall after one auto-rerun). HEAD
   `46e4d98` has no CI pipeline POST yet, but per the authoritative
   HEAD CI rule this is "no signal", not failure. The most recent
   `source=external` POST (#134 for `1452918`) still matches the
   bridge status-mirror fingerprint exactly.
2. **UI/UX approved:** ✅ unchanged — `ContentView.swift` still
   997 lines, last touched `c50c6f7` (2026-05-20T07:55:50Z UTC).
   Ive's sign-off carried forward.
3. **User scenarios captured:** ✅ 6 Jacquard scenarios + 12
   companion unit tests (18 total) + 7 UI tests mapped 1:1; **25/25
   unique tests pass** (24 first attempt + 1 rerun-recovered).
   Mendel's mapping unchanged.
4. **Expert approved:** ✅ `GaugeMath.swift` still 233 lines,
   last touched `c50c6f7`. Jacquard's formula sign-off carried
   forward; no math file touched this cycle.
5. **Code tested and validated:** ✅ 25/25 unique tests green;
   **zero compiler warnings across both attempts**; layered gate
   (`-retry-tests-on-failure` → `verify_xcresult_summary`
   → `rerun_signal_term_failures` → `verify_xcresult_summary`)
   exercised end-to-end with a real per-test signal-term flake and
   recovered cleanly. **This is the first cycle on post-MR !7
   `main` where the rerun path actually fired** — concrete evidence
   the layered gate is wired correctly on the merged `build.sh`.

## Parallel final review (per member area)

- **Tesla** — project scheme, `app.xcodeproj` targets, release
  path unchanged. MR !7 still in place; #15 still closed; #9 still
  held awaiting yashasg reply (~4h38m on the clarification
  comment). Loop posture maintained. **No drift.**
- **Hopper** — `app/build.sh` (**456 lines**, last touched
  `1452918`) exercised the per-test signal-term recovery path
  end-to-end on `main` HEAD for the first time post-MR !7.
  Recovery shape was the older MR !4 variant (per-test signal-term);
  the MR !7-added variants (runner-bootstrap signal-term collapse,
  FBSApplicationLibrary nil-bundle install recovery) did not fire,
  but are still in place and ready. Rerun retained
  `-warnings-as-errors`; rerun bundle was warnings-clean and passing.
  No script change needed this cycle. **No drift; positive
  validation of the layered-gate design.**
- **Ada** — `GaugeMath.swift` unchanged since `c50c6f7`; 18/18
  unit tests green (suite wall ~0.015s, within timing noise of
  prior cycles). **No drift.**
- **Edison** — `ContentView.swift` unchanged since `c50c6f7`;
  7/7 unique UI tests green across both attempts. The flaked test
  (`testShareResultsIsSingleAccessibleAffordance`) was *not* a
  product bug — it crashed before the test body completed any
  assertion (failure message: "Test crashed with signal term."),
  i.e., the simulator-runtime crash happened in the launch/idle
  step, not in product code. **No drift.**
- **Curie** — 25/25 unique tests green; zero compiler warnings;
  canonical bundle (the rerun) `result=Passed`; original bundle
  preserved alongside as `.signal-term-original.xcresult` for
  triage per the build script's design. Serial-UI directive still
  honored (UI suite ran on a single shared simulator both
  attempts). **No drift.**
- **Ive** — UX parity vs `prototype/index.html` unchanged.
  **No drift.**
- **Mendel** — 6 Jacquard scenarios + 9 edge/format/share-fallback
  unit tests + 7 UI tests still 1:1 mapped. The flaked test
  (`testShareResultsIsSingleAccessibleAffordance`) is the
  share-affordance UI test, mapped to the Mendel coverage row
  "single accessible share affordance"; it covered the same
  assertion on the rerun. **No drift.**
- **Jacquard** — math correctness sign-off intact; no math file
  touched this cycle. **No drift.**

## Repo hygiene check

- `excalidraw.log` → `.gitignore` line 11; on disk
  (**6080 bytes**, mtime 2026-05-20T13:45:50Z = 06:45:50 PDT),
  not tracked. The +304 bytes vs the 13:43Z cycle's 5776 bytes
  is one additional Excalidraw MCP server-startup record over
  the past ~6 minutes — routine periodic MCP keepalive, identical
  mechanism to prior cycles.
- `.squad/health-report.txt` → `.gitignore` line 9; on disk, not
  tracked.
- `.squad/log/` → `.gitignore` line 5; tracked logs are
  force-added per established practice (`git ls-files .squad/log`
  = **49 entries** on entry — was 48 last idle cycle; +1 = the
  13:43Z log file. On-disk = **82 entries** — was 81; pre-policy
  locals retained for triage).
- `app/.build/` → `.gitignore` line 17; derived data, log files,
  and both `.xcresult` bundles from this cycle's run all sit
  under here and remain untracked.
- `git status` → clean.

**Hygiene gate green.**

## Drift / new issues

**None this cycle.**

The per-test signal-term flake on
`testShareResultsIsSingleAccessibleAffordance` is the recovery
layer doing its job, not new drift. The bridge POST stream
(unchanged at #134 since the prior cycle) continues to behave as
the documented four-flag status-mirror.

Carried forward (unchanged):

- **GitLab #9** ("swift metrics capture") — Tesla's scope
  clarification comment of 2026-05-20T09:13Z still awaiting
  yashasg reply (~4h38m). All 16 new notes on the issue since
  then are auto-generated `system=true` commit/MR mentions, so
  `user_notes_count` correctly remains 1. Implementation remains
  blocked on scope confirmation. **Held, not blocking goals.**
- **GitLab #1** — project charter metadata, intentionally open.
- **GitLab #15** — **closed** by MR !7 merge `e6b4902`. Today's
  cycle is the first post-merge confirmation that the per-test
  rerun path (the MR !4-era predecessor of #15's bootstrap rerun
  path) is still working on the merged `build.sh`; the MR !7
  expansion did not regress the older path.

## Handoff

Loop remains in the "Final review → All pass → log in
`.squad/log/`, hand off to yashasg" state. Next actionable input
must come from yashasg (reply on #9 to unblock metrics-capture
scope, or a new direction). Today's cycle is a useful positive
data point: the layered gate's rerun path is wired correctly on
post-MR !7 `main` HEAD, fires on a real per-test signal-term flake,
recovers cleanly, and ends the gate green with zero compiler
warnings. Future cycles will continue watching the bridge POST
stream against the four-flag fingerprint and keep extending the
gate-green streak. Squad idle.
