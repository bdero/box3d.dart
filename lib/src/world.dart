import 'package:vector_math/vector_math.dart';

import 'body.dart';
import 'events.dart';
import 'ffi/box3d_bindings.dart';
import 'ffi/box3d_bindings_factory.dart';
import 'physics_types.dart';
import 'queries.dart';

/// A box3d simulation world: a container of bodies and shapes advanced with
/// [step].
///
/// `await Box3d.ensureInitialized()` before constructing a world so the
/// backend is loaded on every platform (it is a no-op on native).
class Box3dWorld {
  /// Creates an empty world with the given [gravity] (default -9.81 on Y).
  factory Box3dWorld({Vector3? gravity}) {
    final g = gravity ?? Vector3(0, -9.81, 0);
    final bindings = box3dBindings();
    final handle = bindings.worldCreate(g.x, g.y, g.z);
    return Box3dWorld._(bindings, handle, g.clone());
  }

  Box3dWorld._(this._bindings, this._handle, this._gravity);

  final Box3dBindings _bindings;
  final int _handle;
  Vector3 _gravity;
  bool _destroyed = false;

  /// The gravity applied to dynamic bodies, in units per second squared.
  Vector3 get gravity => _gravity.clone();

  set gravity(Vector3 value) {
    _gravity = value.clone();
    _bindings.worldSetGravity(_handle, value.x, value.y, value.z);
  }

  /// Advances the simulation by [dt] seconds. [subSteps] trades cost for
  /// solver accuracy; box3d's usual default is 4.
  void step(double dt, {int subSteps = 4}) {
    _bindings.worldStep(_handle, dt, subSteps);
  }

  /// Creates a body of [type] at [position] / [rotation] (both optional,
  /// defaulting to the origin with identity rotation).
  Box3dBody createBody({
    Box3dBodyType type = Box3dBodyType.dynamic_,
    Vector3? position,
    Quaternion? rotation,
  }) {
    final p = position ?? Vector3.zero();
    final q = rotation ?? Quaternion.identity();
    final handle = _bindings.bodyCreate(
      _handle,
      type.kind,
      p.x,
      p.y,
      p.z,
      q.x,
      q.y,
      q.z,
      q.w,
    );
    return Box3dBody(_bindings, handle, type);
  }

  // --- Joints ----------------------------------------------------------------

  /// Rigidly welds [bodyA] to [bodyB] at the given local frames. With all
  /// hertz values 0 the weld is rigid; positive values make it a soft,
  /// spring-like weld.
  Box3dJoint createWeldJoint(
    Box3dBody bodyA,
    Box3dBody bodyB, {
    Box3dFrame? frameA,
    Box3dFrame? frameB,
    bool collideConnected = false,
    double linearHertz = 0,
    double angularHertz = 0,
    double linearDampingRatio = 0,
    double angularDampingRatio = 0,
  }) {
    final a = frameA ?? Box3dFrame();
    final b = frameB ?? Box3dFrame();
    return Box3dJoint(
      _bindings,
      _bindings.jointWeld(
        _handle,
        bodyA.handle,
        bodyB.handle,
        a.position,
        a.rotation,
        b.position,
        b.rotation,
        collideConnected,
        linearHertz,
        angularHertz,
        linearDampingRatio,
        angularDampingRatio,
      ),
    );
  }

  /// Creates a revolute (hinge) joint. The hinge axis is each frame's local
  /// +Z direction (see [Box3dFrame.pointAxis]). Providing both
  /// [lowerLimit] and [upperLimit] (radians) enables the limit; providing
  /// [motorSpeed] and [maxMotorTorque] enables the motor.
  Box3dJoint createRevoluteJoint(
    Box3dBody bodyA,
    Box3dBody bodyB, {
    required Box3dFrame frameA,
    required Box3dFrame frameB,
    bool collideConnected = false,
    double? lowerLimit,
    double? upperLimit,
    double? motorSpeed,
    double? maxMotorTorque,
  }) {
    final hasLimit = lowerLimit != null && upperLimit != null;
    final hasMotor = motorSpeed != null && maxMotorTorque != null;
    return Box3dJoint(
      _bindings,
      _bindings.jointRevolute(
        _handle,
        bodyA.handle,
        bodyB.handle,
        frameA.position,
        frameA.rotation,
        frameB.position,
        frameB.rotation,
        collideConnected,
        hasLimit,
        lowerLimit ?? 0,
        upperLimit ?? 0,
        hasMotor,
        motorSpeed ?? 0,
        maxMotorTorque ?? 0,
      ),
    );
  }

