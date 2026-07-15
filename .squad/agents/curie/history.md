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
