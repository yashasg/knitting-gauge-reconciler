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

## 2026-05-20 — swift-metrics scope (issue #9, Lead pass)

**Session:** Cross-cutting Lead scoping of GitLab issue #9 ("swift metrics
capture"), running in parallel with seven domain agents who are each
producing their own scoping note. Output: `.squad/decisions/inbox/tesla-
metrics-scope.md`.

### Learnings — cross-cutting constraint interactions

- **swift-metrics ≠ analytics, but every off-the-shelf *handler* is.**
  The façade (`apple/swift-metrics`) is a vocabulary; the violation of
  §2.3 ("no network, no analytics upload") only happens when you bootstrap
  it with `StatsdMetricsHandler` / a Prometheus push / an OTel exporter /
  any vendor SDK. The doc's §2.3 reads as if the whole package is banned,
  but actually only the *exporters* are. This needs a written
  clarification in §2.13 or §2.3 — otherwise future agents will either
  block the whole feature or worse, casually pull in a vendor SDK and
  argue it was implicitly allowed.

- **§2.2 determinism and metrics genuinely conflict at the call site.**
  Anywhere we wrap a timer around `GaugeMath.compute`, we *must* do it in
  the caller, never inside the math. The framework lets you wrap a closure
  in `Timer.measure { ... }` — that idiom is forbidden inside the math
  layer because it injects a clock read and a callback into a function we
  promise is pure. The §2.2 amendment has to spell this out; "no clock
  reads" already implies it but agents reading swift-metrics docs in
  isolation will miss the connection.

- **DEBUG-only vs env-var gating is not a wash.**
  My initial instinct was `#if DEBUG` because §2.12 reaches for that
  pattern. But DEBUG-only metrics make TestFlight diagnostics impossible
  (TestFlight ships Release configs). Env-var gating preserves the
  ability to enable metrics in a TestFlight build by editing the scheme
  argument, without ever shipping an enabled-by-default release binary
  to the App Store. The cost is one more knob; the benefit is real
  diagnostic capability before issues are user-visible.

- **MetricKit is a separate API contract from swift-metrics.**
  They are routinely conflated in iOS conversations because both deliver
  "metrics," but `MXMetricManager` is push-from-Apple-OS and swift-metrics
  is pull-from-our-instrumentation-points. Mixing them in a single scope
  doubles the design surface and the test surface. I split them: ship the
  façade first, add the MetricKit bridge in a follow-up cycle if Apple's
  payloads actually answer questions we care about.

- **Privacy-card regression risk re-surfaced.**
  Edison removed the "no analytics" card on 2026-05-19 *in anticipation*
  of analytics. We are not shipping analytics. The card removal is now
  technically over-conservative — the app today still collects nothing
  external. Flagged in the scope file as a non-blocking design follow-up
  for Ive; we should not let "analytics is coming" become a self-
  fulfilling prophecy.

### Decisions I anticipate having to record once yashasg approves

- **decisions.md:** "Tesla: swift-metrics posture for offline app (issue #9)"
  — façade-only, NoOp default, `KGR_METRICS_ENABLED=1` opt-in, in-memory
  bounded sink, no exporter ever, MetricKit deferred.
- **docs/swift_coding_standards.md §2.13** (new): Metrics & observability —
  enumerates allowed/forbidden handlers, defines naming budget (≤ 20
  metric names, three roots), forbids metric calls inside `GaugeMath`,
  ties the env-var gate to launch arguments per §2.3 convention.
- **docs/swift_coding_standards.md §2.2 sub-bullet** (amend): explicit
  ban on `import Metrics` and on `MetricsSystem.*` symbol use from
  `GaugeMath.swift` and any file it transitively calls into.
- **docs/swift_coding_standards.md §2.3** (clarify): swift-metrics façade
  with a non-exporting handler is permitted; any exporter (StatsD,
  Prometheus, OTel, Datadog, Sentry, Firebase, Mixpanel, Adjust,
  AppsFlyer) remains forbidden.
- **docs/swift_coding_standards.md §7** (retire): the open question about
  MetricKit-as-analytics is closed by the new §2.13.
