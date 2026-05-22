# Edison: App icon setup

- **Date:** 2026-05-22T02:25:03.715-07:00
- Generated the full iPhone + App Store icon set from the production-ready 1024×1024 Stitchwise source image and added `AppIcon.appiconset/Contents.json`.
- Updated `app/app.xcodeproj/project.pbxproj` so both Debug and Release use `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;`.
- Verification: `xcodebuild -project app/app.xcodeproj -scheme KnittingGaugeReconciler -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' build` succeeded.
