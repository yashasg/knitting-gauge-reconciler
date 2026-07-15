# Ive — History

## Core Context

- **Owner:** yashasg
- **Project:** A knitting gauge reconciler that converts patterns between stitch/row gauges.
- **Role:** UI/UX Designer (Apple HIG, accessibility)
- **Joined:** 2026-05-19T07:14:05Z

## Archived Summary

- **2026-05-19 foundation:** Locked the core UI principles — one screen / one press, verdict-first hierarchy, text-before-color semantics, and Dynamic Type-safe typography. Approved compact field sizing, strong verdict contrast, and visible text labels on every semantic pill.
- **Prototype → SwiftUI parity review:** Signed off the iOS app once verdict-state logic, pill contrast, and concise axis-specific copy matched the prototype and accessibility floor.
- **Copy / platform guidance:** Confirmed the canonical Xcode project path remains `app/KnittingGaugeReconciler.xcodeproj`; approved the native Copy Results menu; rejected any user-visible metrics UI for MetricKit/swift-metrics work in v1.
- **See archive:** `history-archive.md` contains the detailed 2026-05-19 through 2026-05-21 log.

## Current Learnings

- 2026-06-03T01:47:58Z: **Research validated elastic-layout decision with Apple WWDC citations.** Ive researched Dynamic Type solutions per Yashas's accessibility gate. Findings confirm the elastic-layout principle is WWDC-sanctioned: WWDC 2020:10020 ("avoid truncating text... wrap labels and use full width"), WWDC 2022:10056 (ViewThatFits/AnyLayout), WWDC 2019:261 (Large Content Viewer only for non-scalable chrome, not content badges). Solution ranking: 1) ViewThatFits (primary), 2) AnyLayout+dynamicTypeSize, 3) Large Content Viewer (chrome/accessibility chrome only), 4) FlowLayout, 5) structural relocation. No code changes. Research-backed decision ready for implementation when Yashas approves.

- 2026-06-02T18:32:46-07:00: **IMPLEMENTED — Elastic Layout shipped in MR !43.** Edison successfully implemented the ViewThatFits elastic-layout pattern per Ive's specification. All `.dynamicTypeSize(...accessibility1)` caps removed; ViewThatFits reflow added to GaugeInputGroup header and GaugeStepperField title row. Delta-pill fallback added (needed the VStack backup as Ive anticipated); drift-pill has no fallback (ZStack overlay absorbs sizes gracefully per SKILL.md Value Tile with Badge Overlay pattern). Build exit 0, unit tests 49/49 pass. Four UI-test pre-existing failures flagged (iOS 26 infra flake, contrast audit, unit-toggle regression) — pending Yashas confirmation. Spec decision archived: `.squad/decisions.md` § `ive/dynamic-type-elastic-layout`.

