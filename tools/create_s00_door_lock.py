"""Original ordinary sliding fitting; established Geometry/local export recipe."""
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
c = json.loads((root/'docs/production/s00_door_lock.json').read_text())
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
scene['asset_brief'] = 'docs/production/S00_DOOR_LOCK.md'
scene['source_recipe'] = 'tools/create_s00_door_lock.py'
materials = {}
for family,color,metal,rough in [('iron',(.055,.062,.07,1),1,.7),('brass',(.36,.22,.055,1),1,.48)]:
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

def collar(g,x,length):
    # Closed rectangular guide with a real bore along X, not a solid block.
    def rectangle(y,z):
        return [(-y,c['bore_z']-z),(y,c['bore_z']-z),(y,c['bore_z']+z),(-y,c['bore_z']+z)]
    outer = rectangle(.036,.0345)
    inner = rectangle(c['bore_half_height'],c['bore_half_depth'])
    vertices = [(edge,y,z) for edge in [x-length/2,x+length/2] for y,z in outer+inner]
    faces = []
    for i in range(4):
        j=(i+1)%4
        faces += [[i,j,8+j,8+i],[4+i,12+i,12+j,4+j],
                  [i,4+i,4+j,j],[8+i,8+j,12+j,12+i]]
    g.solid(vertices,faces,'brass')

housing = Geometry()
housing.box((-.21,0,-.025),(.32,.17,.02),'iron',bevel=.005)
for x in [-.31,-.12]:
    collar(housing,x,.034)
for x in [-.345,-.075]:
    for y in [-.061,.061]:
        housing.cylinder((x,y,-.008),.009,.02,'brass',segments=8)
bolt = Geometry()
bolt.box(c['bar_center'],c['bar_size'],'brass',bevel=.004)
bolt.cylinder((-.27,0,.066),.024,.05,'iron',segments=12)
keeper = Geometry()
keeper.box((.14,0,-.029),(.20,.17,.022),'iron',bevel=.005)
collar(keeper,.075,.07)
for x in [.054,.226]:
    for y in [-.061,.061]:
        keeper.cylinder((x,y,-.010),.009,.02,'brass',segments=8)
objects = [g.object(p) for g,p in zip([housing,bolt,keeper],c['parts'])]
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
    assert bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,
        export_yup=True,export_animations=False,export_tangents=True,export_cameras=False,
        export_lights=False,export_extras=False)=={'FINISHED'}
evidence = out/'docs/production/evidence/archive_reconstruction/lock-authoring-20261006'
evidence.mkdir(parents=True)
(evidence/'payload_manifest.json').write_text(json.dumps({
    'payloads':[{'path':p.relative_to(out).as_posix(),'bytes':p.stat().st_size,
        'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in [source]+exports],
    'measurements':measurements,'geometry_helper_sha256':hashlib.sha256(recipe.read_bytes()).hexdigest()
},indent=2)+'\n')
print('S00_LOCK_CREATED PASS:',measurements)
