"""Original shared lift-gate skin within the fixed existing barrier body."""
import ast,hashlib,json,math,sys
from pathlib import Path
import bpy,bmesh
from mathutils import Vector
root=Path(__file__).resolve().parents[1]
out=Path(sys.argv[sys.argv.index('--')+1]).resolve()
c=json.loads((root/'docs/production/archive_wing_gate.json').read_text())
source=out/c['source'];targets=[source]+[out/p['runtime'] for p in c['parts']]
assert not any(p.exists() for p in targets)
for p in targets:p.parent.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
for item in list(bpy.data.collections):bpy.data.collections.remove(item)
scene=bpy.context.scene;scene.unit_settings.system='METRIC';scene.unit_settings.scale_length=1
scene['asset_brief']='docs/production/ARCHIVE_WING_GATE.md'
scene['scope']='Immutable shared cosmetic skin; original gate bindings/body/timing/state/save'
materials={}
for f,color,metal,rough in [('walnut',(.12,.045,.016,1),0,.65),('iron',(.055,.062,.07,1),1,.7),('brass',(.36,.22,.055,1),1,.48)]:
 m=bpy.data.materials.new(Path(c['materials'][f]).stem);m.use_nodes=True;m.use_backface_culling=True
 for key,value in [('Base Color',color),('Metallic',metal),('Roughness',rough)]:m.node_tree.nodes.get('Principled BSDF').inputs[key].default_value=value
 materials[f]=m
recipe=root/'tools/create_wing01_optics.py'
defs=[n for n in ast.parse(recipe.read_text()).body if isinstance(n,(ast.ClassDef,ast.FunctionDef)) and n.name in {'convert','Geometry'}]
exec(compile(ast.Module(body=defs,type_ignores=[]),str(recipe),'exec'),globals())
g=Geometry();g.box((0,0,0),(3.384,3.184,.150),'walnut',.008)
for side in [-1,1]:
 for i in range(10):
  x=(i-4.5)*.318
  g.box((x,0,side*.078),(.306,3.142,.068),'walnut',.005)
 for x in [-1.595,1.595]:
  g.box((x,0,side*.084),(.160,3.17,.055),'walnut',.005)
  g.box((x,0,side*.115),(.056,3.10,.008),'iron',.002)
 for y in [-.98,.98]:
  for i in range(4):
   x=(i-1.5)*.815
   g.box((x,y,side*.115),(.806,.100,.008),'iron',.002)
   for dx in [-.31,.31]:
    g.loft([[(x+dx+.014*math.cos(k*math.pi/4),y+.014*math.sin(k*math.pi/4),z) for k in range(8)] for z in [side*.117,side*.1195]],'brass')
part=c['parts'][0];obj=g.object(part)
bpy.ops.wm.save_as_mainfile(filepath=str(source))
bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj
assert bpy.ops.export_scene.gltf(filepath=str(out/part['runtime']),export_format='GLB',use_selection=True,export_yup=True,export_animations=False,export_tangents=True,export_cameras=False,export_lights=False,export_extras=False)=={'FINISHED'}
obj.data.calc_loop_triangles();tri=len(obj.data.loop_triangles);assert tri<=part['triangle_ceiling']
manifest={'payloads':[{'path':p.relative_to(out).as_posix(),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in targets],'measurements':[{'stem':part['stem'],'triangles':tri,'surfaces':len(obj.data.materials)}],'geometry_helper_sha256':hashlib.sha256(recipe.read_bytes()).hexdigest()}
(out/'payload_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('ARCHIVE_WING_GATE_CREATED PASS',manifest['measurements'])
