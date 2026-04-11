// This file demonstrates violations caught by enforced_lints.
// With the plugin active, the lines below will be flagged in the IDE.

void demonstrateViolations() {
  // violation: `final` on a local variable
  // ignore: no_final_local_variable
  final int a = 1;

  // violation: implicit typing via `var`
  // ignore: no_final_local_variable
  var b = 2;

  // OK: explicit non-final type
  int c = 3;

  print('$a $b $c');
}
