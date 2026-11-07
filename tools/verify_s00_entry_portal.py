"""Reopen original sliding fitting; shading/closure and actual guide clearances."""
import json
import math
from pathlib import Path
import bpy
import bmesh
from mathutils import Vector
from mathutils.bvhtree import BVHTree

root = Path(__file__).resolve().parents[1]
c = json.loads((root/'docs/production/s00_entry_portal.json').read_text())
assert bpy.context.scene.unit_settings.system=='METRIC'
assert bpy.context.scene.unit_settings.scale_length==1
assert len(bpy.context.scene.objects)==2
trees = {}
for p in c['parts']:
    obj = bpy.context.scene.objects[p['stem']]
    assert obj.type=='MESH' and not obj.modifiers and not obj.animation_data
    joint = Vector((p['joint'][0],-p['joint'][2],p['joint'][1]))
    assert (obj.location-joint).length<1e-6 and Vector(obj.rotation_euler).length<1e-6
    assert (obj.scale-Vector((1,1,1))).length<1e-6
    assert [m.name for m in obj.data.materials]==[Path(c['materials'][f]).stem for f in p['materials']]
    assert all(m.use_backface_culling for m in obj.data.materials)
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
    trees[p['id']] = BVHTree.FromPolygons([obj.matrix_world@v.co for v in obj.data.vertices],
        [list(f.vertices) for f in obj.data.polygons],all_triangles=False)
for part in c['parts']:
    obj=bpy.context.scene.objects[part['stem']]
    points=[Vector((v.co.x,v.co.z,-v.co.y)) for v in obj.data.vertices]
    if part['id']=='facade':
        for p in points:assert all(abs(co)<=size/2+1e-6 for co,size in zip(p,c['facade_body_size']))
        assert min(p.y for p in points)>-2.4 and abs(min(p.z for p in points)+.175)<1e-6
    else:
        assert min(p.y for p in points)>=c['arch_min_y']
        assert max(p.z for p in points)<=c['arch_max_z']+1e-6
        assert c['leaf_rear_z']-(9+max(p.z for p in points))>=.115-1e-6
        for p in points:assert abs(p.x)<=2.09 and p.y<=5.93
print('BLENDER_S00_PORTAL PASS: two original closed parts; metric UV/unit shading; original wall containment, fixed lantern face and crown/leaf/player clearance')
