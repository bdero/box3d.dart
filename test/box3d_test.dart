import 'package:box3d/box3d.dart';
import 'package:test/test.dart';

void main() {
  test('exposes a bindings version', () {
    expect(box3dBindingsVersion, isNotEmpty);
  });
}
