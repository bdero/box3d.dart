// Implementation of the flat C ABI declared in box3d_shim.h.
//
// Every entry point loads the packed handle back into a box3d id, calls
// box3d, and writes any by-value result through an out-pointer. Defs are
// always seeded from box3d's b3Default*Def() so the internalValue guards
// and callback fields are correct; the shim only overrides the fields it
// exposes.

#include "box3d_shim.h"

#include <stdbool.h>
#include <stdlib.h>

#include "box3d/box3d.h"
#include "box3d/collision.h"
#include "box3d/id.h"
#include "box3d/types.h"

int32_t b3d_is_double_precision(void) { return b3IsDoublePrecision() ? 1 : 0; }

// ---------------------------------------------------------------------------
// Owned-geometry registry
//
// box3d copies sphere, capsule, and hull geometry into its own storage, but
// it keeps mesh and height-field data by pointer (see b3CreateShapeInternal
// in src/shape.c). Those blobs must outlive the shape, so the shim owns them
// and frees them when the shape (or its whole world) is destroyed. Single
// threaded, like the rest of the shim.
// ---------------------------------------------------------------------------

enum { b3d_owned_mesh = 0, b3d_owned_height_field = 1 };

typedef struct {
  uint64_t shape;
  int32_t kind;
  void *ptr;
} b3d_owned_entry;

static b3d_owned_entry *b3d_owned = 0;
static int32_t b3d_owned_count = 0;
static int32_t b3d_owned_cap = 0;

static void b3d_owned_add(uint64_t shape, int32_t kind, void *ptr) {
  if (b3d_owned_count == b3d_owned_cap) {
    int32_t cap = b3d_owned_cap ? b3d_owned_cap * 2 : 8;
    b3d_owned = realloc(b3d_owned, (size_t)cap * sizeof(b3d_owned_entry));
    b3d_owned_cap = cap;
  }
  b3d_owned[b3d_owned_count].shape = shape;
  b3d_owned[b3d_owned_count].kind = kind;
  b3d_owned[b3d_owned_count].ptr = ptr;
  b3d_owned_count++;
}

static void b3d_owned_free_ptr(int32_t kind, void *ptr) {
  if (kind == b3d_owned_mesh) {
    b3DestroyMesh((b3MeshData *)ptr);
  } else {
    b3DestroyHeightField((b3HeightFieldData *)ptr);
  }
}

// Frees the blob owned by one shape, if any (swap-remove).
static void b3d_owned_remove_shape(uint64_t shape) {
  for (int32_t i = 0; i < b3d_owned_count; i++) {
    if (b3d_owned[i].shape == shape) {
      b3d_owned_free_ptr(b3d_owned[i].kind, b3d_owned[i].ptr);
      b3d_owned[i] = b3d_owned[--b3d_owned_count];
      return;
    }
  }
}

// Frees every blob whose shape belongs to a world. The world index is the
// high half of the packed world handle and the world0 field packed into
// each shape handle (see box3d's id.h packings).
static void b3d_owned_free_world(uint32_t world) {
  uint16_t world_index = (uint16_t)(world >> 16);
  for (int32_t i = 0; i < b3d_owned_count;) {
    uint16_t shape_world = (uint16_t)((b3d_owned[i].shape >> 16) & 0xFFFF);
    if (shape_world == world_index) {
      b3d_owned_free_ptr(b3d_owned[i].kind, b3d_owned[i].ptr);
      b3d_owned[i] = b3d_owned[--b3d_owned_count];
    } else {
      i++;
    }
  }
}

// --- World -----------------------------------------------------------------

uint32_t b3d_world_create(float gx, float gy, float gz) {
  b3WorldDef def = b3DefaultWorldDef();
  def.gravity = (b3Vec3){gx, gy, gz};
  // Single-threaded: run every task inline on the calling thread. No task
  // callbacks and a worker count of 1 keep box3d off its internal thread
  // pool, which the web build cannot use and which we want deterministic.
  def.workerCount = 1;
  def.enqueueTask = 0;
  def.finishTask = 0;
  b3WorldId world = b3CreateWorld(&def);
  return b3StoreWorldId(world);
}

