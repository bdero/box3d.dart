import 'package:vector_math/vector_math.dart';

/// One point of a solid contact manifold.
class Box3dContactPoint {
  Box3dContactPoint({
    required this.position,
    required this.normal,
    required this.impulse,
    required this.separation,
  });

  /// World-space contact position.
  final Vector3 position;

  /// World-space contact normal (points from shape A toward shape B).
  final Vector3 normal;

  /// Normal impulse the solver applied at this point during the step.
  final double impulse;

  /// Gap along the normal: negative when the shapes interpenetrate.
  final double separation;
}

/// Two shapes began touching this step. [shapeA] / [shapeB] are the packed
/// shape handles (compare against a [Box3dShape.handle]).
class Box3dContactBegan {
  Box3dContactBegan({
    required this.shapeA,
    required this.shapeB,
    required this.points,
  });

  final int shapeA;
  final int shapeB;

  /// The contact manifold points for this touch.
  final List<Box3dContactPoint> points;
}

/// Two shapes stopped touching this step.
class Box3dContactEnded {
  Box3dContactEnded({required this.shapeA, required this.shapeB});

  final int shapeA;
  final int shapeB;
}

/// A shape entered a sensor this step. [sensorShape] is the sensor;
/// [visitorShape] is the shape that entered it.
class Box3dSensorBegan {
  Box3dSensorBegan({required this.sensorShape, required this.visitorShape});

  final int sensorShape;
  final int visitorShape;
}

/// A shape left a sensor this step.
class Box3dSensorEnded {
  Box3dSensorEnded({required this.sensorShape, required this.visitorShape});

  final int sensorShape;
  final int visitorShape;
}

/// All events collected during one [Box3dWorld.step], drained together.
class Box3dEvents {
  Box3dEvents({
    required this.contactBegan,
    required this.contactEnded,
    required this.sensorBegan,
    required this.sensorEnded,
  });

  final List<Box3dContactBegan> contactBegan;
  final List<Box3dContactEnded> contactEnded;
  final List<Box3dSensorBegan> sensorBegan;
  final List<Box3dSensorEnded> sensorEnded;

  /// Whether any event of any kind occurred.
  bool get isEmpty =>
      contactBegan.isEmpty &&
      contactEnded.isEmpty &&
      sensorBegan.isEmpty &&
      sensorEnded.isEmpty;
}
