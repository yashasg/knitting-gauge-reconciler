# Tesla directive drop — retire prototype-parity heuristic

**Date:** 2026-05-22T19:27:12-07:00
**Requested by:** Tesla (human)
**Status:** Applied directly to charters per Tesla (Lead) charter authority; awaiting Scribe merge into formal decisions if desired.

## Audit summary

- `.squad/agents/squad/charter.md` does not exist.
- No routing/runbook/template entry in `.squad/routing.md`, `.squad/ceremonies.md`, `.squad/templates/routing.md`, or `.squad/templates/ceremonies.md` explicitly institutionalized the retired final-review parallel sweep.
- The recurring `final-review parallel sweep` pattern is retired and should not be reintroduced.

## Charter edits

### `.squad/agents/edison/charter.md`
**Old text**
```md
Before starting work, read `.squad/decisions.md` for team decisions that affect me.
After making a decision others should know, write it to `.squad/decisions/inbox/edison-{brief-slug}.md`.
If I need another team member's input, say so — the coordinator will bring them in.
```

**Replacement text**
```md
Before starting work, read `.squad/decisions.md` for team decisions that affect me. The app is the source of truth. `prototype/` is archival/sketch only — not a UI, hierarchy, copy, or interaction spec.
Drift audits are against `.squad/decisions.md` and Tesla directives, never against the prototype.
After making a decision others should know, write it to `.squad/decisions/inbox/edison-{brief-slug}.md`.
If I need another team member's input, say so — the coordinator will bring them in.
```

### `.squad/agents/ive/charter.md`
**Old text**
```md
Before starting work, read `.squad/decisions.md` for team decisions that affect me. Read Mendel's persona output before designing flows — design without personas is decoration.

After making a decision others should know, write it to `.squad/decisions/inbox/ive-{brief-slug}.md` — the Scribe will merge it.
```

**Replacement text**
```md
Before starting work, read `.squad/decisions.md` for team decisions that affect me. Read Mendel's persona output before designing flows — design without personas is decoration. The app is the source of truth. `prototype/` is archival/sketch only — not a UI, hierarchy, copy, or interaction spec.
Drift audits are against `.squad/decisions.md` and Tesla directives, never against the prototype.

After making a decision others should know, write it to `.squad/decisions/inbox/ive-{brief-slug}.md` — the Scribe will merge it.
```

### `.squad/agents/curie/charter.md`
**Old text**
```md
Before starting work, read `.squad/decisions.md` for team decisions that affect me.
After making a decision others should know, write it to `.squad/decisions/inbox/curie-{brief-slug}.md` — the Scribe will merge it.
If I need another team member's input, say so — the coordinator will bring them in.
```

**Replacement text**
```md
Before starting work, read `.squad/decisions.md` for team decisions that affect me. The app is the source of truth. `prototype/` is archival/sketch only, except for the sanctioned §2.9 use of `prototype/tests/gauge-math.test.js` as a gauge-math test-vector reference.
Drift audits are against `.squad/decisions.md` and Tesla directives, never against the prototype.
After making a decision others should know, write it to `.squad/decisions/inbox/curie-{brief-slug}.md` — the Scribe will merge it.
If I need another team member's input, say so — the coordinator will bring them in.
```

### `.squad/agents/jacquard/charter.md`
**Old text**
```md
Before starting work, read `.squad/decisions.md` for team decisions that affect me. Coordinate with Ada on math fidelity, with Mendel on persona authenticity, with Ive on terminology and copy.

After making a decision others should know, write it to `.squad/decisions/inbox/jacquard-{brief-slug}.md` — the Scribe will merge it.
```

**Replacement text**
```md
Before starting work, read `.squad/decisions.md` for team decisions that affect me. Coordinate with Ada on math fidelity, with Mendel on persona authenticity, with Ive on terminology and copy. The app is the source of truth. `prototype/` is archival/sketch only — not a UI, hierarchy, copy, or interaction spec.
Drift audits are against `.squad/decisions.md` and Tesla directives, never against the prototype.

After making a decision others should know, write it to `.squad/decisions/inbox/jacquard-{brief-slug}.md` — the Scribe will merge it.
```

### `.squad/agents/ralph/charter.md`
**Old text**
```md
Before starting work, read `.squad/decisions.md` for team decisions that affect me.
After making a decision others should know, write it to `.squad/decisions/inbox/ralph-{brief-slug}.md`.
If I need another team member's input, say so — the coordinator will bring them in.
```

**Replacement text**
```md
Before starting work, read `.squad/decisions.md` for team decisions that affect me. The app is the source of truth. `prototype/` is archival/sketch only — not a UI, hierarchy, copy, or interaction spec.
Reject or bounce issues whose rationale is primarily a prototype diff; drift audits are against `.squad/decisions.md` and Tesla directives, never against the prototype.
After making a decision others should know, write it to `.squad/decisions/inbox/ralph-{brief-slug}.md`.
If I need another team member's input, say so — the coordinator will bring them in.
```
