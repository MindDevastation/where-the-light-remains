"""Original leaf props, using the established metric Geometry/export helper."""
import ast
import hashlib
import json
import math
from pathlib import Path
import sys
import bpy
import bmesh
from mathutils import Vector

root = Path(__file__).resolve().parents[1]
c = json.loads((root / 'docs/production/s01_starting_lens.json').read_text())
out = Path(sys.argv[sys.argv.index('--') + 1]).resolve()
source = out / c['source']
exports = [out / ('game/art/meshes/archive_kit/' + p['stem'] + '.glb') for p in c['parts']]
assert not any(p.exists() for p in [source] + exports), 'Use a new output root'
for p in [source] + exports:
    p.parent.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
for collection in list(bpy.data.collections):
    bpy.data.collections.remove(collection)
scene = bpy.context.scene
scene.unit_settings.system = 'METRIC'
scene.unit_settings.scale_length = 1
scene['asset_brief'] = 'docs/production/S01_STARTING_LENS.md'
scene['source_recipe'] = 'tools/create_s01_starting_lens.py'
materials = {}
for family, color, metal, rough in [
    ('brass',(.36,.22,.055,1),1,.48), ('glass',(.8,.9,.98,.12),0,.08),
    ('iron',(.055,.062,.07,1),1,.7)]:
    m = bpy.data.materials.new(Path(c['materials'][family]).stem)
    m.use_nodes = True
    m.use_backface_culling = True
    bsdf = m.node_tree.nodes.get('Principled BSDF')
    for key,value in [('Base Color',color),('Metallic',metal),('Roughness',rough)]:
        bsdf.inputs[key].default_value = value
    if family == 'glass':
        bsdf.inputs['Alpha'].default_value = .12
    materials[family] = m
recipe = root / 'tools/create_wing01_optics.py'
definitions = [n for n in ast.parse(recipe.read_text()).body
    if isinstance(n,(ast.ClassDef,ast.FunctionDef)) and n.name in {'convert','Geometry'}]
assert len(definitions) == 2
exec(compile(ast.Module(body=definitions,type_ignores=[]),str(recipe),'exec'),globals())

lens = Geometry()
lens.ring(.162,.036,.064,'brass',segments=48)
# Closed convex insert: the rim hides its peripheral contact seam.
lens.loft([[(r*math.cos(i*math.tau/48),r*math.sin(i*math.tau/48),z)
    for i in range(48)] for r,z in [(.118,-.021),(.14,-.009),(.145,0),(.14,.009),(.118,.021)]], 'glass')
for x in [-.183,.183]:
    lens.box((x,0,.041),(.036,.055,.018),'brass',bevel=.004)
socket = Geometry()
socket.ring(.196,.028,.08,'iron',segments=48,center=(0,0,-.025))
socket.ring(.165,.042,.028,'brass',segments=24,center=(0,0,-.08))
for angle in [math.pi/4,3*math.pi/4,5*math.pi/4,7*math.pi/4]:
    socket.cylinder((.196*math.cos(angle),.196*math.sin(angle),.019),.009,.022,'brass',segments=8)
objects = [g.object(p) for g,p in zip([lens,socket],c['parts'])]
measurements = []
for obj,p in zip(objects,c['parts']):
    obj.data.calc_loop_triangles()
    count = len(obj.data.loop_triangles)
    assert count <= p['triangle_ceiling']
    measurements.append({'stem':p['stem'],'triangles':count,'surfaces':len(obj.data.materials)})
assert bpy.ops.wm.save_as_mainfile(filepath=str(source)) == {'FINISHED'}
for obj,path in zip(objects,exports):
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    assert bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,
        export_yup=True,export_animations=False,export_tangents=True,export_cameras=False,
        export_lights=False,export_extras=False) == {'FINISHED'}
evidence = out / 'docs/production/evidence/archive_reconstruction/lens-authoring-20261006-2'
evidence.mkdir(parents=True)
(evidence / 'payload_manifest.json').write_text(json.dumps({
    'payloads':[{'path':p.relative_to(out).as_posix(),'bytes':p.stat().st_size,
        'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in [source]+exports],
    'measurements':measurements,'geometry_helper_sha256':hashlib.sha256(recipe.read_bytes()).hexdigest()
},indent=2)+'\n')
print('S01_LENS_CREATED PASS:',measurements)
