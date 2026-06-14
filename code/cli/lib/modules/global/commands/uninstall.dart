library;

import 'dart:io';

import 'package:cli_router/cli_router.dart';
import 'package:modular_cli_sdk/modular_cli_sdk.dart';
import 'package:path/path.dart' as p;

import '../../../platform/platform_ops.dart';

class UninstallInput extends Input {
  final String installDir;

  UninstallInput({required this.installDir});

  factory UninstallInput.fromCliRequest(CliRequest req) {
    final installDir = p.dirname(p.dirname(Platform.resolvedExecutable));
    return UninstallInput(installDir: installDir);
  }

  @override
  Map<String, dynamic> toJson() => {'installDir': installDir};
}

class UninstallOutput extends Output {
  final String message;

  UninstallOutput({required this.message});

  @override
  Map<String, dynamic> toJson() => {'message': message};

  @override
  int get exitCode => ExitCode.ok;

  @override
  String? toText() => message;
}

class UninstallCommand implements Command<UninstallInput, UninstallOutput> {
  @override
  final UninstallInput input;
  final PlatformOps platformOps;

  UninstallCommand(this.input, {PlatformOps? platformOps})
    : platformOps = platformOps ?? PlatformOps.current();

  @override
  String? validate() => null;

  @override
  Future<UninstallOutput> execute() async {
    final binDir = p.join(input.installDir, 'bin');
    _removeFromPath(binDir);
    await platformOps.scheduleDeletion(input.installDir);

    return UninstallOutput(
      message: 'Post Publisher uninstalled. Restart your terminal to refresh PATH.',
    );
  }

  void _removeFromPath(String binDir) {
    final userPath = platformOps.getEnvVariable('PATH') ?? '';
    final separator = Platform.isWindows ? ';' : ':';
    final updated = userPath
        .split(separator)
        .where((entry) => entry.isNotEmpty)
        .where((entry) => !_pathEquals(entry, binDir))
        .join(separator);

    if (updated != userPath) {
      platformOps.setEnvVariable('PATH', updated);
    }
  }

  bool _pathEquals(String left, String right) {
    return p.normalize(left).toLowerCase() == p.normalize(right).toLowerCase();
  }
}