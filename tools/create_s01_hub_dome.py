"""Original Hub upper drum/dome within pinned original route and camera contract."""
import ast,hashlib,json,math,sys
from pathlib import Path
import bpy,bmesh
from mathutils import Vector
root=Path(__file__).resolve().parents[1]
out=Path(sys.argv[sys.argv.index('--')+1]).resolve()
c=json.loads((root/'docs/production/s01_hub_dome.json').read_text())
source=out/c['source'];targets=[source]+[out/p['runtime'] for p in c['parts']]
assert not any(p.exists() for p in targets)
for p in targets:p.parent.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
for item in list(bpy.data.collections):bpy.data.collections.remove(item)
scene=bpy.context.scene;scene.unit_settings.system='METRIC';scene.unit_settings.scale_length=1
scene['asset_brief']='docs/production/S01_HUB_DOME.md'
scene['scope']='Original cosmetic upper drum/dome; original wall/route/portal/rail bodies and lights unchanged'
materials={}
for f,color,metal,rough in [('stone',(.64,.57,.44,1),0,.78),('walnut',(.12,.045,.016,1),0,.65),('iron',(.055,.062,.07,1),1,.7),('brass',(.36,.22,.055,1),1,.48),('glass',(.8,.9,.98,1),0,.08),('sky',(.018,.035,.09,1),0,1)]:
 m=bpy.data.materials.new(Path(c['materials'][f]).stem);m.use_nodes=True;m.use_backface_culling=True
 for key,value in [('Base Color',color),('Metallic',metal),('Roughness',rough)]:m.node_tree.nodes.get('Principled BSDF').inputs[key].default_value=value
 materials[f]=m
recipe=root/'tools/create_wing01_optics.py'
defs=[n for n in ast.parse(recipe.read_text()).body if isinstance(n,(ast.ClassDef,ast.FunctionDef)) and n.name in {'convert','Geometry'}]
exec(compile(ast.Module(body=defs,type_ignores=[]),str(recipe),'exec'),globals())
n=c['segments'];lat=c['latitude_segments'];end=math.acos(.20/c['radius'])
def annular(g,profile,material,cap_front=False):
 points=[]
 for i in range(n):
  a=2*math.pi*i/n
  for r,y in profile:
   if cap_front and math.cos(a)>0:r=min(r,c['front_cap_z']/math.cos(a))
   points.append((r*math.sin(a),y,r*math.cos(a)))
 count=len(profile)
 faces=[[i*count+j,((i+1)%n)*count+j,((i+1)%n)*count+(j+1)%count,i*count+(j+1)%count] for i in range(n) for j in range(count)]
 g.solid(points,faces,material)
def placed_box(g,center,size,material,wall,bevel=.006):
 q=Geometry();q.box(center,size,material,bevel)
 a=wall['yaw'];co=math.cos(a);si=math.sin(a);p=wall['center']
 pts=[]
 for x,minus_z,y in q.vertices:
  z=-minus_z;pts.append((p[0]+co*x+si*z,y,p[2]-si*x+co*z))
 g.solid(pts,q.faces,material)
objects=[]
for part in c['parts']:
 g=Geometry()
 if part['id']=='drum':
  for w in c['walls']:
   width=w['size'][0]
   placed_box(g,(0,5.37,0),(width-.012,1.138,.30),'stone',w,.008)
   columns=max(2,int(width/.82));pitch=(width-.03)/columns
   for row in range(2):
    for col in range(columns):
     placed_box(g,((col-(columns-1)/2)*pitch,5.085+row*.57,-.145),(pitch-.018,.548,.058),'stone',w,.005)
   placed_box(g,(0,5.975,0),(width-.024,.145,.31),'walnut',w,.008)
   for x in [-width*.38,width*.38]:
    placed_box(g,(x,5.975,-.158),(.066,.14,.024),'iron',w,.003)
    for y in [5.94,6.005]:placed_box(g,(x,y,-.174),(.026,.026,.008),'brass',w,.001)
  for i in range(5):
   a=i*2*math.pi/5
   w={'yaw':a,'center':[-8*math.sin(a),0,-8*math.cos(a)]}
   placed_box(g,(0,5.37,0),(3.4,1.138,.32),'stone',w,.008)
  annular(g,[(c['outer_radius'],5.95),(c['outer_radius'],6.05),(7.55,6.20),(7.49,5.95)],'stone',True)
 elif part['id']=='frame':
  for i in range(n):
   a=i*2*math.pi/n;layers=[]
   for j in range(lat+1):
    t=end*j/lat;r=c['radius']*math.cos(t);y=c['spring_y']+c['rise']*math.sin(t)
    layers.append([((r+dr)*math.sin(a+da),y+dy,(r+dr)*math.cos(a+da)) for dr,dy,da in [(-.035,-.045,-.011),(.045,.045,-.011),(.045,.045,.011),(-.035,-.045,.011)]])
   g.loft(layers,'walnut')
  for t in [.46,.99]:
   r=c['radius']*math.cos(t);y=c['spring_y']+c['rise']*math.sin(t)
   annular(g,[(r+.008,y-.030),(r+.075,y-.030),(r+.075,y+.030),(r+.008,y+.030)],'iron')
   annular(g,[(r+.076,y-.012),(r+.091,y-.012),(r+.091,y+.012),(r+.076,y+.012)],'brass')
  annular(g,[(7.45,6.155),(7.57,6.155),(7.57,6.24),(7.45,6.24)],'iron')
  annular(g,[(.18,9.28),(.25,9.28),(.25,9.36),(.18,9.36)],'brass')
 else:
  sky=part['id']=='sky';radius=7.46 if sky else 7.50;rise=3.075 if sky else 3.10
  offset=.020 if sky else .010
  for i in range(n):
   a0=2*math.pi*i/n+.009;a1=2*math.pi*(i+1)/n-.009
   for j in range(lat):
    t0=end*j/lat+.0007;t1=end*(j+1)/lat-.0007
    layers=[]
    for inner in [0,1]:
     r=radius-inner*offset;h=rise-inner*offset
     layers.append([(r*math.cos(t)*math.sin(a),c['spring_y']+h*math.sin(t),r*math.cos(t)*math.cos(a)) for t,a in [(t0,a0),(t0,a1),(t1,a1),(t1,a0)]])
    g.loft(layers,part['id'])
  y=c['spring_y']+rise
  g.loft([[(.215*math.sin(i*math.pi/12),h,.215*math.cos(i*math.pi/12)) for i in range(24)] for h in [y-.022,y-.010]],part['id'])
 obj=g.object({'stem':part['stem'],'id':part['id'],'materials':part['materials'],'joint':[0,0,0]});objects.append(obj)
bpy.ops.wm.save_as_mainfile(filepath=str(source))
measurements=[]
for obj,part in zip(objects,c['parts']):
 bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj
 target=out/part['runtime']
 assert bpy.ops.export_scene.gltf(filepath=str(target),export_format='GLB',use_selection=True,export_yup=True,export_animations=False,export_tangents=True,export_cameras=False,export_lights=False,export_extras=False)=={'FINISHED'}
 obj.data.calc_loop_triangles();tri=len(obj.data.loop_triangles);assert tri<=part['triangle_ceiling']
 measurements.append({'stem':part['stem'],'triangles':tri,'surfaces':len(obj.data.materials)})
manifest={'payloads':[{'path':p.relative_to(out).as_posix(),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in targets],'measurements':measurements,'geometry_helper_sha256':hashlib.sha256(recipe.read_bytes()).hexdigest()}
(out/'payload_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('S01_HUB_DOME_CREATED PASS',measurements)
