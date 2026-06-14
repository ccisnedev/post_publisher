library;

import 'dart:async';
import 'dart:io';

import 'package:cli_router/cli_router.dart';
import 'package:modular_cli_sdk/modular_cli_sdk.dart';

import '../../../src/config_store.dart';
import '../../../src/linkedin_api.dart';
import '../../../src/oauth.dart';
import '../../../src/url_launcher.dart';

typedef OAuthRequestBuilder = OAuthRequest Function(UserConfig config);

class AuthLoginInput extends Input {
  final bool noOpen;
  final bool manual;
  final String? responseUrl;

  AuthLoginInput({
    this.noOpen = false,
    this.manual = false,
    this.responseUrl,
  });

  factory AuthLoginInput.fromCliRequest(CliRequest req) => AuthLoginInput(
    noOpen: req.flagBool('no-open'),
    manual: req.flagBool('manual'),
    responseUrl: req.flagString('response-url'),
  );

  @override
  Map<String, dynamic> toJson() => {
    'noOpen': noOpen,
    'manual': manual,
    if (responseUrl != null) 'responseUrl': responseUrl,
  };
}

class AuthLoginOutput extends Output {
  final bool success;
  final String message;

  AuthLoginOutput({required this.success, required this.message});

  @override
  Map<String, dynamic> toJson() => {'success': success, 'message': message};

  @override
  int get exitCode => success ? ExitCode.ok : ExitCode.genericError;

  @override
  String? toText() => message;
}

class AuthLoginCommand implements Command<AuthLoginInput, AuthLoginOutput> {
  @override
  final AuthLoginInput input;
  final ConfigStore _store;
  final LinkedInApiClient _api;
  final OAuthRequestBuilder _requestBuilder;

  AuthLoginCommand(
    this.input, {
    ConfigStore? store,
    LinkedInApiClient? api,
    OAuthRequestBuilder? requestBuilder,
  }) : _store = store ?? ConfigStore(),
       _api = api ?? LinkedInApiClient(),
       _requestBuilder = requestBuilder ?? createOAuthRequest;

  @override
  String? validate() => null;

  @override
  Future<AuthLoginOutput> execute() async {
    final config = _store.loadUserConfigSync();
    if (!config.isConfigured) {
      return AuthLoginOutput(
        success: false,
        message: "LinkedIn credentials are not configured yet. Run 'linkedin auth configure' first.",
      );
    }

    final request = _requestBuilder(config);
    stdout.writeln('LinkedIn authorization URL:');
    stdout.writeln(request.authorizationUri.toString());

    if (!input.noOpen) {
      final opened = await openExternalUrl(request.authorizationUri.toString());
      if (!opened) {
        stdout.writeln('Could not open the browser automatically. Open the URL manually.');
      }
    }

    try {
      final response = await _collectAuthorizationResponse(
        redirectUri: Uri.parse(config.redirectUri!),
        expectedState: request.state,
      );

      if (response.error != null) {
        return AuthLoginOutput(
          success: false,
          message: 'LinkedIn authorization failed: ${response.error}',
        );
      }

      if (response.state != null && response.state != request.state) {
        return AuthLoginOutput(
          success: false,
          message: 'LinkedIn returned an unexpected state value.',
        );
      }

      if (response.code == null || response.code!.isEmpty) {
        return AuthLoginOutput(
          success: false,
          message: 'LinkedIn did not return an authorization code.',
        );
      }

      final token = await _api.exchangeAuthorizationCode(
        config: config,
        code: response.code!,
      );

      final profile = await _api.fetchProfile(token.accessToken);
      final updated = config.copyWith(token: token, profile: profile);
      _store.saveUserConfigSync(updated);

      return AuthLoginOutput(
        success: true,
        message: 'Signed in as ${profile.name} (${profile.personUrn}).',
      );
    } on LinkedInApiException catch (error) {
      return AuthLoginOutput(success: false, message: error.toString());
    } catch (error) {
      return AuthLoginOutput(success: false, message: 'Auth login failed: $error');
    }
  }

  Future<_AuthorizationResponse> _collectAuthorizationResponse({
    required Uri redirectUri,
    required String expectedState,
  }) async {
    if (input.responseUrl != null && input.responseUrl!.trim().isNotEmpty) {
      return _AuthorizationResponse.fromInput(input.responseUrl!.trim());
    }

    if (!input.manual && _isLoopbackHttpUri(redirectUri)) {
      final loopback = await _waitForLoopbackRedirect(redirectUri);
      if (loopback != null) {
        return loopback;
      }
      stdout.writeln('Timed out waiting for the local callback. Falling back to manual mode.');
    }

    stdout.write('Paste the full redirect URL from LinkedIn: ');
    final pasted = stdin.readLineSync()?.trim();
    if (pasted == null || pasted.isEmpty) {
      return const _AuthorizationResponse(error: 'No redirect URL was provided.');
    }
    return _AuthorizationResponse.fromInput(pasted);
  }

  bool _isLoopbackHttpUri(Uri uri) {
    return uri.scheme == 'http' &&
        (uri.host == '127.0.0.1' || uri.host == 'localhost');
  }

  Future<_AuthorizationResponse?> _waitForLoopbackRedirect(Uri redirectUri) async {
    HttpServer? server;
    try {
      server = await HttpServer.bind(redirectUri.host, redirectUri.port);
    } on SocketException {
      return null;
    }

    try {
      final request = await server.first.timeout(const Duration(minutes: 3));
      final response = _AuthorizationResponse.fromUri(request.uri);

      request.response.headers.contentType = ContentType.html;
      request.response.write(
        response.error == null
            ? '<html><body><h1>LinkedIn CLI</h1><p>You can return to the terminal.</p></body></html>'
            : '<html><body><h1>LinkedIn CLI</h1><p>Authorization failed. Return to the terminal.</p></body></html>',
      );
      await request.response.close();

      return response;
    } on TimeoutException {
      return null;
    } finally {
      await server.close(force: true);
    }
  }
}

class _AuthorizationResponse {
  final String? code;
  final String? state;
  final String? error;

  const _AuthorizationResponse({this.code, this.state, this.error});

  factory _AuthorizationResponse.fromInput(String input) {
    if (input.contains('://')) {
      return _AuthorizationResponse.fromUri(Uri.parse(input));
    }

    final normalized = input.startsWith('?') ? input.substring(1) : input;
    final uri = Uri.parse('https://localhost/callback?$normalized');
    return _AuthorizationResponse.fromUri(uri);
  }

  factory _AuthorizationResponse.fromUri(Uri uri) => _AuthorizationResponse(
    code: uri.queryParameters['code'],
    state: uri.queryParameters['state'],
    error: uri.queryParameters['error_description'] ?? uri.queryParameters['error'],
  );
}