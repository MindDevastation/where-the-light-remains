"""Ordinary original timber leaf, using approved Geometry and local export contract."""
import ast,hashlib,json,math,sys
from pathlib import Path
import bpy,bmesh
from mathutils import Vector
root=Path(__file__).resolve().parents[1];out=Path(sys.argv[sys.argv.index('--')+1]).resolve()
source=out/'assets/3d/blender/archive_kit/s00_entrance_leaf.blend';target=out/'game/art/meshes/archive_kit/sm_s00_entrance_leaf.glb'
assert not source.exists() and not target.exists()
source.parent.mkdir(parents=True);target.parent.mkdir(parents=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
for item in list(bpy.data.collections):bpy.data.collections.remove(item)
scene=bpy.context.scene;scene.unit_settings.system='METRIC';scene.unit_settings.scale_length=1
scene['asset_brief']='docs/production/S00_ENTRANCE_LEAF.md';scene['scope']='Original timber skin inside unchanged sliding door collision; no exterior/portal layout claim'
materials={}
for family,color,metal,rough,name in [('walnut',(.12,.045,.016,1),0,.65,'m_dark_walnut'),('iron',(.055,.062,.07,1),1,.7,'m_dark_iron'),('brass',(.36,.22,.055,1),1,.48,'m_aged_brass')]:
 m=bpy.data.materials.new(name);m.use_nodes=True;m.use_backface_culling=True
 for key,value in [('Base Color',color),('Metallic',metal),('Roughness',rough)]:m.node_tree.nodes.get('Principled BSDF').inputs[key].default_value=value
 materials[family]=m
recipe=root/'tools/create_wing01_optics.py';definitions=[n for n in ast.parse(recipe.read_text()).body if isinstance(n,(ast.ClassDef,ast.FunctionDef)) and n.name in {'convert','Geometry'}];exec(compile(ast.Module(body=definitions,type_ignores=[]),str(recipe),'exec'),globals())
g=Geometry();g.box((0,0,-.025),(1.28,3.76,.19),'walnut',.012)
for x in [-.44,-.22,0,.22,.44]:g.box((x,0,.076),(.212,3.48,.055),'walnut',.006)
for x in [-.59,.59]:g.box((x,0,0),(.12,3.8,.23),'walnut',.012)
for y in [-1.79,1.79]:g.box((0,y,0),(1.06,.18,.23),'walnut',.009)
for y in [-1.23,.38,1.30]:
 g.box((0,y,.116),(1.20,.105,.014),'iron',.002)
 for x in [-.48,-.28,-.08,.08,.28,.48]:g.cylinder((x,y,.113),.015,.024,'brass',segments=8)
for x in [-.515,.515]:g.box((x,0,.118),(.022,3.30,.008),'brass',.002)
# Ordinary forged diagonal braces, without glyphs or faction symbols.
for direction in [-1,1]:
 brace=Geometry();brace.box((0,0,0),(.055,1.0,.016),'iron',.003)
 a=math.radians(direction*27)
 # Geometry stores Blender coordinates: convert back once before placing.
 pts=[]
 for x,minus_z,y in brace.vertices:
  pts.append((math.cos(a)*x-math.sin(a)*y,math.sin(a)*x+math.cos(a)*y+.94,-minus_z+.112+direction*.0015))
 g.solid(pts,brace.faces,'iron')
p={'id':'leaf','stem':'sm_s00_entrance_leaf','joint':[0,0,0],'materials':['walnut','iron','brass']};obj=g.object(p);obj.data.calc_loop_triangles();count=len(obj.data.loop_triangles);assert count<=3000
assert bpy.ops.wm.save_as_mainfile(filepath=str(source))=={'FINISHED'}
bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj
assert bpy.ops.export_scene.gltf(filepath=str(target),export_format='GLB',use_selection=True,export_yup=True,export_animations=False,export_tangents=True,export_cameras=False,export_lights=False,export_extras=False)=={'FINISHED'}
e=out/'docs/production/evidence/archive_reconstruction/entrance-authoring-20261006';e.mkdir(parents=True)
(e/'payload_manifest.json').write_text(json.dumps({'payloads':[{'path':p.relative_to(out).as_posix(),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in [source,target]],'measurements':[{'stem':obj.name,'triangles':count,'surfaces':3}],'geometry_helper_sha256':hashlib.sha256(recipe.read_bytes()).hexdigest()},indent=2)+'\n')
print('ENTRANCE_LEAF_CREATED PASS',count,'triangles')