- **loop.md:** likely no edit. This is an observability layer, not a goal
  change. Will reconfirm once Hopper/Ada/Edison/Curie return their cycle
  estimates — if it materially changes the work-item list, a new entry
  may be needed.
- **Ownership table addition:** Tesla owns §2.13; Hopper owns the env-var
  plumbing and the release-link assertion; Ada owns the math-layer no-emit
  guard; Edison owns the bootstrap and the call-site instrumentation;
  Curie owns the gate-on/gate-off behavioural tests and the linker-symbol
  assertion.

## 2026-05-20T18:19:39-07:00 — swift-metrics scope synthesis (issue #9)

**Session:** Synthesised the eight parallel scoping notes (Tesla / Ada /
Edison / Curie / Hopper / Ive / Mendel / Jacquard) into a single
ship-ready decision drop at
`.squad/decisions/inbox/tesla-issue9-synthesis.md`, plus a ≤120-line
triage comment on GitLab #9 at
`https://gitlab.com/yashasg/knitting-gauge-reconciler/-/work_items/9#note_3370481646`.

### Learnings — Lead-authority calls I made (and why)

- **Env-var shape: pick Hopper's multi-value over my own binary.**
  I had proposed `KGR_METRICS_ENABLED=1` in the Lead view; Hopper proposed
  `KGR_METRICS_BACKEND` with `noop | inmemory | debug-print`. Switched
  to Hopper's shape because it preserves a distinction the team actually
  needs (silent in-process capture for TestFlight diagnostics vs. console
  echo for local dev) that the binary form collapses. `noop` is the
  explicit "off" state, so a separate master switch is redundant. Single
  knob, three states, default `noop`.
- **DEBUG default `noop`.** Curie's test-isolation rules require it
  (per-test `TestMetrics` injection only works if the global bootstrap
  is silently no-op); Edison's spawn-prompt example used "off in tests";
  silent bootstrap during dev would surprise the team. Edison's "default
  on for dev visibility" alternative loses to test-isolation safety.
- **§2.3 carve-out: build-time SPM is allowed.** §2.3 governs runtime
  behaviour of the shipped iOS binary, not the build toolchain. Wording
  added to the synthesis: *"This rule applies to the runtime behaviour of
  the shipped iOS binary. Build-time toolchain network activity (SPM
  dependency resolution against pinned, `Package.resolved`-committed
  revisions) is out of scope of this rule. The shipped binary must
  perform no network I/O regardless of which SPM dependencies were
  resolved at build time."*
- **Naming budget tightened from ≤20 to ≤15.** Self-override on the
  Lead view's "≤20 distinct metric names" — the synthesis ships with
  exactly 15 names across seven roots (`kgr.compute.*`, `kgr.verdict.*`,
  `kgr.input.*`, `kgr.share.*`, `kgr.help.*`, `kgr.disclosure.*`,
  `kgr.reset.*` plus the one-shot `kgr.session.time_to_first_compute_ms`).
  Tighter cap is cheap to enforce now and keeps the v1 surface auditable.
- **Share-render timing kept in scope** (was an open Q in my Lead view).
  Edison's share-image path is the heaviest on-device operation and the
  most likely UX regression site. Kept as `kgr.share.render_duration_ms`.

### MetricsTestKit fact-check result

Hopper claimed upstream `MetricsTestKit` exists; Curie claimed
swift-metrics does NOT ship a test handler. I fetched
`https://raw.githubusercontent.com/apple/swift-metrics/main/Package.swift`
and confirmed three `.library` products are declared:
`CoreMetrics`, `Metrics`, and **`MetricsTestKit`** (target depends on
`Metrics`). Hopper is correct; Curie's claim is outdated (it may have
been true in an earlier release). Decision: link `MetricsTestKit` to
the unit-test target only; do **not** maintain a local
`TestMetricsFactory`. Saves ~30 lines of code and keeps the test-handler
API consistent with upstream conventions. Curie's `MetricsTests.swift`
will use `MetricsTestKit.TestMetrics`.

### Open questions left for yashasg (5)

1. MetricKit bridge in this cycle, or defer? (Recommend defer.)
2. Diagnostics surface (hidden gesture / debug menu) or strictly
   lldb-only? (Recommend lldb-only for v1.)
