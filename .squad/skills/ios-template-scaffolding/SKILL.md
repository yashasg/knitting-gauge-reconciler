# SKILL: iOS SwiftUI Template Scaffolding

**Domain:** Tooling / Build  
**Author:** Hopper  
**Date:** 2026-05-29T02:00:20-07:00

## Problem

Repeatedly scaffolding a new iOS/SwiftUI + Fastlane project from scratch wastes hours and risks inconsistent tooling setup (warnings-as-errors, lane structure, squad governance).

## Solution Pattern

1. **Source repo → token-ized template** via rsync + sed:
   - Copy everything except `.git`, `.build`, binary artifacts, CI workflow ymls.
   - Rename project directories: `<AppName>` → `__APP_NAME__`, `<AppName>Tests` → `__APP_NAME__Tests`, etc.
   - Token-replace in `project.pbxproj`, `.xcscheme`, `Fastfile`, `build.sh`, `run.sh`, `loop.sh` via `sed -i ''` (BSD-compatible).
   - Drop `.swiftlint.yml` (it IS a yml file); note in README that it should be added per project.
   - Genericize Fastlane: blank `apple_id`, `team_id` in Appfile; blank `git_url`, `username` in Matchfile.
   - Reset `.squad/`: empty roster, blank casting registry/history, generic routing table.

2. **bootstrap.sh** — shipped with the template, self-deletes after use:
   - Validates AppName is a valid Swift identifier (regex `^[A-Za-z_][A-Za-z0-9_]*$`).
   - `mv` renames dirs/files containing `__APP_NAME__`.
   - `find … -print0 | while read -r … ; do sed -i '' … ; done` replaces tokens in all non-binary files.
   - Prints next steps; `rm -- "$0"`.

3. **GitLab push** (glab v1.97.0):
   ```bash
   glab repo create <name> --private
   git remote add origin https://gitlab.com/<user>/<name>.git
   git push -u origin main
   ```
   Note: `--source`/`--push` flags are not supported in this version.

## Key invariants to preserve

- `SWIFT_TREAT_WARNINGS_AS_ERRORS=YES` in `build.sh` (never remove).
- xcpretty wired, `-quiet` set.
- `app/app.xcodeproj` stays as the project file path (not renamed — fastlane references it as `APP_PROJECT`).
- All three targets in pbxproj must reference `__APP_NAME__` / `__BUNDLE_ID__` after templating.

## macOS / BSD sed gotcha

Always use `sed -i ''` (with empty string argument) on macOS. GNU `sed -i` (no arg) will fail.

## Template repo

https://gitlab.com/yashas.gujjar/ios-swiftui-fastlane-template
