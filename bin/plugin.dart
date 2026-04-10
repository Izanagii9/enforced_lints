import 'dart:isolate';

import 'package:analyzer_plugin/starter.dart';

import 'package:bhealth_lint/src/plugin.dart';

void main(List<String> args, SendPort sendPort) {
  ServerPluginStarter(BhealthPlugin()).start(sendPort);
}
