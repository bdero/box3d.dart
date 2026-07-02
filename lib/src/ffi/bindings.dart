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

@Native<Void Function(Uint64, Pointer<Float>)>(symbol: 'b3d_body_get_transform')
external void b3dBodyGetTransform(int body, Pointer<Float> out7);

@Native<Void Function(Uint64, Float, Float, Float, Float, Float, Float, Float)>(
  symbol: 'b3d_body_set_transform',
)
external void b3dBodySetTransform(
  int body,
  double px,
  double py,
  double pz,
  double qx,
  double qy,
  double qz,
  double qw,
);

@Native<Void Function(Uint64, Pointer<Float>)>(
  symbol: 'b3d_body_get_linear_velocity',
)
external void b3dBodyGetLinearVelocity(int body, Pointer<Float> out3);

@Native<Void Function(Uint64, Float, Float, Float)>(
  symbol: 'b3d_body_set_linear_velocity',
)
external void b3dBodySetLinearVelocity(int body, double x, double y, double z);

@Native<Void Function(Uint64, Pointer<Float>)>(
  symbol: 'b3d_body_get_angular_velocity',
)
external void b3dBodyGetAngularVelocity(int body, Pointer<Float> out3);

@Native<Void Function(Uint64, Float, Float, Float)>(
  symbol: 'b3d_body_set_angular_velocity',
)
external void b3dBodySetAngularVelocity(int body, double x, double y, double z);

@Native<Void Function(Uint64, Float)>(symbol: 'b3d_body_set_linear_damping')
external void b3dBodySetLinearDamping(int body, double damping);

@Native<Void Function(Uint64, Float)>(symbol: 'b3d_body_set_angular_damping')
external void b3dBodySetAngularDamping(int body, double damping);

@Native<Void Function(Uint64, Float)>(symbol: 'b3d_body_set_gravity_scale')
external void b3dBodySetGravityScale(int body, double scale);

@Native<Int32 Function(Uint64)>(symbol: 'b3d_body_get_kind')
external int b3dBodyGetKind(int body);

@Native<Void Function(Uint64, Int32)>(symbol: 'b3d_body_set_kind')
external void b3dBodySetKind(int body, int kind);

@Native<Float Function(Uint64)>(symbol: 'b3d_body_get_mass')
external double b3dBodyGetMass(int body);

@Native<Void Function(Uint64)>(symbol: 'b3d_body_apply_mass_from_shapes')
external void b3dBodyApplyMassFromShapes(int body);

@Native<Void Function(Uint64, Int32, Int32, Int32, Int32, Int32, Int32)>(
  symbol: 'b3d_body_set_motion_locks',
)
external void b3dBodySetMotionLocks(
  int body,
  int lx,
  int ly,
  int lz,
  int ax,
  int ay,
  int az,
);

@Native<Void Function(Uint64, Int32)>(symbol: 'b3d_body_set_bullet')
external void b3dBodySetBullet(int body, int enabled);

@Native<Int32 Function(Uint64)>(symbol: 'b3d_body_is_awake')
external int b3dBodyIsAwake(int body);

@Native<Void Function(Uint64, Int32)>(symbol: 'b3d_body_set_awake')
external void b3dBodySetAwake(int body, int awake);

@Native<Void Function(Uint64, Int32)>(symbol: 'b3d_body_enable_sleep')
external void b3dBodyEnableSleep(int body, int enabled);

@Native<
  Void Function(Uint64, Float, Float, Float, Int32, Float, Float, Float, Int32)
>(symbol: 'b3d_body_apply_force')
external void b3dBodyApplyForce(
  int body,
  double fx,
  double fy,
  double fz,
  int hasPoint,
  double px,
  double py,
  double pz,
  int wake,
);

@Native<
  Void Function(Uint64, Float, Float, Float, Int32, Float, Float, Float, Int32)
>(symbol: 'b3d_body_apply_impulse')
external void b3dBodyApplyImpulse(
  int body,
  double ix,
  double iy,
  double iz,
  int hasPoint,
  double px,
  double py,
  double pz,
  int wake,
);

@Native<Void Function(Uint64, Float, Float, Float, Int32)>(
  symbol: 'b3d_body_apply_torque',
)
external void b3dBodyApplyTorque(
  int body,
  double x,
  double y,
  double z,
  int wake,
);

@Native<Void Function(Uint64, Float, Float, Float, Int32)>(
  symbol: 'b3d_body_apply_angular_impulse',
)
external void b3dBodyApplyAngularImpulse(
  int body,
  double x,
  double y,
  double z,
  int wake,
);

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
    Float,
    Float,
    Float,
    Int32,
  )
>(symbol: 'b3d_shape_capsule')
external int b3dShapeCapsule(
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
  int isSensor,
);

@Native<
  Uint64 Function(Uint64, Float, Float, Int32, Float, Float, Float, Int32)
>(symbol: 'b3d_shape_cylinder')
external int b3dShapeCylinder(
  int body,
  double halfHeight,
  double radius,
  int sides,
  double friction,
  double restitution,
  double density,
  int isSensor,
);

@Native<
  Uint64 Function(Uint64, Pointer<Float>, Int32, Float, Float, Float, Int32)
>(symbol: 'b3d_shape_convex_hull')
external int b3dShapeConvexHull(
  int body,
  Pointer<Float> points,
  int pointCount,
  double friction,
  double restitution,
  double density,
  int isSensor,
);

