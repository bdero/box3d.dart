import 'ffi/box3d_bindings_factory.dart';

/// Entry point for one-time box3d initialization.
///
/// On native platforms this is a no-op (the library is linked by the build
/// hook and ready immediately). On the web it will download and instantiate
/// the WebAssembly module. Always `await Box3d.ensureInitialized()` before
/// constructing a [Box3dWorld] so the same code runs on every platform.
///
/// Threading: box3d keeps its worlds in process-global state, so drive it
/// from a single isolate. Using worlds from multiple isolates of the same
/// process concurrently is not supported.
abstract final class Box3d {
  /// Loads box3d if it is not loaded yet. Safe to call repeatedly.
  static Future<void> ensureInitialized() => ensureBox3dReady();
}
