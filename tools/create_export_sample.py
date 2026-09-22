"""Blender CLI: create the minimal one-meter export fixture in an explicit repo.

blender --background --factory-startup --python-exit-code 1 \
    --python tools/create_export_sample.py -- /absolute/repository
Refuses to overwrite either authored binary. This is a test fixture, not art.
"""
from pathlib import Path
import sys
import bpy

repo = Path(sys.argv[sys.argv.index('--') + 1]).resolve()
source = repo / 'assets/3d/blender/validation/sm_pipeline_meter_cube.blend'
export = repo / 'game/art/meshes/validation/sm_pipeline_meter_cube.glb'
if source.exists() or export.exists():
    raise RuntimeError('Refusing to overwrite an existing sample')
source.parent.mkdir(parents=True, exist_ok=True)
export.parent.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
scene = bpy.context.scene
scene.unit_settings.system = 'METRIC'
scene.unit_settings.scale_length = 1.0
bpy.ops.mesh.primitive_cube_add(size=1.0)
obj = bpy.context.object
obj.name = 'sm_pipeline_meter_cube'
# Bottom-center pivot, with unit object transforms and a one-meter bounding box.
for vertex in obj.data.vertices:
    vertex.co.z += 0.5
obj.data.update()
material = bpy.data.materials.new('m_pipeline_neutral')
material.use_nodes = True
bsdf = material.node_tree.nodes.get('Principled BSDF')
bsdf.inputs['Base Color'].default_value = (0.55, 0.55, 0.55, 1.0)
bsdf.inputs['Roughness'].default_value = 0.7
obj.data.materials.append(material)
bpy.ops.wm.save_as_mainfile(filepath=str(source))
bpy.ops.export_scene.gltf(filepath=str(export), export_format='GLB',
                          use_selection=True, export_yup=True,
                          export_animations=False)
print('EXPORT_SAMPLE CREATED:', source, export)
