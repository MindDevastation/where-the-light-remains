"""Original modular walnut case and closed, unlettered archival books."""
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

root=Path(__file__).resolve().parents[1]
c=json.loads((root/'docs/production/archive_bookcase.json').read_text())
out=Path(sys.argv[sys.argv.index('--')+1]).resolve()
source=out/c['source']
export=out/('game/art/meshes/archive_kit/'+c['stem']+'.glb')
assert not source.exists() and not export.exists(), 'Use a new output root'
source.parent.mkdir(parents=True,exist_ok=True)
export.parent.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
for collection in list(bpy.data.collections):
    bpy.data.collections.remove(collection)
scene=bpy.context.scene
scene.unit_settings.system='METRIC'
scene.unit_settings.scale_length=1
scene['asset_brief']='docs/production/ARCHIVE_BOOKCASE.md'
scene['source_recipe']='tools/create_archive_bookcase.py'
materials={}
for family,color,metal,rough in [('walnut',(.12,.045,.016,1),0,.65),
 ('brass',(.36,.22,.055,1),1,.48),('leather',(.20,.085,.038,1),0,.82),
 ('paper',(.73,.63,.42,1),0,.95),('navy',(.045,.08,.17,1),0,.9),
 ('crimson',(.24,.035,.055,1),0,.9)]:
    m=bpy.data.materials.new(Path(c['materials'][family]).stem)
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
g=Geometry()
def block(center,size,family):
    x,y,z=center
    a,b,d=[v/2 for v in size]
    vertices=[(x+sx*a,y+sy*b,z+sz*d) for sx,sy,sz in
     [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]]
    g.solid(vertices,[[0,3,2,1],[4,5,6,7],[0,1,5,4],[3,7,6,2],[0,4,7,3],[1,2,6,5]],family)
# Closed frame with a shallow rear, two bays and three functional shelf levels.
g.box((0,1.275,.025),(2.4,2.55,.05),'walnut',.006)
for x in [-1.14,1.14]:
    g.box((x,1.275,.24),(.12,2.55,.36),'walnut',.012)
g.box((0,1.27,.22),(.064,2.3,.32),'walnut',.007)
for y in [.15,.91,1.67,2.43]:
    g.box((0,y,.24),(2.22,.10,.36),'walnut',.008)
    g.box((0,y+.032,.406),(2.15,.016,.014),'brass',.003)
g.box((0,.045,.24),(2.4,.09,.36),'walnut',.010)
g.box((0,2.505,.24),(2.4,.09,.36),'walnut',.010)
books=[]
for row,base_y in enumerate([.201,.961,1.721]):
    for bay in [-1,1]:
        cursor=-1.048 if bay<0 else .064
        for i in range(8):
            w=.084+.010*((i*7+row*3+(1 if bay>0 else 0))%5)
            h=.43+.030*((i*3+row+(2 if bay>0 else 0))%7)
            depth=.23+.009*(i%4)
            x=cursor+w/2
            z=.10+depth/2
            family=['leather','leather','navy','leather','crimson','leather','navy','leather'][(i+row)%8]
            # Opaque closed paper block plus two binding boards and the visible spine.
            block((x,base_y+h/2,z),(w-.014,h-.025,depth-.018),'paper')
            for side in [-1,1]:
                block((x+side*(w/2-.003),base_y+h/2,z),(.006,h,depth),family)
            block((x,base_y+h/2,.10+depth-.003),(w,h,.006),family)
            for fraction in [.20,.80]:
                block((x,base_y+h*fraction,.10+depth+.002),(w-.005,.010,.003),'brass')
            books.append({'row':row,'bay':bay,'width':w,'height':h,'depth':depth,'family':family})
            cursor+=w+.012
        assert cursor<(-.032 if bay<0 else 1.08), 'Book bays must clear their uprights'
obj=g.object(dict(c,materials=c['material_order']))
obj.data.calc_loop_triangles()
count=len(obj.data.loop_triangles)
assert count<=c['triangle_ceiling'],count
assert bpy.ops.wm.save_as_mainfile(filepath=str(source))=={'FINISHED'}
bpy.ops.object.select_all(action='DESELECT')
obj.select_set(True)
bpy.context.view_layer.objects.active=obj
assert bpy.ops.export_scene.gltf(filepath=str(export),export_format='GLB',use_selection=True,
 export_yup=True,export_animations=False,export_tangents=True,export_cameras=False,
 export_lights=False,export_extras=False)=={'FINISHED'}
raw=export.read_bytes()
assert struct.unpack_from('<4sII',raw)==(b'glTF',2,len(raw))
size,kind=struct.unpack_from('<II',raw,12)
assert kind==0x4e4f534a
doc=json.loads(raw[20:20+size])
assert len(doc['nodes'])==len(doc['meshes'])==1
assert not any(doc.get(k) for k in ['animations','skins','images','textures'])
assert len(doc['meshes'][0]['primitives'])==6
for p in doc['meshes'][0]['primitives']:
    assert {'POSITION','NORMAL','TANGENT','TEXCOORD_0'}<=set(p['attributes'])
e=out/'docs/production/evidence/archive_reconstruction/bookcase-authoring-1'
e.mkdir(parents=True)
(e/'payload_manifest.json').write_text(json.dumps({'payloads':[{'path':p.relative_to(out).as_posix(),
 'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in [source,export]],
 'measurements':{'triangles':count,'surfaces':6,'closed_books':len(books)},'books':books,
 'geometry_helper_sha256':hashlib.sha256(recipe.read_bytes()).hexdigest()},indent=2)+'\n')
print('ARCHIVE_BOOKCASE_CREATED PASS:',count,'triangles; six shared material surfaces;',len(books),'closed unlettered books')
