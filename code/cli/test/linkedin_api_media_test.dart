import 'dart:convert';
import 'dart:io';

import 'package:post_publisher/src/linkedin_api.dart';
import 'package:test/test.dart';

void main() {
  test('createImagePost initializes upload, uploads the file, and creates a post', () async {
    final tempDir = Directory.systemTemp.createTempSync('post_publisher_api_');
    final imageFile = File('${tempDir.path}${Platform.pathSeparator}hello.png')
      ..writeAsBytesSync(const [1, 2, 3, 4]);

    final state = _ServerState();
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);

    server.listen((request) async {
      if (request.uri.path == '/rest/images' &&
          request.uri.queryParameters['action'] == 'initializeUpload') {
        state.initializeImageAuth = request.headers.value(HttpHeaders.authorizationHeader);
        state.initializeImageVersion = request.headers.value('LinkedIn-Version');
        state.initializeImageProtocol = request.headers.value('X-Restli-Protocol-Version');
        state.initializeImageBody = await utf8.decoder.bind(request).join();

        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({
            'value': {
              'uploadUrl': 'http://127.0.0.1:${server.port}/upload/image',
              'image': 'urn:li:image:123',
            },
          }),
        );
        await request.response.close();
        return;
      }

      if (request.uri.path == '/upload/image') {
        state.imageUploadAuth = request.headers.value(HttpHeaders.authorizationHeader);
        state.imageUploadContentType = request.headers.contentType?.mimeType;
        state.imageUploadBytes = await request.fold<List<int>>(
          <int>[],
          (bytes, chunk) => bytes..addAll(chunk),
        );
        request.response.statusCode = 201;
        await request.response.close();
        return;
      }

      if (request.uri.path == '/rest/posts') {
        state.createPostAuth = request.headers.value(HttpHeaders.authorizationHeader);
        state.createPostVersion = request.headers.value('LinkedIn-Version');
        state.createPostProtocol = request.headers.value('X-Restli-Protocol-Version');
        state.createPostBody = await utf8.decoder.bind(request).join();
        request.response.statusCode = 201;
        request.response.headers.set('x-restli-id', 'urn:li:share:image-post');
        await request.response.close();
        return;
      }

      request.response.statusCode = 404;
      await request.response.close();
    });

    try {
      final client = LinkedInApiClient(
        apiBaseUri: Uri.parse('http://127.0.0.1:${server.port}'),
      );

      final result = await client.createImagePost(
        accessToken: 'access-token',
        authorUrn: 'urn:li:person:member-id',
        filePath: imageFile.path,
        message: 'Hello Linkedind',
        visibility: 'PUBLIC',
        apiVersion: '202506',
        altText: 'Example alt text',
      );

      expect(result.postUrn, 'urn:li:share:image-post');
      expect(result.postUrl, 'https://www.linkedin.com/feed/update/urn:li:share:image-post/');
      expect(state.initializeImageAuth, 'Bearer access-token');
      expect(state.initializeImageVersion, '202506');
      expect(state.initializeImageProtocol, '2.0.0');
      expect(state.initializeImageBody, contains('urn:li:person:member-id'));
      expect(state.imageUploadAuth, 'Bearer access-token');
      expect(state.imageUploadContentType, 'image/png');
      expect(state.imageUploadBytes, [1, 2, 3, 4]);
      expect(state.createPostAuth, 'Bearer access-token');
      expect(state.createPostVersion, '202506');
      expect(state.createPostProtocol, '2.0.0');
      expect(state.createPostBody, contains('urn:li:image:123'));
      expect(state.createPostBody, contains('Example alt text'));
      expect(state.createPostBody, contains('Hello Linkedind'));
    } finally {
      await server.close(force: true);
      tempDir.deleteSync(recursive: true);
    }
  });

  test('createDocumentPost initializes upload, uploads the pdf, and creates a post', () async {
    final tempDir = Directory.systemTemp.createTempSync('post_publisher_api_');
    final pdfFile = File('${tempDir.path}${Platform.pathSeparator}hello.pdf')
      ..writeAsBytesSync(const [9, 8, 7, 6]);

    final state = _ServerState();
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);

    server.listen((request) async {
      if (request.uri.path == '/rest/documents' &&
          request.uri.queryParameters['action'] == 'initializeUpload') {
        state.initializeDocumentAuth = request.headers.value(HttpHeaders.authorizationHeader);
        state.initializeDocumentVersion = request.headers.value('LinkedIn-Version');
        state.initializeDocumentProtocol = request.headers.value('X-Restli-Protocol-Version');
        state.initializeDocumentBody = await utf8.decoder.bind(request).join();

        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({
            'value': {
              'uploadUrl': 'http://127.0.0.1:${server.port}/upload/document',
              'document': 'urn:li:document:123',
            },
          }),
        );
        await request.response.close();
        return;
      }

      if (request.uri.path == '/upload/document') {
        state.documentUploadAuth = request.headers.value(HttpHeaders.authorizationHeader);
        state.documentUploadContentType = request.headers.contentType?.mimeType;
        state.documentUploadBytes = await request.fold<List<int>>(
          <int>[],
          (bytes, chunk) => bytes..addAll(chunk),
        );
        request.response.statusCode = 201;
        await request.response.close();
        return;
      }

      if (request.uri.path == '/rest/posts') {
        state.createPostAuth = request.headers.value(HttpHeaders.authorizationHeader);
        state.createPostVersion = request.headers.value('LinkedIn-Version');
        state.createPostProtocol = request.headers.value('X-Restli-Protocol-Version');
        state.createPostBody = await utf8.decoder.bind(request).join();
        request.response.statusCode = 201;
        request.response.headers.set('x-restli-id', 'urn:li:share:document-post');
        await request.response.close();
        return;
      }

      request.response.statusCode = 404;
      await request.response.close();
    });

    try {
      final client = LinkedInApiClient(
        apiBaseUri: Uri.parse('http://127.0.0.1:${server.port}'),
      );

      final result = await client.createDocumentPost(
        accessToken: 'access-token',
        authorUrn: 'urn:li:person:member-id',
        filePath: pdfFile.path,
        title: 'hello.pdf',
        message: 'Hello Linkedind',
        visibility: 'PUBLIC',
        apiVersion: '202506',
      );

      expect(result.postUrn, 'urn:li:share:document-post');
      expect(result.postUrl, 'https://www.linkedin.com/feed/update/urn:li:share:document-post/');
      expect(state.initializeDocumentAuth, 'Bearer access-token');
      expect(state.initializeDocumentVersion, '202506');
      expect(state.initializeDocumentProtocol, '2.0.0');
      expect(state.initializeDocumentBody, contains('urn:li:person:member-id'));
      expect(state.documentUploadAuth, 'Bearer access-token');
      expect(state.documentUploadContentType, 'application/pdf');
      expect(state.documentUploadBytes, [9, 8, 7, 6]);
      expect(state.createPostAuth, 'Bearer access-token');
      expect(state.createPostVersion, '202506');
      expect(state.createPostProtocol, '2.0.0');
      expect(state.createPostBody, contains('urn:li:document:123'));
      expect(state.createPostBody, contains('hello.pdf'));
      expect(state.createPostBody, contains('Hello Linkedind'));
    } finally {
      await server.close(force: true);
      tempDir.deleteSync(recursive: true);
    }
  });
}

class _ServerState {
  String? initializeImageAuth;
  String? initializeImageVersion;
  String? initializeImageProtocol;
  String? initializeImageBody;
  String? imageUploadAuth;
  String? imageUploadContentType;
  List<int>? imageUploadBytes;

  String? initializeDocumentAuth;
  String? initializeDocumentVersion;
  String? initializeDocumentProtocol;
  String? initializeDocumentBody;
  String? documentUploadAuth;
  String? documentUploadContentType;
  List<int>? documentUploadBytes;

  String? createPostAuth;
  String? createPostVersion;
  String? createPostProtocol;
  String? createPostBody;
}