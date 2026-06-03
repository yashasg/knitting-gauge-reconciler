---
name: "uikit-scene-walk-xcuitest"
description: "Present UIKit modals (share sheets, alerts) from SwiftUI in a way that is compatible with XCUITest"
domain: "uikit"
confidence: "high"
source: "earned"
---

## Context

Use when you need to imperatively present a `UIViewController` (share sheet, alert, custom modal) from a SwiftUI context and the presentation must work under XCUITest as well as during live use.

## The Bug

Filtering `connectedScenes` by `.activationState == .foregroundActive` silently drops all scenes during XCUITest — the test harness attaches at `.foregroundInactive`. The result is a no-op with no error logged, making it extremely hard to diagnose.

## Pattern

```swift
private func topmostPresentingViewController() -> UIViewController? {
    let root = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .compactMap { $0.keyWindow ?? $0.windows.first(where: { $0.isKeyWindow }) ?? $0.windows.first }
        .first?
        .rootViewController
    var top = root
    while let presented = top?.presentedViewController {
        top = presented
    }
    return top
}
```

Key rules:
- Cast to `UIWindowScene` but **do not** filter by `.activationState`.
- Walk `.presentedViewController` to reach the topmost controller.
- For `UIActivityViewController` on iPad, always set `popoverPresentationController?.sourceView` and `sourceRect`; otherwise it crashes on iPad.

## Anti-pattern

```swift
// ❌ Breaks under XCUITest — scene is .foregroundInactive, this returns nil
UIApplication.shared.connectedScenes
    .filter { $0.activationState == .foregroundActive }
    .compactMap { $0 as? UIWindowScene }
    .first?.windows.first?.rootViewController
```

## Notes

- `presentResetAlert` in `RequiredAdjustmentsCard.swift` was the canonical correct example when `presentShareSheet` had the bug.
- The comment `// Do not filter by .foregroundActive — during XCUITest the scene is .foregroundInactive` is worth preserving near the helper for future maintainers.
