library;

import 'dart:convert';
import 'dart:io';

import 'config_store.dart';

class LinkedInApiException implements Exception {
  final String message;
  final int? statusCode;

  const LinkedInApiException(this.message, {this.statusCode});

  @override
  String toString() => statusCode == null ? message : 'HTTP $statusCode: $message';
}

class LinkedInPostResult {
  final String postUrn;
  final String? postUrl;

  const LinkedInPostResult({required this.postUrn, this.postUrl});
}

class LinkedInApiClient {
  final HttpClient _client;
  final Uri _authBaseUri;
  final Uri _apiBaseUri;

  LinkedInApiClient({
    HttpClient? httpClient,
    Uri? authBaseUri,
    Uri? apiBaseUri,
  }) : _client = httpClient ?? HttpClient(),
       _authBaseUri = authBaseUri ?? Uri.parse('https://www.linkedin.com'),
       _apiBaseUri = apiBaseUri ?? Uri.parse('https://api.linkedin.com');

  Future<LinkedInToken> exchangeAuthorizationCode({
    required UserConfig config,
    required String code,
    required String codeVerifier,
  }) async {
    final response = await _postForm(
      uri: _authUri('/oauth/v2/accessToken'),
      fields: {
        'grant_type': 'authorization_code',
        'code': code,
        'client_id': config.clientId ?? '',
        'client_secret': config.clientSecret ?? '',
        'redirect_uri': config.redirectUri ?? '',
        'code_verifier': codeVerifier,
      },
    );

    if (response.statusCode != 200) {
      throw LinkedInApiException(
        _extractError(response.body),
        statusCode: response.statusCode,
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final expiresIn = (json['expires_in'] as num?)?.toInt() ?? 3600;
    final refreshTokenExpiresIn =
        (json['refresh_token_expires_in'] as num?)?.toInt();

    return LinkedInToken(
      accessToken: json['access_token'] as String,
      expiresAt: DateTime.now().toUtc().add(Duration(seconds: expiresIn)),
      refreshToken: json['refresh_token'] as String?,
      refreshTokenExpiresAt: refreshTokenExpiresIn == null
          ? null
          : DateTime.now().toUtc().add(
              Duration(seconds: refreshTokenExpiresIn),
            ),
      scope: json['scope'] as String?,
      idToken: json['id_token'] as String?,
    );
  }

  Future<LinkedInProfile> fetchProfile(String accessToken) async {
    final response = await _get(
      uri: _apiUri('/v2/userinfo'),
      headers: {
        HttpHeaders.authorizationHeader: 'Bearer $accessToken',
      },
    );

    if (response.statusCode != 200) {
      throw LinkedInApiException(
        _extractError(response.body),
        statusCode: response.statusCode,
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final personId = json['sub'] as String;

    return LinkedInProfile(
      personId: personId,
      personUrn: 'urn:li:person:$personId',
      name: (json['name'] as String?) ?? 'LinkedIn member',
      email: json['email'] as String?,
    );
  }

  Future<LinkedInPostResult> createTextPost({
    required String accessToken,
    required String authorUrn,
    required String message,
    required String visibility,
    required String apiVersion,
  }) async {
    return _createPost(
      accessToken: accessToken,
      apiVersion: apiVersion,
      payload: _buildPostPayload(
        authorUrn: authorUrn,
        message: message,
        visibility: visibility,
      ),
    );
  }

  Future<LinkedInPostResult> createImagePost({
    required String accessToken,
    required String authorUrn,
    required String filePath,
    required String message,
    required String visibility,
    required String apiVersion,
    String? altText,
  }) async {
    final imageUrn = await _initializeAndUploadMedia(
      accessToken: accessToken,
      authorUrn: authorUrn,
      filePath: filePath,
      apiVersion: apiVersion,
      initializePath: '/rest/images',
      mediaField: 'image',
    );

    return _createPost(
      accessToken: accessToken,
      apiVersion: apiVersion,
      payload: _buildPostPayload(
        authorUrn: authorUrn,
        message: message,
        visibility: visibility,
        content: {
          'media': {
            'id': imageUrn,
            if (altText != null && altText.trim().isNotEmpty)
              'altText': altText.trim(),
          },
        },
      ),
    );
  }

  Future<LinkedInPostResult> createDocumentPost({
    required String accessToken,
    required String authorUrn,
    required String filePath,
    required String title,
    required String message,
    required String visibility,
    required String apiVersion,
  }) async {
    final documentUrn = await _initializeAndUploadMedia(
      accessToken: accessToken,
      authorUrn: authorUrn,
      filePath: filePath,
      apiVersion: apiVersion,
      initializePath: '/rest/documents',
      mediaField: 'document',
    );

    return _createPost(
      accessToken: accessToken,
      apiVersion: apiVersion,
      payload: _buildPostPayload(
        authorUrn: authorUrn,
        message: message,
        visibility: visibility,
        content: {
          'media': {
            'id': documentUrn,
            'title': title,
          },
        },
      ),
    );
  }

  Future<String> _initializeAndUploadMedia({
    required String accessToken,
    required String authorUrn,
    required String filePath,
    required String apiVersion,
    required String initializePath,
    required String mediaField,
  }) async {
    final initializeResponse = await _postJson(
      uri: _apiUri(
        initializePath,
        queryParameters: const {'action': 'initializeUpload'},
      ),
      headers: _linkedInHeaders(accessToken, apiVersion),
      body: {
        'initializeUploadRequest': {
          'owner': authorUrn,
        },
      },
    );

    if (!_isSuccessStatus(initializeResponse.statusCode)) {
      throw LinkedInApiException(
        _extractError(initializeResponse.body),
        statusCode: initializeResponse.statusCode,
      );
    }

    final json = jsonDecode(initializeResponse.body) as Map<String, dynamic>;
    final value = json['value'] as Map<String, dynamic>?;
    final uploadUrl = value?['uploadUrl'] as String?;
    final mediaUrn = value?[mediaField] as String?;

    if (uploadUrl == null || uploadUrl.isEmpty) {
      throw LinkedInApiException('LinkedIn did not return an uploadUrl for $mediaField');
    }
    if (mediaUrn == null || mediaUrn.isEmpty) {
      throw LinkedInApiException('LinkedIn did not return a media URN for $mediaField');
    }

    final uploadResponse = await _uploadBinary(
      uri: Uri.parse(uploadUrl),
      bytes: await File(filePath).readAsBytes(),
      headers: {
        HttpHeaders.authorizationHeader: 'Bearer $accessToken',
      },
      contentType: _contentTypeForPath(filePath),
    );

    if (!_isSuccessStatus(uploadResponse.statusCode)) {
      throw LinkedInApiException(
        _extractError(uploadResponse.body),
        statusCode: uploadResponse.statusCode,
      );
    }

    return mediaUrn;
  }

  Future<LinkedInPostResult> _createPost({
    required String accessToken,
    required String apiVersion,
    required Map<String, Object?> payload,
  }) async {
    final response = await _postJson(
      uri: _apiUri('/rest/posts'),
      headers: _linkedInHeaders(accessToken, apiVersion),
      body: payload,
    );

    if (response.statusCode != 201) {
      throw LinkedInApiException(
        _extractError(response.body),
        statusCode: response.statusCode,
      );
    }

    final postUrn = response.headers['x-restli-id'];
    if (postUrn == null || postUrn.isEmpty) {
      throw const LinkedInApiException('LinkedIn did not return x-restli-id');
    }

    return LinkedInPostResult(
      postUrn: postUrn,
      postUrl: 'https://www.linkedin.com/feed/update/$postUrn/',
    );
  }

  Map<String, Object?> _buildPostPayload({
    required String authorUrn,
    required String message,
    required String visibility,
    Map<String, Object?>? content,
  }) {
    return {
      'author': authorUrn,
      'commentary': message,
      'visibility': visibility,
      'distribution': {
        'feedDistribution': 'MAIN_FEED',
        'targetEntities': <Object>[],
        'thirdPartyDistributionChannels': <Object>[],
      },
      'content':? content,
      'lifecycleState': 'PUBLISHED',
      'isReshareDisabledByAuthor': false,
    };
  }

  Map<String, String> _linkedInHeaders(String accessToken, String apiVersion) {
    return {
      HttpHeaders.authorizationHeader: 'Bearer $accessToken',
      HttpHeaders.contentTypeHeader: 'application/json',
      'LinkedIn-Version': apiVersion,
      'X-Restli-Protocol-Version': '2.0.0',
    };
  }

  Uri _authUri(String path, {Map<String, String>? queryParameters}) {
    return _resolveUri(_authBaseUri, path, queryParameters: queryParameters);
  }

  Uri _apiUri(String path, {Map<String, String>? queryParameters}) {
    return _resolveUri(_apiBaseUri, path, queryParameters: queryParameters);
  }

  Uri _resolveUri(Uri base, String path, {Map<String, String>? queryParameters}) {
    final resolved = base.resolve(path);
    if (queryParameters == null) {
      return resolved;
    }
    return resolved.replace(queryParameters: queryParameters);
  }

  Future<_HttpResponse> _get({
    required Uri uri,
    Map<String, String> headers = const {},
  }) async {
    final request = await _client.getUrl(uri);
    _setHeaders(request, headers);
    return _closeRequest(request);
  }

  Future<_HttpResponse> _postForm({
    required Uri uri,
    required Map<String, String> fields,
    Map<String, String> headers = const {},
  }) async {
    final request = await _client.postUrl(uri);
    _setHeaders(request, headers);
    request.headers.set(
      HttpHeaders.contentTypeHeader,
      'application/x-www-form-urlencoded',
    );
    request.write(Uri(queryParameters: fields).query);
    return _closeRequest(request);
  }

  Future<_HttpResponse> _postJson({
    required Uri uri,
    required Object body,
    Map<String, String> headers = const {},
  }) async {
    final request = await _client.postUrl(uri);
    _setHeaders(request, headers);
    request.write(jsonEncode(body));
    return _closeRequest(request);
  }

  Future<_HttpResponse> _uploadBinary({
    required Uri uri,
    required List<int> bytes,
    Map<String, String> headers = const {},
    String? contentType,
  }) async {
    final request = await _client.putUrl(uri);
    _setHeaders(request, headers);
    if (contentType != null) {
      request.headers.set(HttpHeaders.contentTypeHeader, contentType);
    }
    request.add(bytes);
    return _closeRequest(request);
  }

  void _setHeaders(HttpClientRequest request, Map<String, String> headers) {
    for (final entry in headers.entries) {
      request.headers.set(entry.key, entry.value);
    }
  }

  Future<_HttpResponse> _closeRequest(HttpClientRequest request) async {
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    final headers = <String, String>{};

    response.headers.forEach((name, values) {
      if (values.isNotEmpty) {
        headers[name] = values.first;
      }
    });

    return _HttpResponse(
      statusCode: response.statusCode,
      body: body,
      headers: headers,
    );
  }

  bool _isSuccessStatus(int statusCode) => statusCode >= 200 && statusCode < 300;

  String _contentTypeForPath(String filePath) {
    final lower = filePath.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lower.endsWith('.gif')) {
      return 'image/gif';
    }
    if (lower.endsWith('.pdf')) {
      return 'application/pdf';
    }
    return 'application/octet-stream';
  }

  String _extractError(String body) {
    if (body.trim().isEmpty) {
      return 'Empty response from LinkedIn';
    }

    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return (json['message'] as String?) ??
          (json['error_description'] as String?) ??
          (json['error'] as String?) ??
          body;
    } catch (_) {
      return body;
    }
  }
}

class _HttpResponse {
  final int statusCode;
  final String body;
  final Map<String, String> headers;

  const _HttpResponse({
    required this.statusCode,
    required this.body,
    required this.headers,
  });
}