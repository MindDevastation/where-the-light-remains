"""Author the requested textured Archive core using the existing mesh/export pipeline."""
import argparse,ast,hashlib,json,math,sys
from pathlib import Path
import bpy,bmesh
from mathutils import Vector,Matrix
ROOT=Path(__file__).resolve().parents[1]
a=argparse.ArgumentParser();a.add_argument('--output',type=Path,required=True);a.add_argument('--pedestal',type=Path,required=True);args=a.parse_args(sys.argv[sys.argv.index('--')+1:])
out=args.output.resolve();assert not out.exists();out.mkdir(parents=True)
scene=bpy.context.scene;bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
scene.unit_settings.system='METRIC';scene.unit_settings.scale_length=1
library=ROOT/'game/art/textures/material_library';atlas=ROOT/'assets/3d/textures_source/archive_core_v1'
meta=json.loads((atlas/'atlas_manifest.json').read_text());native=json.loads((ROOT/'docs/production/evidence/archive_reconstruction/core-mount-access-20261008-final2/native.json').read_text())
materials={};images={}
def pbr(name,family,folder=library,prefix=None,metal=0,rough=.6):
 m=bpy.data.materials.get(name) or bpy.data.materials.new(name);m.use_nodes=True;m.use_backface_culling=True;n=m.node_tree.nodes;n.clear();outnode=n.new('ShaderNodeOutputMaterial');bs=n.new('ShaderNodeBsdfPrincipled');m.node_tree.links.new(bs.outputs['BSDF'],outnode.inputs['Surface']);bs.inputs['Metallic'].default_value=metal;bs.inputs['Roughness'].default_value=rough
 tex={}
 for kind in ['albedo','normal','orm']:
  p=folder/f'{prefix or "t_"+family}_{kind}.png'
  if not p.exists():continue
  im=bpy.data.images.load(str(p),check_existing=True);im.colorspace_settings.name='sRGB' if kind=='albedo' else 'Non-Color';images[p.as_posix()]=im;t=n.new('ShaderNodeTexImage');t.image=im;t.extension='REPEAT';tex[kind]=t
 if 'albedo' in tex:m.node_tree.links.new(tex['albedo'].outputs['Color'],bs.inputs['Base Color'])
 if 'normal' in tex:
  no=n.new('ShaderNodeNormalMap');no.inputs['Strength'].default_value=.3 if 'brass' in family else .65;m.node_tree.links.new(tex['normal'].outputs['Color'],no.inputs['Color']);m.node_tree.links.new(no.outputs['Normal'],bs.inputs['Normal'])
 if 'orm' in tex:
  separate=n.new('ShaderNodeSeparateColor');m.node_tree.links.new(tex['orm'].outputs['Color'],separate.inputs['Color']);m.node_tree.links.new(separate.outputs['Green'],bs.inputs['Roughness'])
  if metal:m.node_tree.links.new(separate.outputs['Blue'],bs.inputs['Metallic'])
 return m
for key,family,metal in [('stone','observatory_stone',0),('walnut','dark_walnut',0),('iron','dark_iron',1),('brass','aged_brass',1)]:materials[key]=pbr('m_'+family,family,metal=metal)
materials['atlas']=pbr('m_core_orbit_calibrated_brass','polished_brass',atlas,'t_core_orbit_brass',1)
# Reuse the accepted editable pedestal geometry,not a substitute primitive.
with bpy.data.libraries.load(str(args.pedestal.resolve()),link=False) as (src,dst):dst.objects=[n for n in src.objects if n=='sm_s01_core_pedestal']
base=next(o for o in dst.objects if o is not None);scene.collection.objects.link(base);base.name='Pedestal_Accepted';base.location=(0,0,.7)
base_geometry_hash=hashlib.sha256(b''.join(__import__('struct').pack('<fff',*v.co) for v in base.data.vertices)).hexdigest()
for slot in base.material_slots:
 family=next((f for f in ['observatory_stone','dark_walnut','dark_iron','aged_brass'] if f in slot.material.name),None)
 if family:slot.material=materials[{'observatory_stone':'stone','dark_walnut':'walnut','dark_iron':'iron','aged_brass':'brass'}[family]]
root=bpy.data.objects.new('ArchiveCentralMechanism',None);scene.collection.objects.link(root);base.parent=root
pivot=bpy.data.objects.new('CoreAssembly',None);scene.collection.objects.link(pivot);pivot.parent=root;pivot.location=(0,0,1.8)
pivot['gameplay_pivot_godot_m']=[0,1.8,0];pivot['clock_owner']='Existing shared Astrolabe yaw;no animation or input embedded'
recipe=ROOT/'tools/create_wing01_optics.py';defs=[n for n in ast.parse(recipe.read_text()).body if isinstance(n,(ast.ClassDef,ast.FunctionDef)) and n.name in {'convert','Geometry'}];exec(compile(ast.Module(body=defs,type_ignores=[]),str(recipe),'exec'),globals())
objects=[base];orbit_objects=[];upper_objects=[]
profile=[(-.005,-.014),(.005,-.014),(.007,-.012),(.007,.012),(.005,.014),(-.005,.014),(-.007,.012),(-.007,-.012)]
arc=[0]
for i in range(1,len(profile)):arc.append(arc[-1]+math.dist(profile[i-1],profile[i]))
perimeter=arc[-1]+math.dist(profile[-1],profile[0])
def finish(g,name,mats,parent=pivot):
 obj=g.object({'id':name,'stem':name,'joint':[0,0,0],'materials':mats});obj.parent=parent;objects.append(obj)
 return obj
