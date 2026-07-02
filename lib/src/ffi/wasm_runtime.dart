// Marshalling layer over a WebAssembly instance of the box3d shim.
//
// The shim exposes the same flat b3d_* C ABI whether it is loaded as a
// native dynamic library (via dart:ffi) or as a WebAssembly module. On the
// WebAssembly side a "pointer" is a byte offset into the module's linear
// memory, and structs are read and written by hand at those offsets using
// the same field layouts the native bindings describe.
//
// This file holds the typed reads and writes, which are plain Dart and run
// anywhere. A concrete subclass supplies the live memory view and the
// module's exported allocator (b3d_alloc / b3d_free); see
// wasm_runtime_web.dart for the dart:js_interop implementation.

import 'dart:typed_data';

/// Typed access to a WebAssembly instance's linear memory plus the module's
/// exported allocator.
abstract class WasmRuntime {
  /// A view over the module's current linear memory.
  ///
  /// Read this getter on every access rather than caching it: when the
  /// module grows its memory the backing buffer is replaced, detaching any
  /// view taken beforehand.
  ByteData get memory;

  /// Allocates [byteCount] bytes and returns the pointer (a byte offset).
  /// Returns 0 for a zero-byte request.
  int alloc(int byteCount);

  /// Frees a pointer previously returned by [alloc].
  void free(int pointer);

  double readF32(int p) => memory.getFloat32(p, Endian.little);
  void writeF32(int p, double v) => memory.setFloat32(p, v, Endian.little);

  int readI32(int p) => memory.getInt32(p, Endian.little);
  int readU32(int p) => memory.getUint32(p, Endian.little);
  int readU8(int p) => memory.getUint8(p);

  /// Reads a packed uint64 handle as an int (low + high * 2^32). Exact
  /// while the value fits in 53 bits, matching how a BigInt handle returned
  /// from a call is reduced.
  int readHandle(int p) =>
      memory.getUint32(p, Endian.little) +
      memory.getUint32(p + 4, Endian.little) * 0x100000000;

  /// Reads [count] consecutive 32-bit floats starting at [p].
  Float32List readF32List(int p, int count) {
    final view = memory;
    final out = Float32List(count);
    for (var i = 0; i < count; i++) {
      out[i] = view.getFloat32(p + i * 4, Endian.little);
    }
    return out;
  }

  /// Writes [values] as consecutive 32-bit floats starting at [p].
  void writeF32List(int p, List<double> values) {
    final view = memory;
    for (var i = 0; i < values.length; i++) {
      view.setFloat32(p + i * 4, values[i], Endian.little);
    }
  }

  /// Writes [values] as consecutive 32-bit ints starting at [p].
  void writeI32List(int p, List<int> values) {
    final view = memory;
    for (var i = 0; i < values.length; i++) {
      view.setInt32(p + i * 4, values[i], Endian.little);
    }
  }
}
