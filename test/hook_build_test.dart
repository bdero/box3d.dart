import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../hook/build.dart' as hook;

void main() {
  test('skips native compilation when only data assets are requested', () async {
    final tempDir = await Directory.systemTemp.createTemp('box3d_hook_test_');
    addTearDown(() => tempDir.delete(recursive: true));

    final sharedDir = Directory('${tempDir.path}/shared')..createSync();
    final outputFile = File('${tempDir.path}/output.json');
    final inputFile = File('${tempDir.path}/input.json');
    inputFile.writeAsStringSync(
      jsonEncode({
        'assets': <String, Object?>{},
        'config': {
          'build_asset_types': ['data_assets/data'],
          'linking_enabled': false,
        },
        'out_dir_shared': '${sharedDir.path}${Platform.pathSeparator}',
        'out_file': outputFile.path,
        'package_name': 'box3d',
        'package_root': Directory.current.uri.toFilePath(),
        'user_defines': <String, Object?>{},
      }),
    );

    final result = await Process.run(Platform.resolvedExecutable, [
      'hook/build.dart',
      '--config=${inputFile.path}',
    ]);

    expect(result.exitCode, 0, reason: result.stderr as String);
    expect(outputFile.existsSync(), isTrue);
  });

  group('librariesForTargetOsName', () {
    test('links libm on android and linux targets', () {
      expect(hook.librariesForTargetOsName('android'), ['m']);
      expect(hook.librariesForTargetOsName('linux'), ['m']);
    });

    test('does not link libm on windows or apple targets', () {
      expect(hook.librariesForTargetOsName('windows'), isEmpty);
      expect(hook.librariesForTargetOsName('ios'), isEmpty);
      expect(hook.librariesForTargetOsName('macos'), isEmpty);
    });
  });
  group('definesForTarget', () {
    test('disables SIMD only for android arm32', () {
      expect(
        hook.definesForTarget('android', 'arm'),
        {'BOX3D_DISABLE_SIMD': null},
      );
    });

    test('keeps SIMD enabled for android arm64 and non-android targets', () {
      expect(hook.definesForTarget('android', 'arm64'), isEmpty);
      expect(hook.definesForTarget('linux', 'arm'), isEmpty);
      expect(hook.definesForTarget('windows', 'x64'), isEmpty);
    });
  });
}

