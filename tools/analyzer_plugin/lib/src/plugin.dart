import 'dart:async';

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer_plugin/plugin/plugin.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

import 'rule.dart';
import 'rules.dart';

class EnforcedLintsPlugin extends ServerPlugin {
  EnforcedLintsPlugin()
      : super(resourceProvider: PhysicalResourceProvider.INSTANCE);

  // SourceChanges are pre-built during analyzeFile while the session is fresh.
  // handleEditGetFixes just returns them — no session re-use needed.
  final Map<String, List<_StoredViolation>> _state = {};

  static final _generatedFile = RegExp(
    r'\.(g|freezed|mocks|gr)\.dart$',
  );

  @override
  String get name => 'enforced_lints';

  @override
  String get version => '1.0.0';

  @override
  List<String> get fileGlobsToAnalyze => const ['**/*.dart'];

  @override
  Future<void> analyzeFile({
    required AnalysisContext analysisContext,
    required String path,
  }) async {
    if (!path.endsWith('.dart')) return;

    if (_generatedFile.hasMatch(path)) {
      _state.remove(path);
      channel.sendNotification(AnalysisErrorsParams(path, []).toNotification());
      return;
    }

    try {
      final unit = await getResolvedUnitResult(path);
      final violations = <_StoredViolation>[];
      final errors = <AnalysisError>[];

      for (final rule in kRules) {
        final reporter = RuleReporter();
        rule.run(unit, reporter);

        for (final v in reporter.violations) {
          final location = _location(unit, v.offset, v.length);

          // Pre-build the SourceChange now while the session is fresh.
          // By the time handleEditGetFixes is called the session may be stale.
          SourceChange? sourceChange;
          if (v.fix != null) {
            try {
              final builder = ChangeBuilder(session: unit.session);
              await v.fix!.build(builder, unit);
              sourceChange = builder.sourceChange..message = v.fix!.message;
            } catch (_) {}
          }

          final error = AnalysisError(
            AnalysisErrorSeverity.INFO,
            AnalysisErrorType.LINT,
            location,
            rule.message,
            rule.code,
            correction: rule.correction,
            hasFix: sourceChange != null,
          );
          errors.add(error);
          violations.add(_StoredViolation(
            error: error,
            sourceChange: sourceChange,
            priority: v.fix?.priority ?? 80,
          ));
        }
      }

      _state[path] = violations;
      channel.sendNotification(AnalysisErrorsParams(path, errors).toNotification());
    } catch (_) {
      _state.remove(path);
      channel.sendNotification(AnalysisErrorsParams(path, []).toNotification());
    }
  }

  @override
  Future<EditGetFixesResult> handleEditGetFixes(
    EditGetFixesParams params,
  ) async {
    final path = params.file;
    final offset = params.offset;
    final violations = _state[path] ?? [];
    final fixes = <AnalysisErrorFixes>[];

    for (final sv in violations) {
      if (sv.sourceChange == null) continue;
      final errOffset = sv.error.location.offset;
      final errEnd = errOffset + sv.error.location.length;
      if (offset < errOffset || offset > errEnd) continue;

      final prioritized = [PrioritizedSourceChange(sv.priority, sv.sourceChange!)];

      // "Fix all in file" — only when there are other fixable violations.
      final fixable = violations
          .where((v) => v.error.code == sv.error.code && v.sourceChange != null)
          .toList();
      if (fixable.length > 1) {
        prioritized.add(PrioritizedSourceChange(
          sv.priority - 1,
          _mergeChanges(
            "Fix all '${sv.error.code}' in file",
            fixable.map((v) => v.sourceChange!).toList(),
          ),
        ));
      }

      fixes.add(AnalysisErrorFixes(sv.error, fixes: prioritized));
    }

    return EditGetFixesResult(fixes);
  }

  SourceChange _mergeChanges(String message, List<SourceChange> changes) {
    final combined = SourceChange(message);
    for (final change in changes) {
      for (final fileEdit in change.edits) {
        for (final edit in fileEdit.edits) {
          combined.addEdit(fileEdit.file, fileEdit.fileStamp, edit);
        }
      }
    }
    return combined;
  }

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
  final SourceChange? sourceChange;
  final int priority;

  const _StoredViolation({
    required this.error,
    required this.priority,
    this.sourceChange,
  });
}
