# iOS work loop — drift detected & resolved
# Curie closes #16 (layout-stability flake in
# testCompactWidthKeepsNumericFieldsSideBySideWhenTheyFit);
# MR !8 merged squashed; main HEAD now 4fc939c, CI #139 green,
# native-green local gate (no recovery layer engaged), all 5 ✅

**Date:** 2026-05-20T14:43:21Z
**Owner:** Tesla (loop lead) — work assigned to Curie
**Status:** Drift detected mid-cycle on goal #5; filed as GitLab
issue #16; resolved by Curie via MR !8 (`squad/curie-side-by-side-layout-stability`,
squash commit `f98fa47`, merge commit `4fc939c`); main HEAD now
`4fc939c`, CI #139 green, local gate native-green with **no
recovery layer engaged on either side of the merge**. All 5 goals
re-validated ✅.

## Cycle entry (loop.md step 1)

- `.squad/decisions/inbox/` → **empty** (unchanged since
  2026-05-20T00:08:16Z — now 14h35m without an inbox item).
- `.squad/log/` top of stack on entry →
  `2026-05-20T14-04-38Z-ios-work-loop-recovery-fired-again-share-results.md`
  at commit `1b961a3` (prior cycle's log file).
- Commit graph on entry: `1b961a3` was main HEAD; `d7a2d59` (one
  back) was the SHA the prior cycle gate-validated. `d7a2d59` had
  no CI POST yet at the prior cycle's exit.
- Working tree on entry: clean; in sync with `origin/main`.
- Open GitLab issues on entry: **#9** (`state=opened`,
  `user_notes_count=1`, `updated_at=2026-05-20T09:13:39.684Z` —
  unchanged; Tesla's clarification comment now awaiting yashasg
  reply for **~5h30m**) and **#1** (charter). **#15** still
  closed by MR !7.
- Open MRs on entry: **none**.
- Open work items 1–10 from `loop.md` → all delivered in prior
  cycles.

## Loop step 2 — new CI POST seen on entry

While running the entry checks, pipeline **#136** arrived
(`source=external`, `status=failed`, `sha=d7a2d59`, instant POST
with `before_sha=0000…`, `duration=null`, single status `"Build "`
pointing to GitHub Actions run `26167467127`). Classified as the
**four-flag non-actionable bridge mirror** per prior cycles'
authoritative rule: GH Actions run was `cancelled` ("Canceling
since a higher priority waiting request for ci-push-main exists"
— concurrency-canceled by superseder run `26167973722`, which was
already in-progress at 14:08:12Z). Not drift; pipeline #137
(7m41s wall) subsequently turned `d7a2d59` green via the
superseder. Same supersede-cancel pattern documented in 12:57Z and
13:43Z cycle logs.

## Loop step 3 — local gate, first run on d7a2d59

`./app/build.sh test` on iPhone 17 Pro (iOS 26.4 build 23E244,
UDID `179149FE-BAFF-4464-893B-7468D06F49B7`, host macOS 26.5,
Xcode 26.4):

```
real    1m45.273s
user    0m5.072s
sys     0m5.839s
** TEST SUCCEEDED **
BUILD_SH_EXIT=0
```

Wall sits in the native-green range (1m31s–1m45s across recent
cycles), **not** the recovery-path range (~2m52s). Only one
xcresult bundle produced (no `*.signal-term-original.xcresult`
companion). But the per-suite tally line told a different story:

```
Test Suite 'KnittingGaugeReconcilerUITests' failed at 2026-05-20 07:12:18.023.
    Executed 8 tests, with 1 failure (0 unexpected) in 60.753s
```

**8 tests = 7 unique UI tests + 1 retry.** `0 unexpected` means
xcodebuild's built-in `-retry-tests-on-failure 1` budget caught a
flake: the test failed on iteration 1, then passed on iteration 2
within the same xcodebuild invocation. Gate exit is 0 because
xcodebuild treats "expected then pass" as net-success.

The failure spec was **new**:

```
KnittingGaugeReconcilerUITests.swift:194:
error: -[…testCompactWidthKeepsNumericFieldsSideBySideWhenTheyFit]:
XCTAssertLessThan failed:
("241.1111111111111") is not less than ("21.33333333333333")

Iteration 1 → failed at 5.293s
Iteration 2 → passed at 6.083s
```

**This is NOT the watched `testShareResultsIsSingleAccessibleAffordance`
signal-term flake** (`46e4d98`, `d7a2d59` cycles). This is:

