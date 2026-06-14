library;

import 'dart:convert';
import 'dart:io';

import 'package:cli_router/cli_router.dart';
import 'package:modular_cli_sdk/modular_cli_sdk.dart';
import 'package:path/path.dart' as p;

import '../../../platform/platform_ops.dart';
import '../../../src/version.dart';

const String _defaultRepo = 'ccisnedev/post_publisher';

class UpgradeInput extends Input {
  final String installDir;

  UpgradeInput({required this.installDir});

  factory UpgradeInput.fromCliRequest(CliRequest req) {
    final installDir = p.dirname(p.dirname(Platform.resolvedExecutable));
    return UpgradeInput(installDir: installDir);
  }

  @override
  Map<String, dynamic> toJson() => {'installDir': installDir};
}

class UpgradeOutput extends Output {
  final bool upgraded;
  final String message;
  final String previousVersion;
  final String newVersion;

  UpgradeOutput({
    required this.upgraded,
    required this.message,
    required this.previousVersion,
    required this.newVersion,
  });

  @override
  Map<String, dynamic> toJson() => {
    'upgraded': upgraded,
    'message': message,
    'previousVersion': previousVersion,
    'newVersion': newVersion,
  };

  @override
  int get exitCode => ExitCode.ok;

  @override
  String? toText() => message;
}

class UpgradeCommand implements Command<UpgradeInput, UpgradeOutput> {
  @override
  final UpgradeInput input;
  final PlatformOps platformOps;
  final HttpClient? httpClientOverride;

  UpgradeCommand(
    this.input, {
    PlatformOps? platformOps,
    this.httpClientOverride,
  }) : platformOps = platformOps ?? PlatformOps.current();

  @override
  String? validate() => null;

  @override
  Future<UpgradeOutput> execute() async {
    final client = httpClientOverride ?? HttpClient();
    try {
      final request = await client.getUrl(
        Uri.parse('https://api.github.com/repos/$_defaultRepo/releases/latest'),
      );
      request.headers.set('Accept', 'application/vnd.github+json');
      request.headers.set('User-Agent', 'post-publisher/$linkedinCliVersion');

      final response = await request.close();
      if (response.statusCode != 200) {
        return UpgradeOutput(
          upgraded: false,
          message: 'Failed to fetch the latest release metadata.',
          previousVersion: linkedinCliVersion,
          newVersion: linkedinCliVersion,
        );
      }

      final payload = jsonDecode(
        await response.transform(utf8.decoder).join(),
      ) as Map<String, dynamic>;

      final tag = payload['tag_name'] as String? ?? '';
      final latestVersion = tag.startsWith('v') ? tag.substring(1) : tag;
      if (latestVersion.isEmpty || latestVersion == linkedinCliVersion) {
        return UpgradeOutput(
          upgraded: false,
          message: 'Already on the latest version.',
          previousVersion: linkedinCliVersion,
          newVersion: linkedinCliVersion,
        );
      }

      final assets = (payload['assets'] as List<dynamic>).cast<Map<String, dynamic>>();
      final asset = assets.where(
        (candidate) => candidate['name'] == platformOps.assetName,
      );

      if (asset.isEmpty) {
        return UpgradeOutput(
          upgraded: false,
          message: 'No ${platformOps.assetName} asset found in release $tag.',
          previousVersion: linkedinCliVersion,
          newVersion: latestVersion,
        );
      }

      final downloadUrl = asset.first['browser_download_url'] as String;
      final tempDir = Directory.systemTemp.createTempSync('post_publisher_upgrade_');
      final archiveFile = File(p.join(tempDir.path, platformOps.assetName));

      final downloadRequest = await client.getUrl(Uri.parse(downloadUrl));
      downloadRequest.headers.set('User-Agent', 'post-publisher/$linkedinCliVersion');
      final downloadResponse = await downloadRequest.close();
      final sink = archiveFile.openWrite();
      await downloadResponse.pipe(sink);
      await sink.close();

      if (Platform.isWindows) {
        final backupFile = File('${Platform.resolvedExecutable}.bak');
        if (backupFile.existsSync()) {
          backupFile.deleteSync();
        }
        File(Platform.resolvedExecutable).renameSync(backupFile.path);
      }

      await platformOps.expandArchive(archiveFile.path, input.installDir);
      await platformOps.runPostInstall(input.installDir);
      tempDir.deleteSync(recursive: true);

      return UpgradeOutput(
        upgraded: true,
        message: 'Upgraded $linkedinCliVersion -> $latestVersion',
        previousVersion: linkedinCliVersion,
        newVersion: latestVersion,
      );
    } catch (error) {
      return UpgradeOutput(
        upgraded: false,
        message: 'Upgrade failed: $error',
        previousVersion: linkedinCliVersion,
        newVersion: linkedinCliVersion,
      );
    } finally {
      if (httpClientOverride == null) {
        client.close();
      }
    }
  }
}