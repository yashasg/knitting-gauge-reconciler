# Hopper — History Archive (Pre-2026-05-31)

## Prior Sessions Summary

### 2026-05-31 Early — Cleanup Commit Verification
- Baseline differential analysis: 5 UI test failures on HEAD same as with changes applied
- Conclusion: zero regression, cleanup eligible to commit per gate rule
- Coordinated Edison SwiftLint cleanup (08f8a70) + Curie scroll fix (787ca28)

### 2026-05-31 Mid — Async Share-Image Commit
- Committed b36d9be + 1f65536 (share image async, gitignore report.xml)
- Both pushed to origin/main

### 2026-05-31 Template/Tooling Sessions (Earlier)
- Fastlane produce + match interactive-auth docs (Hopper-20, commit 46c73a3)
- Template Xcode sync groups fix (Hopper-19, commit d3043ff template)
- Ruby preflight guard (Hopper-18, commit 5b9c328 template)
- Template bootstrap flow (Hopper-17)
- Hardened SwiftLint policy (Hopper-15, commit 125a4aa)
- Copilot instructions update (Hopper-16, commit 31ef774)

### 2026-05-29 — File-System-Synchronized Groups Fix
- **Root cause:** Template pbxproj carried 18 stale file references from original gauge-app
- **Fix:** Converted to PBXFileSystemSynchronizedRootGroup (Xcode 16, objectVersion 77)
- **Key detail:** Added PBXFileSystemSynchronizedBuildFileExceptionSet to exclude Info.plist
- **Commits:** Template d3043ff, fabric-stabilizer-picker 117a20f
- **Result:** "Build input files cannot be found" errors eliminated

### 2026-05-29 — Ruby Preflight Guard
- **Landmine:** macOS system Ruby 2.6 read-only, Gemfile.lock pins Ruby >=3
- **Solution:** ruby_preflight() bash function in build.sh and run.sh
- **Strategy:** Self-heal if Homebrew Ruby available, clear error if not
- **Commits:** Template 5b9c328, fabric-stabilizer-picker aa98283

### 2026-05-23 Earlier — Template Bootstrap, Icon, App Name Convention
- Template app icon: neutral placeholder (Gray 8E8E93)
- App name two-name convention (human-readable + slug)
- iOS template hardened SwiftLint policy foundation

## Learnings

- **Xcode pbxproj / file-manifest drift:** Template-derived projects with removed sources but unchanged pbxproj create "Build input files cannot be found" in all clones. PBXFileSystemSynchronizedRootGroup (target membership = folder contents) permanently prevents this class of bug.
- **System Ruby gotcha:** macOS system Ruby is read-only and pre-installed at 2.6. Shell PATH resolution must prioritize Homebrew Ruby (3.x+). Guard scripts self-heal when possible, clear error fallback when not.
- **Fastlane produce + match:** One-shot interactive setup commands (not lanes). First-run prompts for Apple ID 2FA. Must run in real Terminal, not piped/automated shells.

## Status

All prior template and tooling work committed and pushed to GitLab. Ready for session archival.