void b3d_world_destroy(uint32_t world) {
  // Destroy box3d's world first (it tears down the shapes that reference our
  // mesh/height-field blobs), then free the blobs we still own.
  b3DestroyWorld(b3LoadWorldId(world));
  b3d_owned_free_world(world);
}

void b3d_world_set_gravity(uint32_t world, float x, float y, float z) {
  b3World_SetGravity(b3LoadWorldId(world), (b3Vec3){x, y, z});
}

void b3d_world_step(uint32_t world, float dt, int32_t sub_steps) {
  b3World_Step(b3LoadWorldId(world), dt, sub_steps);
}

// --- Bodies ----------------------------------------------------------------

uint64_t b3d_body_create(uint32_t world, int32_t kind, float px, float py,
                         float pz, float qx, float qy, float qz, float qw) {
  b3BodyDef def = b3DefaultBodyDef();
  def.type = (b3BodyType)kind;
  def.position = (b3Pos){px, py, pz};
  def.rotation = (b3Quat){{qx, qy, qz}, qw};
  b3BodyId body = b3CreateBody(b3LoadWorldId(world), &def);
  return b3StoreBodyId(body);
}

void b3d_body_destroy(uint64_t body) { b3DestroyBody(b3LoadBodyId(body)); }

void b3d_body_get_position(uint64_t body, float *out3) {
  b3Pos p = b3Body_GetPosition(b3LoadBodyId(body));
  out3[0] = (float)p.x;
  out3[1] = (float)p.y;
  out3[2] = (float)p.z;
}

void b3d_body_get_rotation(uint64_t body, float *out4) {
  b3Quat q = b3Body_GetRotation(b3LoadBodyId(body));
  out4[0] = q.v.x;
  out4[1] = q.v.y;
  out4[2] = q.v.z;
  out4[3] = q.s;
}

void b3d_body_get_transform(uint64_t body, float *out7) {
  b3WorldTransform t = b3Body_GetTransform(b3LoadBodyId(body));
  out7[0] = (float)t.p.x;
  out7[1] = (float)t.p.y;
  out7[2] = (float)t.p.z;
  out7[3] = t.q.v.x;
  out7[4] = t.q.v.y;
  out7[5] = t.q.v.z;
  out7[6] = t.q.s;
}

void b3d_body_set_transform(uint64_t body, float px, float py, float pz,
                            float qx, float qy, float qz, float qw) {
  b3Body_SetTransform(b3LoadBodyId(body), (b3Pos){px, py, pz},
                      (b3Quat){{qx, qy, qz}, qw});
}

void b3d_body_get_linear_velocity(uint64_t body, float *out3) {
  b3Vec3 v = b3Body_GetLinearVelocity(b3LoadBodyId(body));
  out3[0] = v.x;
  out3[1] = v.y;
  out3[2] = v.z;
}

void b3d_body_set_linear_velocity(uint64_t body, float x, float y, float z) {
  b3Body_SetLinearVelocity(b3LoadBodyId(body), (b3Vec3){x, y, z});
}

void b3d_body_get_angular_velocity(uint64_t body, float *out3) {
  b3Vec3 v = b3Body_GetAngularVelocity(b3LoadBodyId(body));
  out3[0] = v.x;
  out3[1] = v.y;
  out3[2] = v.z;
}

void b3d_body_set_angular_velocity(uint64_t body, float x, float y, float z) {
  b3Body_SetAngularVelocity(b3LoadBodyId(body), (b3Vec3){x, y, z});
}

void b3d_body_set_linear_damping(uint64_t body, float damping) {
  b3Body_SetLinearDamping(b3LoadBodyId(body), damping);
}

void b3d_body_set_angular_damping(uint64_t body, float damping) {
  b3Body_SetAngularDamping(b3LoadBodyId(body), damping);
}

void b3d_body_set_gravity_scale(uint64_t body, float scale) {
  b3Body_SetGravityScale(b3LoadBodyId(body), scale);
}

