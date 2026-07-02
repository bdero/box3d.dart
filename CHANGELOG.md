## 0.1.0

- First functional release. Vendors box3d (pinned to its v0.1.0) and builds
  it, plus a thin C shim, from source through a native-assets build hook, so
  no separate toolchain is needed. Exposes an idiomatic Dart API: worlds,
  rigid bodies, the sphere/box/capsule/cylinder/convex-hull/triangle-mesh/
  height-field shapes, weld/revolute/prismatic/spherical/distance joints,
  contact and sensor events, and raycast/overlap/shape-cast queries. Native
  platforms only for now; the web (WebAssembly) backend is not built yet.

## 0.0.1

- Initial release. These bindings are in active development; this release
  reserves the package name and establishes the package structure. FFI
  bindings and native binaries are not yet included.
