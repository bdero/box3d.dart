// Runs box3d in a real browser over WebAssembly, driving the actual Dart
// web backend (WasmBox3dBindings over js_interop) against the module. The
// module is embedded as base64 (see tool/embed_wasm.sh) so the test needs no
// server. This is the live-browser counterpart to the native suites.
//
// ignore_for_file: implementation_imports

@TestOn('browser')
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:box3d/src/ffi/box3d_bindings.dart';
import 'package:box3d/src/ffi/wasm_box3d_bindings.dart';
import 'package:box3d/src/ffi/wasm_runtime_web.dart';
import 'package:test/test.dart';

import 'wasm_module.g.dart';

// The committed wasm_module.g.dart holds an empty string; tool/embed_wasm.sh
// fills it with the built module. Skip when it is not embedded so a plain
// checkout (and analysis) stays green; CI embeds it before running.
final Object? _skip = wasmModuleBase64.isEmpty
    ? 'wasm module not embedded; run tool/build_wasm.sh then tool/embed_wasm.sh'
    : null;

void main() {
  test('a dynamic box falls under gravity in the browser over wasm', () async {
    final runtime = await JsWasmRuntime.instantiate(
      Uint8List.fromList(base64.decode(wasmModuleBase64)),
    );
    final b = WasmBox3dBindings(runtime);

    final world = b.worldCreate(0, -10, 0);
    final body = b.bodyCreate(world, bodyKindDynamic, 0, 5, 0, 0, 0, 0, 1);
    b.shapeBox(body, 0.5, 0.5, 0.5, 0.5, 0, 1, false);

    final y0 = b.bodyPosition(body).y;
    for (var i = 0; i < 120; i++) {
      b.worldStep(world, 1 / 60, 4);
    }
    final y1 = b.bodyPosition(body).y;

    // ~0.5 * 10 * 2^2 = ~20 units of free fall over two simulated seconds.
    expect(y0, closeTo(5, 1e-3));
    expect(y1, lessThan(y0 - 15));
    b.worldDestroy(world);
  }, skip: _skip);

  test(
    'a body rests on a floor and reports a contact in the browser',
    () async {
      final runtime = await JsWasmRuntime.instantiate(
        Uint8List.fromList(base64.decode(wasmModuleBase64)),
      );
      final b = WasmBox3dBindings(runtime);
      final world = b.worldCreate(0, -10, 0);

      final floor = b.bodyCreate(world, bodyKindStatic, 0, -0.5, 0, 0, 0, 0, 1);
      b.shapeBox(floor, 50, 0.5, 50, 0.8, 0, 1, false);
      final box = b.bodyCreate(world, bodyKindDynamic, 0, 3, 0, 0, 0, 0, 1);
      b.shapeBox(box, 0.5, 0.5, 0.5, 0.8, 0, 1, false);

      for (var i = 0; i < 240; i++) {
        b.worldStep(world, 1 / 60, 4);
      }
      // Rests with its center about half its height above the floor top (y=0).
      expect(b.bodyPosition(box).y, closeTo(0.5, 0.1));
      b.worldDestroy(world);
    },
    skip: _skip,
  );
}
