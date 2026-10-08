"""Authored circular Hub paving with exact retained corridor ownership cutout."""
import ast,hashlib,json,math,sys
from pathlib import Path
import bpy,bmesh
from mathutils import Vector
root=Path(__file__).resolve().parents[1]
out=Path(sys.argv[sys.argv.index('--')+1]).resolve()
c=json.loads((root/'docs/production/s01_hub_floor.json').read_text())
source=out/c['source'];targets=[source]+[out/p['runtime'] for p in c['parts']]
assert not any(p.exists() for p in targets)
for p in targets:p.parent.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
for item in list(bpy.data.collections):bpy.data.collections.remove(item)
scene=bpy.context.scene;scene.unit_settings.system='METRIC';scene.unit_settings.scale_length=1
scene['asset_brief']='docs/production/S01_HUB_FLOOR.md'
scene['scope']='Original cosmetic floor; fixed collider/channels/core/corridor/approach'
materials={}
for f,color,metal,rough in [('stone',(.64,.57,.44,1),0,.78),('brass',(.36,.22,.055,1),1,.48)]:
 m=bpy.data.materials.new(Path(c['materials'][f]).stem);m.use_nodes=True;m.use_backface_culling=True
 for key,value in [('Base Color',color),('Metallic',metal),('Roughness',rough)]:m.node_tree.nodes.get('Principled BSDF').inputs[key].default_value=value
 materials[f]=m
recipe=root/'tools/create_wing01_optics.py'
defs=[n for n in ast.parse(recipe.read_text()).body if isinstance(n,(ast.ClassDef,ast.FunctionDef)) and n.name in {'convert','Geometry'}]
exec(compile(ast.Module(body=defs,type_ignores=[]),str(recipe),'exec'),globals())
def clean(poly):
 changed=True
 while changed and len(poly)>=3:
  changed=False
  for i,p in enumerate(poly):
   a=poly[i-1];b=poly[(i+1)%len(poly)]
   if math.dist(p,a)<1e-7 or abs((p[0]-a[0])*(b[1]-p[1])-(p[1]-a[1])*(b[0]-p[0]))<1e-10:
    poly=poly[:i]+poly[i+1:];changed=True;break
 return poly
def clip(poly,axis,bound,sign):
 if not poly:return []
 result=[]
 for a,b in zip(poly,poly[1:]+poly[:1]):
  da=sign*(a[axis]-bound);db=sign*(b[axis]-bound)
  if da>=-1e-9:result.append(a)
  if (da>=0)!=(db>=0):
   t=da/(da-db);result.append(tuple(a[j]+(b[j]-a[j])*t for j in range(2)))
 return clean(result)
def allowed(poly):
 yield clip(poly,1,-8,1)
 lower=clip(poly,1,-8,-1)
 yield clip(lower,0,-2,-1)
 yield clip(lower,0,2,1)
g=Geometry()
def solid(poly,bottom,top,material):
 if len(poly)<3:return
 area=abs(sum(a[0]*b[1]-b[0]*a[1] for a,b in zip(poly,poly[1:]+poly[:1])))/2
 if area<1e-8:return
 g.loft([[(x,y,z) for x,z in poly] for y in [bottom,top]],material)
circle=[(c['source_radius']*math.sin(i*2*math.pi/c['segments']),c['source_radius']*math.cos(i*2*math.pi/c['segments'])) for i in range(c['segments'])]
for p in allowed(circle):solid(p,-.145,.149,'stone')
for x in range(-10,10):
 for z in range(-10,10):
  poly=circle[:]
  for axis,bound,sign in [(0,x+.009,1),(0,x+.991,-1),(1,z+.009,1),(1,z+.991,-1)]:poly=clip(poly,axis,bound,sign)
  for p in allowed(poly):solid(p,-.140,c['stone_top_local_y'],'stone')
for radius in [1.48,4.10,7.40]:
 for i in range(c['inlay_segments']):
  a=i*2*math.pi/c['inlay_segments'];b=(i+1)*2*math.pi/c['inlay_segments']
  poly=[(r*math.sin(t),r*math.cos(t)) for r,t in [(radius-.014,a),(radius+.014,a),(radius+.014,b),(radius-.014,b)]]
  for p in allowed(poly):solid(p,.1518,c['inlay_top_local_y'],'brass')
part=c['parts'][0];obj=g.object(part)
bpy.ops.wm.save_as_mainfile(filepath=str(source))
bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj
assert bpy.ops.export_scene.gltf(filepath=str(out/part['runtime']),export_format='GLB',use_selection=True,export_yup=True,export_animations=False,export_tangents=True,export_cameras=False,export_lights=False,export_extras=False)=={'FINISHED'}
obj.data.calc_loop_triangles();tri=len(obj.data.loop_triangles);assert tri<=part['triangle_ceiling']
manifest={'payloads':[{'path':p.relative_to(out).as_posix(),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in targets],'measurements':[{'stem':part['stem'],'triangles':tri,'surfaces':len(obj.data.materials)}],'geometry_helper_sha256':hashlib.sha256(recipe.read_bytes()).hexdigest()}
(out/'payload_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('S01_HUB_FLOOR_CREATED PASS',manifest['measurements'])
