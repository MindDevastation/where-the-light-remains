"""Original bounded exterior facade/crown, existing metric Geometry/export contract."""
import ast,hashlib,json,math,sys
from pathlib import Path
import bpy,bmesh
from mathutils import Vector
root=Path(__file__).resolve().parents[1]
out=Path(sys.argv[sys.argv.index('--')+1]).resolve()
source=out/'assets/3d/blender/archive_kit/s00_entry_portal.blend'
contract=json.loads((root/'docs/production/s00_entry_portal.json').read_text())
targets=[source]+[out/p['runtime'] for p in contract['parts']]
assert not any(p.exists() for p in targets)
for p in targets:p.parent.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
for item in list(bpy.data.collections):bpy.data.collections.remove(item)
scene=bpy.context.scene;scene.unit_settings.system='METRIC';scene.unit_settings.scale_length=1
scene['asset_brief']='docs/production/S00_S15_EXTERIOR_INTERFACES.md; bounded facade/crown only'
scene['scope']='Original existing wall volumes and crown above existing entry; no gameplay/state/save/collision/light'
materials={}
for f,color,metal,rough in [('stone',(.64,.57,.44,1),0,.78),('walnut',(.12,.045,.016,1),0,.65),('iron',(.055,.062,.07,1),1,.7),('brass',(.36,.22,.055,1),1,.48),('crimson',(.19,.017,.025,1),0,.92)]:
 m=bpy.data.materials.new(Path(contract['materials'][f]).stem);m.use_nodes=True;m.use_backface_culling=True
 for key,value in [('Base Color',color),('Metallic',metal),('Roughness',rough)]:m.node_tree.nodes.get('Principled BSDF').inputs[key].default_value=value
 materials[f]=m
recipe=root/'tools/create_wing01_optics.py'
defs=[n for n in ast.parse(recipe.read_text()).body if isinstance(n,(ast.ClassDef,ast.FunctionDef)) and n.name in {'convert','Geometry'}]
exec(compile(ast.Module(body=defs,type_ignores=[]),str(recipe),'exec'),globals())
objects=[]
for part in contract['parts']:
 g=Geometry()
 if part['id']=='facade':
  g.box((0,0,.02),(2.244,4.784,.30),'stone',.01)
  for row in range(10):
   y=-2.15+row*.476
   # High central recess carries plain textile; no clue/emblem or loose clutter.
   for col in range(3):
    if col==1 and row>=7:continue
    x=(col-1)*.744
    g.box((x,y,-.1425),(.730,.462,.065),'stone',.008)
  for x in [-.974,.974]:
   for row in range(8):g.box((x,-2.08+row*.535,-.02),(.30,.522,.30),'stone',.011)
   for y in [-2.29,1.92]:g.box((x,y,-.01),(.306,.15,.328),'stone',.009)
  g.box((0,2.13,-.028),(2.14,.24,.28),'walnut',.012)
  for x in [-.92,-.30,.30,.92]:
   g.box((x,2.13,-.159),(.066,.228,.022),'iron',.003)
   for y in [2.055,2.205]:g.cylinder((x,y,-.161),.015,.024,'brass',8)
  g.box((0,1.37,-.15),(.64,.93,.028),'iron',.004)
  g.box((0,1.37,-.169),(.55,.82,.010),'crimson',.002)
  g.box((0,1.82,-.167),(.64,.025,.014),'brass',.002)
 else:
  # Two circular shoulders meet in a gentle Gothic point; segmented closed stones.
  for side in [-1,1]:
   inner_end=math.acos(-.25/1.8);outer_end=math.acos(-.25/2.08)
   for i in range(12):
    t0=i/12+.0015;t1=(i+1)/12-.0015
    def xy(radius,end,t):
     a=math.pi+(end-math.pi)*t
     return (side*(-(.25+radius*math.cos(a))),3.84+radius*math.sin(a))
    q=[xy(1.8,inner_end,t0),xy(2.08,outer_end,t0),xy(2.08,outer_end,t1),xy(1.8,inner_end,t1)]
    g.loft([[(x,y,z) for x,y in q] for z in [-.15,.15]],'stone')
    # A thin iron edge and inset brass bead on the front, never coplanar.
    for radius0,radius1,mat,z0,z1 in [(2.044,2.076,'iron',.145,.156),(1.816,1.829,'brass',.150,.160)]:
     a0=xy(radius0,inner_end if radius0<1.9 else outer_end,t0)
     b0=xy(radius1,inner_end if radius1<1.9 else outer_end,t0)
     b1=xy(radius1,inner_end if radius1<1.9 else outer_end,t1)
     a1=xy(radius0,inner_end if radius0<1.9 else outer_end,t1)
     g.loft([[(x,y,z) for x,y in [a0,b0,b1,a1]] for z in [z0,z1]],mat)
  g.box((0,5.765,.004),(.18,.28,.308),'stone',.008)
  g.box((0,5.82,.154),(.11,.065,.012),'brass',.002)
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
print('S00_ENTRY_PORTAL_CREATED PASS',measurements)
