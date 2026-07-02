// The operation surface the idiomatic box3d API drives, independent of how
// the shim is reached. One implementation calls the shim as a native
// dynamic library (dart:ffi); a later one will call it as a WebAssembly
// module. Both exchange plain Dart values and vector_math types here, so
// nothing about how the shim is reached leaks into the public API.
//
// This surface is deliberately engine-agnostic: it mirrors box3d, and
// references nothing from any engine that consumes the package.

import 'dart:typed_data';

import 'package:vector_math/vector_math.dart';

import '../events.dart';
import '../queries.dart';

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
  );
  int shapeCylinder(
    int body,
    double halfHeight,
    double radius,
    int sides,
    double friction,
    double restitution,
    double density,
    bool isSensor,
  );

  /// Returns 0 (a null handle) when box3d rejects the point set.
  int shapeConvexHull(
    int body,
    Float32List points,
    double friction,
    double restitution,
    double density,
    bool isSensor,
  );

  /// Returns 0 (a null handle) when box3d rejects the mesh.
  int shapeTriMesh(
    int body,
    Float32List vertices,
    Uint32List indices,
    double friction,
    double restitution,
    double density,
    bool isSensor,
  );

  /// Returns 0 (a null handle) on rejection. Heights are row-major over a
  /// countX by countZ grid.
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
  );

  // Shape mutation.
  void shapeSetMaterial(
    int shape,
    double friction,
    double restitution,
    double density,
  );
  void shapeSetFilter(int shape, int category, int mask, int group);
  void shapeEnableSensorEvents(int shape, bool enabled);
  void shapeEnableContactEvents(int shape, bool enabled);
  void shapeDestroy(int shape, bool updateBodyMass);

  // Joints. Each body's local frame is a position plus a rotation; the
  // revolute/prismatic axis is the frame's local Z axis.
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
  );
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
  );
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
  );
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
  );
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
  );
  void jointDestroy(int joint, bool wakeBodies);

  // Events from the most recent step (valid until the next step).
  List<Box3dContactBegan> contactBegan(int world);
  List<Box3dContactEnded> contactEnded(int world);
  List<Box3dSensorBegan> sensorBegan(int world);
  List<Box3dSensorEnded> sensorEnded(int world);

  // Scene queries. `dir` is the full cast translation. category/mask are the
  // query filter bits.
  Box3dRayHit? raycast(int world, Vector3 origin, Vector3 dir, int c, int m);
  List<Box3dRayHit> raycastAll(
    int world,
    Vector3 origin,
    Vector3 dir,
    int c,
    int m,
  );
  List<int> overlapSphere(
    int world,
    Vector3 center,
    double radius,
    int c,
    int m,
  );
  List<int> overlapBox(
    int world,
    Vector3 center,
    Vector3 halfExtents,
    Quaternion rotation,
    int c,
    int m,
  );
  Box3dRayHit? shapeCastSphere(
    int world,
    Vector3 origin,
    double radius,
    Vector3 dir,
    int c,
    int m,
  );
  Box3dRayHit? shapeCastBox(
    int world,
    Vector3 origin,
    Vector3 halfExtents,
    Quaternion rotation,
    Vector3 dir,
    int c,
    int m,
  );
}
