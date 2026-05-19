# Session Log: Design & Research Round 3 (2026-05-19)

**Date:** 2026-05-19 · 02:00 UTC–07:00  
**Scope:** User research (Mendel), knitter domain modeling (Jacquard), UX/design (Ive×5 iterations), user directive capture  
**Outcome:** All major deliverables shipped; one binding user directive captured and baked into design doc + Excalidraw

---

## What Shipped

### Mendel: User Research Foundation
- 5 JTBDs (Cast-on stitch count, per-section cm targets, mid-project verdict, increase-row spacing, one-handed mobile)
- 4 primary personas (Miriam/Yarn-First, Donal/Mid-Project Worrier, Reema/Methodical Technician, Birgitta/One-Handed Adapter)
- Journey sketches for pre-cast-on and mid-project flows
- Accessibility floor: Birgitta's needs (44pt targets, Dynamic Type +3, semantic VoiceOver, text labels on color) are baseline
- 10 open research questions for future user testing
- **Status:** Ready for implementation

### Jacquard: Craft-Truth Foundation
- 7 knitter archetypes (Seamless Top-Down, Sock Architect, Lace/Shawl, Technical Garment, Comfort, Inheritance/Stash, Community Helper)
- Vocabulary cheat sheet (13 canonical terms with rationale)
- 8 anti-patterns guide with corrective approaches
- Scenario library keyed to common failure modes
- **Status:** Ready for implementation and copy reference

### Ive: Design Direction + Excalidraw
- **Design doc:** 4 binding principles (Principle 1: One Screen One Press; Principle 2: Number First; Principle 3: Verdict Dominance; Principle 4: Text Before Color) + hero layout + accessibility floor + verdict copy table (4 branches, all concrete numbers) + audit findings + what's ruled out
- **Excalidraw:** Single-page iOS portrait flow (969×1494 px, 42 elements, 4 verdict state variants within same frame region, no wizard layout, all inputs visible on first paint)
- **Status:** Ready for implementation
- **Iteration notes:** Opus-based attempt (ive-1) failed to converge; Sonnet respawn (ive-2) delivered design doc + initial Excalidraw but shape was desktop-biased; ive-3 backup killed (overlap); ive-4 reshaped to portrait but verdict cards created false wizard impression; ive-5 locked in Principle 1 as top-level binding and re-framed Excalidraw to show 4 state variants as "within same region" via dashed connectors

### User Directive: Captured and Integrated
- **By:** yashasg via Copilot, 2026-05-19T01:54-07:00
- **Binding constraint:** All inputs on one screen, one Calculate button, verdict inline (revealed after press). No wizards, no multi-step, no separate result screens.
- **Integration:** Baked directly into Principle 1 of design doc; Excalidraw layout fully compliant.

---

## What's Open

1. **Birgitta accessibility validation:** Profile is grounded in published disability prevalence and craft-accessibility research, not interviews. Real-world testing with knitters using Dynamic Type +3 and VoiceOver recommended before ship.

2. **Mismatch branch number inclusion:** Design doc flags open question — should "Major Mismatch" branch still surface the adjusted cast-on number to allow cross-checking, or is the "needle change recommended" hedge sufficient? Requires team decision.

3. **CSS custom property fallback:** Verdict slab's dark background + light text require careful contrast work; design doc asks whether CSS custom property inheritance works across browser matrix or whether elevated `accent-soft` card is safer fallback.

4. **Share link usage:** Is the share feature used peer-to-peer (send to a friend) or self-across-devices (send to own email)? Unresolved by research; affects link labeling and context-setting.

5. **Row gauge awareness at arrival:** Do most users already know row gauge is separate from stitch gauge, or do they discover it via the tool? This affects how much "two-axis" framing needs explanation vs. assumption in onboarding.

---

## Cross-Team Alignment

- **Mendel ↔ Jacquard:** Personas map to archetypes; Miriam = Seamless Top-Down, Reema = Technical Garment, Donal spans multiple
- **Ive ↔ Mendel:** Principle 4 ("Text Before Color") operationalizes Birgitta's accessibility profile
- **Ive ↔ Jacquard:** Anti-pattern 5 ("Don't ask for needle size") directly validates Ive's hero layout (no needle size input field)
- **All ↔ User Directive:** Principle 1 is canonically binding for all implementation work

---

## Health Status

- **Decisions.md:** Updated with Round 3 section; grew from 1924 to ~6500 bytes (still well below 20KB archive threshold)
- **Orchestration logs:** 7 entries created (1 failed, 2 success, 1 overlap-killed, 2 iteration-failures, 1 final success)
- **Session log:** This file
- **Agent history:** Updated (ive, mendel, jacquard)
- **Inbox:** 4 files merged and deleted (ready for final git commit)

---

## Next Steps for Implementation

1. **Accessibility validation:** Coordinate with Birgitta (or similar profile) for usability testing on Dynamic Type +3 + VoiceOver
2. **Design refinement:** Resolve open questions (Mismatch number, CSS fallback, share link UX)
3. **Excalidraw hand-off:** Pass to Ada/Curie for HTML/CSS/JS implementation starting from ive-5 frame spec
4. **Copy review:** Use Jacquard's vocabulary cheat sheet as linter for all UI text (inputs, labels, pills, help text, VoiceOver announces)
5. **Accessibility spot-check:** 44pt touch targets, Dynamic Type scaling, semantic labels — all non-negotiable per floor
