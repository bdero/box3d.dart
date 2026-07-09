import 'package:test/test.dart';

import '../hook/build.dart' as hook;

void main() {
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

