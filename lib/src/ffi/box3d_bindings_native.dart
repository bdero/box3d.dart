// dart:ffi implementation of Box3dBindings: calls the shim as a native
// dynamic library and owns the reusable scratch buffer that the
// struct-returning reads (position, rotation, velocity) come back through.

import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:vector_math/vector_math.dart';

import '../events.dart';
import '../queries.dart';
import 'bindings.dart' as native;
import 'box3d_bindings.dart';

/// A [Box3dBindings] backed by the native shim over dart:ffi. One shared
/// instance serves every world; the shim is stateless and takes the world
/// handle per call.
class NativeBox3dBindings extends Box3dBindings {
  NativeBox3dBindings() {
    // This package assumes a single-precision box3d build; a
    // double-precision library has a different struct ABI and would
    // silently corrupt every position/rotation read.
    if (native.b3dIsDoublePrecision() != 0) {
      throw StateError(
        'box3d was built in double precision, which this package does not '
        'support. Rebuild box3d without BOX3D_DOUBLE_PRECISION.',
      );
    }
  }

  // Reusable read scratch, four floats (the widest read is a quaternion).
  // The reads never overlap within a single call, so one buffer is enough.
  // Never freed: the instance lives for the process.
  final Pointer<Float> _read = calloc<Float>(4);

  // Scratch for the two joint local frames (7 floats each: xyz + xyzw).
  final Pointer<Float> _frameA = calloc<Float>(7);
  final Pointer<Float> _frameB = calloc<Float>(7);

  // Scratch for event reads: a two-handle pair and one contact point.
  final Pointer<Uint64> _shapes = calloc<Uint64>(2);
  final Pointer<native.B3dContactPoint> _point =
      calloc<native.B3dContactPoint>();

  // Scratch for a single query hit.
  final Pointer<native.B3dQueryHit> _hit = calloc<native.B3dQueryHit>();

  Box3dRayHit _rayHitFrom(native.B3dQueryHit h, double dirLength) {
    return Box3dRayHit(
      shape: h.shape,
      point: Vector3(h.px, h.py, h.pz),
      normal: Vector3(h.nx, h.ny, h.nz),
      fraction: h.fraction,
      distance: h.fraction * dirLength,
    );
  }

  void _writeFrames(
    Vector3 posA,
    Quaternion rotA,
    Vector3 posB,
    Quaternion rotB,
  ) {
    _frameA[0] = posA.x;
    _frameA[1] = posA.y;
    _frameA[2] = posA.z;
    _frameA[3] = rotA.x;
    _frameA[4] = rotA.y;
    _frameA[5] = rotA.z;
    _frameA[6] = rotA.w;
    _frameB[0] = posB.x;
    _frameB[1] = posB.y;
    _frameB[2] = posB.z;
    _frameB[3] = rotB.x;
    _frameB[4] = rotB.y;
    _frameB[5] = rotB.z;
    _frameB[6] = rotB.w;
  }

  @override
  int worldCreate(double gx, double gy, double gz) =>
      native.b3dWorldCreate(gx, gy, gz);

  @override
  void worldDestroy(int world) => native.b3dWorldDestroy(world);

  @override
  void worldSetGravity(int world, double x, double y, double z) =>
      native.b3dWorldSetGravity(world, x, y, z);