int32_t b3d_body_get_kind(uint64_t body) {
  return (int32_t)b3Body_GetType(b3LoadBodyId(body));
}

void b3d_body_set_kind(uint64_t body, int32_t kind) {
  b3Body_SetType(b3LoadBodyId(body), (b3BodyType)kind);
}

float b3d_body_get_mass(uint64_t body) {
  return b3Body_GetMass(b3LoadBodyId(body));
}

void b3d_body_apply_mass_from_shapes(uint64_t body) {
  b3Body_ApplyMassFromShapes(b3LoadBodyId(body));
}

void b3d_body_set_motion_locks(uint64_t body, int32_t lx, int32_t ly,
                               int32_t lz, int32_t ax, int32_t ay, int32_t az) {
  b3MotionLocks locks = {lx != 0, ly != 0, lz != 0, ax != 0, ay != 0, az != 0};
  b3Body_SetMotionLocks(b3LoadBodyId(body), locks);
}

void b3d_body_set_bullet(uint64_t body, int32_t enabled) {
  b3Body_SetBullet(b3LoadBodyId(body), enabled != 0);
}

int32_t b3d_body_is_awake(uint64_t body) {
  return b3Body_IsAwake(b3LoadBodyId(body)) ? 1 : 0;
}

void b3d_body_set_awake(uint64_t body, int32_t awake) {
  b3Body_SetAwake(b3LoadBodyId(body), awake != 0);
}

void b3d_body_enable_sleep(uint64_t body, int32_t enabled) {
  b3Body_EnableSleep(b3LoadBodyId(body), enabled != 0);
}

void b3d_body_apply_force(uint64_t body, float fx, float fy, float fz,
                          int32_t has_point, float px, float py, float pz,
                          int32_t wake) {
  b3BodyId id = b3LoadBodyId(body);
  b3Vec3 force = {fx, fy, fz};
  if (has_point) {
    b3Body_ApplyForce(id, force, (b3Pos){px, py, pz}, wake != 0);
  } else {
    b3Body_ApplyForceToCenter(id, force, wake != 0);
  }
}

void b3d_body_apply_impulse(uint64_t body, float ix, float iy, float iz,
                            int32_t has_point, float px, float py, float pz,
                            int32_t wake) {
  b3BodyId id = b3LoadBodyId(body);
  b3Vec3 impulse = {ix, iy, iz};
  if (has_point) {
    b3Body_ApplyLinearImpulse(id, impulse, (b3Pos){px, py, pz}, wake != 0);
  } else {
    b3Body_ApplyLinearImpulseToCenter(id, impulse, wake != 0);
  }
}

void b3d_body_apply_torque(uint64_t body, float x, float y, float z,
                           int32_t wake) {
  b3Body_ApplyTorque(b3LoadBodyId(body), (b3Vec3){x, y, z}, wake != 0);
}

void b3d_body_apply_angular_impulse(uint64_t body, float x, float y, float z,
                                    int32_t wake) {
  b3Body_ApplyAngularImpulse(b3LoadBodyId(body), (b3Vec3){x, y, z}, wake != 0);
}

// --- Shapes ----------------------------------------------------------------

// Seeds a shape def with the exposed material triple and sensor flag.
static b3ShapeDef b3d_shape_def(float friction, float restitution,
                                float density, int32_t is_sensor) {
  b3ShapeDef def = b3DefaultShapeDef();
  def.baseMaterial.friction = friction;
  def.baseMaterial.restitution = restitution;
  def.density = density;
  def.isSensor = is_sensor != 0;
  return def;
}

uint64_t b3d_shape_sphere(uint64_t body, float cx, float cy, float cz,
                          float radius, float friction, float restitution,
                          float density, int32_t is_sensor) {
  b3ShapeDef def = b3d_shape_def(friction, restitution, density, is_sensor);
  b3Sphere sphere = {{cx, cy, cz}, radius};
  b3ShapeId shape = b3CreateSphereShape(b3LoadBodyId(body), &def, &sphere);
  return b3StoreShapeId(shape);
}

