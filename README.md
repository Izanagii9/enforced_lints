# enforced_lints

Configurable Dart/Flutter lint rules enforced via the Dart analyzer plugin API.
Rules are reported directly in your IDE as you type, with quick-fixes available where applicable.

---

## Table of contents

- [Installation](#installation)
- [Rules](#rules)
- [Configuring rules](#configuring-rules)
- [Rule reference](#rule-reference)
  - [no\_final\_local\_variable](#no_final_local_variable)
- [Adding new rules](#adding-new-rules)

---

## Installation

Add the package to your `pubspec.yaml` as a dev dependency:

```yaml
dev_dependencies:
  enforced_lints: ^0.1.3
```

Enable the plugin in your `analysis_options.yaml`:

```yaml
analyzer:
  plugins:
    - enforced_lints
```

Run `dart pub get` (or `flutter pub get`), then **restart your IDE** or trigger
_Dart: Restart Analysis Server_ from the command palette. The plugin runs inside
the analysis server, so a restart is required the first time and after every
version upgrade.

---

## Rules

| Rule | Description | Status |
|------|-------------|--------|
| [`no_final_local_variable`](#no_final_local_variable) | Local variables must use explicit, non-final types. Bans `final` and `var`. | ✅ available |

---

## Configuring rules

All rules are **enabled by default**. To disable a specific rule, add an
`enforced_lints` section to your `analysis_options.yaml` and set it to `false`:

```yaml
analyzer:
  plugins:
    - enforced_lints

enforced_lints:
  rules:
    no_final_local_variable: false
```

Changes to `analysis_options.yaml` are picked up automatically — no IDE restart required.

---

## Rule reference

### no_final_local_variable

Local variables must be declared with an explicit, non-final type.
Both `final` and `var` are prohibited.

**Bad**

```dart
void process() {
  final int count = 0;       // ❌ final not allowed on local variables
  var name = 'Alice';        // ❌ var not allowed
  final items = <String>[];  // ❌ final with implicit type
}
```

**Good**

```dart
void process() {
  int count = 0;             // ✅ explicit type, no final
  String name = 'Alice';     // ✅
  List<String> items = [];   // ✅
}
```

**Quick fixes**

The plugin provides quick-fixes that can be applied individually or across the
whole file at once:

| Violation | Fix |
|-----------|-----|
| `final int x = 5` | Removes `final` → `int x = 5` |
| `var x = 5` | Replaces `var` with inferred type → `int x = 5` |
| `var x` (dynamic) | No fix available — no concrete type to substitute |

**Disable this rule**

```yaml
enforced_lints:
  rules:
    no_final_local_variable: false
```

---

## Adding new rules

This package is designed to be extended. To contribute a rule:

1. Create `tools/analyzer_plugin/lib/src/rules/my_rule.dart` extending `DartRule`.
2. Add `MyRule()` to the list in `tools/analyzer_plugin/lib/src/rules.dart`.
3. Add a row to the [Rules](#rules) table and a section to [Rule reference](#rule-reference) in this README.
4. Add an entry to `CHANGELOG.md`.

See the existing [`no_final_local_variable`](#no_final_local_variable) rule for a complete example.