3. Confirm category-only verdict counter (no raw drift percent into
   the sink).
4. Save/load instrumentation in v1 or wait? (Recommend wait —
   saved-reconciliations is still a future work item.)
5. Jacquard's saved-rec-context completeness signals — defer to a
   follow-up tied to saved-rec metadata wiring? (Recommend defer.)

All other previously-flagged questions (env-var shape, DEBUG default,
test handler choice, build-time SPM blessing, naming budget,
share-render timing) are Lead-resolved and no longer block yashasg.

### Files touched this session

- `.squad/decisions/inbox/tesla-issue9-synthesis.md` — created
  (the durable decision artefact; Scribe merges to `decisions.md` next).
- `.squad/work/kgr-issue9-comment.md` — created (source of truth for
  the GitLab comment, kept on disk for audit / re-post).
- `.squad/identity/now.md` — focus rewritten to reflect the scoping
  pass landing.
- `.squad/agents/tesla/history.md` — appended this entry.

### Validation

No Swift code changes this cycle; `./app/build.sh test` not re-run
(documentation / decision only). Build/test gate will run as part of
the implementation cycle once yashasg approves.

## 2026-05-20T18:42:54-07:00 — swift-metrics scope V2 (issue #9, independent re-pass)

**Session:** Independent V2 re-pass of the swift-metrics scoping from the Lead/architecture
vantage, requested by yashasg after team default model changed to `claude-sonnet-4.6`.
Output: `.squad/decisions/inbox/tesla-metrics-scope-v2.md`.

### Learnings — V2 observations

- **V1 synthesis file (`tesla-issue9-synthesis.md`) is absent from the inbox.**
  The history.md entry from 2026-05-20T18:19:39-07:00 states the file was created, but it
  is not present in `.squad/decisions/inbox/`. V2 reconstructed V1 consensus from
  `decisions.md` (all 8 agent views are merged there) and from the history.md synthesis
  entries. This is a hygiene gap: synthesis documents should be committed before being
  referenced. Flagging for Scribe: on the next merge pass, confirm whether
  `tesla-issue9-synthesis.md` content exists elsewhere in decisions.md or needs to be
  re-created from history.md.

- **V2 ratifies ~95% of V1 consensus.** The core architecture (façade-only, NoOp default,
  MetricsTestKit in-memory, no exporters, MetricKit deferred, 7 roots, ≤15 signals) is
  sound. The model-change from `claude-opus-4.7-xhigh` to `claude-sonnet-4.6` did not
  produce material quality difference on this scoping task — the V1 reasoning was solid.

- **One substantive V1 divergence: Release-config unlock mechanism.**
  Hopper's V1 view allowed `inmemory` in Release if an unlock env-var was set. V2
  removes this: Release is always `noop`, unconditionally, no unlock. The correct
  pre-production diagnostic path is a TestFlight Debug/QA build, not a "unlock" switch
  in a Release binary. Simpler story, tighter privacy posture, no App Store review risk.

- **Signal-table naming: `kgr.disclosure.*` → `kgr.help.*` (minor).**
  Edison's V1 view used a `kgr.disclosure.*` root for the full-math toggle. V2 collapses
  it into `kgr.help.*` — all help/explanation affordances under one root, seven roots
  total. One root fewer; the signal table is the same 15 entries.

- **V1 naming budget evolution is confirmed:** Tesla V1 Lead started at ≤20 signals /
  3 roots. Synthesis tightened to ≤15 / 7 roots. V2 ratifies the tightened budget.
  The approved 15-signal table (see v2 scope doc §4) is the implementation contract.

- **`Package.resolved` commitment is now a PR gate, not a convention.**
  V1 flagged it as a carve-out; V2 makes it enforceable — missing `Package.resolved`
  in the same PR as a `Package.swift` change is a blocking review comment. Added to
  §2.13 draft language.

- **MetricKit remains deferred and the reasoning is clean.**
  API contract difference (push-from-OS vs pull-from-instrumentation), different payload
  set, and §7 can be closed by §2.13 alone without implementing the subscriber.

