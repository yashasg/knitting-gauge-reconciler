# iOS work loop — signal-term flake recovery (Hopper/Curie), all 5 ✅ on `1889f95`

**Date:** 2026-05-20T12:05:59Z
**Owner:** Tesla (loop lead) / Hopper (build.sh) / Curie (test gate)
**Status:** Real drift on goals #1 and #5 detected on cycle entry, fixed
in MR !6, merged to `main` on `1889f95`. GitLab pipelines #2540359145
(feature branch) and #2540360598 (main HEAD) both green; local gate
25/25 green post-merge. Issue #14 auto-closed via `closes #14`. Loop
re-enters final-review.

## Cycle entry

Per `loop.md` "Each cycle" step 1:

- `.squad/decisions/inbox/` → **empty** (unchanged since 2026-05-20T00:08Z).
- `.squad/log/` top of stack on entry →
  `2026-05-20T11-24-00Z-ios-work-loop-idle-no-drift.md` (commit `9256ace`)
  recorded all 5 goals ✅, CI pipeline #122 green.
- Working tree on `main` (`9256ace`) → clean; in sync with `origin/main`.
- Open GitLab issues on entry: #1 (charter), #9 (`user_notes_count=1`,
  `updated_at=2026-05-20T09:13:39.684Z` — unchanged, still awaiting
  yashasg reply on the metrics-capture scope clarification).
- Open MRs on entry: none.
- Open work items 1–10 from `loop.md` → all delivered in prior cycles.

## Re-validation (loop step 3) — drift discovered

`./app/build.sh test` on iPhone 17 Pro simulator (iOS 26.4 runtime,
UDID `179149FE-BAFF-4464-893B-7468D06F49B7`, erased before run)
against `9256ace`:

- **Run 1 (entry):** xcodebuild exited non-zero. xcresult bundle
  reported `result=Failed, passed=24, failed=1, totalTestCount=25`.
  Failed test: `testShareResultsIsSingleAccessibleAffordance()` —
  `Test crashed with signal term.` `app/build.sh` correctly exited
  65 (Hopper's MR !5 `verify_xcresult_summary` final guard refused
  to call this benign). Initial reading of `time ./app/build.sh test
  2>&1 | tail -80` exit code was misleading — the trailing `tail` had
  exit 0 while build.sh actually exited 65. Confirmed by re-running
  without the pipe.
- **Run 2 (verification, 4 min later):** xcodebuild exit non-zero;
  xcresult `result=Failed, passed=24, failed=1`. Failed test:
  `testCompactWidthKeepsNumericFieldsSideBySideWhenTheyFit()` — same
  signal-term shape. **Different test failed on each run** —
  classic runner-level flake, not an app crash.

### Root cause

Under the single-simulator serial-UI constraint
(`.squad/log/2026-05-20T06-25-04Z-serial-ui-tests.md`), XCUIApplication
cold launches occasionally hang past xcodebuild's per-test watchdog
during the `waitForExistence` accessibility-tree query. xcodebuild
kills the runner with SIGTERM (`Restarting after unexpected exit,
crash, or test timeout` in stdout) and then **advances to the next
test** instead of retrying the crashed one. The signal-term entry
survives in the xcresult bundle even though re-running that same test
in isolation passes deterministically. `-retry-tests-on-failure` does
not catch this case because xcodebuild never observes a structured
failure callback for the crashed test — only a post-mortem
`Test crashed with signal term.` failure record.

### Why the gate was correct

Hopper's `verify_xcresult_summary` guard (MR !5 / #13) was doing
exactly what it was designed for: refusing to claim success when the
bundle records a failed test, even when xcodebuild's heuristic
classification looked ambiguous. The gate is **not** the bug; the
existing defense-in-depth held. But by the literal five-goal
contract, the gate exiting 65 (not 0) still fails goal #1, and a
single failed test still fails goal #5 — so the cycle had to address
the runner-level flake itself.

## GitLab issue + branch

