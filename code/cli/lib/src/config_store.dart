library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'project_root.dart';

const String defaultApiVersion = '202506';
const List<String> defaultScopes = <String>[
  'openid',
  'profile',
  'email',
  'w_member_social',
];

class LinkedInToken {
  final String accessToken;
  final DateTime expiresAt;
  final String? refreshToken;
  final DateTime? refreshTokenExpiresAt;
  final String? scope;
  final String? idToken;

  const LinkedInToken({
    required this.accessToken,
    required this.expiresAt,
    this.refreshToken,
    this.refreshTokenExpiresAt,
    this.scope,
    this.idToken,
  });

  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAt.toUtc());

  factory LinkedInToken.fromJson(Map<String, dynamic> json) => LinkedInToken(
    accessToken: json['accessToken'] as String,
    expiresAt: DateTime.parse(json['expiresAt'] as String).toUtc(),
    refreshToken: json['refreshToken'] as String?,
    refreshTokenExpiresAt: json['refreshTokenExpiresAt'] == null
        ? null
        : DateTime.parse(json['refreshTokenExpiresAt'] as String).toUtc(),
    scope: json['scope'] as String?,
    idToken: json['idToken'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'expiresAt': expiresAt.toUtc().toIso8601String(),
    if (refreshToken != null) 'refreshToken': refreshToken,
    if (refreshTokenExpiresAt != null)
      'refreshTokenExpiresAt': refreshTokenExpiresAt!.toUtc().toIso8601String(),
    if (scope != null) 'scope': scope,
    if (idToken != null) 'idToken': idToken,
  };
}

class LinkedInProfile {
  final String personId;
  final String personUrn;
  final String name;
  final String? email;

  const LinkedInProfile({
    required this.personId,
    required this.personUrn,
    required this.name,
    this.email,
  });

  factory LinkedInProfile.fromJson(Map<String, dynamic> json) => LinkedInProfile(
    personId: json['personId'] as String,
    personUrn: json['personUrn'] as String,
    name: json['name'] as String,
    email: json['email'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'personId': personId,
    'personUrn': personUrn,
    'name': name,
    if (email != null) 'email': email,
  };
}

class UserConfig {
  final String? clientId;
  final String? clientSecret;
  final String? redirectUri;
  final List<String> scopes;
  final String apiVersion;
  final LinkedInToken? token;
  final LinkedInProfile? profile;

  const UserConfig({
    this.clientId,
    this.clientSecret,
    this.redirectUri,
    this.scopes = defaultScopes,
    this.apiVersion = defaultApiVersion,
    this.token,
    this.profile,
  });

  bool get isConfigured =>
      (clientId?.isNotEmpty ?? false) &&
      (clientSecret?.isNotEmpty ?? false) &&
      (redirectUri?.isNotEmpty ?? false);

  UserConfig copyWith({
    String? clientId,
    String? clientSecret,
    String? redirectUri,
    List<String>? scopes,
    String? apiVersion,
    LinkedInToken? token,
    bool clearToken = false,
    LinkedInProfile? profile,
    bool clearProfile = false,
  }) {
    return UserConfig(
      clientId: clientId ?? this.clientId,
      clientSecret: clientSecret ?? this.clientSecret,
      redirectUri: redirectUri ?? this.redirectUri,
      scopes: scopes ?? this.scopes,
      apiVersion: apiVersion ?? this.apiVersion,
      token: clearToken ? null : (token ?? this.token),
      profile: clearProfile ? null : (profile ?? this.profile),
    );
  }

  factory UserConfig.fromJson(Map<String, dynamic> json) => UserConfig(
    clientId: json['clientId'] as String?,
    clientSecret: json['clientSecret'] as String?,
    redirectUri: json['redirectUri'] as String?,
    scopes: (json['scopes'] as List<dynamic>?)
            ?.map((value) => value as String)
            .toList() ??
        defaultScopes,
    apiVersion: json['apiVersion'] as String? ?? defaultApiVersion,
    token: json['token'] == null
        ? null
        : LinkedInToken.fromJson(json['token'] as Map<String, dynamic>),
    profile: json['profile'] == null
        ? null
        : LinkedInProfile.fromJson(json['profile'] as Map<String, dynamic>),
  );