### V1→V2 delta summary

| Topic | V1 | V2 | Delta |
|---|---|---|---|
| Env-var shape | `KGR_METRICS_BACKEND` multi-value | Same | Ratified |
| Default | `noop` | Same | Ratified |
| Release unlock | Allowed with unlock env-var (Hopper) | Hard `noop`, no unlock | **Diverged** |
| In-memory backend | MetricsTestKit.TestMetrics | Same | Ratified |
| Naming budget | ≤15 / 7 roots | Same | Ratified |
| `kgr.disclosure` root | Separate root | Merged into `kgr.help` | Minor rename |
| MetricKit | Deferred | Same | Ratified |
| SPM carve-out | §2.3 carve-out | Same | Ratified |
| Math-layer ban | §2.2 amendment | Same | Ratified |
| Diagnostics surface | lldb-only | Same | Ratified |

## Team updates
- 2026-05-20T18:19:39-07:00: swift-metrics scoping round (issue #9) completed. 8-agent parallel pass. Decisions merged to decisions.md (now 98,243 bytes).

## 2026-05-20T18:50:53-07:00 — MetricKit pivot V3 (issue #9, architecture decision)

**Session:** yashasg rejected V1/V2 "vocabulary only" plan (swift-metrics, NoOp default) because it has no real data sink — counters count and nobody learns anything. Decision: drop `apple/swift-metrics` entirely and pivot to Apple's MetricKit framework (`import MetricKit`). Output: `.squad/decisions/inbox/tesla-metrickit-scope.md`.

### Learnings — V3 architecture decision

- **The decisive question for any observability architecture is: "Where does the data go?"**
  swift-metrics V1/V2 had a conceptually clean architecture (façade, pluggable backend, NoOp default) but no real data sink for production. Mendel flagged it independently: in-memory counters that never surface anywhere are not analytics — they're a development tool. MetricKit solves the sink problem at the OS level (App Store Connect Analytics is a real, queryable, developer-accessible destination). The vocabulary-vs-handler question is secondary; the data-sink question is primary. Apply this test to every future observability proposal: *if the user opted in and data flowed, where would it land and who would read it?*

- **§2.3 carve-out reasoning — system-mediated egress is a distinct category from developer-initiated egress.**
  The V1/V2 §2.3 rule conflated "no network" with "no data leaves the device." These are different constraints. MetricKit's upload is initiated by the OS, gated on user opt-in, scheduled by Apple, and delivered to a developer-accessible but Apple-hosted sink. The developer's code never opens a socket. This is architecturally distinct from `URLSession(telemetryEndpoint)`. The carve-out is principled: the test is "does *our code* open the connection?" not "does data ever move?" The distinction matters for future decisions (e.g., push notifications, CloudKit sync — all OS-mediated).

- **Signpost roster rationale — 9 signposts from Edison's 12-event starting list.**
  Three V2 events were dropped or merged for MetricKit:
  (a) `field.edit.debounced` (9 per-field variants) — too noisy for MetricKit's daily aggregation model; MetricKit is not a high-frequency event bus.
  (b) `disclosure.full_math.toggle` — insufficient decision value; a disclosure toggle count would not drive any product investment.
  (c) `verdict.current` gauge — MetricKit has no gauge primitive; interval + event only.
  Two V2 events were merged: `gauge.compute.invocations` absorbed into the `compute` interval signpost (which already provides daily count).
  The outcome signal (`verdict.improved` / `verdict.degraded`) is the highest-value addition — it answers "did the tool actually help knitters converge on a workable gauge?" which is the app's primary purpose.

- **Privacy card decision: YES, it returns with MetricKit-corrected language.**
  Edison removed the card on 2026-05-19 in anticipation of analytics. Under V1/V2 nothing left the device. Under V3, data does leave the device (aggregated, system-mediated, not PII). The brand contract is "local-first, offline, no-upload" — MetricKit upload is real (however small and controlled) and honesty with users is non-negotiable. Silence is a false negative. The disclosure is one sentence and the UX cost is negligible.

- **Reusable pattern written as a skill:** `.squad/skills/data-sink-first/SKILL.md` — the "ask data-sink first" decision heuristic for observability architecture proposals.

## 2026-05-20T19:26:30-07:00 — Standards amendments shipped + GitLab #9 correction (V3 finalization)

**Session:** Applied V3 MetricKit scope amendments to `docs/swift_coding_standards.md` and posted a scope-correction comment on GitLab issue #9.

### Standards amendments applied (final text shipped)

**§2.2 (Determinism in the math layer):** Added enforcement sentence at end of section:
> "The math layer (`GaugeMath.swift`) MUST NOT import `MetricKit`, `os.signpost`, `os`, or any analytics framework. Verdict classification for analytics signposts lives in `GaugeMathMetrics.swift`, called by the view layer after `GaugeMath.compute(...)` returns. This is enforced by `MetricKitSubscriberTests.AC-3` (static file scan) and `AC-4` (runtime recording double)."

**§2.3 (No network / no analytics upload):** Rewrote the carve-out. Removed the old "on-device-only counters … acceptable and must not transmit" placeholder. New language explicitly:
- Permits MetricKit (system-framework, OS-mediated upload, user opt-out via iOS Settings)
- Forbids third-party analytics SDKs by name (Firebase, Amplitude, Mixpanel, Segment, GoogleAnalytics, Sentry)
- Defers developer-owned HTTP endpoint to V2, requires named URL + retention policy as a separate amendment

**§2.12 (Release logging discipline):** Added:
> "`MXMetricManagerSubscriber.didReceive(_:)` handlers that log payload contents (e.g., `jsonRepresentation()` via `print` or `os_log`) MUST be wrapped in `#if DEBUG`. In release builds, `didReceive(_:)` is a no-op — the data still flows to App Store Connect Analytics via Apple's auto-pipeline, but our process never emits the contents."

**§7 (MetricKit — open question → CLOSED):** Replaced open-question bullets with RESOLVED entry:
> "RESOLVED 2026-05-20. MetricKit consumption (via `MXMetricManagerSubscriber` and `MXSignpost(_:)`) is in scope. Re-export of payloads to a developer-owned endpoint is forbidden by default — see §2.3 carve-out. The current roster of `MXSignpost` names (9 total) is documented in `.squad/decisions.md`. Any new signpost name requires a Lead review and an addition to `decisions.md`."

**Deviations from V3 scope doc language:** None — all four sections applied verbatim per task directives. The localisation open question that was the second bullet in §7 is now unhoused; it can be added as §8 in a future amendment if localisation work begins.

### GitLab #9 update

- **New note posted:** `https://gitlab.com/yashasg/knitting-gauge-reconciler/-/work_items/9#note_3370575474` (note ID: **3370575474**)
- **Stale note superseded:** Note 3370481646 (swift-metrics synthesis, 2026-05-20T18:19:39) prepended with `> **SUPERSEDED** — see note 3370575474 (MetricKit pivot, 2026-05-20).` via `glab api PUT`.
- Comment covers: why swift-metrics has no sink, MetricKit as replacement, locked 9-signpost roster, privacy posture, V2 deferrals, files landing in scope, standards amendments summary.

### Files touched this session

- `docs/swift_coding_standards.md` — §2.2, §2.3, §2.12, §7 amended
- `.squad/decisions/inbox/tesla-gitlab-9-comment-DRAFT.md` — comment body (persisted as audit trail; was also posted live)
- `.squad/decisions/inbox/tesla-metrickit-standards-shipped.md` — decision drop for Scribe
- `.squad/agents/tesla/history.md` — this entry appended
---

## 2026-05-20T19:26:30Z — MetricKit V1 shipped (Team session)

MetricKit V1 implementation completed. User directives: (1) MetricKit pivot from swift-metrics (2026-05-20T18:50:53), (2) privacy card stays removed (2026-05-20T19:22:50), (3) 9-signpost roster locked (2026-05-20T19:26:30). Build: 49/49 tests pass (was 25). Session log: .squad/log/2026-05-20T19-26-30Z-metrickit-pivot-shipped.md. Orchestration logs: .squad/orchestration-log/2026-05-21T02-26-30Z-{agent-round}.md.
