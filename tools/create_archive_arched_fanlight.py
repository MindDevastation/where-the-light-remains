"""Original bounded fanlight in existing gate header; reuse accepted Geometry."""
import ast,hashlib,json,math,sys
from pathlib import Path
import bpy,bmesh
from mathutils import Vector

root=Path(__file__).resolve().parents[1]
out=Path(sys.argv[sys.argv.index('--')+1]).resolve()
c=json.loads((root/'docs/production/archive_arched_fanlight.json').read_text())
source=out/c['source']
targets=[source]+[out/p['runtime'] for p in c['parts']]
assert not any(p.exists() for p in targets)
for p in targets:p.parent.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
for item in list(bpy.data.collections):bpy.data.collections.remove(item)
scene=bpy.context.scene;scene.unit_settings.system='METRIC';scene.unit_settings.scale_length=1
scene['asset_brief']='docs/production/ARCHIVE_ARCHED_FANLIGHT.md'
scene['scope']='Original static header fanlight; original door/ghost/route/puzzle/save unchanged'
materials={}
for family,color,metal,rough in [('stone',(.64,.57,.44,1),0,.78),('iron',(.055,.062,.07,1),1,.7),('brass',(.36,.22,.055,1),1,.48),('glass',(.8,.9,.98,1),0,.08)]:
 m=bpy.data.materials.new(Path(c['materials'][family]).stem);m.use_nodes=True;m.use_backface_culling=True
 for key,value in [('Base Color',color),('Metallic',metal),('Roughness',rough)]:m.node_tree.nodes.get('Principled BSDF').inputs[key].default_value=value
 materials[family]=m
recipe=root/'tools/create_wing01_optics.py'
defs=[n for n in ast.parse(recipe.read_text()).body if isinstance(n,(ast.ClassDef,ast.FunctionDef)) and n.name in {'convert','Geometry'}]
exec(compile(ast.Module(body=defs,type_ignores=[]),str(recipe),'exec'),globals())
g=Geometry();segments=24;center=3.30
def extrude(outline,z0,z1,family):
 g.loft([[(x,y,z) for x,y in outline] for z in [z0,z1]],family)
for i in range(segments):
 a=i*math.pi/segments;b=(i+1)*math.pi/segments
 outer=[(1.65*math.cos(t),center+1.40*math.sin(t)) for t in [a,b]]
 inner=[(1.46*math.cos(t),center+1.20*math.sin(t)) for t in [a,b]]
 extrude([outer[0],outer[1],inner[1],inner[0]],.176,.276,'stone')
 extrude([outer[0],outer[1],(outer[1][0],4.78),(outer[0][0],4.78)],.176,.276,'stone')
 # A contained brass arch lip; no star/count/glyph decoration.
 lip_o=[(1.49*math.cos(t),center+1.23*math.sin(t)) for t in [a,b]]
 lip_i=[(1.465*math.cos(t),center+1.205*math.sin(t)) for t in [a,b]]
 extrude([lip_o[0],lip_o[1],lip_i[1],lip_i[0]],.265,.274,'brass')
g.box((0,3.26,.226),(3.40,.08,.10),'stone',.004)
for sign in [-1,1]:g.box((sign*1.675,4.04,.226),(.05,1.48,.10),'stone',.003)
pane=[(1.455*math.cos(i*math.pi/segments),center+1.195*math.sin(i*math.pi/segments)) for i in range(segments+1)]
extrude(pane,.199,.207,'glass')
g.box((0,3.326,.25),(2.96,.052,.042),'iron',.003)
for x in [-.75,0,.75]:
 height=1.195*math.sqrt(1-(x/1.455)**2)
 g.box((x,center+height/2,.25),(.044,height,.045),'iron',.003)
 g.box((x,center+height/2,.275),(.012,height-.03,.002),'brass',.0003)
part=c['parts'][0];obj=g.object(part)
bpy.ops.wm.save_as_mainfile(filepath=str(source))
bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj
assert bpy.ops.export_scene.gltf(filepath=str(out/part['runtime']),export_format='GLB',use_selection=True,export_yup=True,export_animations=False,export_tangents=True,export_cameras=False,export_lights=False,export_extras=False)=={'FINISHED'}
obj.data.calc_loop_triangles();tri=len(obj.data.loop_triangles);assert tri<=part['triangle_ceiling']
manifest={'payloads':[{'path':p.relative_to(out).as_posix(),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in targets],'measurements':[{'stem':part['stem'],'triangles':tri,'surfaces':len(obj.data.materials)}],'geometry_helper_sha256':hashlib.sha256(recipe.read_bytes()).hexdigest()}
(out/'payload_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('ARCHIVE_ARCHED_FANLIGHT_CREATED PASS',manifest['measurements'])
