"""Reopen the deliverable in a fresh Blender process and audit actual geometry."""
import argparse,hashlib,json,math,sys
from pathlib import Path
import bpy,bmesh
from mathutils import Vector
p=argparse.ArgumentParser();p.add_argument('--input',type=Path,required=True)
p.add_argument('--output',type=Path,required=True);p.add_argument('--closeup',action='store_true')
a=p.parse_args(sys.argv[sys.argv.index('--')+1:]);a.output.mkdir(parents=True,exist_ok=True)
source=a.input.suffix=='.blend'
if source:bpy.ops.wm.open_mainfile(filepath=str(a.input.resolve()))
else:
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 bpy.ops.import_scene.gltf(filepath=str(a.input.resolve()))
root=bpy.data.objects['ArchiveCentralMechanism'];pivot=bpy.data.objects['CoreAssembly']
parts=[o for o in root.children_recursive if o.type=='MESH']
assert len(parts)==7,len(parts)
assert abs(pivot.location.z-1.02)<1e-5,pivot.location
rows=[];bounds=[];used_images={}
for obj in parts:
 assert all(abs(v-1)<1e-6 for v in obj.scale),(obj.name,tuple(obj.scale))
 assert not obj.modifiers,(obj.name,'unexpected modifier')
 mesh=obj.data;mesh.calc_loop_triangles();assert mesh.uv_layers.active,obj.name
 mesh.calc_tangents()
 assert all(math.isfinite(c) for v in mesh.vertices for c in v.co)
 assert all(math.isfinite(c) for v in mesh.uv_layers.active.data for c in v.uv)
 assert all(math.isfinite(c) for loop in mesh.loops for c in loop.tangent)
 zero_area=0;zero_uv=0
 for tri in mesh.loop_triangles:
  x,y,z=[mesh.vertices[i].co for i in tri.vertices]
  zero_area+=int((y-x).cross(z-x).length<1e-10)
  x,y,z=[mesh.uv_layers.active.data[i].uv for i in tri.loops]
  zero_uv+=int(abs((y.x-x.x)*(z.y-x.y)-(y.y-x.y)*(z.x-x.x))<1e-12)
 assert zero_area==0,(obj.name,'zero area',zero_area)
 assert zero_uv==0,(obj.name,'zero UV',zero_uv)
 bm=bmesh.new();bm.from_mesh(mesh);nonmanifold=sum(not e.is_manifold for e in bm.edges);bm.free()
 if source:assert nonmanifold==0,(obj.name,'nonmanifold',nonmanifold)
 for slot in obj.material_slots:
  assert slot.material and slot.material.use_nodes,obj.name
  for node in slot.material.node_tree.nodes:
   if node.type=='TEX_IMAGE' and node.image:
    im=node.image;assert im.size[0]>0 and im.size[1]>0,im.name
    if source:assert im.packed_file,im.name
    used_images[im.name]={'size':list(im.size),'packed':bool(im.packed_file)}
 for corner in obj.bound_box:bounds.append(obj.matrix_world@Vector(corner))
 rows.append({'part':obj.name,'triangles':len(mesh.loop_triangles),'materials':len(mesh.materials),
              'nonmanifold_edges':nonmanifold,'zero_geometry_triangles':zero_area,'zero_uv_triangles':zero_uv})
total=sum(r['triangles'] for r in rows);assert total==29780,total
assert len(used_images)==12,len(used_images)
minimum=[min(v[i] for v in bounds) for i in range(3)];maximum=[max(v[i] for v in bounds) for i in range(3)]
report={'status':'PASS','route':'fresh source reopen' if source else 'fresh GLB import',
        'blender':bpy.app.version_string,'file_sha256':hashlib.sha256(a.input.read_bytes()).hexdigest(),
        'mesh_parts':rows,'triangles':total,'used_images':used_images,
        'bounds_blender_m':{'min':minimum,'max':maximum},'scale':[1,1,1],
        'pivot_godot_m':[0,1.02,0],'note':'GLB vertex splits at UV seams are expected; watertightness is checked on the source'}
(a.output/('source_reopen.json' if source else 'glb_reimport.json')).write_text(json.dumps(report,indent=2)+'\n')
if source:
 bpy.ops.object.select_all(action='DESELECT')
 for obj in [root,pivot]+parts:obj.select_set(True)
 bpy.context.view_layer.objects.active=parts[0]
 bpy.ops.export_scene.gltf(filepath=str(a.output/'fresh_reopen_export.glb'),export_format='GLB',use_selection=True,
                          export_yup=True,export_tangents=True,export_animations=False,export_cameras=False,export_lights=False)
 if a.closeup:
  scene=bpy.context.scene
  for obj in bpy.data.collections['PREVIEW_ONLY'].objects:obj.hide_set(False)
  scene.camera.location=(-2.8,-1.7,2.4)
  scene.camera.rotation_euler=(Vector((0,0,1.02))-scene.camera.location).to_track_quat('-Z','Y').to_euler()
  scene.camera.data.ortho_scale=1.35;scene.cycles.samples=32
  scene.render.resolution_x=1000;scene.render.resolution_y=1000
  scene.render.filepath=str(a.output/'source_reopen_closeup.png');bpy.ops.render.render(write_still=True)
print('ARCHIVE_CORE_REOPEN_PASS',json.dumps({'source':source,'triangles':total,'images':len(used_images)}))
