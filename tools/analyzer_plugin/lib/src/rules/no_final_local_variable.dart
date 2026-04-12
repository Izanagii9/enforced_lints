import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:enforced_lints_plugin/src/rule.dart';


class NoFinalLocalVariable extends DartRule {
  const NoFinalLocalVariable();

  @override
  String get code => 'no_final_local_variable';

  @override
  String get message => 'Local variables must use explicit, non-final types. '
      'Avoid `final` and implicit typing (`var`).';

  @override
  String get correction =>
      'Use an explicit type without `final`, e.g. `int x = 5;`.';

  @override
  void run(ResolvedUnitResult unit, RuleReporter reporter) {
    unit.unit.visitChildren(_Visitor(reporter));
  }
}

class _Visitor extends RecursiveAstVisitor<void> {
  final RuleReporter _reporter;

  _Visitor(this._reporter);

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    super.visitVariableDeclarationList(node);

    // Only flag local variables (inside statements or for-loops).
    final parent = node.parent;
    if (parent is! VariableDeclarationStatement &&
        parent is! ForPartsWithDeclarations) {
      return;
    }

    // If it already has an explicit non-final type, it's correct.
    if (!node.isFinal && node.type != null) return;

    final Token? keyword = node.keyword;
    if (keyword == null) {
      return;
    }

    final TypeAnnotation? typeAnnotation = node.type;

    RuleFix? fix;

    if (typeAnnotation != null) {
      // `final int x = 5` → remove `final `
      fix = RuleFix("Remove 'final'", (builder, unit) async {
        await builder.addDartFileEdit(unit.path, (edit) {
          final deleteLength = typeAnnotation.offset - keyword.offset;
          edit.addDeletion(SourceRange(keyword.offset, deleteLength));
        });
      });
    } else {
      // `var x = 5` or `final x = 5` → replace keyword with inferred type
      final staticType = node.variables.first.declaredFragment?.element.type;
      if (staticType != null && staticType is! DynamicType) {
        final typeName = staticType.getDisplayString();
        fix = RuleFix("Replace '${keyword.lexeme}' with '$typeName'",
            (builder, unit) async {
          await builder.addDartFileEdit(unit.path, (edit) {
            edit.addSimpleReplacement(
              SourceRange(keyword.offset, keyword.length),
              typeName,
            );
          });
        });
      }
    }

    _reporter.reportAtNode(node, fix: fix);
  }
}
