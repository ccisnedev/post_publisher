library;

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import 'config_store.dart';

class OAuthRequest {
  final Uri authorizationUri;
  final String state;
  final String codeVerifier;

  const OAuthRequest({
    required this.authorizationUri,
    required this.state,
    required this.codeVerifier,
  });
}

OAuthRequest createOAuthRequest(UserConfig config) {
  final clientId = _requireNonBlank(config.clientId, 'clientId');
  final redirectUri = _requireNonBlank(config.redirectUri, 'redirectUri');
  final state = _randomUrlSafe(32);
  final codeVerifier = _randomUrlSafe(64);
  final codeChallenge = _base64UrlNoPadding(
    sha256.convert(utf8.encode(codeVerifier)).bytes,
  );

  final uri = Uri.https('www.linkedin.com', '/oauth/v2/authorization', {
    'response_type': 'code',
    'client_id': clientId,
    'redirect_uri': redirectUri,
    'scope': config.scopes.join(' '),
    'state': state,
    'code_challenge': codeChallenge,
    'code_challenge_method': 'S256',
    'enable_extended_login': 'true',
  });

  return OAuthRequest(
    authorizationUri: uri,
    state: state,
    codeVerifier: codeVerifier,
  );
}

String _randomUrlSafe(int length) {
  const alphabet =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
  final random = Random.secure();
  return List.generate(length, (_) => alphabet[random.nextInt(alphabet.length)])
      .join();
}

String _base64UrlNoPadding(List<int> bytes) {
  return base64Url.encode(bytes).replaceAll('=', '');
}

String _requireNonBlank(String? value, String fieldName) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) {
    throw StateError('Missing required OAuth config field: $fieldName');
  }
  return normalized;
}