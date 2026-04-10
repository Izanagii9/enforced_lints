import 'dart:async';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

/// Callback that populates a [ChangeBuilder] with the edits for a fix.
typedef BuildFix = FutureOr<void> Function(
  ChangeBuilder builder,
  ResolvedUnitResult unit,
);

/// A quick-fix associated with a [DartRule] violation.
class RuleFix {
  final String message;
  final int priority;
  final BuildFix build;

  const RuleFix(this.message, this.build, {this.priority = 80});
}

/// A recorded violation produced by [RuleReporter].
class Violation {
  final int offset;
  final int length;
  final RuleFix? fix;

  const Violation({required this.offset, required this.length, this.fix});
}

/// Collects violations during a rule run.
class RuleReporter {
  final List<Violation> _violations = [];

  void reportAtNode(AstNode node, {RuleFix? fix}) {
    _violations.add(
      Violation(offset: node.offset, length: node.length, fix: fix),
    );
  }

  List<Violation> get violations => List.unmodifiable(_violations);
}

/// Base class for all custom lint rules.
///
/// To add a new rule:
///   1. Create a file in `lib/src/rules/my_rule.dart` extending [DartRule].
///   2. Add `MyRule()` to the list in `lib/src/rules.dart`.
abstract class DartRule {
  const DartRule();

  /// Unique lint code shown in the IDE (e.g. `no_final_local_variable`).
  String get code;

  /// Human-readable problem message.
  String get message;

  /// Correction hint shown alongside the problem.
  String get correction;

  /// Inspect [unit] and call [reporter] for each violation found.
  void run(ResolvedUnitResult unit, RuleReporter reporter);
}
