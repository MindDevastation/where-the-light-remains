"""Reopen and independently inspect dome solids and actual roof ray coverage."""
import json
import math
from pathlib import Path
import bpy
import bmesh
from mathutils import Vector
from mathutils.bvhtree import BVHTree

root = Path(__file__).resolve().parents[1]
contract = json.loads((root/'docs/production/wing01_dome_coverage.json').read_text())
scene = bpy.context.scene
assert scene.unit_settings.system == 'METRIC' and scene.unit_settings.scale_length == 1
assert len(scene.objects) == 3 and all(o.type == 'MESH' for o in scene.objects)
trees = {}
for part in contract['parts']:
    obj = scene.objects[part['stem']]
    assert obj.location.length < 1e-6 and Vector(obj.rotation_euler).length < 1e-6
    assert (obj.scale-Vector((1,1,1))).length < 1e-6
    assert not obj.modifiers and not obj.animation_data
    assert [m.name for m in obj.data.materials] == [Path(contract['materials'][f]).stem for f in part['materials']]
    assert all(m.use_backface_culling for m in obj.data.materials)
    if part['id']=='glass':
        assert all(p.use_smooth for p in obj.data.polygons), 'Continuous curved glass shading'
    coordinates = [(v.co.x,v.co.z,-v.co.y) for v in obj.data.vertices]
    low = [min(p[i] for p in coordinates) for i in range(3)]
    high = [max(p[i] for p in coordinates) for i in range(3)]
    assert all(low[i]>=part['bounds_min'][i]-1e-5 and high[i]<=part['bounds_max'][i]+1e-5 for i in range(3)), (part['id'],low,high)
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    assert all(e.is_manifold and len(e.link_faces)==2 for e in bm.edges)
    assert all(f.calc_area()>1e-10 for f in bm.faces)
    volume = bm.calc_volume(signed=True)
    assert volume > 0
    bm.free()
    obj.data.calc_loop_triangles()
    count = len(obj.data.loop_triangles)
    assert count <= part['triangle_ceiling']
    assert len(obj.data.uv_layers) == 1
    obj.data.calc_tangents(uvmap='UVMap')
    uv = obj.data.uv_layers.active.data
    for tri in obj.data.loop_triangles:
        a,b,c = [uv[i].uv for i in tri.loops]
        area = abs((b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x))/2
        assert abs(area/tri.area-1)<.003
    assert all(abs(l.normal.length-1)<1e-5 and abs(l.tangent.length-1)<1e-5
               and abs(l.normal.dot(l.tangent))<1e-5 for l in obj.data.loops)
    trees[part['id']] = BVHTree.FromPolygons([v.co for v in obj.data.vertices],
        [list(f.vertices) for f in obj.data.polygons],all_triangles=True)
    print('BLENDER_DOME_PART PASS:',part['id'],'triangles=',count,'surfaces=',len(obj.data.materials),
          'bounds=',low,high,'closed_volume=',volume,'metric UVs; normals/tangents; identity pivot')

def convert(p):
    return Vector((p[0],-p[2],p[1]))

origin = convert((0,1.6,0))
directions = [(0,1,0)]
for height in (.25,.75,1.5):
    for i in range(16):
        phi = (i+.5)*2*math.pi/16
        directions.append((math.cos(phi),height,math.sin(phi)))
for direction in directions:
    ray = convert(direction).normalized()
    glass = trees['glass'].ray_cast(origin,ray,12)
    sky = trees['sky'].ray_cast(origin,ray,12)
    assert glass[0] is not None and sky[0] is not None, direction
    assert glass[3]+.12 < sky[3], (direction,glass[3],sky[3])
    assert glass[1].dot(ray)<0 and sky[1].dot(ray)<0, 'Interior faces must face the player'
print('BLENDER_DOME_ROOF_RAYS PASS:',len(directions),'actual covered interior rays; separate farther opaque sky')
for i in range(16):
    phi = i*2*math.pi/16
    radial = Vector((5*math.cos(phi),0,6*math.sin(phi)))
    t = .48
    center = radial*math.cos(t)+Vector((0,1.5+4*math.sin(t),0))
    normal = (radial.normalized()*(4*math.cos(t))+Vector((0,radial.length*math.sin(t),0))).normalized()
    hit = trees['frame'].ray_cast(convert(center-normal*.3),convert(normal),.5)
    assert (hit[0] is not None) == (i%4!=0), ('Intermediate member/cardinal exclusion',i)
print('BLENDER_DOME_MERIDIANS PASS: twelve actual members; four accepted cardinal locations excluded')
print('BLENDER_DOME PASS: three reopened parts; closed roof coverage; separate sky; unchanged cardinal rib scope')
