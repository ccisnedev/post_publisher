library;

import 'dart:io';

import 'package:cli_router/cli_router.dart';
import 'package:modular_cli_sdk/modular_cli_sdk.dart';
import 'package:path/path.dart' as p;

import '../../../src/config_store.dart';

class InitInput extends Input {
  final String workingDirectory;

  InitInput({required this.workingDirectory});

  factory InitInput.fromCliRequest(CliRequest req) =>
      InitInput(workingDirectory: Directory.current.path);

  @override
  Map<String, dynamic> toJson() => {'workingDirectory': workingDirectory};
}

class InitOutput extends Output {
  final String message;
  final bool created;

  InitOutput({required this.message, required this.created});

  @override
  Map<String, dynamic> toJson() => {'message': message, 'created': created};

  @override
  int get exitCode => ExitCode.ok;

  @override
  String? toText() => message;
}

class InitCommand implements Command<InitInput, InitOutput> {
  @override
  final InitInput input;
  final ConfigStore _store;

  InitCommand(this.input, {ConfigStore? store})
    : _store = store ?? ConfigStore(workingDirectory: input.workingDirectory);

  @override
  String? validate() => null;

  @override
  Future<InitOutput> execute() async {
    final steps = <String>[];
    final configFile = File(_store.projectConfigPath);

    if (!configFile.existsSync()) {
      _store.saveProjectConfigSync(const ProjectConfig());
      steps.add('Created ${p.relative(configFile.path, from: _store.projectRoot)}');
    }

    final gitignore = File(p.join(_store.projectRoot, '.gitignore'));
    const localEntry = '.post_publisher/local.json';
    if (!gitignore.existsSync()) {
      gitignore.writeAsStringSync(
        '# LinkedIn CLI local overrides\n$localEntry\n',
      );
      steps.add('Created .gitignore with LinkedIn CLI entry');
    } else {
      var content = gitignore.readAsStringSync();
      if (!content.contains(localEntry)) {
        if (!content.endsWith('\n')) {
          content = '$content\n';
        }
        gitignore.writeAsStringSync('$content# LinkedIn CLI local overrides\n$localEntry\n');
        steps.add('Added LinkedIn CLI local override to .gitignore');
      }
    }

    if (steps.isEmpty) {
      return InitOutput(
        message: 'LinkedIn CLI is already initialized in ${_store.projectRoot}',
        created: false,
      );
    }

    return InitOutput(message: steps.join('\n'), created: true);
  }
}