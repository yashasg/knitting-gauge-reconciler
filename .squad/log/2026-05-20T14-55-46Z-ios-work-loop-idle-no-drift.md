# iOS work loop — idle, no drift
# Post-MR !8 native-green streak extends; gate fastest-ever on
# main bc3f685 (1m31.231s); CI mirror #140 = success on the prior
# log commit 77faa23 (bc3f685 absorbed in the documented
# supersede chain); all 5 ✅.

**Date:** 2026-05-20T14:55:46Z
**Owner:** Tesla (loop lead)
**Status:** Idle. All 5 goals re-validated ✅. No drift. No
new work items. Squad awaiting yashasg input on #9 to unblock
metrics-capture scope.

## Cycle entry (loop.md step 1)

- `.squad/decisions/inbox/` → **empty** (unchanged since
  2026-05-20T00:08:16Z — now **14h47m** without an inbox item).
- `.squad/log/` top of stack on entry →
  `2026-05-20T14-43-21Z-ios-work-loop-curie-layout-stability-fix.md`
  at commit `bc3f685` (prior cycle's log, written by the
  Tesla-led drift-detected-and-resolved cycle that filed #16,
  shipped MR !8, and validated the fix on the new main HEAD
  `4fc939c`).
- Commit graph on entry:
  - `bc3f685` = main HEAD (log-only commit; appended the two
    cycle log files from the prior cycle).
  - `77faa23` = prior log commit immediately under
    `bc3f685` (the in-production validation log for `4fc939c`).
  - `4fc939c` = MR !8 merge commit; product code at this SHA is
    the operating product for goals #1–#5.
  - `f98fa47` = Curie's squash commit on the merged branch.
  - Product diff `4fc939c..bc3f685` = log files only (+1034
    insertions across 2 `.squad/log/*.md` files, zero source).
- Working tree on entry: **clean**; in sync with `origin/main`.
- Open MRs: **none**.
- Open GitLab issues on entry: **#1** (charter, intentionally
  open) and **#9** (`state=opened`, `user_notes_count=1` for
  Tesla's 09:13:39.596Z scope-clarification comment; subsequent
  notes are all auto-generated `mentioned in commit` mirrors —
  17 notes total, but only **1 human-authored** since opening).
  **#15** still closed by MR !7. **#16** still closed by MR !8.
- Open work items 1–10 from `loop.md` → all delivered in prior
  cycles. Top of the work queue is empty.

## Loop step 2 — new CI POST seen on entry

Pipeline **#140** (`source=external`, `status=success`,
`sha=77faa23`, finished 2026-05-20T14:54:05.790Z) had just
landed at entry. Triggered by the bridge-POST chain from the
push of the two log commits (`77faa23` and `bc3f685`):

