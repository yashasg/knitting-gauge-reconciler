# iOS work loop — Hopper closes #15, all 5 goals ✅, MR !7 merged

**Date:** 2026-05-20T13:34:30Z
**Owner:** Tesla (loop lead), Hopper (delivery)
**Status:** Cycle delivered a new fix. New GitLab issue **#15** opened
(Hopper · goals 1 & 5), resolved via **MR !7** merged into `main` as
`e6b4902`. Post-merge gate re-validation passed natively. All 5 goals
✅ on current HEAD `e6b4902`.

This cycle breaks the long run of "idle, no drift" cycles that had
held since 2026-05-20T09:46Z. New drift was discovered on entry by
running `./app/build.sh test` on the prior cycle's HEAD `16c5be1` —
the gate failed with a previously-unrecognized variant of UI-runner
flake that MR !6's recovery did not handle. The cycle delivered a
build.sh extension covering two additional flake shapes, observed
together in a single run during validation.

## Cycle entry (loop.md step 1)

- `.squad/decisions/inbox/` → **empty** (unchanged since
  2026-05-20T00:08Z; `ls -la` shows only `.` and `..`).
- `.squad/log/` top of stack on entry →
  `2026-05-20T13-09-12Z-ios-work-loop-idle-no-drift.md` at commit
  `16c5be1` (the prior cycle's log file, pushed at 13:10:23Z UTC).
- Commit graph since prior cycle (before this cycle's work):
  `15123a8` ← `16c5be1` (HEAD on entry).
- Working tree on `main` at `16c5be1` → clean; in sync with
  `origin/main`.
- Open GitLab issues on entry: **#9** (`state=opened`,
  `user_notes_count=1`, `updated_at=2026-05-20T09:13:39.684Z` —
  byte-identical to prior cycle; Tesla's metrics-capture scope
  clarification still awaiting yashasg reply ~4h20m) and **#1**
  (charter, intentionally open).
- Open MRs on entry: **none**.
- Open work items 1–10 from `loop.md` → all delivered in prior
  cycles.

## Loop step 2 — pick top work item

Work-items list empty on entry. Proceeded directly to loop step 3
(re-validation) to confirm idle state — and the gate failed,
generating a new work item.

## Loop step 3 — re-validation on entry HEAD reveals new drift

`./app/build.sh test` on iPhone 17 Pro simulator (iOS 26.4 runtime,
UDID `179149FE-BAFF-4464-893B-7468D06F49B7`, already booted) against
`16c5be1` at 13:13:14Z:

```
real    1m13.731s
BUILD_SH_EXIT=65
error: xcresult summary disagrees with success heuristic — bundle reports result=Failed passed=18 failed=1 skipped=0
error: refusing to treat xcodebuild exit 65 as benign because the xcresult bundle reports real test failures
```

xcresult bundle reported `result=Failed passed=18 failed=1 skipped=0
total=19`. The 18 unit tests passed; the UI suite never started.
Single `testFailures` entry:

```json
{
  "failureText": "Early unexpected exit, operation never finished bootstrapping - no restart will be attempted. (Underlying Error: Test crashed with signal term while preparing to run tests.)",
  "targetName": "KnittingGaugeReconcilerUITests",
  "testIdentifierString": "KnittingGaugeReconcilerUITests-Runner (14649) encountered an error"
}
```

This shape is **not** the per-test signal-term variant MR !6 (#14)
handled. The recovery's Python extractor required
`failureText == "Test crashed with signal term."` exactly AND
`testIdentifierString` containing `/` (Target/method spec). This
variant's `failureText` carries the longer "preparing to run tests"
qualifier and `testIdentifierString` is the
`<Target>-Runner (<pid>) encountered an error` shell — extractor
exited 2, recovery silently returned 1, gate exited 65.

**Drift identified.** Goals 1 and 5 ❌ on `16c5be1` for this run.

## Loop step 4 — open issue, branch, fix, push, merge

### GitLab issue #15

Opened at 13:14Z:

```
#15 · Hopper · goal 1 & 5 · build.sh recovery misses runner-bootstrap signal-term variant
```

Full description posted with failureText/testIdentifierString
verbatim, explanation of why MR !6's extractor misses this variant,
and a fix sketch (extend the extractor to recognize the new variant
and emit a target-only rerun spec).

### Feature branch `squad/hopper-runner-bootstrap-signal-term-recovery`

Branched from `16c5be1`. Two edits to `app/build.sh`:

1. **Extractor extension** — `rerun_signal_term_failures()`'s embedded
   Python now recognizes three classes of failure:
   - `PER_TEST` = `"Test crashed with signal term."` →
     `Target/Suite/method` rerun spec (unchanged from MR !6).
   - `RUNNER_BOOTSTRAP` → match on
     `"Test crashed with signal term while preparing to run tests"`
     substring → emit target-only rerun spec.
   - `RUNNER_INSTALL_FAILED` / `RUNNER_LAUNCH_FAILED` / `FBS_NIL`
     (added during the live verification run below; see "Second flake
     mode appears under verification" section) → emit target-only
     rerun spec.

2. **`BENIGN_XCODE_INFRA_FAILURE` extension** — the early
   "Failed to launch app | NSMachErrorDomain" guard (lines ~180)
   would pre-empt the recovery for the (c) install/launch variant
   because it matches "Failed to launch app" before BENIGN gets
   checked. Pattern now also matches:
   - `Failed to launch app with identifier: com\.yashasg\.KnittingGaugeReconcilerUITests\.xctrunner`
   - `Simulator device failed to launch com\.yashasg\.KnittingGaugeReconcilerUITests\.xctrunner`
   - `Failed to install or launch the test runner`
   - `Application info provider \(FBSApplicationLibrary\) returned nil`

3. **Dedupe across variants** — when the same bundle contains both a
   (a) per-test failure and a (b)/(c) target-level failure for the
   same target (common — an earlier per-test signal-term can leave
   the simulator rough enough that the next runner cold launch
   fails), the target-level rerun subsumes the method-level rerun
   and the narrower spec is dropped to keep `rerun_count` accurate
   against the ">5 = not infra flake" guard.

### Second flake mode appears under verification

First verification run on the branch (13:17Z) — also flaked, but in
a different shape than the entry-cycle flake:

```
real    2m9.774s
BUILD_SH_EXIT=65
error: xcodebuild emitted simulator launch/crash diagnostics
```

xcresult bundle: `result=Failed passed=22 failed=2 skipped=0
total=24`. Two `testFailures` entries:

- `failureText="Failed to install or launch the test runner. (Underlying Error: Simulator device failed to launch com.yashasg.KnittingGaugeReconcilerUITests.xctrunner. (...) Application info provider (FBSApplicationLibrary) returned nil ...)"`
  `testIdentifierString="KnittingGaugeReconcilerUITests-Runner (30907) encountered an error"`
- `failureText="Test crashed with signal term."`
  `testIdentifierString="KnittingGaugeReconcilerUITests/KnittingGaugeReconcilerUITests/testPrototypeParityControlsAreAvailable()"`

The first is the new (c) install/launch variant; the second is the
existing (a) per-test variant. They co-occurred (4 UI tests passed
before the runner died, then the cold-launch retry failed to install
the runner). The build.sh exited at the early guard (line ~180)
*before* the recovery gateway at line ~352, because the first guard
matched "Failed to launch app" and the BENIGN pattern did not
mention the runner-install variant.

Extractor was extended a second time (same edit batch as above) to
cover (c) — recognized by any of the three new substrings — and
`BENIGN_XCODE_INFRA_FAILURE` was extended to neutralize the early
guard for the install/launch shape. With both edits, the extractor
emitted exactly one target-level rerun spec
(`KnittingGaugeReconcilerUITests`), as the dedupe collapsed the
per-test spec into the target-level one.

### Verification

- **Extractor unit-test against the saved failed bundle** (the
  `result=Failed passed=22 failed=2 total=24` bundle from the
  install/launch flake): collapsed correctly to one target-level
  spec `KnittingGaugeReconcilerUITests` and exit 0.
- **End-to-end gate run on the branch** at 13:22Z: **native green**
  (no flake this run; recovery acted as no-op defense in depth as
  designed). `result=Passed passed=25 failed=0 skipped=0 total=25`,
  0 compiler warnings, 1m39s wall, `BUILD_SH_EXIT=0`.

### MR !7 → merged

```
MR !7 · Recover runner-bootstrap & install/launch UI flakes in build.sh — closes #15
  source: squad/hopper-runner-bootstrap-signal-term-recovery
  target: main
  pushed: 13:22Z
  merged: 13:23Z (fast-forward, branch auto-deleted; local branch
                 also removed)
  remove_source_branch: true
```

CI policy reminder (carried forward from prior cycles): no
`.gitlab-ci.yml` is configured in this repo, so feature branches
never receive a real GitLab CI run. External bridge POSTs on `main`
are status-mirrors only (see "Bridge status-mirror framework"
below). The merge therefore proceeded once the **local gate** was
green on the branch tip, per the framework. `glab` warned
"No pipeline running on squad/hopper-runner-bootstrap-signal-term-recovery"
on merge — expected.

GitLab #15 was **auto-closed** by the `closes #15` trailer in commit
`1452918`; verified `state: closed` post-merge.

### Post-merge gate re-validation

`./app/build.sh test` on `main` at `e6b4902` at 13:28Z:

```
real    1m33.797s
** TEST SUCCEEDED **
BUILD_SH_EXIT=0
```

xcresult: `result=Passed passed=25 failed=0 skipped=0 total=25`,
`expectedFailures=0`. Compiler warnings: 0. No
`.signal-term-original.xcresult` / `.flake-rerun.xcresult` sidecars
produced (recovery did not fire — native green again on the merged
HEAD). UI suite wall: ~58.5s (single iteration; the original 75s
included the iteration-1 reboot overhead of the prior failed
attempt).

## Bridge status-mirror framework — #133 datapoint

New `source=external` POST arrived at 13:29:02.575Z for the
**prior** main HEAD `16c5be1` (not the merged `e6b4902` yet):

| field        | value                                       |
|--------------|---------------------------------------------|
| iid          | #133                                        |
| sha          | 16c5be1203b5e162be36aab1a3ed46771bae0d4c    |
| status       | failed                                      |
| source       | external                                    |
| before_sha   | 0000000000000000000000000000000000000000    |
| started_at   | null                                        |
| duration     | null                                        |
| created_at   | 2026-05-20T13:29:02.575Z                    |
| finished_at  | 2026-05-20T13:29:02.820Z (Δ = 245ms)        |
| jobs count   | 0                                           |

All four bridge-mirror fingerprints match the canonical pattern
established in the 12:57Z log:
- `source=external`
- `before_sha=000…000`
- `started_at=null`
- `jobs=[]` (zero-length)

Sub-second `finished - created` delta (245ms) confirms no GitLab
runner ever picked up #133; it is purely a status mirror of the
upstream GHA verdict for `16c5be1`. Per the established framework
this is **not actionable from inside this repo**.

No bridge POST has arrived for the merged HEAD `e6b4902` yet
(checked 8 times across ~4 minutes after merge). Per the
authoritative HEAD CI rule, zero rows for the HEAD SHA = "no
signal", not "failed". Local gate is authoritative for goal 1.

## Loop step 5 — goal re-evaluation on `e6b4902`

1. **Working app:** ✅ Local gate exit 0 on `e6b4902` (iPhone 17 Pro
   sim, iOS 26.4 build 23E244, host macOS 26.5, zero crashes,
   1m33.797s wall). HEAD `e6b4902` has no CI pipeline POST yet ("no
   signal"). Most recent bridge POST is #133 for prior HEAD
   `16c5be1`, `failed`, matches status-mirror fingerprint exactly
   (no GitLab runner executed), so it does not override the
   local-gate signal.
2. **UI/UX approved:** ✅ `ContentView.swift` still 997 lines, last
   touched `c50c6f7` (2026-05-20T07:55Z UTC). Ive's sign-off
   carried forward.
3. **User scenarios captured:** ✅ 6 Jacquard scenarios + 12
   companion unit tests (18 total) + 7 UI tests mapped 1:1; 25/25
   green. Mendel's mapping unchanged.
4. **Expert approved:** ✅ `GaugeMath.swift` still 233 lines, last
   touched `c50c6f7`. Jacquard's formula sign-off carried forward.
5. **Code tested and validated:** ✅ 25/25 green; zero warnings;
   layered gate
   (`-retry-tests-on-failure` → `verify_xcresult_summary`
   → `rerun_signal_term_failures` (now 3 variants)
   → `verify_xcresult_summary`) natively green on the post-merge
   run with no recovery needed.

## Parallel final review (per member area)

- **Tesla** — drove the cycle from entry-flake discovery through
  issue #15 → MR !7 → merge → re-validation. Loop posture restored
  to "all 5 ✅, no drift". No tracker drift.
- **Hopper** — delivered the build.sh fix (`+92/-25 lines`, the only
  source change this cycle). Native green pre- and post-merge.
  Defense-in-depth ladder now spans **three** UI-runner flake
  variants. **No remaining drift.**
- **Ada** — `GaugeMath.swift` unchanged since `c50c6f7`; 18/18 unit
  tests green. **No drift.**
- **Edison** — `ContentView.swift` unchanged since `c50c6f7`; 7/7 UI
  tests green on post-merge run. **No drift.**
- **Curie** — 25/25 green; zero warnings; bundle `result=Passed`;
  the new defense-in-depth ladder is tested by unit-testing the
  extractor against the saved failed bundle (covered above). The
  live-flake-recovery code path was not exercised in the
  post-merge run because that run was natively green; the extractor
  test plus the BENIGN pattern grep test combined cover the
  decision logic. **No drift.**
- **Ive** — UX parity vs `prototype/index.html` unchanged.
  **No drift.**
- **Mendel** — 6 Jacquard scenarios + 9 edge/format/share-fallback
  unit tests + 7 UI tests still 1:1 mapped. **No drift.**
- **Jacquard** — math correctness sign-off intact; no math file
  touched this cycle. **No drift.**

## Repo hygiene check

- `excalidraw.log` → `.gitignore` line 11; on disk, not tracked.
- `.squad/health-report.txt` → `.gitignore` line 9; on disk, not
  tracked.
- `.squad/log/` → `.gitignore` line 5; tracked logs force-added per
  established practice. This log file will be force-added on the
  next commit.
- `app/.build/` → `.gitignore` line 17; derived data, log files,
  and the `KnittingGaugeReconciler.xcresult` from this cycle's
  runs all sit under here and remain untracked.
- `git status` (pre-log-commit) → clean except the new log file
  staged for force-add.

**Hygiene gate green.**

## Drift / new issues

**Net this cycle:**
- **New:** #15 opened — runner-bootstrap (and install/launch)
  variant of UI flake unhandled by build.sh recovery.
- **Resolved:** #15 closed by MR !7 / commit `1452918`. All 5 goals
  back to ✅.

Carried forward (unchanged):

- **GitLab #9** ("swift metrics capture") — Tesla's scope
  clarification comment of 2026-05-20T09:13Z still awaiting yashasg
  reply (~4h20m since clarification, `user_notes_count` still 1).
  Implementation remains blocked on scope confirmation. **Held,
  not blocking goals.**
- **GitLab #1** — project charter metadata, intentionally open.

Bridge status-mirror behavior is unchanged: #133 (newest POST)
matches the same four-fingerprint pattern as #125–#132 before it.
No new GitLab issue opened for the bridge flake (still
non-actionable from inside this repo).

## Handoff

Loop returns to the "Final review → All pass → log in
`.squad/log/`, hand off to yashasg" state on `main` at `e6b4902`.
Next actionable input must come from yashasg (reply on #9 to
unblock metrics-capture scope, or a new direction).

The defense-in-depth recovery ladder now covers all three observed
UI-runner flake shapes; if a fourth variant appears in a future
cycle, the pattern is established (open issue, extend extractor +
BENIGN, re-validate). Squad idle once this log is committed and
pushed.
