"""Reopen the editable rug and measure volume, shading and actual top rays."""
import json
from pathlib import Path
import bpy
import bmesh
from mathutils import Vector
from mathutils.bvhtree import BVHTree

root = Path(__file__).resolve().parents[1]
c = json.loads((root / 'docs/production/archive_rug.json').read_text())
scene = bpy.context.scene
assert scene.unit_settings.system == 'METRIC' and scene.unit_settings.scale_length == 1
assert len(scene.objects) == 1
obj = scene.objects[c['stem']]
assert obj.type == 'MESH' and not obj.modifiers and not obj.animation_data
assert obj.location.length < 1e-6 and Vector(obj.rotation_euler).length < 1e-6
assert (obj.scale - Vector((1,1,1))).length < 1e-6
assert [m.name for m in obj.data.materials] == [Path(c['materials'][f]).stem for f in c['material_order']]
assert all(m.use_backface_culling for m in obj.data.materials)
coordinates = [(v.co.x, v.co.z, -v.co.y) for v in obj.data.vertices]
low = [min(v[i] for v in coordinates) for i in range(3)]
high = [max(v[i] for v in coordinates) for i in range(3)]
assert all(abs(low[i]-c['bounds_min'][i]) < 1e-5 and abs(high[i]-c['bounds_max'][i]) < 1e-5 for i in range(3))
assert all(abs(low[i]+high[i]) < 1e-5 for i in range(3)), 'Centered pivot'
bm = bmesh.new()
bm.from_mesh(obj.data)
assert all(e.is_manifold and len(e.link_faces) == 2 for e in bm.edges)
assert all(f.calc_area() > 1e-10 for f in bm.faces)
volume = bm.calc_volume(signed=True)
assert 0 < volume <= 2.6*4*.008
bm.free()
obj.data.calc_loop_triangles()
assert len(obj.data.loop_triangles) == 44
assert len(obj.data.uv_layers) == 1
obj.data.calc_tangents(uvmap='UVMap')
uv = obj.data.uv_layers.active.data
for tri in obj.data.loop_triangles:
    a,b,d = [uv[i].uv for i in tri.loops]
    area = abs((b.x-a.x)*(d.y-a.y)-(b.y-a.y)*(d.x-a.x))/2
    assert abs(area/tri.area-1) < .003
assert all(abs(l.normal.length-1) < 1e-5 and abs(l.tangent.length-1) < 1e-5
           and abs(l.normal.dot(l.tangent)) < 1e-5 for l in obj.data.loops)
tree = BVHTree.FromPolygons([v.co for v in obj.data.vertices],
                          [list(f.vertices) for f in obj.data.polygons], all_triangles=True)
for x,z in [(0,0),(-1.25,0),(1.25,0),(0,-1.95),(0,1.95)]:
    hit = tree.ray_cast(Vector((x,-z,.1)), Vector((0,0,-1)), .2)
    assert hit[0] is not None and abs(hit[3]-.096) < 1e-5
    expected = 1 if (x,z) == (0,0) else 0
    assert obj.data.polygons[hit[2]].material_index == expected
print('BLENDER_RUG PASS: 44 triangles; two shared surfaces; closed volume', volume,
      '; centered pivot; metric UVs; unit shading; five actual top rays')
