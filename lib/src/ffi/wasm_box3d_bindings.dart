// dart:js_interop implementation of Box3dBindings: drives the shim as a
// WebAssembly module. Functions are called on the instance's exports;
// pointers are byte offsets into linear memory, and structs are marshalled
// at those offsets with the layouts the native bindings describe.
//
// Handles are the shim's packed values: a world is a uint32 (a plain JS
// number), while bodies, shapes, and joints are uint64 carried across the
// boundary as BigInt. Collision-filter bits are also uint64. u64 values
// round-trip exactly while they fit in 53 bits (see readHandle).

import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:vector_math/vector_math.dart';

import '../events.dart';
import '../queries.dart';
import 'box3d_bindings.dart';
import 'wasm_runtime_web.dart';

@JS('BigInt')
external JSBigInt _bigInt(JSAny value);

@JS('Number')
external JSNumber _number(JSAny value);

/// A [Box3dBindings] backed by a WebAssembly instance of the shim.
class WasmBox3dBindings extends Box3dBindings {
  WasmBox3dBindings(this._runtime) {
    _read = _runtime.alloc(28); // up to 7 floats (transform)
    _shapes = _runtime.alloc(16); // two u64 handles
    _point = _runtime.alloc(32); // b3d_contact_point (8 floats)
    _hit = _runtime.alloc(40); // b3d_query_hit (u64 + 7 floats)
    _frameA = _runtime.alloc(28); // 7 floats
    _frameB = _runtime.alloc(28);
  }

  final JsWasmRuntime _runtime;
  late final int _read;
  late final int _shapes;
  late final int _point;
  late final int _hit;
  late final int _frameA;
  late final int _frameB;

  JSObject get _exports => _runtime.exports;

  // ---- call + argument helpers ---------------------------------------------

  JSAny? _invoke(String name, List<JSAny?> args) =>
      _exports.callMethodVarArgs(name.toJS, args);

  int _invokeInt(String name, List<JSAny?> args) =>
      (_invoke(name, args)! as JSNumber).toDartInt;

  double _invokeDouble(String name, List<JSAny?> args) =>
      (_invoke(name, args)! as JSNumber).toDartDouble;

  // u64 return (a BigInt) reduced to an int, matching readHandle.
  int _invokeHandle(String name, List<JSAny?> args) =>
      _number(_invoke(name, args)!).toDartDouble.toInt();

  JSNumber _f(double v) => v.toJS;
  JSNumber _i(int v) => v.toJS;
  JSBigInt _h(int handle) => _bigInt(handle.toJS);
  JSNumber _b(bool v) => (v ? 1 : 0).toJS;

  // ---- world ---------------------------------------------------------------

  @override
  int worldCreate(double gx, double gy, double gz) =>
      _invokeInt('b3d_world_create', [_f(gx), _f(gy), _f(gz)]);

  @override
  void worldDestroy(int world) => _invoke('b3d_world_destroy', [_i(world)]);

  @override
  void worldSetGravity(int world, double x, double y, double z) =>
      _invoke('b3d_world_set_gravity', [_i(world), _f(x), _f(y), _f(z)]);

  @override
  void worldStep(int world, double dt, int subSteps) =>
      _invoke('b3d_world_step', [_i(world), _f(dt), _i(subSteps)]);

  // ---- bodies --------------------------------------------------------------

  @override
  int bodyCreate(
    int world,
    int kind,
    double px,
    double py,
    double pz,
    double qx,
    double qy,
    double qz,
    double qw,
  ) => _invokeHandle('b3d_body_create', [
    _i(world),
    _i(kind),
    _f(px),
    _f(py),
    _f(pz),
    _f(qx),
    _f(qy),
    _f(qz),
    _f(qw),
  ]);

  @override
  void bodyDestroy(int body) => _invoke('b3d_body_destroy', [_h(body)]);

  Vector3 _readVec3() => Vector3(
    _runtime.readF32(_read),
    _runtime.readF32(_read + 4),
    _runtime.readF32(_read + 8),
  );

  @override
  Vector3 bodyPosition(int body) {
    _invoke('b3d_body_get_position', [_h(body), _i(_read)]);
    return _readVec3();
  }

  @override
  Quaternion bodyRotation(int body) {
    _invoke('b3d_body_get_rotation', [_h(body), _i(_read)]);
    return Quaternion(
      _runtime.readF32(_read),
      _runtime.readF32(_read + 4),
      _runtime.readF32(_read + 8),
      _runtime.readF32(_read + 12),
    );
  }

