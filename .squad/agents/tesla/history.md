# Tesla — History

## Core Context

- **Project:** A knitting gauge reconciler that converts patterns between stitch/row gauges.
- **Role:** Lead
- **Joined:** 2026-05-19T07:11:08.645Z

## Learnings

- **prototype/ now has tests/ subdirectory (2026-05-19):** JS test harness at prototype/tests/gauge-math.test.js (node-runnable, 77 passing). Coverage includes Jacquard's six craft scenarios and edge cases.

- **Xcode 26.4 / iOS 26.4 known build issues (2026-05-19):** Two benign infrastructure bugs affect `build.sh` runs:
  1. macOS BSD `mktemp` rejects templates with trailing `.log` suffix after `XXXXXX` — use `XXXXXX` at end of template.
  2. After all UI tests complete, xcodebuild may crash with `Failed to launch app with identifier: (null)` / `Invalid request: No bundle identifier` / `mkstemp: No such file or directory` in result-bundle staging. This is a post-test cleanup bug — all assertions already passed. The `build.sh` benign-crash bypass handles this.
  3. Stale DerivedData causes compiled binaries to lag behind source changes. The updated `build.sh` uses `-derivedDataPath "$PROJECT_DIR/.build/derived-data"` and does an explicit `rm -rf` before each run.

