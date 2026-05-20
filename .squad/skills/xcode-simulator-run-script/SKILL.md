---
name: "xcode-simulator-run-script"
description: "Build an iOS app with the existing build script, then install and launch it on the matching simulator"
domain: "build"
confidence: "high"
source: "earned"
---

## Context

Use this when adding a local run command for an Xcode iOS app that already has a build script controlling project, scheme, DerivedData, warnings, and simulator defaults.

## Patterns

- Delegate compilation to the existing build script instead of duplicating `xcodebuild` flags.
- Preserve simulator overrides (`SIMULATOR_NAME`, `SIMULATOR_UDID`, `DESTINATION`) and resolve a UDID for `simctl` install/launch.
- Locate the built simulator `.app` under the same DerivedData products path used by the build script.
- Read `CFBundleIdentifier` from the built app's `Info.plist` with `PlistBuddy`; do not hardcode it.
- Stage the `.app` outside DerivedData before `simctl install` if other build/test jobs may clean DerivedData concurrently.

## Examples

- Build: `DESTINATION="platform=iOS Simulator,id=$SIMULATOR_UDID" ./app/build.sh build`
- Product path: `app/.build/derived-data/Build/Products/Debug-iphonesimulator/*.app`
- Launch: `xcrun simctl install "$SIMULATOR_UDID" "$STAGED_APP"` then `xcrun simctl launch "$SIMULATOR_UDID" "$BUNDLE_ID"`

## Anti-Patterns

- Duplicating project, scheme, warning, or DerivedData build policy in the run script.
- Hardcoding bundle identifiers when the built app metadata is available.
- Installing directly from DerivedData in a repo where parallel build/test jobs clean DerivedData.
