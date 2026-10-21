"""Finish the standalone reference hero using the verified mesh and GLB recipe.

The older measured upper-only export remains a separate compatibility asset.
This source never rewrites shipping scenes or the accepted pedestal.
"""
import argparse, ast, hashlib, json, math, sys
from pathlib import Path
import bpy, bmesh
from mathutils import Vector, Matrix

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--input', type=Path, required=True)
parser.add_argument('--output', type=Path, required=True)
args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:])
out = args.output.resolve()
assert not out.exists(), 'Use a new output directory'
out.mkdir(parents=True)
bpy.ops.wm.open_mainfile(filepath=str(args.input.resolve()))
scene = bpy.context.scene
root = bpy.data.objects['ArchiveCentralMechanism']
pivot = bpy.data.objects['CoreAssembly']
preview = bpy.data.collections['PREVIEW_ONLY']
for obj in list(bpy.data.objects):
    if obj.type == 'MESH' and obj.name != 'PreviewGround':
        bpy.data.objects.remove(obj, do_unlink=True)
pivot.location = (0, 0, 1.02)
pivot['gameplay_pivot_godot_m'] = [0, 1.02, 0]
pivot['scope'] = 'Complete standalone visual; measured upper-only sibling uses pivot 1.8m'
materials = {key: bpy.data.materials[name] for key, name in [
    ('atlas', 'm_core_orbit_calibrated_brass'), ('brass', 'm_aged_brass'),
    ('iron', 'm_dark_iron'), ('walnut', 'm_dark_walnut')]}
recipe = ROOT / 'tools/create_wing01_optics.py'
defs = [n for n in ast.parse(recipe.read_text()).body
        if isinstance(n, (ast.ClassDef, ast.FunctionDef)) and n.name in {'convert', 'Geometry'}]
exec(compile(ast.Module(body=defs, type_ignores=[]), str(recipe), 'exec'), globals())
parts = []

def finish(g, name, slots, parent=root):
    obj = g.object({'id': name, 'stem': name, 'joint': [0, 0, 0], 'materials': slots})
    obj.parent = parent
    for face in obj.data.polygons:
        face.use_smooth = True
    obj.data.set_sharp_from_angle(angle=math.radians(38))
    parts.append(obj)
    return obj

def lathe(g, profile, material, n=64):
    g.loft([[(r*math.cos(math.tau*i/n), y, r*math.sin(math.tau*i/n))
             for i in range(n)] for y, r in profile], material)

def orient(g, start, rotation, translation):
    for i in range(start, len(g.vertices)):
        co = Vector(g.vertices[i])
        godot = Vector((co.x, co.z, -co.y))
        g.vertices[i] = convert(rotation @ godot + Vector(translation))

def ring_horizontal(g, y, radius, width, depth, mat, n=64):
    start = len(g.vertices)
    g.ring(radius, width, depth, mat, n)
    orient(g, start, Matrix.Rotation(math.pi/2, 3, 'X'), (0, y, 0))

# A compact dark wooden drum, stepped brass rims and black inset fascias.
g = Geometry()
lathe(g, [(.006,.438),(.012,.46),(.033,.46),(.047,.442),(.055,.43)], 'brass')
lathe(g, [(.045,.425),(.063,.436),(.08,.436),(.088,.407)], 'iron')
lathe(g, [(.077,.397),(.09,.405),(.265,.405),(.28,.39)], 'walnut')
lathe(g, [(.087,.407),(.095,.412),(.12,.412),(.128,.407)], 'brass')
lathe(g, [(.247,.405),(.255,.42),(.275,.42),(.285,.397)], 'brass')
lathe(g, [(.276,.39),(.29,.405),(.314,.405),(.33,.375),(.341,.36)], 'brass')
lathe(g, [(.339,.354),(.345,.36),(.351,.36)], 'iron')
for y,r in [(.026,.459),(.068,.435),(.108,.413),(.266,.42),(.302,.405),(.342,.345)]:
    ring_horizontal(g,y,r,.006,.005,'atlas')
body = finish(g,'sm_archive_core_plinth',['brass','iron','walnut','atlas'])

