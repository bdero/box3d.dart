// Build hook for the box3d package.
//
// Compiles the vendored box3d C sources (native/box3d/src) together with
// the flat C shim (native/shim) into a single dynamic library, emitted as
// the `box3d_native` code asset that the FFI bindings load at runtime.
//
// This is the source-build path. It needs a C toolchain, which the Flutter
// and Dart SDKs already provide through the hook's build config. A later
// phase adds a prebuilt-download path so consumers need no toolchain; until
// then every build compiles box3d from the pinned submodule.

import 'dart:io';

import 'package:hooks/hooks.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

const _assetName = 'box3d_native';

// box3d requires C17. Its sources are self-contained (only libm on Unix)
// and select precision / SIMD through compile-time macros that default,
// with no defines, to single precision and native SIMD, which is what we
// want for the native build.
const _box3dSrc = 'native/box3d/src';
const _box3dInclude = 'native/box3d/include';
const _shimSrc = 'native/shim/box3d_shim.c';

Future<void> main(List<String> args) async {
  await build(args, (input, output) async {
    // CBuilder.run itself skips when the build does not want code assets.
    final sources = <String>[..._box3dSources(input), _shimSrc];

    final builder = CBuilder.library(
      name: _assetName,
      assetName: _assetName,
      sources: sources,
      includes: const [
        _box3dInclude,
        // box3d's own sources include their sibling headers by bare name
        // (e.g. #include "core.h"), so src/ must be on the include path too.
        _box3dSrc,
        'native/shim',
      ],
      std: 'c17',
    );

    await builder.run(input: input, output: output);
  });
}

// Every .c file under the vendored box3d src directory, as package-root
// relative paths. Globbed rather than hard-coded so a submodule bump that
// adds or removes a source file needs no edit here.
List<String> _box3dSources(BuildInput input) {
  final dir = Directory.fromUri(input.packageRoot.resolve('$_box3dSrc/'));
  final root = input.packageRoot.toFilePath();
  return dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.c'))
      .map((f) => f.path.substring(root.length))
      .toList()
    ..sort();
}