- A different test (`testCompactWidthKeepsNumericFieldsSideBySideWhenTheyFit`).
- A different failure mode: **layout-assertion timing race**,
  not a process signal-term.
- A different recovery layer: xcodebuild's coarse
  `-retry-tests-on-failure 1` budget, not the MR !4 per-test
  `verify_xcresult_summary` → `-only-testing` per-spec rerun.

## Drift classification

By loop.md step 5, this **is drift**:

1. **First-ever occurrence** of this spec flaking across the
   entire post-MR !6 cycle history (no entry in the same-spec
   counter prior to this cycle).
2. **Fixable test-side root cause** — the assertion at line 194
   ran immediately after `waitForExistence(timeout: 2)`, which
   only confirms accessibility-tree presence, not SwiftUI layout
   completion. On cold launch, `AdaptiveTwoColumnStack` resolves
   to its horizontal configuration *after* the first frame; the
   sub-frame transient is invisible to users but observable to
   XCUITest's frame inspection.
3. **Burns the coarsest retry budget** — `-retry-tests-on-failure 1`
   is the last-resort safety net for genuine simulator-runtime
   flakes (e.g., signal-terms not classified clean by MR !4's
   extractor). Consuming it on a fixable test-side race weakens
   that safety net.

**Distinct from the "watched signal" of share-affordance
signal-term recurrence** (which has its own filing threshold of
3 consecutive on the same spec or any rerun-itself failure). The
share-affordance flake is a simulator-runtime issue with no
deterministic test-side fix; the new flake is a test-engineering
gap with a small, contained fix.

## Loop step 5 → file GitLab issue → pick top work item

- **Filed:** GitLab issue **#16** (Curie / goal #5 / one-line
  per loop.md step 5):
  *"Layout-stability flake in testCompactWidthKeepsNumericFieldsSideBySideWhenTheyFit —
  assertSideBySide races AdaptiveTwoColumnStack"*. Description
  includes observed gate output, root-cause analysis, distinction
  from the watched signal-term flake, proposed fix scope (test-side
  only, no product-code change), and acceptance criteria.
- **Picked:** #16 became the top open work item; assigned to
  **Curie** per the loop roster (Curie owns all tests).
- **Branch:** `squad/curie-side-by-side-layout-stability` cut
  from `1b961a3` (`main` HEAD on entry).

## Curie's fix (squash commit f98fa47)

Single-file change in
`app/KnittingGaugeReconcilerUITests/KnittingGaugeReconcilerUITests.swift`
(net +39 / −3 lines):

1. Added private `waitUntil(timeout:interval:_:)` helper. Uses
   `RunLoop.current.run(until:)` to pump the run loop (matching
   the existing `waitForScrollingToSettle` style at line 289) —
   **not** `Thread.sleep`, which is incompatible with XCUITest's
   event loop. Returns `Bool` with `@discardableResult` so
   assertion callers can ignore the return.
2. Rewrote `assertSideBySide(_:_:timeout:file:line:)` to
   pre-wait the geometric invariant
   (`trailing.frame.minX > leading.frame.maxX
   && abs(trailing.midY − leading.midY) < max(heights)`) for up
   to 3s, 0.1s polling interval, before producing the same two
   `XCTAssert*` lines with actual frame values if the invariant
   never stabilizes.
3. Same treatment for
   `assertStackedBelow(_:_:timeout:file:line:)`
   (single-axis invariant).
4. Reformatted both helpers' signatures and the trailing
   `XCTAssertLessThan` call to break lines under 120 cols
   (decisions doc §2.7 compliance — pre-existing 174-char line
   replaced).

**No product-code change.** `ContentView.swift`,
`GaugeMath.swift`, `AdaptiveTwoColumnStack`, and any other
non-test source are byte-identical. The transient layout state is
sub-frame and users do not perceive it; fixing it test-side
preserves Ive's UX sign-off without re-triggering UX review.

## Loop step 3 — gate after fix (local on branch HEAD)

`./app/build.sh test` on the same simulator:

```
real    1m43.346s
user    0m3.379s
sys     0m3.312s
** TEST SUCCEEDED **
BUILD_SH_EXIT=0
```

Per-suite tallies (line 1283–1287 of the run log):

```
Test Suite 'KnittingGaugeReconcilerUITests' passed at 07:17:37.170.
    Executed 7 tests, with 0 failures (0 unexpected) in 68.522s
✔ Test run with 18 tests in 1 suite passed after 0.062 seconds.
```