uint64_t b3d_shape_box(uint64_t body, float hx, float hy, float hz,
                       float friction, float restitution, float density,
                       int32_t is_sensor) {
  b3ShapeDef def = b3d_shape_def(friction, restitution, density, is_sensor);
  // b3BoxHull embeds a b3HullData whose array offsets index into the box
  // arrays that follow it, so &box.base is a complete hull for as long as
  // box is on the stack. box3d deep-copies it during shape creation.
  b3BoxHull box = b3MakeBoxHull(hx, hy, hz);
  b3ShapeId shape = b3CreateHullShape(b3LoadBodyId(body), &def, &box.base);
  return b3StoreShapeId(shape);
}

uint64_t b3d_shape_capsule(uint64_t body, float ax, float ay, float az,
                           float bx, float by, float bz, float radius,
                           float friction, float restitution, float density,
                           int32_t is_sensor) {
  b3ShapeDef def = b3d_shape_def(friction, restitution, density, is_sensor);
  b3Capsule capsule = {{ax, ay, az}, {bx, by, bz}, radius};
  b3ShapeId shape = b3CreateCapsuleShape(b3LoadBodyId(body), &def, &capsule);
  return b3StoreShapeId(shape);
}

uint64_t b3d_shape_cylinder(uint64_t body, float half_height, float radius,
                            int32_t sides, float friction, float restitution,
                            float density, int32_t is_sensor) {
  b3ShapeDef def = b3d_shape_def(friction, restitution, density, is_sensor);
  // b3CreateCylinder builds the hull from y = yOffset up by height; offset
  // by -half_height to center it on the body origin. box3d copies the hull
  // into its own database during shape creation, so we free ours after.
  b3HullData *hull = b3CreateCylinder(2.0f * half_height, radius, -half_height,
                                      sides);
  if (hull == 0) {
    return 0;
  }
  b3ShapeId shape = b3CreateHullShape(b3LoadBodyId(body), &def, hull);
  b3DestroyHull(hull);
  return b3StoreShapeId(shape);
}

uint64_t b3d_shape_convex_hull(uint64_t body, const float *points,
                               int32_t point_count, float friction,
                               float restitution, float density,
                               int32_t is_sensor) {
  b3ShapeDef def = b3d_shape_def(friction, restitution, density, is_sensor);
  // The packed xyz floats are laid out exactly like an array of b3Vec3.
  b3HullData *hull =
      b3CreateHull((const b3Vec3 *)points, point_count, point_count);
  if (hull == 0) {
    return 0;
  }
  b3ShapeId shape = b3CreateHullShape(b3LoadBodyId(body), &def, hull);
  b3DestroyHull(hull);
  return b3StoreShapeId(shape);
}

// --- Shape mutation --------------------------------------------------------

void b3d_shape_set_material(uint64_t shape, float friction, float restitution,
                            float density) {
  b3ShapeId id = b3LoadShapeId(shape);
  b3Shape_SetFriction(id, friction);
  b3Shape_SetRestitution(id, restitution);
  b3Shape_SetDensity(id, density, true);
}

void b3d_shape_set_filter(uint64_t shape, uint64_t category, uint64_t mask,
                          int32_t group) {
  b3Filter filter = {category, mask, group};
  b3Shape_SetFilter(b3LoadShapeId(shape), filter, true);
}

void b3d_shape_enable_sensor_events(uint64_t shape, int32_t enabled) {
  b3Shape_EnableSensorEvents(b3LoadShapeId(shape), enabled != 0);
}

void b3d_shape_enable_contact_events(uint64_t shape, int32_t enabled) {
  b3Shape_EnableContactEvents(b3LoadShapeId(shape), enabled != 0);
}

void b3d_shape_destroy(uint64_t shape, int32_t update_body_mass) {
  b3DestroyShape(b3LoadShapeId(shape), update_body_mass != 0);
  b3d_owned_remove_shape(shape);
}

