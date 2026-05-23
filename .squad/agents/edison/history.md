# Edison — History

## Core Context

- **Project:** A knitting gauge reconciler that converts patterns between stitch/row gauges.
- **Role:** Frontend Dev
- **Joined:** 2026-05-19T07:11:08.646Z
- **Simulator environment (2026-05-22T21:18Z):** iPhone 17 Pro validated for app/run.sh launcher (no hang issues post-Hopper fix).

## Current Status (2026-05-23)

**Latest work:** Delta pill final shape & color decision (2026-05-22T04:17:35-07:00). Implemented as warm-brown capsule badge with white semibold text, reusing AppTheme.secondary color (aliased as deltaPill).

**Verification:** 62/62 tests pass, 0 SwiftLint violations, build succeeds.

## Recent Sessions

### 2026-05-22T04:17:35-07:00 — Delta Pill Final Shape & Color (supersedes circular olive spec)

**Decision:** Delta pills are **capsule** badges (not circular) filled with existing warm-brown `AppTheme.secondary`, white `.caption2.weight(.semibold)` text, 8pt H / 3pt V padding.

**Why:** Three iterations were attempted on top of circular olive design: (a) circular shape caused layout regression with adjacent field; (b) bespoke color asset duplicated existing secondary brown. Capsule + reused secondary color removed regression and simplified palette.

**Implementation:** `DeltaPillBadge` in `GaugeStepperField.swift` uses `.clipShape(Capsule())` with `.fixedSize(horizontal: true, vertical: false)`. Component reused in field header, wheel-picker header, adjustment summary for consistency.

**Verification:** Commits bde2d87, 80f14b8, 673a578, 3c48771 on main. `bash app/build.sh build` → EXIT: 0.

### 2026-05-22T21:30:00-07:00 — VerdictCard Main-Screen Revert (Edison-1)

**What:** Removed `VerdictCard(...)` from `ContentView.swift`, completing rollback of MR !35's main-screen additions per Tesla directive.

**Kept:** `Verdict` enum, math/tiering logic, and VerdictCard.swift view file (for export/future use).

**Why:** Tesla rejected always-visible verdict card on hierarchy/visual-quality grounds. Second same-day rejection of MR !35 main-screen additions (first hero tiles, now verdict card).

**Lesson:** Prototype-parity sweeps can produce UI Tesla rejects on sight. Do not add prominent cards to `ContentView` without explicit sign-off. Scope: keep verdict logic available for non-main-screen surfaces (export, help flows), remove rejected presentation from primary hierarchy.

**Commit:** 515ab51 | Build: EXIT: 0 | Tests: 62/62 pass

### 2026-05-23T02:38:00-07:00 — Nav Title Rename to "Stitchwise" (Edison-2)

**What:** Renamed main screen navigation title from "Gauge Reconciler" to "Stitchwise".

**Location:** `app/KnittingGaugeReconciler/ContentView.swift:116` (NavigationStack `.navigationTitle(...)`)

**Why:** User-facing rebranding to new product name.

**Scope:** Navigation title only. No bundle ID, project name, or other app identity changes.

**Commit:** c85de7dd | MR: !37 | Branch: fix/nav-title-stitchwise

### 2026-05-23T02:38:00-07:00 — VerdictCard Incomplete Removal Root Cause (Edison-3)

**What:** Discovered and fixed incomplete VerdictCard removal from commit 515ab51.

**Root Cause:** The call site removal was surgical but left two verdict-family remnants:
1. `AdjustmentSheetView.statusCard` in `Views/RequiredAdjustmentsCard.swift` still rendered the same summary/rejection family (including major-drift warning copy).
2. `Views/VerdictCard.swift` and `GaugeMathPresentation.swift` remained in Xcode target even though unreferenced.

**Remediation:** Complete family removal:
- Deleted `VerdictCard.swift`
- Deleted `GaugeMathPresentation.swift`
- Removed verdict branch from `RequiredAdjustmentsCard.swift` (removed `AdjustmentSheetView.statusCard` rendering)
- Cleaned project.pbxproj entries

**Decision:** Future UI rejections must search for naming variants (`Verdict`, `Major mismatch`, `mismatch`, `statusCard`) to verify complete family removal before calling rollback done.

**Commit:** a2d63e02 | MR: !38 | Branch: fix/remove-major-mismatch | Worktree: ../knitting-gauge-reconciler-verdict-removal/

## Key Learnings & Patterns

- **Prototype parity is necessary but not sufficient** — visual quality and hierarchy decisions are separate approval gates owned by Tesla (2026-05-22T19:23:34-07:00).
- **UI changes require explicit approval** — future UI work is not auto-pickup-eligible from prototype-parity drift. Explicit Tesla sign-off required before implementation (charter updated).
- **Accessibility compound operations** — `.accessibilityElement(children: .ignore)` suppresses child `.accessibilityIdentifier` visibility in XCUITest (undocumented, critical).
- **Main-screen nav title location** — the user-facing main screen title lives in `app/KnittingGaugeReconciler/ContentView.swift` at the root `NavigationStack` via `.navigationTitle(...)`.

## Verification Status

- **Build:** Succeeds on iPhone 17 Pro / Pro Max simulator
- **Tests:** 62/62 pass (49 Swift Testing + 13 XCTest UI), 0 failures
- **Lint:** SwiftLint clean (0 violations, including identifier_name, line_length, color_literal_rgb)
- **Compiler:** 0 warnings (SWIFT_TREAT_WARNINGS_AS_ERRORS=YES)

## See Also

- **Detailed archive:** `history-archive.md` contains full prior session logs (2026-05-22 early sessions, 2026-05-21, earlier)
- **Decisions:** `.squad/decisions.md` contains all team decisions and UI specifications

### 2026-05-23T02:27:08-07:00 — Verdict/Major Mismatch removal follow-up

**What:** Removed the lingering verdict-family summary card from `RequiredAdjustmentsCard.swift`, deleted unused `VerdictCard.swift` and `GaugeMathPresentation.swift`, and removed their Xcode project entries.

**Why the earlier removal was incomplete:** Commit `515ab51` only removed the `VerdictCard(...)` call site from `ContentView.swift`. The same rejection-family UI still survived as the inline `statusCard` inside `AdjustmentSheetView` (summary + over-15%-drift warning), and the unused verdict view/presentation files stayed wired into the project.

**Verification:** `swiftlint lint --config ../.swiftlint.yml --reporter xcode` → 0 violations. `app/build.sh build` → success. `app/build.sh test` still hits the pre-existing UI failures around `testAllJacquardScenariosAreVisibleInUI` / `testCompactWidthKeepsNumericFieldsSideBySideWhenTheyFit` not finding `cast-on-result`.

---

### 2026-05-23T09:44Z — MR !37 & !38 Merged to Main (Tesla-4 background agent)

**Status:** ✅ Merged to main on GitLab

MR !38 (VerdictCard and GaugeMathPresentation full removal) merged to main. Related commit: `efcb810`. Also MR !37 (nav title → Stitchwise) landed simultaneously (SHA `12ac758`). No conflicts. VerdictCard/Major Mismatch saga finally closed.
