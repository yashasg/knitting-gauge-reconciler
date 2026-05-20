# iOS work loop — local gate green, GitLab gate blocked

**Owner:** Tesla / Hopper / Curie  
**Goal:** Cycle step 4 / merge gate  
**Status:** Local pass; external GitLab gate blocked

## Work completed

- Closed the Hopper project-path inbox drift by restoring `app/KnittingGaugeReconciler.xcodeproj` as the canonical Xcode project path in squad records.
- Hardened `app/build.sh` so test mode retries once after transient CoreSimulator launch-state failures (`Busy`, invalid device state, Mach -308, no process handle, or disconnected test runner) by rebooting the selected simulator.
- Preserved strict failure behavior for compiler warnings, XCTest assertion failures, failed suites/cases, and non-benign simulator launch/crash diagnostics.

## Validation

- `bash -n app/build.sh` exited 0.
- `xcodebuild -list -project app/KnittingGaugeReconciler.xcodeproj` exited 0.
- `node prototype/tests/gauge-math.test.js` exited 0 with 77 passed, 0 failed, 0 pending.
- `./app/build.sh test` exited 0 on the iPhone 17 Pro simulator after the new retry path handled an Xcode/CoreSimulator launch-state failure.

## Branch state

- Branch: `squad/ios-work-loop-validation`
- Local/remote ref: `c0a9b4adc7c396814024b1590280a084f1246a71`
- Remote `main`: `18bc8734d0482f19517998546b15ef11f497c858`
- `git push origin HEAD:squad/ios-work-loop-validation`: `Everything up-to-date`

## External gate

- `GITLAB_TOKEN` is not present in this environment.
- GitLab project, branch, pipeline, and merge-request API endpoints return `404 Project Not Found`.
- A GitLab issue cannot be opened or verified from this environment without project API access.

## Goal status

1. **Working app:** ✅ `./app/build.sh test` exits 0 locally on iPhone simulator.
2. **UI/UX approved:** ✅ Existing Ive sign-off remains valid; no UI drift was introduced.
3. **User scenarios captured:** ✅ Six Jacquard scenarios remain covered by prototype, unit, and UI tests.
4. **Expert approved:** ✅ Swift math remains aligned with `.squad/decisions/decisions.md`.
5. **Code tested and validated:** ✅ Curie's local warning-as-error gate is green.

Do not merge to `main` until GitLab access is restored and the latest branch/MR pipeline is verified green.
