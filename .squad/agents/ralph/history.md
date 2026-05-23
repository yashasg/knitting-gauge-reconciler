# Ralph — History

## Core Context

- **Project:** A knitting gauge reconciler that converts patterns between stitch/row gauges.
- **Role:** Work Monitor
- **Joined:** 2026-05-19T07:11:08.647Z

## Learnings

<!-- Append learnings below -->


## [2026-05-19 19:13:04Z] Canonical Xcode Project Path Update

⚠️ **All squad members:** The Xcode project has been renamed to **`app/app.xcodeproj`**. 

- **Previous path:** `app/KnittingGaugeReconciler.xcodeproj`
- **Current path:** `app/app.xcodeproj` (canonical reference)
- **App target & scheme:** `KnittingGaugeReconciler` (unchanged)
- **Build script:** `app/build.sh` updated and validated

Any references to the old project path should be updated. Use `app/app.xcodeproj` going forward.

---

### 2026-05-19 — corrected canonical Xcode project path

Correction to earlier path note: the project bundle must remain `app/KnittingGaugeReconciler.xcodeproj` per the explicit Tesla scaffold priority item. Route future build/project-path work to Hopper with the full project path.

## 2026-05-22T20:37:00-07:00 — Prototype-parity governance purge + auto-merge scope change

**Session:** scribe-orchestration-2026-05-22  

**Context:** Tesla retired the team-wide prototype-parity heuristic (2026-05-22T19:27:12-07:00). Ralph's auto-pickup queue must reject issues whose rationale is primarily a prototype diff. Visible UI changes are excluded from auto-merge; they pause for Tesla sign-off before implementation.

**New scope:** Ralph loop auto-pickup-eligible: backend, tooling, tests, accessibility fixes, warning cleanup, bug fixes that don't change visible layout. Excluded: visible UI/UX changes, hierarchy changes on primary screen, new prominent visual elements. These always wait for Tesla.

**Implication for Ralph:** Issues #44 (hero tiles) and #46 (information hierarchy) are invalidated as work items — they exist only as artifacts of the prototype-parity misframe, not as bugs to fix. Ralph should bounce or close such issues on receipt.

**New regime:** The app is the source of truth. `prototype/` is archival/sketch only, not a reference, spec, or test oracle. Drift audits are against `.squad/decisions.md` and Tesla directives, never against the prototype. Charter updated; see `.squad/agents/ralph/charter.md`.