  @override
  void bodySetTransform(
    int body,
    double px,
    double py,
    double pz,
    double qx,
    double qy,
    double qz,
    double qw,
  ) => _invoke('b3d_body_set_transform', [
    _h(body),
    _f(px),
    _f(py),
    _f(pz),
    _f(qx),
    _f(qy),
    _f(qz),
    _f(qw),
  ]);

  @override
  Vector3 bodyLinearVelocity(int body) {
    _invoke('b3d_body_get_linear_velocity', [_h(body), _i(_read)]);
    return _readVec3();
  }

  @override
  void bodySetLinearVelocity(int body, double x, double y, double z) =>
      _invoke('b3d_body_set_linear_velocity', [_h(body), _f(x), _f(y), _f(z)]);

  @override
  Vector3 bodyAngularVelocity(int body) {
    _invoke('b3d_body_get_angular_velocity', [_h(body), _i(_read)]);
    return _readVec3();
  }

  @override
  void bodySetAngularVelocity(int body, double x, double y, double z) =>
      _invoke('b3d_body_set_angular_velocity', [_h(body), _f(x), _f(y), _f(z)]);

  @override
  void bodySetLinearDamping(int body, double damping) =>
      _invoke('b3d_body_set_linear_damping', [_h(body), _f(damping)]);

  @override
  void bodySetAngularDamping(int body, double damping) =>
      _invoke('b3d_body_set_angular_damping', [_h(body), _f(damping)]);

  @override
  void bodySetGravityScale(int body, double scale) =>
      _invoke('b3d_body_set_gravity_scale', [_h(body), _f(scale)]);

  @override
  int bodyKind(int body) => _invokeInt('b3d_body_get_kind', [_h(body)]);

  @override
  void bodySetKind(int body, int kind) =>
      _invoke('b3d_body_set_kind', [_h(body), _i(kind)]);

  @override
  double bodyMass(int body) => _invokeDouble('b3d_body_get_mass', [_h(body)]);

  @override
  void bodyApplyMassFromShapes(int body) =>
      _invoke('b3d_body_apply_mass_from_shapes', [_h(body)]);

  @override
  void bodySetMotionLocks(
    int body,
    bool lx,
    bool ly,
    bool lz,
    bool ax,
    bool ay,
    bool az,
  ) => _invoke('b3d_body_set_motion_locks', [
    _h(body),
    _b(lx),
    _b(ly),
    _b(lz),
    _b(ax),
    _b(ay),
    _b(az),
  ]);

  @override
  void bodySetBullet(int body, bool enabled) =>
      _invoke('b3d_body_set_bullet', [_h(body), _b(enabled)]);

  @override
  bool bodyIsAwake(int body) =>
      _invokeInt('b3d_body_is_awake', [_h(body)]) != 0;

  @override
  void bodySetAwake(int body, bool awake) =>
      _invoke('b3d_body_set_awake', [_h(body), _b(awake)]);

  @override
  void bodyEnableSleep(int body, bool enabled) =>
      _invoke('b3d_body_enable_sleep', [_h(body), _b(enabled)]);

  @override
  void bodyApplyForce(
    int body,
    double fx,
    double fy,
    double fz,
    bool hasPoint,
    double px,
    double py,
    double pz,
    bool wake,
  ) => _invoke('b3d_body_apply_force', [
    _h(body),
    _f(fx),
    _f(fy),
    _f(fz),
    _b(hasPoint),
    _f(px),
    _f(py),
    _f(pz),
    _b(wake),
  ]);

  @override
  void bodyApplyImpulse(
    int body,
    double ix,
    double iy,
    double iz,
    bool hasPoint,
    double px,
    double py,
    double pz,
    bool wake,
  ) => _invoke('b3d_body_apply_impulse', [
    _h(body),
    _f(ix),
    _f(iy),
    _f(iz),
    _b(hasPoint),
    _f(px),
    _f(py),
    _f(pz),
    _b(wake),
  ]);

  @override
  void bodyApplyTorque(int body, double x, double y, double z, bool wake) =>
      _invoke('b3d_body_apply_torque', [
        _h(body),
        _f(x),
        _f(y),
        _f(z),
        _b(wake),
      ]);

