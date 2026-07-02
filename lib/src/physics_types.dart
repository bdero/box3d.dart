import 'dart:math' as math;

import 'package:vector_math/vector_math.dart';

import 'ffi/box3d_bindings.dart';

/// How a body participates in the simulation.
enum Box3dBodyType {
  /// Never moves. Zero mass, infinite inertia.
  static_(bodyKindStatic),

  /// Moved only by setting its transform or velocity; unaffected by forces
  /// and collisions.
  kinematic(bodyKindKinematic),

  /// Fully simulated: moved by gravity, forces, and contacts.
  dynamic_(bodyKindDynamic);

  const Box3dBodyType(this.kind);

  /// The byte passed across the shim ABI (matches box3d's b3BodyType).
  final int kind;
}

/// Surface properties of a shape.
class Box3dMaterial {
  const Box3dMaterial({
    this.friction = 0.6,
    this.restitution = 0.0,
    this.density = 1.0,
  });

  /// Coulomb (dry) friction coefficient, usually in [0, 1].
  final double friction;

  /// Coefficient of restitution (bounciness), usually in [0, 1].
  final double restitution;

  /// Mass per unit volume, usually in kg/m^3.
  final double density;

  /// A reasonable default surface (moderate friction, no bounce, unit
  /// density).
  static const Box3dMaterial standard = Box3dMaterial();
}

/// A collider attached to a [Box3dBody]. Returned by the body's `add*`
/// shape methods; use it to change the surface material, collision filter,
/// or to remove the collider.
class Box3dShape {
  /// Constructed by [Box3dBody]; not part of the public API.
  Box3dShape(this._bindings, this.handle);

  final Box3dBindings _bindings;

  /// The packed uint64 shape handle from the shim.
  final int handle;

  bool _destroyed = false;

  /// Replaces the shape's surface material (friction, restitution, and
  /// density; changing density recomputes the body's mass).
  void setMaterial(Box3dMaterial material) => _bindings.shapeSetMaterial(
    handle,
    material.friction,
    material.restitution,
    material.density,
  );

  /// Sets collision filtering. A pair of shapes collides only when each
  /// one's [category] intersects the other's [mask]; a non-zero, matching
  /// [group] forces always-collide (positive) or never-collide (negative).
  void setCollisionFilter({
    required int category,
    required int mask,
    int group = 0,
  }) => _bindings.shapeSetFilter(handle, category, mask, group);

  /// Whether this shape emits sensor (overlap) events.
  set sensorEventsEnabled(bool value) =>
      _bindings.shapeEnableSensorEvents(handle, value);

  /// Whether this shape emits contact (begin/end touch) events.
  set contactEventsEnabled(bool value) =>
      _bindings.shapeEnableContactEvents(handle, value);

  /// Removes this collider from its body. [updateBodyMass] recomputes the
  /// body's mass from its remaining shapes.
  void destroy({bool updateBodyMass = true}) {
    if (_destroyed) return;
    _destroyed = true;
    _bindings.shapeDestroy(handle, updateBodyMass);
  }
}

/// A joint's attachment frame on one body: a body-local anchor [position]
/// and a [rotation].
///
/// Different joints read the working axis from a different local frame axis:
/// a revolute joint hinges about the frame's local +Z ([Box3dFrame.pointAxis]),
/// while a prismatic joint slides along the frame's local +X
/// ([Box3dFrame.pointAxisX]).
class Box3dFrame {
  Box3dFrame({Vector3? position, Quaternion? rotation})
    : position = position ?? Vector3.zero(),
      rotation = rotation ?? Quaternion.identity();

  /// A frame at [anchor] whose local +Z axis points along [axis]. Use for a
  /// revolute joint's hinge axis.
  factory Box3dFrame.pointAxis(Vector3 anchor, Vector3 axis) =>
      Box3dFrame(position: anchor, rotation: _rotationBetween(_z, axis));

  /// A frame at [anchor] whose local +X axis points along [axis]. Use for a
  /// prismatic joint's slide axis.
  factory Box3dFrame.pointAxisX(Vector3 anchor, Vector3 axis) =>
      Box3dFrame(position: anchor, rotation: _rotationBetween(_x, axis));

  final Vector3 position;
  final Quaternion rotation;

  static final Vector3 _x = Vector3(1, 0, 0);
  static final Vector3 _z = Vector3(0, 0, 1);

  // The shortest rotation taking unit vector [from] onto [to].
  static Quaternion _rotationBetween(Vector3 from, Vector3 to) {
    final a = to.normalized();
    final dot = from.dot(a);
    if (dot > 0.999999) return Quaternion.identity();
    if (dot < -0.999999) {
      // Antiparallel: rotate 180 degrees about any perpendicular axis.
      final perp = (from.x.abs() < 0.9 ? Vector3(1, 0, 0) : Vector3(0, 1, 0))
        ..cross(from)
        ..normalize();
      return Quaternion.axisAngle(perp, math.pi);
    }
    final cross = from.cross(a)..normalize();
    return Quaternion.axisAngle(cross, math.acos(dot.clamp(-1.0, 1.0)));
  }
}

/// A constraint between two bodies. Create one with the `world.create*Joint`
/// methods; call [destroy] to remove it.
class Box3dJoint {
  /// Constructed by [Box3dWorld]; not part of the public API.
  Box3dJoint(this._bindings, this.handle);

  final Box3dBindings _bindings;

  /// The packed uint64 joint handle from the shim.
  final int handle;

  bool _destroyed = false;

  /// Removes this joint. [wakeBodies] wakes the connected bodies.
  void destroy({bool wakeBodies = true}) {
    if (_destroyed) return;
    _destroyed = true;
    _bindings.jointDestroy(handle, wakeBodies);
  }
}
