"""Original shared wall practical; only writes to a new disposable output root."""
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
contract = json.loads((root/'docs/production/archive_wall_lantern.json').read_text())
out = Path(sys.argv[sys.argv.index('--')+1]).resolve()
source = out/contract['source']
export = out/('game/art/meshes/archive_kit/'+contract['stem']+'.glb')
assert not source.exists() and not export.exists(), 'Use a new output root'
source.parent.mkdir(parents=True,exist_ok=True)
export.parent.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
for collection in list(bpy.data.collections):
    bpy.data.collections.remove(collection)
scene = bpy.context.scene
scene.unit_settings.system='METRIC'
scene.unit_settings.scale_length=1
scene['asset_brief']='docs/production/ARCHIVE_WALL_LANTERN.md'
scene['source_recipe']='tools/create_archive_wall_lantern.py'
materials={}
for family,color,metal,rough in [('iron',(.055,.062,.07,1),1,.7),
 ('brass',(.36,.22,.055,1),1,.48),('glass',(.8,.9,.98,1),0,.08),
 ('gold',(.55,.28,.065,1),0,.4)]:
    m=bpy.data.materials.new(Path(contract['materials'][family]).stem)
    m.use_nodes=True
    m.use_backface_culling=True
    shader=m.node_tree.nodes.get('Principled BSDF')
    for key,value in [('Base Color',color),('Metallic',metal),('Roughness',rough)]:
        shader.inputs[key].default_value=value
    materials[family]=m
recipe=root/'tools/create_wing01_optics.py'
definitions=[n for n in ast.parse(recipe.read_text()).body
 if isinstance(n,(ast.ClassDef,ast.FunctionDef)) and n.name in {'convert','Geometry'}]
assert len(definitions)==2
exec(compile(ast.Module(body=definitions,type_ignores=[]),str(recipe),'exec'),globals())
g=Geometry()
# Solid mounting plate and lower cantilever. Back face sits at the wall pivot.
g.box((0,0,.018),(.13,.46,.036),'iron',.006)
g.box((0,-.19,.12),(.060,.055,.20),'iron',.006)
g.box((0,0,.038),(.038,.35,.012),'brass',.003)
# Four narrow posts leave the glazing clear. Closed roof/base caps avoid paper edges.
for x in [-.143,.143]:
    for z in [.106,.334]:
        g.box((x,0,z),(.028,.38,.028),'brass',.003)
for y,sign in [(-.205,-1),(.205,1)]:
    loops=[]
    for dy,w,d in [(-.027,.17,.142),(0,.18,.15),(.027,.16,.13)]:
        loops.append([(-w,y+dy,.22-d),(w,y+dy,.22-d),(w,y+dy,.22+d),(-w,y+dy,.22+d)])
    g.loft(loops,'brass')
# A short finial gives a quiet recognisable silhouette without decorative text.
g.box((0,.273,.22),(.05,.082,.05),'brass',.005)
# Three thin closed panes; back is metal mounted against the bracket.
def pane(center,size):
    x,y,z=center
    a,b,c=[v/2 for v in size]
    vertices=[(x+sx*a,y+sy*b,z+sz*c) for sx,sy,sz in
      [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]]
    g.solid(vertices,[[0,3,2,1],[4,5,6,7],[0,1,5,4],[3,7,6,2],[0,4,7,3],[1,2,6,5]],'glass')
pane((0,0,.326),(.26,.35,.004))
pane((-.135,0,.22),(.004,.35,.20))
pane((.135,0,.22),(.004,.35,.20))
g.box((0,0,.108),(.26,.35,.012),'iron',.002)
# Static enclosed emissive core: not a flame animation or an interaction hint.
loops=[]
for y,radius in [(-.125,.023),(-.10,.047),(.085,.047),(.125,.023)]:
    loops.append([(radius*math.cos(2*math.pi*i/12),y,.22+radius*math.sin(2*math.pi*i/12)) for i in range(12)])
g.loft(loops,'gold')
part=dict(contract,materials=contract['material_order'])
obj=g.object(part)
obj.data.calc_loop_triangles()
count=len(obj.data.loop_triangles)
assert count<=contract['triangle_ceiling'], count
assert bpy.ops.wm.save_as_mainfile(filepath=str(source))=={'FINISHED'}
bpy.ops.object.select_all(action='DESELECT')
obj.select_set(True)
bpy.context.view_layer.objects.active=obj
assert bpy.ops.export_scene.gltf(filepath=str(export),export_format='GLB',use_selection=True,
 export_yup=True,export_animations=False,export_tangents=True,export_cameras=False,
 export_lights=False,export_extras=False)=={'FINISHED'}
raw=export.read_bytes()
assert struct.unpack_from('<4sII',raw)==(b'glTF',2,len(raw))
size,kind=struct.unpack_from('<II',raw,12)
assert kind==0x4e4f534a
doc=json.loads(raw[20:20+size])
assert len(doc['nodes'])==len(doc['meshes'])==1
assert not any(doc.get(k) for k in ['animations','skins','images','textures'])
assert len(doc['meshes'][0]['primitives'])==4
for p in doc['meshes'][0]['primitives']:
    assert {'POSITION','NORMAL','TANGENT','TEXCOORD_0'}<=set(p['attributes'])
e=out/'docs/production/evidence/archive_reconstruction/lantern-authoring-1'
e.mkdir(parents=True)
(e/'payload_manifest.json').write_text(json.dumps({'payloads':[{'path':p.relative_to(out).as_posix(),
 'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in [source,export]],
 'measurements':{'triangles':count,'surfaces':4},
 'geometry_helper_sha256':hashlib.sha256(recipe.read_bytes()).hexdigest()},indent=2)+'\n')
print('ARCHIVE_LANTERN_CREATED PASS:',count,'triangles; four reused material surfaces; identity meters')
