## 0.1.1

### Fixed

- Example file no longer contains real violations, which caused `dart analyze --fatal-infos` to fail and zeroed out the pub.dev static analysis score.
- Widened `analyzer` constraint to `<13.0.0` to include the latest compatible version and improve the pub.dev dependency score.

## 0.1.0

### Added

- Per-rule opt-out configuration via `analysis_options.yaml` — set any rule to `false` to disable it.
- Unit tests for the `no_final_local_variable` rule.
- Example project demonstrating plugin integration and rule configuration.
- `dart run tools/reset_plugin_cache.dart` script to reset the analysis server plugin cache during plugin development.

### Changed

- README restructured with anchor navigation, a rules table with status indicators, and a detailed per-rule reference section.
- Root library now includes setup documentation and exports a `version` constant.

## 0.0.1

### Added

- `no_final_local_variable`: enforce explicit non-final types for local variables.
