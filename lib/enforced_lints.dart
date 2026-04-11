/// Configurable Dart/Flutter lint rules enforced via the analyzer plugin API.
///
/// ## Setup
///
/// Add the plugin to your `pubspec.yaml`:
///
/// ```yaml
/// dev_dependencies:
///   enforced_lints: ^0.0.1
/// ```
///
/// Then enable it in `analysis_options.yaml`:
///
/// ```yaml
/// analyzer:
///   plugins:
///     - enforced_lints
/// ```
///
/// Restart your IDE after adding the plugin.
///
/// ## Available rules
///
/// | Rule | Description |
/// |------|-------------|
/// | `no_final_local_variable` | Local variables must use explicit, non-final types. |
///
/// ## Configuring rules
///
/// All rules are enabled by default. To disable specific rules, add an
/// `enforced_lints` section to your `analysis_options.yaml`:
///
/// ```yaml
/// enforced_lints:
///   rules:
///     no_final_local_variable: false
/// ```
library enforced_lints;

/// The current version of the enforced_lints package.
const String version = '0.0.1';
