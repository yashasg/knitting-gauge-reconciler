---
configured: true
interval: 10
timeout: 30
description: "Knitting Gauge Reconciler — iOS app build loop"
---

# Squad Work Loop — Knitting Gauge Reconciler iOS

## Test scope authority (fail closed)

- Only a direct user directive may enable or disable a test suite or determine the mandatory test inventory.
- Agent charters, reviewer verdicts or rejections, issue or merge-request rewrites, general authorization to run the loop, final-review goals, and inferred coverage requirements may never expand or override user-set test scope.
- UI tests and XCUITests remain disabled. Clearing the implementation queue is necessary but is not approval; re-enabling them requires a newer explicit user approval even when the queue is empty.
- Before assigning or running test work, read the active user-owned test-scope decision in full. If it is absent, unreadable, truncated, conflicting, or ambiguous, stop, fail closed, and ask the user. Never run tests outside the last explicit scope.
- Reviewers may report an out-of-scope coverage gap as advisory, but may not activate or rewrite issues, alter labels, re-enable targets, reject an authorized artifact, or invoke reviewer lockout to expand test scope.

## Model defaults

Always use `gpt-5.6-sol` for every Squad agent launched by this loop, including Ralph and Scribe.

## Goals (all five must be ✅ to exit)

1. **Working app** — `./app/build.sh test` exits 0, iPhone simulator, zero crashes.
2. **UI/UX approved** — Ive signs off on SwiftUI screens against `prototype/index.html`.
3. **User scenarios captured** — Mendel confirms all 6 Jacquard scenarios (`prototype/tests/gauge-math.test.js`) are covered by tests.
4. **Expert approved** — Jacquard signs off on the JS → Swift math port against `.squad/decisions/decisions.md`.
5. **Code tested and validated** — Curie runs `./app/build.sh test`; all tests pass, zero warnings.

## Each cycle

1. **Reconcile unfinished work before selecting anything fresh.** Inspect the current branch, `git worktree list`, stray local branches with no worktree, `git stash list` and any other loop-preserved saved state, plus the corresponding GitLab issue and merge request state. Resume real unfinished, unshipped work. Discard a stale worktree, branch, stash, or saved state only when GitLab confirms its issue or merge request already shipped. For each GitLab-confirmed stale worktree/branch (issue closed or MR merged), run `git worktree remove --force <path>`, `git branch -D <branch>`, and `git worktree prune`. Never delete an active or unshipped worktree; if GitLab state is ambiguous, preserve it and report it. Never dispatch a new implementation while unfinished work for the same issue exists.
2. **Finish any merge request that is already ready.** Check all open merge requests, including those found in step 1. If one has a green pipeline for its exact current commit and no unresolved blocker, merge it and complete step 9 cleanup before starting new work.
3. Check `.squad/decisions/inbox/` and `.squad/log/` for open items.
4. Only after steps 1–3 leave nothing to resume or merge, pick the top **runnable domain issue**. Skip trackers and issues labeled `follow-up`; respect dependencies in the issue description. Assign the domain to the right member(s).
5. Work on a feature branch and use the full 30-minute cycle budget productively:
   - Continue through the issue checklist; do not stop after one subtask, one file, one agent response, or session logging.
   - Run independent domain work in parallel when files do not conflict.
   - Parallel helpers are allowed only while the coordinator remains active to collect and integrate their results. Required implementation or review work may not be abandoned in the background at cycle end.
   - End early only when the domain issue is complete, the queue is empty, or progress requires unavailable human input.
   - If the 30-minute limit arrives before completion, preserve the branch and continue the **same domain issue** next cycle.
6. Complete every acceptance criterion for exit and explicit regression guardrail in the domain issue, then run `./app/build.sh test`; **a warning = a failure.** Fix failures before publishing.
7. Commit the coherent domain-issue change, push its feature branch, and create exactly one merge request. Link the issue and list its satisfied exit criteria and guardrails.
8. Record the pushed commit SHA and wait for that exact SHA's CI/CD pipeline to turn green. Confirm the merge request still matches the issue contract and has no unresolved blockers, then merge it.
9. After merge, verify the issue worktree is clean, remove it, delete the merged local branch, remove only that shipped issue's obsolete loop-preserved saved state, and run `git worktree prune`. If anything is dirty or cannot be attributed safely, preserve it and report it instead of deleting it.
10. Re-evaluate all five goals.
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
