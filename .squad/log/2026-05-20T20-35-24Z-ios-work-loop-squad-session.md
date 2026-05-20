# iOS Work Loop — Squad Session 2026-05-20T20:35:24Z

**Lead:** Tesla
**Entry HEAD:** `e03e10b` (steady-state, idle-no-drift cadence)
**Exit HEAD:**  `be687e7` (MR !10 merged)
**Result:** all 5 goals ✅

## Entry-gate observation

First gate run on `e03e10b` failed (exit 65) with a previously-unseen UI-runner
bootstrap failure shape:

```
Early unexpected exit, operation never finished bootstrapping - no restart
will be attempted. (Underlying Error: Lost pending connection to the test
runner before launch.)
```

The `rerun_signal_term_failures` extractor in `app/build.sh` did not match this
shape (no `signal term` in the failure text, and the per-target
`"Test crashed with signal term while preparing to run tests"` opener was
absent). The rerun was therefore refused and the original failure stood.
A manual `simctl shutdown all && simctl erase ... && boot` cleared the wedged
device and two subsequent gate runs both passed (123.67s, 101.53s).

Diagnosed as a fourth flake variant **(d)** — *runner-bootstrap connection
loss* — distinct from the existing (a) per-test SIGTERM, (b) bootstrap signal-
term, and (c) install/launch failures. The fix requires both extractor
recognition AND escalation to `simctl erase` (a plain shutdown+boot is not
always enough).

## Work items delivered

### #17 + MR !9 — Hopper · variant (d) recovery (FIRST PASS)

Filed [#17](https://gitlab.com/yashasg/knitting-gauge-reconciler/-/issues/17)
and delivered as MR !9 (merged as `390621c`):

- Added variant (d) matcher to `rerun_signal_term_failures`:
  recognizes `Early unexpected exit, operation never finished bootstrapping`
  + `Lost pending connection to the test runner before launch`.
- Added a `needs_full_erase` flag — when any rerun spec is whole-target,
  escalate sim reset to `simctl shutdown` + `erase` + `boot` instead of just
  `shutdown` + `boot`.
- Updated the docstring to document variant (d) and the erase escalation
  rationale.
- Validated with offline extractor fixtures (all 4 variants accepted, real
  assertion failure correctly rejected) and 2 local gate runs (one of which
  actually exercised the recovery path via variant (c)).

Issue #17 auto-closed on merge.

### MR !10 — Hopper · always-erase + two-pass rerun (FOLLOW-ON, this MR)

Post-merge gate runs on `390621c` exposed a second gap: a per-test (variant a)
SIGTERM still hit `Mach error -308 - (ipc/mig) server died` on the rerun,
because MR !9's escalation only fired for whole-target reruns. The per-test
rerun got only `shutdown` + `boot` and the CoreSimulator state was not
cleared enough.

Filed and delivered as MR !10 (merged as `be687e7`):

1. **Always** erase + boot before the rerun, regardless of variant. Both
   per-test and whole-target reruns now get a clean device. The ~20s extra
   cost is acceptable on the rare recovery path.
2. **Two-pass rerun:** if the rerun bundle itself reports only recognized
   bootstrap-class failures (variant b/c/d, no per-test SIGTERM, no real
   assertion failure), escalate to a heavier reset (`simctl shutdown all`
   + 2s sleep for CoreSimulator IPC to settle + `erase` + `boot`) and try
   the same rerun once more. Max two attempts total.
3. New `bootstrap_only_rerun_failures()` helper detects second-pass
   eligibility. Strict: any per-test SIGTERM, real XCTAssert failure, or
   unknown failure shape in the rerun bundle refuses the second pass and
   the original failure stands.

Validated on iPhone 17 Pro (iOS 26.4) against MR !10 HEAD:

| Run | Wall | Result |
| --- | --- | --- |
| MR !10 local · 1 | 290.24s | First xcodebuild hit per-test SIGTERM on `testAccessibilityDynamicTypeStacksGaugeMeasurementPairs` (variant a); recovery erased the sim, reran just that test; `** TEST SUCCEEDED **`, 25/25, 0 warnings, exit 0. Second-pass NOT needed. |
| MR !10 local · 2 | 105.78s | Clean Iteration 1 pass, 0 warnings, exit 0. |
| Post-merge on `be687e7` | 177.80s (`2m57.8s`) | Per-test SIGTERM in Iteration 1; recovery layer fired, erased sim, rerun passed — `signal-term flake(s) recovered on rerun; all test assertions now pass`, exit 0. |

Extractor fixtures (offline): bootstrap variants (b)/(c)/(d) + Invalid-device-
state + Mach-308 all accepted by `bootstrap_only_rerun_failures` (rc=0);
per-test SIGTERM rejected (rc=2); real XCTAssert rejected (rc=2); mixed
bootstrap + assert rejected (rc=2); empty input rejected (rc=2).

## Concurrent-agent interference (operational note)

During this session, at least **3 other** copilot CLI agents were observed
running the same `loop.md` prompt concurrently (`ps aux` showed PIDs 11769,
27139, 38907 in addition to my PID 56241, all `copilot -p` with the same
loop text). Observable interference:

- `git reflog` showed branch checkouts and resets I did not issue.
- Uncommitted edits in my working tree silently reverted to clean main
  between tool calls.
- First `git push -u` of a feature branch did not actually upload the commit
  (remote stayed at base sha); force-push landed it on retry.
- One concurrent agent landed a passing log cycle (`1715144`) for a run
  that happened to pass without exercising the per-test rerun path, which
  briefly looked like a fix but did not actually patch the gap.

**Mitigation in this cycle:** moved uncommitted work onto a feature branch
via `git stash`/`git stash pop`, committed and pushed in tight back-to-back
calls before re-evaluating state. The build script's existing
`$BUILD_DIR/build.lock` (PID-checked, 120s wait) correctly serialized the
gate runs across agents.

**Recommendation for future cycles:** until concurrent-agent fan-out is
constrained, prefer locking sequences: stash → branch → edit → commit →
push → MR → merge with no intermediate state visits, and check `ps aux`
for sibling `copilot -p` PIDs at cycle entry.

## Goal verdicts (exit, `be687e7`)

| # | Goal | Verdict | Evidence |
| - | --- | --- | --- |
| 1 | Working app — `./app/build.sh test` exits 0, simulator, zero crashes | ✅ | Post-merge gate `be687e7`: 25/25 tests, exit 0, recovery layer fired and recovered cleanly. |
| 2 | UI/UX approved by Ive against `prototype/index.html` | ✅ | No changes to ContentView, GaugeView, or styling this cycle; Ive's prior sign-off on `0a708ce` carries forward. |
| 3 | All 6 Jacquard scenarios covered (Mendel) | ✅ | No changes to `GaugeMath.swift`, `GaugeMathTests.swift`, or `KnittingGaugeReconcilerUITests.swift` this cycle; Mendel's prior coverage map on `0a708ce` carries forward. |
| 4 | Jacquard signs off on JS → Swift math port | ✅ | No changes to `GaugeMath.swift` this cycle; Jacquard's prior sign-off on `0a708ce` carries forward. |
| 5 | Code tested and validated, zero warnings | ✅ | Local gate runs (×3) and post-merge gate on `be687e7` all 0 warnings, 25/25 tests, exit 0. |

## Handoff

`app/build.sh` now handles all four observed UI-runner flake variants with
always-erase + two-pass-rerun semantics. No follow-on issues opened.
Returning to steady-state idle-no-drift cadence.