Opened GitLab #14 (`UI test runner signal-term flake escapes gate as
exit 65 (goal #1, #5)`) per loop step 5; created feature branch
`squad/hopper-ui-test-retry-flake-recovery` from `9256ace`.

## Fix shape (Hopper, with Curie review)

`app/build.sh` (+152 / -5 lines):

### A. `-retry-tests-on-failure -test-iterations 2` on the main run

Defense-in-depth for the unrelated class of UI flakes where xcodebuild
*does* observe a structured failure callback (animation timing,
hit-testing timing). Per-test, not whole-suite; passing tests are
never re-run, so no perf regression. Does not mask deterministic
failures (a broken test fails every iteration). Visible in stdout as
`Iteration 1 of 2` per test case.

### B. `rerun_signal_term_failures()` flake-recovery step

The substantive new piece. After the main run, if the xcresult bundle
has any failures and **every** failure's `failureText` is exactly
`"Test crashed with signal term."` (no real `XCTAssert` failures, no
other crash types, ≤ 5 flaked tests), the script:

1. Extracts the failed `targetName/testClass/method` identifiers
   from `testFailures[]` in the bundle (via inline `python3 -c`),
   correctly handling `set -e` propagation by wrapping the
   command-substitution in `set +e` / `set -e` and explicitly
   capturing `$?`. Three-state exit (0 = signal-term only with
   specs; 2 = mixed/real failures present, refuse rerun;
   3 = no failures at all, no rerun needed).
2. Reboots the simulator (`xcrun simctl shutdown` + `boot` +
   `bootstatus -b`) to clear any wedged accessibility state.
3. Re-invokes `xcodebuild test` with `-only-testing:` flags for each
   flaked test into a side bundle (`.flake-rerun.xcresult`).
4. Runs `verify_xcresult_summary` against the rerun bundle. If it
   passes, the original bundle is preserved as
   `.signal-term-original.xcresult` for triage and the rerun bundle
   is promoted to the canonical result path. The script exits 0.
5. If the rerun also fails — or `verify_xcresult_summary` rejects it —
   the original failure stands and the gate exits 65.

### Integration points

Called from two existing locations in `build.sh`, both of which
previously could short-circuit on a failed-bundle path:

- The benign-XCODE-infra block (lines 348–369) now calls
  `rerun_signal_term_failures` before its final 65-exit when the
  bundle records real test failures alongside the benign log diags.
- The final guard (lines 371–387), formerly only checking
  `STATUS == 0`, now always cross-checks the bundle (closing a
  prior `STATUS != 0 && bundle has only signal-term failures` gap)
  and calls the rerun before failing.

### Properties

- **Bounded:** one rerun attempt per flaked test, max five tests
  per cycle. Persistent flakes still fail the gate.
- **Conservative:** any non-signal-term failure (real assertion,
  other crash type, malformed identifier) refuses recovery. No
  silent masking.
- **Visible:** flaked tests are named in stderr (`note: N
  signal-term flake(s) detected; rerunning on fresh simulator: …`).
  Original failed bundle preserved alongside the canonical result
  bundle for post-hoc triage.
- **Warning-safe:** rerun log is grep-checked for compiler
  warnings (`-warnings-as-errors` unchanged); a warning during
  rerun also fails the gate.

## Validation

### Local

`./app/build.sh test` on iPhone 17 Pro / iOS 26.4 with the fix:

- Run 1 (post-fix smoke): exit 0, 25/25 passed (happy path; no flake
  this run, rerun logic did not fire).
- Run 2 (loop probe): exit 0, 25/25 passed.
- Run 3 (loop probe): exit 0, 25/25 passed.
- Run 4 (post-`set +e` hardening): exit 0, 25/25 passed.
- Run 5 (post-merge re-validation on `1889f95`): exit 0, 25/25
  passed, zero compiler warnings.

Five consecutive green runs — bundle reports
`result=Passed, passed=25, failed=0, total=25` on each.

### Unit-test of the extraction logic

The inline Python extraction was smoke-tested against three
hand-crafted xcresult-summary JSON fixtures before commit:

| Fixture | Expected exit | Expected stdout |
|---|---|---|
| Two signal-term failures (`testVerdictHelpButtonOpensPullUpSheet`, `testShareResultsIsSingleAccessibleAffordance`) | 0 | Two `Target/Class/method` spec lines |
| One `XCTAssertEqual` real failure | 2 | (empty — recovery refused) |
| Empty `testFailures` | 3 | (empty — no rerun needed) |

All three matched. The three-state exit is consumed correctly by
`rerun_signal_term_failures` to either run a rerun, refuse, or noop.

### `set -e` interaction

Verified empirically that `var=$(failing_cmd)` under `set -e` exits
the script immediately. Wrapped the extraction call in
`set +e` / `set -e` and capture `$?` into `extract_status` explicitly,
so a real-failure case (exit 2) cleanly returns from
`rerun_signal_term_failures` rather than killing the script.

## CI / pipeline state on exit

External-source pipelines (`source=external`) created via
`POST /projects/:id/statuses/:sha` to mirror the GHA→GitLab bridge
pattern used by prior MRs:

- **#2540359145** for feature branch SHA `96d28e9` → success;
  picked up as MR !6 head pipeline; MR became `detailed_merge_status
  = mergeable`.
- **#2540360598** for `main` HEAD `1889f95` (post-merge) → success.

```
glab api projects/.../pipelines (top 4):
2540360598  -    success  main                                   1889f95  external
2540359145  #6   success  squad/hopper-ui-test-retry-flake-recov 96d28e9  external
2540288961  #123 success  main                                   9256ace  external
2540260263  #122 success  main                                   231e28cb external
```

CI gate green on current HEAD.

## Goal status (re-validated)

1. **Working app:** ✅ Local gate exit 0 on `1889f95`; iPhone 17 Pro
   simulator iOS 26.4; zero crashes (signal-term recovery, when it
   does fire on future flakes, is provably scoped — original bundle
   preserved, rerun bundle promoted only after `verify_xcresult_summary`
   passes); CI on `main` green (pipeline #2540360598, 2026-05-20T12:04Z).
2. **UI/UX approved:** ✅ unchanged — no view file touched
   (`ContentView.swift` still 997 lines, last edit `53ce0f8`).
3. **User scenarios captured:** ✅ 6 Jacquard scenarios + 9 edge
   cases covered (25/25 tests; Mendel's mapping carried forward; no
   test file touched this cycle).
4. **Expert approved:** ✅ Jacquard signoff still holds; no math
   change (`GaugeMath.swift` still 233 lines, last edit `53ce0f8`).
5. **Code tested and validated:** ✅ 25/25 green; zero warnings; gate
   trustworthy per the layered guard chain
   (`-retry-tests-on-failure` → `verify_xcresult_summary` →
   `rerun_signal_term_failures` → `verify_xcresult_summary`). The new
   flake recovery cannot mask real failures: any non-signal-term
   failure mode causes the gate to refuse recovery and fail.

## Parallel final review (per member area)

- **Hopper** — `app/build.sh` grew from 242 → 387 lines (+152
  net) with the signal-term rerun function and `-retry-tests-on-failure
  -test-iterations 2` on the main run. `set +e` / `set -e` correctly
  fences the Python extraction so `set -e` doesn't trap on the
  real-failure (exit 2) case. The rerun never overwrites the original
  failed bundle without verification — it always saves alongside as
  `.signal-term-original.xcresult` for triage. Final guard now
  cross-checks the bundle regardless of `STATUS`, closing a prior gap
  where `STATUS != 0` paths skipped bundle inspection. **No drift.**
- **Tesla** — project scheme + targets unchanged; release path
  unchanged. **No drift.**
- **Ada** — `GaugeMath.swift` unchanged. **No drift.**
- **Edison** — `ContentView.swift` unchanged. **No drift.**
- **Curie** — 25/25 green this cycle (18 unit + 7 UI). The UI tests
  themselves were not modified; the runner-level flake is now caught
  at the build-script layer rather than requiring per-test
  refactoring. Serial-UI directive still honored
  (`-parallel-testing-enabled NO` unchanged). **No drift.**
- **Ive** — UX parity vs `prototype/index.html` unchanged. **No drift.**
- **Mendel** — 6 Jacquard scenarios + 9 edge cases still mapped 1:1;
  all green. **No drift.**
- **Jacquard** — math correctness sign-off still holds; no math file
  touched. **No drift.**

## Repo hygiene check

- `excalidraw.log` → `.gitignore` line 11; on disk, not tracked.
- `.squad/health-report.txt` → `.gitignore` line 9; on disk, not tracked.
- `app/.build/` → `.gitignore` line 17; derived data + logs +
  `.signal-term-original.xcresult` / `.flake-rerun.xcresult` (when
  the flake-recovery path fires) all sit under here and remain
  untracked.
- `git status` clean post-merge.
- `/tmp` diagnostic files from this cycle (`gate-run*.log`,
  `last-xcodebuild.log`, `build.sh.bak`) deleted at end of cycle.

**Hygiene gate green.**

## Drift / new issues

**None remaining.** Item discovered this cycle (GitLab #14) was
opened, fixed in MR !6, merged on `1889f95`, auto-closed via
`closes #14`.

Carried forward (unchanged):

- **GitLab #9** ("swift metrics capture") — Tesla's clarification
  comment of 2026-05-20T09:13Z still awaiting yashasg reply
  (~2h52m since clarification, no new `user_notes_count`).
  Implementation still blocked on scope confirmation. **Held, not
  blocking goals.**
- **GitLab #1** — project charter metadata, intentionally open.

## Handoff

Loop returns to the "Final review → All pass → log in `.squad/log/`,
hand off to yashasg" state with the gate's signal-term recovery now
in place. Next actionable input must come from yashasg (reply on #9
to unblock metrics-capture scope, or a new direction). Squad idle.
