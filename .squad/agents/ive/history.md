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
- 2026-05-21T20:30:12-07:00: Apple's single-screen utility apps (Calculator, Compass, Stopwatch, Measure) do not display the app name as a heading — the function is self-evident. For this app, the HIG-aligned choice is to remove the `.largeTitle` "Gauge Reconciler" header entirely, letting the content cards serve as the hero. The info button stays; the title goes. Spec delivered to `.squad/decisions/inbox/ive-app-title-hig-spec.md`.
- 2026-05-22T01:45:35-07:00: This palette's dark mode should stay warm and textile-like: backgrounds shift to brown-black, cards lift one step lighter, semantic amber/red accents brighten for contrast, and texture dots must invert to a very low-opacity light speck instead of a dark one. Spec delivered to `.squad/decisions/inbox/ive-color-spec-dark-mode.md`.

## Team Updates

- 2026-05-22T02:50:32Z: The user directive for this session superseded Ive's mismatch-only auto-present, persistent inline summary, and cached reopen conditions. Shipped behavior is deterministic: `View Adjustments` always opens the sheet and recomputes on every tap.
- 2026-05-22T02:50:32Z: Detailed pre-summary history moved to `history-archive.md` to keep active context under the 15 KB limit.

### 2026-05-22T01:45:35-07:00 — Dark Mode Color Spec (ive-3)

**Session:** ive-3

- **Deliverable:** `.squad/decisions/inbox/ive-color-spec-dark-mode.md`
- **Scope:** Dark mode color palette for AppTheme (16 tokens)
- **Color space:** sRGB component values in 0–1 decimals
- **Approach:** Keep warm, textile-like character. Backgrounds shift to brown-black, cards lift one step lighter, semantic accents (amber/red) brighten for contrast, texture dots invert to very low-opacity light specks.
- **Asset naming:** Kebab-case prefixed with `app-theme-` for 1:1 mapping to AppTheme token names.
- **Implementation notes:** Use light values as `Any Appearance` entries, dark values as `Dark` entries. Bake texture-dot alpha (0.10) into Color Set. Keep `terracotta` and `mismatchText` numerically identical across appearances.
- **Handed to:** Edison for Assets.xcassets migration.

### 2026-05-22T01:59:32Z — Decisions Merged

All decisions from this session merged to `.squad/decisions.md` (inbox cleared).

