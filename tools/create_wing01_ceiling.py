"""Original isolated roof study; never overwrite accepted source/exports.

blender --background --factory-startup --python-exit-code 1
  --python tools/create_wing01_ceiling.py -- /absolute/empty/output-root
"""
import ast
import hashlib
import json
import math
from pathlib import Path
import struct
import sys
import bpy
import bmesh
from mathutils import Vector

root = Path(__file__).resolve().parents[1]
contract = json.loads((root / 'docs/production/wing01_ceiling_sample.json').read_text())
out = Path(sys.argv[sys.argv.index('--') + 1]).resolve()
targets = [out / contract['source']] + [out / ('game/art/meshes/archive_kit/' + p['stem'] + '.glb') for p in contract['parts']]
assert not any(p.exists() for p in targets), 'Use an empty output root'
for target in targets:
    target.parent.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
for collection in list(bpy.data.collections):
    bpy.data.collections.remove(collection)
scene = bpy.context.scene
scene.unit_settings.system = 'METRIC'
scene.unit_settings.scale_length = 1
scene['asset_brief'] = 'docs/production/WING01_CEILING_SAMPLE.md'
scene['source_recipe'] = 'tools/create_wing01_ceiling.py'
materials = {}
for family, color, metal, rough in (
    ('stone', (.64, .57, .44, 1), 0, .78),
    ('iron', (.055, .062, .07, 1), 1, .7),
    ('brass', (.36, .22, .055, 1), 1, .48),
):
    m = bpy.data.materials.new(Path(contract['materials'][family]).stem)
    m.use_nodes = True
    m.use_backface_culling = True
    shader = m.node_tree.nodes.get('Principled BSDF')
    for key, value in [('Base Color', color), ('Metallic', metal), ('Roughness', rough)]:
        shader.inputs[key].default_value = value
    materials[family] = m
recipe = root / 'tools/create_wing01_optics.py'
definitions = [n for n in ast.parse(recipe.read_text()).body
               if isinstance(n, (ast.ClassDef, ast.FunctionDef)) and n.name in {'convert', 'Geometry'}]
assert len(definitions) == 2
exec(compile(ast.Module(body=definitions, type_ignores=[]), str(recipe), 'exec'), globals())


def rib(g, span):
    a = span / 2
    for sign in (-1, 1):
        g.box((sign*a, .09, 0), (.6, .18, .6), 'stone')
        g.box((sign*a, .69, 0), (.36, 1.02, .36), 'stone')
        g.box((sign*a, 1.32, 0), (.6, .36, .6), 'stone')
        g.box((sign*a, 1.24, 0), (.61-.02, .04, .59), 'brass', .006)
    # Four half-ribs end inside the separate shared collar, not one another.
    stop = math.acos(.25 / a)
    for side in (-1, 1):
        for family, width, depth, zoffset in [('iron', .24, .20, 0),
                                             ('brass', .022, .015, -.106),
                                             ('brass', .022, .015, .106)]:
            loops = []
            for i in range(contract['arc_segments_per_half'] + 1):
                t = stop * i / contract['arc_segments_per_half']
                x, y = side*a*math.cos(t), 1.5+4*math.sin(t)
                nx, ny = side*4*math.cos(t), a*math.sin(t)
                length = math.hypot(nx, ny)
                nx, ny = nx/length, ny/length
                w, d, bevel = width/2, depth/2, min(.012, width/5, depth/5)
                section = [(-w+bevel,-d), (w-bevel,-d), (w,-d+bevel), (w,d-bevel),
                           (w-bevel,d), (-w+bevel,d), (-w,d-bevel), (-w,-d+bevel)]
                if family == "brass":
                    section = [(-w,-d),(w,-d),(w,d),(-w,d)]
                loops.append([(x+u*nx, y+u*ny, zoffset+z) for u,z in section])
            g.loft(loops, family)


