"""Original ordinary fittings; established Geometry and pivot/export contract."""
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
c = json.loads((root/'docs/production/s01_hub_controls.json').read_text())
out = Path(sys.argv[sys.argv.index('--')+1]).resolve()
source = out/c['source']
exports = [out/('game/art/meshes/archive_kit/'+p['stem']+'.glb') for p in c['parts']]
assert not any(p.exists() for p in [source]+exports), 'Use a new output root'
for p in [source]+exports:
    p.parent.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
for collection in list(bpy.data.collections):
    bpy.data.collections.remove(collection)
scene = bpy.context.scene
scene.unit_settings.system = 'METRIC'
scene.unit_settings.scale_length = 1
scene['asset_brief'] = 'docs/production/S01_HUB_CONTROLS.md'
scene['source_recipe'] = 'tools/create_s01_hub_controls.py'
materials = {}
for family,color,metal,rough in [('iron',(.055,.062,.07,1),1,.7),
    ('brass',(.36,.22,.055,1),1,.48),('walnut',(.12,.045,.016,1),0,.65)]:
    m = bpy.data.materials.new(Path(c['materials'][family]).stem)
    m.use_nodes = True
    m.use_backface_culling = True
    bsdf = m.node_tree.nodes.get('Principled BSDF')
    for key,value in [('Base Color',color),('Metallic',metal),('Roughness',rough)]:
        bsdf.inputs[key].default_value = value
    materials[family] = m
recipe = root/'tools/create_wing01_optics.py'
definitions = [n for n in ast.parse(recipe.read_text()).body
    if isinstance(n,(ast.ClassDef,ast.FunctionDef)) and n.name in {'convert','Geometry'}]
assert len(definitions)==2
exec(compile(ast.Module(body=definitions,type_ignores=[]),str(recipe),'exec'),globals())

panel = Geometry()
panel.box((0,0,-.045),(.39,.38,.07),'iron',bevel=.012)
for y in [-.176,.176]:
    panel.box((0,y,-.005),(.37,.025,.024),'brass',bevel=.004)
for x in [-.178,.178]:
    panel.box((x,0,-.005),(.025,.327,.024),'brass',bevel=.004)
for x in [-.178,.178]:
    for y in [-.176,.176]:
        panel.cylinder((x,y,.01),.009,.02,'brass',segments=8)
# Vertical hinge: ordinary axis-aligned closed bearing, no runtime rig.
panel.loft([[(-.157+r*math.cos(i*math.tau/16),y,.02+r*math.sin(i*math.tau/16))
    for i in range(16)] for r,y in [(.011,-.12),(.014,-.112),(.014,.112),(.011,.12)]],'brass')
cover = Geometry()
cover.box((.157,0,0),(.314,.3,.02),'walnut',bevel=.005)
for y in [-.14,.14]:
    cover.box((.157,y,.012),(.30,.018,.014),'brass',bevel=.003)
for x in [.013,.301]:
    cover.box((x,0,.012),(.018,.26,.014),'brass',bevel=.003)
cover.box((.271,0,.022),(.032,.065,.025),'brass',bevel=.004)
lever = Geometry()
lever.box((0,-.035,-.055),(.22,.24,.05),'iron',bevel=.01)
lever.box((-.14,-.08,-.04),(.16,.075,.04),'iron',bevel=.008)
for x in [-.084,.084]:
    for y in [-.132,.062]:
        lever.cylinder((x,y,-.021),.01,.028,'brass',segments=8)
# Horizontal axle along +X, centered at the wrapper's handle pivot.
lever.loft([[(x,-.08+r*math.cos(i*math.tau/16),r*math.sin(i*math.tau/16))
    for i in range(16)] for r,x in [(.036,-.065),(.042,-.057),(.042,.057),(.036,.065)]],'brass')
handle = Geometry()
handle.box((0,.106,0),(.032,.212,.032),'brass',bevel=.005)
handle.cylinder((0,.204,0),.045,.07,'walnut',segments=16)
for z in [-.038,.038]:
    handle.cylinder((0,.204,z),.038,.012,'brass',segments=16)
objects = [g.object(p) for g,p in zip([panel,cover,lever,handle],c['parts'])]
measurements = []
for obj,p in zip(objects,c['parts']):
    obj.data.calc_loop_triangles()
    count = len(obj.data.loop_triangles)
    assert count<=p['triangle_ceiling']
    measurements.append({'stem':p['stem'],'triangles':count,'surfaces':len(obj.data.materials)})
assert bpy.ops.wm.save_as_mainfile(filepath=str(source))=={'FINISHED'}
for obj,path in zip(objects,exports):
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    location = obj.location.copy()
    obj.location = (0,0,0)
    assert bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,
        export_yup=True,export_animations=False,export_tangents=True,export_cameras=False,
        export_lights=False,export_extras=False)=={'FINISHED'}
    obj.location = location
evidence = out/'docs/production/evidence/archive_reconstruction/controls-authoring-20261006'
evidence.mkdir(parents=True)
(evidence/'payload_manifest.json').write_text(json.dumps({
    'payloads':[{'path':p.relative_to(out).as_posix(),'bytes':p.stat().st_size,
        'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in [source]+exports],
    'measurements':measurements,'geometry_helper_sha256':hashlib.sha256(recipe.read_bytes()).hexdigest()
},indent=2)+'\n')
print('S01_CONTROLS_CREATED PASS:',measurements)