  @override
  void worldStep(int world, double dt, int subSteps) =>
      native.b3dWorldStep(world, dt, subSteps);

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
  ) => native.b3dBodyCreate(world, kind, px, py, pz, qx, qy, qz, qw);

  @override
  void bodyDestroy(int body) => native.b3dBodyDestroy(body);

  @override
  Vector3 bodyPosition(int body) {
    native.b3dBodyGetPosition(body, _read);
    return Vector3(_read[0], _read[1], _read[2]);
  }

  @override
  Quaternion bodyRotation(int body) {
    native.b3dBodyGetRotation(body, _read);
    return Quaternion(_read[0], _read[1], _read[2], _read[3]);
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
  ) => native.b3dBodySetTransform(body, px, py, pz, qx, qy, qz, qw);

  @override
  Vector3 bodyLinearVelocity(int body) {
    native.b3dBodyGetLinearVelocity(body, _read);
    return Vector3(_read[0], _read[1], _read[2]);
  }

  @override
  void bodySetLinearVelocity(int body, double x, double y, double z) =>
      native.b3dBodySetLinearVelocity(body, x, y, z);

  @override
  Vector3 bodyAngularVelocity(int body) {
    native.b3dBodyGetAngularVelocity(body, _read);
    return Vector3(_read[0], _read[1], _read[2]);
  }

  @override
  void bodySetAngularVelocity(int body, double x, double y, double z) =>
      native.b3dBodySetAngularVelocity(body, x, y, z);

  @override
  void bodySetLinearDamping(int body, double damping) =>
      native.b3dBodySetLinearDamping(body, damping);

  @override
  void bodySetAngularDamping(int body, double damping) =>
      native.b3dBodySetAngularDamping(body, damping);

  @override
  void bodySetGravityScale(int body, double scale) =>
      native.b3dBodySetGravityScale(body, scale);

  @override
  int bodyKind(int body) => native.b3dBodyGetKind(body);

  @override
  void bodySetKind(int body, int kind) => native.b3dBodySetKind(body, kind);

  @override
  double bodyMass(int body) => native.b3dBodyGetMass(body);

  @override
  void bodyApplyMassFromShapes(int body) =>
      native.b3dBodyApplyMassFromShapes(body);

  @override
  void bodySetMotionLocks(
    int body,
    bool lx,
    bool ly,
    bool lz,
    bool ax,
    bool ay,
    bool az,
  ) => native.b3dBodySetMotionLocks(
    body,
    lx ? 1 : 0,
    ly ? 1 : 0,
    lz ? 1 : 0,
    ax ? 1 : 0,
    ay ? 1 : 0,
    az ? 1 : 0,
  );

  @override
  void bodySetBullet(int body, bool enabled) =>
      native.b3dBodySetBullet(body, enabled ? 1 : 0);

  @override
  bool bodyIsAwake(int body) => native.b3dBodyIsAwake(body) != 0;

  @override
  void bodySetAwake(int body, bool awake) =>
      native.b3dBodySetAwake(body, awake ? 1 : 0);

  @override
  void bodyEnableSleep(int body, bool enabled) =>
      native.b3dBodyEnableSleep(body, enabled ? 1 : 0);

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
  ) => native.b3dBodyApplyForce(
    body,
    fx,
    fy,
    fz,
    hasPoint ? 1 : 0,
    px,
    py,
    pz,
    wake ? 1 : 0,
  );

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
  ) => native.b3dBodyApplyImpulse(
    body,
    ix,
    iy,
    iz,
    hasPoint ? 1 : 0,
    px,
    py,
    pz,
    wake ? 1 : 0,
  );

  @override
  void bodyApplyTorque(int body, double x, double y, double z, bool wake) =>
      native.b3dBodyApplyTorque(body, x, y, z, wake ? 1 : 0);

  @override
  void bodyApplyAngularImpulse(
    int body,
    double x,
    double y,
    double z,
    bool wake,
  ) => native.b3dBodyApplyAngularImpulse(body, x, y, z, wake ? 1 : 0);

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
  ) => native.b3dShapeSphere(
    body,
    cx,
    cy,
    cz,
    radius,
    friction,
    restitution,
    density,
    isSensor ? 1 : 0,
  );

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
  ) => native.b3dShapeBox(
    body,
    hx,
    hy,
    hz,
    friction,
    restitution,
    density,
    isSensor ? 1 : 0,
  );

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
  ) => native.b3dShapeCapsule(
    body,
    ax,
    ay,
    az,
    bx,
    by,
    bz,
    radius,
    friction,
    restitution,
    density,
    isSensor ? 1 : 0,
  );

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
  ) => native.b3dShapeCylinder(
    body,
    halfHeight,
    radius,
    sides,
    friction,
    restitution,
    density,
    isSensor ? 1 : 0,
  );

  @override
  int shapeConvexHull(
    int body,
    Float32List points,
    double friction,
    double restitution,
    double density,
    bool isSensor,
  ) {
    final ptr = calloc<Float>(points.length);
    try {
      ptr.asTypedList(points.length).setAll(0, points);
      return native.b3dShapeConvexHull(
        body,
        ptr,
        points.length ~/ 3,
        friction,
        restitution,
        density,
        isSensor ? 1 : 0,
      );
    } finally {
      calloc.free(ptr);
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
    final vPtr = calloc<Float>(vertices.length);
    final iPtr = calloc<Int32>(indices.length);
    try {
      vPtr.asTypedList(vertices.length).setAll(0, vertices);
      iPtr.cast<Uint32>().asTypedList(indices.length).setAll(0, indices);
      return native.b3dShapeTriMesh(
        body,
        vPtr,
        vertices.length ~/ 3,
        iPtr,
        indices.length ~/ 3,
        friction,
        restitution,
        density,
        isSensor ? 1 : 0,
      );
    } finally {
      calloc.free(vPtr);
      calloc.free(iPtr);
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
    final ptr = calloc<Float>(heights.length);
    try {
      ptr.asTypedList(heights.length).setAll(0, heights);
      return native.b3dShapeHeightField(
        body,
        countX,
        countZ,
        ptr,
        scaleX,
        scaleY,
        scaleZ,
        friction,
        restitution,
        density,
        isSensor ? 1 : 0,
      );
    } finally {
      calloc.free(ptr);
    }
  }

  @override
  void shapeSetMaterial(
    int shape,
    double friction,
    double restitution,
    double density,
  ) => native.b3dShapeSetMaterial(shape, friction, restitution, density);

  @override
  void shapeSetFilter(int shape, int category, int mask, int group) =>
      native.b3dShapeSetFilter(shape, category, mask, group);

  @override
  void shapeEnableSensorEvents(int shape, bool enabled) =>
      native.b3dShapeEnableSensorEvents(shape, enabled ? 1 : 0);

  @override
  void shapeEnableContactEvents(int shape, bool enabled) =>
      native.b3dShapeEnableContactEvents(shape, enabled ? 1 : 0);

  @override
  void shapeDestroy(int shape, bool updateBodyMass) =>
      native.b3dShapeDestroy(shape, updateBodyMass ? 1 : 0);

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
    return native.b3dJointWeld(
      world,
      bodyA,
      bodyB,
      _frameA,
      _frameB,
      collide ? 1 : 0,
      linearHertz,
      angularHertz,
      linearDamping,
      angularDamping,
    );
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
    return native.b3dJointRevolute(
      world,
      bodyA,
      bodyB,
      _frameA,
      _frameB,
      collide ? 1 : 0,
      enableLimit ? 1 : 0,
      lower,
      upper,
      enableMotor ? 1 : 0,
      motorSpeed,
      maxMotorTorque,
    );
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
    return native.b3dJointPrismatic(
      world,
      bodyA,
      bodyB,
      _frameA,
      _frameB,
      collide ? 1 : 0,
      enableLimit ? 1 : 0,
      lower,
      upper,
      enableMotor ? 1 : 0,
      motorSpeed,
      maxMotorForce,
    );
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
    return native.b3dJointSpherical(
      world,
      bodyA,
      bodyB,
      _frameA,
      _frameB,
      collide ? 1 : 0,
      enableCone ? 1 : 0,
      coneAngle,
      enableTwist ? 1 : 0,
      lowerTwist,
      upperTwist,
      enableMotor ? 1 : 0,
      maxMotorTorque,
    );
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
    return native.b3dJointDistance(
      world,
      bodyA,
      bodyB,
      _frameA,
      _frameB,
      collide ? 1 : 0,
      length,
      enableLimit ? 1 : 0,
      minLength,
      maxLength,
      enableSpring ? 1 : 0,
      hertz,
      dampingRatio,
      enableMotor ? 1 : 0,
      motorSpeed,
      maxMotorForce,
    );
  }

  @override
  void jointDestroy(int joint, bool wakeBodies) =>
      native.b3dJointDestroy(joint, wakeBodies ? 1 : 0);

  @override
  List<Box3dContactBegan> contactBegan(int world) {
    final count = native.b3dContactBeginCount(world);
    final events = <Box3dContactBegan>[];
    for (var i = 0; i < count; i++) {
      final pointCount = native.b3dContactBeginAt(world, i, _shapes);
      final points = <Box3dContactPoint>[];
      for (var p = 0; p < pointCount; p++) {
        native.b3dContactBeginPointAt(world, i, p, _point);
        final c = _point.ref;
        points.add(
          Box3dContactPoint(
            position: Vector3(c.px, c.py, c.pz),
            normal: Vector3(c.nx, c.ny, c.nz),
            impulse: c.impulse,
            separation: c.separation,
          ),
        );
      }
      events.add(
        Box3dContactBegan(
          shapeA: _shapes[0],
          shapeB: _shapes[1],
          points: points,
        ),
      );
    }
    return events;
  }

  @override
  List<Box3dContactEnded> contactEnded(int world) {
    final count = native.b3dContactEndCount(world);
    final events = <Box3dContactEnded>[];
    for (var i = 0; i < count; i++) {
      native.b3dContactEndAt(world, i, _shapes);
      events.add(Box3dContactEnded(shapeA: _shapes[0], shapeB: _shapes[1]));
    }
    return events;
  }

  @override
  List<Box3dSensorBegan> sensorBegan(int world) {
    final count = native.b3dSensorBeginCount(world);
    final events = <Box3dSensorBegan>[];
    for (var i = 0; i < count; i++) {
      native.b3dSensorBeginAt(world, i, _shapes);
      events.add(
        Box3dSensorBegan(sensorShape: _shapes[0], visitorShape: _shapes[1]),
      );
    }
    return events;
  }

  @override
  List<Box3dSensorEnded> sensorEnded(int world) {
    final count = native.b3dSensorEndCount(world);
    final events = <Box3dSensorEnded>[];
    for (var i = 0; i < count; i++) {
      native.b3dSensorEndAt(world, i, _shapes);
      events.add(
        Box3dSensorEnded(sensorShape: _shapes[0], visitorShape: _shapes[1]),
      );
    }
    return events;
  }

  @override
  Box3dRayHit? raycast(int world, Vector3 origin, Vector3 dir, int c, int m) {
    final hit = native.b3dRaycastClosest(
      world,
      origin.x,
      origin.y,
      origin.z,
      dir.x,
      dir.y,
      dir.z,
      c,
      m,
      _hit,
    );
    return hit == 0 ? null : _rayHitFrom(_hit.ref, dir.length);
  }

  @override
  List<Box3dRayHit> raycastAll(
    int world,
    Vector3 origin,
    Vector3 dir,
    int c,
    int m,
  ) {
    final count = native.b3dRaycastAll(
      world,
      origin.x,
      origin.y,
      origin.z,
      dir.x,
      dir.y,
      dir.z,
      c,
      m,
    );
    final length = dir.length;
    final hits = <Box3dRayHit>[];
    for (var i = 0; i < count; i++) {
      native.b3dQueryHitAt(i, _hit);
      hits.add(_rayHitFrom(_hit.ref, length));
    }
    return hits;
  }

  @override
  List<int> overlapSphere(
    int world,
    Vector3 center,
    double radius,
    int c,
    int m,
  ) {
    final count = native.b3dOverlapSphere(
      world,
      center.x,
      center.y,
      center.z,
      radius,
      c,
      m,
    );
    return [for (var i = 0; i < count; i++) native.b3dQueryShapeAt(i)];
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
    final count = native.b3dOverlapBox(
      world,
      center.x,
      center.y,
      center.z,
      halfExtents.x,
      halfExtents.y,
      halfExtents.z,
      rotation.x,
      rotation.y,
      rotation.z,
      rotation.w,
      c,
      m,
    );
    return [for (var i = 0; i < count; i++) native.b3dQueryShapeAt(i)];
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
    final hit = native.b3dShapecastSphere(
      world,
      origin.x,
      origin.y,
      origin.z,
      radius,
      dir.x,
      dir.y,
      dir.z,
      c,
      m,
      _hit,
    );
    return hit == 0 ? null : _rayHitFrom(_hit.ref, dir.length);
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
    final hit = native.b3dShapecastBox(
      world,
      origin.x,
      origin.y,
      origin.z,
      halfExtents.x,
      halfExtents.y,
      halfExtents.z,
      rotation.x,
      rotation.y,
      rotation.z,
      rotation.w,
      dir.x,
      dir.y,
      dir.z,
      c,
      m,
      _hit,
    );
    return hit == 0 ? null : _rayHitFrom(_hit.ref, dir.length);
  }
}
