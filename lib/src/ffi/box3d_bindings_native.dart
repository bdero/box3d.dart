// dart:ffi implementation of Box3dBindings: calls the shim as a native
// dynamic library and owns the reusable scratch buffer that the
// struct-returning reads (position, rotation, velocity) come back through.

import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:vector_math/vector_math.dart';

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
}
