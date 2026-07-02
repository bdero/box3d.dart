import 'package:box3d/box3d.dart';
import 'package:test/test.dart';
import 'package:vector_math/vector_math.dart';

void main() {
  setUpAll(Box3d.ensureInitialized);

  late Box3dWorld world;
  setUp(() => world = Box3dWorld());
  tearDown(() => world.dispose());

  // Destroying a body cascades to its shapes in box3d, so destroying a shape
  // afterwards operates on an already-freed shape. This must be a safe no-op,
  // not a crash (the scene-graph unmount order can destroy the body first).
  test('destroying a shape after its body is a safe no-op', () {
    for (var i = 0; i < 30; i++) {
      final body = world.createBody(position: Vector3(0, i.toDouble(), 0));
      final box = body.addBox(Vector3.all(0.5)); // a hull-based shape
      final sphere = body.addSphere(0.5);
      body.destroy();
      // These would double-free without the shim's validity guard.
      box.destroy();
      sphere.destroy();
    }
    world.step(1 / 60);
  });

  test('destroying the same shape twice is a safe no-op', () {
    final body = world.createBody();
    final box = body.addBox(Vector3.all(0.5));
    box.destroy();
    box.destroy();
    world.step(1 / 60);
  });
}
