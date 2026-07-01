import 'package:box3d/box3d.dart';
import 'package:test/test.dart';
import 'package:vector_math/vector_math.dart';

void main() {
  setUpAll(Box3d.ensureInitialized);

  test('a dynamic box falls under gravity and rests on a static floor', () {
    final world = Box3dWorld(gravity: Vector3(0, -10, 0));
    addTearDown(world.dispose);

    // A static floor: a wide, thin box centered just below the origin so
    // its top surface sits at y = 0.
    final floor = world.createBody(
      type: Box3dBodyType.static_,
      position: Vector3(0, -0.5, 0),
    );
    floor.addBox(Vector3(50, 0.5, 50));

    // A dynamic unit box dropped from a few units up.
    final box = world.createBody(position: Vector3(0, 5, 0));
    box.addBox(Vector3.all(0.5));

    expect(box.position.y, closeTo(5, 1e-4));

    // Step for two seconds of simulated time.
    for (var i = 0; i < 120; i++) {
      world.step(1 / 60);
    }

    // It should have fallen and come to rest on the floor, its center near
    // half its height above y = 0.
    expect(box.position.y, closeTo(0.5, 0.1));
    expect(box.position.x, closeTo(0, 0.1));
    expect(box.position.z, closeTo(0, 0.1));
    expect(box.linearVelocity.length, lessThan(0.1));
  });

  test('reports single precision', () {
    // Constructing a world touches the native bindings, whose constructor
    // asserts the library is single precision. If we got here, it is.
    final world = Box3dWorld();
    addTearDown(world.dispose);
    final body = world.createBody(position: Vector3(0, 10, 0));
    body.addSphere(0.5);

    world.step(1 / 60);
    // A single 1/60 step under default gravity moves the sphere only a
    // little; mostly this checks the read path returns sane values.
    expect(body.position.y, lessThan(10));
    expect(body.position.y, greaterThan(9.9));
  });
}