  @override
  void bodyApplyAngularImpulse(
    int body,
    double x,
    double y,
    double z,
    bool wake,
  ) => _invoke('b3d_body_apply_angular_impulse', [
    _h(body),
    _f(x),
    _f(y),
    _f(z),
    _b(wake),
  ]);

  // ---- shapes --------------------------------------------------------------

  @override
  int shapeSphere(
    int body,
    double cx,
    double cy,
    double cz,
    double radius,
    double friction,
    double restitution,
    double density,
    bool isSensor,
  ) => _invokeHandle('b3d_shape_sphere', [
    _h(body),
    _f(cx),
    _f(cy),
    _f(cz),
    _f(radius),
    _f(friction),
    _f(restitution),
    _f(density),
    _b(isSensor),
  ]);

  @override
  int shapeBox(
    int body,
    double hx,
    double hy,
    double hz,
    double friction,
    double restitution,
    double density,
    bool isSensor,
  ) => _invokeHandle('b3d_shape_box', [
    _h(body),
    _f(hx),
    _f(hy),
    _f(hz),
    _f(friction),
    _f(restitution),
    _f(density),
    _b(isSensor),
  ]);

  @override
  int shapeCapsule(
    int body,
    double ax,
    double ay,
    double az,
    double bx,
    double by,
    double bz,
    double radius,
    double friction,
    double restitution,
    double density,
    bool isSensor,
  ) => _invokeHandle('b3d_shape_capsule', [
    _h(body),
    _f(ax),
    _f(ay),
    _f(az),
    _f(bx),
    _f(by),
    _f(bz),
    _f(radius),
    _f(friction),
    _f(restitution),
    _f(density),
    _b(isSensor),
  ]);

  @override
  int shapeCylinder(
    int body,
    double halfHeight,
    double radius,
    int sides,
    double friction,
    double restitution,
    double density,
    bool isSensor,
  ) => _invokeHandle('b3d_shape_cylinder', [
    _h(body),
    _f(halfHeight),
    _f(radius),
    _i(sides),
    _f(friction),
    _f(restitution),
    _f(density),
    _b(isSensor),
  ]);

  @override
  int shapeConvexHull(
    int body,
    Float32List points,
    double friction,
    double restitution,
    double density,
    bool isSensor,
  ) {
    final ptr = _runtime.alloc(points.length * 4);
    try {
      _runtime.writeF32List(ptr, points);
      return _invokeHandle('b3d_shape_convex_hull', [
        _h(body),
        _i(ptr),
        _i(points.length ~/ 3),
        _f(friction),
        _f(restitution),
        _f(density),
        _b(isSensor),
      ]);
    } finally {
      _runtime.free(ptr);
    }
  }

  @override
  int shapeTriMesh(
    int body,
    Float32List vertices,
    Uint32List indices,
    double friction,
    double restitution,
    double density,
    bool isSensor,
  ) {
    final vPtr = _runtime.alloc(vertices.length * 4);
    final iPtr = _runtime.alloc(indices.length * 4);
    try {
      _runtime.writeF32List(vPtr, vertices);
      _runtime.writeI32List(iPtr, indices);
      return _invokeHandle('b3d_shape_trimesh', [
        _h(body),
        _i(vPtr),
        _i(vertices.length ~/ 3),
        _i(iPtr),
        _i(indices.length ~/ 3),
        _f(friction),
        _f(restitution),
        _f(density),
        _b(isSensor),
      ]);
    } finally {
      _runtime.free(vPtr);
      _runtime.free(iPtr);
    }
  }

  @override
  int shapeHeightField(
    int body,
    int countX,
    int countZ,
    Float32List heights,
    double scaleX,
    double scaleY,
    double scaleZ,
    double friction,
    double restitution,
    double density,
    bool isSensor,
  ) {
    final ptr = _runtime.alloc(heights.length * 4);
    try {
      _runtime.writeF32List(ptr, heights);
      return _invokeHandle('b3d_shape_height_field', [
        _h(body),
        _i(countX),
        _i(countZ),
        _i(ptr),
        _f(scaleX),
        _f(scaleY),
        _f(scaleZ),
        _f(friction),
        _f(restitution),
        _f(density),
        _b(isSensor),
      ]);
    } finally {
      _runtime.free(ptr);
    }
  }

  @override
  void shapeSetMaterial(
    int shape,
    double friction,
    double restitution,
    double density,
  ) => _invoke('b3d_shape_set_material', [
    _h(shape),
    _f(friction),
    _f(restitution),
    _f(density),
  ]);

