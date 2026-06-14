import 'dart:io';

import 'package:post_publisher/modules/post/commands/document.dart';
import 'package:post_publisher/modules/post/commands/image.dart';
import 'package:post_publisher/src/config_store.dart';
import 'package:post_publisher/src/linkedin_api.dart';
import 'package:test/test.dart';

void main() {
  test('post image validates that the file exists', () {
    final command = PostImageCommand(
      PostImageInput(filePath: 'missing.png', message: 'Hello Linkedind'),
    );

    expect(command.validate(), contains('does not exist'));
  });

  test('post document validates that the file is a pdf', () {
    final tempDir = Directory.systemTemp.createTempSync('post_publisher_media_');

    try {
      final textFile = File('${tempDir.path}${Platform.pathSeparator}notes.txt')
        ..writeAsStringSync('hello');

      final command = PostDocumentCommand(
        PostDocumentInput(filePath: textFile.path, message: 'Hello Linkedind'),
      );

      expect(command.validate(), contains('PDF'));
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('post image delegates to the API client with the authenticated member', () async {
    final tempDir = Directory.systemTemp.createTempSync('post_publisher_media_');

    try {
      final imageFile = File('${tempDir.path}${Platform.pathSeparator}hello.png')
        ..writeAsBytesSync(const [1, 2, 3]);

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

      final api = _FakeMediaApi();
      final output = await PostImageCommand(
        PostImageInput(filePath: imageFile.path, message: 'Hello Linkedind'),
        store: store,
        api: api,
      ).execute();

      expect(output.success, isTrue);
      expect(api.imageFilePath, imageFile.path);
      expect(api.authorUrn, 'urn:li:person:member-id');
      expect(api.message, 'Hello Linkedind');
      expect(api.apiVersion, '202506');
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('post document delegates to the API client with a derived title', () async {
    final tempDir = Directory.systemTemp.createTempSync('post_publisher_media_');

    try {
      final pdfFile = File('${tempDir.path}${Platform.pathSeparator}hello.pdf')
        ..writeAsBytesSync(const [1, 2, 3]);

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

      final api = _FakeMediaApi();
      final output = await PostDocumentCommand(
        PostDocumentInput(filePath: pdfFile.path, message: 'Hello Linkedind'),
        store: store,
        api: api,
      ).execute();

      expect(output.success, isTrue);
      expect(api.documentFilePath, pdfFile.path);
      expect(api.documentTitle, 'hello.pdf');
      expect(api.authorUrn, 'urn:li:person:member-id');
      expect(api.message, 'Hello Linkedind');
      expect(api.apiVersion, '202506');
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  });
}

class _FakeMediaApi extends LinkedInApiClient {
  String? imageFilePath;
  String? documentFilePath;
  String? documentTitle;
  String? authorUrn;
  String? message;
  String? apiVersion;

  @override
  Future<LinkedInPostResult> createImagePost({
    required String accessToken,
    required String authorUrn,
    required String filePath,
    required String message,
    required String visibility,
    required String apiVersion,
    String? altText,
  }) async {
    imageFilePath = filePath;
    this.authorUrn = authorUrn;
    this.message = message;
    this.apiVersion = apiVersion;
    return const LinkedInPostResult(postUrn: 'urn:li:share:image');
  }

  @override
  Future<LinkedInPostResult> createDocumentPost({
    required String accessToken,
    required String authorUrn,
    required String filePath,
    required String title,
    required String message,
    required String visibility,
    required String apiVersion,
  }) async {
    documentFilePath = filePath;
    documentTitle = title;
    this.authorUrn = authorUrn;
    this.message = message;
    this.apiVersion = apiVersion;
    return const LinkedInPostResult(postUrn: 'urn:li:share:document');
  }
}