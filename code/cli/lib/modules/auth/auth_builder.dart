import 'package:modular_cli_sdk/modular_cli_sdk.dart';

import 'commands/configure.dart';
import 'commands/login.dart';
import 'commands/logout.dart';
import 'commands/status.dart';

void buildAuthModule(ModuleBuilder m) {
  m.command<AuthConfigureInput, AuthConfigureOutput>(
    'configure',
    (req) => AuthConfigureCommand(AuthConfigureInput.fromCliRequest(req)),
    description: 'Save LinkedIn app credentials for this machine',
  );

  m.command<AuthLoginInput, AuthLoginOutput>(
    'login',
    (req) => AuthLoginCommand(AuthLoginInput.fromCliRequest(req)),
    description: 'Sign in with LinkedIn and cache the access token locally',
  );

  m.command<AuthLoginInput, AuthLoginOutput>(
    'signin',
    (req) => AuthLoginCommand(AuthLoginInput.fromCliRequest(req)),
    description: 'Alias for auth login',
  );

  m.command<AuthStatusInput, AuthStatusOutput>(
    'status',
    (req) => AuthStatusCommand(AuthStatusInput.fromCliRequest(req)),
    description: 'Show the current LinkedIn auth status',
  );

  m.command<AuthLogoutInput, AuthLogoutOutput>(
    'logout',
    (req) => AuthLogoutCommand(AuthLogoutInput.fromCliRequest(req)),
    description: 'Remove the cached LinkedIn token',
  );
}