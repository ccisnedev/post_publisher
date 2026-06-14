import 'dart:io';

import 'package:post_publisher/modules/global/commands/init.dart';
import 'package:test/test.dart';

void main() {
  test('init creates project config in the working directory', () async {
    final tempDir = Directory.systemTemp.createTempSync('post_publisher_init_');

    try {
      final output = await InitCommand(
        InitInput(workingDirectory: tempDir.path),
      ).execute();

      expect(output.created, isTrue);
      expect(
        File('${tempDir.path}${Platform.pathSeparator}.post_publisher${Platform.pathSeparator}config.json').existsSync(),
        isTrue,
      );
      expect(
        File('${tempDir.path}${Platform.pathSeparator}.gitignore').existsSync(),
        isTrue,
      );
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  });
}