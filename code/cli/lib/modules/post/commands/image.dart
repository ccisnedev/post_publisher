library;

import 'dart:io';

import 'package:cli_router/cli_router.dart';
import 'package:modular_cli_sdk/modular_cli_sdk.dart';

import '../../../src/config_store.dart';
import '../../../src/linkedin_api.dart';

class PostImageInput extends Input {
  final String? filePath;
  final String? message;
  final String? visibility;
  final String? organizationUrn;
  final String? altText;

  PostImageInput({
    this.filePath,
    this.message,
    this.visibility,
    this.organizationUrn,
    this.altText,
  });

  factory PostImageInput.fromCliRequest(CliRequest req) => PostImageInput(
    filePath: req.flagString('file'),
    message: req.flagString('message'),
    visibility: req.flagString('visibility'),
    organizationUrn: req.flagString('organization'),
    altText: req.flagString('alt-text'),
  );

  @override
  Map<String, dynamic> toJson() => {
    if (filePath != null) 'filePath': filePath,
    if (message != null) 'message': message,
    if (visibility != null) 'visibility': visibility,
    if (organizationUrn != null) 'organizationUrn': organizationUrn,
    if (altText != null) 'altText': altText,
  };
}

class PostImageOutput extends Output {
  final bool success;
  final String message;
  final String? postUrn;
  final String? postUrl;

  PostImageOutput({
    required this.success,
    required this.message,
    this.postUrn,
    this.postUrl,
  });

  @override
  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
    if (postUrn != null) 'postUrn': postUrn,
    if (postUrl != null) 'postUrl': postUrl,
  };

  @override
  int get exitCode => success ? ExitCode.ok : ExitCode.genericError;

  @override
  String? toText() {
    if (!success) {
      return message;
    }

    final buffer = StringBuffer(message);
    if (postUrn != null) {
      buffer.writeln();
      buffer.write('Post URN: $postUrn');
    }
    if (postUrl != null) {
      buffer.writeln();
      buffer.write('URL: $postUrl');
    }
    return buffer.toString();
  }
}

class PostImageCommand implements Command<PostImageInput, PostImageOutput> {
  @override
  final PostImageInput input;
  final ConfigStore _store;
  final LinkedInApiClient _api;

  PostImageCommand(
    this.input, {
    ConfigStore? store,
    LinkedInApiClient? api,
  }) : _store = store ?? ConfigStore(),
       _api = api ?? LinkedInApiClient();

  @override
  String? validate() {
    final filePath = input.filePath?.trim();
    if (filePath == null || filePath.isEmpty) {
      return 'Missing required --file value.';
    }

    final file = File(filePath);
    if (!file.existsSync()) {
      return 'The file does not exist: $filePath';
    }

    final lower = filePath.toLowerCase();
    const allowed = ['.png', '.jpg', '.jpeg', '.gif'];
    if (!allowed.any(lower.endsWith)) {
      return 'Image posts require a PNG, JPG, JPEG, or GIF file.';
    }

    final message = input.message?.trim();
    if (message == null || message.isEmpty) {
      return 'Missing required --message value.';
    }

    return null;
  }

  @override
  Future<PostImageOutput> execute() async {
    final userConfig = _store.loadUserConfigSync();
    final projectConfig = _store.loadProjectConfigSync();

    final token = userConfig.token;
    if (token == null) {
      return PostImageOutput(
        success: false,
        message: "No LinkedIn token found. Run 'post-publisher auth login' first.",
      );
    }
    if (token.isExpired) {
      return PostImageOutput(
        success: false,
        message: "The cached LinkedIn token is expired. Run 'post-publisher auth login' again.",
      );
    }

    final authorUrn =
        input.organizationUrn ??
        projectConfig.defaultOrganizationUrn ??
        userConfig.profile?.personUrn;
    if (authorUrn == null || authorUrn.isEmpty) {
      return PostImageOutput(
        success: false,
        message: 'Could not determine the LinkedIn author URN.',
      );
    }

    final visibility = input.visibility ?? projectConfig.defaultVisibility;
    final apiVersion = projectConfig.apiVersion.isNotEmpty
        ? projectConfig.apiVersion
        : userConfig.apiVersion;

    try {
      final result = await _api.createImagePost(
        accessToken: token.accessToken,
        authorUrn: authorUrn,
        filePath: input.filePath!.trim(),
        message: input.message!.trim(),
        visibility: visibility,
        apiVersion: apiVersion,
        altText: input.altText?.trim(),
      );

      return PostImageOutput(
        success: true,
        message: 'LinkedIn image post created successfully.',
        postUrn: result.postUrn,
        postUrl: result.postUrl,
      );
    } on LinkedInApiException catch (error) {
      return PostImageOutput(success: false, message: error.toString());
    } on UnimplementedError catch (error) {
      return PostImageOutput(success: false, message: error.toString());
    } catch (error) {
      return PostImageOutput(success: false, message: 'Image post failed: $error');
    }
  }
}