"""Inspect the actual saved/retrieved third-size wall, independently of its builder."""
import json
from pathlib import Path
import bpy
import bmesh
from mathutils import Vector
from mathutils.bvhtree import BVHTree

root = Path(__file__).resolve().parents[1]
m = json.loads((root / 'docs/production/archive_wall_3m.json').read_text())
scene = bpy.context.scene
assert scene.unit_settings.system == 'METRIC' and scene.unit_settings.scale_length == 1
objects = list(scene.objects)
assert len(objects) == 1 and objects[0].type == 'MESH'
obj = objects[0]
assert obj.name == m['stem'] and obj.users_collection[0].name == m['id']
assert obj.location.length < 1e-6 and Vector(obj.rotation_euler).length < 1e-6
assert (obj.scale - Vector((1, 1, 1))).length < 1e-6
assert not obj.modifiers and not obj.animation_data
for axis, (low, high) in enumerate(((-1.5, 1.5), (-.2, .2), (0, 4))):
    coordinates = [v.co[axis] for v in obj.data.vertices]
    assert abs(min(coordinates) - low) < 1e-6 and abs(max(coordinates) - high) < 1e-6
assert [mat.name for mat in obj.data.materials] == ['m_observatory_stone']
assert obj.data.materials[0].use_backface_culling and len(obj.data.uv_layers) == 1
obj.data.calc_loop_triangles()
assert len(obj.data.loop_triangles) <= m['triangle_ceiling']
bm = bmesh.new()
bm.from_mesh(obj.data)
assert all(e.is_manifold and len(e.link_faces) == 2 for e in bm.edges)
assert all(v.link_faces for v in bm.verts) and all(f.calc_area() > 1e-10 for f in bm.faces)
assert bm.calc_volume(signed=True) > 0
bm.free()
obj.data.calc_tangents(uvmap='UVMap')
uv = obj.data.uv_layers.active.data
for tri in obj.data.loop_triangles:
    a, b, c = [uv[i].uv for i in tri.loops]
    area = abs((b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x)) / 2
    assert abs(area / tri.area - 1) < .001
for loop in obj.data.loops:
    assert abs(loop.normal.length - 1) < 1e-5 and abs(loop.tangent.length - 1) < 1e-5
    assert abs(loop.normal.dot(loop.tangent)) < 1e-5
bvh = BVHTree.FromPolygons([v.co for v in obj.data.vertices],
                           [list(f.vertices) for f in obj.data.polygons], all_triangles=True)
for x in (-1.4, -.75, 0, .75, 1.4):
    for height in (.1, 2, 3.9):
        for side in (-1, 1):
            point, normal, face, distance = bvh.ray_cast(Vector((x, side, height)), Vector((0, -side, 0)), 2)
            assert point is not None and normal.y * side > .9
print('BLENDER_WALL_3M PASS: reopened watertight source; two outward faces; metric UVs; normals/tangents; centered pivot and exact bounds; triangles=', len(obj.data.loop_triangles))
