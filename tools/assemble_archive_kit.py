"""Build only the approved script-free wrappers and isolated test assemblies.

python tools/assemble_archive_kit.py
After the first Godot import: python tools/assemble_archive_kit.py --configure-imports
Imported materials are remapped to the existing shared Godot resources, not
duplicated per instance. No GameRoot/world routing or project settings edits.
"""
from pathlib import Path
import json
import math
import re
import sys

root = Path(__file__).resolve().parents[1]
contract = json.loads((root / 'docs/production/modular_archive_kit_v1.json').read_text())


def number(value):
    return f'{value:.9f}'.rstrip('0').rstrip('.') if value else '0'


def vector(value):
    return 'Vector3(' + ', '.join(number(x) for x in value) + ')'


def name(identifier):
    return 'Archive' + ''.join(part.capitalize() for part in identifier.split('_'))


def curve(opening):
    half = opening['width_m'] / 2
    rise = opening['apex_y_m'] - opening['spring_y_m']
    c = (rise * rise - half * half) / (2 * half)
    radius = half + c
    points = []
    for i in range(opening['segments_per_half'] + 1):
        theta = math.pi + (math.acos(-c / radius) - math.pi) * i / opening['segments_per_half']
        points.append((c + radius * math.cos(theta), opening['spring_y_m'] + radius * math.sin(theta)))
    points[-1] = (0, opening['apex_y_m'])
    return points + [(-x, y) for x, y in reversed(points[:-1])]


for module in contract['modules']:
    identifier = module['id']
    resources, nodes = [], []
    if identifier == 'arch_4m':
        resources.append('[sub_resource type="BoxShape3D" id="Jamb"]\nsize = Vector3(0.8, 4, 0.4)')
        for side, x in (('LeftJamb', -1.6), ('RightJamb', 1.6)):
            nodes.append(f'[node name="{side}" type="CollisionShape3D" parent="Collision"]\nposition = {vector((x, 2, 0))}\nshape = SubResource("Jamb")')
        points = curve(module['opening'])
        for index, ((x0, y0), (x1, y1)) in enumerate(zip(points, points[1:])):
            values = [coordinate for z in (-.2, .2)
                      for point in ((x0, y0, z), (x1, y1, z), (x1, 4, z), (x0, 4, z))
                      for coordinate in point]
            key = f'Crown{index:02d}'
            resources.append(f'[sub_resource type="ConvexPolygonShape3D" id="{key}"]\npoints = PackedVector3Array(' + ', '.join(number(x) for x in values) + ')')
            nodes.append(f'[node name="{key}" type="CollisionShape3D" parent="Collision"]\nshape = SubResource("{key}")')
    else:
        low, high = module['bounds_min'], module['bounds_max']
        size = [b - a for a, b in zip(low, high)]
        center = [(a + b) / 2 for a, b in zip(low, high)]
        resources.append(f'[sub_resource type="BoxShape3D" id="Solid"]\nsize = {vector(size)}')
        nodes.append(f'[node name="Solid" type="CollisionShape3D" parent="Collision"]\nposition = {vector(center)}\nshape = SubResource("Solid")')
    text = f'[gd_scene load_steps={len(resources) + 2} format=3]\n\n'
    text += f'[ext_resource type="PackedScene" path="res://art/meshes/archive_kit/{module["stem"]}.glb" id="Art"]\n\n'
    text += '\n\n'.join(resources) + '\n\n'
    text += f'[node name="{name(identifier)}" type="Node3D"]\nmetadata/module_id = "{identifier}"\n\n'
    text += '[node name="Art" parent="." instance=ExtResource("Art")]\n\n'
    text += '[node name="Collision" type="StaticBody3D" parent="."]\ncollision_layer = 1\ncollision_mask = 1\n\n'
    text += '\n\n'.join(nodes) + '\n\n'
    for anchor, position in module['anchors'].items():
        text += f'[node name="{anchor.capitalize()}" type="Marker3D" parent="."]\nposition = {vector(position)}\n\n'
    target = root / f'game/worlds/archive/modules/archive_{identifier}.tscn'
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(text.rstrip() + '\n')


