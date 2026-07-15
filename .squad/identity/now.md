---
updated_at: 2026-07-15T14:58:16.016-07:00
focus_area: Issue #59 canonical CI gate; issue #82 blocked revision
active_issues: [59, 82]
---

# What We're Focused On

Issue #59 is the top runnable dependency and is owned by Hopper. It must restore
exact-payload-SHA checkout/assertion and repository-root `./app/build.sh test`
as the canonical remote CI gate.

Issue #82 and MR !47 remain preserved unchanged and blocked on #59 after exact-SHA
remote failures. Shannon is locked out of the revision cycle. Edison owns the
later independent issue #82 revision after #59 is accepted.
