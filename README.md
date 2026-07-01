# box3d

Dart FFI bindings for [box3d](https://github.com/erincatto/box3d), Erin Catto's 3D rigid body physics engine.

This is a pure Dart package (no Flutter dependency), so it can be used from any Dart runtime that supports FFI, including Flutter apps, `dart run` command-line programs, and servers.

## Status

These bindings are in active development. This early release reserves the package name and lays out the structure. The FFI bindings and prebuilt native binaries are not here yet.

Planned:

- Generated FFI bindings over the box3d C API.
- Prebuilt native binaries for the common platforms, downloaded by a build hook (no local C toolchain required for consumers), with a source build fallback.
- A small idiomatic Dart surface (worlds, bodies, shapes, joints, stepping) over the raw bindings.

## Usage

```dart
import 'package:box3d/box3d.dart';

void main() {
  print(box3dBindingsVersion);
}
```

## License

MIT, see [LICENSE](LICENSE). box3d itself is MIT licensed by Erin Catto, see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
