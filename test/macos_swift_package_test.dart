import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('macOS Swift package local dependencies exist in the repository', () {
    final packageFile = File(
      'plugins/deepsky_bluetooth_macos/macos/deepsky_bluetooth_macos/Package.swift',
    );
    final packageDir = packageFile.parent;
    final packageSource = packageFile.readAsStringSync();
    final pathDependency = RegExp(
      r'\.package\(name:\s*"FlutterFramework",\s*path:\s*"([^"]+)"\)',
    ).firstMatch(packageSource)?.group(1);

    expect(pathDependency, isNotNull);
    expect(
      Directory('${packageDir.path}/$pathDependency').existsSync(),
      isTrue,
    );
  });
}
