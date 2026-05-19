# Curie — History

## Core Context

- **Project:** A knitting gauge reconciler that converts patterns between stitch/row gauges.
- **Role:** Tester
- **Joined:** 2026-05-19T07:11:08.646Z

## Learnings

- Corrected gauge formulas confirmed by Jacquard craft-truth spec (decisions.md: Summary → The Correct Formulas). Use `your_st / pattern_st` for stitch scale and `pattern_row / your_row` for cm-depth scale in future test cases.
- **Test file location:** `prototype/tests/gauge-math.test.js` — run with `node prototype/tests/gauge-math.test.js`. No external dependencies; Node 18+ stdlib only.
- **Rounding rule for increase rows:** `fmtRows(x) = Math.max(1, Math.round(x))`. JS `Math.round` is half-up: 6.5 → 7, 6.4 → 6. Minimum output is 1 (clamp prevents zero/negative row counts).
- **Spec discrepancies found:** Jacquard's Scenario 5 defines `stitchWidthScale` as `ys/ps` (count multiplier) while Scenario 4 and the code both use `ps/ys` (display width ratio). Scenario 6's Expected tuple lists increase spacing as 10.7 but the formula gives 8. Decision filed at `.squad/decisions/inbox/curie-test-discrepancy.md`.
