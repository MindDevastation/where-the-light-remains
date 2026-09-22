"""Disposable Blender CLI/exporter check, not a production asset or LFS gate.

blender --background --factory-startup --python-exit-code 1 \
    --python tools/blender_cli_probe.py -- /absolute/new/output-directory
"""
from pathlib import Path
import json
import struct
import sys
import bpy

out = Path(sys.argv[sys.argv.index('--') + 1]).resolve()
out.mkdir(parents=True, exist_ok=False)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
bpy.context.scene.unit_settings.system = 'METRIC'
bpy.context.scene.unit_settings.scale_length = 1.0
bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0))
cube = bpy.context.object
cube.name = 'sm_cli_probe'
material = bpy.data.materials.new('m_cli_probe')
material.use_nodes = True
cube.data.materials.append(material)
assert len(cube.data.uv_layers) == 1
assert len(cube.data.materials) == 1
assert tuple(cube.scale) == (1.0, 1.0, 1.0)
assert all(abs(d - 1.0) < 0.00001 for d in cube.dimensions)
blend = out / 'cli_probe.blend'
glb = out / 'cli_probe.glb'
assert bpy.ops.wm.save_as_mainfile(filepath=str(blend)) == {'FINISHED'}
assert bpy.ops.export_scene.gltf(filepath=str(glb), export_format='GLB',
                                 use_selection=True, export_animations=False) == {'FINISHED'}
data = glb.read_bytes()
magic, version, length = struct.unpack_from('<4sII', data)
assert (magic, version, length) == (b'glTF', 2, len(data))
json_length, chunk_type = struct.unpack_from('<II', data, 12)
assert chunk_type == 0x4E4F534A
doc = json.loads(data[20:20 + json_length])
assert len(doc['meshes']) == 1 and len(doc['materials']) == 1
primitive = doc['meshes'][0]['primitives'][0]
assert 'NORMAL' in primitive['attributes'] and 'TEXCOORD_0' in primitive['attributes']
assert blend.read_bytes().startswith(b'BLENDER')
print('BLENDER_CLI_PROBE PASS:', bpy.app.version_string,
      'one-meter mesh, UV, normals, one material, source saved, GLB 2.0 exported')
print('Disposable output:', out)
