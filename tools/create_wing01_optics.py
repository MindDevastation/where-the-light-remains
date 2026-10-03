"""Original bounded optical carrier; refuses to overwrite source/exports.

blender --background --factory-startup --python-exit-code 1 --python
tools/create_wing01_optics.py -- /absolute/new/output-repository
Godot coordinates are converted once to Blender. Source joint translations
are deliberate; selected GLBs are exported around identity local pivots.
"""
from pathlib import Path
import hashlib
import json
import math
import sys

import bpy
import bmesh
from mathutils import Vector

root = Path(__file__).resolve().parents[1]
contract = json.loads((root / 'docs/production/wing01_optics_v1.json').read_text())
out = Path(sys.argv[sys.argv.index('--') + 1]).resolve()
source = out / contract['source']
exports = out / 'game/art/meshes/wing01'
targets = [source] + [exports / (p['stem'] + '.glb') for p in contract['parts']]
assert not any(p.exists() for p in targets), 'Use a new disposable output root'
source.parent.mkdir(parents=True, exist_ok=True)
exports.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
for c in list(bpy.data.collections):
    bpy.data.collections.remove(c)
scene = bpy.context.scene
scene.unit_settings.system = 'METRIC'
scene.unit_settings.scale_length = 1
scene['asset_brief'] = 'docs/production/WING01_OPTICS_SAMPLE.md; contract v1'
scene['source_recipe'] = 'tools/create_wing01_optics.py'
materials = {}
for family, color, metal, rough in (
    ('stone', (.64, .57, .44, 1), 0, .78),
    ('brass', (.36, .22, .055, 1), 1, .48),
    ('walnut', (.12, .045, .016, 1), 0, .65),
    ('iron', (.055, .062, .07, 1), 1, .7),
):
    name = Path(contract['materials'][family]).stem
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    m.use_backface_culling = True
    bsdf = m.node_tree.nodes.get('Principled BSDF')
    for key, value in [('Base Color', color), ('Metallic', metal), ('Roughness', rough)]:
        bsdf.inputs[key].default_value = value
    materials[family] = m


def convert(point):
    x, y, z = point
    return (x, -z, y)


class Geometry:
    def __init__(self):
        self.vertices, self.faces, self.slots = [], [], []

    def solid(self, vertices, faces, material):
        # Independent closed solids retain separate vertex sets at contacts.
        offset = len(self.vertices)
        self.vertices.extend(convert(p) for p in vertices)
        self.faces.extend([[i + offset for i in face] for face in faces])
        self.slots.extend([material] * len(faces))

    def loft(self, loops, material, caps=True):
        n = len(loops[0])
        faces = []
        for row in range(len(loops) - 1):
            for i in range(n):
                j = (i + 1) % n
                faces.append([row*n+i, row*n+j, (row+1)*n+j, (row+1)*n+i])
        if caps:
            faces.extend([list(reversed(range(n))), list(range((len(loops)-1)*n, len(loops)*n))])
        self.solid([p for loop in loops for p in loop], faces, material)

    def box(self, center, size, material, bevel=.015):
        x, y, z = center
        a, b, c = [v/2 for v in size]
        v = min(bevel, a/3, b/3, c/3)
        def rectangle(a, c, y):
            return [(x-a+v,y,z-c), (x+a-v,y,z-c), (x+a,y,z-c+v), (x+a,y,z+c-v),
                    (x+a-v,y,z+c), (x-a+v,y,z+c), (x-a,y,z+c-v), (x-a,y,z-c+v)]
        self.loft([rectangle(a-v,c-v,y-b), rectangle(a,c,y-b+v),
                   rectangle(a,c,y+b-v), rectangle(a-v,c-v,y+b)], material)

    def cylinder(self, center, radius, length, material, segments=16):
        x, y, z = center
        loops = [[(x+r*math.cos(2*math.pi*i/segments), y+r*math.sin(2*math.pi*i/segments), z+d)
                  for i in range(segments)] for r,d in
                 [(radius*.88,-length/2), (radius,-length/2+.008),
                  (radius,length/2-.008), (radius*.88,length/2)]]
        self.loft(loops, material)

    def ring(self, radius, width, depth, material, segments=80, center=(0,0,0)):
        # Eight-point radial/depth cross section; bevels are part of the solid.
        a, d, v = width/2, depth/2, min(.008,width/4,depth/4)
        profile = [(radius-a+v,-d),(radius+a-v,-d),(radius+a,-d+v),(radius+a,d-v),
                   (radius+a-v,d),(radius-a+v,d),(radius-a,d-v),(radius-a,-d+v)]
        x,y,z = center
        vertices = [(x+r*math.cos(2*math.pi*i/segments),y+r*math.sin(2*math.pi*i/segments),z+h)
                    for i in range(segments) for r,h in profile]
        faces = [[i*8+j, ((i+1)%segments)*8+j, ((i+1)%segments)*8+(j+1)%8,i*8+(j+1)%8]
                 for i in range(segments) for j in range(8)]
        self.solid(vertices, faces, material)

    def object(self, part):
        mesh = bpy.data.meshes.new(part['stem'])
        mesh.from_pydata(self.vertices, [], self.faces)
        for family in part['materials']:
            mesh.materials.append(materials[family])
        for polygon, family in zip(mesh.polygons, self.slots):
            polygon.material_index = part['materials'].index(family)
        bm = bmesh.new()
        bm.from_mesh(mesh)
        bmesh.ops.triangulate(bm, faces=list(bm.faces))
        bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
        assert all(e.is_manifold for e in bm.edges)
        bm.to_mesh(mesh)
        bm.free()
        mesh.update()
        uv = mesh.uv_layers.new(name='UVMap')
        up = Vector((0,0,1))
        for face in mesh.polygons:
            n = face.normal
            if abs(n.dot(up)) < .95:
                v = (up - n*n.dot(up)).normalized()
                u = v.cross(n).normalized()
            else:
                u = (Vector((1,0,0))-n*n.x).normalized()
                v = n.cross(u).normalized()
            for i in face.loop_indices:
                co = mesh.vertices[mesh.loops[i].vertex_index].co
                uv.data[i].uv = (co.dot(u),co.dot(v))
        mesh.calc_tangents(uvmap='UVMap')
        collection = bpy.data.collections.new(part['id'])
        scene.collection.children.link(collection)
        obj = bpy.data.objects.new(part['stem'],mesh)
        collection.objects.link(obj)
        obj.location = convert(part['joint'])
        obj['joint_godot_m'] = part['joint']
        obj['component'] = part['id']
        obj['source_translation'] = 'deliberate assembled joint; export local identity'
        return obj


