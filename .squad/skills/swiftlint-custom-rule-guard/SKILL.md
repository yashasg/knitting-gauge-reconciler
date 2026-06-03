---
name: "swiftlint-custom-rule-guard"
description: "How to write SwiftLint custom_rules regex entries that guard against accessibility and architectural anti-patterns in iOS/SwiftUI codebases"
domain: "ios, swiftlint, swift, accessibility, tooling"
confidence: "high"
source: "earned"
---

## Context

Use when adding a new custom SwiftLint rule to prevent regression of a code pattern that was intentionally removed (e.g., an accessibility anti-pattern, a banned API, an architectural boundary violation).

## Patterns

### 1. YAML string quoting for regex values

Always use **single-quoted** YAML strings for `regex:` and `message:` fields. Single quotes are literal — backslashes have no special meaning, so `\.foo` is the regex `\.foo` (literal dot then `foo`).

```yaml
# ✅ Single quotes — backslashes are literal
no_minimum_scale_factor:
  regex: '\.minimumScaleFactor\('
  message: 'Banned — reflow with ViewThatFits instead.'

# ❌ Double quotes — backslash is an escape character; \. is invalid
no_minimum_scale_factor:
  regex: "\.minimumScaleFactor\("     # YAML parse error!
  message: "Banned — use .environment(\.dynamicTypeSize…)"  # \. is invalid escape
```

### 2. Targeting a view modifier vs. an environment keypath

SwiftUI has two distinct syntaxes for `dynamicTypeSize`:

| Syntax | Role | Example |
|---|---|---|
| `.dynamicTypeSize(…)` | View modifier — **applies** a size/range | `.dynamicTypeSize(...DynamicTypeSize.accessibility1)` |
| `\.dynamicTypeSize` | KeyPath — **reads** the environment | `@Environment(\.dynamicTypeSize)` |
| `.environment(\.dynamicTypeSize, …)` | Environment setter — used in `#Preview` | `.environment(\.dynamicTypeSize, .accessibility5)` |

**The regex `\.dynamicTypeSize\(\.\.\.` ONLY matches the view-modifier PartialRangeThrough form.** It does not fire on:
- `@Environment(\.dynamicTypeSize)` — no `(` after the keypath
- `.environment(\.dynamicTypeSize, .accessibility5)` — no `(` directly after the keypath
- `dynamicTypeSize.isAccessibilitySize` — no leading `.` at the start of `dynamicTypeSize`

### 3. PartialRangeThrough vs. PartialRangeFrom

```swift
// ❌ PartialRangeThrough (upper cap) — BANNED
.dynamicTypeSize(...DynamicTypeSize.accessibility1)

// ✅ PartialRangeFrom (lower floor) — acceptable
.dynamicTypeSize(DynamicTypeSize.xSmall...)

// ✅ Closed range — situationally acceptable but unusual
.dynamicTypeSize(DynamicTypeSize.xSmall...DynamicTypeSize.accessibility5)
```

The regex `\.dynamicTypeSize\(\.\.\.` targets `...` at the **start** of the argument (PartialRangeThrough). It does not fire on PartialRangeFrom (where `...` is at the end).

If you need to also ban ClosedRange upper-bound caps, add a second rule:
```yaml
no_dynamic_type_closed_range_cap:
  regex: '\.dynamicTypeSize\(DynamicTypeSize\.[a-zA-Z0-9]+\.\.\.DynamicTypeSize\.'
  severity: error
```

### 4. Exclusions for tests

Test directories often need to set specific sizes for layout assertions — exclude them explicitly:

```yaml
excluded:
  - app/KnittingGaugeReconcilerTests
  - app/KnittingGaugeReconcilerUITests
```

This applies to ALL custom rules. You can also exclude per-rule using the `excluded_paths` key (SwiftLint 0.52+):
```yaml
no_dynamic_type_cap:
  regex: '\.dynamicTypeSize\(\.\.\.'
  excluded_paths:
    - app/KnittingGaugeReconcilerUITests
```

### 5. Negative testing procedure

Always verify both directions before shipping a new rule:

```bash
# Step 1: Clean baseline — must be 0 violations
swiftlint lint --config .swiftlint.yml --reporter xcode

# Step 2: Temporarily inject the banned pattern into any source file
echo '// TEST .minimumScaleFactor(0.5)' >> app/KnittingGaugeReconciler/Views/HomeHeaderView.swift

# Step 3: Lint should fire
swiftlint lint --config .swiftlint.yml --reporter xcode
# Expected: 1 violation, no_minimum_scale_factor

# Step 4: Revert
git checkout app/KnittingGaugeReconciler/Views/HomeHeaderView.swift
```

Note: SwiftLint regex scans **raw file text including comments**. A banned pattern in a comment WILL trigger the rule. This is acceptable for regression guards — it prevents people from leaving a "reminder" comment that contains the banned form.

### 6. Pre-commit hook wiring

Per §3.1 of `docs/swift_coding_standards.md`:

```bash
cat > .git/hooks/pre-commit << 'EOF'
#!/usr/bin/env bash
if command -v swiftlint &>/dev/null; then
  swiftlint lint --config .swiftlint.yml --reporter xcode
fi
EOF
chmod +x .git/hooks/pre-commit
```

The hook is not committed to the repo (`.git/` is untracked). Document the setup command in `docs/swift_coding_standards.md` §3.1 so teammates can reinstall after a fresh clone.

### 7. Documentation requirement

Per charter: every SwiftLint rule must be documented in `docs/swift_coding_standards.md`:
- §3.2 table: Rule ID, severity, what it catches
- §3.3+ subsection: rationale, code examples (banned ❌ and correct ✅), scope notes

## Examples from this project

```yaml
# Guards against reintroducing minimumScaleFactor (banned 2026-06-02)
no_minimum_scale_factor:
  name: "minimumScaleFactor shrinks text"
  message: 'minimumScaleFactor shrinks text below the user chosen Dynamic Type size — banned per accessibility decision; reflow with ViewThatFits instead.'
  regex: '\.minimumScaleFactor\('
  severity: error

# Guards against reintroducing dynamicTypeSize PartialRangeThrough cap (banned 2026-06-02)
no_dynamic_type_cap:
  name: "dynamicTypeSize partial-range ceiling"
  message: 'dynamicTypeSize cap clamps Dynamic Type growth — banned per accessibility decision; reflow with ViewThatFits instead.'
  regex: '\.dynamicTypeSize\(\.\.\.'
  severity: error
```

## Anti-Patterns

- **Don't use double-quoted YAML** for regex/message values containing backslashes — YAML parser rejects `\.`
- **Don't forget to exclude test directories** — tests legitimately set sizes for assertions
- **Don't add `multiline_matching: true`** unless the banned pattern actually spans lines; it's slower
- **Don't rely on UI tests alone** to guard source-level anti-patterns — lint catches it at commit time, UI tests catch it at simulator runtime (much slower, flakier)
