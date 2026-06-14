library;

import 'dart:io';

import 'package:post_publisher/post_publisher.dart';

Future<void> main(List<String> args) async {
  final code = await runPostPublisherCli(args);
  exit(code);
}