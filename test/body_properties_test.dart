import 'package:box3d/box3d.dart';
import 'package:test/test.dart';
import 'package:vector_math/vector_math.dart';

void main() {
  setUpAll(Box3d.ensureInitialized);

  late Box3dWorld world;
  setUp(() => world = Box3dWorld(gravity: Vector3(0, -10, 0)));
  tearDown(() => world.dispose());

  Box3dBody dynamicBox({Vector3? at}) {
    final body = world.createBody(position: at ?? Vector3(0, 0, 0));
    body.addBox(Vector3.all(0.5));
    return body;
  }

  test('mass comes from shape volume and density', () {
    final body = world.createBody();
    // Unit cube (1x1x1) at density 2 => mass 2.
    body.addBox(Vector3.all(0.5), material: const Box3dMaterial(density: 2));
    expect(body.mass, closeTo(2.0, 1e-3));
  });

  test('an impulse sets linear velocity', () {
    final body = dynamicBox();
    body.applyImpulse(Vector3(0, 0, 5));
    // impulse = mass * dv; unit-density unit cube has mass 1, so dv ~= 5.
    expect(body.linearVelocity.z, closeTo(5, 1e-2));
  });

  test('gravity scale of zero makes a body weightless', () {
    final body = dynamicBox(at: Vector3(0, 5, 0));
    body.gravityScale = 0;
    for (var i = 0; i < 60; i++) {
      world.step(1 / 60);
    }
    expect(body.position.y, closeTo(5, 1e-3));
  });

  test('locking linear axes pins position while gravity pulls', () {
    final body = dynamicBox(at: Vector3(0, 5, 0));
    body.setMotionLocks(linearY: true);
    for (var i = 0; i < 60; i++) {
      world.step(1 / 60);
    }
    expect(body.position.y, closeTo(5, 1e-3));
  });

  test('angular velocity spins the body', () {
    final body = dynamicBox();
    body.gravityScale = 0;
    body.angularVelocity = Vector3(0, 4, 0);
    for (var i = 0; i < 30; i++) {
      world.step(1 / 60);
    }
    // After half a second at 4 rad/s it should have rotated appreciably.
    expect(body.rotation.radians, greaterThan(0.5));
  });

  test('a body settles to sleep and can be woken', () {
    final floor = world.createBody(
      type: Box3dBodyType.static_,
      position: Vector3(0, -0.5, 0),
    );
    floor.addBox(Vector3(50, 0.5, 50));
    final body = dynamicBox(at: Vector3(0, 0.5, 0));

    // Let it come to rest; box3d sleeps resting bodies.
    for (var i = 0; i < 240; i++) {
      world.step(1 / 60);
    }
    expect(body.isAwake, isFalse);

    body.wakeUp();
    expect(body.isAwake, isTrue);
  });

  test('setTransform teleports a kinematic body', () {
    final body = world.createBody(type: Box3dBodyType.kinematic);
    body.addBox(Vector3.all(0.5));
    body.setTransform(Vector3(3, 4, 5));
    world.step(1 / 60);
    final p = body.position;
    expect(p.x, closeTo(3, 1e-4));
    expect(p.y, closeTo(4, 1e-4));
    expect(p.z, closeTo(5, 1e-4));
  });
}
