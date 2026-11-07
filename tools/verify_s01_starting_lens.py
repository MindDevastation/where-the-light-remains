"""Reopen both original props and check actual geometry, shading and seating rays."""
import json
from pathlib import Path
import bpy
import bmesh
from mathutils import Vector
from mathutils.bvhtree import BVHTree

root = Path(__file__).resolve().parents[1]
c = json.loads((root / 'docs/production/s01_starting_lens.json').read_text())
assert bpy.context.scene.unit_settings.system == 'METRIC'
assert bpy.context.scene.unit_settings.scale_length == 1
assert len(bpy.context.scene.objects) == 2
for p in c['parts']:
    obj = bpy.context.scene.objects[p['stem']]
    assert obj.type == 'MESH' and not obj.modifiers and not obj.animation_data
    assert obj.location.length < 1e-6 and Vector(obj.rotation_euler).length < 1e-6
    assert (obj.scale-Vector((1,1,1))).length < 1e-6
    assert [m.name for m in obj.data.materials] == [Path(c['materials'][f]).stem for f in p['materials']]
    assert all(m.use_backface_culling for m in obj.data.materials)
    co = [(v.co.x,v.co.z,-v.co.y) for v in obj.data.vertices]
    assert all(abs(v[i]) < c['target_size'][i]/2 for v in co for i in range(3))
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    assert all(e.is_manifold and len(e.link_faces)==2 for e in bm.edges)
    assert all(f.calc_area()>1e-10 for f in bm.faces) and bm.calc_volume(signed=True)>0
    bm.free()
    obj.data.calc_loop_triangles()
    assert len(obj.data.loop_triangles)<=p['triangle_ceiling']
    assert len(obj.data.uv_layers)==1
    obj.data.calc_tangents(uvmap='UVMap')
    uv = obj.data.uv_layers.active.data
    for tri in obj.data.loop_triangles:
        a,b,d = [uv[i].uv for i in tri.loops]
        area = abs((b.x-a.x)*(d.y-a.y)-(b.y-a.y)*(d.x-a.x))/2
        assert abs(area/tri.area-1)<.004
    assert all(abs(l.normal.length-1)<1e-5 and abs(l.tangent.length-1)<1e-5
        and abs(l.normal.dot(l.tangent))<1e-5 for l in obj.data.loops)
    tree = BVHTree.FromPolygons([v.co for v in obj.data.vertices],
        [list(f.vertices) for f in obj.data.polygons],all_triangles=True)
    # Front is Godot +Z = Blender -Y. The empty socket must have a real open bore.
    hit = tree.ray_cast(Vector((0,-.14,0)),Vector((0,1,0)),.3)
    if p['id']=='socket':
        assert hit[0] is None, 'Empty center is open geometry'
        for radius in [.183,.20]:
            hit = tree.ray_cast(Vector((radius,-.14,0)),Vector((0,1,0)),.3)
            assert hit[0] is not None, 'Actual socket ring catches seating rays'
    else:
        assert hit[0] is not None and obj.data.polygons[hit[2]].material_index==1
        hit = tree.ray_cast(Vector((.17,-.14,0)),Vector((0,1,0)),.3)
        assert hit[0] is not None and obj.data.polygons[hit[2]].material_index==0
print('BLENDER_S01_LENS PASS: two closed props; unit pivots/metric UVs; actual glass/rim rays and open socket bore')
