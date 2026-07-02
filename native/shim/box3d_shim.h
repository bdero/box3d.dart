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

// out3 receives x, y, z; out4 receives x, y, z, w; out7 receives position
// (x, y, z) then rotation (x, y, z, w).
B3D_SHIM_API void b3d_body_get_position(uint64_t body, float *out3);
B3D_SHIM_API void b3d_body_get_rotation(uint64_t body, float *out4);
B3D_SHIM_API void b3d_body_get_transform(uint64_t body, float *out7);
B3D_SHIM_API void b3d_body_set_transform(uint64_t body, float px, float py,
                                         float pz, float qx, float qy, float qz,
                                         float qw);
B3D_SHIM_API void b3d_body_get_linear_velocity(uint64_t body, float *out3);
B3D_SHIM_API void b3d_body_set_linear_velocity(uint64_t body, float x, float y,
                                               float z);
B3D_SHIM_API void b3d_body_get_angular_velocity(uint64_t body, float *out3);
B3D_SHIM_API void b3d_body_set_angular_velocity(uint64_t body, float x, float y,
                                                float z);
B3D_SHIM_API void b3d_body_set_linear_damping(uint64_t body, float damping);
B3D_SHIM_API void b3d_body_set_angular_damping(uint64_t body, float damping);
B3D_SHIM_API void b3d_body_set_gravity_scale(uint64_t body, float scale);
B3D_SHIM_API int32_t b3d_body_get_kind(uint64_t body);
B3D_SHIM_API void b3d_body_set_kind(uint64_t body, int32_t kind);
B3D_SHIM_API float b3d_body_get_mass(uint64_t body);
// Recompute mass, center of mass, and inertia from the body's shapes.
B3D_SHIM_API void b3d_body_apply_mass_from_shapes(uint64_t body);

// Motion locks: pass 1 to lock an axis, 0 to leave it free.
B3D_SHIM_API void b3d_body_set_motion_locks(uint64_t body, int32_t lx,
                                            int32_t ly, int32_t lz, int32_t ax,
                                            int32_t ay, int32_t az);
// Treat the body as a fast-moving object for continuous collision.
B3D_SHIM_API void b3d_body_set_bullet(uint64_t body, int32_t enabled);

// Sleeping.
B3D_SHIM_API int32_t b3d_body_is_awake(uint64_t body);
B3D_SHIM_API void b3d_body_set_awake(uint64_t body, int32_t awake);
B3D_SHIM_API void b3d_body_enable_sleep(uint64_t body, int32_t enabled);

// Forces and impulses. has_point selects the point-of-application overload
// (world-space point) versus the apply-at-center overload. wake wakes the
// body if it is sleeping.
B3D_SHIM_API void b3d_body_apply_force(uint64_t body, float fx, float fy,
                                       float fz, int32_t has_point, float px,
                                       float py, float pz, int32_t wake);
B3D_SHIM_API void b3d_body_apply_impulse(uint64_t body, float ix, float iy,
                                         float iz, int32_t has_point, float px,
                                         float py, float pz, int32_t wake);
B3D_SHIM_API void b3d_body_apply_torque(uint64_t body, float x, float y,
                                        float z, int32_t wake);
B3D_SHIM_API void b3d_body_apply_angular_impulse(uint64_t body, float x,
                                                 float y, float z, int32_t wake);

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

// A capsule given the two hemisphere centers (local space) and the radius.
B3D_SHIM_API uint64_t b3d_shape_capsule(uint64_t body, float ax, float ay,
                                        float az, float bx, float by, float bz,
                                        float radius, float friction,
                                        float restitution, float density,
                                        int32_t is_sensor);

// A Y-axis cylinder centered on the body origin, tessellated into a hull
// with `sides` faces around the axis.
B3D_SHIM_API uint64_t b3d_shape_cylinder(uint64_t body, float half_height,
                                         float radius, int32_t sides,
                                         float friction, float restitution,
                                         float density, int32_t is_sensor);

// A convex hull of `point_count` points (packed xyz). Returns 0 if box3d
// rejects the point set.
B3D_SHIM_API uint64_t b3d_shape_convex_hull(uint64_t body, const float *points,
                                            int32_t point_count, float friction,
                                            float restitution, float density,
                                            int32_t is_sensor);