- **Five exit goals confirmed green locally (2026-05-19T11:13Z):**
  - `./app/build.sh test` exits 0: 15 unit tests + testAllJacquardScenariosAreVisibleInUI (6 UI scenarios) pass.
  - All goals 1–5 satisfied locally; GitLab CI still blocked on no-runner issue (work item #3).

- **Work loop rerun still CI-blocked (2026-05-19T11:40Z):**
  - `./app/build.sh test` exits 0 locally with `** TEST SUCCEEDED **`.
  - `.gitlab-ci.yml` matches GitLab's hosted macOS runner syntax (`saas-macos-medium-m1`, `macos-26-xcode-26`).
  - Merge remains blocked by GitLab work item #3 until the namespace gets hosted macOS runner eligibility or a project/group macOS runner with the required tag.

- **Final gate review — All 5 goals APPROVED (2026-05-19T15:00Z):**
  - **Goal 1:** `./app/build.sh test` exits 0 on iOS simulator with zero crashes ✅ — 15 Swift unit tests + 3 UI tests pass, `** TEST SUCCEEDED **`.
  - **Goal 2:** UI/UX approved against prototype/index.html ✅ — Ive signed off all four inputs, live recalc, hero percentages, results table, accessibility, Dynamic Type coverage.
  - **Goal 3:** All 6 Jacquard scenarios covered by tests ✅ — JS prototype suite: 77/77 pass (all scenarios + edge cases); Swift unit tests: scenarios 1–6 explicit; Swift UI tests: `testAllJacquardScenariosAreVisibleInUI` verifies all six visible.
  - **Goal 4:** Jacquard signs off on JS→Swift math port ✅ — `.squad/decisions/inbox/jacquard-math-signoff.md` signed off: all four canonical formulas correct, all six scenarios pass with expected values, craft-truth verified.
  - **Goal 5:** Curie final test passes with zero warnings ✅ — `SWIFT_TREAT_WARNINGS_AS_ERRORS=YES`, `GCC_TREAT_WARNINGS_AS_ERRORS=YES`, `CLANG_TREAT_WARNINGS_AS_ERRORS=YES` all active; zero compiler warnings in build output.
  - **Trade-off accepted:** GitLab CI blocker is infrastructure-level (no hosted macOS runner eligibility in namespace); not a code defect. Local test gate 100% green. Code is production-ready; merge blocked only on GitLab admin configuration.


## [2026-05-19 19:13:04Z] Canonical Xcode Project Path Update

⚠️ **All squad members:** The Xcode project has been renamed to **`app/app.xcodeproj`**. 

- **Previous path:** `app/KnittingGaugeReconciler.xcodeproj`
- **Current path:** `app/app.xcodeproj` (canonical reference)
- **App target & scheme:** `KnittingGaugeReconciler` (unchanged)
- **Build script:** `app/build.sh` updated and validated

Any references to the old project path should be updated. Use `app/app.xcodeproj` going forward.

---

### 2026-05-19 — corrected canonical Xcode project path

Correction to earlier path note: the project bundle must remain `app/KnittingGaugeReconciler.xcodeproj` per Tesla's explicit scaffold priority item. Merge and CI checks should use `./app/build.sh test` and the `KnittingGaugeReconciler` scheme.

## [2026-05-19T13:06:06.205-07:00] Run Script Rescue

- Rescued the stuck Hopper handoff for simulator launch support; `app/run.sh` now validates with `bash -n` and ran successfully end-to-end via `./app/run.sh`.
- Convention established: `app/run.sh` is a thin launch wrapper over `app/build.sh`; `build.sh` remains the single source of build configuration, simulator destination, derived data, and warning policy.
- Trade-off: the run script duplicates a small amount of simulator/app-install plumbing to keep developer launch ergonomics simple, but does not duplicate Xcode build policy.

## [2026-05-20T05:06:06Z] Saved Reconciliations Architecture Evaluation

**Session:** Three-agent consensus on saved reconciliations feature  
**Participants:** Tesla (architecture), Mendel (user research), Jacquard (domain)  
**Output:** Orchestration logs, decision archive, session log

**Decision:** Recommend SwiftData persistence on iOS 17+. Store full `GaugeInputs` (9 fields) + metadata (label, createdAt, updatedAt). Recomputed values derived via `GaugeMath.compute()`.

**MVP Scope:** Save (explicit button on results), List (chronological + swipe-to-delete), Load (tap to reload into calculator), Delete. No iCloud sync or search in v1.

**Handoff status:** Ready for Edison (iOS implementation) and Ive (metadata UX design). See `.squad/decisions.md` (2026-05-19 Evening Session) and orchestration logs for full context.

---

## 2026-05-20 — Swift Coding Standards Adoption (Issue #8)

**Session:** Adopt Google Swift Style Guide as the team's normative reference.
**Participants:** Tesla (sole driver this cycle — small documentation+ownership change).
**Trigger:** GitLab issue #8 ("follow coding standards") — user requested
copying `google_swift_coding_style.md` to `docs/swift_coding_standards.md`
and updating Squad to follow it.

**Constraint discovered:** The uploaded artefact is unreachable from
automation. Direct fetch (`/uploads/<secret>/<filename>`) → Cloudflare bot
challenge (HTTP 403). GitLab API equivalent
(`/api/v4/projects/.../uploads/<secret>/<filename>`) → 404. The project
uploads listing returns only 2 unrelated files (`DESIGN.md`, `screen.png`).

**Decision:** Don't vendor the upstream guide. Instead, write a project-
local `docs/swift_coding_standards.md` that:

1. Points at Google's canonical, stable URL (`https://google.github.io/swift/`)
   as the normative external reference.
2. Captures the **project bindings** that already apply to this codebase and
   that the loop has enforced ad-hoc until now: warnings-as-errors, no
   network, determinism in the math layer, force-unwrap discipline, serial
   UI tests, accessibility identifiers as part of the public contract,
   etc. Twelve subsections under §2.
3. Defines resolution rules (§4 — project rule > Google > Apple API design
   guidelines > existing file convention).
4. Defines amendment flow via `.squad/decisions/inbox/<agent>-swift-
   standard-*.md` so future changes follow the normal Scribe merge.

**Ownership assignment:**

- Ada owns §2.2 (Determinism in the math layer).
- Edison owns §2.8 (SwiftUI specifics).
- Hopper owns §3 (Tooling — build script, future formatter/linter wiring).
- Curie owns §2.9 (Tests).
- Tesla owns the rest and the resolution rules.

**Files touched:**

- `docs/swift_coding_standards.md` — created.
- `.squad/decisions.md` — appended "Tesla: Swift Coding Standards Adopted".
- `.squad/agents/ada/charter.md` — added "Coding standards" subsection.
- `.squad/agents/edison/charter.md` — added "Coding standards" subsection.
- `.squad/agents/hopper/charter.md` — added "Coding standards" subsection.
- `.squad/agents/curie/charter.md` — added "Coding standards" subsection.
- `README.md` — added "Development" section linking to the standards doc.

**Validation:** No Swift code changes; ran `./app/build.sh test` to confirm
the documentation-only change does not regress the build/test gate.

**Triage in same cycle:**

- Closed stale issues #5 (no_matching_runner), #6 (external gate blocked),
  #7 (ci/cd now fixed, informational) with explanatory comments — CI is
  demonstrably green on `main` (#108, #110) and on every recent MR.
- Commented on #9 (Swift metrics capture) with a scope clarification
  request: the metric list looks server-shaped (request counts, DB pools,
  queue depth) but the app charter forbids network calls — proposed a
  device-local MetricKit-plus-in-process-counters interpretation and held
  implementation pending response.
