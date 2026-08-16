// Covers the build hook's target-dependent choices without running a real
// cross-compile, plus the data-assets-only invocation that has no code
// config to read.

import 'dart:convert';
import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:test/test.dart';

import '../hook/build.dart' as hook;

void main() {
  test(
    'skips native compilation when only data assets are requested',
    () async {
      final tempDir = await Directory.systemTemp.createTemp('box3d_hook_test_');
      addTearDown(() => tempDir.delete(recursive: true));

      final sharedDir = Directory('${tempDir.path}/shared')..createSync();
      final outputFile = File('${tempDir.path}/output.json');
      final inputFile = File('${tempDir.path}/input.json');
      // Hand-built because the hook protocol has no test helper for it. The
      // schema belongs to package:hooks, so a protocol bump can break this
      // test without anything in box3d changing.
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
    },
  );

  group('librariesForTarget', () {
    test('links libm on android and linux', () {
      expect(hook.librariesForTarget(OS.android), ['m']);
      expect(hook.librariesForTarget(OS.linux), ['m']);
    });

    test('links nothing on windows and apple targets', () {
      expect(hook.librariesForTarget(OS.windows), isEmpty);
      expect(hook.librariesForTarget(OS.iOS), isEmpty);
      expect(hook.librariesForTarget(OS.macOS), isEmpty);
    });
  });

  group('definesForTarget', () {
    test('disables SIMD on 32-bit arm regardless of OS', () {
      expect(hook.definesForTarget(Architecture.arm), {
        'BOX3D_DISABLE_SIMD': null,
      });
    });

    test('keeps SIMD enabled on arm64 and x64', () {
      expect(hook.definesForTarget(Architecture.arm64), isEmpty);
      expect(hook.definesForTarget(Architecture.x64), isEmpty);
    });
  });
}
