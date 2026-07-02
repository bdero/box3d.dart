// Points the web backend at the WebAssembly build of the shim attached to
// the matching GitHub release. The release workflow uploads the module and
// its checksum; the release step fills these in (the same way native
// binaries are attached), so the published package downloads exactly its own
// release's module.
//
// Empty [wasmReleaseTag] / [wasmSha256] mean no release has been cut yet.
// Until then, point the web backend at a locally served module with
// --dart-define=BOX3D_WASM_URL=<url> (see box3d_bindings_factory_web.dart).

/// Root the module is downloaded from. GitHub release assets lack the CORS
/// headers a browser fetch needs, so releases serve the module through a
/// CORS proxy; set this to that proxy's base URL. The full URL is
/// `$wasmReleaseBaseUrl/$wasmReleaseTag/$wasmFileName`.
const String wasmReleaseBaseUrl = '';

/// The release tag the module is attached to (e.g. `box3d-0.1.0`). Empty
/// until the first web release.
const String wasmReleaseTag = '';

/// File name of the module within the release.
const String wasmFileName = 'box3d_native.wasm';

/// Lower-case hex sha256 of the released module, verified after download.
/// Empty until the first web release.
const String wasmSha256 = '';
