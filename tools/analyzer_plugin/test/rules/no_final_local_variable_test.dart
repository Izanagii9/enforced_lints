import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'package:enforced_lints_plugin/src/rule.dart';
import 'package:enforced_lints_plugin/src/rules/no_final_local_variable.dart';

// Temp files are written inside the project's .dart_tool directory to avoid
// Windows 8.3 short-name paths (e.g. GONCAL~1) that AnalysisContextCollection
// rejects as non-normalized.
final _tmpDir = Directory(
  p.join(Directory.current.path, '.dart_tool', 'test_tmp'),
);

Future<List<Violation>> analyze(String source) async {
  _tmpDir.createSync(recursive: true);

  final tmp = File(
    p.join(_tmpDir.path, 'test_${DateTime.now().microsecondsSinceEpoch}.dart'),
  );
  tmp.writeAsStringSync(source);
  addTearDown(() {
    if (tmp.existsSync()) tmp.deleteSync();
  });

  final collection = AnalysisContextCollection(includedPaths: [tmp.path]);
  final ctx = collection.contextFor(tmp.path);
  final result =
      await ctx.currentSession.getResolvedUnit(tmp.path) as ResolvedUnitResult;

  final reporter = RuleReporter();
  NoFinalLocalVariable().run(result, reporter);
  return reporter.violations;
}

void main() {
  group('NoFinalLocalVariable rule processes final local variables correctly',
      () {
    test('final local variable with an explicit type reports one violation',
        () async {
      final violations = await analyze('void f() { final int x = 5; }');
      expect(violations, hasLength(1));
    });

    test('final local variable without a type annotation reports one violation',
        () async {
      final violations = await analyze('void f() { final x = 5; }');
      expect(violations, hasLength(1));
    });

    test(
      'final local variable with an explicit type offers a remove-final quick fix',
      () async {
        final violations = await analyze('void f() { final int x = 5; }');
        expect(violations.single.fix, isNotNull);
        expect(violations.single.fix!.message, contains("Remove 'final'"));
      },
    );

    test(
      'final local variable without a type annotation offers a replace-keyword quick fix with the inferred type name',
      () async {
        final violations = await analyze('void f() { final x = 5; }');
        expect(violations.single.fix, isNotNull);
        expect(
          violations.single.fix!.message,
          contains("Replace 'final' with 'int'"),
        );
      },
    );

    test(
      'multiple final local variables in the same function each report a violation',
      () async {
        final violations = await analyze('''
void f() {
  final int a = 1;
  final int b = 2;
  final c = 3;
}
''');
        expect(violations, hasLength(3));
      },
    );

    test('class-level final field does not report any violations', () async {
      final violations = await analyze('class A { final int x = 5; }');
      expect(violations, isEmpty);
    });

    test('top-level final variable does not report any violations', () async {
      final violations = await analyze('final int x = 5;');
      expect(violations, isEmpty);
    });

    test('static final field does not report any violations', () async {
      final violations = await analyze('class A { static final int x = 5; }');
      expect(violations, isEmpty);
    });
  });

  group(
      'NoFinalLocalVariable rule processes var-declared local variables correctly',
      () {
    test('var-declared local variable reports one violation', () async {
      final violations = await analyze('void f() { var x = 5; }');
      expect(violations, hasLength(1));
    });

    test('var variable in a for-loop initializer reports one violation',
        () async {
      final violations = await analyze(
        'void f() { for (var i = 0; i < 3; i++) {} }',
      );
      expect(violations, hasLength(1));
    });

    test(
      'var variable with an inferrable type offers a replace-keyword quick fix with the inferred type name',
      () async {
        final violations = await analyze('void f() { var x = 5; }');
        expect(violations.single.fix, isNotNull);
        expect(
          violations.single.fix!.message,
          contains("Replace 'var' with 'int'"),
        );
      },
    );

    test(
      'var variable resolving to dynamic does not offer any quick fix',
      () async {
        final violations = await analyze('void f() { var x; }');
        expect(violations.single.fix, isNull);
      },
    );

    test(
      'multiple var-declared local variables in the same function each report a violation',
      () async {
        final violations = await analyze('''
void f() {
  var a = 1;
  var b = 'hello';
  var c = true;
}
''');
        expect(violations, hasLength(3));
      },
    );
  });

  group(
    'NoFinalLocalVariable rule processes mixed final and var local variable declarations correctly',
    () {
      test(
        'mixed final and var declarations in the same function each report one violation',
        () async {
          final violations = await analyze('''
void f() {
  final int a = 1;
  var b = 2;
  final c = 3;
}
''');
          expect(violations, hasLength(3));
        },
      );

      test(
        'mixed final and var declarations in the same function each offer their respective quick fixes',
        () async {
          final violations = await analyze('''
void f() {
  final int a = 1;
  var b = 2;
  final c = 3;
}
''');
          expect(violations[0].fix!.message, contains("Remove 'final'"));
          expect(
              violations[1].fix!.message, contains("Replace 'var' with 'int'"));
          expect(violations[2].fix!.message,
              contains("Replace 'final' with 'int'"));
        },
      );
    },
  );
}
