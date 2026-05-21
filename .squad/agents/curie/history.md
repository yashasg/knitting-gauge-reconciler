# Curie — History

## Core Context

- **Project:** A knitting gauge reconciler that converts patterns between stitch/row gauges.
- **Role:** Tester
- **Joined:** 2026-05-19T07:11:08.646Z

## Learnings

### 2026-05-20T20:38:28-07:00 — Cleanup Round 2026-05-20

**Session:** cleanup-round (Edison audit + Edison/Curie implementation, parallel)

**3 items shipped (all test-file improvements):**
- **7.1:** MockMetricPayload.jsonRepresentation() removed (not protocol-required). All AC tests pass.
- **8.1:** scrollToTop(in:) dead UI test helper deleted.
- **8.2:** defaultLaunchEnvironment dedupe. Extracted to `private static let defaultLaunchEnvironment: [String: String]` with 7 canonical keys. All 7 tests use `.merging({ _, new in new })` for overrides. **Key pattern:** Static required (not let) for @MainActor XCTestCase methods. Eliminates silent divergence risk.

**Test count:** 49/49 before and after (no @Test methods deleted).

**Build:** exit 0, ** TEST SUCCEEDED **, 0 warnings, 49/49 tests pass.

---

## 2026-05-20T19:26:30Z — MetricKit V1 Shipped

24 new tests in MetricKitSubscriberTests.swift across 4 suites (AC-1..AC-8, all PASS). Test count: 18 unit → 42 unit (+24). 7 UI unchanged. Total: 49 tests.

---

## Earlier Sessions

(See history-archive.md for full timeline of 2026-05-19 and earlier 2026-05-20 work, including edge case tests, float precision, UI test runner blockers, and build.sh validation.)
