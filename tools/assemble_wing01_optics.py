"""Build only the script-free carrier. Run --configure-imports after import."""
from pathlib import Path
import json
import re
import sys

root = Path(__file__).resolve().parents[1]
c = json.loads((root/'docs/production/wing01_optics_v1.json').read_text())


def vec(values):
    return 'Vector3('+', '.join(f'{x:.9f}'.rstrip('0').rstrip('.') if x else '0' for x in values)+')'


resources = []
nodes = []
for part in c['parts']:
    id = part['id']
    nodes.append(f'[node name="{id.capitalize()}" type="Node3D" parent="."]\nposition = {vec(part["joint"])}\nmetadata/component = "{id}"')
    nodes.append(f'[node name="Art" parent="{id.capitalize()}" instance=ExtResource("{id}")]')
    if id != 'frame':
        resources.append(f'[sub_resource type="SphereShape3D" id="Pick_{id}"]\nradius = {part["pick_radius_m"]}')
        point = part['grip'] if id != 'focus' else part['pick']
        nodes.append(f'[node name="Grip" type="Area3D" parent="{id.capitalize()}"]\nposition = {vec(point)}\ncollision_layer = 2\ncollision_mask = 0\nmonitoring = false\nmetadata/component = "{id}"')
        nodes.append(f'[node name="Shape" type="CollisionShape3D" parent="{id.capitalize()}/Grip"]\nshape = SubResource("Pick_{id}")')
        nodes.append(f'[node name="Axis" type="Marker3D" parent="{id.capitalize()}"]')
resources.append('[sub_resource type="BoxShape3D" id="Base"]\nsize = Vector3(1.92, 0.64, 0.98)')
resources.append('[sub_resource type="BoxShape3D" id="Support"]\nsize = Vector3(0.19, 1.24, 0.27)')
nodes.append('[node name="Collision" type="StaticBody3D" parent="Frame"]\ncollision_layer = 1\ncollision_mask = 1')
nodes.append('[node name="Base" type="CollisionShape3D" parent="Frame/Collision"]\nposition = Vector3(0, 0.32, 0)\nshape = SubResource("Base")')
for side,x in [('Left',-.96),('Right',.96)]:
    nodes.append(f'[node name="{side}" type="CollisionShape3D" parent="Frame/Collision"]\nposition = {vec([x,1.26,.13])}\nshape = SubResource("Support")')
text = f'[gd_scene load_steps={len(resources)+6} format=3]\n\n'
for part in c['parts']:
    text += f'[ext_resource type="PackedScene" path="res://art/meshes/wing01/{part["stem"]}.glb" id="{part["id"]}"]\n'
text += '\n'+'\n\n'.join(resources)+'\n\n[node name="Wing01OpticsSample" type="Node3D"]\nmetadata/brief = "S02-001/S02-003 articulation carrier; no solver"\n\n'
text += '\n\n'.join(nodes)+'\n'
target = root/c['wrapper']
target.parent.mkdir(parents=True,exist_ok=True)
target.write_text(text)
if '--configure-imports' in sys.argv:
    for part in c['parts']:
        target = root/f'game/art/meshes/wing01/{part["stem"]}.glb.import'
        text = target.read_text()
        materials = {Path(c['materials'][family]).stem:
                     {'use_external/enabled':True,'use_external/path':c['materials'][family],
                      'use_external/fallback_path':c['materials'][family]} for family in part['materials']}
        text,count = re.subn(r'(?ms)^_subresources=.*?(?=^\w[^\n]*=|\Z)',
                            lambda _: '_subresources='+json.dumps({'materials':materials},indent=2)+'\n',text)
        assert count==1
        text = text.replace('meshes/generate_lods=true','meshes/generate_lods=false')
        text = text.replace('animation/import=true','animation/import=false')
        # Preserve joint grip/stop positions for this bounded mechanical sample.
        text = text.replace('meshes/force_disable_compression=false','meshes/force_disable_compression=true')
        target.write_text(text)
print('WING01_ASSEMBLED: script-free carrier, four independent +Z joints, four moving grip Areas, three blocking boxes')