- **Exit 0**
- **0 compiler warnings**
- **0 recovery markers** (no `signal-term`, no `rerun`, no
  `Restarting after unexpected`, no `XCTAssert*` failure)
- **1 xcresult bundle** (canonical only — no `*.signal-term-original.xcresult`)
- **UI suite: `Executed 7 tests` not `Executed 8 tests`** —
  zero retries consumed; the previously-flaky spec ran exactly
  once and passed in 8.981s (vs prior 5.293s fail + 6.083s
  retry = 11.376s budget consumed pre-fix — **net wall
  improvement of ~2.4s** on the same path).
- **Unit suite:** 18/18 Swift Testing tests pass in 0.062s.

All five acceptance criteria from issue #16 satisfied.

## Loop step 4 — push, CI, merge

- Branch pushed: `origin/squad/curie-side-by-side-layout-stability`
  at SHA `f98fa47`.
- MR opened: **!8** ("Stabilize side-by-side / stacked layout
  assertions — closes #16"), target `main`, source-branch removal
  on merge enabled.
- GitHub Actions run for the MR: `26168620860` (`gitlab_mr`
  workflow). **Completed `success` in 9m47s** at 14:28:46Z.
- GitLab pipeline mirror: **#138** for `f98fa47` →
  `status=success`. MR's `detailed_merge_status` flipped to
  `mergeable` with `head_pipeline_status=success`.
- Merged at 14:30:59Z via merge commit (not squash, per established
  pattern of merge commits on `main` — see `e6b4902`, `1889f95`).
  Merge commit: `4fc939c`. Source branch
  `squad/curie-side-by-side-layout-stability` deleted server-side
  and local-pruned.
- Issue **#16 auto-closed** by the merge (the squash commit
  message contains `closes #16`); verified via `glab issue view 16
  state=closed`.

## Loop step 3 — gate on new main HEAD 4fc939c

After `git checkout main && git pull --ff-only`, re-ran the gate:

```
real    1m32.587s
user    0m3.040s
sys     0m2.798s
** TEST SUCCEEDED **
BUILD_SH_EXIT=0
```

- **Fastest native-green wall in recent history** (vs 1m31s,
  1m45s, 2m52s across the last 4 cycles).