# Original unlettered fine brass hardware, without new puzzle markings.
g = Geometry()
for i in range(10):
    a = math.tau*i/10
    turn = Matrix.Rotation(a,3,'Y')
    start = len(g.vertices)
    g.box((0,.18,.402),(.034,.186,.025),'brass',.006)
    g.box((0,.104,.414),(.056,.023,.039),'atlas',.004)
    g.box((0,.26,.414),(.056,.023,.039),'atlas',.004)
    for y in [.108,.258]:
        g.cylinder((0,y,.44),.011,.02,'iron',10)
        g.cylinder((0,y,.449),.006,.018,'atlas',8)
    orient(g,start,turn,(0,0,0))
finish(g,'sm_archive_core_plinth_hardware',['brass','atlas','iron'])

# Decorative turned support remains part of the static body.
g = Geometry()
lathe(g, [(.346,.13),(.359,.151),(.38,.151),(.391,.113),(.413,.105),
          (.425,.13),(.448,.13),(.46,.093),(.486,.088),(.5,.06),
          (.57,.054),(.59,.071),(.616,.071),(.63,.052)],'brass',40)
lathe(g, [(.38,.116),(.397,.12),(.413,.12)],'iron',40)
lathe(g, [(.447,.098),(.462,.102),(.483,.102)],'iron',40)
lathe(g, [(.62,.047),(.64,.055),(.985,.055),(1.02,.043)],'iron',24)
for y,r in [(.367,.151),(.435,.13),(.604,.072)]:
    ring_horizontal(g,y,r,.008,.008,'atlas',40)
finish(g,'sm_archive_core_turned_support',['brass','iron','atlas'])

native = json.loads((ROOT/'docs/production/evidence/archive_reconstruction/core-mount-access-20261008-final2/native.json').read_text())
meta = json.loads((ROOT/'assets/3d/textures_source/archive_core_hero_v1/atlas_manifest.json').read_text())
atlas_material = materials['atlas']
for node in atlas_material.node_tree.nodes:
    if node.type == 'TEX_IMAGE':
        kind = node.image.name.rsplit('_',1)[-1].split('.')[0]
        p = ROOT/f'assets/3d/textures_source/archive_core_hero_v1/t_core_hero_brass_{kind}.png'
        node.image = bpy.data.images.load(str(p),check_existing=True)
        node.image.colorspace_settings.name = 'sRGB' if kind == 'albedo' else 'Non-Color'
    if node.type == 'NORMAL_MAP':
        node.inputs['Strength'].default_value = .75
profile = [(-.025,-.014),(.025,-.014),(.028,-.011),(.028,.011),
           (.025,.014),(-.025,.014),(-.028,.011),(-.028,-.011)]
arc = [0]
for i in range(1,8):
    arc.append(arc[-1]+math.dist(profile[i-1],profile[i]))
