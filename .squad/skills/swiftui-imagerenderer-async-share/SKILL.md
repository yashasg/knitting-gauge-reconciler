---
name: "swiftui-imagerenderer-async-share"
description: "How to make SwiftUI ImageRenderer-based share flows async without blocking the main thread"
domain: "swiftui, concurrency, sharing"
confidence: "high"
source: "earned"
---

## Context

`ImageRenderer` is `@MainActor`-isolated in SwiftUI. Rasterizing a view to `UIImage` must happen on the main actor. However, PNG encoding (`UIImage.pngData()`) and file writes (`Data.write(to:)`) are expensive and can block the UI. This skill covers the split that keeps the UI responsive.

## Patterns

### Actor Split

```
MainActor                          Detached Task
─────────────────────────────────  ──────────────────────────────
ImageRenderer(content:).uiImage    (nothing here — UIImage not
UIImage.pngData()                   captured across boundary)
                                   Data.write(to:fileURL, options:[.atomic])
```

- **Rasterize on MainActor** — no choice, `ImageRenderer` requires it.
- **Encode on MainActor** — keep `pngData()` co-located to avoid capturing `UIImage` (not safely Sendable) across the detached boundary.
- **Write on detached task** — `Data` and `URL` are `Sendable`; disk I/O is the blocking work.

### Re-entrancy Guard

Add `@State private var isPreparingShare = false` to the sheet view. Check and set it synchronously before launching the `Task {}`, then reset after the payload is ready.

```swift
onShare: {
    guard !isPreparingShare else { return }
    isPreparingShare = true
    Task {
        let items = await onShare(result)
        sharePayload = ShareSheetPayload(items: items)
        isPreparingShare = false
    }
}
```

### Async renderShareImageURL Pattern

```swift
@MainActor
private func renderShareImageURL(summary: ResultsExportSummary) async -> URL? {
    let renderer = ImageRenderer(content: ShareableView(summary: summary))
    renderer.proposedSize = .init(width: 390, height: nil)
    renderer.scale = 3

    // Must stay on MainActor. Encode here too — do NOT capture UIImage across detached boundary.
    guard let image = renderer.uiImage, let pngData = image.pngData() else { return nil }

    // Offload disk write only; Data is Sendable.
    return await Task.detached(priority: .userInitiated) {
        do {
            let caches = try FileManager.default.url(
                for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true
            )
            let dir = caches.appendingPathComponent("ShareExports", isDirectory: true)
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let fileURL = dir.appendingPathComponent("results.png")
            try pngData.write(to: fileURL, options: [.atomic])
            return fileURL
        } catch {
            return nil as URL?
        }
    }.value
}
```

### UX During Preparation

Replace the share button's icon with a `ProgressView` and `.disabled(true)` while `isPreparingShare` is set:

```swift
Button(action: onShare) {
    if isPreparingShare {
        ProgressView().tint(AppTheme.sage).frame(width: 44, height: 44)
    } else {
        Image(systemName: "square.and.arrow.up")
            .frame(width: 44, height: 44).contentShape(Rectangle())
    }
}
.disabled(isPreparingShare)
```

## Examples

- `app/KnittingGaugeReconciler/ContentView.swift` — `shareItems(for:)` + `renderShareImageURL(summary:)`
- `app/KnittingGaugeReconciler/Views/RequiredAdjustmentsCard.swift` — `AdjustmentSheetView` + `AdjustmentSheetHeader`

## Anti-Patterns

- **Never capture `UIImage` in `Task.detached`** — `UIImage` is `@unchecked Sendable` but crossing the actor boundary with it is fragile. Encode to `Data` first.
- **Never use `DispatchQueue.main.async`** inside a SwiftUI view — use `.task`, `Task {}` in button actions, or `await` instead (§2.8).
- **No `Task {}` directly inside `View.body`** — `Task {}` in a button *action closure* is acceptable; bare `Task {}` as a body side-effect is not (use `.task` modifier instead).
- **Don't skip the re-entrancy guard** — without it, rapid double-taps can produce concurrent renders and a race on the cache file.
