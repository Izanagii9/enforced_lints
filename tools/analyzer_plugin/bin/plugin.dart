import 'dart:isolate';

import 'package:analyzer_plugin/starter.dart';
import 'package:enforced_lints_plugin/src/plugin.dart';

void main(List<String> args, SendPort sendPort) {
  ServerPluginStarter(EnforcedLintsPlugin()).start(sendPort);
}
