"""Author the ordinary closed cloth rug; existing textile surfaces, no clue."""
import ast
import hashlib
import json
from pathlib import Path
import sys
import bpy
import bmesh
from mathutils import Vector

root = Path(__file__).resolve().parents[1]
c = json.loads((root / 'docs/production/archive_rug.json').read_text())
out = Path(sys.argv[sys.argv.index('--') + 1]).resolve()
source = out / c['source']
export = out / ('game/art/meshes/archive_kit/' + c['stem'] + '.glb')
assert not source.exists() and not export.exists(), 'Use a new output root'
source.parent.mkdir(parents=True, exist_ok=True)
export.parent.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
for collection in list(bpy.data.collections):
    bpy.data.collections.remove(collection)
scene = bpy.context.scene
scene.unit_settings.system = 'METRIC'
scene.unit_settings.scale_length = 1
scene['asset_brief'] = 'docs/production/ARCHIVE_RUG.md'
scene['source_recipe'] = 'tools/create_archive_rug.py'
materials = {}
for family, color in [('navy', (.045, .08, .17, 1)), ('crimson', (.24, .035, .055, 1))]:
    material = bpy.data.materials.new(Path(c['materials'][family]).stem)
    material.use_nodes = True
    material.use_backface_culling = True
    shader = material.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Base Color'].default_value = color
    shader.inputs['Roughness'].default_value = .9
    materials[family] = material
recipe = root / 'tools/create_wing01_optics.py'
definitions = [n for n in ast.parse(recipe.read_text()).body
               if isinstance(n, (ast.ClassDef, ast.FunctionDef)) and n.name in {'convert', 'Geometry'}]
assert len(definitions) == 2
exec(compile(ast.Module(body=definitions, type_ignores=[]), str(recipe), 'exec'), globals())

def outline(a, d, y, chamfer):
    return [(-a+chamfer,y,-d),(a-chamfer,y,-d),(a,y,-d+chamfer),(a,y,d-chamfer),
            (a-chamfer,y,d),(-a+chamfer,y,d),(-a,y,d-chamfer),(-a,y,-d+chamfer)]

# Shared vertices connect the border to the inset field, with no coplanar overlay.
outer_low = outline(1.3, 2, -.004, c['corner_chamfer'])
outer_top = outline(1.3, 2, .004, c['corner_chamfer'])
inner_top = outline(1.3-c['border_width'], 2-c['border_width'], .004, .06)
faces = [list(reversed(range(8)))]
faces += [[i, (i+1)%8, 8+(i+1)%8, 8+i] for i in range(8)]
faces += [[8+i, 8+(i+1)%8, 16+(i+1)%8, 16+i] for i in range(8)]
faces += [list(range(16,24))]
g = Geometry()
g.solid(outer_low+outer_top+inner_top, faces, 'navy')
g.slots[-1] = 'crimson'
obj = g.object(dict(c, materials=c['material_order']))
obj['source_translation'] = 'centered cloth pivot; unit-scale local export'
obj.data.calc_loop_triangles()
count = len(obj.data.loop_triangles)
assert count == 44 and count <= c['triangle_ceiling']
assert bpy.ops.wm.save_as_mainfile(filepath=str(source)) == {'FINISHED'}
obj.select_set(True)
bpy.context.view_layer.objects.active = obj
assert bpy.ops.export_scene.gltf(filepath=str(export), export_format='GLB', use_selection=True,
    export_yup=True, export_animations=False, export_tangents=True, export_cameras=False,
    export_lights=False, export_extras=False) == {'FINISHED'}
evidence = out / 'docs/production/evidence/archive_reconstruction/rug-authoring-20261006'
evidence.mkdir(parents=True)
(evidence / 'payload_manifest.json').write_text(json.dumps({
    'payloads': [{'path': p.relative_to(out).as_posix(), 'bytes': p.stat().st_size,
                 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()} for p in [source, export]],
    'measurements': {'triangles': count, 'surfaces': 2, 'thickness_m': .008},
    'geometry_helper_sha256': hashlib.sha256(recipe.read_bytes()).hexdigest()
}, indent=2) + '\n')
print('ARCHIVE_RUG_CREATED PASS:', count, 'triangles; closed navy border/crimson field')