def transition(g):
    for x in (-5, 5):
        g.box((x,.75,0), (.4,1.5,12.4), 'stone')
    for z in (-6, 6):
        g.box((0,.75,z), (10,1.5,.4), 'stone')
    # Exact corner angles split outer rays at each rectangular corner.
    corner = math.atan2(6,5)
    angles = sorted(set([2*math.pi*i/64 for i in range(65)] +
                        [corner, math.pi-corner, math.pi+corner, 2*math.pi-corner]))
    boundary = []
    for angle in angles:
        x,z = 5*math.cos(angle),6*math.sin(angle)
        factor = min(5/abs(x) if abs(x)>1e-8 else float('inf'),
                     6/abs(z) if abs(z)>1e-8 else float('inf'))
        boundary.append(((x,z),(x*factor,z*factor)))
    for (inner_a,outer_a),(inner_b,outer_b) in zip(boundary,boundary[1:]):
        polygon = []
        for point in [inner_a,outer_a,outer_b,inner_b]:
            if not polygon or math.dist(point,polygon[-1])>1e-7:
                polygon.append(point)
        if math.dist(polygon[0],polygon[-1])<1e-7:
            polygon.pop()
        n = len(polygon)
        assert n >= 3
        vertices = [(x,y,z) for y in (1.44,1.5) for x,z in polygon]
        faces = [list(reversed(range(n))), list(range(n,2*n))]
        faces += [[i,(i+1)%n,(i+1)%n+n,i+n] for i in range(n)]
        g.solid(vertices,faces,'stone')
    # Spring belt follows the same polygonal ellipse; no transparent roof panes.
    loops = []
    for angle in angles:
        loops.append([((5+r)*math.cos(angle),1.43+y,(6+r)*math.sin(angle))
                      for r,y in [(-.065,-.06),(.065,-.06),(.065,.06),(-.065,.06)]])
    # Avoid duplicate coincident end caps on the closed belt.
    vertices = [p for loop in loops[:-1] for p in loop]
    count = len(loops)-1
    faces = [[i*4+j,((i+1)%count)*4+j,((i+1)%count)*4+(j+1)%4,i*4+(j+1)%4]
             for i in range(count) for j in range(4)]
    g.solid(vertices,faces,'iron')
    g.box((0,5.5,0),(.6,.28,.6),'iron',.018)
    g.box((0,5.52,0),(.62,.035,.62),'brass',.006)


objects = []
measurements = []
for part in contract['parts']:
    geometry = Geometry()
    if 'span_m' in part:
        rib(geometry,part['span_m'])
    else:
        transition(geometry)
    obj = geometry.object(part)
    obj.data.calc_loop_triangles()
    assert len(obj.data.loop_triangles) <= part['triangle_ceiling']
    objects.append(obj)
    measurements.append({'id':part['id'],'triangles':len(obj.data.loop_triangles),'surfaces':len(obj.data.materials)})
assert bpy.ops.wm.save_as_mainfile(filepath=str(targets[0])) == {'FINISHED'}
for obj,target,part in zip(objects,targets[1:],contract['parts']):
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    assert bpy.ops.export_scene.gltf(filepath=str(target),export_format='GLB',use_selection=True,
        export_yup=True,export_animations=False,export_tangents=True,export_cameras=False,
        export_lights=False,export_extras=False) == {'FINISHED'}
    raw = target.read_bytes()
    assert struct.unpack_from('<4sII',raw)==(b'glTF',2,len(raw))
    size,kind = struct.unpack_from('<II',raw,12)
    assert kind == 0x4e4f534a
    doc = json.loads(raw[20:20+size])
    assert len(doc['nodes']) == len(doc['meshes']) == 1
    assert not any(doc.get(k) for k in ('animations','skins','images','textures'))
    assert len(doc['meshes'][0]['primitives']) == len(part['materials'])
    for primitive in doc['meshes'][0]['primitives']:
        assert {'POSITION','NORMAL','TANGENT','TEXCOORD_0'} <= set(primitive['attributes'])
e = out / 'docs/production/evidence/archive_reconstruction/ceiling-authoring-2'
e.mkdir(parents=True)
(e/'payload_manifest.json').write_text(json.dumps({'payloads':[{'path':p.relative_to(out).as_posix(),
    'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in targets],
    'measurements':measurements,'geometry_helper_sha256':hashlib.sha256(recipe.read_bytes()).hexdigest()},indent=2)+'\n')
print('WING01_CEILING_CREATED PASS:',json.dumps(measurements))
