import 'rule.dart';
import 'rules/no_final_local_variable.dart';

/// All active lint rules.
///
/// To add a new rule, create a file in `lib/src/rules/` and add one line here.
const List<DartRule> kRules = [
  NoFinalLocalVariable(),
];
