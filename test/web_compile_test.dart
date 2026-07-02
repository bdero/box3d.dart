// Compiles the package for the web. Importing the public API forces the
// js_interop backend (factory -> WasmBox3dBindings -> WasmRuntime) to build;
// a stray dart:ffi import anywhere on the web path would fail the compile.
// Constructing a world needs the wasm module loaded, so this only checks the
// entry point compiles and is reachable.

@TestOn('browser')
library;

import 'package:box3d/box3d.dart';
import 'package:test/test.dart';

void main() {
  test('public API compiles and links on web', () {
    expect(Box3d.ensureInitialized, isA<Function>());
  });
}
