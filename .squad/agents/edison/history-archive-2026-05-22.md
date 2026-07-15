# Edison — 2026-05-21/22 Archived History Summary

_Summarized at 2026-07-14T23:38:12.955-07:00 after crossing the 15,360-byte history threshold._

## Shipped UI learnings

- Migrated AppTheme colors to semantic asset-catalog colors while preserving light/dark behavior and removing direct custom color construction.
- Completed non-color HIG/SwiftLint cleanup without changing behavior; accessibility labels, traits, hit targets, and Dynamic Type remained acceptance constraints.
- App-title experiments resolved in favor of native navigation behavior rather than a redundant in-content app-name heading.
- Tightened main-screen spacing and polished the reconcile/results hierarchy while preserving readability and touch targets.
- Result/adjustment boxes use equal-width layouts so paired values remain visually comparable.
- Required adjustments moved into a pull-up sheet; subsequent content-first polish repaired title, spacing, reset, and share flow behavior.
- Sheet and share changes must preserve accessibility identifiers and avoid presenting stale or obscured actions.
- Repeated summary entries from parallel sessions were consolidated here; exact implementation decisions remain in git history and `.squad/decisions.md`.

Current implementation learnings remain in `history.md`.
