// The operation surface the idiomatic box3d API drives, independent of how
// the shim is reached. One implementation calls the shim as a native
// dynamic library (dart:ffi); a later one will call it as a WebAssembly
// module. Both exchange plain Dart values and vector_math types here, so
// nothing about how the shim is reached leaks into the public API.
//
// This surface is deliberately engine-agnostic: it mirrors box3d, and
// references nothing from any engine that consumes the package.

import 'package:vector_math/vector_math.dart';

/// Body-kind bytes shared with the shim's C ABI (match b3BodyType).
const int bodyKindStatic = 0;
const int bodyKindKinematic = 1;
const int bodyKindDynamic = 2;

/// The shim operations the idiomatic layer depends on. A world is a packed
/// uint32 handle; bodies and shapes are packed uint64 handles. The single
/// shared instance is created by the factory; each world passes its own
/// handle back in.
abstract class Box3dBindings {
  // World.
  int worldCreate(double gx, double gy, double gz);
  void worldDestroy(int world);
  void worldSetGravity(int world, double x, double y, double z);
  void worldStep(int world, double dt, int subSteps);

  // Bodies.
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
  );
  void bodyDestroy(int body);
  Vector3 bodyPosition(int body);
  Quaternion bodyRotation(int body);
  void bodySetTransform(
    int body,
    double px,
    double py,
    double pz,
    double qx,
    double qy,
    double qz,
    double qw,
  );
  Vector3 bodyLinearVelocity(int body);
  void bodySetLinearVelocity(int body, double x, double y, double z);
  Vector3 bodyAngularVelocity(int body);
  void bodySetAngularVelocity(int body, double x, double y, double z);
  void bodySetLinearDamping(int body, double damping);
  void bodySetAngularDamping(int body, double damping);
  void bodySetGravityScale(int body, double scale);
  int bodyKind(int body);
  void bodySetKind(int body, int kind);
  double bodyMass(int body);
  void bodyApplyMassFromShapes(int body);
  void bodySetMotionLocks(
    int body,
    bool lx,
    bool ly,
    bool lz,
    bool ax,
    bool ay,
    bool az,
  );
  void bodySetBullet(int body, bool enabled);
  bool bodyIsAwake(int body);
  void bodySetAwake(int body, bool awake);
  void bodyEnableSleep(int body, bool enabled);
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
  );
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
  );
  void bodyApplyTorque(int body, double x, double y, double z, bool wake);
  void bodyApplyAngularImpulse(
    int body,
    double x,
    double y,
    double z,
    bool wake,
  );

  // Shapes.
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
  );
  int shapeBox(
    int body,
    double hx,
    double hy,
    double hz,
    double friction,
    double restitution,
    double density,
    bool isSensor,
  );
}
