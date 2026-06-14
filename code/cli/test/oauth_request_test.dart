import 'package:post_publisher/src/config_store.dart';
import 'package:post_publisher/src/oauth.dart';
import 'package:test/test.dart';

void main() {
  test('createOAuthRequest builds a confidential LinkedIn authorization URL', () {
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
    expect(request.state, hasLength(32));
    // The confidential flow authenticates with the client_secret at the token
    // exchange, so no PKCE parameters should be present.
    expect(query.containsKey('code_challenge'), isFalse);
    expect(query.containsKey('code_challenge_method'), isFalse);
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