- GH Actions run `26170145869` (`gitlab_push`,
  `repository_dispatch`, created 14:45:23Z) was the first
  dispatch; **completed `cancelled`** at 14:45:37Z after
  ~14s. Cancellation reason follows the documented
  ci-push-main concurrency rule ("higher priority waiting
  request").
- GH Actions run `26170157460` (`gitlab_push`,
  `repository_dispatch`, created 14:45:33Z, ~10s after the
  cancelled predecessor) was the superseder. **Completed
  `success`** at 14:54:21Z (wall 8m48s). It posted back to
  GitLab as pipeline #140 with `sha=77faa23` — i.e., the
  superseder's dispatch payload carried `77faa23` as the head
  SHA, not the literal latest `bc3f685`.
- Net effect: GitLab pipeline #140 = success on `77faa23`
  but **no dedicated pipeline for `bc3f685`** — `bc3f685` is
  absorbed into the supersede chain. This is the documented
  bridge-mirror dynamic from prior cycles (cf. 12:57Z,
  13:43Z, 14:42Z logs). It is **not drift**: `bc3f685` and
  `77faa23` and `4fc939c` are all byte-identical at the
  product layer (log-file-only diffs), so #140's green on
  `77faa23` validates the same product code as `bc3f685`.
- Pipeline #139 (success on `4fc939c`, finished 14:38:48Z)
  remains the **primary product gate** for this main HEAD;
  #140 (success on `77faa23`) is the post-log-commit
  re-validation.

No new "four-flag non-actionable bridge mirror" cancellation
event this cycle (i.e., no failed pipeline with
`before_sha=0000…` plus GH `cancelled` plus single `"Build "`
status plus instant-POST that was so common across the
12:57Z–13:51Z cycles). The supersede that did occur
(`26170145869` → `26170157460`) resolved cleanly to a
success pipeline rather than to a separate failed bridge
mirror.

## Loop step 3 — local gate on bc3f685

`./app/build.sh test` on iPhone 17 Pro simulator (iOS 26.4
build 23E244, UDID `179149FE-BAFF-4464-893B-7468D06F49B7`,
host macOS 26.5, Xcode 26.4):

```
real    1m31.231s
user    0m3.178s
sys     0m2.594s
** TEST SUCCEEDED **
BUILD_SH_EXIT=0
```

**Fastest native-green wall in recorded cycle history.**
The prior fastest was 1m31.987s (last cycle, pre-MR !8 entry
run on `d7a2d59`); before that the floor sat at ~1m32–1m45s
across the native-green range. Today's 1m31.231s is **~1.4s
below the prior cycle's post-merge gate** of 1m32.587s on
`4fc939c`, with the speedup attributable to a warm
DerivedData (no clean rebuild this session) and the
flake-fix branch's removal of the previously-consumed
xcodebuild retry overhead.

Per-suite tallies (from a second confirmation run captured
to `/tmp/gate-bc3f685.log` to extract grepable diagnostics):

```
Test Suite 'KnittingGaugeReconcilerUITests' passed at 07:50:32.648.
    Executed 7 tests, with 0 failures (0 unexpected) in 57.065 (57.069) seconds
Test Suite 'KnittingGaugeReconcilerUITests.xctest' passed at 07:50:32.648.
    Executed 7 tests, with 0 failures (0 unexpected) in 57.065 (57.069) seconds
Test Suite 'All tests' passed at 07:50:32.649.
    Executed 7 tests, with 0 failures (0 unexpected) in 57.065 (57.070) seconds
✔ Test run with 18 tests in 1 suite passed after 0.002 seconds.
```

`xcrun xcresulttool get test-results summary` on the
canonical xcresult bundle:

```
totalTestCount: 25
passedTests:    25
failedTests:    0
skippedTests:   0
expectedFailures: 0
result:         Passed
```

**Native-green diagnostic fingerprint:**

| Marker | Count |
|---|---|
| `signal-term` | 0 |
| `Restarting after unexpected` | 0 |
| `XCTAssert.*failed` | 0 |
| `verify_xcresult_summary` invocations | 0 |
| `-only-testing` per-spec rerun lines | 0 |
| `Executed 8 tests` (`-retry-tests-on-failure 1` consumed) | 0 |
| Compiler `warning:` lines | 0 |
| `*.xcresult` bundles produced | **1** (canonical only) |

Both safety-net budgets fully **unused**:

1. **xcodebuild `-retry-tests-on-failure 1`** — UI suite
   shows `Executed 7 tests, with 0 failures` (the unique
   count); no eighth-iteration retry line; the
   previously-flaky `testCompactWidthKeepsNumericFieldsSideBySideWhenTheyFit`
   ran exactly once and passed (vs the pre-MR !8 run on
   `d7a2d59` which consumed it: `Executed 8 tests, with 1
   failure (0 unexpected)`).
2. **MR !4 per-test rerun via `verify_xcresult_summary` /
   `-only-testing`** — never engaged; no rerun bundle
   (`*.signal-term-original.xcresult` or otherwise) produced;
   the wall would have been ~2m52s if MR !4 had fired (cf.
   `46e4d98` / `d7a2d59` cycles).

## Loop step 5 — goal re-evaluation

1. **Working app:** ✅ Local gate exit 0 on `bc3f685` (product
   = `4fc939c`); iPhone 17 Pro sim, iOS 26.4; zero crashes;
   1m31.231s native-green wall. GitLab CI #139 = success on
   `4fc939c` (primary product gate); #140 = success on
   `77faa23` (re-validation on identical product code).
   No recovery layer engaged on either gate run this cycle.
2. **UI/UX approved:** ✅ `ContentView.swift` (997 lines)
   byte-identical since `c50c6f7` (2026-05-20T07:55:50Z PDT
   ≡ 14:55:50Z UTC ≈ exactly one day ago by clock).
   `AdaptiveTwoColumnStack` and all hero/table/inputs
   components unchanged. Ive's UX sign-off (from `c50c6f7`
   cycle) carries forward.
3. **User scenarios captured:** ✅ All 6 Jacquard scenarios
   (`scenario1PerfectMatch` … `scenario6BothDenser`) + 12
   companion unit tests + 7 UI tests all pass natively in a
   single iteration each. `testCompactWidthKeepsNumericFieldsSideBySideWhenTheyFit`
   (the spec resolved by MR !8) ran exactly once and passed
   in ~5.3s, freeing the retry budget. Mendel's 1:1 mapping
   unchanged.
