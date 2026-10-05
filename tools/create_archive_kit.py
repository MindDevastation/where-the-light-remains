"""Author the approved five-part Archive sample, not a general world generator.

blender --background --factory-startup --python-exit-code 1 \
    --python tools/create_archive_kit.py -- /absolute/empty/output-repository
Reads the approved contract from the script's repository. Refuses to overwrite
source/exports; rerun into a disposable output root for a deliberate rebuild.
All geometry is original. No concept pixels, proprietary assets or new maps.
"""
from pathlib import Path
import hashlib
import json
import math
import struct
import sys

import bpy
import bmesh
from mathutils import Vector

recipe_root = Path(__file__).resolve().parents[1]
contract = json.loads((recipe_root / 'docs/production/modular_archive_kit_v1.json').read_text())
out = Path(sys.argv[sys.argv.index('--') + 1]).resolve()
source = out / 'assets/3d/blender/archive_kit/archive_kit_sample.blend'
exports = out / 'game/art/meshes/archive_kit'
targets = [source] + [exports / (m['stem'] + '.glb') for m in contract['modules']]
if any(p.exists() for p in targets):
    raise RuntimeError('Refusing to overwrite an authored source/export; use a disposable output root')
source.parent.mkdir(parents=True, exist_ok=True)
exports.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
for collection in list(bpy.data.collections):
    bpy.data.collections.remove(collection)
scene = bpy.context.scene
scene.unit_settings.system = 'METRIC'
scene.unit_settings.scale_length = 1.0
scene['asset_brief'] = 'docs/production/MODULAR_ARCHIVE_KIT.md; contract v1 / visual revision 2'
scene['source_recipe'] = 'tools/create_archive_kit.py'

materials = []
for name, color, metal, rough in (
    ('m_observatory_stone', (0.64, 0.57, 0.44, 1), 0, 0.78),
    ('m_aged_brass', (0.36, 0.22, 0.055, 1), 1, 0.48),
):
    material = bpy.data.materials.new(name)
    material.use_nodes = True
    material.use_backface_culling = True
    bsdf = material.node_tree.nodes.get('Principled BSDF')
    bsdf.inputs['Base Color'].default_value = color
    bsdf.inputs['Metallic'].default_value = metal
    bsdf.inputs['Roughness'].default_value = rough
    materials.append(material)


class Geometry:
    """Stitched static volume, authored in Godot meter coordinates."""
    def __init__(self):
        self.vertices, self.faces, self.slots = [], [], []
        self.lookup = {}

    def point(self, xyz):
        # Apply the verified Godot Y-up -> Blender Z-up conversion once.
        x, y, z = xyz
        key = tuple(round(v, 9) for v in (x, -z, y))
        if key not in self.lookup:
            self.lookup[key] = len(self.vertices)
            self.vertices.append(key)
        return self.lookup[key]

    def face(self, points, material=0):
        indices = [self.point(p) for p in points]
        assert len(set(indices)) == len(indices), points
        self.faces.append(indices)
        self.slots.append(material)

    def band(self, a, b, material=0, closed=True):
        assert len(a) == len(b)
        for i in range(len(a) if closed else len(a) - 1):
            j = (i + 1) % len(a)
            self.face([a[i], a[j], b[j], b[i]], material)

    def object(self, module):
        mesh = bpy.data.meshes.new(module['stem'])
        mesh.from_pydata(self.vertices, [], self.faces)
        mesh.update()
        for family in module['materials']:
            mesh.materials.append(materials[0 if family == 'stone' else 1])
        for polygon, slot in zip(mesh.polygons, self.slots):
            polygon.material_index = slot
        bm = bmesh.new()
        bm.from_mesh(mesh)
        bmesh.ops.triangulate(bm, faces=list(bm.faces))
        bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
        if bm.calc_volume(signed=True) < 0:
            bmesh.ops.reverse_faces(bm, faces=list(bm.faces))
        assert all(e.is_manifold for e in bm.edges), module['id'] + ' has open/nonmanifold edges'
        assert bm.calc_volume(signed=True) > 0
        bm.to_mesh(mesh)
        bm.free()
        mesh.update()
        # Orthonormal per-face projections give exactly one UV unit per meter.
        # Vertical surfaces keep +V upward; cuts lie on construction/bevel edges.
        uv = mesh.uv_layers.new(name='UVMap')
        up = Vector((0, 0, 1))
        for face in mesh.polygons:
            n = face.normal
            if abs(n.dot(up)) < 0.95:
                v = (up - n * n.dot(up)).normalized()
                u = v.cross(n).normalized()
            else:
                u = (Vector((1, 0, 0)) - n * n.x).normalized()
                v = n.cross(u).normalized()
            for loop_index in face.loop_indices:
                co = mesh.vertices[mesh.loops[loop_index].vertex_index].co
                uv.data[loop_index].uv = (co.dot(u), co.dot(v))
        mesh.calc_tangents(uvmap='UVMap')
        collection = bpy.data.collections.new(module['id'])
        scene.collection.children.link(collection)
        obj = bpy.data.objects.new(module['stem'], mesh)
        collection.objects.link(obj)
        obj['inventory'] = module['inventory']
        obj['module_id'] = module['id']
        obj['triangle_ceiling'] = module['triangle_ceiling']
        obj['runtime_materials'] = ', '.join(contract['materials'][key] for key in module['materials'])
        assert len(mesh.polygons) <= module['triangle_ceiling']
        return obj