uint64_t b3d_shape_trimesh(uint64_t body, const float *vertices,
                           int32_t vertex_count, const int32_t *indices,
                           int32_t triangle_count, float friction,
                           float restitution, float density,
                           int32_t is_sensor) {
  b3ShapeDef def = b3d_shape_def(friction, restitution, density, is_sensor);
  b3MeshDef mesh_def = {0};
  // The packed xyz floats are laid out exactly like an array of b3Vec3.
  mesh_def.vertices = (b3Vec3 *)vertices;
  mesh_def.indices = (int32_t *)indices;
  mesh_def.vertexCount = vertex_count;
  mesh_def.triangleCount = triangle_count;
  b3MeshData *mesh = b3CreateMesh(&mesh_def, 0, 0);
  if (mesh == 0) {
    return 0;
  }
  b3ShapeId shape = b3CreateMeshShape(b3LoadBodyId(body), &def, mesh,
                                      (b3Vec3){1.0f, 1.0f, 1.0f});
  if (shape.index1 == 0) {
    b3DestroyMesh(mesh);
    return 0;
  }
  uint64_t handle = b3StoreShapeId(shape);
  b3d_owned_add(handle, b3d_owned_mesh, mesh);
  return handle;
}

// --- Joints ----------------------------------------------------------------

static b3Transform b3d_frame(const float *f) {
  return (b3Transform){{f[0], f[1], f[2]}, {{f[3], f[4], f[5]}, f[6]}};
}

// Fills the common joint fields shared by every joint def.
static void b3d_fill_joint_base(b3JointDef *base, uint64_t body_a,
                                uint64_t body_b, const float *frame_a,
                                const float *frame_b, int32_t collide) {
  base->bodyIdA = b3LoadBodyId(body_a);
  base->bodyIdB = b3LoadBodyId(body_b);
  base->localFrameA = b3d_frame(frame_a);
  base->localFrameB = b3d_frame(frame_b);
  base->collideConnected = collide != 0;
}

uint64_t b3d_joint_weld(uint32_t world, uint64_t body_a, uint64_t body_b,
                        const float *frame_a, const float *frame_b,
                        int32_t collide, float linear_hertz,
                        float angular_hertz, float linear_damping,
                        float angular_damping) {
  b3WeldJointDef def = b3DefaultWeldJointDef();
  b3d_fill_joint_base(&def.base, body_a, body_b, frame_a, frame_b, collide);
  def.linearHertz = linear_hertz;
  def.angularHertz = angular_hertz;
  def.linearDampingRatio = linear_damping;
  def.angularDampingRatio = angular_damping;
  b3JointId joint = b3CreateWeldJoint(b3LoadWorldId(world), &def);
  return b3StoreJointId(joint);
}

uint64_t b3d_joint_revolute(uint32_t world, uint64_t body_a, uint64_t body_b,
                            const float *frame_a, const float *frame_b,
                            int32_t collide, int32_t enable_limit, float lower,
                            float upper, int32_t enable_motor, float motor_speed,
                            float max_motor_torque) {
  b3RevoluteJointDef def = b3DefaultRevoluteJointDef();
  b3d_fill_joint_base(&def.base, body_a, body_b, frame_a, frame_b, collide);
  def.enableLimit = enable_limit != 0;
  def.lowerAngle = lower;
  def.upperAngle = upper;
  def.enableMotor = enable_motor != 0;
  def.motorSpeed = motor_speed;
  def.maxMotorTorque = max_motor_torque;
  b3JointId joint = b3CreateRevoluteJoint(b3LoadWorldId(world), &def);
  return b3StoreJointId(joint);
}

uint64_t b3d_joint_prismatic(uint32_t world, uint64_t body_a, uint64_t body_b,
                             const float *frame_a, const float *frame_b,
                             int32_t collide, int32_t enable_limit, float lower,
                             float upper, int32_t enable_motor,
                             float motor_speed, float max_motor_force) {
  b3PrismaticJointDef def = b3DefaultPrismaticJointDef();
  b3d_fill_joint_base(&def.base, body_a, body_b, frame_a, frame_b, collide);
  def.enableLimit = enable_limit != 0;
  def.lowerTranslation = lower;
  def.upperTranslation = upper;
  def.enableMotor = enable_motor != 0;
  def.motorSpeed = motor_speed;
  def.maxMotorForce = max_motor_force;
  b3JointId joint = b3CreatePrismaticJoint(b3LoadWorldId(world), &def);
  return b3StoreJointId(joint);
}

