# enforced_lints

Configurable Dart/Flutter lint rules enforced via the Dart analyzer plugin API.
Rules are reported directly in your IDE as you type, with quick-fixes available where applicable.

---

## Installation

Add the package to your `pubspec.yaml` as a dev dependency:

```yaml
dev_dependencies:
  enforced_lints: ^0.0.1
```

Then enable the plugin in your `analysis_options.yaml`:

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

## Available rules

| Rule | Description | Default |
|------|-------------|---------|
| `no_final_local_variable` | Local variables must use explicit, non-final types. Bans `final` and `var`. | enabled |

---

## Configuring rules

All rules are **enabled by default**. To disable a specific rule, add an
`enforced_lints` section to your `analysis_options.yaml` and set the rule to
`false`:

```yaml
analyzer:
  plugins:
    - enforced_lints

enforced_lints:
  rules:
    no_final_local_variable: false
```

Changes to `analysis_options.yaml` are picked up automatically — no IDE restart
required.

---

## Rule reference

### `no_final_local_variable`

Local variables must be declared with an explicit, non-final type.
Both `final` and `var` are prohibited.

**Bad**

```dart
void process() {
  final int count = 0;   // ❌ final not allowed
  var name = 'Alice';    // ❌ var not allowed
  final items = <String>[];  // ❌ final + implicit type
}
```

**Good**

```dart
void process() {
  int count = 0;         // ✅ explicit type, no final
  String name = 'Alice'; // ✅
  List<String> items = []; // ✅
}
```

**Quick fixes**

The plugin provides quick-fixes that can be applied individually or all at once
across the file:

- `final int x = 5` → removes `final`, leaving `int x = 5`
- `var x = 5` → replaces `var` with the inferred type, giving `int x = 5`

> **Note:** No fix is offered when the type resolves to `dynamic`, since there
> is no safe concrete type to substitute.

---

## Adding new rules

This package is designed to be extended. To contribute a rule:

1. Create `tools/analyzer_plugin/lib/src/rules/my_rule.dart` extending `DartRule`.
2. Add `MyRule()` to the list in `tools/analyzer_plugin/lib/src/rules.dart`.
3. Add an entry to the rule table in this README and to `CHANGELOG.md`.

See the existing `no_final_local_variable` rule for a complete example.
