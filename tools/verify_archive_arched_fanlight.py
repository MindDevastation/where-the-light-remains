"""Reopen actual fanlight; metric shading, solids and full ghost-depth separation."""
import json
from pathlib import Path
import bpy,bmesh
from mathutils import Vector
root=Path(__file__).resolve().parents[1]
c=json.loads((root/'docs/production/archive_arched_fanlight.json').read_text())
assert bpy.context.scene.unit_settings.system=='METRIC' and bpy.context.scene.unit_settings.scale_length==1
assert len(bpy.context.scene.objects)==1
part=c['parts'][0];obj=bpy.context.scene.objects[part['stem']]
assert obj.type=='MESH' and not obj.modifiers and not obj.animation_data
assert obj.location.length<1e-6 and Vector(obj.rotation_euler).length<1e-6 and (obj.scale-Vector((1,1,1))).length<1e-6
assert [m.name for m in obj.data.materials]==[Path(c['materials'][f]).stem for f in part['materials']]
assert all(m.use_backface_culling for m in obj.data.materials)
bm=bmesh.new();bm.from_mesh(obj.data)
assert all(e.is_manifold and len(e.link_faces)==2 for e in bm.edges)
assert all(f.calc_area()>1e-10 for f in bm.faces) and bm.calc_volume(signed=True)>0
bm.free();obj.data.calc_loop_triangles();assert len(obj.data.loop_triangles)<=part['triangle_ceiling']
assert len(obj.data.uv_layers)==1;obj.data.calc_tangents(uvmap='UVMap');uv=obj.data.uv_layers.active.data
for tri in obj.data.loop_triangles:
 a,b,d=[uv[i].uv for i in tri.loops];area=abs((b.x-a.x)*(d.y-a.y)-(b.y-a.y)*(d.x-a.x))/2
 assert abs(area/tri.area-1)<.004
assert all(abs(l.normal.length-1)<1e-5 and abs(l.tangent.length-1)<1e-5 and abs(l.normal.dot(l.tangent))<1e-5 for l in obj.data.loops)
points=[Vector((v.co.x,v.co.z,-v.co.y)) for v in obj.data.vertices]
for p in points:
 assert all(lo-1e-6<=co<=hi+1e-6 for co,lo,hi in zip(p,c['min'],c['max']))
assert min(p.z for p in points)-c['gate_max_z']>.056
assert min(p.y for p in points)-c['gate_top']>.019 and c['lintel_bottom']-max(p.y for p in points)>.019
print('BLENDER_ARCHIVE_ARCHED_FANLIGHT PASS: closed positive unit fanlight; metric UV/unit shading/four shared surfaces; passage/lintel and entire opening-ghost depth clearance')
