## 0.1.0

### Added

- Per-rule opt-out configuration via `analysis_options.yaml` — set any rule to `false` to disable it.
- Unit tests for the `no_final_local_variable` rule.
- Example project demonstrating plugin integration and rule configuration.
- `dart run tool/reset_plugin_cache.dart` script to reset the analysis server plugin cache during plugin development.

### Changed

- README restructured with anchor navigation, a rules table with status indicators, and a detailed per-rule reference section.
- Root library now includes setup documentation and exports a `version` constant.

## 0.0.1

### Added

- `no_final_local_variable`: enforce explicit non-final types for local variables.
