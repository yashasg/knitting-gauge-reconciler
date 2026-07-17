---
updated_at: 2026-07-16T16:32:43.998-07:00
focus_area: Resume and ship issue #51 canonical serial UI test gate
active_issues: [51]
---

# What We're Focused On

Issue #51 remains the sole runnable domain issue. Resume Hopper's isolated
worktree on `squad/51-restore-canonical-serial-ui-test-gate`; MR !66 exists at
`ea7ca64`, but its exact-SHA Build & Test status is failed and three later files
remain modified locally. The commit is Tesla-authored despite Tesla's lockout,
so preserve it and require eligible Hopper revision plus Curie's independent
gate.

Fresh work is forbidden. Goals #1, #3, and #5 still require the exact-current
85-test gate, Curie approval, green pipeline, merge, and safe cleanup. All other
open items are the #1 tracker or `follow-up` issues; preserve ambiguous local
state.
