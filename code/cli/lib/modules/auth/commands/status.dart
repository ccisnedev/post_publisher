library;

import 'package:cli_router/cli_router.dart';
import 'package:modular_cli_sdk/modular_cli_sdk.dart';

import '../../../src/config_store.dart';

class AuthStatusInput extends Input {
  AuthStatusInput();

  factory AuthStatusInput.fromCliRequest(CliRequest req) => AuthStatusInput();

  @override
  Map<String, dynamic> toJson() => {};
}

class AuthStatusOutput extends Output {
  final String text;

  AuthStatusOutput({required this.text});

  @override
  Map<String, dynamic> toJson() => {'text': text};

  @override
  int get exitCode => ExitCode.ok;

  @override
  String? toText() => text;
}

class AuthStatusCommand implements Command<AuthStatusInput, AuthStatusOutput> {
  @override
  final AuthStatusInput input;
  final ConfigStore _store;

  AuthStatusCommand(this.input, {ConfigStore? store})
    : _store = store ?? ConfigStore();

  @override
  String? validate() => null;

  @override
  Future<AuthStatusOutput> execute() async {
    final config = _store.loadUserConfigSync();
    final buffer = StringBuffer()
      ..writeln('LinkedIn auth status')
      ..writeln('  Config file: ${_store.userConfigPath}')
      ..writeln('  Configured: ${config.isConfigured ? 'yes' : 'no'}')
      ..writeln('  Redirect URI: ${config.redirectUri ?? '(not set)'}')
      ..writeln('  Scopes: ${config.scopes.join(' ')}');

    if (config.profile != null) {
      buffer.writeln('  Member: ${config.profile!.name}');
      buffer.writeln('  Person URN: ${config.profile!.personUrn}');
    } else {
      buffer.writeln('  Member: (not resolved yet)');
    }

    if (config.token == null) {
      buffer.writeln('  Token: missing');
    } else if (config.token!.isExpired) {
      buffer.writeln('  Token: expired at ${config.token!.expiresAt.toUtc()}');
    } else {
      buffer.writeln('  Token: valid until ${config.token!.expiresAt.toUtc()}');
    }

    return AuthStatusOutput(text: buffer.toString().trimRight());
  }
}