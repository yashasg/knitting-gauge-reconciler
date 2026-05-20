# iOS work loop — GitLab gate blocked

**Date:** 2026-05-20T08:11:48Z  
**Owner:** Tesla / Curie  
**Status:** Local gates green; GitLab gate blocked

## Work item

Top open item remains the remote merge gate for `squad/curie-serial-ui-test-hardening`.

## Local validation

- `node prototype/tests/gauge-math.test.js` exited 0 with 77 passed, 0 failed, 0 pending.
- `./app/build.sh test` exited 0 on the iPhone simulator with warnings-as-errors enabled and serial UI testing (`-parallel-testing-enabled NO`).
- `git push origin HEAD:squad/curie-serial-ui-test-hardening` reported `Everything up-to-date`.

## External gate

- Remote branch existed at `a6c08c023fbdfa1c5796be2342c47e8c8922b76c` before this log commit was added and pushed.
- Remote `main` exists at `4f3cfdfbfd92f3e66347e0e61ddf13e5f5938f9f`.
- `GITLAB_TOKEN` is not present in this environment.
- GitLab project, merge request, and pipeline API calls for `yashasg/knitting-gauge-reconciler` return `404 Project Not Found`, including when retried with the available git credential.

Do not merge into `main` until GitLab API/project access is restored and the branch pipeline is confirmed green.

## Goal status

1. **Working app:** ✅ Local `./app/build.sh test` exits 0 on iPhone simulator.
2. **UI/UX approved:** ✅ Existing Ive-approved UI surface unchanged in this cycle.
3. **User scenarios captured:** ✅ Six Jacquard scenarios remain covered by prototype, Swift unit, and UI tests.
4. **Expert approved:** ✅ Swift math remains aligned with Jacquard decisions.
5. **Code tested and validated:** ✅ Curie's local warning-as-error gate is green.
