import 'package:vector_math/vector_math.dart';

import 'ffi/box3d_bindings.dart';
import 'physics_types.dart';

/// A rigid body in a [Box3dWorld]. Create one with `world.createBody(...)`.
///
/// A body is a point mass with a transform; its collision volume comes from
/// the shapes attached with [addSphere] / [addBox].
class Box3dBody {
  /// Constructed by [Box3dWorld]; not part of the public API.
  Box3dBody(this._bindings, this.handle, this.type);

  final Box3dBindings _bindings;

  /// The packed uint64 body handle from the shim.
  final int handle;

  /// How this body participates in the simulation.
  final Box3dBodyType type;

  bool _destroyed = false;

  /// The body's world-space position.
  Vector3 get position => _bindings.bodyPosition(handle);

  /// The body's world-space orientation.
  Quaternion get rotation => _bindings.bodyRotation(handle);

  /// The body's linear velocity, in units per second.
  Vector3 get linearVelocity => _bindings.bodyLinearVelocity(handle);

  set linearVelocity(Vector3 value) =>
      _bindings.bodySetLinearVelocity(handle, value.x, value.y, value.z);

  /// Attaches a sphere collider and returns its handle.
  Box3dShape addSphere(
    double radius, {
    Vector3? center,
    Box3dMaterial material = Box3dMaterial.standard,
    bool isSensor = false,
  }) {
    final c = center ?? Vector3.zero();
    return Box3dShape(
      _bindings.shapeSphere(
        handle,
        c.x,
        c.y,
        c.z,
        radius,
        material.friction,
        material.restitution,
        material.density,
        isSensor,
      ),
    );
  }

  /// Attaches a box collider (given its half-extents) and returns its
  /// handle.
  Box3dShape addBox(
    Vector3 halfExtents, {
    Box3dMaterial material = Box3dMaterial.standard,
    bool isSensor = false,
  }) {
    return Box3dShape(
      _bindings.shapeBox(
        handle,
        halfExtents.x,
        halfExtents.y,
        halfExtents.z,
        material.friction,
        material.restitution,
        material.density,
        isSensor,
      ),
    );
  }

  /// Removes this body (and its shapes) from the world.
  void destroy() {
    if (_destroyed) return;
    _destroyed = true;
    _bindings.bodyDestroy(handle);
  }
}
