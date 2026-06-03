# Skill: Dynamic Type — Elastic Layout (No Exceptions)

**Owner:** Ive (UI/UX Designer)  
**Created:** 2026-06-02  
**Updated:** 2026-06-02 (v2 — supersedes hide-at-AX-sizes approach)

## Core Principle

> **Text always renders at the user's exact chosen Dynamic Type size. The LAYOUT adapts — by reflowing, wrapping, or growing — never the text.**

No `.minimumScaleFactor`. No `.dynamicTypeSize` cap. No conditional hiding.

## Problem

Decorative elements (badges, pills, tags) overflow at accessibility Dynamic Type sizes. Common "solutions" that violate HIG:
- `.dynamicTypeSize(...DynamicTypeSize.accessibility1)` — caps text, ignores user choice
- `.minimumScaleFactor(0.7)` — shrinks text, harms readability
- `if isAccessibilitySize { EmptyView() }` — hides content from large-text users

All three are compromises. The correct answer: the layout must absorb the text size.

## Solution: `ViewThatFits`

iOS 16+ (we target iOS 17). SwiftUI measures children in order, picks the first that fits. No manual breakpoints, no `GeometryReader` hacks.

**Pattern:**

```swift
ViewThatFits(in: .horizontal) {
    // Preferred: side-by-side
    HStack { label; badge }
    // Fallback: stacked (full width each)
    VStack(alignment: .leading) { label; badge }
}
```

**Behavior:**
- xSmall–xxxLarge: HStack fits, renders side-by-side
- AX1–AX5: HStack doesn't fit, falls through to VStack
- Text is never truncated, never shrunk, never capped

## Example: Header with Decorative Tag

```swift
struct CardHeader: View {
    let title: String
    let tag: String?

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                Text(title)
                    .font(.title2.weight(.bold))
                Spacer()
                if let tag {
                    Text(tag)
                        .font(.caption2.weight(.bold))
                        .accessibilityHidden(true)
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.title2.weight(.bold))
                if let tag {
                    Text(tag)
                        .font(.caption2.weight(.bold))
                        .accessibilityHidden(true)
                }
            }
        }
    }
}
```

## Example: Value Tile with Badge Overlay

For badges that float over a tile (ZStack overlay), the layout usually tolerates some overlap at large sizes. Only add a VStack fallback if real-device testing shows unacceptable visual breakage:

```swift
@ViewBuilder
private var valueTile: some View {
    ViewThatFits(in: .horizontal) {
        // Preferred: badge overlays tile
        ZStack(alignment: .topTrailing) {
            tileContent
            if showBadge { badge.offset(x: -6, y: -6) }
        }
        // Fallback: badge above tile
        VStack(alignment: .trailing, spacing: 4) {
            if showBadge { badge }
            tileContent
        }
    }
}
```

## Decorative Elements: Keep `.accessibilityHidden(true)`

Even though badges now render at all sizes, they remain decorative — their information is duplicated in adjacent accessibility labels. Keep `.accessibilityHidden(true)` so VoiceOver users aren't spammed with redundant announcements.

**Example:**
- Per-tag "PER 10CM / 4\"" — info is in "24 stitches per 10 cm" label
- Delta pill "+12" — info is in "You Must Knit: 64, 12 more than pattern" label
- Drift pill "−3%" — info is in "Rows adjusted: 52, −3% drift" label

## When NOT to Use ViewThatFits

- **Simple single-line text** — just let it wrap naturally with `.lineLimit(nil)`
- **Interactive elements** — buttons must maintain 44pt hit targets regardless
- **Grid layouts** — use `isAccessibilitySize` reflow (existing `GaugeMeasurementPair` pattern)

## Existing Codebase Pattern

`GaugeMeasurementPair.swift` and `AdjustmentValuePair.swift` use the manual reflow pattern:

```swift
if dynamicTypeSize.isAccessibilitySize {
    VStack { ... }
} else {
    LazyVGrid(columns: columns) { ... }
}
```

This is correct for content-bearing paired fields. `ViewThatFits` is cleaner for header/badge layouts.

## Trade-offs

| Concern | Assessment |
|---------|------------|
| Cards grow taller | Correct behavior. User chose large text. |
| Truncation | None — text never constrained |
| Layout thrash | `ViewThatFits` measures once; no animation jank |
| VoiceOver focus order | Unchanged — decorative elements hidden |

## HIG Reference

> "Support all Dynamic Type sizes. ... People who rely on larger text sizes should be able to read all content in your app."  
> — [Apple HIG: Typography](https://developer.apple.com/design/human-interface-guidelines/typography)

## Implementation Notes (2026-06-02)

### `Spacer()` inside `ViewThatFits` children is safe
A `Spacer()` inside an HStack that is a `ViewThatFits` child has ideal size 0. `ViewThatFits` measures ideal size, so the HStack's ideal width = sum of non-Spacer children. The Spacer only fills space once the HStack is actually rendered.

### `.fixedSize(horizontal: true)` pills require ViewThatFits
Pills using `.fixedSize(horizontal: true)` insist on their intrinsic width regardless of parent. In an HStack at AX5, this is near-certain overflow. Always wrap the pill's row in `ViewThatFits`.

### ZStack overlay pills do NOT require ViewThatFits
Pills positioned via `ZStack(alignment: .topTrailing)` with `.offset` absorb larger sizes gracefully — the overlay simply grows. Only add a `ViewThatFits` fallback if simulator testing shows the pill obscures content unacceptably.

### Private computed properties reduce duplication in ViewThatFits
Since both branches must be fully self-contained, extract shared subviews as `private var` computed properties:
```swift
@ViewBuilder private var iconView: some View { ... }
private var titleView: some View { ... }
private var perTagView: some View { ... }
```
Both branches reference the same properties — reduces duplication while keeping ViewThatFits pattern clear.

## Checklist

- [x] NO `.minimumScaleFactor` on any text
- [x] NO `.dynamicTypeSize(...cap)` on any text
- [x] NO conditional hiding at accessibility sizes
- [x] `ViewThatFits` used for header/badge layouts
- [x] Decorative elements keep `.accessibilityHidden(true)`
- [x] AX5 preview added for visual verification
- [x] Verified VoiceOver labels unchanged
