"""Reopen originals, measure shading/closure, assembled poses and cover gap."""
import json
import math
from pathlib import Path
import bpy
import bmesh
from mathutils import Vector
from mathutils.bvhtree import BVHTree

root = Path(__file__).resolve().parents[1]
c = json.loads((root/'docs/production/s01_hub_controls.json').read_text())
assert bpy.context.scene.unit_settings.system=='METRIC'
assert bpy.context.scene.unit_settings.scale_length==1
assert len(bpy.context.scene.objects)==4
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
    angles = [0,c['cover_open_degrees']] if p['id']=='panel_cover' else \
             [0,c['lever_pulled_degrees']] if p['id']=='lever_handle' else [0]
    for angle in angles:
        for v in obj.data.vertices:
            x,y,z = v.co.x,v.co.z,-v.co.y
            a = math.radians(angle)
            if p['id']=='panel_cover':
                x,z = math.cos(a)*x+math.sin(a)*z,-math.sin(a)*x+math.cos(a)*z
                x,y,z = x+c['cover_hinge'][0],y+c['cover_hinge'][1],z+c['cover_hinge'][2]
            elif p['id']=='lever_handle':
                y,z = math.cos(a)*y-math.sin(a)*z,math.sin(a)*y+math.cos(a)*z
                x,y,z = x+c['lever_pivot'][0],y+c['lever_pivot'][1],z+c['lever_pivot'][2]
            assert all(abs(co)<=size/2 for co,size in zip((x,y,z),c['target_size'])), (p['id'],angle,(x,y,z))
    trees[p['id']] = BVHTree.FromPolygons([obj.matrix_world@v.co for v in obj.data.vertices],
        [list(f.vertices) for f in obj.data.polygons],all_triangles=True)
# An actual source ray from the center gap finds static plate behind and cover
# in front. Preview panel is at X=-0.5; Godot +Z maps to Blender -Y.
origin = Vector((-.5,0,0))
rear = trees['panel_base'].ray_cast(origin,Vector((0,1,0)),.2)
front = trees['panel_cover'].ray_cast(origin,Vector((0,-1,0)),.2)
assert rear[0] is not None and front[0] is not None
assert abs(rear[3]+front[3]-.02)<1e-5
print('BLENDER_S01_CONTROLS PASS: four closed parts; assembled pivot poses inside targets; metric UVs/unit shading; actual 20mm center cover gap')
