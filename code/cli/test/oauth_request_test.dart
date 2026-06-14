import 'package:post_publisher/src/config_store.dart';
import 'package:post_publisher/src/oauth.dart';
import 'package:test/test.dart';

void main() {
  test('createOAuthRequest builds a LinkedIn authorization URL with PKCE', () {
    final config = UserConfig(
      clientId: 'client-id',
      clientSecret: 'client-secret',
      redirectUri: 'http://127.0.0.1:8787/callback',
      scopes: const ['openid', 'profile', 'email', 'w_member_social'],
      apiVersion: '202506',
    );

    final request = createOAuthRequest(config);
    final query = request.authorizationUri.queryParameters;

    expect(request.authorizationUri.host, 'www.linkedin.com');
    expect(request.authorizationUri.path, '/oauth/v2/authorization');
    expect(query['response_type'], 'code');
    expect(query['client_id'], 'client-id');
    expect(query['redirect_uri'], 'http://127.0.0.1:8787/callback');
    expect(query['scope'], 'openid profile email w_member_social');
    expect(query['state'], request.state);
    expect(query['code_challenge_method'], 'S256');
    expect(query['code_challenge'], isNotEmpty);
    expect(query['enable_extended_login'], 'true');
    expect(request.state, hasLength(32));
    expect(request.codeVerifier, hasLength(64));
    expect(
      RegExp(r'^[A-Za-z0-9\-._~]+$').hasMatch(request.codeVerifier),
      isTrue,
    );
  });

  test('createOAuthRequest fails fast when client id is missing', () {
    const config = UserConfig(
      redirectUri: 'http://127.0.0.1:8787/callback',
      scopes: defaultScopes,
    );

    expect(() => createOAuthRequest(config), throwsStateError);
  });

  test('createOAuthRequest fails fast when redirect uri is missing', () {
    const config = UserConfig(
      clientId: 'client-id',
      scopes: defaultScopes,
    );

    expect(() => createOAuthRequest(config), throwsStateError);
  });
}