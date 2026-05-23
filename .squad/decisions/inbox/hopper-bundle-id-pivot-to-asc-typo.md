# Hopper — Bundle ID pivot to ASC typo

- **Date:** 2026-05-23T03:28:48-07:00
- **Author:** Hopper
- **Status:** Proposed

## Context

Tesla cannot create a new App Store Connect app. The existing ASC entry (numeric app ID `6772098335`) is already wired into Fastlane/Appfile, but ASC has the bundle identifier registered as `com.yashasg.knitting-guage-reconciler` — lowercase, hyphenated, and with the `guage` typo.

## Decision

Align the iOS codebase and Fastlane signing configuration to `com.yashasg.knitting-guage-reconciler` instead of the previous `com.yashasg.KnittingGaugeReconciler` identifier.

## Rationale

- Uses the existing ASC app immediately; no new ASC app creation is required.
- Unblocks Match signing and CD/TestFlight/App Store upload flows, which must target the bundle ID ASC already owns.
- Keeps the numeric ASC app ID (`6772098335`) and bundle ID configuration consistent across Xcode, Appfile, and Matchfile.

## Consequence

The typo'd bundle ID becomes the canonical release identifier for this app. Correcting it later would require provisioning and migrating to a brand-new ASC app entry.