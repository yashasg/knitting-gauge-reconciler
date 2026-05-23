# Jacquard — History

## Core Context

- **Project:** A knitting gauge reconciler that converts patterns between stitch/row gauges.
- **Role:** Domain Expert (Knitting Mathematics)
- **Joined:** 2026-05-19T07:11:08.646Z

## Learnings

### 2026-05-20T20:38:28-07:00 — Cleanup Round 2026-05-20

**Session:** cleanup-round (Edison audit + Edison/Curie implementation, parallel)

**Items affecting Jacquard domain:**
- **8.2 (defaultLaunchEnvironment dedupe in UI tests):** Tests using KGR_CAST_ON feature flags migrated to dedup pattern. Canonical values preserved; tests still hit 3% rounding drift threshold gate correctly. No change to threshold logic or signpost #9 (`cast_on.driftBandShown`).

**Status:** Cleanup round shipped 11 items (8 Edison + 3 Curie). All 49 tests pass, 0 warnings. Jacquard's domain untouched. Mendel/Jacquard threshold review still optional follow-up (deferred from earlier sessions).

---

## 2026-05-20T19:26:30Z — MetricKit V1 Shipped

MetricKit V1 implementation completed. Signpost #9 (`cast_on.driftBandShown`) gates on Jacquard's 3% threshold. Build: 49/49 tests pass.

---

## Earlier Sessions

(See history-archive.md for full timeline of cast_on rounding drift threshold evaluation, Scenario 6 divergence investigation, and prior domain math reviews.)

## 2026-05-22T20:37:00-07:00 — Prototype-parity governance purge + scenario-coverage standard update

**Session:** scribe-orchestration-2026-05-22  

**Context:** Tesla retired the team-wide prototype-parity heuristic (2026-05-22T19:27:12-07:00). Follow-up directive 2026-05-22T19:39:36-07:00 re-anchors all scenario-coverage standards to **Jacquard-defined craft scenarios** sourced from Jacquard's charter and `.squad/decisions.md`, not from `prototype/tests/gauge-math.test.js`.

**Implication for Jacquard:** Scenario definitions remain the canonical source for test vector coverage across Curie and the Swift test suite. Jacquard's domain knowledge (knitting craft, gauge math, edge cases) drives the scenarios. The prototype is no longer consulted for scenario authority.

**New regime:** The app is the source of truth. `prototype/` is archival/sketch only, not a reference, spec, or test oracle. Drift audits are against `.squad/decisions.md` and Tesla directives, never against the prototype. Charter updated; see `.squad/agents/jacquard/charter.md`.

