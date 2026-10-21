"""Original flat entry approach and contained guard skins, existing metric Geometry/export contract."""
import ast,hashlib,json,math,sys
from pathlib import Path
import bpy,bmesh
from mathutils import Vector
root=Path(__file__).resolve().parents[1]
out=Path(sys.argv[sys.argv.index('--')+1]).resolve()
source=out/'assets/3d/blender/archive_kit/s00_approach.blend'
contract=json.loads((root/'docs/production/s00_approach.json').read_text())
targets=[source]+[out/p['runtime'] for p in contract['parts']]
assert not any(p.exists() for p in targets)
for p in targets:p.parent.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
for item in list(bpy.data.collections):bpy.data.collections.remove(item)
scene=bpy.context.scene;scene.unit_settings.system='METRIC';scene.unit_settings.scale_length=1
scene['asset_brief']='docs/production/S00_APPROACH.md; bounded facade/crown only'
scene['scope']='Original flat approach and guard body volumes; no gameplay/state/save/collision/light'
materials={}
for f,color,metal,rough in [('stone',(.64,.57,.44,1),0,.78),('walnut',(.12,.045,.016,1),0,.65),('iron',(.055,.062,.07,1),1,.7),('brass',(.36,.22,.055,1),1,.48),('crimson',(.19,.017,.025,1),0,.92)]:
 if f not in contract['materials']: continue
 m=bpy.data.materials.new(Path(contract['materials'][f]).stem);m.use_nodes=True;m.use_backface_culling=True
 for key,value in [('Base Color',color),('Metallic',metal),('Roughness',rough)]:m.node_tree.nodes.get('Principled BSDF').inputs[key].default_value=value

 if f in contract['materials']: materials[f]=m
recipe=root/'tools/create_wing01_optics.py'
defs=[n for n in ast.parse(recipe.read_text()).body if isinstance(n,(ast.ClassDef,ast.FunctionDef)) and n.name in {'convert','Geometry'}]
exec(compile(ast.Module(body=defs,type_ignores=[]),str(recipe),'exec'),globals())
objects=[]
for part in contract['parts']:
 g=Geometry()
 if part['id']=='path':
  g.box((0,0,0),(3.988,.296,7.988),'stone',.005)
  for row in range(10):
   z=-3.582+row*.796
   for col in range(5):
    g.box(((col-2)*.72,.151,z),(.704,.01,.780),'stone',.002)
   for x in [-1.893,1.893]:g.box((x,.151,z),(.174,.01,.780),'stone',.002)
  for x in [-1.8,1.8]:
   # Five closed edge segments avoid ill-conditioned eight-meter thin UV faces.
   for i in range(5):
    z=-3.188+i*1.594
    g.box((x,.152,z),(.008,.004,1.580),'iron',.001)
    g.box((x+(.013 if x>0 else -.013),.153,z),(.007,.003,1.580),'brass',.0005)
 else:
  rear=part['id']=='guard_rear';length=4.6 if rear else 8.3
  def box(center,size,material,bevel=.005):
   if rear:center=(center[2],center[1]+.002,center[0]);size=(size[2],size[1],size[0])
   g.box(center,size,material,bevel)
  box((0,-.398,0),(.294,.388,length-.012),'stone',.008)
  box((0,.54,0),(.160,.100,length-.022),'iron',.005)
  box((0,-.14,0),(.104,.05,length-.09),'iron',.004)
  count=7 if rear else 11
  for i in range(count):
   z=-length/2+.11+i*(length-.22)/(count-1)
   box((0,.135,z),(.13,.81,.065),'iron',.004)
   box((0,.488,z),(.134,.032,.069),'brass',.002)
  for i in range((count-1)*2):
   z=-length/2+.15+(i+.5)*(length-.30)/((count-1)*2)
   box((0,.135,z),(.042,.51,.042),'iron',.003)
 obj=g.object({'stem':part['stem'],'id':part['id'],'materials':part['materials'],'joint':[0,0,0]})
 objects.append(obj)
bpy.ops.wm.save_as_mainfile(filepath=str(source))
measurements=[]
for obj,part in zip(objects,contract['parts']):
 bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj
 bpy.ops.export_scene.gltf(filepath=str(out/part['runtime']),export_format='GLB',use_selection=True,export_yup=True,export_apply=True,export_animations=False,export_cameras=False,export_lights=False,export_materials='EXPORT')
 obj.data.calc_loop_triangles();measurements.append({'stem':part['stem'],'triangles':len(obj.data.loop_triangles),'surfaces':len(obj.data.materials)})
manifest={'payloads':[{'path':p.relative_to(out).as_posix(),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in targets],'measurements':measurements,'geometry_helper_sha256':hashlib.sha256(recipe.read_bytes()).hexdigest()}
(out/'payload_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('S00_APPROACH_CREATED PASS',measurements)