for idx,(radius,region) in enumerate(zip([.58,.46,.34],meta['regions'])):
 basis=Matrix(native['native_bases'][idx]).transposed();g=Geometry();pts=[]
 for i in range(96):
  theta=math.tau*i/96
  for dr,width in profile:pts.append(tuple(basis@Vector(((radius+dr)*math.cos(theta),width,(radius+dr)*math.sin(theta)))))
 faces=[[i*8+j,((i+1)%96)*8+j,((i+1)%96)*8+(j+1)%8,i*8+(j+1)%8] for i in range(96) for j in range(8)];g.solid(pts,faces,'atlas')
 obj=finish(g,['Orbit_Outer','Orbit_Inner','Orbit_Third'][idx],['atlas']);orbit_objects.append(obj);upper_objects.append(obj)
 for face in obj.data.polygons:
  ids=[obj.data.loops[k].vertex_index for k in face.loop_indices];wrap=any(v//8==0 for v in ids) and any(v//8==95 for v in ids);profilewrap=any(v%8==0 for v in ids) and any(v%8==7 for v in ids)
  for k in face.loop_indices:
   v=obj.data.loops[k].vertex_index;i,j=divmod(v,8);u=(96 if wrap and i==0 else i)/96*region['u_pixels']/4096;vertical=(perimeter if profilewrap and j==0 else arc[j])*1024
   obj.data.uv_layers.active.data[k].uv=(u,1-(region['v_start']+vertical)/512)
 obj.data.calc_tangents();obj['radius_m']=radius;obj['role']='Visual orbit;not a puzzle input';obj['triangles']=len(obj.data.polygons)
# Reuse closed-loft geometry for the approved upper bridges and lathed spindle.
g=Geometry()
for route in native['bridge_routes']:
 path=[Vector(p)-Vector((0,1.8,0)) for p in route['path_world_m']];loops=[]
 for i,center in enumerate(path):
  direction=(path[min(i+1,len(path)-1)]-path[max(0,i-1)]).normalized();side=direction.cross(Vector((0,0,1)))
  if side.length<.01:side=direction.cross(Vector((1,0,0)))
  side.normalize();second=direction.cross(side).normalized();loops.append([tuple(center+side*x+second*y) for x,y in [(-.008,-.005),(.008,-.005),(.01,-.003),(.01,.003),(.008,.005),(-.008,.005),(-.01,.003),(-.01,-.003)]])
 g.loft(loops,'atlas')
def lathe(profile,material,n):g.loft([[(r*math.cos(math.tau*i/n),y-1.8,r*math.sin(math.tau*i/n)) for i in range(n)] for y,r in profile],material)
lathe([(1.39,.045),(1.405,.055),(1.78,.055),(1.8,.045)],'iron',16)
lathe([(1.39,.17),(1.40,.188),(1.43,.188),(1.44,.17)],'atlas',16)
# Small central bearing intentionally joins all upper bridges.
lathe([(1.775,.06),(1.785,.07),(1.815,.07),(1.825,.06)],'atlas',12)
mount=finish(g,'UpperMounts',['atlas','iron']);upper_objects.append(mount)
for face in mount.data.polygons:
 for k in face.loop_indices:
  uv=mount.data.uv_layers.active.data[k].uv;uv.y=.94+uv.y*.01
mount.data.calc_tangents()
# The image's luminous center is a material effect;no new scene light is exported.
from mathutils import Color
energy=bpy.data.materials.new('m_core_energy_gold');energy.use_nodes=True;bs=energy.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(.8,.31,.035,1);bs.inputs['Emission Color'].default_value=(1,.42,.06,1);bs.inputs['Emission Strength'].default_value=3.0;bs.inputs['Roughness'].default_value=.25
bpy.ops.mesh.primitive_uv_sphere_add(segments=24,ring_count=12,radius=.075);orb=bpy.context.object;orb.name='CoreEnergy';orb.parent=pivot;orb.location=(0,0,0);orb.data.materials.append(energy);objects.append(orb)
for f in orb.data.polygons:f.use_smooth=True
# Transparent shell and two noninteractive cage bands reproduce the central gem.
glass=bpy.data.materials.new('m_core_memory_glass');glass.use_nodes=True;bs=glass.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(.9,.72,.43,1);bs.inputs['Roughness'].default_value=.12;bs.inputs['Alpha'].default_value=.17;bs.inputs['Metallic'].default_value=.15;glass.surface_render_method='DITHERED'
bpy.ops.mesh.primitive_uv_sphere_add(segments=24,ring_count=12,radius=.105);shell=bpy.context.object;shell.name='CoreGlass';shell.parent=pivot;shell.location=(0,0,0);shell.data.materials.append(glass);objects.append(shell)
for f in shell.data.polygons:f.use_smooth=True
g=Geometry();g.ring(.109,.006,.006,'atlas',32);g2=Geometry();g2.ring(.109,.006,.006,'atlas',32)
for x,minus_z,y in g2.vertices:g.vertices.append((x,-y,-minus_z))
offset=len(g.vertices)-len(g2.vertices);g.faces.extend([[v+offset for v in f] for f in g2.faces]);g.slots.extend(g2.slots)
cage=finish(g,'CoreCage',['atlas'])
for face in cage.data.polygons:
 for k in face.loop_indices:cage.data.uv_layers.active.data[k].uv.y=.96
# Actual source counts and independent editable part hierarchy.
for obj in objects:
 if obj.type=='MESH':obj.data.calc_loop_triangles();obj['triangles']=len(obj.data.loop_triangles)
ring_triangles=sum(o['triangles'] for o in orbit_objects);mount_triangles=mount['triangles'];assert ring_triangles+mount_triangles<=6000 and mount_triangles<=600,(ring_triangles,mount_triangles)
# A nonexported studio rig renders the actual authored model.
preview=bpy.data.collections.new('PREVIEW_ONLY');scene.collection.children.link(preview)
def preview_link(obj):
 for c in list(obj.users_collection):c.objects.unlink(obj)
 preview.objects.link(obj)
def area(name,location,power,color,size):
 data=bpy.data.lights.new(name,'AREA');data.energy=power;data.color=color;data.shape='DISK';data.size=size;obj=bpy.data.objects.new(name,data);preview.objects.link(obj);obj.location=location;obj.rotation_euler=(Vector((0,0,1.2))-obj.location).to_track_quat('-Z','Y').to_euler()
area('Key',(3,-4,5),1100,(1,.85,.67),4);area('CoolRim',(-3,2,4),1400,(.39,.58,1),3);area('Fill',(-3,-2,2.5),650,(.7,.79,1),3)
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.005));floor=bpy.context.object;floor.name='PreviewGround';preview_link(floor);mat=bpy.data.materials.new('preview_floor');mat.diffuse_color=(.018,.027,.042,1);floor.data.materials.append(mat)
bpy.ops.object.camera_add(location=(3.5,-5.5,3.1));camera=bpy.context.object;camera.name='PreviewCamera';preview_link(camera);camera.rotation_euler=(Vector((0,0,1.12))-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.type='ORTHO';camera.data.ortho_scale=3.1;scene.camera=camera
scene.world.color=(.055,.055,.055);scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=48;scene.cycles.use_denoising=True;scene.render.resolution_x=1200;scene.render.resolution_y=1200;scene.render.resolution_percentage=100;scene.view_settings.view_transform='AgX'
bpy.ops.file.pack_all();source=out/'s01_archive_core_v1.blend';bpy.ops.wm.save_as_mainfile(filepath=str(source))
# Export only authored asset nodes;the source studio is excluded.
def export(path,selected):
 bpy.ops.object.select_all(action='DESELECT')
 for obj in selected:obj.select_set(True)
 bpy.context.view_layer.objects.active=selected[0]
 bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_yup=True,export_animations=False,export_tangents=True,export_cameras=False,export_lights=False,export_extras=True)
