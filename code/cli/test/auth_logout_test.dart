import 'dart:io';

import 'package:post_publisher/modules/auth/commands/logout.dart';
import 'package:post_publisher/src/config_store.dart';
import 'package:test/test.dart';

void main() {
  test('auth logout clears session state but preserves app credentials', () async {
    final tempDir = Directory.systemTemp.createTempSync('post_publisher_logout_');

    try {
      final store = ConfigStore(
        configHome: tempDir.path,
        workingDirectory: tempDir.path,
      );
      store.saveUserConfigSync(
        UserConfig(
          clientId: 'client-id',
          clientSecret: 'client-secret',
          redirectUri: 'http://127.0.0.1:8787/callback',
          scopes: defaultScopes,
          token: LinkedInToken(
            accessToken: 'access-token',
            expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
          ),
          profile: const LinkedInProfile(
            personId: 'member-id',
            personUrn: 'urn:li:person:member-id',
            name: 'Test Member',
          ),
        ),
      );

      final output = await AuthLogoutCommand(
        AuthLogoutInput(),
        store: store,
      ).execute();
      final savedConfig = store.loadUserConfigSync();

      expect(output.message, contains('Removed the cached LinkedIn token.'));
      expect(savedConfig.clientId, 'client-id');
      expect(savedConfig.clientSecret, 'client-secret');
      expect(savedConfig.redirectUri, 'http://127.0.0.1:8787/callback');
      expect(savedConfig.token, isNull);
      expect(savedConfig.profile, isNull);
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  });
}