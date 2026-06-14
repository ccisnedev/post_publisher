library;

import 'package:cli_router/cli_router.dart';
import 'package:modular_cli_sdk/modular_cli_sdk.dart';

const String linkedInHelpText =
    'Usage:\n'
    '  post-publisher                 Display CLI status and quick-start help\n'
    '  post-publisher help            Show this help\n'
    '  post-publisher --help          Show this help\n'
    '  post-publisher -h              Show this help\n'
    '  post-publisher <command> ...\n'
    '  (pp is a short alias for post-publisher)\n'
    '\n'
    'Root commands:\n'
    '  help       Show available commands\n'
    '  init       Create project-level defaults in .post_publisher/config.json\n'
    '  version    Print the current CLI version\n'
    '  doctor     Verify Dart, Git, LinkedIn credentials, and auth status\n'
    '  upgrade    Download and install the latest Post Publisher release\n'
    '  uninstall  Remove Post Publisher from the system\n'
    '\n'
    'Modules:\n'
    '  auth configure   Save LinkedIn app credentials for this machine\n'
    '  auth login       Sign in with LinkedIn and cache the access token\n'
    '  auth signin      Alias for auth login\n'
    '  auth status      Show the current LinkedIn auth status\n'
    '  auth logout      Remove the cached LinkedIn token\n'
    '  post text        Publish a text post as yourself or an organization\n'
    '  post image       Publish an image post from a local file\n'
    '  post document    Publish a PDF document post from a local file\n';

class HelpInput extends Input {
  HelpInput();

  factory HelpInput.fromCliRequest(CliRequest req) => HelpInput();

  @override
  Map<String, dynamic> toJson() => {};
}

class HelpOutput extends Output {
  final String text;

  HelpOutput({required this.text});

  @override
  Map<String, dynamic> toJson() => {'help': text};

  @override
  int get exitCode => ExitCode.ok;

  @override
  String? toText() => text;
}

class HelpCommand implements Command<HelpInput, HelpOutput> {
  @override
  final HelpInput input;

  HelpCommand(this.input);

  @override
  String? validate() => null;

  @override
  Future<HelpOutput> execute() async {
    return HelpOutput(text: linkedInHelpText);
  }
}