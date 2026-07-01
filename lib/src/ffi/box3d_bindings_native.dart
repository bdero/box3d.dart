// dart:ffi implementation of Box3dBindings: calls the shim as a native
// dynamic library and owns the reusable scratch buffer that the
// struct-returning reads (position, rotation, velocity) come back through.

import 'dart:ffi';

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
  Vector3 bodyLinearVelocity(int body) {
    native.b3dBodyGetLinearVelocity(body, _read);
    return Vector3(_read[0], _read[1], _read[2]);
  }

  @override
  void bodySetLinearVelocity(int body, double x, double y, double z) =>
      native.b3dBodySetLinearVelocity(body, x, y, z);

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
}
