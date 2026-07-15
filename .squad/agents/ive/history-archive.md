# Ive — Archived History Summary

_Summarized at 2026-07-14T23:38:12.955-07:00 after crossing the 15,360-byte history threshold._

## Durable UX/accessibility learnings

- The design direction favors a focused native utility: clear pattern-versus-swatch inputs, actionable reconciliation outputs, restrained visual hierarchy, and no decorative complexity that competes with the task.
- Cast-on and adjustment UX should use knitter-facing language and paired values that are easy to compare at a glance.
- Early SwiftUI reviews required semantic hierarchy, Dynamic Type support, VoiceOver labels/order, sufficient contrast, and minimum touch targets before approval.
- Canonical Xcode project path is `app/KnittingGaugeReconciler.xcodeproj`; scheme is `KnittingGaugeReconciler`.
- Copy-results UX should use a native menu/share interaction with concise confirmation and accessible labels rather than custom chrome.
- Metrics must remain invisible to the visual experience, privacy-safe, and limited to actionable workflow health; instrumentation must not distort interaction design.
- The mismatch-state revision favored explicit, calm state communication and rejected layouts that overemphasized percentages over the user’s next knitting action.
- UI approval is conditional on runtime evidence across compact widths, large Dynamic Type, VoiceOver, light/dark appearance, and error states.

Current UX decisions remain in `history.md`.
