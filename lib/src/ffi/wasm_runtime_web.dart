// dart:js_interop implementation of [WasmRuntime]: instantiates the box3d
// shim's WebAssembly module and binds its exported memory and allocator.
// Only compiled on the web; the per-function b3d_* bindings are layered on
// top of the instance separately (see wasm_box3d_bindings.dart).

import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'wasm_runtime.dart';

/// A [WasmRuntime] backed by an instantiated WebAssembly module.
class JsWasmRuntime extends WasmRuntime {
  JsWasmRuntime._(this.exports);

  /// The instance's exports. The b3d_* bindings call functions on this.
  final JSObject exports;

  /// Instantiates the box3d shim module from [bytes]. The module is a
  /// standalone reactor that needs only three trivial host functions, stubbed
  /// here: it owns and exports its own linear memory and allocator.
  static Future<JsWasmRuntime> instantiate(Uint8List bytes) async {
    final result = await _instantiate(bytes.toJS, _imports()).toDart;
    return JsWasmRuntime._(result.instance.exports);
  }

  static JSObject _imports() {
    final wasi = JSObject();
    // Only used by box3d's profiling timer; a fixed 0 is harmless.
    wasi['clock_time_get'] =
        ((JSAny? id, JSAny? precision, JSAny? ptr) => 0.toJS).toJS;
    // Logging sink; report everything written.
    wasi['fd_write'] =
        ((JSAny? fd, JSAny? iov, JSAny? count, JSAny? written) => 0.toJS).toJS;
    final env = JSObject();
    env['emscripten_notify_memory_growth'] = ((JSAny? index) {}).toJS;
    final imports = JSObject();
    imports['wasi_snapshot_preview1'] = wasi;
    imports['env'] = env;
    return imports;
  }

  @override
  ByteData get memory {
    final mem = exports['memory'] as JSObject;
    return (mem['buffer'] as JSArrayBuffer).toDart.asByteData();
  }

  @override
  int alloc(int byteCount) {
    if (byteCount == 0) return 0;
    return (exports.callMethod('b3d_alloc'.toJS, byteCount.toJS) as JSNumber)
        .toDartInt;
  }

  @override
  void free(int pointer) {
    if (pointer == 0) return;
    exports.callMethod('b3d_free'.toJS, pointer.toJS);
  }
}

@JS('WebAssembly.instantiate')
external JSPromise<_InstantiatedSource> _instantiate(
  JSUint8Array bytes,
  JSObject imports,
);

extension type _InstantiatedSource(JSObject _) implements JSObject {
  external _Instance get instance;
}

extension type _Instance(JSObject _) implements JSObject {
  external JSObject get exports;
}