perimeter = arc[-1]+math.dist(profile[-1],profile[0])
rings = []
for idx,radius in enumerate([.58,.46,.34]):
    basis = Matrix(native['native_bases'][idx]).transposed()
    g = Geometry()
    vertices = [tuple(basis @ Vector(((radius+dr)*math.cos(math.tau*i/96),w,
                                    (radius+dr)*math.sin(math.tau*i/96))))
                for i in range(96) for dr,w in profile]
    faces = [[i*8+j,((i+1)%96)*8+j,((i+1)%96)*8+(j+1)%8,i*8+(j+1)%8]
             for i in range(96) for j in range(8)]
    g.solid(vertices,faces,'atlas')
    obj = finish(g,['Orbit_Outer','Orbit_Inner','Orbit_Third'][idx],['atlas'],pivot)
    rings.append(obj)
    region = meta['regions'][idx]
    for face in obj.data.polygons:
        ids = [obj.data.loops[k].vertex_index for k in face.loop_indices]
        wrap = any(v//8==0 for v in ids) and any(v//8==95 for v in ids)
        pwrap = any(v%8==0 for v in ids) and any(v%8==7 for v in ids)
        for k in face.loop_indices:
            i,j = divmod(obj.data.loops[k].vertex_index,8)
            u = (96 if wrap and i==0 else i)/96*region['u_pixels']/4096
            v = (perimeter if pwrap and j==0 else arc[j])*1024
            obj.data.uv_layers.active.data[k].uv = (u,1-(region['v_start']+v)/1024)
    obj.data.calc_tangents()
    obj['radius_m'] = radius
    obj['role'] = 'Visual orbit, no new input or animation'

# Bridge routes and collar locations follow the same measured shape at the new
# standalone visual height; gameplay-compatible dimensions live in the sibling.
g = Geometry()
for idx,route in enumerate(native['bridge_routes']):
    path = [Vector(p)-Vector((0,1.8,0)) for p in route['path_world_m']]
    loops = []
    for i,center in enumerate(path):
        direction = (path[min(i+1,len(path)-1)]-path[max(0,i-1)]).normalized()
        side = direction.cross(Vector((0,0,1)))
        if side.length < .01: side = direction.cross(Vector((1,0,0)))
        side.normalize();second = direction.cross(side).normalized()
        loops.append([tuple(center+side*x+second*y)
                      for x,y in [(-.01,-.008),(.01,-.008),(.014,-.004),(.014,.004),
                                  (.01,.008),(-.01,.008),(-.014,.004),(-.014,-.004)]])
    g.loft(loops,'brass')
    point = path[-1]
    basis = Matrix(native['native_bases'][idx]).transposed()
    for r,length,material in [(.041,.05,'iron'),(.032,.062,'atlas'),(.017,.075,'brass')]:
        start = len(g.vertices)
        g.cylinder((0,0,0),r,length,material,20)
        orient(g,start,basis @ Matrix.Rotation(math.pi/2,3,'X'),point)
finish(g,'sm_archive_core_upper_bearings',['brass','iron','atlas'],pivot)

# Core emission is material-only; there are no exported light nodes.
for name,radius,material in [('CoreEnergy',.106,'m_core_energy_gold'),
                             ('CoreGlass',.151,'m_core_memory_glass')]:
    bpy.ops.mesh.primitive_uv_sphere_add(segments=32,ring_count=16,radius=radius)
    obj = bpy.context.object;obj.name=name;obj.parent=pivot;obj.location=(0,0,0)
    obj.data.materials.append(bpy.data.materials[material])
    for face in obj.data.polygons:face.use_smooth=True
    parts.append(obj)
g = Geometry()
for rot in [Matrix.Identity(3),Matrix.Rotation(math.pi/2,3,'Y')]:
    start = len(g.vertices);g.ring(.157,.009,.009,'atlas',48)
    orient(g,start,rot,(0,0,0))
for y in [-.158,.158]:
    lathe(g,[(y-.012,.025),(y-.006,.039),(y+.006,.039),(y+.012,.025)],'brass',16)
finish(g,'sm_archive_core_gem_cage',['atlas','brass'],pivot)

# Fine luminous meridians inside the glass reproduce the reference's warm core.
emission = bpy.data.materials['m_core_energy_gold']
materials['energy'] = emission
g = Geometry()
for angle in [0,math.pi/3,2*math.pi/3]:
    start = len(g.vertices);g.ring(.137,.0016,.0016,'energy',40)
    orient(g,start,Matrix.Rotation(angle,3,'Y'),(0,0,0))
finish(g,'sm_archive_core_luminous_traces',['energy'],pivot)

# Use the exporter's built-in material output convention for the ORM R channel.
from io_scene_gltf2.blender.com.material_helpers import create_settings_group
ao_group = create_settings_group('glTF Material Output')
for material in set(materials.values()):
    separate = next((n for n in material.node_tree.nodes if n.type == 'SEPARATE_COLOR'),None)
    if separate:
        node = material.node_tree.nodes.new('ShaderNodeGroup')
        node.node_tree = ao_group
        material.node_tree.links.new(separate.outputs['Red'],node.inputs['Occlusion'])
emission.node_tree.nodes.get('Principled BSDF').inputs['Emission Strength'].default_value = 1.6

# Non-orbit hardware uses the plain brass atlas guard, with nondegenerate UVs.
for obj in parts:
    if obj not in rings and obj.type == 'MESH':
        for slot in obj.material_slots:
            if slot.material == atlas_material:
                for face in obj.data.polygons:
                    if obj.material_slots[face.material_index].material == atlas_material:
                        for k in face.loop_indices:
                            uv = obj.data.uv_layers.active.data[k].uv
                            uv.y = .06 + uv.y*.012
        obj.data.calc_tangents()
    obj.data.calc_loop_triangles()
    obj['triangles'] = len(obj.data.loop_triangles)

# Consolidate stationary pieces that share the same parent and materials.
# Ring, glass and core pivots remain independent, with identity object scales.
def consolidate(names, name):
    chosen = [bpy.data.objects[n] for n in names]
    bpy.ops.object.select_all(action='DESELECT')
    for obj in chosen:obj.select_set(True)
    bpy.context.view_layer.objects.active = chosen[0]
    for obj in chosen:parts.remove(obj)
    bpy.ops.object.join()
    merged = bpy.context.object;merged.name = name
    merged.data.calc_loop_triangles();merged['triangles'] = len(merged.data.loop_triangles)
    parts.append(merged)
consolidate(['sm_archive_core_plinth','sm_archive_core_plinth_hardware',
             'sm_archive_core_turned_support'],'sm_archive_core_static_body')
consolidate(['sm_archive_core_upper_bearings','sm_archive_core_gem_cage'],
            'sm_archive_core_mounts_and_cage')
consolidate(['CoreEnergy','sm_archive_core_luminous_traces'],'CoreEnergy')
root['asset_version'] = 'archive_core_hero_v1'
root['purpose'] = 'Standalone reference-look model; shipping assignment is separate'
scene.camera.location = (-3.5,-2.5,3.1)
scene.camera.rotation_euler = (Vector((0,0,.8))-scene.camera.location).to_track_quat('-Z','Y').to_euler()
scene.camera.data.ortho_scale = 1.93
scene.render.resolution_x = 1200;scene.render.resolution_y = 1200
scene.cycles.samples = 64
scene.render.image_settings.file_format = 'PNG'
for name in ['Key','CoolRim','Fill']:
    light = bpy.data.objects[name]
    light.rotation_euler = (Vector((0,0,.8))-light.location).to_track_quat('-Z','Y').to_euler()
bpy.data.objects['Key'].data.energy=700
bpy.data.objects['CoolRim'].data.energy=950
bpy.data.objects['Fill'].data.energy=250
bpy.ops.file.pack_all()
# Keep the source viewport focused on the actual asset, and hide only the studio.
for obj in preview.objects:obj.hide_set(True)
bpy.ops.object.select_all(action='DESELECT')
for obj in parts:obj.select_set(True)
bpy.context.view_layer.objects.active = rings[0]
bpy.ops.wm.save_as_mainfile(filepath=str(out/'s01_archive_core_hero_v1.blend'))
for obj in [root,pivot]:obj.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(out/'sm_s01_archive_core_hero_v1.glb'),
    export_format='GLB',use_selection=True,export_yup=True,export_animations=False,
    export_tangents=True,export_cameras=False,export_lights=False,export_extras=True)
for obj in preview.objects:obj.hide_set(False)
scene.render.filepath = str(out/'s01_archive_core_hero_preview.png')
bpy.ops.render.render(write_still=True)
receipt = {'status':'AUTHORED_EXPORTED_RENDERED','blender':bpy.app.version_string,
    'triangles':sum(o['triangles'] for o in parts),'mesh_parts':len(parts),
    'ring_triangles':[o['triangles'] for o in rings],
    'pivot_y_m':1.02,'units':'meters','shipping_scene_changed':False,
    'reference':'assets/3d/reference/s01_core_final_look_v1/s01_core_final_look_v1.png',
    'compatibility_variant':'sm_s01_core_upper_v1.glb preserves the earlier measured contract',
    'outputs':[{'file':p.name,'bytes':p.stat().st_size,
                'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
               for p in out.iterdir() if p.is_file()]}
(out/'authoring.json').write_text(json.dumps(receipt,indent=2)+'\n')
print('ARCHIVE_CORE_HERO_AUTHORED',json.dumps(receipt))
