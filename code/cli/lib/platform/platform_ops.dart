library;

import 'dart:io' show Platform;

import 'linux_platform_ops.dart';
import 'windows_platform_ops.dart';

abstract class PlatformOps {
  String get binaryName;
  String get assetName;

  Future<void> expandArchive(String archivePath, String destDir);
  String? getEnvVariable(String name);
  Future<void> setEnvVariable(String name, String value);
  Future<void> selfReplace(String newBinaryPath, String currentBinaryPath);
  Future<void> runPostInstall(String installDir);
  Future<void> scheduleDeletion(String dir);

  factory PlatformOps.current() {
    if (Platform.isWindows) {
      return WindowsPlatformOps();
    }
    if (Platform.isLinux || Platform.isMacOS) {
      return LinuxPlatformOps();
    }
    throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
  }
}