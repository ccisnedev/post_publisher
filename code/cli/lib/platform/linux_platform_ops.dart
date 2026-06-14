library;

import 'dart:io';

import 'platform_ops.dart';

class LinuxPlatformOps implements PlatformOps {
  @override
  String get binaryName => 'post-publisher';

  @override
  String get assetName => 'post-publisher-linux-x64.tar.gz';

  @override
  Future<void> expandArchive(String archivePath, String destDir) async {
    final result = await Process.run('tar', ['xzf', archivePath, '-C', destDir]);
    if (result.exitCode != 0) {
      throw ProcessException(
        'tar',
        ['xzf', archivePath],
        'Failed to extract archive: ${result.stderr}',
        result.exitCode,
      );
    }
  }

  @override
  String? getEnvVariable(String name) => Platform.environment[name];

  @override
  Future<void> setEnvVariable(String name, String value) async {}

  @override
  Future<void> selfReplace(String newBinaryPath, String currentBinaryPath) async {
    final backupPath = '$currentBinaryPath.bak';
    File(currentBinaryPath).renameSync(backupPath);
    File(newBinaryPath).copySync(currentBinaryPath);
    await Process.run('chmod', ['+x', currentBinaryPath]);
    try {
      File(backupPath).deleteSync();
    } on FileSystemException {
      // Best effort.
    }
  }

  @override
  Future<void> runPostInstall(String installDir) async {}

  @override
  Future<void> scheduleDeletion(String dir) async {
    await Process.start('rm', ['-rf', dir], mode: ProcessStartMode.detached);
  }
}