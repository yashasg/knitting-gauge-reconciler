### 2026-05-22T21:30:00-07:00: Edison — VerdictCard main-screen revert

**Requested by:** Tesla (human)

**What:** Removed the `VerdictCard(...)` call site from `app/KnittingGaugeReconciler/ContentView.swift`, completing the rollback of MR !35's always-visible main-screen additions after the earlier hero-tile revert.

**Kept:** `Verdict` math/types/tiering remain intact (`GaugeMathMetrics.swift` including `majorMismatch`, plus ContentView verdict computed properties/signpost logic). `app/KnittingGaugeReconciler/Views/VerdictCard.swift` stays in the codebase.

**Share/export note:** `ShareableView` still compiles after the revert and does not currently instantiate `VerdictCard`; the preserved view file is retained for export-related/future verdict presentation rather than main-screen placement.

**Why:** Tesla rejected the always-visible verdict copy on hierarchy/visual-quality grounds. Do not add prominent cards to `ContentView` without explicit Tesla sign-off.