// A triangle mesh from `vertex_count` packed-xyz vertices and
// `triangle_count` triangles (3 int32 indices each). Concave; typically
// attached to a static body. Returns 0 if box3d rejects the mesh. The shim
// retains ownership of the built mesh (box3d references it by pointer) and
// frees it when the shape or its world is destroyed.
B3D_SHIM_API uint64_t b3d_shape_trimesh(uint64_t body, const float *vertices,
                                        int32_t vertex_count,
                                        const int32_t *indices,
                                        int32_t triangle_count, float friction,
                                        float restitution, float density,
                                        int32_t is_sensor);

// A height field over a count_x by count_z grid of unscaled heights
// (row-major), scaled by (scale_x, scale_y, scale_z). Same ownership note
// as the triangle mesh. Returns 0 on rejection.
B3D_SHIM_API uint64_t b3d_shape_height_field(
    uint64_t body, int32_t count_x, int32_t count_z, const float *heights,
    float scale_x, float scale_y, float scale_z, float friction,
    float restitution, float density, int32_t is_sensor);

// --- Shape mutation --------------------------------------------------------

B3D_SHIM_API void b3d_shape_set_material(uint64_t shape, float friction,
                                         float restitution, float density);
B3D_SHIM_API void b3d_shape_set_filter(uint64_t shape, uint64_t category,
                                       uint64_t mask, int32_t group);
B3D_SHIM_API void b3d_shape_enable_sensor_events(uint64_t shape,
                                                 int32_t enabled);
B3D_SHIM_API void b3d_shape_enable_contact_events(uint64_t shape,
                                                  int32_t enabled);
B3D_SHIM_API void b3d_shape_destroy(uint64_t shape, int32_t update_body_mass);

// --- Joints ----------------------------------------------------------------
//
// Joints connect two bodies through a local frame on each. A frame is 7
// floats: position (x, y, z) then rotation quaternion (x, y, z, w). For a
// revolute joint the hinge axis is the frame's local Z axis; for a
// prismatic joint the slide axis is the frame's local Z axis. To anchor to
// the world, use a static body as one side. All return a packed uint64
// joint handle.

B3D_SHIM_API uint64_t b3d_joint_weld(uint32_t world, uint64_t body_a,
                                     uint64_t body_b, const float *frame_a,
                                     const float *frame_b, int32_t collide,
                                     float linear_hertz, float angular_hertz,
                                     float linear_damping,
                                     float angular_damping);

B3D_SHIM_API uint64_t b3d_joint_revolute(
    uint32_t world, uint64_t body_a, uint64_t body_b, const float *frame_a,
    const float *frame_b, int32_t collide, int32_t enable_limit, float lower,
    float upper, int32_t enable_motor, float motor_speed,
    float max_motor_torque);

B3D_SHIM_API uint64_t b3d_joint_prismatic(
    uint32_t world, uint64_t body_a, uint64_t body_b, const float *frame_a,
    const float *frame_b, int32_t collide, int32_t enable_limit, float lower,
    float upper, int32_t enable_motor, float motor_speed, float max_motor_force);

B3D_SHIM_API uint64_t b3d_joint_spherical(
    uint32_t world, uint64_t body_a, uint64_t body_b, const float *frame_a,
    const float *frame_b, int32_t collide, int32_t enable_cone,
    float cone_angle, int32_t enable_twist, float lower_twist,
    float upper_twist, int32_t enable_motor, float max_motor_torque);

B3D_SHIM_API uint64_t b3d_joint_distance(
    uint32_t world, uint64_t body_a, uint64_t body_b, const float *frame_a,
    const float *frame_b, int32_t collide, float length, int32_t enable_limit,
    float min_length, float max_length, int32_t enable_spring, float hertz,
    float damping_ratio, int32_t enable_motor, float motor_speed,
    float max_motor_force);

B3D_SHIM_API void b3d_joint_destroy(uint64_t joint, int32_t wake_bodies);

#ifdef __cplusplus
}
#endif

#endif // BOX3D_SHIM_H
