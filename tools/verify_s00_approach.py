"""Reopen original flat paving/guards; shading, closure and original containment."""
import json
import math
from pathlib import Path
import bpy
import bmesh
from mathutils import Vector
from mathutils.bvhtree import BVHTree

root = Path(__file__).resolve().parents[1]
c = json.loads((root/'docs/production/s00_approach.json').read_text())
assert bpy.context.scene.unit_settings.system=='METRIC'
assert bpy.context.scene.unit_settings.scale_length==1
assert len(bpy.context.scene.objects)==3
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
    size=part['body_size']
    for p in points:
        assert abs(p.x)<=size[0]/2+1e-6 and abs(p.z)<=size[2]/2+1e-6
        assert p.y>=-size[1]/2-1e-6
        assert p.y<= (c['max_floor_local_y'] if part['id']=='path' else size[1]/2)+1e-6
    if part['id']=='path':assert abs(max(p.y for p in points)-.156)<1e-6
    else:assert min(p.y for p in points)>-.6 and max(p.y for p in points)<.6
print('BLENDER_S00_APPROACH PASS: three closed original parts; metric UV/unit shading/pivots; original floor/guard envelopes and six-mm level paving')
