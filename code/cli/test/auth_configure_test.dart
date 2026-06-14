import 'dart:io';

import 'package:post_publisher/modules/auth/commands/configure.dart';
import 'package:post_publisher/src/config_store.dart';
import 'package:test/test.dart';

void main() {
  test('auth configure saves the provided credentials and required scopes', () async {
    final tempDir = Directory.systemTemp.createTempSync('post_publisher_config_');

    try {
      final store = ConfigStore(configHome: tempDir.path, workingDirectory: tempDir.path);
      final command = AuthConfigureCommand(
        AuthConfigureInput(
          clientId: 'client-id',
          clientSecret: 'client-secret',
          redirectUri: 'http://127.0.0.1:8787/callback',
          scopes: 'openid profile email w_member_social',
          apiVersion: '202506',
        ),
        store: store,
      );

      final output = await command.execute();
      final config = store.loadUserConfigSync();

      expect(output.message, contains(store.userConfigPath));
      expect(config.clientId, 'client-id');
      expect(config.clientSecret, 'client-secret');
      expect(config.redirectUri, 'http://127.0.0.1:8787/callback');
      expect(config.scopes, containsAll(['openid', 'profile', 'w_member_social']));
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  });
}