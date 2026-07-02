# box3d

Dart FFI bindings for [box3d](https://github.com/erincatto/box3d), Erin Catto's 3D rigid body physics engine.

This is a pure Dart package (no Flutter dependency), so it can be used from any Dart runtime that supports FFI: Flutter apps, `dart run` command-line programs, and servers. A WebAssembly backend runs it on the web too.

> **Status: experimental.** box3d itself is young (this package tracks its v0.1.0), so the API may change between releases.

## How it works

box3d is vendored as C source and compiled, together with a thin C shim, into a native library through a Dart build hook. No separate toolchain is required beyond the C compiler the Dart/Flutter SDK already uses. On the web, the same shim is compiled to WebAssembly and driven over its linear memory.

## Usage

```dart
import 'package:box3d/box3d.dart';
import 'package:vector_math/vector_math.dart';

Future<void> main() async {
  await Box3d.ensureInitialized(); // no-op on native; loads the wasm on web

  final world = Box3dWorld(gravity: Vector3(0, -9.81, 0));

  // A static floor.
  final floor = world.createBody(type: Box3dBodyType.static_);
  floor.addBox(Vector3(50, 0.5, 50));

  // A falling dynamic box.
  final box = world.createBody(position: Vector3(0, 5, 0));
  box.addBox(Vector3.all(0.5));

  for (var i = 0; i < 120; i++) {
    world.step(1 / 60);
  }
  print(box.position); // resting on the floor

  world.dispose();
}
```

The API covers rigid bodies (dynamic / kinematic / static), the sphere, box, capsule, cylinder, convex-hull, triangle-mesh, and height-field shapes, weld / revolute / prismatic / spherical / distance joints, contact and sensor events (`world.drainEvents()`), and raycast / overlap / shape-cast queries.

## Web

The web backend needs the WebAssembly module. Build it with:

```sh
source /path/to/emsdk/emsdk_env.sh
tool/build_wasm.sh   # emits build/wasm/box3d_native.wasm
```

Serve that file and point the loader at it during development:

```sh
flutter run -d chrome --dart-define=BOX3D_WASM_URL=/box3d_native.wasm
```

A hosted module for released versions (so consumers need no build step) is pending.

## Threading

box3d keeps its worlds in process-global state, so drive it from a single isolate. Using worlds from multiple isolates of the same process concurrently is not supported.

## License

MIT, see [LICENSE](LICENSE). box3d itself is MIT licensed by Erin Catto, see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
