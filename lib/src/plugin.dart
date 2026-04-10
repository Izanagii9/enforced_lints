import 'dart:async';
import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer_plugin/plugin/plugin.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

import 'rule.dart';
import 'rules.dart';

final _logFile = File(
  r'C:\BYME\SOLUTIONS\bhealthmobile\custom_lints\logs\boot.log',
);

void _debug(String msg) {
  _logFile.writeAsStringSync(
    '[${DateTime.now().toIso8601String()}] $msg\n',
    mode: FileMode.append,
    flush: true,
  );
}

class BhealthPlugin extends ServerPlugin {
  BhealthPlugin()
      : super(resourceProvider: PhysicalResourceProvider.INSTANCE) {
    _debug('BhealthPlugin() constructed');
  }

  // Violations per file path — kept so that handleEditGetFixes can look up fixes.
  final Map<String, List<_StoredViolation>> _violations = {};

  static final _generatedFile = RegExp(
    r'\.(g|freezed|mocks|gr)\.dart$',
  );

  // ---------------------------------------------------------------------------
  // ServerPlugin contract
  // ---------------------------------------------------------------------------

  @override
  String get name => 'bhealth_lint';

  @override
  String get version => '1.0.0';

  @override
  List<String> get fileGlobsToAnalyze => const ['**/*.dart'];

  @override
  void start(dynamic channel) {
    _debug('BhealthPlugin.start() called');
    super.start(channel);
  }

  // ---------------------------------------------------------------------------
  // Analysis
  // ---------------------------------------------------------------------------

  @override
  Future<void> analyzeFile({
    required AnalysisContext analysisContext,
    required String path,
  }) async {
    _debug('analyzeFile: $path');
    if (!path.endsWith('.dart')) return;

    // Clear any stale data and send an empty error list for generated files.
    if (_generatedFile.hasMatch(path)) {
      _violations.remove(path);
      channel.sendNotification(
        AnalysisErrorsParams(path, []).toNotification(),
      );
      return;
    }

    try {
      final unit = await getResolvedUnitResult(path);
      final stored = <_StoredViolation>[];
      final errors = <AnalysisError>[];

      for (final rule in kRules) {
        final reporter = RuleReporter();
        rule.run(unit, reporter);

        for (final v in reporter.violations) {
          final location = _location(unit, v.offset, v.length);
          final error = AnalysisError(
            AnalysisErrorSeverity.WARNING,
            AnalysisErrorType.LINT,
            location,
            rule.message,
            rule.code,
            correction: rule.correction,
            hasFix: v.fix != null,
          );
          errors.add(error);
          stored.add(_StoredViolation(error: error, fix: v.fix));
        }
      }

      _debug('analyzeFile: ${errors.length} errors found in $path');
      _violations[path] = stored;
      channel.sendNotification(
        AnalysisErrorsParams(path, errors).toNotification(),
      );
    } catch (e, st) {
      _debug('analyzeFile ERROR for $path: $e\n$st');
      _violations.remove(path);
      channel.sendNotification(
        AnalysisErrorsParams(path, []).toNotification(),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Quick fixes
  // ---------------------------------------------------------------------------

  @override
  Future<EditGetFixesResult> handleEditGetFixes(
    EditGetFixesParams params,
  ) async {
    final path = params.file;
    final offset = params.offset;
    final stored = _violations[path] ?? [];
    final fixes = <AnalysisErrorFixes>[];

    for (final sv in stored) {
      final errOffset = sv.error.location.offset;
      final errEnd = errOffset + sv.error.location.length;
      if (offset < errOffset || offset > errEnd) continue;
      if (sv.fix == null) continue;

      ResolvedUnitResult unit;
      try {
        unit = await getResolvedUnitResult(path);
      } catch (_) {
        continue;
      }

      final builder = ChangeBuilder(session: unit.session);
      await sv.fix!.build(builder, unit);
      final change = builder.sourceChange
        ..message = sv.fix!.message;

      fixes.add(
        AnalysisErrorFixes(
          sv.error,
          fixes: [PrioritizedSourceChange(sv.fix!.priority, change)],
        ),
      );
    }

    return EditGetFixesResult(fixes);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Location _location(ResolvedUnitResult unit, int offset, int length) {
    final info = unit.lineInfo;
    final start = info.getLocation(offset);
    final end = info.getLocation(offset + length);
    return Location(
      unit.path,
      offset,
      length,
      start.lineNumber,
      start.columnNumber,
      endLine: end.lineNumber,
      endColumn: end.columnNumber,
    );
  }
}

class _StoredViolation {
  final AnalysisError error;
  final RuleFix? fix;

  const _StoredViolation({required this.error, this.fix});
}