def assembly(filename, floors, facade, piers):
    ids = sorted({'floor_1m', 'pier_4m'} | {entry['module'] for entry in facade})
    text = f'[gd_scene load_steps={len(ids) + 1} format=3]\n\n'
    for identifier in ids:
        text += f'[ext_resource type="PackedScene" path="res://worlds/archive/modules/archive_{identifier}.tscn" id="{identifier}"]\n'
    text += '\n[node name="ArchiveKitSample" type="Node3D"]\n\n'
    text += '[node name="Floors" type="Node3D" parent="."]\n\n'
    for index, position in enumerate(floors):
        text += f'[node name="Floor{index:02d}" parent="Floors" instance=ExtResource("floor_1m")]\nposition = {vector(position)}\n\n'
    text += '[node name="Facade" type="Node3D" parent="."]\n\n'
    for index, entry in enumerate(facade):
        text += f'[node name="Bay{index}" parent="Facade" instance=ExtResource("{entry["module"]}")]\nposition = {vector(entry["position"])}\n'
        if entry['yaw']:
            text += f'rotation = Vector3(0, {number(math.radians(entry["yaw"]))}, 0)\n'
        text += '\n'
    text += '[node name="Piers" type="Node3D" parent="."]\n\n'
    for index, position in enumerate(piers):
        text += f'[node name="Pier{index}" parent="Piers" instance=ExtResource("pier_4m")]\nposition = {vector(position)}\n\n'
    target = root / ('game/tests/fixtures/' + filename)
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(text.rstrip() + '\n')


sample = contract['sample']
grid = sample['floor_grid']
floors = [[grid['first_center'][axis] + x * grid['step_x'][axis] + z * grid['step_z'][axis]
           for axis in range(3)] for z in range(grid['count_z']) for x in range(grid['count_x'])]
assembly('archive_kit_sample.tscn', floors, sample['facade'], sample['piers'])
corner = sample['corner_test']
assembly('archive_kit_corner.tscn', [[x + .5, 0, z + .5] for x in range(-5, 1) for z in range(-1, 5)],
         [e for e in corner if e['module'] != 'pier_4m'],
         [e['position'] for e in corner if e['module'] == 'pier_4m'])

if '--configure-imports' in sys.argv:
    for module in contract['modules']:
        target = root / f'game/art/meshes/archive_kit/{module["stem"]}.glb.import'
        if not target.is_file():
            raise RuntimeError('Run the initial Godot import before configuring ' + str(target))
        text = target.read_text()
        materials = {('m_observatory_stone' if family == 'stone' else 'm_aged_brass'):
                     {'use_external/enabled': True, 'use_external/path': contract['materials'][family],
                      'use_external/fallback_path': contract['materials'][family]}
                     for family in module['materials']}
        replacement = '_subresources=' + json.dumps({'materials': materials}, indent=2) + '\n'
        text, count = re.subn(r'(?ms)^_subresources=.*?(?=^\w[^\n]*=|\Z)', lambda match: replacement, text)
        assert count == 1, target
        # Low-density static test parts: no unnecessary generated LOD variants.
        text = text.replace('meshes/generate_lods=true', 'meshes/generate_lods=false')
        # Preserve the 1 mm anchors and 2 mm floor dressing in this tiny sample.
        text = text.replace('meshes/force_disable_compression=false', 'meshes/force_disable_compression=true')
        text = text.replace('animation/import=true', 'animation/import=false')
        target.write_text(text)
    print('ARCHIVE_KIT_IMPORT_CONFIGURED: shared external materials; no per-instance copies; actual reuse still requires runtime validation')
print('ARCHIVE_KIT_ASSEMBLED: five script-free wrappers; 63-part primary pad; separate 39-part right-angle fixture; authored primitive/convex collision')
