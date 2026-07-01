import 'package:vector_math/vector_math.dart';

import 'body.dart';
import 'ffi/box3d_bindings.dart';
import 'ffi/box3d_bindings_factory.dart';
import 'physics_types.dart';

/// A box3d simulation world: a container of bodies and shapes advanced with
/// [step].
///
/// `await Box3d.ensureInitialized()` before constructing a world so the
/// backend is loaded on every platform (it is a no-op on native).
class Box3dWorld {
  /// Creates an empty world with the given [gravity] (default -9.81 on Y).
  factory Box3dWorld({Vector3? gravity}) {
    final g = gravity ?? Vector3(0, -9.81, 0);
    final bindings = box3dBindings();
    final handle = bindings.worldCreate(g.x, g.y, g.z);
    return Box3dWorld._(bindings, handle, g.clone());
  }

  Box3dWorld._(this._bindings, this._handle, this._gravity);

  final Box3dBindings _bindings;
  final int _handle;
  Vector3 _gravity;
  bool _destroyed = false;

  /// The gravity applied to dynamic bodies, in units per second squared.
  Vector3 get gravity => _gravity.clone();

  set gravity(Vector3 value) {
    _gravity = value.clone();
    _bindings.worldSetGravity(_handle, value.x, value.y, value.z);
  }

  /// Advances the simulation by [dt] seconds. [subSteps] trades cost for
  /// solver accuracy; box3d's usual default is 4.
  void step(double dt, {int subSteps = 4}) {
    _bindings.worldStep(_handle, dt, subSteps);
  }

  /// Creates a body of [type] at [position] / [rotation] (both optional,
  /// defaulting to the origin with identity rotation).
  Box3dBody createBody({
    Box3dBodyType type = Box3dBodyType.dynamic_,
    Vector3? position,
    Quaternion? rotation,
  }) {
    final p = position ?? Vector3.zero();
    final q = rotation ?? Quaternion.identity();
    final handle = _bindings.bodyCreate(
      _handle,
      type.kind,
      p.x,
      p.y,
      p.z,
      q.x,
      q.y,
      q.z,
      q.w,
    );
    return Box3dBody(_bindings, handle, type);
  }

  /// Destroys the world and everything in it.
  void dispose() {
    if (_destroyed) return;
    _destroyed = true;
    _bindings.worldDestroy(_handle);
  }
}
