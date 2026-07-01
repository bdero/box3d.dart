// Native backend factory: the shim is a dynamic library reached over
// dart:ffi, bundled and linked by the build hook, so readiness is a no-op
// and one shared bindings instance serves every world.

import 'box3d_bindings.dart';
import 'box3d_bindings_native.dart';

Box3dBindings? _shared;

/// Nothing to load: the native library is bundled by the build hook.
Future<void> ensureBox3dReady() async {}

/// The shared native bindings instance.
Box3dBindings box3dBindings() => _shared ??= NativeBox3dBindings();
