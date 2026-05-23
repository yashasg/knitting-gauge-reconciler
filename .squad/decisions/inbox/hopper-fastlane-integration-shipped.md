# Hopper Fastlane Integration — shipped

**Date:** 2026-05-23T01:01:48-07:00  
**Author:** Hopper (Tooling Dev)  
**Requested by:** Tesla (human)

## What shipped

Implemented the approved five-part Fastlane convergence from `cocktail-batch-dilution` into KGR on branch `feat/fastlane-from-cocktail`:

1. Adopted cocktail's Team ID in `app/fastlane/Appfile` while keeping KGR's bundle identifier `com.yashasg.KnittingGaugeReconciler`.
2. Added a preflight guard that compares Fastlane `app_identifier` against `app/app.xcodeproj/project.pbxproj` `PRODUCT_BUNDLE_IDENTIFIER` and aborts release lanes on drift.
3. Added a TestFlight build-number helper that falls back cleanly when the current marketing version has no prior TestFlight build.
4. Switched Fastlane release auth to App Store Connect API key env vars: `ASC_KEY_ID`, `ASC_ISSUER_ID`, and exactly one of `ASC_KEY_FILEPATH` / `ASC_KEY_CONTENT_B64`.
5. Ported cocktail's release-signing hardening: CI temp keychain, optional WWDR import, `match`-derived signing context, manual export wiring.

## Active CI test shape

The active Fastlane CI test shape is now cocktail-style and scheme-driven:

- `ci` builds the shared `KnittingGaugeReconciler` scheme and runs tests from that scheme without a lane-level `only_testing` filter.
- `test` also runs the scheme-defined test scope.
- The shared Xcode scheme is now the source of truth for whether unit tests and UI tests participate in Fastlane CI.

## Superseded assumptions

This shipped shape supersedes the prior accepted Fastlane CI assumptions referenced in squad decision history:

- Release-config-build / Debug-test split as the preferred CI lane shape
- Serial-UI CI policy as an active Fastlane constraint
- Canceled-as-failed behavior as part of the prior CI design rationale

Tesla explicitly approved the override for this Fastlane integration.

## CI env-var contract

### App Store Connect auth
- `ASC_KEY_ID`
- `ASC_ISSUER_ID`
- exactly one of:
  - `ASC_KEY_FILEPATH`
  - `ASC_KEY_CONTENT_B64`

### Signing / release lanes
- `MATCH_PASSWORD`
- `MATCH_KEYCHAIN_PASSWORD`
- optional: `WWDR_CERT_PATH`
- existing credentials for the `fastlane_hisa` match repository must still be present in CI

## Validation

- `ruby -c app/fastlane/Fastfile` after each of the five Fastlane commits
- No Fastlane lanes executed; secrets were intentionally not configured in-session
