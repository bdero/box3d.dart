// Native FFI declarations for the box3d shim (native/shim/box3d_shim.h).
//
// Each symbol here matches one `b3d_*` C function. Handles cross as the
// integer packings box3d defines: a world is a uint32, bodies and shapes
// are uint64. By-value results (position, rotation, velocity) are read
// back through a caller-provided Pointer<Float>.
//
// Native only: this file imports dart:ffi and is never part of a web
// build. The web backend binds the same shim ABI over WebAssembly memory.

@DefaultAsset('package:box3d/box3d_native')
library;

import 'dart:ffi';

@Native<Int32 Function()>(symbol: 'b3d_is_double_precision')
external int b3dIsDoublePrecision();

// --- World -----------------------------------------------------------------

@Native<Uint32 Function(Float, Float, Float)>(symbol: 'b3d_world_create')
external int b3dWorldCreate(double gx, double gy, double gz);

@Native<Void Function(Uint32)>(symbol: 'b3d_world_destroy')
external void b3dWorldDestroy(int world);

@Native<Void Function(Uint32, Float, Float, Float)>(
  symbol: 'b3d_world_set_gravity',
)
external void b3dWorldSetGravity(int world, double x, double y, double z);

@Native<Void Function(Uint32, Float, Int32)>(symbol: 'b3d_world_step')
external void b3dWorldStep(int world, double dt, int subSteps);

// --- Bodies ----------------------------------------------------------------

@Native<
  Uint64 Function(
    Uint32,
    Int32,
    Float,
    Float,
    Float,
    Float,
    Float,
    Float,
    Float,
  )
>(symbol: 'b3d_body_create')
external int b3dBodyCreate(
  int world,
  int kind,
  double px,
  double py,
  double pz,
  double qx,
  double qy,
  double qz,
  double qw,
);

@Native<Void Function(Uint64)>(symbol: 'b3d_body_destroy')
external void b3dBodyDestroy(int body);

@Native<Void Function(Uint64, Pointer<Float>)>(symbol: 'b3d_body_get_position')
external void b3dBodyGetPosition(int body, Pointer<Float> out3);

@Native<Void Function(Uint64, Pointer<Float>)>(symbol: 'b3d_body_get_rotation')
external void b3dBodyGetRotation(int body, Pointer<Float> out4);

@Native<Void Function(Uint64, Pointer<Float>)>(
  symbol: 'b3d_body_get_linear_velocity',
)
external void b3dBodyGetLinearVelocity(int body, Pointer<Float> out3);

@Native<Void Function(Uint64, Float, Float, Float)>(
  symbol: 'b3d_body_set_linear_velocity',
)
external void b3dBodySetLinearVelocity(int body, double x, double y, double z);

// --- Shapes ----------------------------------------------------------------

@Native<
  Uint64 Function(
    Uint64,
    Float,
    Float,
    Float,
    Float,
    Float,
    Float,
    Float,
    Int32,
  )
>(symbol: 'b3d_shape_sphere')
external int b3dShapeSphere(
  int body,
  double cx,
  double cy,
  double cz,
  double radius,
  double friction,
  double restitution,
  double density,
  int isSensor,
);

@Native<
  Uint64 Function(Uint64, Float, Float, Float, Float, Float, Float, Int32)
>(symbol: 'b3d_shape_box')
external int b3dShapeBox(
  int body,
  double hx,
  double hy,
  double hz,
  double friction,
  double restitution,
  double density,
  int isSensor,
);