def rectangle(x0, x1, y0, y1, z):
    return [(x0, y0, z), (x1, y0, z), (x1, y1, z), (x0, y1, z)]


def wall(width):
    if not isinstance(width, (int, float)) or width not in (2, 3, 4):
        raise ValueError('Supported wall spans are exactly 2, 3 and 4 meters')
    g = Geometry()
    # Preserve the accepted 2/4 m geometry exactly. The pending 3 m variant
    # has two 1.5 m bays, with the same metric trim insets and closed perimeter.
    # This helper does not add a source/export to the five-part sample CLI.
    bay_count = 1 if width == 2 else 2
    bay_width = width / bay_count
    for center in [-width / 2 + bay_width / 2 + i * bay_width for i in range(bay_count)]:
        for sign in (-1, 1):
            profiles = [
                (0.0, 0.0, 4.0, .20), (.055, .11, 3.89, .20),
                (.075, .135, 3.87, .178), (.10, .30, 3.72, .178),
                (.14, .34, 3.68, .142), (.20, .45, 3.50, .142),
                (.22, .47, 3.48, .12),
            ]
            loops = [rectangle(center - bay_width / 2 + inset, center + bay_width / 2 - inset, low, high, sign * depth)
                     for inset, low, high, depth in profiles]
            for a, b in zip(loops, loops[1:]):
                g.band(a, b)
            g.face(loops[-1])
    # Perimeter walls: split top/bottom at the same construction-bay vertices.
    for a in [-width / 2 + i * bay_width for i in range(bay_count)]:
        for y in (0, 4):
            g.face([(a, y, -.2), (a + bay_width, y, -.2), (a + bay_width, y, .2), (a, y, .2)])
    for x in (-width / 2, width / 2):
        g.face([(x, 0, -.2), (x, 4, -.2), (x, 4, .2), (x, 0, .2)])
    return g


def opening_path(opening, offset):
    a = opening['width_m'] / 2
    spring = opening['spring_y_m']
    h = opening['apex_y_m'] - spring
    c = (h * h - a * a) / (2 * a)
    r = a + c + offset
    apex_angle = math.acos(-c / r)
    left = [(-a - offset, 0), (-a - offset, spring)]
    for i in range(1, opening['segments_per_half'] + 1):
        theta = math.pi + (apex_angle - math.pi) * i / opening['segments_per_half']
        left.append((c + r * math.cos(theta), spring + r * math.sin(theta)))
    left[-1] = (0, spring + math.sqrt(r * r - c * c))
    return left + [(-x, y) for x, y in reversed(left[:-1])]


def arch(opening):
    g = Geometry()
    # Broad stone moulding, restrained 15 mm brass band, symmetric reverse face.
    profiles = [(0, .145), (.035, .18), (.050, .20), (.075, .20),
                (.09, .185), (.105, .185), (.12, .20), (.18, .20),
                (.205, .165), (.24, .13)]
    paths = [opening_path(opening, offset) for offset, depth in profiles]
    sides = {}
    for sign in (-1, 1):
        loops = [[(x, y, sign * depth) for x, y in path]
                 for path, (_, depth) in zip(paths, profiles)]
        sides[sign] = loops
        for index, (a, b) in enumerate(zip(loops, loops[1:])):
            g.band(a, b, material=1 if index == 4 else 0, closed=False)
        # Concave U-shaped structural face outside the layered surround.
        g.face([(-2, 0, sign * .13), (-2, 4, sign * .13),
                (2, 4, sign * .13), (2, 0, sign * .13)] + list(reversed(loops[-1])))
    g.band(sides[-1][0], sides[1][0], closed=False)
    outer = [(-2, 0), (-2, 4), (2, 4), (2, 0)]
    g.band([(x, y, -.13) for x, y in outer], [(x, y, .13) for x, y in outer], closed=False)
    for side_index, outer_x in ((0, -2), (-1, 2)):
        # Two jamb soles close the volume without bridging/blocking the opening.
        g.face([(outer_x, 0, -.13)] + [loop[side_index] for loop in reversed(sides[-1])]
               + [loop[side_index] for loop in sides[1]] + [(outer_x, 0, .13)])
    return g


