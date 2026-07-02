#!/usr/bin/env bash
#
# Builds the box3d WebAssembly module for the web backend: box3d plus the
# shim, compiled with emscripten into a standalone reactor module that
# exports the b3d_* C ABI (and b3d_alloc/b3d_free) plus its linear memory.
# The web backend instantiates it directly with a tiny import stub; see
# lib/src/ffi/wasm_runtime_web.dart.
#
# SIMD is disabled (box3d's SSE2/NEON path does not map to plain wasm) and
# the world runs single-threaded, matching the native shim. Requires the
# emscripten SDK on PATH (source emsdk_env.sh first).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$ROOT/build/wasm"
OUT="$OUT_DIR/box3d_native.wasm"

if ! command -v emcc >/dev/null 2>&1; then
  echo "emcc not found. Install and activate the emscripten SDK first:" >&2
  echo "  source /path/to/emsdk/emsdk_env.sh" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

# Export every b3d_* function (identifiers immediately followed by '(' in the
# shim header), each prefixed with '_' as emscripten expects.
EXPORTS=$(grep -oE 'b3d_[a-z_0-9]+\(' "$ROOT/native/shim/box3d_shim.h" \
  | tr -d '(' | sort -u | sed 's/^/_/' | paste -sd, -)

emcc -O3 -DNDEBUG -DBOX3D_DISABLE_SIMD \
  -I"$ROOT/native/box3d/include" \
  -I"$ROOT/native/box3d/src" \
  -I"$ROOT/native/shim" \
  "$ROOT"/native/box3d/src/*.c \
  "$ROOT/native/shim/box3d_shim.c" \
  -sSTANDALONE_WASM -sALLOW_MEMORY_GROWTH=1 --no-entry \
  -sEXPORTED_FUNCTIONS="$EXPORTS" \
  -o "$OUT"

# Size-optimize with emscripten's own wasm-opt (matches the emitted wasm
# feature set; a system binaryen may be too old to validate it).
WASM_OPT="$(dirname "$(command -v emcc)")/../upstream/bin/wasm-opt"
if [ -x "$WASM_OPT" ]; then
  "$WASM_OPT" -Oz --all-features "$OUT" -o "$OUT"
fi

echo "Built $OUT ($(du -h "$OUT" | cut -f1))"
