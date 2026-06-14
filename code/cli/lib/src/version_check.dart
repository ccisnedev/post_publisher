library;

import 'dart:convert';
import 'dart:io';

class VersionCheckResult {
  final bool updateAvailable;
  final String? latestVersion;

  const VersionCheckResult({
    required this.updateAvailable,
    this.latestVersion,
  });
}

Future<VersionCheckResult> checkLatestVersion({
  required String currentVersion,
  String repo = 'ccisnedev/post_publisher',
  HttpClient? clientOverride,
}) async {
  final client = clientOverride ?? HttpClient();
  try {
    final request = await client.getUrl(
      Uri.parse('https://api.github.com/repos/$repo/releases/latest'),
    );
    request.headers.set('Accept', 'application/vnd.github+json');
    request.headers.set('User-Agent', 'post-publisher/$currentVersion');

    final response = await request.close();
    if (response.statusCode != 200) {
      return const VersionCheckResult(updateAvailable: false);
    }

    final body = await response.transform(utf8.decoder).join();
    final payload = jsonDecode(body) as Map<String, dynamic>;
    final tag = (payload['tag_name'] as String?) ?? '';
    final latest = tag.startsWith('v') ? tag.substring(1) : tag;

    if (latest.isEmpty || latest == currentVersion) {
      return VersionCheckResult(updateAvailable: false, latestVersion: latest);
    }

    return VersionCheckResult(updateAvailable: true, latestVersion: latest);
  } catch (_) {
    return const VersionCheckResult(updateAvailable: false);
  } finally {
    if (clientOverride == null) {
      client.close();
    }
  }
}