  /// Creates a prismatic (slider) joint. The slide axis is each frame's
  /// local +X direction (see [Box3dFrame.pointAxisX]). Limits are in length
  /// units; the motor drives linear speed.
  Box3dJoint createPrismaticJoint(
    Box3dBody bodyA,
    Box3dBody bodyB, {
    required Box3dFrame frameA,
    required Box3dFrame frameB,
    bool collideConnected = false,
    double? lowerLimit,
    double? upperLimit,
    double? motorSpeed,
    double? maxMotorForce,
  }) {
    final hasLimit = lowerLimit != null && upperLimit != null;
    final hasMotor = motorSpeed != null && maxMotorForce != null;
    return Box3dJoint(
      _bindings,
      _bindings.jointPrismatic(
        _handle,
        bodyA.handle,
        bodyB.handle,
        frameA.position,
        frameA.rotation,
        frameB.position,
        frameB.rotation,
        collideConnected,
        hasLimit,
        lowerLimit ?? 0,
        upperLimit ?? 0,
        hasMotor,
        motorSpeed ?? 0,
        maxMotorForce ?? 0,
      ),
    );
  }

  /// Creates a spherical (ball-and-socket) joint. Optionally limits the
  /// swing to [coneAngle] (radians) and the twist to [lowerTwist] ..
  /// [upperTwist].
  Box3dJoint createSphericalJoint(
    Box3dBody bodyA,
    Box3dBody bodyB, {
    Box3dFrame? frameA,
    Box3dFrame? frameB,
    bool collideConnected = false,
    double? coneAngle,
    double? lowerTwist,
    double? upperTwist,
    double? maxMotorTorque,
  }) {
    final a = frameA ?? Box3dFrame();
    final b = frameB ?? Box3dFrame();
    final hasTwist = lowerTwist != null && upperTwist != null;
    return Box3dJoint(
      _bindings,
      _bindings.jointSpherical(
        _handle,
        bodyA.handle,
        bodyB.handle,
        a.position,
        a.rotation,
        b.position,
        b.rotation,
        collideConnected,
        coneAngle != null,
        coneAngle ?? 0,
        hasTwist,
        lowerTwist ?? 0,
        upperTwist ?? 0,
        maxMotorTorque != null,
        maxMotorTorque ?? 0,
      ),
    );
  }

  /// Creates a distance joint holding [bodyA] and [bodyB] a fixed [length]
  /// apart at the given anchors. Enable a spring for softness, a
  /// [minLength] .. [maxLength] range, or a motor.
  Box3dJoint createDistanceJoint(
    Box3dBody bodyA,
    Box3dBody bodyB, {
    required double length,
    Box3dFrame? frameA,
    Box3dFrame? frameB,
    bool collideConnected = false,
    double? minLength,
    double? maxLength,
    double? springHertz,
    double springDampingRatio = 0,
    double? motorSpeed,
    double? maxMotorForce,
  }) {
    final a = frameA ?? Box3dFrame();
    final b = frameB ?? Box3dFrame();
    final hasLimit = minLength != null && maxLength != null;
    final hasMotor = motorSpeed != null && maxMotorForce != null;
    return Box3dJoint(
      _bindings,
      _bindings.jointDistance(
        _handle,
        bodyA.handle,
        bodyB.handle,
        a.position,
        a.rotation,
        b.position,
        b.rotation,
        collideConnected,
        length,
        hasLimit,
        minLength ?? length,
        maxLength ?? length,
        springHertz != null,
        springHertz ?? 0,
        springDampingRatio,
        hasMotor,
        motorSpeed ?? 0,
        maxMotorForce ?? 0,
      ),
    );
  }

