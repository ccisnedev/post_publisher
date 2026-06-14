library;

import 'package:cli_router/cli_router.dart';
import 'package:modular_cli_sdk/modular_cli_sdk.dart';

import '../../../src/config_store.dart';
import '../../../src/linkedin_api.dart';

class PostTextInput extends Input {
  final String? message;
  final String? visibility;
  final String? organizationUrn;

  PostTextInput({this.message, this.visibility, this.organizationUrn});

  factory PostTextInput.fromCliRequest(CliRequest req) => PostTextInput(
    message: req.flagString('message'),
    visibility: req.flagString('visibility'),
    organizationUrn: req.flagString('organization'),
  );

  @override
  Map<String, dynamic> toJson() => {
    if (message != null) 'message': message,
    if (visibility != null) 'visibility': visibility,
    if (organizationUrn != null) 'organizationUrn': organizationUrn,
  };
}

class PostTextOutput extends Output {
  final bool success;
  final String message;
  final String? postUrn;
  final String? postUrl;

  PostTextOutput({
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

class PostTextCommand implements Command<PostTextInput, PostTextOutput> {
  @override
  final PostTextInput input;
  final ConfigStore _store;
  final LinkedInApiClient _api;

  PostTextCommand(
    this.input, {
    ConfigStore? store,
    LinkedInApiClient? api,
  }) : _store = store ?? ConfigStore(),
       _api = api ?? LinkedInApiClient();

  @override
  String? validate() {
    final message = input.message?.trim();
    if (message == null || message.isEmpty) {
      return 'Missing required --message value.';
    }
    return null;
  }

  @override
  Future<PostTextOutput> execute() async {
    final userConfig = _store.loadUserConfigSync();
    final projectConfig = _store.loadProjectConfigSync();

    final token = userConfig.token;
    if (token == null) {
      return PostTextOutput(
        success: false,
        message: "No LinkedIn token found. Run 'linkedin auth login' first.",
      );
    }
    if (token.isExpired) {
      return PostTextOutput(
        success: false,
        message: "The cached LinkedIn token is expired. Run 'linkedin auth login' again.",
      );
    }

    final authorUrn =
      input.organizationUrn ??
      projectConfig.defaultOrganizationUrn ??
      userConfig.profile?.personUrn;
    if (authorUrn == null || authorUrn.isEmpty) {
      return PostTextOutput(
        success: false,
        message: 'Could not determine the LinkedIn author URN.',
      );
    }

    final visibility = input.visibility ?? projectConfig.defaultVisibility;
    final apiVersion = projectConfig.apiVersion.isNotEmpty
        ? projectConfig.apiVersion
        : userConfig.apiVersion;

    try {
      final result = await _api.createTextPost(
        accessToken: token.accessToken,
        authorUrn: authorUrn,
        message: input.message!.trim(),
        visibility: visibility,
        apiVersion: apiVersion,
      );

      return PostTextOutput(
        success: true,
        message: 'LinkedIn post created successfully.',
        postUrn: result.postUrn,
        postUrl: result.postUrl,
      );
    } on LinkedInApiException catch (error) {
      return PostTextOutput(success: false, message: error.toString());
    } catch (error) {
      return PostTextOutput(success: false, message: 'Post failed: $error');
    }
  }
}