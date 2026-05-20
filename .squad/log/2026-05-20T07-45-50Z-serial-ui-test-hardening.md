# iOS work loop — serial UI test hardening

**Status:** local pass; GitLab gate pending

## Work item

Curie hardened the iOS UI tests under the single-simulator constraint. Tests now launch each Jacquard scenario independently with environment-seeded inputs, avoid parallel UI runners, use deterministic dynamic type, and rely on coordinate scrolling/tapping where simulator hit-testing is flaky.

## Validation

- `node prototype/tests/gauge-math.test.js` → 77 passed, 0 failed, 0 pending.
- `./app/build.sh test` → exit 0 on the iPhone simulator with warnings-as-errors enabled.
- `app/build.sh` serial UI-test flag remains `-parallel-testing-enabled NO`.

## Goal check

1. Working app: ✅ local iPhone simulator gate passes.
2. UI/UX approved: ✅ existing Ive-approved surface unchanged; this cycle only hardens test access hooks and launch state.
3. User scenarios captured: ✅ all 6 Jacquard scenarios are covered in unit and UI tests.
4. Expert approved: ✅ formula behavior remains aligned with Jacquard decisions.
5. Code tested and validated: ✅ local Curie gate passes with zero compiler-warning failures.

## External gate

Feature branch must still pass GitLab CI/CD before merge into `main`.