objects = []
for part in contract['parts']:
    g = Geometry()
    if part['id'] == 'frame':
        # Stepped pedestal: chamfered stone silhouette, walnut inlay, brass lip.
        g.box((0,.10,0),(1.92,.20,.98),'stone',.04)
        g.box((0,.29,0),(1.72,.18,.84),'stone',.035)
        g.box((0,.45,0),(1.55,.14,.72),'stone',.025)
        g.box((0,.555,0),(1.52,.07,.70),'brass',.012)
        g.box((0,.615,.08),(1.45,.05,.50),'walnut',.012)
        for side in (-1,1):
            g.box((side*.96,1.26,.13),(.16,1.24,.24),'walnut')
            for height in (.72,1.20,1.80):
                g.box((side*.96,height,.13),(.19,.07,.27),'iron',.008)
                g.cylinder((side*.96,height,-.025),.034,.035,'brass',12)
            g.box((side*.96,.665,.13),(.26,.09,.32),'brass')
        # Rear supports and bearing: no extra circular optical ring.
        g.box((0,1.72,.20),(1.84,.085,.10),'iron',.01)
        g.box((0,1.18,.20),(.085,1.05,.10),'iron',.01)
        g.cylinder((0,1.72,.10),.10,.19,'brass',20)
        # Rear track shoes contact each annulus without a fourth ring.
        for radius in (.89,.70,.51):
            for side in (-1,1):
                g.box((side*radius,1.72,.091),(.075,.10,.12),'iron',.008)
        # Independent low focus housing, raised five-stop hardware.
        fx,fy,fz = contract['parts'][-1]['joint']
        g.box((fx,fy,fz+.14),(.56,.57,.14),'walnut',.025)
        for angle in contract['focus_test_degrees']:
            a = math.radians(angle)
            g.cylinder((fx+.254*math.cos(a),fy+.254*math.sin(a),fz-.025),.019,.026,'brass',12)
        g.cylinder((fx,fy,fz+.05),.075,.16,'iron',20)
    elif part['id'] == 'focus':
        g.ring(.19,.055,.045,'brass',40)
        g.cylinder((0,0,0),.048,.07,'iron',16)
        for angle in (0,120,240):
            a = math.radians(angle)
            # Three closed spokes join the hub to the rim.
            vertices = []
            for z in (-.016,.016):
                for r,w in [(.025,-.012),(.178,-.012),(.178,.012),(.025,.012)]:
                    vertices.append((r*math.cos(a)-w*math.sin(a),r*math.sin(a)+w*math.cos(a),z))
            g.solid(vertices,[[0,1,2,3],[4,7,6,5],[0,4,5,1],[1,5,6,2],[2,6,7,3],[3,7,4,0]],'brass')
        g.cylinder((.16,0,-.068),.032,.12,'walnut',16)
        g.cylinder((0,0,-.075),.033,.085,'walnut',16)
        g.box((.224,0,-.04),(.045,.023,.028),'brass',.004)
    else:
        g.ring(part['radius_m'],part['width_m'],.065,'brass',part['segments'])
        grip = part['grip']
        g.cylinder((grip[0],grip[1],-.05),.055,.045,'iron',16)
        g.cylinder(grip,.035,.11,'walnut',16)
        # Simple pointer fitting rotates with the grip, without invented glyphs.
        g.box((grip[0],grip[1],-.155),(.074,.045,.025),'brass',.005)
    objects.append(g.object(part))

assert bpy.ops.wm.save_as_mainfile(filepath=str(source)) == {'FINISHED'}
for part,obj in zip(contract['parts'],objects):
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    location = obj.location.copy()
    obj.location = (0,0,0)
    target = exports / (part['stem'] + '.glb')
    assert bpy.ops.export_scene.gltf(filepath=str(target),export_format='GLB',use_selection=True,
                                    export_animations=False,export_tangents=True) == {'FINISHED'}
    obj.location = location
    obj.data.calc_loop_triangles()
    assert len(obj.data.loop_triangles) <= part['triangle_ceiling']
    print('WING01_AUTHORED:',part['id'],'triangles=',len(obj.data.loop_triangles),'surfaces=',len(obj.data.materials))
manifest = [{'path':str(p.relative_to(out)),'bytes':p.stat().st_size,
             'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in targets]
evidence = out / 'docs/production/evidence/wing01_optics'
evidence.mkdir(parents=True,exist_ok=True)
(evidence/'payload_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('WING01_AUTHORING PASS: original five-part source; local identity exports; six payload hashes')