def square(y, half, bevel=.018):
    a, b = half, half - bevel
    return [(a, y, b), (b, y, a), (-b, y, a), (-a, y, b),
            (-a, y, -b), (-b, y, -a), (b, y, -a), (a, y, -b)]


def pier():
    g = Geometry()
    sections = [(0, .30), (.08, .30), (.11, .285), (.17, .285),
                (.19, .285), (.23, .27), (.38, .27), (.43, .235),
                (.54, .235), (3.44, .235), (3.50, .25), (3.61, .25),
                (3.68, .285), (3.76, .285), (3.80, .30), (3.88, .30),
                (3.90, .30), (3.94, .275), (4.00, .275), (4.03, .30), (4.12, .30)]
    loops = [square(y, half) for y, half in sections]
    for i, (a, b) in enumerate(zip(loops, loops[1:])):
        g.band(a, b, material=1 if i in (3, 15) else 0)
    g.face(loops[0])
    g.face(loops[-1])
    return g


def floor():
    g = Geometry()
    def loop(y, half):
        return [(-half, y, -half), (half, y, -half), (half, y, half), (-half, y, half)]
    loops = [loop(-.2, .5), loop(-.002, .5), loop(0, .498)]
    for a, b in zip(loops, loops[1:]):
        g.band(a, b)
    g.face(loops[0])
    g.face(loops[-1])
    return g


objects = []
for module in contract['modules']:
    builder = {'wall_2m': lambda: wall(2), 'wall_4m': lambda: wall(4),
               'arch_4m': lambda: arch(module['opening']), 'floor_1m': floor,
               'pier_4m': pier}[module['id']]
    obj = builder().object(module)
    objects.append(obj)
    print('AUTHORED', module['id'], 'triangles=', len(obj.data.polygons),
          'surfaces=', len(obj.data.materials), 'dimensions=', tuple(round(v, 6) for v in obj.dimensions))
guides = bpy.data.collections.new('_SOURCE_ONLY_GUIDES')
scene.collection.children.link(guides)
guide = bpy.data.objects.new('MeterOriginGuide', None)
guide.empty_display_type = 'ARROWS'
guide.empty_display_size = .5
guides.objects.link(guide)
guides.hide_render = True
for collection in scene.collection.children:
    collection.hide_viewport = collection.name not in ('arch_4m', '_SOURCE_ONLY_GUIDES')
assert bpy.ops.wm.save_as_mainfile(filepath=str(source)) == {'FINISHED'}
records = []
for collection in scene.collection.children:
    collection.hide_viewport = False
for obj, module in zip(objects, contract['modules']):
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    target = exports / (module['stem'] + '.glb')
    assert bpy.ops.export_scene.gltf(filepath=str(target), export_format='GLB',
                                    use_selection=True, export_yup=True,
                                    export_animations=False, export_tangents=True,
                                    export_cameras=False, export_lights=False,
                                    export_extras=False) == {'FINISHED'}
    data = target.read_bytes()
    assert struct.unpack_from('<4sII', data) == (b'glTF', 2, len(data))
    size, kind = struct.unpack_from('<II', data, 12)
    assert kind == 0x4E4F534A
    document = json.loads(data[20:20 + size])
    assert len(document['meshes']) == 1
    assert not any(document.get(k) for k in ('animations', 'skins', 'images', 'textures'))
    primitives = document['meshes'][0]['primitives']
    assert len(primitives) == len(module['materials'])
    for primitive in primitives:
        assert {'POSITION', 'NORMAL', 'TANGENT', 'TEXCOORD_0'} <= set(primitive['attributes'])
    records.append({'module': module['id'], 'path': str(target.relative_to(out)),
                    'sha256': hashlib.sha256(data).hexdigest(), 'bytes': len(data),
                    'triangles': len(obj.data.polygons), 'surfaces': len(obj.data.materials),
                    'bounds_min': module['bounds_min'], 'bounds_max': module['bounds_max']})
raw = source.read_bytes()
records.insert(0, {'path': str(source.relative_to(out)), 'sha256': hashlib.sha256(raw).hexdigest(),
                   'bytes': len(raw), 'role': 'editable Blender source, five module collections'})
manifest = out / 'docs/production/evidence/modular_archive_kit/payload_manifest.json'
manifest.parent.mkdir(parents=True, exist_ok=True)
manifest.write_text(json.dumps({'contract_version': 1, 'visual_revision': 2,
                                'recipe_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                                'payloads': records}, indent=2) + '\n')
print('ARCHIVE_KIT_CREATED PASS: five original watertight static meshes; unit transforms; metric UVs; normals/tangents; one source + five GLBs')
