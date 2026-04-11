import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:test/test.dart';

import 'package:enforced_lints_plugin/src/rule.dart';
import 'package:enforced_lints_plugin/src/rules/no_final_local_variable.dart';

void main() {
  Future<List<Violation>> analyze(String source) async {
    final tmp = File(
      '${Directory.systemTemp.path}/test_nflv_${DateTime.now().microsecondsSinceEpoch}.dart',
    );
    tmp.writeAsStringSync(source);
    addTearDown(tmp.deleteSync);

    final collection = AnalysisContextCollection(includedPaths: [tmp.path]);
    final ctx = collection.contextFor(tmp.path);
    final result =
        await ctx.currentSession.getResolvedUnit(tmp.path) as ResolvedUnitResult;

    final reporter = RuleReporter();
    NoFinalLocalVariable().run(result, reporter);
    return reporter.violations;
  }

  group('NoFinalLocalVariable', () {
    group('violations', () {
      test('flags final with explicit type', () async {
        final violations = await analyze('void f() { final int x = 5; }');
        expect(violations, hasLength(1));
      });

      test('flags var', () async {
        final violations = await analyze('void f() { var x = 5; }');
        expect(violations, hasLength(1));
      });

      test('flags final without type', () async {
        final violations = await analyze('void f() { final x = 5; }');
        expect(violations, hasLength(1));
      });

      test('flags variable inside for loop initializer', () async {
        final violations = await analyze(
          'void f() { for (var i = 0; i < 3; i++) {} }',
        );
        expect(violations, hasLength(1));
      });

      test('reports multiple violations in one function', () async {
        final violations = await analyze('''
void f() {
  final int a = 1;
  var b = 2;
  final c = 3;
}
''');
        expect(violations, hasLength(3));
      });
    });

    group('allowed cases', () {
      test('allows explicit non-final type', () async {
        final violations = await analyze('void f() { int x = 5; }');
        expect(violations, isEmpty);
      });

      test('does not flag class-level final fields', () async {
        final violations = await analyze('class A { final int x = 5; }');
        expect(violations, isEmpty);
      });

      test('does not flag top-level final variables', () async {
        final violations = await analyze('final int x = 5;');
        expect(violations, isEmpty);
      });

      test('does not flag static final fields', () async {
        final violations =
            await analyze('class A { static final int x = 5; }');
        expect(violations, isEmpty);
      });
    });

    group('fixes', () {
      test('provides fix for final with explicit type', () async {
        final violations = await analyze('void f() { final int x = 5; }');
        expect(violations.single.fix, isNotNull);
        expect(violations.single.fix!.message, contains("Remove 'final'"));
      });

      test('provides fix for var with inferrable type', () async {
        final violations = await analyze('void f() { var x = 5; }');
        expect(violations.single.fix, isNotNull);
        expect(
          violations.single.fix!.message,
          contains("Replace 'var' with 'int'"),
        );
      });

      test('provides no fix when type is dynamic', () async {
        final violations = await analyze('void f() { var x; }');
        // dynamic / uninitialized — fix cannot infer a type
        expect(violations.single.fix, isNull);
      });
    });
  });
}
