"""Inspect actual reopened source and GLBs, including independent retrieval.

Use absolute source and script paths; cwd/PWD must match the inspected repo.
"""
from pathlib import Path
import hashlib
import json
import struct

import bpy
import bmesh
from mathutils import Vector
from mathutils.bvhtree import BVHTree

root = Path(__file__).resolve().parents[1]
c = json.loads((root/'docs/production/wing01_optics_v1.json').read_text())
assert Path(bpy.data.filepath).resolve() == root/c['source'], bpy.data.filepath
assert bpy.context.scene.unit_settings.system == 'METRIC'
assert bpy.context.scene.unit_settings.scale_length == 1
assert len(bpy.context.scene.objects) == len(c['parts']) == 5
total = 0
for part in c['parts']:
    obj = bpy.context.scene.objects[part['stem']]
    assert obj.type == 'MESH' and obj.users_collection[0].name == part['id']
    x,y,z = part['joint']
    assert (obj.location-Vector((x,-z,y))).length < 1e-6
    assert obj.rotation_euler.to_matrix().is_identity
    assert (obj.scale-Vector((1,1,1))).length < 1e-6
    assert not obj.modifiers and not obj.animation_data
    mesh = obj.data
    assert len(mesh.uv_layers) == 1
    expected = [Path(c['materials'][family]).stem for family in part['materials']]
    assert [m.name for m in mesh.materials] == expected
    assert all(m.use_backface_culling for m in mesh.materials)
    mesh.calc_loop_triangles()
    triangles = len(mesh.loop_triangles)
    assert triangles <= part['triangle_ceiling']
    total += triangles
    bm = bmesh.new()
    bm.from_mesh(mesh)
    assert all(e.is_manifold for e in bm.edges)
    assert all(v.link_faces for v in bm.verts)
    assert all(f.calc_area() > 1e-10 for f in bm.faces)
    # Every disconnected authored solid must have outward winding.
    unseen = set(bm.faces)
    solids = 0
    while unseen:
        todo = [unseen.pop()]
        connected = set(todo)
        while todo:
            face = todo.pop()
            for edge in face.edges:
                for other in edge.link_faces:
                    if other in unseen:
                        unseen.remove(other); connected.add(other); todo.append(other)
        volume = 0
        for face in connected:
            a,b,d = [v.co for v in face.verts]
            volume += a.dot(b.cross(d))/6
        assert volume > 1e-9, (part['id'],volume)
        solids += 1
    bm.free()
    mesh.calc_tangents(uvmap='UVMap')
    uv = mesh.uv_layers.active.data
    for triangle in mesh.loop_triangles:
        a,b,d = [uv[i].uv for i in triangle.loops]
        area = abs((b.x-a.x)*(d.y-a.y)-(b.y-a.y)*(d.x-a.x))/2
        assert abs(area/triangle.area-1)<.003,part['id']
    for loop in mesh.loops:
        assert abs(loop.normal.length-1)<1e-5 and abs(loop.tangent.length-1)<1e-5
        assert abs(loop.normal.dot(loop.tangent))<1e-5
    if part['id'] in ['outer','middle','inner']:
        bvh = BVHTree.FromPolygons([v.co for v in mesh.vertices],
                                  [list(f.vertices) for f in mesh.polygons],all_triangles=True)
        # In Blender, optical front is +Y. Actual solid aperture/radial-band rays.
        assert bvh.ray_cast(Vector((0,1,0)),Vector((0,-1,0)),2)[0] is None
        for radius,hit in [(part['radius_m'],True),(part['radius_m']-.08,False),(part['radius_m']+.08,False)]:
            assert (bvh.ray_cast(Vector((radius,1,0)),Vector((0,-1,0)),2)[0] is not None)==hit
    if part['id'] == 'frame':
        import math
        bvh = BVHTree.FromPolygons([v.co for v in mesh.vertices],
                                  [list(f.vertices) for f in mesh.polygons],all_triangles=True)
        fx,fy,fz = c['parts'][-1]['joint']
        assert len(c['focus_test_degrees']) == 5
        for angle in c['focus_test_degrees']:
            for offset,depth in [(0,.598),(36,.49)]:
                a = math.radians(angle+offset)
                point = bvh.ray_cast(Vector((fx+.254*math.cos(a),1,fy+.254*math.sin(a))),Vector((0,-1,0)),2)[0]
                assert point is not None and abs(point.y-depth)<1e-5, (angle,offset,point)
        print('WING01_FOCUS_MARKERS PASS: five actual raised stop centers and five empty intervals, stored triangle rays')
    glb = (root/f'game/art/meshes/wing01/{part["stem"]}.glb').read_bytes()
    assert struct.unpack_from('<4sII',glb)==(b'glTF',2,len(glb))
    size,kind = struct.unpack_from('<II',glb,12)
    assert kind == 0x4e4f534a
    doc = json.loads(glb[20:20+size])
    assert len(doc['meshes'])==len(doc['nodes'])==1 and not doc.get('animations')
    node = doc['nodes'][0]
    assert node.get('translation',[0,0,0])==[0,0,0]
    assert node.get('rotation',[0,0,0,1])==[0,0,0,1]
    assert node.get('scale',[1,1,1])==[1,1,1] and 'matrix' not in node
    assert {m['name'] for m in doc['materials']}==set(expected)
    assert sum(doc['accessors'][p['indices']]['count']//3 for p in doc['meshes'][0]['primitives'])==triangles
    for p in doc['meshes'][0]['primitives']:
        assert {'POSITION','NORMAL','TEXCOORD_0','TANGENT'}<=p['attributes'].keys()
    print('WING01_SOURCE_PART PASS:',part['id'],f'{triangles} triangles; {solids} outward closed solids; joint/identity export; metric UVs/normals/tangents')
for row in json.loads((root/'docs/production/evidence/wing01_optics/payload_manifest.json').read_text()):
    data = (root/row['path']).read_bytes()
    assert len(data)==row['bytes'] and hashlib.sha256(data).hexdigest()==row['sha256']
print('WING01_SOURCE PASS:',bpy.data.filepath,'; 5 parts;',total,'triangles; six payload hashes match')
