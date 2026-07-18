# Curie — History

## Core Context

- **Project:** Knitting gauge reconciler
- **Role:** Tester

## Summarized Learnings

_Summarized at 2026-07-14T23:38:12.955-07:00 after crossing the 15,360-byte history threshold._

- **iOS 26.4 sheet regressions:** `LazyVGrid` can omit off-screen accessibility cells inside a sheet; eager layout avoids this. `.accessibilityElement(children: .contain)` can be required for XCTest visibility while swallowing SwiftUI `Button` taps; the load-bearing workaround is a UIKit `UIButton` wrapper outside the `ScrollView`, with an imperative alert. Do not revert without proving the OS behavior changed.
- **UI scroll helper:** cap attempts at six and stop after two measurable no-progress drags. Compare scroll accessibility value and target frame, but never infer no progress when neither signal is available.
- **Validation history:** MetricKit V1 shipped with 24 payload/subscriber tests. The final identifier-fix gate recorded 61/61 passing, zero lint violations, and zero compiler warnings; simulator contention and SIGTERM flakes require isolated build state and bounded retries.
- **Review discipline:** align findings with user decisions before calling them blockers. Release-build/Debug-test splits, serial policy, cancellation handling, and deferred diagnostics may be explicit choices.
- **Governance:** prototype parity and the Curie §2.9 prototype carveout were retired; scenarios come from Jacquard and `.squad/decisions.md`. The later issue #65 gate permits only a narrow comparison, not parity authority.
- **UI contract changes:** removal of the visible VerdictCard requires UI expectations to follow the current hierarchy while retaining unit coverage for verdict math.
- **CI contract:** Fastlane test participation is scheme-driven; inspect the shared Xcode scheme rather than assuming lane-level filters.
- **Dynamic Type:** keep source-level lint guards and runtime reflow/audit tests complementary. Historical iOS 26 failures involving `cast-on-result`, alert timing, and audit target attachment were infrastructure-sensitive and require explicit evidence before regression attribution.

Earlier detailed entries are retained in `history-archive.md`.

## Issue #65 coverage gate — 2026-07-15T04:42:30.201-07:00

- Added the validator, optional output/screen, validation focus, Reset/Undo, scene/process restoration, independent-scene storage, and revised-form accessibility contracts in the three authorized test files.
- Formula/validator/export coverage passed 23/23; optional screen matrix passed 1/1; Reset/Undo and background restoration passed 2/2; SwiftLint reported 0 violations.
- Canonical `./app/build.sh test` failed: 70/75 passed, 5 failed, 0 skipped; result/build evidence recorded two app accessibility failures, validation/scene/UI-runner crashes, one warning, and retries after unexpected exits.
- Edison UI artifact rejected: Done on multiple invalid fields blocks the main run loop; process interruption loses the scene draft; `gauge-lead` fails contrast and `gauge-summary` fails text-clipping audit. Ada math stayed green. Recommend Hopper for the independent revision.

## Issue #65 final gate — 2026-07-15T09:08:17-07:00

- Approved Hopper's independent revision after focused validation, restoration, keyboard, Dynamic Type, and
  accessibility regressions passed.
- The isolated canonical `./app/build.sh test` gate passed 76/76 with 0 retries, 0 SwiftLint violations, and no
  compiler, analyzer, or application-runtime warning matches.

## Issue #51 exact-SHA rejection — 2026-07-16T18:32:38.211-07:00

- Local HEAD and MR !66 matched Edison revision `2021bac598de922ba67f812d1f1ec95b20d297ba`, but the review worktree was already dirty in `app/build.sh` and `app/fastlane/diagnostics_verifier.rb`.
- Rejected before executable verification because the unstaged toolchain, destination, and verifier-environment changes made exact-SHA attribution impossible; no canonical run or retry was performed.
- Restored issue #51's canonical title, preserved its description/evidence, recorded the rejection, and required a coordinator-spawned independent tooling specialist. Edison is now locked out alongside Tesla, Hopper, and Ada.

## Issue #107 / MR !92 gate review — 2026-07-17T08:46:51.558-07:00

- Performed read-only evaluation of exact SHA `30ec632d8429141fd58a6d671969d9826deb0a17` for issue #107 / MR !92.
- **REJECT:** The required worktree at `/Users/yashasgujjar/dev/knitting-gauge-reconciler-107-prototype` was not found.
- Could not verify SHA linkage, artifact paths, `app/.build/fastlane-output.log`, gate results, unit test counts, suite inventory, skipped/disabled status, warnings/advisories/crashes, unit-only target, or process exit status.
- No substitute artifacts were used; no tests or builds were executed.
- All required evidence for authorization is unavailable at the authorized path.

## Issue #122 / MR !93 evidence review — 2026-07-17T09:04:51.961-07:00

- **REJECT:** Existing artifacts reported 75/75 passing tests across 6 suites with zero failures, skips, warnings, advisories, or crashes, but did not explicitly prove clean exact-SHA provenance or record the outer `./app/build.sh test` exit code.
- The reviewed SHA was `cb75ee577a96bfb541302d0d6f2bbf399ea04579`; its diff was limited to `prototype/index.html`, and the Fastfile/log selected only `KnittingGaugeReconcilerTests`.
- No tests or builds were run. The review worktree was externally removed during the review.

