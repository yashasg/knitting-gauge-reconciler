# Hopper — Shared Xcode scheme for CI

**Date:** 2026-05-22T15:15:26-07:00  
**Owner:** Hopper  
**Status:** Implemented

## Decision

Commit a shared Xcode scheme at `app/app.xcodeproj/xcshareddata/xcschemes/KnittingGaugeReconciler.xcscheme` so CI can resolve the `KnittingGaugeReconciler` scheme without relying on uncommitted `xcuserdata`.

## Scope

- Main app target: `KnittingGaugeReconciler` (`000000000000000000000401`)
- Unit test target: `KnittingGaugeReconcilerTests` (`000000000000000000000402`)
- UI test target: `KnittingGaugeReconcilerUITests` (`000000000000000000000403`)
- App bundle identifier: `com.yashasg.KnittingGaugeReconciler`

## Rationale

Fastlane CI runs on a clean runner and cannot see developer-local schemes stored outside source control. Sharing the scheme restores the standard Xcode contract: build the app, include both test bundles in the scheme, run tests in Debug, and use Release for profiling and archiving.

## Validation

- `xmllint --noout app/app.xcodeproj/xcshareddata/xcschemes/KnittingGaugeReconciler.xcscheme`
- `xcodebuild -project app/app.xcodeproj -list`
