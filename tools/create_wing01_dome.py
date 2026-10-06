"""Author original dome coverage; preserve every accepted ceiling component.

blender --background --factory-startup --python-exit-code 1
  --python tools/create_wing01_dome.py -- /absolute/empty/output-root
"""
import ast
import hashlib
import json
import math
from pathlib import Path
import struct
import sys
import bpy
import bmesh
from mathutils import Vector

root = Path(__file__).resolve().parents[1]
contract = json.loads((root/'docs/production/wing01_dome_coverage.json').read_text())
out = Path(sys.argv[sys.argv.index('--')+1]).resolve()
targets = [out/contract['source']] + [out/('game/art/meshes/archive_kit/'+p['stem']+'.glb') for p in contract['parts']]
assert not any(p.exists() for p in targets), 'Use an empty output root'
for p in targets:
    p.parent.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
for collection in list(bpy.data.collections):
    bpy.data.collections.remove(collection)
scene = bpy.context.scene
scene.unit_settings.system = 'METRIC'
scene.unit_settings.scale_length = 1
scene['asset_brief'] = 'docs/production/WING01_DOME_COVERAGE.md'
scene['source_recipe'] = 'tools/create_wing01_dome.py'
materials = {}
for family,color,metal,rough in [('iron',(.055,.062,.07,1),1,.7),
 ('brass',(.36,.22,.055,1),1,.48),('glass',(.8,.9,.98,1),0,.08),('sky',(.018,.045,.13,1),0,1)]:
    m=bpy.data.materials.new(Path(contract['materials'][family]).stem)
    m.use_nodes=True
    m.use_backface_culling=True
    shader=m.node_tree.nodes.get('Principled BSDF')
    for key,value in [('Base Color',color),('Metallic',metal),('Roughness',rough)]:
        shader.inputs[key].default_value=value
    materials[family]=m
recipe=root/'tools/create_wing01_optics.py'
definitions=[n for n in ast.parse(recipe.read_text()).body
 if isinstance(n,(ast.ClassDef,ast.FunctionDef)) and n.name in {'convert','Geometry'}]
assert len(definitions)==2
exec(compile(ast.Module(body=definitions,type_ignores=[]),str(recipe),'exec'),globals())


def frame(g):
    for ray in range(contract['meridian_count']):
        if ray % 4 == 0:
            continue  # Accepted cardinal ribs remain separate, byte-identical.
        phi=2*math.pi*ray/contract['meridian_count']
        radial=Vector((5*math.cos(phi),0,6*math.sin(phi)))
        radius=radial.length
        direction=radial.normalized()
        lateral=Vector((direction.z,0,-direction.x))
        stop=math.acos(.25/radius)
        for family,width,depth,offset in [('iron',.16,.16,0),('brass',.012,.026,-.081)]:
            loops=[]
            for step in range(contract['meridian_segments']+1):
                t=stop*step/contract['meridian_segments']
                center=radial*math.cos(t)+Vector((0,1.5+4*math.sin(t),0))
                normal=(direction*(4*math.cos(t))+Vector((0,radius*math.sin(t),0))).normalized()
                w,d=width/2,depth/2
                if family=='iron':
                    bevel=.008
                    profile=[(-w+bevel,-d),(w-bevel,-d),(w,-d+bevel),(w,d-bevel),
                             (w-bevel,d),(-w+bevel,d),(-w,d-bevel),(-w,-d+bevel)]
                else:
                    profile=[(-w,-d),(w,-d),(w,d),(-w,d)]
                loops.append([tuple(center+normal*(u+offset)+lateral*v) for u,v in profile])
            g.loft(loops,family)
    for t in contract['tie_angles_radians']:
        loops=[]
        for step in range(64):
            phi=2*math.pi*step/64
            radial=Vector((5*math.cos(phi),0,6*math.sin(phi)))
            direction=radial.normalized()
            normal=(direction*(4*math.cos(t))+Vector((0,radial.length*math.sin(t),0))).normalized()
            tangent=(-radial*math.sin(t)+Vector((0,4*math.cos(t),0))).normalized()
            center=radial*math.cos(t)+Vector((0,1.5+4*math.sin(t),0))+normal*.035
            loops.append([tuple(center+normal*u+tangent*v) for u,v in [(-.036,-.032),(.036,-.032),(.036,.032),(-.036,.032)]])
        vertices=[p for loop in loops for p in loop]
        faces=[[i*4+j,((i+1)%64)*4+j,((i+1)%64)*4+(j+1)%4,i*4+(j+1)%4] for i in range(64) for j in range(4)]
        g.solid(vertices,faces,'iron')


