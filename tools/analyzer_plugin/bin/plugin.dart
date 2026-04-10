import 'dart:isolate';

import 'package:analyzer_plugin/starter.dart';
import '../lib/src/plugin.dart';

void main(List<String> args, SendPort sendPort) {
  ServerPluginStarter(EnforcedLintsPlugin()).start(sendPort);
}
