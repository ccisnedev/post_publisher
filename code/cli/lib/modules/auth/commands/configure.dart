library;

import 'dart:io';

import 'package:cli_router/cli_router.dart';
import 'package:modular_cli_sdk/modular_cli_sdk.dart';

import '../../../src/config_store.dart';

class AuthConfigureInput extends Input {
  final String? clientId;
  final String? clientSecret;
  final String? redirectUri;
  final String? scopes;
  final String? apiVersion;

  AuthConfigureInput({
    this.clientId,
    this.clientSecret,
    this.redirectUri,
    this.scopes,
    this.apiVersion,
  });

  factory AuthConfigureInput.fromCliRequest(CliRequest req) => AuthConfigureInput(
    clientId: req.flagString('client-id'),
    clientSecret: req.flagString('client-secret'),
    redirectUri: req.flagString('redirect-uri'),
    scopes: req.flagString('scopes'),
    apiVersion: req.flagString('api-version'),
  );

  @override
  Map<String, dynamic> toJson() => {
    if (clientId != null) 'clientId': clientId,
    if (redirectUri != null) 'redirectUri': redirectUri,
    if (scopes != null) 'scopes': scopes,
    if (apiVersion != null) 'apiVersion': apiVersion,
  };
}

class AuthConfigureOutput extends Output {
  final String message;

  AuthConfigureOutput({required this.message});

  @override
  Map<String, dynamic> toJson() => {'message': message};

  @override
  int get exitCode => ExitCode.ok;

  @override
  String? toText() => message;
}

class AuthConfigureCommand implements Command<AuthConfigureInput, AuthConfigureOutput> {
  @override
  final AuthConfigureInput input;
  final ConfigStore _store;

  AuthConfigureCommand(this.input, {ConfigStore? store})
    : _store = store ?? ConfigStore();

  @override
  String? validate() => null;

  @override
  Future<AuthConfigureOutput> execute() async {
    final current = _store.loadUserConfigSync();

    final clientId = _pickValue(
      explicit: input.clientId,
      envValue: Platform.environment['LINKEDIN_CLIENT_ID'],
      fallback: current.clientId,
      prompt: 'LinkedIn Client ID',
    );

    final clientSecret = _pickValue(
      explicit: input.clientSecret,
      envValue: Platform.environment['LINKEDIN_CLIENT_SECRET'],
      fallback: current.clientSecret,
      prompt: 'LinkedIn Client Secret',
    );

    final redirectUri = _pickValue(
      explicit: input.redirectUri,
      envValue: Platform.environment['LINKEDIN_REDIRECT_URI'],
      fallback: current.redirectUri ?? 'http://127.0.0.1:8787/callback',
      prompt: 'Redirect URI',
    );

    final scopesValue = _pickValue(
      explicit: input.scopes,
      envValue: Platform.environment['LINKEDIN_SCOPES'],
      fallback: current.scopes.join(' '),
      prompt: 'Scopes (space or comma separated)',
    );

    final apiVersion = _pickValue(
      explicit: input.apiVersion,
      envValue: Platform.environment['LINKEDIN_API_VERSION'],
      fallback: current.apiVersion,
      prompt: 'LinkedIn API version',
    );

    final scopes = _normalizeScopes(scopesValue ?? defaultScopes.join(' '));
    final updated = current.copyWith(
      clientId: clientId,
      clientSecret: clientSecret,
      redirectUri: redirectUri,
      scopes: scopes,
      apiVersion: apiVersion,
    );

    _store.saveUserConfigSync(updated);

    return AuthConfigureOutput(
      message: 'Saved LinkedIn auth configuration to ${_store.userConfigPath}',
    );
  }

  String? _pickValue({
    required String? explicit,
    required String? envValue,
    required String? fallback,
    required String prompt,
  }) {
    final preferred = explicit ?? envValue ?? fallback;
    if (preferred != null && preferred.trim().isNotEmpty) {
      return preferred.trim();
    }

    stdout.write('$prompt: ');
    return stdin.readLineSync()?.trim();
  }

  List<String> _normalizeScopes(String raw) {
    final scopes = raw
        .split(RegExp(r'[\s,]+'))
        .where((scope) => scope.trim().isNotEmpty)
        .map((scope) => scope.trim())
        .toSet()
        .toList();

    for (final required in const ['openid', 'profile', 'w_member_social']) {
      if (!scopes.contains(required)) {
        scopes.add(required);
      }
    }

    return scopes;
  }
}