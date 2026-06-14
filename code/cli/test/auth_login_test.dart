import 'dart:io';

import 'package:post_publisher/modules/auth/commands/login.dart';
import 'package:post_publisher/src/config_store.dart';
import 'package:post_publisher/src/linkedin_api.dart';
import 'package:post_publisher/src/oauth.dart';
import 'package:test/test.dart';

void main() {
  test('auth login fails when credentials are missing', () async {
    final tempDir = Directory.systemTemp.createTempSync('post_publisher_login_');

    try {
      final store = ConfigStore(
        configHome: tempDir.path,
        workingDirectory: tempDir.path,
      );

      final output = await AuthLoginCommand(
        AuthLoginInput(noOpen: true),
        store: store,
      ).execute();

      expect(output.success, isFalse);
      expect(output.message, contains('linkedin auth configure'));
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('auth login rejects a mismatched state value', () async {
    final tempDir = Directory.systemTemp.createTempSync('post_publisher_login_');

    try {
      final store = ConfigStore(
        configHome: tempDir.path,
        workingDirectory: tempDir.path,
      );
      store.saveUserConfigSync(
        const UserConfig(
          clientId: 'client-id',
          clientSecret: 'client-secret',
          redirectUri: 'http://127.0.0.1:8787/callback',
          scopes: defaultScopes,
        ),
      );

      final output = await AuthLoginCommand(
        AuthLoginInput(
          noOpen: true,
          responseUrl:
              'http://127.0.0.1:8787/callback?code=auth-code&state=wrong-state',
        ),
        store: store,
        api: _FakeLinkedInApiClient(),
        requestBuilder: (_) => OAuthRequest(
          authorizationUri: Uri.parse('https://www.linkedin.com/oauth/v2/authorization'),
          state: 'expected-state',
        ),
      ).execute();

      expect(output.success, isFalse);
      expect(output.message, contains('unexpected state'));
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('auth login stores token and profile on success', () async {
    final tempDir = Directory.systemTemp.createTempSync('post_publisher_login_');

    try {
      final store = ConfigStore(
        configHome: tempDir.path,
        workingDirectory: tempDir.path,
      );
      store.saveUserConfigSync(
        const UserConfig(
          clientId: 'client-id',
          clientSecret: 'client-secret',
          redirectUri: 'http://127.0.0.1:8787/callback',
          scopes: defaultScopes,
        ),
      );

      final api = _FakeLinkedInApiClient(
        token: LinkedInToken(
          accessToken: 'access-token',
          expiresAt: DateTime.utc(2030, 1, 1),
          scope: 'openid profile email w_member_social',
          idToken: 'id-token',
        ),
        profile: const LinkedInProfile(
          personId: 'member-id',
          personUrn: 'urn:li:person:member-id',
          name: 'Test Member',
          email: 'test@example.com',
        ),
      );

      final output = await AuthLoginCommand(
        AuthLoginInput(
          noOpen: true,
          responseUrl:
              'http://127.0.0.1:8787/callback?code=auth-code&state=expected-state',
        ),
        store: store,
        api: api,
        requestBuilder: (_) => OAuthRequest(
          authorizationUri: Uri.parse('https://www.linkedin.com/oauth/v2/authorization'),
          state: 'expected-state',
        ),
      ).execute();

      final savedConfig = store.loadUserConfigSync();

      expect(output.success, isTrue);
      expect(output.message, contains('Test Member'));
      expect(api.receivedCode, 'auth-code');
      expect(savedConfig.token?.accessToken, 'access-token');
      expect(savedConfig.profile?.personUrn, 'urn:li:person:member-id');
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  });
}

class _FakeLinkedInApiClient extends LinkedInApiClient {
  final LinkedInToken? token;
  final LinkedInProfile? profile;
  String? receivedCode;

  _FakeLinkedInApiClient({this.token, this.profile});

  @override
  Future<LinkedInToken> exchangeAuthorizationCode({
    required UserConfig config,
    required String code,
  }) async {
    receivedCode = code;
    return token ??
        LinkedInToken(
          accessToken: 'default-access-token',
          expiresAt: DateTime.utc(2030, 1, 1),
        );
  }

  @override
  Future<LinkedInProfile> fetchProfile(String accessToken) async {
    return profile ??
        const LinkedInProfile(
          personId: 'default-member-id',
          personUrn: 'urn:li:person:default-member-id',
          name: 'Default Member',
        );
  }
}