import 'dart:io';

import 'package:yaml/yaml.dart';

/// Parsed configuration from the `enforced_lints` section of
/// `analysis_options.yaml`.
///
/// Example `analysis_options.yaml`:
/// ```yaml
/// enforced_lints:
///   rules:
///     no_final_local_variable: false  # disable this rule
/// ```
///
/// All rules are enabled by default. A rule is only disabled when
/// explicitly set to `false`.
class EnforcedLintsConfig {
  static const _pluginKey = 'enforced_lints';
  static const _rulesKey = 'rules';

  final Set<String> _disabledRules;

  const EnforcedLintsConfig._({required Set<String> disabledRules})
      : _disabledRules = disabledRules;

  /// All rules enabled — used when no config file exists or parsing fails.
  static const EnforcedLintsConfig empty =
      EnforcedLintsConfig._(disabledRules: {});

  /// Reads and parses the options file at [optionsFilePath].
  factory EnforcedLintsConfig.fromOptionsFile(String optionsFilePath) {
    try {
      final content = File(optionsFilePath).readAsStringSync();
      final doc = loadYaml(content);
      if (doc is! Map) return EnforcedLintsConfig.empty;

      final pluginOptions = doc[_pluginKey];
      if (pluginOptions is! Map) return EnforcedLintsConfig.empty;

      final rulesMap = pluginOptions[_rulesKey];
      if (rulesMap is! Map) return EnforcedLintsConfig.empty;

      final disabled = <String>{};
      for (final entry in rulesMap.entries) {
        if (entry.value == false) disabled.add(entry.key as String);
      }
      return EnforcedLintsConfig._(disabledRules: disabled);
    } catch (_) {
      return EnforcedLintsConfig.empty;
    }
  }

  /// Returns `true` when [ruleCode] has not been explicitly disabled.
  bool isEnabled(String ruleCode) => !_disabledRules.contains(ruleCode);
}
