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

### 2026-07-15T00:51:39.795-07:00 — Issue #65 remains the runnable domain gate

- GitLab issue #65 is open with 0/10 acceptance items complete, no related MR, and no remote issue branch.
- Local `squad/65-harden-form-state` is clean at intake and 2 commits ahead / 0 behind `origin/main`; its diff is coordination state only, with no product implementation.
- No Edison agent remains active, so the prior “running” claim is stale rather than evidence of completion.
- The existing approved contract remains authoritative: Edison owns the five production files first, Curie owns the three test files only after API freeze, then read-only review gates proceed in order.

### 2026-07-15T06:42:38.937-07:00 — Issue #65 stash recovery boundary

- `refs/stash` (`6ae295a`) is based exactly on clean branch HEAD `9dc3492`; its index parent has the same tree as HEAD and its untracked parent is the empty tree. All 13 captured modifications are unstaged.
- The stash is a composite issue snapshot, not coherent Edison-only work: two Squad records, eight production files, and all three Curie test files are mixed together. Applying it wholesale would restore stale coordination claims and bypass the production-before-tests handoff.
- Selective recovery of the eight production paths is mechanically safe only while HEAD remains `9dc3492` and those paths remain clean. Preserve the stash; do not pop or apply it wholesale.
- The source API is not frozen in repository state. Edison must first recover and gate production, remove the wheel initializer's raw `Double`/`Int` reparse in favor of the central validator, and record a source freeze. Curie then owns only the three test files and must add genuine process-interruption and independent-multiple-scene coverage before the full gate.
- GitLab issue #65's canonical description still matches the required contract; no rewrite or status comment is warranted.

### 2026-07-15T07:22:37.572-07:00 — Issue #65 lockout reconciliation

- Curie's rejection predates and mechanically overrides the recovery gate's invalid “Edison resumes” assignment; only reviewer approval of an independent revision can clear Edison's seven-file UI lockout.
- The intake 13-path composite is not stash `6ae295a`: stale Edison/decisions changes are absent, Curie/Tesla histories are present, and eight production/test paths contain later content.
- Hopper is the next eligible owner with the seven UI paths from the rejection gate. Ada's accepted math and Curie's three retained test artifacts are read-only; no stash or working-tree change may be discarded.
- Issue #65 remains the top runnable domain issue with no dependency, remote issue branch, or open MR. The executable local gate and snapshot blob baseline are recorded in `tesla-issue-65-lockout-resolution.md`.

### 2026-07-15T09:08:17-07:00 — Issue #65 approved for publication

- All ten acceptance criteria and all regression guardrails are satisfied locally.
- Ive, Jacquard, and Mendel approved their read-only gates; Curie's isolated canonical run passed 76/76 with no
  retries or warning matches.
- The branch is eligible for its single linked merge request and exact-commit CI gate.

### 2026-07-15T14:58:16.016-07:00 — Issue #82 static reconciliation

- `squad/82-restore-production-scene-persistence` is clean, pushed at exact
  SHA `b22c775`, and limited to the three authorized files.
- The three restored files and unchanged `GaugeMath.swift` exactly match all
  four issue-approved blob revisions.
- MR !47 is the only MR for the branch and is domain-coherent, but its 77/77
  claim has no recorded Curie exact-SHA gate and it has no pipeline.
- Verdict: READY-BUT-BLOCKED-ON-CURIE. Issue #82 was corrected in place; all
  acceptance and reviewer checkboxes remain open pending Curie's exact gate.
