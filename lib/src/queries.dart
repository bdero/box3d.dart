import 'package:vector_math/vector_math.dart';

/// A hit from a ray cast or shape cast. [shape] is the packed shape handle
/// (compare against a [Box3dShape.handle]).
class Box3dRayHit {
  Box3dRayHit({
    required this.shape,
    required this.point,
    required this.normal,
    required this.fraction,
    required this.distance,
  });

  final int shape;

  /// World-space hit point.
  final Vector3 point;

  /// World-space surface normal at the hit.
  final Vector3 normal;

  /// Fraction along the cast (0 at the origin, 1 at the far end) where the
  /// hit occurred.
  final double fraction;

  /// Distance from the cast origin to the hit, in world units.
  final double distance;
}
