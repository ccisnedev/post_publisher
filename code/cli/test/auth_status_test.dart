import 'dart:io';

import 'package:post_publisher/modules/auth/commands/status.dart';
import 'package:post_publisher/src/config_store.dart';
import 'package:test/test.dart';

void main() {
  test('auth status reports resolved member and valid token', () async {
    final tempDir = Directory.systemTemp.createTempSync('post_publisher_status_');

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
            email: 'test@example.com',
          ),
        ),
      );

      final output = await AuthStatusCommand(
        AuthStatusInput(),
        store: store,
      ).execute();

      expect(output.text, contains('Configured: yes'));
      expect(output.text, contains('Member: Test Member'));
      expect(output.text, contains('Person URN: urn:li:person:member-id'));
      expect(output.text, contains('Token: valid until'));
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('auth status reports an expired token', () async {
    final tempDir = Directory.systemTemp.createTempSync('post_publisher_status_');

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
            expiresAt: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
          ),
        ),
      );

      final output = await AuthStatusCommand(
        AuthStatusInput(),
        store: store,
      ).execute();

      expect(output.text, contains('Token: expired at'));
      expect(output.text, contains('Member: (not resolved yet)'));
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  });
}