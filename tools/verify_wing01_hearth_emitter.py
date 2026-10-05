"""Independently reopen actual housing source and verify each closed solid and bowl cavity."""
import json
from pathlib import Path
import bpy
import bmesh
from mathutils import Vector
from mathutils.bvhtree import BVHTree

root = Path(__file__).resolve().parents[1]
c = json.loads((root / 'docs/production/wing01_hearth_emitter.json').read_text())
assert bpy.context.scene.unit_settings.system == 'METRIC' and bpy.context.scene.unit_settings.scale_length == 1
assert len(bpy.context.scene.objects) == 2
for part in c['parts']:
    obj = bpy.context.scene.objects[part['stem']]
    assert obj.type == 'MESH' and obj.users_collection[0].name == part['id']
    assert obj.location.length < 1e-6 and obj.rotation_euler.to_matrix().is_identity
    assert (obj.scale - Vector((1, 1, 1))).length < 1e-6
    assert not obj.modifiers and not obj.animation_data
    mesh = obj.data
    lo, hi = part['bounds_min'], part['bounds_max']
    for axis, (low, high) in enumerate(((lo[0], hi[0]), (-hi[2], -lo[2]), (lo[1], hi[1]))):
        values = [v.co[axis] for v in mesh.vertices]
        assert abs(min(values) - low) < 1e-6 and abs(max(values) - high) < 1e-6
    assert [m.name for m in mesh.materials] == [Path(c['materials'][f]).stem for f in part['materials']]
    assert all(m.use_backface_culling for m in mesh.materials)
    assert len(mesh.uv_layers) == 1
    mesh.calc_loop_triangles()
    assert len(mesh.loop_triangles) <= part['triangle_ceiling']
    bm = bmesh.new()
    bm.from_mesh(mesh)
    assert all(e.is_manifold and len(e.link_faces) == 2 for e in bm.edges)
    assert all(v.link_faces for v in bm.verts) and all(f.calc_area() > 1e-10 for f in bm.faces)
    unseen = set(bm.faces)
    solids = 0
    while unseen:
        todo = [unseen.pop()]
        connected = set(todo)
        while todo:
            face = todo.pop()
            for edge in face.edges:
                for other in edge.link_faces:
                    if other in unseen:
                        unseen.remove(other); connected.add(other); todo.append(other)
        volume = sum(f.verts[0].co.dot(f.verts[1].co.cross(f.verts[2].co)) / 6 for f in connected)
        assert volume > 1e-9, (part['id'], volume)
        solids += 1
    assert solids == (2 if part['id'] == 'hearth' else 3)
    bm.free()
    mesh.calc_tangents(uvmap='UVMap')
    uv = mesh.uv_layers.active.data
    for tri in mesh.loop_triangles:
        a, b, d = [uv[i].uv for i in tri.loops]
        area = abs((b.x-a.x)*(d.y-a.y)-(b.y-a.y)*(d.x-a.x)) / 2
        assert abs(area / tri.area - 1) < .003
    for loop in mesh.loops:
        assert abs(loop.normal.length-1) < 1e-5 and abs(loop.tangent.length-1) < 1e-5
        assert abs(loop.normal.dot(loop.tangent)) < 1e-5
    bvh = BVHTree.FromPolygons([v.co for v in mesh.vertices], [list(f.vertices) for f in mesh.polygons], all_triangles=True)
    if part['id'] == 'hearth':
        for x in (0, .1, -.1, .2, -.2):
            hit, normal, face, distance = bvh.ray_cast(Vector((x, 0, 1)), Vector((0, 0, -1)), 2)
            assert hit is not None and abs(hit.z + .06) < 1e-5 and normal.z > .9, (x, hit)
        hit = bvh.ray_cast(Vector((.55, 0, 1)), Vector((0, 0, -1)), 2)[0]
        assert hit is not None and hit.z > .30
    else:
        hit = bvh.ray_cast(Vector((0, 0, -1)), Vector((0, 0, 1)), 2)[0]
        assert hit is not None and abs(hit.z + .174) < 1e-5
    print('WING01_HOUSING_SOURCE PASS:', part['id'], 'triangles=', len(mesh.loop_triangles), 'surfaces=', len(mesh.materials), 'closed outward solids; meter UVs; normals/tangents; cavity/front rays')
print('WING01_HEARTH_EMITTER_SOURCE PASS: reopened actual two-part source')
