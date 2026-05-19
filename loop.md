---
configured: true
interval: 1
timeout: 30
description: "Knitting Gauge Reconciler — iOS app build loop"
---

# Squad Work Loop — Knitting Gauge Reconciler iOS

## Goals (all five must be ✅ to exit)

1. **Working app** — `./app/build.sh test` exits 0, iPhone simulator, zero crashes.
2. **UI/UX approved** — Ive signs off on SwiftUI screens against `prototype/index.html`.
3. **User scenarios captured** — Mendel confirms all 6 Jacquard scenarios (`prototype/tests/gauge-math.test.js`) are covered by tests.
4. **Expert approved** — Jacquard signs off on the JS → Swift math port against `.squad/decisions/decisions.md`.
5. **Code tested and validated** — Curie runs `./app/build.sh test`; all tests pass, zero warnings.

## Each cycle

1. Check `.squad/decisions/inbox/` and `.squad/log/` for open items.
2. Pick the top open work item; assign to the right member (see roster below).
3. Make the change on a feature branch, then run `./app/build.sh test`. **A warning = a failure. Fix before moving on.**
4. Once the feature is complete and tests pass locally, push the branch and wait for CI/CD to pass on GitLab. Do not merge until the pipeline is green. Then merge the branch into `main`.
5. Re-evaluate all five goals.
   - Any goal ❌ or new drift found → **open a GitLab issue** (`gitlab.com/yashasg/knitting-gauge-reconciler`) with member name, goal #, and one-line description. Add to work items. Keep looping.
   - All five ✅ → proceed to final review.

## Roster

| Member | Owns |
|--------|------|
| **Tesla** | Lead, blockers, handoffs |
| **Hopper** | `app/build.sh` — build/test/release modes, `-warnings-as-errors` |
| **Ada** | `GaugeMath.swift` — port of `computeGaugeMath`, `fmtCm`, `fmtRows`, `fmtPct`, `computeActStitches` |
| **Edison** | SwiftUI views — `ContentView.swift`, live recalc, hero numbers, adjustment table |
| **Curie** | All tests — unit + UI; runs `./app/build.sh test` |
| **Ive** | UX review against prototype |
| **Mendel** | Maps user scenarios to test cases |
| **Jacquard** | Gauge math domain review |

## Work items (priority order)

1. **Hopper** — Write `app/build.sh` (build/test/release, `-warnings-as-errors`, xcpretty).
2. **Tesla** — Scaffold `app/KnittingGaugeReconciler.xcodeproj` (SwiftUI + Swift Testing targets).
3. **Ada** — Port gauge math JS → `GaugeMath.swift`.
4. **Curie** — Write Swift unit tests for all 6 scenarios + edge cases.
5. **Edison** — Build `ContentView.swift` (4 inputs, live recalc, hero %s, table).
6. **Ive** — Review ContentView; approve or file UX issues.
7. **Mendel** — Map all 6 scenarios to UI-level tests.
8. **Jacquard** — Sign off on `GaugeMath.swift` formula correctness.
9. **Curie** — Final test run: `./app/build.sh test` green, zero warnings.
10. **Tesla** — Confirm all 5 goals ✅; trigger final review.

## Final review (parallel — only when work items are empty)

All members review simultaneously against their area. Any new issue or drift found → **open a GitLab issue** and resume looping. All pass → log in `.squad/log/`, hand off to yashasg.
