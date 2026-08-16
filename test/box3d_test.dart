import 'dart:io';

import 'package:box3d/box3d.dart';
import 'package:test/test.dart';

void main() {
  test('reports the pubspec version', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(
      r'^version:\s*(\S+)',
      multiLine: true,
    ).firstMatch(pubspec)?.group(1);

    expect(version, isNotNull, reason: 'no version in pubspec.yaml');
    expect(box3dBindingsVersion, version);
  });
}
