library;

import 'package:cli_router/cli_router.dart';
import 'package:modular_cli_sdk/modular_cli_sdk.dart';

import '../../../src/config_store.dart';
import '../../../src/version.dart';
import '../../../src/version_check.dart';

class TuiInput extends Input {
  TuiInput();

  factory TuiInput.fromCliRequest(CliRequest req) => TuiInput();

  @override
  Map<String, dynamic> toJson() => {};
}

class TuiOutput extends Output {
  final String text;

  TuiOutput({required this.text});

  @override
  Map<String, dynamic> toJson() => {'text': text};

  @override
  int get exitCode => ExitCode.ok;

  @override
  String? toText() => text;
}

class TuiCommand implements Command<TuiInput, TuiOutput> {
  @override
  final TuiInput input;
  final ConfigStore _store;
  final Future<VersionCheckResult> Function({required String currentVersion})?
      _versionChecker;

  TuiCommand(
    this.input, {
    ConfigStore? store,
    Future<VersionCheckResult> Function({required String currentVersion})?
        versionChecker,
  }) : _store = store ?? ConfigStore(),
       _versionChecker = versionChecker;

  @override
  String? validate() => null;

  @override
  Future<TuiOutput> execute() async {
    final config = _store.loadUserConfigSync();
    final configured = config.isConfigured ? 'configured' : 'not configured';
    final auth = config.token == null
        ? 'not signed in'
        : (config.token!.isExpired ? 'token expired' : 'signed in');

    var text = _buildBanner(
      version: linkedinCliVersion,
      configured: configured,
      auth: auth,
    );

    try {
      final checker = _versionChecker ??
          ({required String currentVersion}) =>
              checkLatestVersion(currentVersion: currentVersion);
      final result = await checker(currentVersion: linkedinCliVersion);
      if (result.updateAvailable && result.latestVersion != null) {
        text = '$text\n\nUpdate available: '
            '$linkedinCliVersion -> ${result.latestVersion} '
            "(run 'linkedin upgrade')";
      }
    } catch (_) {
      // Silent.
    }

    return TuiOutput(text: text);
  }
}

String _buildBanner({
  required String version,
  required String configured,
  required String auth,
}) {
  return 'LinkedIn CLI v$version\n'
      'Open-source posting workflow for personal accounts and organizations.\n\n'
      'Status\n'
      '  Config: $configured\n'
      '  Auth:   $auth\n\n'
      'Quick start\n'
      '  1. linkedin auth configure\n'
      '  2. linkedin auth login\n'
      '  3. linkedin post text --message "Hello from the CLI"\n\n'
      'Run: linkedin help';
}