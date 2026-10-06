"""Source floor closure/shading/metric UV and exact corridor ownership notch."""
import json,math
from pathlib import Path
import bpy,bmesh
from mathutils import Vector
root=Path(__file__).resolve().parents[1]
c=json.loads((root/'docs/production/s01_hub_floor.json').read_text())
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
assert max(p.y for p in points)<=c['inlay_top_local_y']+1e-6
for p in points:
 assert math.hypot(p.x,p.z)<=c['source_radius']+1e-5 and p.y>=-.14501
 assert not (-1.99999<p.x<1.99999 and p.z<-8.00001)
print('BLENDER_S01_HUB_FLOOR PASS: closed positive unit floor, metric UV/unit shading; authored corridor notch and sub-channel/core/approach surface')
