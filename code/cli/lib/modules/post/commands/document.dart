library;

import 'dart:io';

import 'package:cli_router/cli_router.dart';
import 'package:modular_cli_sdk/modular_cli_sdk.dart';
import 'package:path/path.dart' as p;

import '../../../src/config_store.dart';
import '../../../src/linkedin_api.dart';

class PostDocumentInput extends Input {
  final String? filePath;
  final String? message;
  final String? visibility;
  final String? organizationUrn;
  final String? title;

  PostDocumentInput({
    this.filePath,
    this.message,
    this.visibility,
    this.organizationUrn,
    this.title,
  });

  factory PostDocumentInput.fromCliRequest(CliRequest req) => PostDocumentInput(
    filePath: req.flagString('file'),
    message: req.flagString('message'),
    visibility: req.flagString('visibility'),
    organizationUrn: req.flagString('organization'),
    title: req.flagString('title'),
  );

  @override
  Map<String, dynamic> toJson() => {
    if (filePath != null) 'filePath': filePath,
    if (message != null) 'message': message,
    if (visibility != null) 'visibility': visibility,
    if (organizationUrn != null) 'organizationUrn': organizationUrn,
    if (title != null) 'title': title,
  };
}

class PostDocumentOutput extends Output {
  final bool success;
  final String message;
  final String? postUrn;
  final String? postUrl;

  PostDocumentOutput({
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

class PostDocumentCommand
    implements Command<PostDocumentInput, PostDocumentOutput> {
  @override
  final PostDocumentInput input;
  final ConfigStore _store;
  final LinkedInApiClient _api;

  PostDocumentCommand(
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

    if (!filePath.toLowerCase().endsWith('.pdf')) {
      return 'Document posts currently require a PDF file.';
    }

    final message = input.message?.trim();
    if (message == null || message.isEmpty) {
      return 'Missing required --message value.';
    }

    return null;
  }

  @override
  Future<PostDocumentOutput> execute() async {
    final userConfig = _store.loadUserConfigSync();
    final projectConfig = _store.loadProjectConfigSync();

    final token = userConfig.token;
    if (token == null) {
      return PostDocumentOutput(
        success: false,
        message: "No LinkedIn token found. Run 'post-publisher auth login' first.",
      );
    }
    if (token.isExpired) {
      return PostDocumentOutput(
        success: false,
        message: "The cached LinkedIn token is expired. Run 'post-publisher auth login' again.",
      );
    }

    final authorUrn =
        input.organizationUrn ??
        projectConfig.defaultOrganizationUrn ??
        userConfig.profile?.personUrn;
    if (authorUrn == null || authorUrn.isEmpty) {
      return PostDocumentOutput(
        success: false,
        message: 'Could not determine the LinkedIn author URN.',
      );
    }

    final visibility = input.visibility ?? projectConfig.defaultVisibility;
    final apiVersion = projectConfig.apiVersion.isNotEmpty
        ? projectConfig.apiVersion
        : userConfig.apiVersion;
    final filePath = input.filePath!.trim();
    final title = input.title?.trim().isNotEmpty == true
        ? input.title!.trim()
        : p.basename(filePath);

    try {
      final result = await _api.createDocumentPost(
        accessToken: token.accessToken,
        authorUrn: authorUrn,
        filePath: filePath,
        title: title,
        message: input.message!.trim(),
        visibility: visibility,
        apiVersion: apiVersion,
      );

      return PostDocumentOutput(
        success: true,
        message: 'LinkedIn document post created successfully.',
        postUrn: result.postUrn,
        postUrl: result.postUrl,
      );
    } on LinkedInApiException catch (error) {
      return PostDocumentOutput(success: false, message: error.toString());
    } on UnimplementedError catch (error) {
      return PostDocumentOutput(success: false, message: error.toString());
    } catch (error) {
      return PostDocumentOutput(
        success: false,
        message: 'Document post failed: $error',
      );
    }
  }
}