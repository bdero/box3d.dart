// Implementation of the flat C ABI declared in box3d_shim.h.
//
// Every entry point loads the packed handle back into a box3d id, calls
// box3d, and writes any by-value result through an out-pointer. Defs are
// always seeded from box3d's b3Default*Def() so the internalValue guards
// and callback fields are correct; the shim only overrides the fields it
// exposes.

#include "box3d_shim.h"

#include "box3d/box3d.h"
#include "box3d/collision.h"
#include "box3d/id.h"
#include "box3d/types.h"

int32_t b3d_is_double_precision(void) { return b3IsDoublePrecision() ? 1 : 0; }

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

void b3d_world_destroy(uint32_t world) { b3DestroyWorld(b3LoadWorldId(world)); }

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

void b3d_body_get_linear_velocity(uint64_t body, float *out3) {
  b3Vec3 v = b3Body_GetLinearVelocity(b3LoadBodyId(body));
  out3[0] = v.x;
  out3[1] = v.y;
  out3[2] = v.z;
}

void b3d_body_set_linear_velocity(uint64_t body, float x, float y, float z) {
  b3Body_SetLinearVelocity(b3LoadBodyId(body), (b3Vec3){x, y, z});
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
