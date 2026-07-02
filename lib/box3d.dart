/// Dart FFI bindings for the box3d 3D rigid body physics engine.
///
/// `await Box3d.ensureInitialized()`, create a [Box3dWorld], add bodies and
/// shapes, and advance it with [Box3dWorld.step]. This package is
/// engine-agnostic: it mirrors box3d and depends on no rendering engine.
library;

export 'src/body.dart';
export 'src/box3d_base.dart';
export 'src/events.dart';
export 'src/physics_types.dart';
export 'src/queries.dart';
export 'src/version.dart';
export 'src/world.dart';
