library;

import 'dart:io';

import 'package:cli_router/cli_router.dart';
import 'package:modular_cli_sdk/modular_cli_sdk.dart';

import '../../../src/config_store.dart';
import '../../../src/version.dart';

typedef ProcessRunner =
    Future<ProcessResult> Function(String executable, List<String> arguments);

class DoctorCheck {
  final String name;
  final bool passed;
  final String? details;
  final String? remediation;

  const DoctorCheck({
    required this.name,
    required this.passed,
    this.details,
    this.remediation,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'passed': passed,
    if (details != null) 'details': details,
    if (remediation != null) 'remediation': remediation,
  };
}

class DoctorInput extends Input {
  DoctorInput();

  factory DoctorInput.fromCliRequest(CliRequest req) => DoctorInput();

  @override
  Map<String, dynamic> toJson() => {};
}

class DoctorOutput extends Output {
  final List<DoctorCheck> checks;

  DoctorOutput({required this.checks});

  bool get passed => checks.every((check) => check.passed);

  @override
  Map<String, dynamic> toJson() => {
    'checks': checks.map((check) => check.toJson()).toList(),
    'passed': passed,
  };

  @override
  int get exitCode => passed ? ExitCode.ok : ExitCode.genericError;

  @override
  String? toText() {
    final buffer = StringBuffer('Checking Post Publisher setup...\n');
    for (final check in checks) {
      final icon = check.passed ? '✓' : '✗';
      buffer.write('  $icon ${check.name}');
      if (check.details != null && check.details!.isNotEmpty) {
        buffer.write(' ${check.details}');
      }
      buffer.writeln();
      if (!check.passed && check.remediation != null) {
        buffer.writeln('    -> ${check.remediation}');
      }
    }
    buffer.writeln();
    buffer.write(passed ? 'All checks passed.' : 'Some checks failed.');
    return buffer.toString();
  }
}

class DoctorCommand implements Command<DoctorInput, DoctorOutput> {
  @override
  final DoctorInput input;
  final ConfigStore _store;
  final ProcessRunner _processRunner;

  DoctorCommand(
    this.input, {
    ConfigStore? store,
    ProcessRunner? processRunner,
  }) : _store = store ?? ConfigStore(),
       _processRunner = processRunner ?? _defaultProcessRunner;

  @override
  String? validate() => null;

  @override
  Future<DoctorOutput> execute() async {
    final checks = <DoctorCheck>[
      DoctorCheck(name: 'post-publisher', passed: true, details: linkedinCliVersion),
    ];

    checks.add(await _checkCommand('dart', ['--version']));
    checks.add(await _checkCommand('git', ['--version']));

    final config = _store.loadUserConfigSync();
    checks.add(
      DoctorCheck(
        name: 'client id',
        passed: config.clientId?.isNotEmpty ?? false,
        remediation: "Run 'post-publisher auth configure --client-id <id>'",
      ),
    );
    checks.add(
      DoctorCheck(
        name: 'client secret',
        passed: config.clientSecret?.isNotEmpty ?? false,
        remediation: "Run 'post-publisher auth configure --client-secret <secret>'",
      ),
    );
    checks.add(
      DoctorCheck(
        name: 'redirect uri',
        passed: config.redirectUri?.isNotEmpty ?? false,
        details: config.redirectUri,
        remediation: "Run 'post-publisher auth configure --redirect-uri <uri>'",
      ),
    );

    final requiredScopes = {'openid', 'profile', 'w_member_social'};
    final scopeSet = config.scopes.toSet();
    checks.add(
      DoctorCheck(
        name: 'required scopes',
        passed: requiredScopes.every(scopeSet.contains),
        details: config.scopes.join(' '),
        remediation: "Run 'post-publisher auth configure' and keep openid, profile, and w_member_social",
      ),
    );

    final token = config.token;
    checks.add(
      DoctorCheck(
        name: 'auth token',
        passed: token != null && !token.isExpired,
        details: token == null
            ? null
            : (token.isExpired ? 'expired' : 'valid until ${token.expiresAt.toUtc()}'),
        remediation: "Run 'post-publisher auth login'",
      ),
    );

    final profile = config.profile;
    checks.add(
      DoctorCheck(
        name: 'member profile',
        passed: profile != null,
        details: profile?.personUrn,
        remediation: "Run 'post-publisher auth login' to resolve your member URN",
      ),
    );

    return DoctorOutput(checks: checks);
  }

  Future<DoctorCheck> _checkCommand(String executable, List<String> arguments) async {
    try {
      final result = await _processRunner(executable, arguments);
      if (result.exitCode != 0) {
        return DoctorCheck(
          name: executable,
          passed: false,
          details: (result.stderr as String).trim(),
          remediation: 'Install $executable and ensure it is available on PATH',
        );
      }

      final output = '${result.stdout}${result.stderr}'.trim();
      final line = output.split('\n').first.trim();
      return DoctorCheck(name: executable, passed: true, details: line);
    } on ProcessException {
      return DoctorCheck(
        name: executable,
        passed: false,
        remediation: 'Install $executable and ensure it is available on PATH',
      );
    }
  }
}

Future<ProcessResult> _defaultProcessRunner(
  String executable,
  List<String> arguments,
) {
  return Process.run(executable, arguments);
}