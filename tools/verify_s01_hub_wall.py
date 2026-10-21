"""Reopen source and prove closed metric geometry stays in the original body."""
import json
from pathlib import Path
import bpy,bmesh
from mathutils import Vector
from mathutils.bvhtree import BVHTree
root=Path(__file__).resolve().parents[1]
c=json.loads((root/'docs/production/s01_hub_wall.json').read_text())
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
for p in points:assert all(abs(co)<=size/2+1e-6 for co,size in zip(p,c['body_size']))
assert abs(min(p.y for p in points)+2.392)<1e-6
tree=BVHTree.FromPolygons([v.co for v in obj.data.vertices],[list(p.vertices) for p in obj.data.polygons],all_triangles=True)
for side in [-1,1]:
 for x,y in [(2.56,0),(-2.56,0),(1.0,2.05),(1.0,-2.20)]:
  hit,normal,index,distance=tree.ray_cast(Vector((x,-side*.6,y)),Vector((0,side,0)))
  assert hit is not None and obj.data.polygons[index].material_index==part['materials'].index('walnut')
print('BLENDER_S01_HUB_WALL PASS: closed positive unit master, metric UV/normals/tangents; original eight wall-body containment/floor gap')
