# Curie — History

## Core Context

- **Project:** A knitting gauge reconciler that converts patterns between stitch/row gauges.
- **Role:** Tester
- **Joined:** 2026-05-19T07:11:08.646Z

## Current Queue (2026-07-14T19:32:30.380-07:00)

- Work item #80 owns the final post-merge native gate. Wait until all accepted mandatory work is merged, then run `./app/build.sh test` and inspect the xcresult for zero failures, crashes, warnings, analyzer warnings, skips, and SwiftLint violations.
- Tesla's local candidate run is green (70 test runs; 77 prototype harness checks), but it does not replace Curie's final post-merge gate.
- Preserve the scheme-driven CI test model and serial native simulator gate documented in current team decisions.

## Durable Learnings

- On iOS 26.4, `LazyVGrid` inside a sheet-hosted `UIHostingController` may not render off-screen accessibility cells; eager `HStack` rendering fixed the affected tests.
- `.accessibilityElement(children: .contain)` is load-bearing for the sheet accessibility tree and can swallow SwiftUI `Button` actions. The `UIKitTapButton`/`UIButton` workaround should remain until the platform regression is resolved.
- UI-test scrolling should bail only after measurable no-progress; when both accessibility value and target frame are unavailable, continue rather than assuming failure.
- Before declaring CI blockers, align findings with user directives and the active decision ledger; distinguish defects from accepted design and deferred work.
- Test vectors are governed by the current math contract and Jacquard decisions, not the archival prototype.

## Archive

Earlier detailed session records were moved to `history-archive.md` on 2026-07-14T19:32:30.380-07:00 after this file exceeded 15,360 bytes.
