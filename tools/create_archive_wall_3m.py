"""Export only the bounded third wall size with the existing kit geometry/export policy.

blender --background --factory-startup --python-exit-code 1 \
    --python tools/create_archive_wall_3m.py -- /absolute/empty/output-root
The accepted five-module source/exports are never rebuilt or overwritten.
"""
import ast
import hashlib
import json
from pathlib import Path
import struct
import sys

import bpy
import bmesh
from mathutils import Vector

root = Path(__file__).resolve().parents[1]
contract = json.loads((root / 'docs/production/modular_archive_kit_v1.json').read_text())
module = json.loads((root / 'docs/production/archive_wall_3m.json').read_text())
out = Path(sys.argv[sys.argv.index('--') + 1]).resolve()
source, target = out / module['source'], out / module['runtime']
if source.exists() or target.exists():
    raise RuntimeError('Refusing to overwrite an authored source/export')
source.parent.mkdir(parents=True, exist_ok=True)
target.parent.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
for collection in list(bpy.data.collections):
    bpy.data.collections.remove(collection)
scene = bpy.context.scene
scene.unit_settings.system = 'METRIC'
scene.unit_settings.scale_length = 1
scene['asset_brief'] = 'docs/production/archive_wall_3m.json; MODULAR_ARCHIVE_KIT.md visual revision 2'
scene['source_recipe'] = 'tools/create_archive_wall_3m.py'
stone = bpy.data.materials.new('m_observatory_stone')
stone.use_nodes = True
stone.use_backface_culling = True
bsdf = stone.node_tree.nodes.get('Principled BSDF')
bsdf.inputs['Base Color'].default_value = (.64, .57, .44, 1)
bsdf.inputs['Metallic'].default_value = 0
bsdf.inputs['Roughness'].default_value = .78
materials = [stone]
# Reuse the exact previously tested geometry, manifold/UV/tangent authoring helpers.
# Do not execute the five-part CLI or introduce a second geometry algorithm.
recipe = root / 'tools/create_archive_kit.py'
definitions = [n for n in ast.parse(recipe.read_text()).body
               if isinstance(n, (ast.ClassDef, ast.FunctionDef))
               and n.name in {'Geometry', 'rectangle', 'wall'}]
assert len(definitions) == 3
exec(compile(ast.Module(body=definitions, type_ignores=[]), str(recipe), 'exec'), globals())
obj = wall(3).object(module)
assert obj.location.length == 0 and obj.scale == Vector((1, 1, 1))
assert bpy.ops.wm.save_as_mainfile(filepath=str(source)) == {'FINISHED'}
bpy.ops.object.select_all(action='DESELECT')
obj.select_set(True)
bpy.context.view_layer.objects.active = obj
assert bpy.ops.export_scene.gltf(filepath=str(target), export_format='GLB', use_selection=True,
                                export_yup=True, export_animations=False, export_tangents=True,
                                export_cameras=False, export_lights=False, export_extras=False) == {'FINISHED'}
raw = target.read_bytes()
assert struct.unpack_from('<4sII', raw) == (b'glTF', 2, len(raw))
size, kind = struct.unpack_from('<II', raw, 12)
assert kind == 0x4E4F534A
doc = json.loads(raw[20:20 + size])
assert len(doc['meshes']) == 1 and len(doc['meshes'][0]['primitives']) == 1
assert not any(doc.get(k) for k in ('animations', 'skins', 'images', 'textures'))
assert {'POSITION', 'NORMAL', 'TANGENT', 'TEXCOORD_0'} <= set(doc['meshes'][0]['primitives'][0]['attributes'])
payloads = [{'path': str(p.relative_to(out)), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest(),
             'bytes': p.stat().st_size} for p in (source, target)]
manifest = out / 'docs/production/evidence/archive_reconstruction/front-wall-authoring-1/payload_manifest.json'
manifest.parent.mkdir(parents=True, exist_ok=True)
manifest.write_text(json.dumps({'module': module, 'triangles': len(obj.data.polygons),
                               'payloads': payloads, 'recipe_sha256': hashlib.sha256(recipe.read_bytes()).hexdigest()}, indent=2) + '\n')
print('ARCHIVE_WALL_3M_CREATED PASS: one closed original wall, editable source + GLB; triangles=', len(obj.data.polygons))