export(out/'s01_archive_core_v1.glb',[root,pivot]+objects)
# Separate canonical-pivot orbits allow existing pedestal/controls to stay in scene.
pivot.location=(0,0,0);export(out/'sm_s01_core_upper_v1.glb',[pivot]+upper_objects);pivot.location=(0,0,1.8)
scene.render.filepath=str(out/'s01_archive_core_preview.png');bpy.ops.render.render(write_still=True)
receipt={'status':'AUTHORED_EXPORTED_RENDERED','source_blender_version':bpy.app.version_string,'source_reference':'assets/3d/reference/s01_core_final_look_v1/s01_core_final_look_v1.png','ring_triangles':ring_triangles,'mount_triangles':mount_triangles,'full_triangles':sum(o['triangles'] for o in objects),'mesh_objects':len(objects),'part_names':[o.name for o in objects],'base_geometry_vertex_sha256':base_geometry_hash,'base_reused_from':str(args.pedestal),'upper_runtime_pivot_godot_m':[0,1.8,0],'root_scale':[1,1,1],'asset_geometry_only':True,'scene_lights_exported':False,'independent_animation_exported':False,'texture_sources':[p for p in images],'outputs':[{'file':p.name,'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size} for p in out.glob('*') if p.is_file()]}
(out/'authoring.json').write_text(json.dumps(receipt,indent=2)+'\n');print('ARCHIVE_CORE_MODEL_AUTHORED',json.dumps({'rings':ring_triangles,'mounts':mount_triangles,'full':receipt['full_triangles']}))
