import 'package:box3d/box3d.dart';
import 'package:test/test.dart';
import 'package:vector_math/vector_math.dart';

void main() {
  setUpAll(Box3d.ensureInitialized);

  late Box3dWorld world;
  setUp(() => world = Box3dWorld(gravity: Vector3(0, 0, 0)));
  tearDown(() => world.dispose());

  // A static unit box centered at [center]; returns its shape.
  Box3dShape box(Vector3 center) {
    final body = world.createBody(
      type: Box3dBodyType.static_,
      position: center,
    );
    return body.addBox(Vector3.all(0.5));
  }

  test('raycast returns the closest shape and hit geometry', () {
    box(Vector3(5, 0, 0));
    box(Vector3(10, 0, 0));

    final hit = world.raycast(Vector3(0, 0, 0), Vector3(1, 0, 0));
    expect(hit, isNotNull);
    // Front face of the nearer box is at x = 4.5.
    expect(hit!.point.x, closeTo(4.5, 0.05));
    expect(hit.distance, closeTo(4.5, 0.05));
    expect(hit.normal.x, closeTo(-1, 0.05));
  });

  test('raycast misses when nothing is in the way', () {
    box(Vector3(0, 10, 0));
    final hit = world.raycast(Vector3(0, 0, 0), Vector3(1, 0, 0));
    expect(hit, isNull);
  });

  test('raycastAll returns every shape along the ray', () {
    box(Vector3(5, 0, 0));
    box(Vector3(10, 0, 0));
    final hits = world.raycastAll(Vector3(0, 0, 0), Vector3(1, 0, 0));
    expect(hits.length, 2);
  });

  test('overlapSphere finds shapes within the sphere', () {
    final near = box(Vector3(1, 0, 0));
    box(Vector3(20, 0, 0));
    final hits = world.overlapSphere(Vector3(0, 0, 0), 2);
    expect(hits, contains(near.handle));
    expect(hits.length, 1);
  });

  test('overlapBox finds shapes within the box', () {
    final inside = box(Vector3(0, 0, 0));
    box(Vector3(20, 0, 0));
    final hits = world.overlapBox(Vector3(0, 0, 0), Vector3.all(1));
    expect(hits, contains(inside.handle));
  });

  test('shapeCastSphere sweeps a sphere until it hits', () {
    final target = box(Vector3(5, 0, 0));
    final hit = world.shapeCastSphere(Vector3(0, 0, 0), 0.5, Vector3(1, 0, 0));
    expect(hit, isNotNull);
    expect(hit!.shape, target.handle);
    // Sphere radius 0.5 stops when its surface reaches the box face at
    // x = 4.5, so its center travels ~4.0.
    expect(hit.distance, closeTo(4.0, 0.1));
  });
}
