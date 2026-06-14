library;

import 'package:cli_router/cli_router.dart';
import 'package:modular_cli_sdk/modular_cli_sdk.dart';

import '../../../src/config_store.dart';

class AuthLogoutInput extends Input {
  AuthLogoutInput();

  factory AuthLogoutInput.fromCliRequest(CliRequest req) => AuthLogoutInput();

  @override
  Map<String, dynamic> toJson() => {};
}

class AuthLogoutOutput extends Output {
  final String message;

  AuthLogoutOutput({required this.message});

  @override
  Map<String, dynamic> toJson() => {'message': message};

  @override
  int get exitCode => ExitCode.ok;

  @override
  String? toText() => message;
}

class AuthLogoutCommand implements Command<AuthLogoutInput, AuthLogoutOutput> {
  @override
  final AuthLogoutInput input;
  final ConfigStore _store;

  AuthLogoutCommand(this.input, {ConfigStore? store})
    : _store = store ?? ConfigStore();

  @override
  String? validate() => null;

  @override
  Future<AuthLogoutOutput> execute() async {
    final current = _store.loadUserConfigSync();
    _store.saveUserConfigSync(
      current.copyWith(clearToken: true, clearProfile: true),
    );

    return AuthLogoutOutput(message: 'Removed the cached LinkedIn token.');
  }
}