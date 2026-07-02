import 'package:box3d/box3d.dart';
import 'package:test/test.dart';
import 'package:vector_math/vector_math.dart';

void main() {
  setUpAll(Box3d.ensureInitialized);

  late Box3dWorld world;
  setUp(() => world = Box3dWorld(gravity: Vector3(0, -10, 0)));
  tearDown(() => world.dispose());

  test('a falling box generates a contact-begin event on the floor', () {
    final ground = world.createBody(
      type: Box3dBodyType.static_,
      position: Vector3(0, -0.5, 0),
    );
    ground.addBox(Vector3(50, 0.5, 50)).contactEventsEnabled = true;

    final box = world.createBody(position: Vector3(0, 1.0, 0));
    box.addBox(Vector3.all(0.5)).contactEventsEnabled = true;

    var began = 0;
    Box3dContactBegan? first;
    for (var i = 0; i < 120; i++) {
      world.step(1 / 60);
      final events = world.drainEvents();
      if (events.contactBegan.isNotEmpty) {
        began += events.contactBegan.length;
        first ??= events.contactBegan.first;
      }
    }

    expect(began, greaterThan(0));
    final event = first;
    expect(event, isNotNull);
    expect(event!.points, isNotEmpty);
    // The contact normal is roughly vertical and the point is near the floor
    // top (y = 0).
    final p = event.points.first;
    expect(p.normal.y.abs(), greaterThan(0.8));
    expect(p.position.y, closeTo(0, 0.2));
  });

  test('a sensor reports enter and exit as a body passes through', () {
    // A static sensor slab straddling y = 0.
    final trigger = world.createBody(type: Box3dBodyType.static_);
    final sensorShape = trigger.addBox(Vector3(2, 0.5, 2), isSensor: true);
    sensorShape.sensorEventsEnabled = true;

    // A body that falls through the sensor (no solid floor).
    final faller = world.createBody(position: Vector3(0, 3, 0));
    faller.addSphere(0.25).sensorEventsEnabled = true;

    var entered = 0;
    var exited = 0;
    for (var i = 0; i < 240; i++) {
      world.step(1 / 60);
      final events = world.drainEvents();
      for (final e in events.sensorBegan) {
        if (e.sensorShape == sensorShape.handle) entered++;
      }
      for (final e in events.sensorEnded) {
        if (e.sensorShape == sensorShape.handle) exited++;
      }
    }

    expect(entered, 1);
    expect(exited, 1);
  });
}
