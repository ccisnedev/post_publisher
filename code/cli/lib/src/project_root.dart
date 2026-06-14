library;

import 'dart:io';

String? getProjectRoot(String startDirectory) {
  var current = Directory(startDirectory).absolute;

  while (true) {
    if (Directory('${current.path}${Platform.pathSeparator}.git').existsSync()) {
      return current.path;
    }

    final parent = current.parent;
    if (parent.path == current.path) {
      return null;
    }
    current = parent;
  }
}