def shell(g,part):
    n,bands=contract['shell_longitudes'],contract['shell_latitudes']
    vertices=[]
    for axes,rise in [(part['outer_axes_m'],part['outer_rise_m']),
                      (part['inner_axes_m'],part['inner_rise_m'])]:
        for band in range(bands):
            t=math.pi/2*band/bands
            for i in range(n):
                phi=2*math.pi*i/n
                vertices.append((axes[0]*math.cos(phi)*math.cos(t),part['base_y_m']+rise*math.sin(t),axes[1]*math.sin(phi)*math.cos(t)))
        vertices.append((0,part['base_y_m']+rise,0))
    stride=n*bands+1
    faces=[]
    for layer in range(2):
        start=layer*stride
        for band in range(bands-1):
            for i in range(n):
                j=(i+1)%n
                faces.append([start+band*n+i,start+band*n+j,start+(band+1)*n+j,start+(band+1)*n+i])
        pole=start+n*bands
        for i in range(n):
            faces.append([start+(bands-1)*n+i,start+(bands-1)*n+(i+1)%n,pole])
    for i in range(n):
        j=(i+1)%n
        faces.append([i,j,stride+j,stride+i])
    g.solid(vertices,faces,part['materials'][0])


objects=[]
measurements=[]
for part in contract['parts']:
    geometry=Geometry()
    if part['id']=='frame':
        frame(geometry)
    else:
        shell(geometry,part)
    obj=geometry.object(part)
    if part['id']=='glass':
        # Continuous curved glazing needs continuous shading normals. Flat
        # triangle normals turned a practical's reflection into a checker grid.
        for polygon in obj.data.polygons:
            polygon.use_smooth=True
        obj.data.update()
        obj.data.calc_tangents(uvmap='UVMap')
    obj.data.calc_loop_triangles()
    count=len(obj.data.loop_triangles)
    assert count<=part['triangle_ceiling'],(part['id'],count)
    measurements.append({'id':part['id'],'triangles':count,'surfaces':len(obj.data.materials)})
    objects.append(obj)
assert bpy.ops.wm.save_as_mainfile(filepath=str(targets[0]))=={'FINISHED'}
for obj,target,part in zip(objects,targets[1:],contract['parts']):
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active=obj
    assert bpy.ops.export_scene.gltf(filepath=str(target),export_format='GLB',use_selection=True,
      export_yup=True,export_animations=False,export_tangents=True,export_cameras=False,
      export_lights=False,export_extras=False)=={'FINISHED'}
    raw=target.read_bytes()
    assert struct.unpack_from('<4sII',raw)==(b'glTF',2,len(raw))
    size,kind=struct.unpack_from('<II',raw,12)
    assert kind==0x4e4f534a
    doc=json.loads(raw[20:20+size])
    assert len(doc['nodes'])==len(doc['meshes'])==1
    assert not any(doc.get(k) for k in ('animations','skins','images','textures'))
    assert len(doc['meshes'][0]['primitives'])==len(part['materials'])
    for primitive in doc['meshes'][0]['primitives']:
        assert {'POSITION','NORMAL','TANGENT','TEXCOORD_0'}<=set(primitive['attributes'])
e=out/'docs/production/evidence/archive_reconstruction/dome-authoring-2'
e.mkdir(parents=True)
(e/'payload_manifest.json').write_text(json.dumps({'payloads':[{'path':p.relative_to(out).as_posix(),
 'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in targets],
 'measurements':measurements,'geometry_helper_sha256':hashlib.sha256(recipe.read_bytes()).hexdigest()},indent=2)+'\n')
print('WING01_DOME_CREATED PASS:',json.dumps(measurements))