  @override
  void shapeSetFilter(int shape, int category, int mask, int group) => _invoke(
    'b3d_shape_set_filter',
    [_h(shape), _h(category), _h(mask), _i(group)],
  );

  @override
  void shapeEnableSensorEvents(int shape, bool enabled) =>
      _invoke('b3d_shape_enable_sensor_events', [_h(shape), _b(enabled)]);

  @override
  void shapeEnableContactEvents(int shape, bool enabled) =>
      _invoke('b3d_shape_enable_contact_events', [_h(shape), _b(enabled)]);

  @override
  void shapeDestroy(int shape, bool updateBodyMass) =>
      _invoke('b3d_shape_destroy', [_h(shape), _b(updateBodyMass)]);

  // ---- joints --------------------------------------------------------------

  void _writeFrames(
    Vector3 posA,
    Quaternion rotA,
    Vector3 posB,
    Quaternion rotB,
  ) {
    _runtime.writeF32List(_frameA, [
      posA.x,
      posA.y,
      posA.z,
      rotA.x,
      rotA.y,
      rotA.z,
      rotA.w,
    ]);
    _runtime.writeF32List(_frameB, [
      posB.x,
      posB.y,
      posB.z,
      rotB.x,
      rotB.y,
      rotB.z,
      rotB.w,
    ]);
  }

  @override
  int jointWeld(
    int world,
    int bodyA,
    int bodyB,
    Vector3 posA,
    Quaternion rotA,
    Vector3 posB,
    Quaternion rotB,
    bool collide,
    double linearHertz,
    double angularHertz,
    double linearDamping,
    double angularDamping,
  ) {
    _writeFrames(posA, rotA, posB, rotB);
    return _invokeHandle('b3d_joint_weld', [
      _i(world),
      _h(bodyA),
      _h(bodyB),
      _i(_frameA),
      _i(_frameB),
      _b(collide),
      _f(linearHertz),
      _f(angularHertz),
      _f(linearDamping),
      _f(angularDamping),
    ]);
  }

  @override
  int jointRevolute(
    int world,
    int bodyA,
    int bodyB,
    Vector3 posA,
    Quaternion rotA,
    Vector3 posB,
    Quaternion rotB,
    bool collide,
    bool enableLimit,
    double lower,
    double upper,
    bool enableMotor,
    double motorSpeed,
    double maxMotorTorque,
  ) {
    _writeFrames(posA, rotA, posB, rotB);
    return _invokeHandle('b3d_joint_revolute', [
      _i(world),
      _h(bodyA),
      _h(bodyB),
      _i(_frameA),
      _i(_frameB),
      _b(collide),
      _b(enableLimit),
      _f(lower),
      _f(upper),
      _b(enableMotor),
      _f(motorSpeed),
      _f(maxMotorTorque),
    ]);
  }

  @override
  int jointPrismatic(
    int world,
    int bodyA,
    int bodyB,
    Vector3 posA,
    Quaternion rotA,
    Vector3 posB,
    Quaternion rotB,
    bool collide,
    bool enableLimit,
    double lower,
    double upper,
    bool enableMotor,
    double motorSpeed,
    double maxMotorForce,
  ) {
    _writeFrames(posA, rotA, posB, rotB);
    return _invokeHandle('b3d_joint_prismatic', [
      _i(world),
      _h(bodyA),
      _h(bodyB),
      _i(_frameA),
      _i(_frameB),
      _b(collide),
      _b(enableLimit),
      _f(lower),
      _f(upper),
      _b(enableMotor),
      _f(motorSpeed),
      _f(maxMotorForce),
    ]);
  }

  @override
  int jointSpherical(
    int world,
    int bodyA,
    int bodyB,
    Vector3 posA,
    Quaternion rotA,
    Vector3 posB,
    Quaternion rotB,
    bool collide,
    bool enableCone,
    double coneAngle,
    bool enableTwist,
    double lowerTwist,
    double upperTwist,
    bool enableMotor,
    double maxMotorTorque,
  ) {
    _writeFrames(posA, rotA, posB, rotB);
    return _invokeHandle('b3d_joint_spherical', [
      _i(world),
      _h(bodyA),
      _h(bodyB),
      _i(_frameA),
      _i(_frameB),
      _b(collide),
      _b(enableCone),
      _f(coneAngle),
      _b(enableTwist),
      _f(lowerTwist),
      _f(upperTwist),
      _b(enableMotor),
      _f(maxMotorTorque),
    ]);
  }