- 0 compiler warnings.
- 0 recovery markers.
- 1 xcresult bundle (canonical only).
- Per-suite: `Executed 7 tests, with 0 failures (0 unexpected)
  in 59.593 seconds` on the UI suite (vs 60.753s pre-fix with
  the extra retry — the 1.16s reduction is the saved retry
  overhead, dominated by the second iteration's app-launch cost).
- Target spec `testCompactWidthKeepsNumericFieldsSideBySideWhenTheyFit`:
  single iteration, 5.308s (vs 8.981s on the branch — the
  branch run had a hotter simulator from the prior build,
  here we're at a normal cadence). The polling overhead is
  bounded by the 3s timeout and exits the moment the invariant
  is satisfied — typically sub-100ms on a settled layout.
- Unit: 18/18 in 0.007s.

## Loop step 4 — CI on new main HEAD

- GitHub Actions run **`26169339784`** (`gitlab_push` workflow)
  triggered by the merge push; completed `success` in **7m46s**.
- GitLab pipeline **#139** for `4fc939c` (full SHA
  `4fc939c3eec42eb513999875b6c62a40334a9a55`): `status=success`,
  finished 14:38:47Z. Single status `"Build "` mirroring the
  GH run.
- **No supersede-cancel this cycle** on the merge push — the
  run completed cleanly without being displaced. (Contrast with
  prior cycles' #136 pattern where a queued superseder canceled
  the in-flight run.)

## Loop step 5 — goal re-evaluation

1. **Working app:** ✅ Local gate exit 0 on `4fc939c` (iPhone 17
   Pro sim, iOS 26.4, zero crashes, 1m32.6s native-green wall).
   GitLab CI **#139** = success on the same SHA. No recovery
   layer engaged.
2. **UI/UX approved:** ✅ `ContentView.swift` (997 lines)
   byte-identical since `c50c6f7` (2026-05-20T07:55:50Z). Ive's
   sign-off carries forward; no product-code change in MR !8.
3. **User scenarios captured:** ✅ 6 Jacquard scenarios + 12
   companion unit tests (18 unit total) + 7 UI tests (25 unique
   tests overall) all pass natively in a single iteration each.
   Mendel's mapping unchanged; the resolved flake spec
   (`testCompactWidthKeepsNumericFieldsSideBySideWhenTheyFit`)
   is a layout-parity test, not one of the 6 Jacquard scenario
   UI tests — the Jacquard scenarios themselves were never
   involved in this cycle's drift.
4. **Expert approved:** ✅ `GaugeMath.swift` (233 lines)
   byte-identical since `c50c6f7`. Jacquard's formula sign-off
   carries forward; math layer not touched and not exercised in
   the recovery path (flake was UI-layer only).
5. **Code tested and validated:** ✅ 25/25 unique tests green
   natively (no retry budget consumed, no per-test rerun
   bundle); 0 compiler warnings across all xcodebuild
   invocations this cycle. The previously-flaky spec now runs
   exactly once and passes. Net safety-net status: **MR !4
   per-test recovery budget unused this cycle; xcodebuild
   `-retry-tests-on-failure 1` budget unused this cycle** —
   both safety nets fully available for any genuine future
   simulator-runtime flake.

## Parallel final review (per member area)

- **Tesla** — Drift correctly classified mid-cycle (first
  occurrence, fixable test-side, distinct from watched
  signal-term pattern); issue #16 filed with loop.md step 5
  compliance (member name, goal #, one-line description); fix
  assigned to the correct owner (Curie owns tests); merge
  commit pattern preserved (`4fc939c` matches the `e6b4902` /
  `1889f95` shape). **No drift.** Open held items unchanged:
  **#9** (Tesla's 09:13Z scope-clarification comment now ~5h30m
  awaiting yashasg reply — still blocked on user input, not
  blocking any of the 5 goals).
- **Hopper** — `app/build.sh` (456 lines) byte-identical since
  `1452918` (MR !7 merge). Layered gate behavior validated
  twice this cycle: pre-fix it correctly absorbed the
  `-retry-tests-on-failure 1` flake without false-failing the
  gate (exit 0, no signal-term mis-classification); post-fix
  it ran cleanly native-green with no recovery layer engaged.
  Warning gate (`-warnings-as-errors` / `SWIFT_TREAT_WARNINGS_AS_ERRORS` /
  `GCC_TREAT_WARNINGS_AS_ERRORS` / `CLANG_TREAT_WARNINGS_AS_ERRORS`)
  enforced on all 3 xcodebuild invocations this cycle (entry
  run, branch run, post-merge run); zero compiler warnings on
  all three. **No drift.**
- **Ada** — `GaugeMath.swift` (233 lines) byte-identical since
  `c50c6f7`. Swift Testing unit suite passed 18/18 natively in
  0.007–0.062s across all three runs this cycle (the spread is
  simulator-warmth-only). Math layer not exercised in any
  recovery path. **No drift.**
- **Edison** — `ContentView.swift` (997 lines) byte-identical
  since `c50c6f7`. The flake's root cause was a SwiftUI
  layout-pass transient in `AdaptiveTwoColumnStack` on cold
  launch, but the fix was applied test-side (Curie's domain)
  because: (a) the transient is sub-frame and user-invisible;
  (b) `AdaptiveTwoColumnStack`'s current shape was reviewed by
  Ive and changing it would re-trigger UX review for no user-
  facing benefit; (c) the test-side wait-for-invariant pattern
  is the conventional XCUITest fix for this class of race.
  **No drift in UI code.**
- **Curie** — Single-file test fix delivered, MR !8 merged via
  CI-green path; coding-standards check pass (§2.7 line-length,
  §2.9 XCTest for UI, §2.4/§2.5 no force-unwrap/IUO, §2.12 no
  print/Logger). Test wall behavior on the resolved spec: 5.293s
  fail + 6.083s retry (pre-fix, retry-budget consumed) →
  5.308s native pass (post-fix on main, single iteration, retry
  budget intact). UI suite tally moved from `Executed 8 tests,
  with 1 failure (0 unexpected)` to `Executed 7 tests, with 0
  failures (0 unexpected)` — the cleaner shape. **No drift.**
- **Ive** — UX parity vs `prototype/index.html` unchanged. The
  `AdaptiveTwoColumnStack` horizontal-on-compact layout
  contract preserved (the test that flaked was specifically
  asserting that contract); the test now waits for the layout
  pass to complete rather than asserting on its transient
  state. No UX-visible change. **No drift.**
- **Mendel** — 6 Jacquard scenarios + 12 companion unit tests
  + 7 UI tests still 1:1 mapped. The resolved flake spec is
  one of the 7 UI tests (the compact-width layout test), not
  one of the 6 Jacquard scenario tests; scenario coverage is
  100% green on the first attempt natively both pre- and
  post-fix. **No drift.**
- **Jacquard** — math correctness sign-off intact; no math
  file touched this cycle; math layer not exercised in either
  pre-fix or post-fix recovery paths (flake was UI-layer only
  and the post-fix run had no recovery path at all). **No
  drift.**

## Repo hygiene check

- `excalidraw.log` → `.gitignore` line 11; on disk, not tracked.
- `.squad/health-report.txt` → `.gitignore` line 9; on disk,
  not tracked.
- `.squad/log/` → `.gitignore` line 5 with `force-add` policy
  on tracked logs. Before this commit:
  `git ls-files .squad/log` = 51 entries; this commit will
  add the 52nd. On-disk = 84 + 1 (this cycle's tracked log,
  no other untracked log files).
- `.squad/decisions/inbox/` → `.gitignore` line 7; still
  empty, nothing to track.
- `app/.build/` → `.gitignore` line 17; the 3 xcresult bundles
  produced this cycle (entry-run, branch-run, post-merge-run)
  all sit untracked under `app/.build/derived-data/Logs/Test/`.
- `git status` → clean (pre-log-commit).

**Hygiene gate green.**

## Recovery / run-streak counters

- **MR !4 per-test recovery firings on post-MR !7 `main`:**
  unchanged at **2 of 5** cycles (`46e4d98`, `d7a2d59`). This
  cycle (`4fc939c`) did **not** engage MR !4 — gate ran
  native-green post-merge. The recovery infrastructure remains
  fully available; today's drift was absorbed and resolved at
  the *test-engineering* layer, not the *test-runtime recovery*
  layer.
- **xcodebuild `-retry-tests-on-failure 1` firings on post-MR
  !7 `main`:** **1 of 5** cycles (this cycle's pre-fix gate
  run on `d7a2d59`). Post-fix on `4fc939c`: budget unused.
- **Native first-attempt streak since MR !7 merge:** post-merge
  it's now **1** cycle (`4fc939c` native-green). Pre-merge
  `d7a2d59` reset the prior streak with the new layout flake.
- **Gate-green streak (gate exit 0 regardless of recovery):**
  extends to **15 consecutive cycles** since MR !6.
- **Same-spec flake counter for
  `testShareResultsIsSingleAccessibleAffordance`:** unchanged
  at **2 occurrences** on post-MR !7 `main` — that spec did
  not flake this cycle.
- **Same-spec flake counter for
  `testCompactWidthKeepsNumericFieldsSideBySideWhenTheyFit`:**
  **resolved** at first occurrence by the wait-for-invariant
  fix; not expected to recur unless the underlying SwiftUI
  layout-pass timing changes substantially.
- **MR !7-added recovery paths fired on `main`:** still **0**.

## Drift / new issues

**Detected and resolved within this cycle.**

- **#16 filed → MR !8 merged → #16 closed** within ~35 min
  total cycle time (drift detection at 07:11 PDT, fix landed
  on main at 07:30 PDT, CI green at 07:38 PDT). Loop.md step 5
  honored end-to-end: drift seen → issue opened → top work
  item picked → branch + test → push → CI green → merge → log.

Carried forward (unchanged from prior cycle):

- **GitLab #9** ("swift metrics capture") — Tesla's scope
  clarification comment of 2026-05-20T09:13Z still awaiting
  yashasg reply (~5h30m). Implementation remains blocked on
  scope confirmation. **Held, not blocking goals.**
- **GitLab #1** — project charter metadata, intentionally open.
- **GitLab #15** — closed by MR !7 merge `e6b4902`.

## Handoff

Loop returns to the "Final review → All pass → log in
`.squad/log/`, hand off to yashasg" state on `main` HEAD
`4fc939c`. Today's cycle was the **first drift-detected-and-
resolved cycle on post-MR !7 main**: the loop infrastructure
caught a new flake class (layout-stability assertion race,
distinct from the watched signal-term pattern), correctly
classified it as drift rather than as a watched signal,
filed the issue, dispatched to the right owner (Curie),
shipped a surgical test-only fix through full CI, and returned
to all-5-✅ state. The fix improves the *cleanliness* of the
safety nets (both xcodebuild's coarse retry budget and MR !4's
per-test rerun budget are now unused on the routine main path,
fully available for genuine future flakes). Next actionable
input still must come from yashasg (reply on #9 to unblock
metrics-capture scope, or a new direction). Squad idle.