4. **Expert approved:** ✅ `GaugeMath.swift` (233 lines)
   byte-identical since `c50c6f7`. Swift Testing unit suite
   passes 18/18 in 0.002s. Math layer not touched, not
   exercised in any recovery path (no recovery path engaged).
   Jacquard's formula sign-off carries forward.
5. **Code tested and validated:** ✅ 25/25 unique tests
   green natively across both gate runs this cycle (the
   1m31.231s entry run and the diagnostic-capture re-run).
   0 compiler warnings. 0 recovery markers. 1 canonical
   xcresult bundle per run. xcresulttool summary confirms
   `result: Passed`. Both safety-net budgets unused —
   maximum headroom for any genuine future flake.

## Parallel final review (per member area)

- **Tesla** — Loop entry validated cleanly; inbox/log/MR
  state matches expected idle pattern; goal re-eval confirms
  no drift. Held items unchanged: **#9** Tesla's 09:13Z
  scope-clarification comment now **~5h42m** awaiting yashasg
  reply (5h30m at prior cycle entry → 5h42m at this entry).
  **#1** charter intentionally open. **No drift.**
- **Hopper** — `app/build.sh` (456 lines) byte-identical
  since `1452918` (MR !7). Gate behavior validated twice this
  cycle (entry run + diagnostic re-run); both invocations:
  exit 0, single canonical xcresult, zero warnings, zero
  recovery markers. Warning gate
  (`SWIFT_TREAT_WARNINGS_AS_ERRORS=YES` /
  `GCC_TREAT_WARNINGS_AS_ERRORS=YES` /
  `CLANG_TREAT_WARNINGS_AS_ERRORS=YES` /
  `-warnings-as-errors`) enforced on both invocations.
  Layered recovery infrastructure (signal-term reclassification,
  per-test rerun via `verify_xcresult_summary`,
  runner-bootstrap retry) all available and unused. **No drift.**
- **Ada** — `GaugeMath.swift` byte-identical since `c50c6f7`.
  Swift Testing unit suite 18/18 in 0.001–0.002s across all
  test methods, repeated cleanly across the two gate runs.
  Math layer not touched, not exercised in any recovery path.
  **No drift.**
- **Edison** — `ContentView.swift` byte-identical since
  `c50c6f7`. Live recalc, hero %s, adjustment table, input
  validation, share/copy, saved-reconciliations panel,
  `AdaptiveTwoColumnStack` layout — all unchanged and
  validated through the 7 UI tests. **No drift.**
- **Curie** — `KnittingGaugeReconcilerUITests.swift`
  byte-identical since MR !8 squash `f98fa47`. The
  wait-for-invariant pattern in `assertSideBySide` /
  `assertStackedBelow` continues to absorb the
  cold-launch layout-pass race silently — the spec ran
  exactly once and passed in 5.3s, with the polling helper
  exiting at the first observation that the geometric
  invariant held (likely sub-100ms on a settled layout, well
  under the 3s timeout ceiling). **No drift.**
- **Ive** — UX parity vs `prototype/index.html` unchanged;
  no product-code changes this cycle. **No drift.**
- **Mendel** — 6 Jacquard scenarios + 12 unit + 7 UI tests
  still 1:1 mapped; all green natively first attempt. The
  resolved layout-stability spec (a parity test, not one of
  the 6 Jacquard scenario tests) further protects the suite
  from coarse-retry-budget consumption. **No drift.**
- **Jacquard** — math correctness sign-off intact; math
  layer untouched. **No drift.**

## Repo hygiene check

- `excalidraw.log` → `.gitignore` line 11; on disk, not
  tracked.
- `.squad/health-report.txt` → `.gitignore` line 9; on disk,
  not tracked.
- `.squad/log/` → `.gitignore` line 5 with `force-add` policy
  on tracked logs. Before this commit:
  `git ls-files .squad/log` = 52 entries (one above the
  prior cycle's count of 51, reflecting the
  `2026-05-20T14-43-21Z-…` log added by the prior cycle's
  commit `bc3f685`); this commit will add the 53rd.
- `.squad/decisions/inbox/` → `.gitignore` line 7; still
  empty, nothing to track.
- `app/.build/` → `.gitignore` line 17; the 2 xcresult
  bundles produced this cycle (entry-run + diagnostic re-run)
  both sit untracked under `app/.build/derived-data/Logs/Test/`.
  Only the most-recent canonical bundle remains on disk
  (xcodebuild overwrites between invocations); no
  `*.signal-term-original.xcresult` companion this cycle.
- `git status` → clean (pre-log-commit).

**Hygiene gate green.**

## Recovery / run-streak counters

