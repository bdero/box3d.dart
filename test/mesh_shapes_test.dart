import 'dart:typed_data';

import 'package:box3d/box3d.dart';
import 'package:test/test.dart';
import 'package:vector_math/vector_math.dart';

void main() {
  setUpAll(Box3d.ensureInitialized);

  late Box3dWorld world;
  setUp(() => world = Box3dWorld(gravity: Vector3(0, -10, 0)));
  tearDown(() => world.dispose());

  test('a sphere rests on a triangle-mesh floor', () {
    // A large flat quad at y = 0 made of two triangles. Wound so the face
    // normal points up (+Y); mesh triangles are one-sided.
    final vertices = Float32List.fromList(<double>[
      -50, 0, -50, 50, 0, -50, 50, 0, 50, -50, 0, 50, //
    ]);
    final indices = Uint32List.fromList(<int>[0, 2, 1, 0, 3, 2]);

    final ground = world.createBody(type: Box3dBodyType.static_);
    final mesh = ground.addTriMesh(vertices, indices);
    expect(mesh, isNotNull);

    final ball = world.createBody(position: Vector3(0, 5, 0));
    ball.addSphere(0.5);

    for (var i = 0; i < 240; i++) {
      world.step(1 / 60);
    }
    expect(ball.position.y, closeTo(0.5, 0.06));
  });

  test('a sphere rests on a flat height field', () {
    // A flat 4x4 grid at height 0.
    final heights = Float32List(16); // all zeros
    final ground = world.createBody(
      type: Box3dBodyType.static_,
      position: Vector3(-1.5, 0, -1.5),
    );
    final field = ground.addHeightField(
      countX: 4,
      countZ: 4,
      heights: heights,
      scale: Vector3(1, 1, 1),
    );
    expect(field, isNotNull);

    final ball = world.createBody(position: Vector3(0, 5, 0));
    ball.addSphere(0.5);

    for (var i = 0; i < 300; i++) {
      world.step(1 / 60);
    }
    expect(ball.position.y, closeTo(0.5, 0.1));
  });

  test('destroying a mesh shape frees its owned data', () {
    // Exercises the ownership registry's per-shape free path.
    final vertices = Float32List.fromList(<double>[
      -1, 0, -1, 1, 0, -1, 1, 0, 1, -1, 0, 1, //
    ]);
    final indices = Uint32List.fromList(<int>[0, 1, 2, 0, 2, 3]);
    final ground = world.createBody(type: Box3dBodyType.static_);
    final mesh = ground.addTriMesh(vertices, indices)!;
    mesh.destroy();
    // Stepping afterwards must not touch the freed mesh.
    world.step(1 / 60);
  });
}
