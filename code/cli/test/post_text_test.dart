import 'dart:io';

import 'package:post_publisher/modules/post/commands/text.dart';
import 'package:post_publisher/src/config_store.dart';
import 'package:post_publisher/src/linkedin_api.dart';
import 'package:test/test.dart';

void main() {
  test('post text validates that message is required', () {
    final command = PostTextCommand(PostTextInput());

    expect(command.validate(), contains('--message'));
  });

  test('post text fails when no token is cached', () async {
    final tempDir = Directory.systemTemp.createTempSync('post_publisher_post_');

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
          profile: LinkedInProfile(
            personId: 'member-id',
            personUrn: 'urn:li:person:member-id',
            name: 'Test Member',
          ),
        ),
      );

      final output = await PostTextCommand(
        PostTextInput(message: 'Hello Linkedind'),
        store: store,
        api: _FakePostsApi(),
      ).execute();

      expect(output.success, isFalse);
      expect(output.message, contains('linkedin auth login'));
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('post text fails when the cached token is expired', () async {
    final tempDir = Directory.systemTemp.createTempSync('post_publisher_post_');

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
          profile: const LinkedInProfile(
            personId: 'member-id',
            personUrn: 'urn:li:person:member-id',
            name: 'Test Member',
          ),
        ),
      );

      final output = await PostTextCommand(
        PostTextInput(message: 'Hello Linkedind'),
        store: store,
        api: _FakePostsApi(),
      ).execute();

      expect(output.success, isFalse);
      expect(output.message, contains('expired'));
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('post text creates a personal post and returns URN and URL', () async {
    final tempDir = Directory.systemTemp.createTempSync('post_publisher_post_');

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
          apiVersion: '202506',
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
      store.saveProjectConfigSync(
        const ProjectConfig(
          apiVersion: '202506',
          defaultVisibility: 'PUBLIC',
        ),
      );

      final api = _FakePostsApi(
        result: const LinkedInPostResult(
          postUrn: 'urn:li:share:1234567890',
          postUrl: 'https://www.linkedin.com/feed/update/urn:li:share:1234567890/',
        ),
      );

      final output = await PostTextCommand(
        PostTextInput(message: 'Hello Linkedind'),
        store: store,
        api: api,
      ).execute();

      expect(output.success, isTrue);
      expect(output.postUrn, 'urn:li:share:1234567890');
      expect(output.postUrl, 'https://www.linkedin.com/feed/update/urn:li:share:1234567890/');
      expect(api.receivedAccessToken, 'access-token');
      expect(api.receivedAuthorUrn, 'urn:li:person:member-id');
      expect(api.receivedMessage, 'Hello Linkedind');
      expect(api.receivedVisibility, 'PUBLIC');
      expect(api.receivedApiVersion, '202506');
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  });
}

class _FakePostsApi extends LinkedInApiClient {
  final LinkedInPostResult? result;
  String? receivedAccessToken;
  String? receivedAuthorUrn;
  String? receivedMessage;
  String? receivedVisibility;
  String? receivedApiVersion;

  _FakePostsApi({this.result});

  @override
  Future<LinkedInPostResult> createTextPost({
    required String accessToken,
    required String authorUrn,
    required String message,
    required String visibility,
    required String apiVersion,
  }) async {
    receivedAccessToken = accessToken;
    receivedAuthorUrn = authorUrn;
    receivedMessage = message;
    receivedVisibility = visibility;
    receivedApiVersion = apiVersion;

    return result ??
        const LinkedInPostResult(
          postUrn: 'urn:li:share:default',
          postUrl: 'https://www.linkedin.com/feed/update/urn:li:share:default/',
        );
  }
}