  @override
  int jointDistance(
    int world,
    int bodyA,
    int bodyB,
    Vector3 posA,
    Quaternion rotA,
    Vector3 posB,
    Quaternion rotB,
    bool collide,
    double length,
    bool enableLimit,
    double minLength,
    double maxLength,
    bool enableSpring,
    double hertz,
    double dampingRatio,
    bool enableMotor,
    double motorSpeed,
    double maxMotorForce,
  ) {
    _writeFrames(posA, rotA, posB, rotB);
    return _invokeHandle('b3d_joint_distance', [
      _i(world),
      _h(bodyA),
      _h(bodyB),
      _i(_frameA),
      _i(_frameB),
      _b(collide),
      _f(length),
      _b(enableLimit),
      _f(minLength),
      _f(maxLength),
      _b(enableSpring),
      _f(hertz),
      _f(dampingRatio),
      _b(enableMotor),
      _f(motorSpeed),
      _f(maxMotorForce),
    ]);
  }

  @override
  void jointDestroy(int joint, bool wakeBodies) =>
      _invoke('b3d_joint_destroy', [_h(joint), _b(wakeBodies)]);

  // ---- events --------------------------------------------------------------

  @override
  List<Box3dContactBegan> contactBegan(int world) {
    final count = _invokeInt('b3d_contact_begin_count', [_i(world)]);
    final events = <Box3dContactBegan>[];
    for (var i = 0; i < count; i++) {
      final pointCount = _invokeInt('b3d_contact_begin_at', [
        _i(world),
        _i(i),
        _i(_shapes),
      ]);
      final shapeA = _runtime.readHandle(_shapes);
      final shapeB = _runtime.readHandle(_shapes + 8);
      final points = <Box3dContactPoint>[];
      for (var p = 0; p < pointCount; p++) {
        _invoke('b3d_contact_begin_point_at', [
          _i(world),
          _i(i),
          _i(p),
          _i(_point),
        ]);
        points.add(
          Box3dContactPoint(
            position: Vector3(
              _runtime.readF32(_point),
              _runtime.readF32(_point + 4),
              _runtime.readF32(_point + 8),
            ),
            normal: Vector3(
              _runtime.readF32(_point + 12),
              _runtime.readF32(_point + 16),
              _runtime.readF32(_point + 20),
            ),
            impulse: _runtime.readF32(_point + 24),
            separation: _runtime.readF32(_point + 28),
          ),
        );
      }
      events.add(
        Box3dContactBegan(shapeA: shapeA, shapeB: shapeB, points: points),
      );
    }
    return events;
  }

  @override
  List<Box3dContactEnded> contactEnded(int world) {
    final count = _invokeInt('b3d_contact_end_count', [_i(world)]);
    final events = <Box3dContactEnded>[];
    for (var i = 0; i < count; i++) {
      _invoke('b3d_contact_end_at', [_i(world), _i(i), _i(_shapes)]);
      events.add(
        Box3dContactEnded(
          shapeA: _runtime.readHandle(_shapes),
          shapeB: _runtime.readHandle(_shapes + 8),
        ),
      );
    }
    return events;
  }

  @override
  List<Box3dSensorBegan> sensorBegan(int world) {
    final count = _invokeInt('b3d_sensor_begin_count', [_i(world)]);
    final events = <Box3dSensorBegan>[];
    for (var i = 0; i < count; i++) {
      _invoke('b3d_sensor_begin_at', [_i(world), _i(i), _i(_shapes)]);
      events.add(
        Box3dSensorBegan(
          sensorShape: _runtime.readHandle(_shapes),
          visitorShape: _runtime.readHandle(_shapes + 8),
        ),
      );
    }
    return events;
  }

  @override
  List<Box3dSensorEnded> sensorEnded(int world) {
    final count = _invokeInt('b3d_sensor_end_count', [_i(world)]);
    final events = <Box3dSensorEnded>[];
    for (var i = 0; i < count; i++) {
      _invoke('b3d_sensor_end_at', [_i(world), _i(i), _i(_shapes)]);
      events.add(
        Box3dSensorEnded(
          sensorShape: _runtime.readHandle(_shapes),
          visitorShape: _runtime.readHandle(_shapes + 8),
        ),
      );
    }
    return events;
  }

