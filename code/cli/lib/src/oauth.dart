library;

import 'dart:math';

import 'config_store.dart';

class OAuthRequest {
  final Uri authorizationUri;
  final String state;

  const OAuthRequest({
    required this.authorizationUri,
    required this.state,
  });
}

// LinkedIn exposes two distinct OAuth flows. The confidential Authorization
// Code flow (used by "Sign in with LinkedIn using OpenID Connect" and "Share on
// LinkedIn") authenticates the token exchange with the client_secret and does
// NOT use PKCE. PKCE is only for the separate native flow, which lives at a
// different authorization endpoint and must be enabled by LinkedIn per app.
// Sending PKCE parameters here makes LinkedIn treat the request as a public
// client and the client_secret authentication fails ("Client authentication
// failed"), so we stick to the plain confidential flow.
OAuthRequest createOAuthRequest(UserConfig config) {
  final clientId = _requireNonBlank(config.clientId, 'clientId');
  final redirectUri = _requireNonBlank(config.redirectUri, 'redirectUri');
  final state = _randomUrlSafe(32);

  final uri = Uri.https('www.linkedin.com', '/oauth/v2/authorization', {
    'response_type': 'code',
    'client_id': clientId,
    'redirect_uri': redirectUri,
    'scope': config.scopes.join(' '),
    'state': state,
  });

  return OAuthRequest(
    authorizationUri: uri,
    state: state,
  );
}

String _randomUrlSafe(int length) {
  const alphabet =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
  final random = Random.secure();
  return List.generate(length, (_) => alphabet[random.nextInt(alphabet.length)])
      .join();
}

String _requireNonBlank(String? value, String fieldName) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) {
    throw StateError('Missing required OAuth config field: $fieldName');
  }
  return normalized;
}