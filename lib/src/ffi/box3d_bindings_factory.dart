// Selects the Box3dBindings backend for the target platform: the native
// dynamic library (dart:ffi) everywhere except the web, where a later
// phase will run the shim as a WebAssembly module. The conditional picks
// the web factory when dart:js_interop is available, keeping dart:ffi out
// of web builds.

export 'box3d_bindings_factory_io.dart'
    if (dart.library.js_interop) 'box3d_bindings_factory_web.dart';
