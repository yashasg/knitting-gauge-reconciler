## 2026-05-22T03:48:45-07:00 — Edison: Delta pill mismatch indicator

- **Date:** 2026-05-22T03:48:45-07:00
- **Author:** Edison
- **Area:** SwiftUI / gauge input affordances

**Decision:** Replace the inline `mismatch` capsule beside `Stitches` and `Rows` with a signed numeric delta pill that shows `patternValue - userValue` (for example `+2` or `-2`).

**Why:** The numeric delta communicates the exact gauge difference at a glance while preserving the compact, non-growing inline treatment the user already approved.

**Implementation notes:** Keep the existing capsule styling (`.caption2.weight(.semibold)`, cream text, mismatch-red background, 8pt horizontal / 3pt vertical padding, `Capsule()` clipping). Only render the pill when the values differ. Continue exposing the full mismatch sentence through accessibility and the wheel-sheet warning summary; only the visual pill text changes.

**Verification:** `cd app && bash build.sh build 2>&1; echo "EXIT: $?"` → `EXIT: 0`
