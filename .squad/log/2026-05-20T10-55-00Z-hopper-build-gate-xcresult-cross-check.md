# iOS work loop — Hopper closes #13 (build.sh false-pass), all 5 goals ✅

**Date:** 2026-05-20T10:55:00Z
**Owner:** Tesla (loop lead), Hopper (executor on `app/build.sh`)
**Status:** Real drift on Goal #5 (gate trustworthiness) detected on cycle
entry, fixed in MR !5, merged to `main` on `fadaeb4`. GitLab pipeline
#120 + GHA run 26157557983 green; local gate 25/25 green. Issue #13
auto-closed via `closes #13`. Loop re-enters final-review.

## Cycle entry

Per `loop.md` "Each cycle" step 1:

- `.squad/decisions/inbox/` → **empty** (unchanged since 2026-05-20T00:08Z).
- `.squad/log/` top of stack on entry →
  `2026-05-20T10-10-00Z-ios-work-loop-idle-no-drift.md` (commit `f78b953`,
  ≈45 minutes earlier) had recorded all 5 goals ✅, only outstanding item
  GitLab #9 deferred awaiting yashasg.
- Working tree on `main` (`f78b953`) → clean; no commits ahead/behind
  `origin/main`.
- Open GitLab issues on entry: #1 (charter), #9 (still 1 comment, still
  no yashasg reply). #2–#8, #10–#12 closed.
- Open MRs on entry: none.
- Open work items 1–10 from `loop.md` → all delivered in prior cycles.

Re-validation in this cycle uncovered a real regression of trust in the
local gate (not in the app itself): see next section.

## Drift discovered: build.sh masks real test failures

While running `./app/build.sh test` against `f78b953` on a degraded
iPhone 17 Pro simulator (UDID `179149FE-…`, not erased between
sessions), the script returned exit 0 and printed
`note: xcodebuild exit 65 attributed to Xcode 26.4 post-test
infrastructure bug; all test assertions passed` — but the xcresult
bundle disagreed:

```
result      : "Failed"
passedTests : 5
failedTests : 3
skippedTests: 0
```

- **2 UI tests crashed mid-execution with signal term:**
  `testAccessibilityDynamicTypeStacksGaugeMeasurementPairs()`,
  `testPrototypeParityControlsAreAvailable()`.
