// Web backend factory: the shim is a WebAssembly module downloaded at
// runtime (the web counterpart of the native code asset), instantiated once
// and shared by every world. It must be loaded before the first world is
// created; ensureBox3dReady does the download (and checksum, for a released
// module), and box3dBindings then returns bindings on the shared instance.
//
// During development, before a release exists, set
// --dart-define=BOX3D_WASM_URL=<url> to load a locally served module (a
// relative, same-origin URL avoids CORS). Checksum verification is skipped
// for an explicit override.

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'box3d_bindings.dart';
import 'wasm_box3d_bindings.dart';
import 'wasm_release.dart';
import 'wasm_runtime_web.dart';

const _urlOverride = String.fromEnvironment('BOX3D_WASM_URL');

JsWasmRuntime? _runtime;

/// Downloads and instantiates the shim's WebAssembly module once. Safe to
/// call repeatedly; later calls return immediately.
Future<void> ensureBox3dReady() async {
  if (_runtime != null) return;
  final (url, expectedSha256) = _resolveSource();
  final bytes = await _fetchBytes(url);
  if (expectedSha256 != null) {
    final actual = sha256.convert(bytes).toString();
    if (actual != expectedSha256) {
      throw StateError(
        'Checksum mismatch for the box3d wasm module from $url.\n'
        '  expected: $expectedSha256\n  actual:   $actual',
      );
    }
  }
  _runtime = await JsWasmRuntime.instantiate(bytes);
}

WasmBox3dBindings? _shared;

/// The shared bindings on the loaded module. Throws if the module has not
/// been loaded yet.
Box3dBindings box3dBindings() {
  final runtime = _runtime;
  if (runtime == null) {
    throw StateError(
      'The box3d WebAssembly module is not loaded. Await '
      'Box3d.ensureInitialized() before constructing a world on the web.',
    );
  }
  return _shared ??= WasmBox3dBindings(runtime);
}

(String, String?) _resolveSource() {
  if (_urlOverride.isNotEmpty) return (_urlOverride, null);
  if (wasmReleaseTag.isEmpty || wasmSha256.isEmpty) {
    throw StateError(
      'No box3d wasm release is configured yet. Build the module '
      '(tool/build_wasm.sh) and set --dart-define=BOX3D_WASM_URL=<url> to a '
      'served copy, or use a published release of box3d.',
    );
  }
  return ('$wasmReleaseBaseUrl/$wasmReleaseTag/$wasmFileName', wasmSha256);
}

Future<Uint8List> _fetchBytes(String url) async {
  final response = await _fetch(url.toJS).toDart;
  if (!response.ok) {
    throw StateError(
      'Could not download the box3d wasm module from $url: '
      'HTTP ${response.status}',
    );
  }
  final buffer = await response.arrayBuffer().toDart;
  return buffer.toDart.asUint8List();
}

@JS('fetch')
external JSPromise<_FetchResponse> _fetch(JSString url);

extension type _FetchResponse(JSObject _) implements JSObject {
  external bool get ok;
  external int get status;
  external JSPromise<JSArrayBuffer> arrayBuffer();
}