@Native<
  Uint64 Function(
    Uint64,
    Pointer<Float>,
    Int32,
    Pointer<Int32>,
    Int32,
    Float,
    Float,
    Float,
    Int32,
  )
>(symbol: 'b3d_shape_trimesh')
external int b3dShapeTriMesh(
  int body,
  Pointer<Float> vertices,
  int vertexCount,
  Pointer<Int32> indices,
  int triangleCount,
  double friction,
  double restitution,
  double density,
  int isSensor,
);

@Native<
  Uint64 Function(
    Uint64,
    Int32,
    Int32,
    Pointer<Float>,
    Float,
    Float,
    Float,
    Float,
    Float,
    Float,
    Int32,
  )
>(symbol: 'b3d_shape_height_field')
external int b3dShapeHeightField(
  int body,
  int countX,
  int countZ,
  Pointer<Float> heights,
  double scaleX,
  double scaleY,
  double scaleZ,
  double friction,
  double restitution,
  double density,
  int isSensor,
);

@Native<Void Function(Uint64, Float, Float, Float)>(
  symbol: 'b3d_shape_set_material',
)
external void b3dShapeSetMaterial(
  int shape,
  double friction,
  double restitution,
  double density,
);

@Native<Void Function(Uint64, Uint64, Uint64, Int32)>(
  symbol: 'b3d_shape_set_filter',
)
external void b3dShapeSetFilter(int shape, int category, int mask, int group);

@Native<Void Function(Uint64, Int32)>(symbol: 'b3d_shape_enable_sensor_events')
external void b3dShapeEnableSensorEvents(int shape, int enabled);

@Native<Void Function(Uint64, Int32)>(symbol: 'b3d_shape_enable_contact_events')
external void b3dShapeEnableContactEvents(int shape, int enabled);

@Native<Void Function(Uint64, Int32)>(symbol: 'b3d_shape_destroy')
external void b3dShapeDestroy(int shape, int updateBodyMass);

// --- Joints ----------------------------------------------------------------
// frameA / frameB each point at 7 floats: position xyz then rotation xyzw.

@Native<
  Uint64 Function(
    Uint32,
    Uint64,
    Uint64,
    Pointer<Float>,
    Pointer<Float>,
    Int32,
    Float,
    Float,
    Float,
    Float,
  )
>(symbol: 'b3d_joint_weld')
external int b3dJointWeld(
  int world,
  int bodyA,
  int bodyB,
  Pointer<Float> frameA,
  Pointer<Float> frameB,
  int collide,
  double linearHertz,
  double angularHertz,
  double linearDamping,
  double angularDamping,
);

@Native<
  Uint64 Function(
    Uint32,
    Uint64,
    Uint64,
    Pointer<Float>,
    Pointer<Float>,
    Int32,
    Int32,
    Float,
    Float,
    Int32,
    Float,
    Float,
  )
>(symbol: 'b3d_joint_revolute')
external int b3dJointRevolute(
  int world,
  int bodyA,
  int bodyB,
  Pointer<Float> frameA,
  Pointer<Float> frameB,
  int collide,
  int enableLimit,
  double lower,
  double upper,
  int enableMotor,
  double motorSpeed,
  double maxMotorTorque,
);

@Native<
  Uint64 Function(
    Uint32,
    Uint64,
    Uint64,
    Pointer<Float>,
    Pointer<Float>,
    Int32,
    Int32,
    Float,
    Float,
    Int32,
    Float,
    Float,
  )
>(symbol: 'b3d_joint_prismatic')
external int b3dJointPrismatic(
  int world,
  int bodyA,
  int bodyB,
  Pointer<Float> frameA,
  Pointer<Float> frameB,
  int collide,
  int enableLimit,
  double lower,
  double upper,
  int enableMotor,
  double motorSpeed,
  double maxMotorForce,
);

@Native<
  Uint64 Function(
    Uint32,
    Uint64,
    Uint64,
    Pointer<Float>,
    Pointer<Float>,
    Int32,
    Int32,
    Float,
    Int32,
    Float,
    Float,
    Int32,
    Float,
  )
>(symbol: 'b3d_joint_spherical')
external int b3dJointSpherical(
  int world,
  int bodyA,
  int bodyB,
  Pointer<Float> frameA,
  Pointer<Float> frameB,
  int collide,
  int enableCone,
  double coneAngle,
  int enableTwist,
  double lowerTwist,
  double upperTwist,
  int enableMotor,
  double maxMotorTorque,
);

@Native<
  Uint64 Function(
    Uint32,
    Uint64,
    Uint64,
    Pointer<Float>,
    Pointer<Float>,
    Int32,
    Float,
    Int32,
    Float,
    Float,
    Int32,
    Float,
    Float,
    Int32,
    Float,
    Float,
  )
>(symbol: 'b3d_joint_distance')
external int b3dJointDistance(
  int world,
  int bodyA,
  int bodyB,
  Pointer<Float> frameA,
  Pointer<Float> frameB,
  int collide,
  double length,
  int enableLimit,
  double minLength,
  double maxLength,
  int enableSpring,
  double hertz,
  double dampingRatio,
  int enableMotor,
  double motorSpeed,
  double maxMotorForce,
);

@Native<Void Function(Uint64, Int32)>(symbol: 'b3d_joint_destroy')
external void b3dJointDestroy(int joint, int wakeBodies);
