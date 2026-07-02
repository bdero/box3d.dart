import 'dart:typed_data';

import 'package:box3d/box3d.dart';
import 'package:test/test.dart';
import 'package:vector_math/vector_math.dart';

void main() {
  setUpAll(Box3d.ensureInitialized);

  late Box3dWorld world;
  setUp(() => world = Box3dWorld(gravity: Vector3(0, -10, 0)));
  tearDown(() => world.dispose());

  Box3dBody floor() {
    final body = world.createBody(
      type: Box3dBodyType.static_,
      position: Vector3(0, -0.5, 0),
    );
    body.addBox(Vector3(50, 0.5, 50));
    return body;
  }

  // Drops a body with the given shape and returns its resting height.
  double restingHeight(Box3dBody body) {
    for (var i = 0; i < 240; i++) {
      world.step(1 / 60);
    }
    return body.position.y;
  }

  test('a sphere rests on the floor at its radius', () {
    floor();
    final body = world.createBody(position: Vector3(0, 5, 0));
    body.addSphere(0.5);
    expect(restingHeight(body), closeTo(0.5, 0.05));
  });

  test('a capsule rests on the floor at halfHeight + radius', () {
    floor();
    final body = world.createBody(position: Vector3(0, 5, 0));
    body.addCapsule(0.3, halfHeight: 0.5);
    body.setMotionLocks(angularX: true, angularZ: true); // keep it upright
    expect(restingHeight(body), closeTo(0.8, 0.05));
  });

  test('a cylinder rests on the floor at its halfHeight', () {
    floor();
    final body = world.createBody(position: Vector3(0, 5, 0));
    body.addCylinder(0.5, 0.4);
    expect(restingHeight(body), closeTo(0.5, 0.06));
  });

  test('a convex hull of a unit cube rests at its half-height', () {
    floor();
    final body = world.createBody(position: Vector3(0, 5, 0));
    final cube = Float32List.fromList(<double>[
      -0.5, -0.5, -0.5, 0.5, -0.5, -0.5, 0.5, 0.5, -0.5, -0.5, 0.5, -0.5, //
      -0.5, -0.5, 0.5, 0.5, -0.5, 0.5, 0.5, 0.5, 0.5, -0.5, 0.5, 0.5,
    ]);
    final shape = body.addConvexHull(cube);
    expect(shape, isNotNull);
    expect(restingHeight(body), closeTo(0.5, 0.06));
  });

  test('convex hull rejects a degenerate point set', () {
    final body = world.createBody();
    // All points colinear: not a valid 3D hull.
    final line = Float32List.fromList(<double>[0, 0, 0, 1, 0, 0, 2, 0, 0]);
    expect(body.addConvexHull(line), isNull);
  });

  test('collision filtering lets a body pass through the floor', () {
    // Floor in category 1, colliding only with category 2.
    final ground = world.createBody(
      type: Box3dBodyType.static_,
      position: Vector3(0, -0.5, 0),
    );
    ground
        .addBox(Vector3(50, 0.5, 50))
        .setCollisionFilter(category: 1, mask: 2);

    // Faller in category 4, colliding only with category 1. Since the floor
    // does not accept category 4, the pair never collides.
    final body = world.createBody(position: Vector3(0, 5, 0));
    body.addBox(Vector3.all(0.5)).setCollisionFilter(category: 4, mask: 1);

    expect(restingHeight(body), lessThan(-1));
  });

  test('setMaterial and destroy work on a shape', () {
    final body = world.createBody();
    final shape = body.addBox(Vector3.all(0.5));
    shape.setMaterial(const Box3dMaterial(friction: 0.9, density: 3));
    expect(body.mass, closeTo(3.0, 1e-3));
    shape.destroy();
    // A dynamic body with no shapes has no mass.
    expect(body.mass, closeTo(0.0, 1e-3));
  });
}
