"""Ordinary original timber leaf, using approved Geometry and local export contract."""
import ast,hashlib,json,math,sys
from pathlib import Path
import bpy,bmesh
from mathutils import Vector
root=Path(__file__).resolve().parents[1];out=Path(sys.argv[sys.argv.index('--')+1]).resolve()
source=out/'assets/3d/blender/archive_kit/s01_core_pedestal.blend';target=out/'game/art/meshes/archive_kit/sm_s01_core_pedestal.glb'
assert not source.exists() and not target.exists()
source.parent.mkdir(parents=True);target.parent.mkdir(parents=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
for item in list(bpy.data.collections):bpy.data.collections.remove(item)
scene=bpy.context.scene;scene.unit_settings.system='METRIC';scene.unit_settings.scale_length=1
scene['asset_brief']='docs/production/S01_CORE_PEDESTAL.md';scene['scope']='Original lower mechanical plinth inside unchanged core cylinder; full hero/orbit/rotunda separate'
materials={}
for family,color,metal,rough,name in [('walnut',(.12,.045,.016,1),0,.65,'m_dark_walnut'),('iron',(.055,.062,.07,1),1,.7,'m_dark_iron'),('brass',(.36,.22,.055,1),1,.48,'m_aged_brass'),('stone',(.64,.57,.44,1),0,.78,'m_observatory_stone'),('crimson',(.22,.025,.032,1),0,.85,'m_crimson_textile')]:
 m=bpy.data.materials.new(name);m.use_nodes=True;m.use_backface_culling=True
 for key,value in [('Base Color',color),('Metallic',metal),('Roughness',rough)]:m.node_tree.nodes.get('Principled BSDF').inputs[key].default_value=value
 materials[family]=m
recipe=root/'tools/create_wing01_optics.py';definitions=[n for n in ast.parse(recipe.read_text()).body if isinstance(n,(ast.ClassDef,ast.FunctionDef)) and n.name in {'convert','Geometry'}];exec(compile(ast.Module(body=definitions,type_ignores=[]),str(recipe),'exec'),globals())
g=Geometry()
def barrel(profile,material,segments=24):
 g.loft([[(radius*math.cos(2*math.pi*i/segments),height,radius*math.sin(2*math.pi*i/segments)) for i in range(segments)] for height,radius in profile],material)
barrel([(-.694,.945),(-.675,.98),(-.545,.98),(-.53,.945)],'stone')
barrel([(-.53,.88),(-.522,.90),(-.49,.90),(-.482,.88)],'iron')
barrel([(-.48,.852),(-.468,.875),(-.125,.84),(-.113,.821)],'walnut',segments=16)
barrel([(-.12,.876),(-.11,.897),(-.071,.897),(-.06,.876)],'brass')
barrel([(-.06,.103),(-.048,.12),(.588,.12),(.60,.103)],'iron')
barrel([(.55,.16),(.565,.18),(.675,.18),(.69,.16)],'brass')
# Raised head fasteners around the lower timber fascia, with axis radial.
for i in range(16):
 a=2*math.pi*i/16
 stud=Geometry();stud.cylinder((0,0,0),.012,.025,'brass',segments=8)
 pts=[]
 for x,minus_z,y in stud.vertices:
  z=-minus_z
  pts.append((math.cos(a)*x+math.sin(a)*z+math.sin(a)*.859,y-.29,-math.sin(a)*x+math.cos(a)*z+math.cos(a)*.859))
 g.solid(pts,stud.faces,'brass')
g.box((0,-.30,.866),(.42,.24,.012),'crimson',.002)
g.box((0,-.175,.872),(.44,.025,.020),'iron',.003)
p={'id':'pedestal','stem':'sm_s01_core_pedestal','joint':[0,0,0],'materials':['stone','walnut','iron','brass','crimson']};obj=g.object(p);obj.data.calc_loop_triangles();count=len(obj.data.loop_triangles);assert count<=3000

assert bpy.ops.wm.save_as_mainfile(filepath=str(source))=={'FINISHED'}
bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj
assert bpy.ops.export_scene.gltf(filepath=str(target),export_format='GLB',use_selection=True,export_yup=True,export_animations=False,export_tangents=True,export_cameras=False,export_lights=False,export_extras=False)=={'FINISHED'}
e=out/'docs/production/evidence/archive_reconstruction/core-pedestal-authoring-20261006';e.mkdir(parents=True)
(e/'payload_manifest.json').write_text(json.dumps({'payloads':[{'path':p.relative_to(out).as_posix(),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in [source,target]],'measurements':[{'stem':obj.name,'triangles':count,'surfaces':5}],'geometry_helper_sha256':hashlib.sha256(recipe.read_bytes()).hexdigest()},indent=2)+'\n')
print('CORE_PEDESTAL_CREATED PASS',count,'triangles')