- **MR !4 per-test recovery firings on post-MR !7 `main`:**
  unchanged at **2 of 6** cycles (`46e4d98`, `d7a2d59`).
  This cycle (`bc3f685`) did **not** engage MR !4 — gate ran
  native-green both times.
- **xcodebuild `-retry-tests-on-failure 1` firings on
  post-MR !7 `main`:** unchanged at **1 of 6** cycles
  (the pre-MR !8 gate run on `d7a2d59` from the prior
  cycle). Today's two runs: both unused.
- **Native first-attempt streak since MR !8 merge:**
  now **2 consecutive cycles** (`4fc939c` post-merge gate +
  `bc3f685` this cycle), both with single-iteration UI
  suite tallies. The 1m31.231s wall is the fastest seen on
  any main HEAD across the entire post-MR !6 history.
- **Gate-green streak (gate exit 0 regardless of recovery):**
  extends to **16 consecutive cycles** since MR !6.
- **Same-spec flake counter for
  `testShareResultsIsSingleAccessibleAffordance`:**
  unchanged at **2 occurrences** on post-MR !7 `main`
  (`46e4d98`, `d7a2d59`); did not flake this cycle.
- **Same-spec flake counter for
  `testCompactWidthKeepsNumericFieldsSideBySideWhenTheyFit`:**
  unchanged at **1 occurrence** (`d7a2d59`) resolved at
  first observation by MR !8's wait-for-invariant fix.
  Did not recur this cycle (single-iteration pass in 5.3s).
- **MR !7-added recovery paths fired on `main`:** still **0**.
- **MR !8-added test-side waits fired on `main`:** at least
  one (the `assertSideBySide` poll inside
  `testCompactWidthKeepsNumericFieldsSideBySideWhenTheyFit`
  necessarily ran), but the poll exited at first observation
  rather than waiting for the timeout, so it's silently
  successful and produces no log marker.

## Bridge-mirror sub-state

The bridge-mirror dynamic for log-only push trains continues
to follow the established pattern:

- A push containing two log commits (`77faa23` then `bc3f685`,
  pushed in the same `git push`) triggered one GitLab webhook
  per commit, hence two `repository_dispatch` calls into GH
  Actions (`26170145869` and `26170157460`, 10s apart).
- The ci-push-main concurrency rule cancelled the earlier
  dispatch (`26170145869`) ~14s after it started, on
  arrival of the second.
- The second dispatch (`26170157460`) ran to completion in
  8m48s and reported back to GitLab as pipeline #140 with
  `sha=77faa23` — the head SHA from the second webhook's
  payload, which under the GitLab bridge configuration
  resolves to the prior commit (not the literal `bc3f685`
  at the time of GH dispatch).
- The discrepancy between GitLab main HEAD (`bc3f685`) and
  the latest pipeline SHA (`77faa23`) is **not drift** —
  the two commits are byte-identical at the product layer
  (log files only). The primary product-validation pipeline
  remains #139 on `4fc939c`, which is the actual product
  code at HEAD.
- In future pushes that include product changes, the
  bridge-POST cancellation pattern could in principle cause
  a product change at HEAD to lack a dedicated pipeline.
  Mitigation: the local gate (this cycle's 1m31.231s)
  always validates the literal HEAD before any push, and
  the warning gate enforced inside the GH workflow makes
  any product-layer regression unable to ride a green
  pipeline. The pattern is therefore **operationally
  acceptable** but **filed as a future-improvement candidate**
  should any product-pipeline gap appear.

## Drift / new issues

**None this cycle.**

Carried forward (unchanged from prior cycle):

- **GitLab #9** ("swift metrics capture") — Tesla's scope
  clarification comment of 09:13:39Z still awaiting
  yashasg reply (~5h42m at this cycle's entry, up from
  ~5h30m at the prior cycle entry). All subsequent notes
  on #9 are auto-generated `mentioned in commit` mirrors
  (17 notes total, 1 human-authored). Implementation
  remains blocked on scope confirmation. **Held, not
  blocking any of the 5 goals.**
- **GitLab #1** — project charter metadata, intentionally
  open.
- **GitLab #15** — closed by MR !7 merge `e6b4902`.
- **GitLab #16** — closed by MR !8 merge `4fc939c`.

## Handoff

Loop returns to the "Final review → All pass → log in
`.squad/log/`, hand off to yashasg" state on `main` HEAD
`bc3f685` (this cycle's log commit will become the new
HEAD upon push). Today's cycle was the **first
post-MR !8 idle cycle**: no drift, no recovery layer
engaged, fastest native-green wall on record, both
safety-net budgets unused. The pre-MR !8 layout-stability
flake spec ran clean. Next actionable input must come from
yashasg (reply on #9 to unblock metrics-capture scope, or
a new direction). Squad idle.
