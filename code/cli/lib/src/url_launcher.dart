library;

import 'dart:io';

Future<bool> openExternalUrl(String url) async {
  try {
    if (Platform.isWindows) {
      // Use rundll32 instead of `cmd /c start` because the URL contains `&`
      // (OAuth query separators) and cmd.exe would treat them as command
      // separators. rundll32 receives the URL as a single argument.
      final result = await Process.run(
        'rundll32',
        ['url.dll,FileProtocolHandler', url],
      );
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