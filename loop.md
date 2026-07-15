---
configured: true
interval: 10
timeout: 30
description: "Knitting Gauge Reconciler — iOS app build loop"
---

# Squad Work Loop — Knitting Gauge Reconciler iOS

## Model defaults

Always use `gpt-5.6-sol` for every Squad agent launched by this loop, including Ralph and Scribe.

## Goals (all five must be ✅ to exit)

1. **Working app** — `./app/build.sh test` exits 0, iPhone simulator, zero crashes.
2. **UI/UX approved** — Ive signs off on SwiftUI screens against `prototype/index.html`.
3. **User scenarios captured** — Mendel confirms all 6 Jacquard scenarios (`prototype/tests/gauge-math.test.js`) are covered by tests.
4. **Expert approved** — Jacquard signs off on the JS → Swift math port against `.squad/decisions/decisions.md`.
5. **Code tested and validated** — Curie runs `./app/build.sh test`; all tests pass, zero warnings.

## Each cycle

1. Check `.squad/decisions/inbox/` and `.squad/log/` for open items.
2. Pick the top **runnable domain issue**. Skip trackers and issues labeled `follow-up`; respect dependencies in the issue description. Assign the domain to the right member(s).
3. Use the full 30-minute cycle budget productively:
   - Continue through the issue checklist; do not stop after one subtask, one file, one agent response, or session logging.
   - Run independent domain work in parallel when files do not conflict.
   - End early only when the domain issue is complete, the queue is empty, or progress requires unavailable human input.
   - If the 30-minute limit arrives before completion, preserve the branch and continue the **same domain issue** next cycle.
4. Do not open a merge request until every acceptance criterion for exit and every explicit regression guardrail in the domain issue passes locally. Run `./app/build.sh test`; **a warning = a failure.**
5. Create exactly one merge request for the completed domain issue. Link the issue, list its satisfied exit criteria and guardrails, push the branch, and wait for CI/CD on the exact commit. Do not merge until the pipeline is green and the implementation matches the issue contract.
6. Re-evaluate all five goals.
   - Any goal ❌ or new drift found → **open a GitLab issue** (`gitlab.com/yashasg/knitting-gauge-reconciler`) with member name, goal #, and one-line description. Add to work items. Keep looping.
   - All five ✅ → proceed to final review.

## Domain issue contract

- One domain issue owns one coherent merge request.
- Every issue must include explicit acceptance criteria for exit and runnable regression guardrails.
- Never create a separate issue for a subtask already covered by an open domain issue; rewrite the domain issue description instead.
- Never add issue comments for status or scope changes; rewrite the canonical issue description.
- Final-review issues stay blocked until all runnable domain issues are closed and no domain merge request is open.

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
