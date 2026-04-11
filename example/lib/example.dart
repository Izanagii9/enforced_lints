// This file shows how enforced_lints integrates with a Dart project.
// Once the plugin is active, violations are highlighted directly in the IDE.

// ─── Flagged by enforced_lints ────────────────────────────────────────────────
//
//   final int a = 1;      ← no_final_local_variable: final not allowed
//   var b = 2;            ← no_final_local_variable: var not allowed
//   final items = [];     ← no_final_local_variable: final + implicit type
//
// ─── Correct patterns ─────────────────────────────────────────────────────────

void demonstrateCorrectUsage() {
  int count = 0;
  String name = 'Alice';
  List<String> items = [];

  print('$count $name $items');
}
