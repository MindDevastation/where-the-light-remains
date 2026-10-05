"""Two bounded original S02 housings using the accepted optical-source helpers.

blender --background --factory-startup --python-exit-code 1 \
    --python tools/create_wing01_hearth_emitter.py -- /absolute/empty/output-root
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
contract = json.loads((root / 'docs/production/wing01_hearth_emitter.json').read_text())
out = Path(sys.argv[sys.argv.index('--') + 1]).resolve()
source = out / contract['source']
targets = [source] + [out / ('game/art/meshes/wing01/' + p['stem'] + '.glb') for p in contract['parts']]
assert not any(p.exists() for p in targets), 'Use an empty output root; no existing asset is rebuilt'
for target in targets:
    target.parent.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
for collection in list(bpy.data.collections):
    bpy.data.collections.remove(collection)
scene = bpy.context.scene
scene.unit_settings.system = 'METRIC'
scene.unit_settings.scale_length = 1
scene['asset_brief'] = 'docs/production/WING01_HEARTH_EMITTER.md; wing01_hearth_emitter.json'
scene['source_recipe'] = 'tools/create_wing01_hearth_emitter.py'
materials = {}
for family, color, metal, rough in (
    ('stone', (.64, .57, .44, 1), 0, .78),
    ('brass', (.36, .22, .055, 1), 1, .48),
    ('iron', (.055, .062, .07, 1), 1, .7),
    ('glass', (.65, .8, .9, 1), 0, .12),
):
    material = bpy.data.materials.new(Path(contract['materials'][family]).stem)
    material.use_nodes = True
    material.use_backface_culling = True
    bsdf = material.node_tree.nodes.get('Principled BSDF')
    for key, value in [('Base Color', color), ('Metallic', metal), ('Roughness', rough)]:
        bsdf.inputs[key].default_value = value
    materials[family] = material
recipe = root / 'tools/create_wing01_optics.py'
definitions = [n for n in ast.parse(recipe.read_text()).body
               if isinstance(n, (ast.ClassDef, ast.FunctionDef)) and n.name in {'convert', 'Geometry'}]
assert len(definitions) == 2
exec(compile(ast.Module(body=definitions, type_ignores=[]), str(recipe), 'exec'), globals())

def profile(g, sections, family):
    loops = [[(radius * math.cos(2 * math.pi * i / 32), y,
               radius * math.sin(2 * math.pi * i / 32)) for i in range(32)]
             for radius, y in sections]
    g.loft(loops, family)

objects = []
for part in contract['parts']:
    g = Geometry()
    if part['id'] == 'hearth':
        profile(g, [(.45, -.65), (.48, -.63), (.48, -.59), (.44, -.54),
                    (.38, -.5), (.32, -.46), (.27, -.38), (.24, -.18), (.29, -.14)], 'stone')
        # Hollow vessel: outside, rounded lip, inside and a recessed solid floor.
        # The two capped ends are below the mouth; no disk covers the opening.
        profile(g, [(.35, -.14), (.41, -.12), (.5, .04), (.6, .25), (.6, .30),
                    (.57, .32), (.53, .30), (.52, .25), (.44, .04), (.32, -.06)], 'brass')
    else:
        # Local -Y optical face matches the preserved 90-degree parent rotation.
        profile(g, [(.205, .175), (.22, .15), (.22, .1), (.24, .08), (.24, -.08),
                    (.22, -.1), (.22, -.175), (.205, -.2), (.18, -.2),
                    (.17, -.18), (.17, -.13)], 'brass')
        profile(g, [(.215, .1), (.23, .095), (.23, .085), (.215, .08)], 'iron')
        profile(g, [(.155, -.174), (.16, -.170), (.16, -.164), (.155, -.16)], 'glass')
    obj = g.object(part)
    obj.data.calc_loop_triangles()
    assert len(obj.data.loop_triangles) <= part['triangle_ceiling']
    objects.append(obj)
    print('WING01_HOUSING_AUTHORED', part['id'], len(obj.data.loop_triangles), 'triangles', len(obj.data.materials), 'surfaces')
scene.collection.children['emitter'].hide_viewport = True
assert bpy.ops.wm.save_as_mainfile(filepath=str(source)) == {'FINISHED'}
scene.collection.children['emitter'].hide_viewport = False
for obj, target, part in zip(objects, targets[1:], contract['parts']):
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    assert bpy.ops.export_scene.gltf(filepath=str(target), export_format='GLB', use_selection=True,
                                    export_yup=True, export_animations=False, export_tangents=True,
                                    export_cameras=False, export_lights=False, export_extras=False) == {'FINISHED'}
    raw = target.read_bytes()
    assert struct.unpack_from('<4sII', raw) == (b'glTF', 2, len(raw))
    size, kind = struct.unpack_from('<II', raw, 12)
    assert kind == 0x4e4f534a
    doc = json.loads(raw[20:20 + size])
    assert len(doc['meshes']) == len(doc['nodes']) == 1
    assert not any(doc.get(k) for k in ('animations', 'skins', 'images', 'textures'))
    assert len(doc['meshes'][0]['primitives']) == len(part['materials'])
    for prim in doc['meshes'][0]['primitives']:
        assert {'POSITION', 'NORMAL', 'TANGENT', 'TEXCOORD_0'} <= set(prim['attributes'])
e = out / 'docs/production/evidence/archive_reconstruction/hearth-emitter-authoring-1'
e.mkdir(parents=True)
(e / 'payload_manifest.json').write_text(json.dumps({'payloads': [{'path': p.relative_to(out).as_posix(),
    'bytes': p.stat().st_size, 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()} for p in targets],
    'recipe_sha256': hashlib.sha256(recipe.read_bytes()).hexdigest()}, indent=2) + '\n')
print('WING01_HEARTH_EMITTER_CREATED PASS: two original static housings; one editable source + two GLBs')
