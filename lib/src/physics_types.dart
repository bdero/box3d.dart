import 'ffi/box3d_bindings.dart';

/// How a body participates in the simulation.
enum Box3dBodyType {
  /// Never moves. Zero mass, infinite inertia.
  static_(bodyKindStatic),

  /// Moved only by setting its transform or velocity; unaffected by forces
  /// and collisions.
  kinematic(bodyKindKinematic),

  /// Fully simulated: moved by gravity, forces, and contacts.
  dynamic_(bodyKindDynamic);

  const Box3dBodyType(this.kind);

  /// The byte passed across the shim ABI (matches box3d's b3BodyType).
  final int kind;
}

/// Surface properties of a shape.
class Box3dMaterial {
  const Box3dMaterial({
    this.friction = 0.6,
    this.restitution = 0.0,
    this.density = 1.0,
  });

  /// Coulomb (dry) friction coefficient, usually in [0, 1].
  final double friction;

  /// Coefficient of restitution (bounciness), usually in [0, 1].
  final double restitution;

  /// Mass per unit volume, usually in kg/m^3.
  final double density;

  /// A reasonable default surface (moderate friction, no bounce, unit
  /// density).
  static const Box3dMaterial standard = Box3dMaterial();
}

/// A handle to a shape attached to a [Box3dBody]. Opaque for now; richer
/// shape control lands with the full shape set.
class Box3dShape {
  Box3dShape(this.handle);

  /// The packed uint64 shape handle from the shim.
  final int handle;
}