- 2026-06-02T18:27:43-07:00: **SUPERSEDED — minimumScaleFactor should be removed, not tokenized.** The concern conflates two issues: (1) `.dynamicTypeSize(...accessibility1)` caps maximum growth, (2) `.minimumScaleFactor(0.7)` allows shrinkage *only when layout pressure forces it*. The cap is the accessibility constraint; the scale factor is a layout pressure-relief valve. On decorative `.accessibilityHidden(true)` elements, shrinking visual text does not harm VoiceOver users (they don't see it) but does prevent layout overflow for sighted large-text users. The combination is correct for this use case. 0.7 is not magic — it's the HIG-adjacent "shrink no more than 30%" heuristic common in Apple templates. Should be tokenized as `AppTheme.minimumScaleFactor` for consistency.

- 2026-06-02T18:32:46-07:00: **SUPERSEDED — Elastic Layout is the correct answer.** The prior "hide at accessibility sizes + minimumScaleFactor as pressure valve" approach was a compromise. Yashas correctly pushed back: we should have ZERO accessibility exceptions. The correct principle is: **text always renders at the user's exact chosen Dynamic Type size; the LAYOUT absorbs overflow by reflowing.** No `.minimumScaleFactor` (no shrinking), no `.dynamicTypeSize` cap (no clamping), no conditional hiding. Use `ViewThatFits` (iOS 16+, we target iOS 17) to provide side-by-side when it fits, stacked when it doesn't. Cards grow taller at large sizes — that's correct behavior. Decorative pills remain `.accessibilityHidden(true)` (info is duplicated in adjacent labels). New spec: `.squad/decisions/inbox/ive-dynamic-type-elastic-layout.md`. Updated skill: `.squad/skills/dynamic-type-reflow/SKILL.md`.

- 2026-05-22T21:30:00-07:00: **Main screen is task-execution surface, not analysis display.** The VerdictCard rejection (2 hours after hero-tile rejection, same pattern) exposed that the prior heuristic—"ask 'why does the user encounter this at this moment?'"—was insufficient. The real rule is: inputs and adjustments belong on the main screen; diagnostic copy, verdicts, and percentages do not. Both hero tiles and VerdictCard are analysis/diagnosis, even though one shows raw numbers and the other shows narrative interpretation. The distinction "raw vs. interpretive" is orthogonal to the real division: "actionable for this task vs. judgment about task state." Verdict enum, `verdictTitle()`, `verdictBody()` stay in codebase for use in ShareableView export and accessibility labels, but the verdict card itself is off the main screen. Postmortem: `.squad/decisions/inbox/ive-verdictcard-postmortem.md`.
- 2026-05-22T19:23:34-07:00: **Prototype parity is not a design end state.** Achieving structural alignment with a web prototype must be validated against platform conventions (iOS HIG single-screen utilities do not lead with diagnostic detail), domain mental models (knitters think in actions, not percentages), real-estate tradeoffs (mobile vertical pressure), and information-hierarchy first principles (actionable instruction before diagnostic precision). "Because the prototype did it" is not a sufficient design rationale. Future prototype-parity work requires a gut-check gate: *"Why does the user encounter this at this moment?"* If the answer is "so I can show the user this number," the design is information-architecture-first rather than user-task-first. Postmortem: `.squad/decisions/inbox/ive-hero-tile-postmortem.md`.
- 2026-05-21T12:41:13-07:00: The gauge-field mismatch fix must not consume extra vertical space. Preferred pattern: keep equal-width paired fields, carry warning state inside existing field chrome, and move the full mismatch sentence to accessibility payloads / the picker surface.
- 2026-05-21T19:42:31-07:00: Moving Required Adjustment details into a native sheet is HIG-aligned when the sheet uses native detents, a visible Close button, a state-aware title, and a scrollable body that remains accessible at large text sizes.
- 2026-05-21T20:30:12-07:00: Apple's single-screen utility apps (Calculator, Compass, Stopwatch, Measure) do not display the app name as a heading — the function is self-evident. For this app, the HIG-aligned choice is to remove the `.largeTitle` "Gauge Reconciler" header entirely, letting the content cards serve as the hero. The info button stays; the title goes. Spec delivered to `.squad/decisions/inbox/ive-app-title-hig-spec.md`.
- 2026-05-22T01:45:35-07:00: This palette's dark mode should stay warm and textile-like: backgrounds shift to brown-black, cards lift one step lighter, semantic amber/red accents brighten for contrast, and texture dots must invert to a very low-opacity light speck instead of a dark one. Spec delivered to `.squad/decisions/inbox/ive-color-spec-dark-mode.md`.

## Team Updates

- 2026-05-22T21:30:00-07:00: **Second Tesla rejection (VerdictCard).** Same day as hero-tile revert; same design error. Postmortem exposed flaw in initial heuristic—"ask why the user encounters this?"—was insufficient. Real rule: inputs + adjustments on main screen; diagnostic judgments off. Verdict enum + logic preserved for export/AX. Postmortem delivered; charter updated.
- 2026-05-22T02:50:32Z: The user directive for this session superseded Ive's mismatch-only auto-present, persistent inline summary, and cached reopen conditions. Shipped behavior is deterministic: `View Adjustments` always opens the sheet and recomputes on every tap.
- 2026-05-22T02:50:32Z: Detailed pre-summary history moved to `history-archive.md` to keep active context under the 15 KB limit.

### 2026-05-22T01:45:35-07:00 — Dark Mode Color Spec (ive-3)

**Session:** ive-3

- **Deliverable:** `.squad/decisions/inbox/ive-color-spec-dark-mode.md`
- **Scope:** Dark mode color palette for AppTheme (16 tokens)
- **Color space:** sRGB component values in 0–1 decimals
- **Approach:** Keep warm, textile-like character. Backgrounds shift to brown-black, cards lift one step lighter, semantic accents (amber/red) brighten for contrast, texture dots invert to very low-opacity light specks.
- **Asset naming:** Kebab-case prefixed with `app-theme-` for 1:1 mapping to AppTheme token names.
- **Implementation notes:** Use light values as `Any Appearance` entries, dark values as `Dark` entries. Bake texture-dot alpha (0.10) into Color Set. Keep `terracotta` and `mismatchText` numerically identical across appearances.
- **Handed to:** Edison for Assets.xcassets migration.

### 2026-05-22T01:59:32Z — Decisions Merged

All decisions from this session merged to `.squad/decisions.md` (inbox cleared).


## 2026-05-22T20:37:00-07:00 — Hero tiles postmortem + prototype-parity governance purge

**Session:** scribe-orchestration-2026-05-22  

**Context:** Hero tiles removed from main UI per Tesla directive (2026-05-22T19:23:34-07:00). Authored design postmortem analyzing the information-order rationale from the prototype, the platform-specific constraints that predict Tesla's rejection, and the signals that should have triggered a design review before implementation. Postmortem documents the shift from prototype-parity thinking to first-principles iOS HIG thinking.

**New regime:** The app is the source of truth. `prototype/` is archival/sketch only, not a UI, hierarchy, copy, or interaction spec. Drift audits are against `.squad/decisions.md` and Tesla directives, never against the prototype. Charter updated; see `.squad/agents/ive/charter.md`.

**Key learning:** Future design work must validate prototype-parity alignment against platform conventions (iOS HIG single-screen utilities do not lead with diagnostic detail), domain mental models (knitters think in actions, not percentages), real-estate tradeoffs (mobile vertical pressure), and information-hierarchy first principles (actionable instruction before diagnostic precision). The gate is always: "Why does the user encounter this at this moment?" If the answer is "because the prototype put it there," run a design review. If the answer is "the user needs it to make a decision," integrate it into the decision-making flow.

**Decision:** Postmortem and governance directives merged to `.squad/decisions.md` (2026-05-22T19:23:34 through 2026-05-22T19:39:36-07:00).

## 2026-07-15T09:08:17-07:00 — Issue #65 UX approval

- Approved the single required-gauge surface, 24-point pattern/swatch separation, collapsed blank optional details,
  inline correction/focus flow, Reset/Undo discoverability, Dynamic Type reflow, semantic text colors, and VoiceOver
  behavior against the issue contract and the session-authorized prototype comparison.
