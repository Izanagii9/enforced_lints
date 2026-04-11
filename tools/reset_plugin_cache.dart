/// Deletes the Dart analysis server plugin cache so the next IDE startup
/// picks up the latest plugin build instead of a stale copy.
///
/// The analysis server copies every plugin to:
///   ~/.dartServer/.plugin_manager/   (macOS / Linux)
///   %USERPROFILE%\.dartServer\.plugin_manager\   (Windows)
///
/// It only re-copies when the package version changes. During development,
/// where the version stays fixed, deleting this directory is the only
/// reliable way to force a fresh copy.
///
/// Usage:
///   dart run tool/reset_plugin_cache.dart
///
/// After running: restart your IDE or trigger
/// "Dart: Restart Analysis Server" from the command palette.
import 'dart:io';

void main() {
  final home = _homeDir();
  if (home == null) {
    stderr.writeln('Could not determine home directory. '
        'Set HOME (Unix) or USERPROFILE (Windows) and retry.');
    exitCode = 1;
    return;
  }

  final cacheDir = Directory('$home/.dartServer/.plugin_manager');

  if (!cacheDir.existsSync()) {
    print('Nothing to delete — cache directory does not exist:');
    print('  ${cacheDir.path}');
    return;
  }

  cacheDir.deleteSync(recursive: true);
  print('Deleted plugin cache: ${cacheDir.path}');
  print('');
  print('Next step: restart your IDE or run '
      '"Dart: Restart Analysis Server".');
}

String? _homeDir() {
  if (Platform.isWindows) {
    return Platform.environment['USERPROFILE'];
  }
  return Platform.environment['HOME'];
}
