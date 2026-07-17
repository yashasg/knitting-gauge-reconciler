# Tesla — History

## Core Context

- **Project:** Knitting gauge reconciler
- **Role:** Lead / Architect

## Summarized Learnings

_Summarized at 2026-07-15T14:58:16.016-07:00 after crossing the 15,360-byte history threshold._

- Use `app/KnittingGaugeReconciler.xcodeproj` with scheme `KnittingGaugeReconciler`; simulator execution is the acceptance signal.
- Favor the existing calculator workflow over speculative persistence or saved-reconciliation scope unless product requirements explicitly authorize it.
- Keep gauge math pure and telemetry native, privacy-safe, low-cardinality, protocol-seamed, and outside formula boundaries.
- Reconcile product value, platform constraints, privacy, testability, dependency cost, and canonical decisions before authorizing cross-cutting work.
- Git publication requires a clean authorized diff, exact-SHA local evidence, exact-SHA CI, and reviewer gates; issue or MR prose is not substitute evidence.
- Preserve dirty or ambiguous worktrees, stashes, and branches unless independent repository evidence proves them shipped and disposable.

Earlier durable detail is summarized in `history-archive.md`.


## 2026-07-17 Reconciliation Summary

_Summarized at 2026-07-17T01:44:15.855-07:00 after crossing the 15,360-byte history threshold. Detailed prior context is retained in `history-archive.md`._

- Issue contracts and canonical decisions supersede prototypes, stale handoffs, and delayed GitLab metadata.
- Publication requires one coherent issue/MR, eligible ownership, clean authorized scope, independent gates, and green CI for the exact candidate SHA.
- The direct test boundary is fail-closed. Authorized build tooling must select the unit target explicitly, avoid retries/repetition masking, and emit attributable evidence.
- Preserve dirty or divergent worktrees, stashes, branches, and safety refs unless shipment and ownership make cleanup independently provable.
- Concurrent publication races must be reconciled by truthful issue identity rather than duplicate MRs or retroactive shipment claims.
- Issues #103, #104, #106/#108, #109-#112 advanced through reconciliation and publication under these rules.

## Current Handoff

### 2026-07-17T01:44:15.855-07:00 — Issue #114

- Issue #114 and MR !82 are the sole active domain identity at exact head `ffdfa5d26195bae8bbd1c12fc917e0bce3fb520c`, one commit ahead of synchronized `main`/`origin/main` `99f13d0dd0c84281b42a9a5565428b25abed084c`.
- The clean candidate changes one CD workflow file. Hopper owns resumption through the existing issue/MR; no fresh implementation is warranted.
- No exact-head pipeline or commit status existed at this snapshot, so merge remained blocked.
- Static inspection authorized the unit-only `./app/build.sh test` route; no test ran during reconciliation.
- Preserve dirty root coordination records, shipped-but-dirty #109 identity state, blocked divergent #51 state, 34 stashes, 11 safety refs, and closed-unmerged stray branches.
