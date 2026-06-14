library;

import 'dart:io';

Future<bool> openExternalUrl(String url) async {
  try {
    if (Platform.isWindows) {
      final result = await Process.run('cmd', ['/c', 'start', '', url]);
      return result.exitCode == 0;
    }

    if (Platform.isMacOS) {
      final result = await Process.run('open', [url]);
      return result.exitCode == 0;
    }

    final result = await Process.run('xdg-open', [url]);
    return result.exitCode == 0;
  } catch (_) {
    return false;
  }
}