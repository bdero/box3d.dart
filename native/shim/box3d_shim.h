// Flat C ABI over box3d for the Dart bindings.
//
// box3d's own API passes small structs (ids, vectors, quaternions) by
// value. That is awkward to reach over dart:ffi and impractical to
// hand-marshal over WebAssembly linear memory, where by-value struct
// calling conventions lower to hidden pointers. This shim flattens the
// curated surface the Dart package exposes into primitives plus
// out-pointers, so the native and web backends bind one identical ABI.
//
// Handles cross as the integer packings box3d itself defines
// (b3StoreWorldId/b3StoreBodyId/...): a world is a uint32, bodies and
// shapes are uint64. This file knows only box3d; it contains nothing
// specific to any engine that consumes the Dart package.

#ifndef BOX3D_SHIM_H
#define BOX3D_SHIM_H

#include <stdint.h>

#if defined(_WIN32)
#define B3D_SHIM_API __declspec(dllexport)
#else
#define B3D_SHIM_API __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

// 1 when box3d was built in double-precision mode (a different ABI than
// this shim assumes). Used as a build-time sanity check from Dart.
B3D_SHIM_API int32_t b3d_is_double_precision(void);

// --- World -----------------------------------------------------------------

// Creates a single-threaded world with the given gravity and returns its
// packed uint32 handle.
B3D_SHIM_API uint32_t b3d_world_create(float gx, float gy, float gz);
B3D_SHIM_API void b3d_world_destroy(uint32_t world);
B3D_SHIM_API void b3d_world_set_gravity(uint32_t world, float x, float y,
                                        float z);
B3D_SHIM_API void b3d_world_step(uint32_t world, float dt, int32_t sub_steps);

// --- Bodies ----------------------------------------------------------------

// kind: 0 static, 1 kinematic, 2 dynamic (matches b3BodyType). Rotation is
// a quaternion in xyzw order.
B3D_SHIM_API uint64_t b3d_body_create(uint32_t world, int32_t kind, float px,
                                      float py, float pz, float qx, float qy,
                                      float qz, float qw);
B3D_SHIM_API void b3d_body_destroy(uint64_t body);

// out3 receives x, y, z; out4 receives x, y, z, w.
B3D_SHIM_API void b3d_body_get_position(uint64_t body, float *out3);
B3D_SHIM_API void b3d_body_get_rotation(uint64_t body, float *out4);
B3D_SHIM_API void b3d_body_get_linear_velocity(uint64_t body, float *out3);
B3D_SHIM_API void b3d_body_set_linear_velocity(uint64_t body, float x, float y,
                                               float z);

// --- Shapes ----------------------------------------------------------------

// Attaches a shape to a body and returns its packed uint64 handle. The
// material triple (friction, restitution, density) and the sensor flag are
// applied to the shape def.
B3D_SHIM_API uint64_t b3d_shape_sphere(uint64_t body, float cx, float cy,
                                       float cz, float radius, float friction,
                                       float restitution, float density,
                                       int32_t is_sensor);
B3D_SHIM_API uint64_t b3d_shape_box(uint64_t body, float hx, float hy, float hz,
                                    float friction, float restitution,
                                    float density, int32_t is_sensor);

#ifdef __cplusplus
}
#endif

#endif // BOX3D_SHIM_H