  Map<String, dynamic> toJson() => {
    if (clientId != null) 'clientId': clientId,
    if (clientSecret != null) 'clientSecret': clientSecret,
    if (redirectUri != null) 'redirectUri': redirectUri,
    'scopes': scopes,
    'apiVersion': apiVersion,
    if (token != null) 'token': token!.toJson(),
    if (profile != null) 'profile': profile!.toJson(),
  };
}

class ProjectConfig {
  final String apiVersion;
  final String defaultVisibility;
  final String? defaultOrganizationUrn;

  const ProjectConfig({
    this.apiVersion = defaultApiVersion,
    this.defaultVisibility = 'PUBLIC',
    this.defaultOrganizationUrn,
  });

  factory ProjectConfig.fromJson(Map<String, dynamic> json) => ProjectConfig(
    apiVersion: json['apiVersion'] as String? ?? defaultApiVersion,
    defaultVisibility: json['defaultVisibility'] as String? ?? 'PUBLIC',
    defaultOrganizationUrn: json['defaultOrganizationUrn'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'apiVersion': apiVersion,
    'defaultVisibility': defaultVisibility,
    if (defaultOrganizationUrn != null)
      'defaultOrganizationUrn': defaultOrganizationUrn,
  };
}

class ConfigStore {
  final String workingDirectory;
  final String configHome;

  ConfigStore({
    String? workingDirectory,
    String? configHome,
  }) : workingDirectory = workingDirectory ?? Directory.current.path,
       configHome = configHome ?? _defaultConfigHome();

  String get userConfigPath => p.join(configHome, 'config.json');

  String get projectRoot => getProjectRoot(workingDirectory) ?? workingDirectory;

  String get projectConfigPath =>
      p.join(projectRoot, '.post_publisher', 'config.json');

  bool get projectConfigExists => File(projectConfigPath).existsSync();

  UserConfig loadUserConfigSync() {
    final file = File(userConfigPath);
    if (!file.existsSync()) {
      return const UserConfig();
    }
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    return UserConfig.fromJson(json);
  }

  void saveUserConfigSync(UserConfig config) {
    final file = File(userConfigPath);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(_prettyJson(config.toJson()));
  }

  ProjectConfig loadProjectConfigSync() {
    final file = File(projectConfigPath);
    if (!file.existsSync()) {
      return const ProjectConfig();
    }
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    return ProjectConfig.fromJson(json);
  }

  void saveProjectConfigSync(ProjectConfig config) {
    final file = File(projectConfigPath);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(_prettyJson(config.toJson()));
  }

  String _prettyJson(Map<String, dynamic> json) {
    return const JsonEncoder.withIndent('  ').convert(json);
  }
}

String _defaultConfigHome() {
  if (Platform.isWindows) {
    final appData = Platform.environment['APPDATA'];
    if (appData != null && appData.isNotEmpty) {
      return p.join(appData, 'post_publisher');
    }
    final userProfile = Platform.environment['USERPROFILE'];
    if (userProfile != null && userProfile.isNotEmpty) {
      return p.join(userProfile, 'AppData', 'Roaming', 'post_publisher');
    }
  }

  if (Platform.isMacOS) {
    final home = Platform.environment['HOME'];
    if (home != null && home.isNotEmpty) {
      return p.join(home, 'Library', 'Application Support', 'post_publisher');
    }
  }

  final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
  if (home != null && home.isNotEmpty) {
    return p.join(home, '.config', 'post_publisher');
  }

  return p.join(Directory.current.path, '.post_publisher');
}