## Final unit-only gate — 2026-07-17T15:24:25.888-07:00

- Proved `./app/build.sh test` is unit-only: it calls Fastlane `ci`; `ci` passes `only_testing: ["KnittingGaugeReconcilerTests"]`; the shared scheme lists only unit target `000...402`; the project keeps UI target `000...403` as a separate UI-testing bundle/source phase.
- Canonical command exited 0: 78/78 unit tests in 6 suites passed, including all six Jacquard scenarios and validator, rounding/status-boundary, large-drift, floating-point, and cast-on edges.
- SwiftLint found 0 violations; warning/crash diagnostic scans were clean; Xcode explicitly bypassed UI-testing initialization. **PASS / APPROVE** for final goals 1/3/5.

## Final unit-only rerun — 2026-07-17T15:55:16.891-07:00

- Immediately before execution, re-proved the active route: `./app/build.sh test` selects Fastlane `ci`; `ci` supplies only `KnittingGaugeReconcilerTests`; the shared scheme's sole testable is unit target `000...402`; the project declares it as a unit-test bundle and keeps the UI-testing target separate.
- Ran exactly `./app/build.sh test` once. It exited 0 with 78/78 tests in 6 suites passing and all six named Jacquard scenarios passing.
- SwiftLint found 0 violations; warnings were compiler errors; Fastlane, exported-diagnostics, and outer-output scans completed cleanly with zero warning/crash matches. **PASS / APPROVE** for final goals 1/3/5.

## Canonical final test execution — 2026-07-17T16:44:38.371-07:00

- Static proof confirmed `./app/build.sh test` selects Fastlane `ci`, whose `scan`/`run_tests` scope is exactly `only_testing: ["KnittingGaugeReconcilerTests"]`; the shared scheme's sole TestAction testable is `KnittingGaugeReconcilerTests`.
- Command count 1: `./app/build.sh test` exited 0 on iPhone 17 Pro (iOS 26.5, UDID `11CCFC00-6C86-434E-B022-0957C4A67EB0`); 78/78 tests passed across 6 suites, including all six Jacquard scenarios.
- SwiftLint reported 0 violations; warning and crash scans found 0 matches. **APPROVE**.

## Unit-only final gate — 2026-07-17T16:55:05.482-07:00

- Re-proved the active route from TEAM ROOT: `app/build.sh` test mode selects Fastlane `ci`; the lane applies `only_testing: ["KnittingGaugeReconcilerTests"]`; the shared scheme has one unit-test TestAction entry; the project classifies that target as a unit-test bundle.
- Ran exactly `./app/build.sh test` once. Exit 0 on iPhone 17 Pro; Swift Testing executed 78 static declarations in 6 suites, with 78 passed, 0 failed, 0 skipped, and no crashes.
- SwiftLint found 0 violations. Compiler warning-as-error settings, exported-diagnostics verification, and outer-output verification completed with no warnings or prohibited diagnostics. All five loop goals remain **PASS**; no in-scope gap.

## Final authorized unit gate — 2026-07-17T17:14:23.945-07:00

- Static inspection proved `./app/build.sh test` routes to Fastlane `ci`, passes only `KnittingGaugeReconcilerTests`, and the shared scheme lists only that unit-test target; UI/XCUITests remained unselected.
- Ran exactly `./app/build.sh test` once. Exit 0 on iPhone 17 Pro, iOS 26.5, UDID `11CCFC00-6C86-434E-B022-0957C4A67EB0`; 78/78 tests in 6 suites passed, including all six Jacquard scenarios, with 0 failures, skips, expected failures, warnings, crashes, or retries.
- SwiftLint reported 0 violations; raw/exported diagnostics and outer-output gates passed. **APPROVE**.

## Final Goal #1/#5 gate — 2026-07-17T18:14:22.715-07:00

- Re-proved the route is unit-only: `build.sh test` selects Fastlane `ci`; the lane adds `only_testing: ["KnittingGaugeReconcilerTests"]`; the shared scheme contains only unit target `000...402`; UI target `000...403` remains separate and unselected.
- Ran exactly `./app/build.sh test` once. Exit 0 on iPhone 17 Pro, iOS 26.5 (`iPhone18,1`, UDID `11CCFC00-6C86-434E-B022-0957C4A67EB0`); 78/78 tests passed in 6 suites.
- SwiftLint found 0 violations; warning and prohibited crash scans found 0 matches; raw/exported diagnostics and outer-output verification passed. **PASS**.

## Final authorized gate — 2026-07-17T18:38:57-07:00

- No sibling `xcodebuild`/`xctest` executor was active immediately before the run; static inspection again proved the route selects only `KnittingGaugeReconcilerTests`.
- Exactly one `./app/build.sh test` run exited 0: 78/78 tests in 6 suites passed on iPhone 17 Pro, iOS 26.5, UDID `11CCFC00-6C86-434E-B022-0957C4A67EB0`; every named Jacquard scenario passed.
- SwiftLint found 0 violations, retries/skips/expected failures/crashes were 0, and raw/exported diagnostics plus outer-output verification were clean. **APPROVE**.
