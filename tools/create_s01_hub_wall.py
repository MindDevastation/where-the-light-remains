"""Original two-sided wall skin inside the eight fixed Hub wall bodies."""
import ast,hashlib,json,math,sys
from pathlib import Path
import bpy,bmesh
from mathutils import Vector
root=Path(__file__).resolve().parents[1]
out=Path(sys.argv[sys.argv.index('--')+1]).resolve()
c=json.loads((root/'docs/production/s01_hub_wall.json').read_text())
source=out/c['source'];targets=[source]+[out/p['runtime'] for p in c['parts']]
assert not any(p.exists() for p in targets)
for p in targets:p.parent.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
for item in list(bpy.data.collections):bpy.data.collections.remove(item)
scene=bpy.context.scene;scene.unit_settings.system='METRIC';scene.unit_settings.scale_length=1
scene['asset_brief']='docs/production/S01_HUB_WALL.md'
scene['scope']='Cosmetic two-sided master; original body and five route apertures unchanged'
materials={}
for f,color,metal,rough in [('stone',(.64,.57,.44,1),0,.78),('walnut',(.12,.045,.016,1),0,.65),('iron',(.055,.062,.07,1),1,.7),('brass',(.36,.22,.055,1),1,.48),('navy',(.023,.048,.105,1),0,.92)]:
 m=bpy.data.materials.new(Path(c['materials'][f]).stem);m.use_nodes=True;m.use_backface_culling=True
 for key,value in [('Base Color',color),('Metallic',metal),('Roughness',rough)]:m.node_tree.nodes.get('Principled BSDF').inputs[key].default_value=value
 materials[f]=m
recipe=root/'tools/create_wing01_optics.py'
defs=[n for n in ast.parse(recipe.read_text()).body if isinstance(n,(ast.ClassDef,ast.FunctionDef)) and n.name in {'convert','Geometry'}]
exec(compile(ast.Module(body=defs,type_ignores=[]),str(recipe),'exec'),globals())
g=Geometry();g.box((0,0,0),(5.776,4.784,.286),'stone',.008)
def fitting(center,size,material):
 x,y,z=center;a,b,d=[v/2 for v in size]
 g.loft([[(x-a,y-b,h),(x+a,y-b,h),(x+a,y+b,h),(x-a,y+b,h)] for h in [z-d,z+d]],material)
for side in [-1,1]:
 for row in range(9):
  for col in range(4):
   # Quiet repeated ashlar relief; no decorative route symbols.
   x=(col-1.5)*1.427;y=-2.115+row*.529
   g.box((x,y,side*.126),(1.411,.513,.050),'stone',.006)
 for x in [-2.56,2.56]:
  g.box((x,-.06,side*.119),(.23,4.52,.090),'walnut',.008)
  for y in [-1.79,.11,1.92]:
   fitting((x,y,side*.166),(.254,.060,.015),'iron')
   fitting((x,y,side*.173),(.025,.025,.004),'brass')
 for i in range(4):
  x=(i-1.5)*1.432
  for y,height in [(-2.20,.24),(2.05,.30)]:
   g.box((x,y,side*.111),(1.420,height,.110),'walnut',.009)
   fitting((x,y,side*.166),(.055,height-.020,.016),'iron')
   for dy in [-height*.30,height*.30]:
    fitting((x,y+dy,side*.173),(.024,.024,.004),'brass')
 g.box((0,1.18,side*.165),(.66,1.10,.018),'iron',.003)
 g.box((0,1.18,side*.173),(.572,1.012,.003),'navy',.001)
 fitting((0,1.70,side*.173),(.612,.020,.004),'brass')
part=c['parts'][0];obj=g.object(part)
bpy.ops.wm.save_as_mainfile(filepath=str(source))
bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj
assert bpy.ops.export_scene.gltf(filepath=str(out/part['runtime']),export_format='GLB',use_selection=True,export_yup=True,export_animations=False,export_tangents=True,export_cameras=False,export_lights=False,export_extras=False)=={'FINISHED'}
obj.data.calc_loop_triangles();tri=len(obj.data.loop_triangles);assert tri<=part['triangle_ceiling']
manifest={'payloads':[{'path':p.relative_to(out).as_posix(),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in targets],'measurements':[{'stem':part['stem'],'triangles':tri,'surfaces':len(obj.data.materials)}],'geometry_helper_sha256':hashlib.sha256(recipe.read_bytes()).hexdigest()}
(out/'payload_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('S01_HUB_WALL_CREATED PASS',manifest['measurements'])
