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

## 2026-07-15T09:08:17-07:00 — Issue #65 math approval

- Approved the central finite/range validator, stitch-width and cast-on reciprocals, row/dimension scales,
  canonical-centimetre section math, established rounding, and omission of absent optional values.
- All six scenario vectors match the formula authority in `.squad/decisions.md`.

## 2026-07-16T10:52:38.873-07:00 — Goal #4 JS-to-Swift re-verification

- Re-approved the current Swift port against the authorized prototype vectors and decision ledger after
  whole-number validation was added for cast-on and shaping intervals.
- Physically actionable outputs are discrete: cast-on and section guidance are whole stitches/rows;
  shaping rounds half-up to at least one row, and copy warns knitters to reconcile cast-on with pattern repeats.
- Canonical centimetres remain the arithmetic model; inch entry/display uses exact `2.54` conversion with
  intentional whole-unit UI rounding. All six scenario vectors, status wording, and reciprocal directions agree.

## 2026-07-17T15:24:25.888-07:00 — Goal #4 final domain signoff

- Approved HEAD `57ce2b2050399df7bb3513251ec4cfd960192662` by static review.
- All six canonical outcomes, reciprocal gauge directions, half-up whole-stitch/row presentation, exact
  `2.54` inch storage, optional absence, and the nonpositive cast-on guard remain contract-correct.

## 2026-07-17T16:44:38.371-07:00 — Fresh final formula/craft signoff

- **APPROVE** local HEAD `f7c305ca22f6d9178e99fe2f07a2f031c19fe746`; `origin/main`
  is `8d883d2b15fdfe224b3b2fef6ad20acb9e6412f9`, and their app/prototype trees are identical.
- Static review reconfirmed canonical reciprocal directions, percentage meaning, half-up whole
  stitch/row outcomes, pattern-repeat reconciliation, exact `2.54` conversion, and canonical-cm arithmetic.
- Exactly six prototype scenarios map one-to-one to the six named authorized Swift unit scenarios.
  No build or test command was run; no current craft/formula gap was found.

## 2026-07-17T16:55:05.482-07:00 — Simultaneous final knitting-domain review

- **PASS / APPROVE** at local HEAD `f7c305ca22f6d9178e99fe2f07a2f031c19fe746`; the reviewed
  `app/` and canonical scenario artifacts are unchanged from shipped `origin/main`.
- Formula direction, half-up whole-stitch/row rounding, canonical-centimetre arithmetic, exact
  `2.54` inch conversion, unit terminology, optional absence, and practical pattern-repeat guidance pass.
- All six canonical vectors and their displayed whole outcomes map directly to the six named Swift unit cases.
  Goals 1–5 retain PASS evidence; no test or build command was run and no craft gap was found.

## 2026-07-17T17:14:23.945-07:00 — Final independent JS-to-Swift domain review

- **APPROVE** local HEAD `f7c305ca22f6d9178e99fe2f07a2f031c19fe746` by static review.
- Stitch/cast-on reciprocals, row/dimension reciprocals, shaping, section-row preservation, percentages,
  half-up whole-stitch/row presentation, validation/absence, zero-cast-on omission, and exact `2.54` units agree.
- All six realistic scenarios produce the canonical lengths, intervals, percentages, and cast-ons; no test or
  build command was run and no high-confidence knitting-domain blocker was found.