  // --- Events ----------------------------------------------------------------

  /// Drains the contact and sensor events from the most recent [step]. Call
  /// once per step; the underlying buffers are replaced on the next step.
  /// Shapes must opt in via [Box3dShape.contactEventsEnabled] /
  /// [Box3dShape.sensorEventsEnabled] to appear here.
  Box3dEvents drainEvents() => Box3dEvents(
    contactBegan: _bindings.contactBegan(_handle),
    contactEnded: _bindings.contactEnded(_handle),
    sensorBegan: _bindings.sensorBegan(_handle),
    sensorEnded: _bindings.sensorEnded(_handle),
  );

  // --- Scene queries ---------------------------------------------------------

  // All category / mask bits set: match everything by default.
  static const int _allBits = -1;

  /// Casts a ray from [origin] along [direction] up to [maxDistance] and
  /// returns the closest hit, or null. [category] / [mask] filter which
  /// shapes are considered.
  Box3dRayHit? raycast(
    Vector3 origin,
    Vector3 direction, {
    double maxDistance = 1e6,
    int category = _allBits,
    int mask = _allBits,
  }) {
    final dir = direction.normalized()..scale(maxDistance);
    return _bindings.raycast(_handle, origin, dir, category, mask);
  }

  /// Casts a ray and returns every hit along it (unsorted).
  List<Box3dRayHit> raycastAll(
    Vector3 origin,
    Vector3 direction, {
    double maxDistance = 1e6,
    int category = _allBits,
    int mask = _allBits,
  }) {
    final dir = direction.normalized()..scale(maxDistance);
    return _bindings.raycastAll(_handle, origin, dir, category, mask);
  }

  /// Returns the handles of shapes overlapping a sphere at [center].
  List<int> overlapSphere(
    Vector3 center,
    double radius, {
    int category = _allBits,
    int mask = _allBits,
  }) => _bindings.overlapSphere(_handle, center, radius, category, mask);

  /// Returns the handles of shapes overlapping an oriented box.
  List<int> overlapBox(
    Vector3 center,
    Vector3 halfExtents, {
    Quaternion? rotation,
    int category = _allBits,
    int mask = _allBits,
  }) => _bindings.overlapBox(
    _handle,
    center,
    halfExtents,
    rotation ?? Quaternion.identity(),
    category,
    mask,
  );

  /// Sweeps a sphere from [origin] along [direction] up to [maxDistance] and
  /// returns the closest hit, or null.
  Box3dRayHit? shapeCastSphere(
    Vector3 origin,
    double radius,
    Vector3 direction, {
    double maxDistance = 1e6,
    int category = _allBits,
    int mask = _allBits,
  }) {
    final dir = direction.normalized()..scale(maxDistance);
    return _bindings.shapeCastSphere(
      _handle,
      origin,
      radius,
      dir,
      category,
      mask,
    );
  }

  /// Sweeps an oriented box from [origin] along [direction] and returns the
  /// closest hit, or null.
  Box3dRayHit? shapeCastBox(
    Vector3 origin,
    Vector3 halfExtents,
    Vector3 direction, {
    Quaternion? rotation,
    double maxDistance = 1e6,
    int category = _allBits,
    int mask = _allBits,
  }) {
    final dir = direction.normalized()..scale(maxDistance);
    return _bindings.shapeCastBox(
      _handle,
      origin,
      halfExtents,
      rotation ?? Quaternion.identity(),
      dir,
      category,
      mask,
    );
  }

  /// Destroys the world and everything in it.
  void dispose() {
    if (_destroyed) return;
    _destroyed = true;
    _bindings.worldDestroy(_handle);
  }
}