- **The entire unit-test bundle never bootstrapped** (System Failures
  pseudo-suite: "Early unexpected exit … Lost pending connection to
  the test runner before launch.").
- `xcodebuild` itself printed `** TEST FAILED **` and exited 65.

A clean rerun after `xcrun simctl erase` produced 25/25 green, exit 0
— so this is **not** a source regression in the app. It is a defect
in `app/build.sh` lines 166–183: the `BENIGN_XCODE_INFRA_FAILURE`
regex matches `Early unexpected exit, operation never finished
bootstrapping` and `Test crashed with signal term` anywhere in the
log, which legitimately fires both for pre-/post-test Xcode 26.4
infrastructure noise (the intended case) and for in-test crashes /
bundle bootstrap failures (real failures). The final guard
`! grep -Eq "Test Suite '.*' failed|Test Case '.*' failed"` is
xcpretty-shaped and does not catch Swift-Testing-style output or the
System Failures wrapper.

This affects:
- **Goal #1** — "working app" exit-code contract is unreliable: a
  future real regression on a degraded simulator could silently pass
  the local gate.
- **Goal #5** — Curie's gate cannot be trusted to fail when tests
  actually fail.

Severity: medium today (no source regression hidden), but blocks the
loop's guarantee that "warning = failure, fix before moving on".

## Issue + branch + MR

- **GitLab #13** "Hopper: build.sh masks real test failures via
  overly-broad benign-infra triage" — opened 2026-05-20T10:32Z with
  full reproduction, root cause, and acceptance criteria.
- Branch `squad/hopper-build-gate-xcresult-cross-check` cut from
  `f78b953`.
- **MR !5** opened against `main`, merged on `fadaeb4` after CI green.

## Fix shape (Hopper)

Added `verify_xcresult_summary()` to `app/build.sh` (+58 lines net):

1. Read `xcrun xcresulttool get test-results summary --path
   "$RESULT_BUNDLE_PATH"` JSON.
2. Parse via `/usr/bin/python3` (system, no new dep — already required
   by Xcode CLT).
3. Require `result == "Passed"`, `failedTests == 0`, `passedTests > 0`
   (catches the "no tests ran" bootstrap-crash case).
4. Return 65 on any disagreement, with a diagnostic that names the
   actual bundle counts.

Called in two places:

- **Inside the benign-infra escape hatch** (line 218–229): the
  heuristic now only exits 0 if the xcresult bundle also says Passed.
  Bundle wins over regex. This closes the original bug.
- **Final guard before `exit $STATUS`** (line 232–240): even when
  `xcodebuild` itself exits 0, cross-check the bundle. Defends against
  any future case where xcodebuild reports success while the bundle
  records failures.

The existing checks (warnings-as-errors compile gate, post-run
warning regex, simulator-busy retry-once, real-XCTAssert-failure
grep) are unchanged.

## Verification

**Unit-test matrix** (synthesized JSON fed through a shimmed `xcrun`,
exercising the `verify_xcresult_summary` function in isolation):

| Case | xcresult contents | want | got |
|------|-------------------|------|-----|
| missing bundle | (no directory) | rc=65 | rc=65 ✅ |
| passing | `result=Passed, p=25, f=0, s=0` | rc=0 | rc=0 ✅ |
| **original bug repro** | `result=Failed, p=5, f=3, s=0` | rc=65 | rc=65 ✅ |
| zero-tests bootstrap-crash | `result=Failed, p=0, f=0, s=0` | rc=65 | rc=65 ✅ |
| malformed JSON | `not json at all` | rc=65 | rc=65 ✅ |
| missing keys | `{}` | rc=65 | rc=65 ✅ |

All 6 cases pass. The original bug repro (5p/3f → exit 0 before)
now correctly exits 65 with diagnostic:
`error: xcresult summary disagrees with success heuristic — bundle
reports result=Failed passed=5 failed=3 skipped=0`.

**Integration:** `./app/build.sh test` on a clean iPhone 17 Pro
simulator (iOS 26.4 runtime, UDID
`179149FE-BAFF-4464-893B-7468D06F49B7`) against `fadaeb4`:

- Exit code: 0
- `** TEST SUCCEEDED **`
- xcresult: `result=Passed, passedTests=25, failedTests=0, skippedTests=0`
- Warnings: 0 (compile-time `-warnings-as-errors` + post-run
  `COMPILER_WARN_PATTERN` regex both passed)

## CI / pipeline state on exit

`glab ci list` after merge:

```
(success) • #2540185747 (#120) main                                                (~1 min ago)
(success) • #2540162869 (#119) squad/hopper-build-gate-xcresult-cross-check       (~10 min ago)
(success) • #2540103194 (#118) main                                                (~35 min ago)
```

- **#119** for branch HEAD `0647fbf` → bridge mirror of GHA run
  **26157137291** (`gitlab_mr`, Debug profile, 7m24s, all jobs ✅
  including swift-format --strict lint).
- **#120** for `main` HEAD `fadaeb4` → bridge mirror of GHA run
  **26157557983** (`gitlab_push`, Release profile per
  `push-to-main=Release`, 7m14s, all jobs ✅ including coverage
  threshold).
- Only annotation on both: benign cache-save failure (`.github#17`),
  pre-existing infra noise unrelated to this MR.

CI gate green on current HEAD. Bridge mirror cleanly mirrored both
the MR and the post-merge push.

## Goal status (post-fix)

1. **Working app:** ✅ Local gate exit 0 on `fadaeb4`; iPhone 17 Pro
   simulator iOS 26.4; zero crashes; CI on `main` green (GHA run
   26157557983 → GitLab pipeline #120, 2026-05-20T10:53Z).
2. **UI/UX approved:** ✅ unchanged — Ive's prior signoffs still hold
   (no view file touched).
3. **User scenarios captured:** ✅ 6 Jacquard scenarios + 9 edge
   cases covered (25/25 tests; Mendel mapping carried forward).
4. **Expert approved:** ✅ Jacquard signoff still holds; no math
   change in this MR (`app/build.sh` only).
5. **Code tested and validated:** ✅ 25/25 green; zero warnings;
   **and the gate is now trustworthy** — the verify-xcresult guard
   ensures a future degraded-simulator real failure can no longer
   silently pass.

## Parallel final review (per member area)

- **Hopper** — `app/build.sh` grew from 185→242 lines (+58 net). New
  `verify_xcresult_summary()` helper; called inside benign-infra
  escape hatch AND as final guard before exit. All prior contracts
  (warnings-as-errors, simctl-busy retry-once, mutex lock, xcpretty
  pipe, exit-65 on warning) preserved. Unit-tested 6 cases + green
  integration on `fadaeb4`. **Drift closed.**
- **Tesla** — `app.xcodeproj` scheme + targets unchanged; Release
  configuration exercised on `fadaeb4` by GHA run 26157557983
  (push-to-main → Release). **No drift.**
- **Ada** — `GaugeMath.swift` (233 lines) unchanged. **No drift.**
- **Edison** — `ContentView.swift` (997 lines) unchanged. **No drift.**
- **Curie** — 25/25 green this run (18 unit + 7 UI, serial).
  Gate now defended against the false-positive class that prompted
  this cycle. **No drift.**
- **Ive** — UX parity vs `prototype/index.html` unchanged. **No drift.**
- **Mendel** — Six Jacquard scenarios + nine edge cases still mapped
  1:1; all green. **No drift.**
- **Jacquard** — Math-correctness sign-off still holds; this MR did
  not touch any math file. **No drift.**

## Repo hygiene check (issue #12 follow-through)

- `excalidraw.log` → gitignored line 11; on disk, not tracked.
- `.squad/health-report.txt` → gitignored line 9; on disk, not tracked.
- `git status` clean post-merge.

**Hygiene gate green.**

## Drift / new issues

None remaining. Item discovered this cycle (GitLab #13) was opened,
fixed in MR !5, merged on `fadaeb4`, auto-closed via `closes #13`.

Carried forward (unchanged):

- **GitLab #9** ("swift metrics capture") — Tesla's clarification
  comment of 2026-05-20T09:13Z still awaiting yashasg reply (~1h42m
  since clarification, ~45min since prior cycle re-confirmed waiting).
  No implementation possible until scope is confirmed. **Held, not
  blocking goals.**
- **GitLab #1** — project charter metadata, intentionally open.

## Handoff

Loop returns to the "Final review → All pass → log in `.squad/log/`,
hand off to yashasg" state. Next actionable input must come from
yashasg (reply on #9 to unblock metrics-capture work, or a new
direction). Squad idle.