uint64_t b3d_joint_spherical(uint32_t world, uint64_t body_a, uint64_t body_b,
                             const float *frame_a, const float *frame_b,
                             int32_t collide, int32_t enable_cone,
                             float cone_angle, int32_t enable_twist,
                             float lower_twist, float upper_twist,
                             int32_t enable_motor, float max_motor_torque) {
  b3SphericalJointDef def = b3DefaultSphericalJointDef();
  b3d_fill_joint_base(&def.base, body_a, body_b, frame_a, frame_b, collide);
  def.enableConeLimit = enable_cone != 0;
  def.coneAngle = cone_angle;
  def.enableTwistLimit = enable_twist != 0;
  def.lowerTwistAngle = lower_twist;
  def.upperTwistAngle = upper_twist;
  def.enableMotor = enable_motor != 0;
  def.maxMotorTorque = max_motor_torque;
  b3JointId joint = b3CreateSphericalJoint(b3LoadWorldId(world), &def);
  return b3StoreJointId(joint);
}

uint64_t b3d_joint_distance(uint32_t world, uint64_t body_a, uint64_t body_b,
                            const float *frame_a, const float *frame_b,
                            int32_t collide, float length, int32_t enable_limit,
                            float min_length, float max_length,
                            int32_t enable_spring, float hertz,
                            float damping_ratio, int32_t enable_motor,
                            float motor_speed, float max_motor_force) {
  b3DistanceJointDef def = b3DefaultDistanceJointDef();
  b3d_fill_joint_base(&def.base, body_a, body_b, frame_a, frame_b, collide);
  def.length = length;
  def.enableLimit = enable_limit != 0;
  def.minLength = min_length;
  def.maxLength = max_length;
  def.enableSpring = enable_spring != 0;
  def.hertz = hertz;
  def.dampingRatio = damping_ratio;
  def.enableMotor = enable_motor != 0;
  def.motorSpeed = motor_speed;
  def.maxMotorForce = max_motor_force;
  b3JointId joint = b3CreateDistanceJoint(b3LoadWorldId(world), &def);
  return b3StoreJointId(joint);
}

void b3d_joint_destroy(uint64_t joint, int32_t wake_bodies) {
  b3DestroyJoint(b3LoadJointId(joint), wake_bodies != 0);
}

uint64_t b3d_shape_height_field(uint64_t body, int32_t count_x, int32_t count_z,
                                const float *heights, float scale_x,
                                float scale_y, float scale_z, float friction,
                                float restitution, float density,
                                int32_t is_sensor) {
  b3ShapeDef def = b3d_shape_def(friction, restitution, density, is_sensor);

  // Quantization needs a non-empty height range.
  int32_t count = count_x * count_z;
  float minimum = heights[0];
  float maximum = heights[0];
  for (int32_t i = 1; i < count; i++) {
    if (heights[i] < minimum) {
      minimum = heights[i];
    }
    if (heights[i] > maximum) {
      maximum = heights[i];
    }
  }
  if (maximum <= minimum) {
    maximum = minimum + 1.0f;
  }

  b3HeightFieldDef hf_def = {0};
  hf_def.heights = (float *)heights;
  hf_def.scale = (b3Vec3){scale_x, scale_y, scale_z};
  hf_def.countX = count_x;
  hf_def.countZ = count_z;
  hf_def.globalMinimumHeight = minimum;
  hf_def.globalMaximumHeight = maximum;
  b3HeightFieldData *field = b3CreateHeightField(&hf_def);
  if (field == 0) {
    return 0;
  }
  b3ShapeId shape = b3CreateHeightFieldShape(b3LoadBodyId(body), &def, field);
  if (shape.index1 == 0) {
    b3DestroyHeightField(field);
    return 0;
  }
  uint64_t handle = b3StoreShapeId(shape);
  b3d_owned_add(handle, b3d_owned_height_field, field);
  return handle;
}
