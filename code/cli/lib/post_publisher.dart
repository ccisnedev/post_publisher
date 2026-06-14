library;

import 'package:modular_cli_sdk/modular_cli_sdk.dart';

import 'modules/auth/auth_builder.dart';
import 'modules/global/global_builder.dart';
import 'modules/post/post_builder.dart';

List<String> normalizePostPublisherArgs(List<String> args) {
  if (args.length == 1 && (args.first == '--help' || args.first == '-h')) {
    return const ['help'];
  }
  if (args.length == 1 && (args.first == '--version' || args.first == '-v')) {
    return const ['version'];
  }
  return args;
}

Future<int> runPostPublisherCli(List<String> args) async {
  final cli = ModularCli();

  cli.module('', buildGlobalModule);
  cli.module('auth', buildAuthModule);
  cli.module('post', buildPostModule);

  return cli.run(normalizePostPublisherArgs(args));
}