  // ---- queries -------------------------------------------------------------

  Box3dRayHit _readHit(double dirLength) => Box3dRayHit(
    shape: _runtime.readHandle(_hit),
    point: Vector3(
      _runtime.readF32(_hit + 8),
      _runtime.readF32(_hit + 12),
      _runtime.readF32(_hit + 16),
    ),
    normal: Vector3(
      _runtime.readF32(_hit + 20),
      _runtime.readF32(_hit + 24),
      _runtime.readF32(_hit + 28),
    ),
    fraction: _runtime.readF32(_hit + 32),
    distance: _runtime.readF32(_hit + 32) * dirLength,
  );

  @override
  Box3dRayHit? raycast(int world, Vector3 origin, Vector3 dir, int c, int m) {
    final hit = _invokeInt('b3d_raycast_closest', [
      _i(world),
      _f(origin.x),
      _f(origin.y),
      _f(origin.z),
      _f(dir.x),
      _f(dir.y),
      _f(dir.z),
      _h(c),
      _h(m),
      _i(_hit),
    ]);
    return hit == 0 ? null : _readHit(dir.length);
  }

  @override
  List<Box3dRayHit> raycastAll(
    int world,
    Vector3 origin,
    Vector3 dir,
    int c,
    int m,
  ) {
    final count = _invokeInt('b3d_raycast_all', [
      _i(world),
      _f(origin.x),
      _f(origin.y),
      _f(origin.z),
      _f(dir.x),
      _f(dir.y),
      _f(dir.z),
      _h(c),
      _h(m),
    ]);
    final length = dir.length;
    final hits = <Box3dRayHit>[];
    for (var i = 0; i < count; i++) {
      _invoke('b3d_query_hit_at', [_i(i), _i(_hit)]);
      hits.add(_readHit(length));
    }
    return hits;
  }

  List<int> _drainShapes(int count) => [
    for (var i = 0; i < count; i++)
      _invokeHandle('b3d_query_shape_at', [_i(i)]),
  ];

  @override
  List<int> overlapSphere(
    int world,
    Vector3 center,
    double radius,
    int c,
    int m,
  ) {
    final count = _invokeInt('b3d_overlap_sphere', [
      _i(world),
      _f(center.x),
      _f(center.y),
      _f(center.z),
      _f(radius),
      _h(c),
      _h(m),
    ]);
    return _drainShapes(count);
  }

  @override
  List<int> overlapBox(
    int world,
    Vector3 center,
    Vector3 halfExtents,
    Quaternion rotation,
    int c,
    int m,
  ) {
    final count = _invokeInt('b3d_overlap_box', [
      _i(world),
      _f(center.x),
      _f(center.y),
      _f(center.z),
      _f(halfExtents.x),
      _f(halfExtents.y),
      _f(halfExtents.z),
      _f(rotation.x),
      _f(rotation.y),
      _f(rotation.z),
      _f(rotation.w),
      _h(c),
      _h(m),
    ]);
    return _drainShapes(count);
  }

  @override
  Box3dRayHit? shapeCastSphere(
    int world,
    Vector3 origin,
    double radius,
    Vector3 dir,
    int c,
    int m,
  ) {
    final hit = _invokeInt('b3d_shapecast_sphere', [
      _i(world),
      _f(origin.x),
      _f(origin.y),
      _f(origin.z),
      _f(radius),
      _f(dir.x),
      _f(dir.y),
      _f(dir.z),
      _h(c),
      _h(m),
      _i(_hit),
    ]);
    return hit == 0 ? null : _readHit(dir.length);
  }

  @override
  Box3dRayHit? shapeCastBox(
    int world,
    Vector3 origin,
    Vector3 halfExtents,
    Quaternion rotation,
    Vector3 dir,
    int c,
    int m,
  ) {
    final hit = _invokeInt('b3d_shapecast_box', [
      _i(world),
      _f(origin.x),
      _f(origin.y),
      _f(origin.z),
      _f(halfExtents.x),
      _f(halfExtents.y),
      _f(halfExtents.z),
      _f(rotation.x),
      _f(rotation.y),
      _f(rotation.z),
      _f(rotation.w),
      _f(dir.x),
      _f(dir.y),
      _f(dir.z),
      _h(c),
      _h(m),
      _i(_hit),
    ]);
    return hit == 0 ? null : _readHit(dir.length);
  }
}
