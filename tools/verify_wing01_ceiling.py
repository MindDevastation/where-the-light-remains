"""Inspect reopened editable ceiling geometry independently of its generator."""
import json
from pathlib import Path
import bpy
import bmesh
from mathutils import Vector
from mathutils.bvhtree import BVHTree

root = Path(__file__).resolve().parents[1]
contract = json.loads((root/'docs/production/wing01_ceiling_sample.json').read_text())
scene = bpy.context.scene
assert scene.unit_settings.system == 'METRIC' and scene.unit_settings.scale_length == 1
assert len(scene.objects) == 3 and all(obj.type == 'MESH' for obj in scene.objects)
for part in contract['parts']:
    obj = scene.objects[part['stem']]
    assert obj.location.length < 1e-6 and Vector(obj.rotation_euler).length < 1e-6
    assert (obj.scale-Vector((1,1,1))).length < 1e-6
    assert not obj.modifiers and not obj.animation_data
    assert [m.name for m in obj.data.materials] == [Path(contract['materials'][f]).stem for f in part['materials']]
    assert all(m.use_backface_culling for m in obj.data.materials)
    coordinates = [(v.co.x,v.co.z,-v.co.y) for v in obj.data.vertices]
    low = [min(p[axis] for p in coordinates) for axis in range(3)]
    high = [max(p[axis] for p in coordinates) for axis in range(3)]
    assert all(low[i]>=part['bounds_min'][i]-1e-6 and high[i]<=part['bounds_max'][i]+1e-6 for i in range(3))
    assert abs(low[1])<1e-6
    if 'span_m' in part:
        assert abs(low[0]-part['bounds_min'][0])<1e-6 and abs(high[0]-part['bounds_max'][0])<1e-6
        assert high[1] > 5.60, 'Tall crown must approach the shared collar'
    else:
        assert all(abs(low[i]-part['bounds_min'][i])<1e-6 and abs(high[i]-part['bounds_max'][i])<1e-6 for i in range(3))
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    assert all(e.is_manifold and len(e.link_faces)==2 for e in bm.edges)
    assert all(f.calc_area()>1e-10 for f in bm.faces)
    assert bm.calc_volume(signed=True)>0
    bm.free()
    obj.data.calc_loop_triangles()
    count = len(obj.data.loop_triangles)
    assert count <= part['triangle_ceiling']
    assert len(obj.data.uv_layers)==1
    obj.data.calc_tangents(uvmap='UVMap')
    uv = obj.data.uv_layers.active.data
    for tri in obj.data.loop_triangles:
        a,b,c = [uv[i].uv for i in tri.loops]
        area = abs((b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x))/2
        assert abs(area/tri.area-1)<.003
    assert all(abs(l.normal.length-1)<1e-5 and abs(l.tangent.length-1)<1e-5 and
               abs(l.normal.dot(l.tangent))<1e-5 for l in obj.data.loops)
    bvh = BVHTree.FromPolygons([v.co for v in obj.data.vertices],
                              [list(f.vertices) for f in obj.data.polygons],all_triangles=True)
    def upward(x,z):
        return bvh.ray_cast(Vector((x,-z,1.3)),Vector((0,0,1)),.25)[0]
    if part['id']=='transition':
        # Actual mesh coverage, not only the formula/metadata used to generate it.
        assert all(upward(x,z) is not None for x,z in [(4.9,5.9),(-4.9,5.9),
                    (4.9,-5.9),(-4.9,-5.9),(4.8,3),(-4.8,-3),(3,5.8),(-3,-5.8)])
        assert upward(0,0) is None, 'Corner infill must not become a low central ceiling'
        iron = part['materials'].index('iron')
        belt_planes = {round(f.center.z,5) for f in obj.data.polygons
                       if f.material_index==iron and abs(f.normal.z)>.99 and f.center.z<2}
        assert belt_planes == {1.37,1.49}, belt_planes
        assert 1.44 not in belt_planes, 'Metal underside must clear the stone underside plane'
    print('BLENDER_CEILING_PART PASS:',part['id'],'triangles=',count,'surfaces=',len(obj.data.materials),
          'actual_bounds=',low,high,'closed topology; metric UVs; unit normals/tangents; identity pivot')
print('BLENDER_CEILING PASS: three reopened parts; two span variants; actual corner coverage and open central headroom')
