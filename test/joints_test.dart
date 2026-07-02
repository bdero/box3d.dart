import 'dart:math' as math;

import 'package:box3d/box3d.dart';
import 'package:test/test.dart';
import 'package:vector_math/vector_math.dart';

void main() {
  setUpAll(Box3d.ensureInitialized);

  late Box3dWorld world;
  setUp(() => world = Box3dWorld(gravity: Vector3(0, -10, 0)));
  tearDown(() => world.dispose());

  // A static anchor body at the origin.
  Box3dBody anchor() => world.createBody(type: Box3dBodyType.static_);

  test('a weld joint holds a body rigidly in place', () {
    final ground = anchor();
    final body = world.createBody(position: Vector3(0, 0, 0));
    body.addBox(Vector3.all(0.5));

    world.createWeldJoint(
      ground,
      body,
      frameB: Box3dFrame(position: Vector3(0, 0, 0)),
    );

    for (var i = 0; i < 120; i++) {
      world.step(1 / 60);
    }
    // Rigidly welded to the static ground, it barely moves despite gravity.
    expect(body.position.y, closeTo(0, 0.05));
  });

  test('a distance joint keeps bodies a fixed distance apart', () {
    final ground = anchor();
    final body = world.createBody(position: Vector3(0, -3, 0));
    body.addSphere(0.3);

    world.createDistanceJoint(ground, body, length: 3);

    for (var i = 0; i < 300; i++) {
      world.step(1 / 60);
    }
    // Hangs 3 units below the anchor.
    expect(body.position.length, closeTo(3, 0.1));
  });

  test('a revolute joint restricts motion to a hinge and can be limited', () {
    final ground = anchor();
    // Arm offset along +X so gravity gives the hinge a moment.
    final arm = world.createBody(position: Vector3(1, 0, 0));
    arm.addBox(Vector3(1, 0.1, 0.1));

    // Hinge about the Z axis at the origin (anchor side) and at the arm's
    // local -X end.
    world.createRevoluteJoint(
      ground,
      arm,
      frameA: Box3dFrame.pointAxis(Vector3(0, 0, 0), Vector3(0, 0, 1)),
      frameB: Box3dFrame.pointAxis(Vector3(-1, 0, 0), Vector3(0, 0, 1)),
      lowerLimit: -math.pi / 4,
      upperLimit: 0,
    );

    for (var i = 0; i < 300; i++) {
      world.step(1 / 60);
    }
    // The arm swings down under gravity but the lower limit stops it at
    // about -45 degrees, so its end cannot fall to a full vertical hang.
    expect(arm.position.y, greaterThan(-0.85));
    expect(arm.position.y, lessThan(0.0));
  });

  test('a spherical joint acts as a ball-and-socket pendulum', () {
    final ground = anchor();
    final bob = world.createBody(position: Vector3(0, -2, 0));
    bob.addSphere(0.3);

    world.createSphericalJoint(
      ground,
      bob,
      frameB: Box3dFrame(position: Vector3(0, 2, 0)),
    );

    for (var i = 0; i < 300; i++) {
      world.step(1 / 60);
    }
    // Stays roughly 2 units from the anchor (the socket radius).
    expect(bob.position.length, closeTo(2, 0.15));
  });

  test('destroying a joint releases the constraint', () {
    final ground = anchor();
    final body = world.createBody(position: Vector3(0, 0, 0));
    body.addSphere(0.3);
    final joint = world.createDistanceJoint(ground, body, length: 0.001);

    world.step(1 / 60);
    joint.destroy();

    for (var i = 0; i < 120; i++) {
      world.step(1 / 60);
    }
    // With the joint gone the body falls freely.
    expect(body.position.y, lessThan(-1));
  });
}
