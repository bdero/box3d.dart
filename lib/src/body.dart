import 'package:vector_math/vector_math.dart';

import 'ffi/box3d_bindings.dart';
import 'physics_types.dart';

/// A rigid body in a [Box3dWorld]. Create one with `world.createBody(...)`.
///
/// A body is a point mass with a transform; its collision volume comes from
/// the shapes attached with [addSphere] / [addBox] and the other shape
/// methods.
class Box3dBody {
  /// Constructed by [Box3dWorld]; not part of the public API.
  Box3dBody(this._bindings, this.handle, this._type);

  final Box3dBindings _bindings;

  /// The packed uint64 body handle from the shim.
  final int handle;

  Box3dBodyType _type;

  bool _destroyed = false;

  /// How this body participates in the simulation.
  Box3dBodyType get type => _type;

  set type(Box3dBodyType value) {
    _type = value;
    _bindings.bodySetKind(handle, value.kind);
  }

  // --- Transform -------------------------------------------------------------

  /// The body's world-space position.
  Vector3 get position => _bindings.bodyPosition(handle);

  /// The body's world-space orientation.
  Quaternion get rotation => _bindings.bodyRotation(handle);

  /// Teleports the body to [position] / [rotation]. For a dynamic body this
  /// is an instantaneous move (not a swept motion); for a kinematic body,
  /// prefer setting [linearVelocity] so it sweeps and pushes dynamic bodies.
  void setTransform(Vector3 position, [Quaternion? rotation]) {
    final q = rotation ?? this.rotation;
    _bindings.bodySetTransform(
      handle,
      position.x,
      position.y,
      position.z,
      q.x,
      q.y,
      q.z,
      q.w,
    );
  }

  // --- Velocity and damping --------------------------------------------------

  /// The body's linear velocity, in units per second.
  Vector3 get linearVelocity => _bindings.bodyLinearVelocity(handle);

  set linearVelocity(Vector3 value) =>
      _bindings.bodySetLinearVelocity(handle, value.x, value.y, value.z);

  /// The body's angular velocity, in radians per second.
  Vector3 get angularVelocity => _bindings.bodyAngularVelocity(handle);

  set angularVelocity(Vector3 value) =>
      _bindings.bodySetAngularVelocity(handle, value.x, value.y, value.z);

  /// Reduces linear velocity over time. 0 disables damping.
  set linearDamping(double value) =>
      _bindings.bodySetLinearDamping(handle, value);

  /// Reduces angular velocity over time. 0 disables damping.
  set angularDamping(double value) =>
      _bindings.bodySetAngularDamping(handle, value);

  /// Scales the gravity applied to this body (1 is normal, 0 is weightless).
  set gravityScale(double value) =>
      _bindings.bodySetGravityScale(handle, value);

  // --- Mass ------------------------------------------------------------------

  /// The body's total mass in kilograms, computed from its shapes.
  double get mass => _bindings.bodyMass(handle);

  /// Recomputes mass, center of mass, and inertia from the attached shapes.
  /// Shapes update the mass automatically; call this after changing a
  /// shape's density if you disabled that automatic update.
  void recomputeMass() => _bindings.bodyApplyMassFromShapes(handle);

  // --- Locks and continuous collision ----------------------------------------

  /// Prevents motion along the given axes. Locked axes neither translate
  /// (linear) nor rotate (angular).
  void setMotionLocks({
    bool linearX = false,
    bool linearY = false,
    bool linearZ = false,
    bool angularX = false,
    bool angularY = false,
    bool angularZ = false,
  }) => _bindings.bodySetMotionLocks(
    handle,
    linearX,
    linearY,
    linearZ,
    angularX,
    angularY,
    angularZ,
  );

  /// Treats this body as a fast-moving object that performs continuous
  /// collision detection against non-bullet bodies. Use sparingly.
  set isBullet(bool value) => _bindings.bodySetBullet(handle, value);

  // --- Sleeping --------------------------------------------------------------

  /// Whether the body is currently awake (being simulated).
  bool get isAwake => _bindings.bodyIsAwake(handle);

  /// Wakes the body if it is sleeping.
  void wakeUp() => _bindings.bodySetAwake(handle, true);

  /// Puts the body to sleep.
  void sleep() => _bindings.bodySetAwake(handle, false);

  /// Whether this body is allowed to fall asleep when it comes to rest.
  set sleepEnabled(bool value) => _bindings.bodyEnableSleep(handle, value);

  // --- Forces and impulses ---------------------------------------------------

  /// Applies a continuous [force] this step. With [point] (world-space) the
  /// force also produces torque; without it the force acts at the center of
  /// mass.
  void applyForce(Vector3 force, {Vector3? point, bool wake = true}) {
    final p = point ?? Vector3.zero();
    _bindings.bodyApplyForce(
      handle,
      force.x,
      force.y,
      force.z,
      point != null,
      p.x,
      p.y,
      p.z,
      wake,
    );
  }

  /// Applies an instantaneous [impulse]. With [point] (world-space) it also
  /// produces angular velocity; without it it acts at the center of mass.
  void applyImpulse(Vector3 impulse, {Vector3? point, bool wake = true}) {
    final p = point ?? Vector3.zero();
    _bindings.bodyApplyImpulse(
      handle,
      impulse.x,
      impulse.y,
      impulse.z,
      point != null,
      p.x,
      p.y,
      p.z,
      wake,
    );
  }

  /// Applies a continuous [torque] this step, in newton-meters.
  void applyTorque(Vector3 torque, {bool wake = true}) =>
      _bindings.bodyApplyTorque(handle, torque.x, torque.y, torque.z, wake);

  /// Applies an instantaneous angular [impulse].
  void applyAngularImpulse(Vector3 impulse, {bool wake = true}) => _bindings
      .bodyApplyAngularImpulse(handle, impulse.x, impulse.y, impulse.z, wake);

  // --- Shapes ----------------------------------------------------------------

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
