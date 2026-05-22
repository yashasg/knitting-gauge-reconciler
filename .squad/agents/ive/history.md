# Ive — History

## Core Context

- **Owner:** yashasg
- **Project:** A knitting gauge reconciler that converts patterns between stitch/row gauges.
- **Role:** UI/UX Designer (Apple HIG, accessibility)
- **Joined:** 2026-05-19T07:14:05Z

## Archived Summary

- **2026-05-19 foundation:** Locked the core UI principles — one screen / one press, verdict-first hierarchy, text-before-color semantics, and Dynamic Type-safe typography. Approved compact field sizing, strong verdict contrast, and visible text labels on every semantic pill.
- **Prototype → SwiftUI parity review:** Signed off the iOS app once verdict-state logic, pill contrast, and concise axis-specific copy matched the prototype and accessibility floor.
- **Copy / platform guidance:** Confirmed the canonical Xcode project path remains `app/KnittingGaugeReconciler.xcodeproj`; approved the native Copy Results menu; rejected any user-visible metrics UI for MetricKit/swift-metrics work in v1.
- **See archive:** `history-archive.md` contains the detailed 2026-05-19 through 2026-05-21 log.

## Current Learnings

- 2026-05-21T12:41:13-07:00: The gauge-field mismatch fix must not consume extra vertical space. Preferred pattern: keep equal-width paired fields, carry warning state inside existing field chrome, and move the full mismatch sentence to accessibility payloads / the picker surface.
- 2026-05-21T19:42:31-07:00: Moving Required Adjustment details into a native sheet is HIG-aligned when the sheet uses native detents, a visible Close button, a state-aware title, and a scrollable body that remains accessible at large text sizes.

## Team Updates

- 2026-05-22T02:50:32Z: The user directive for this session superseded Ive's mismatch-only auto-present, persistent inline summary, and cached reopen conditions. Shipped behavior is deterministic: `View Adjustments` always opens the sheet and recomputes on every tap.
- 2026-05-22T02:50:32Z: Detailed pre-summary history moved to `history-archive.md` to keep active context under the 15 KB limit.
