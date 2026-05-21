# Tesla — History

## Core Context

- **Project:** A knitting gauge reconciler that converts patterns between stitch/row gauges.
- **Role:** Lead / Architect
- **Joined:** 2026-05-19T07:11:08.646Z

## Learnings

### 2026-05-20T20:38:28-07:00 — Cleanup Round 2026-05-20 (Architecture Oversight)

**Session:** cleanup-round (Edison audit + Edison/Curie implementation, parallel)

**Deferred architectural calls:**
- **D.1 (split GaugeMath file boundaries):** `ResultsExportSummary`, `ResultsShareTextFormatter`, `ResultsExportRowsModel`, `plain()`, `fixed()`, `gaugeStatus()`, `rowStatus()` all in `GaugeMath.swift` (math engine + export-formatting layer). File boundary blurry. Could split into `GaugeExportFormatters.swift` but touches file organization (Hopper + Tesla call). **Deferred. No action this round.**

**4.1 fix (signpost inflation) — vetting:**
- Edison's cached `@State var cachedResult` + `.onChange(of: inputs, initial: true)` for `recomputeResult()`.
- Signpost fires 1× per input change instead of 15-20× per body render.
- **Confirmed:** Matches §2.2 math-boundary (GaugeMath pure, signpost view-layer only).
- **Status:** Approved and shipped.

**Status:** Cleanup round shipped 11 items (8 Edison + 3 Curie). All 49 tests pass, 0 warnings. D.1 pending Tesla call. Next round may invoke Tesla's decision if file architecture needs clarification.

---

## 2026-05-20T19:26:30Z — MetricKit V1 Shipped

MetricKit V1 implementation completed. 9 signpost names locked by user directive. Build: 49/49 tests (was 25). Swift coding standards amended (§2.2/§2.3/§2.12/§7). GitLab #9 updated with scope correction, privacy posture, and deferred items.

---

## Earlier Sessions

(See history-archive.md for full timeline of MetricKit scope design, swift-metrics V2 re-pass, user directives, and prior architecture decisions.)
