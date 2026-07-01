// Web backend factory (placeholder).
//
// The web path runs the shim as a WebAssembly module downloaded at
// runtime, marshalled over linear memory the way the native backend uses
// dart:ffi. That is a later phase; until then the web factory throws so a
// web build compiles (no dart:ffi here) but fails loudly if used.

import 'box3d_bindings.dart';

Future<void> ensureBox3dReady() async {
  throw UnsupportedError(
    'box3d does not support the web yet. The WebAssembly backend is not '
    'implemented.',
  );
}

Box3dBindings box3dBindings() {
  throw UnsupportedError(
    'box3d does not support the web yet. The WebAssembly backend is not '
    'implemented.',
  );
}
