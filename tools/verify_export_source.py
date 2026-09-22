"""Run with Blender --background <retrieved.blend> --python-exit-code 1 --python this_file."""
import bpy
from mathutils import Vector

scene = bpy.context.scene
assert scene.unit_settings.system == 'METRIC'
assert scene.unit_settings.scale_length == 1.0
assert len(scene.objects) == 1
obj = scene.objects[0]
assert obj.type == 'MESH'
assert obj.location.length < 1e-6
assert Vector(obj.rotation_euler).length < 1e-6
assert (obj.scale - Vector((1, 1, 1))).length < 1e-6
assert (obj.dimensions - Vector((1, 1, 1))).length < 1e-6
assert len(obj.data.uv_layers) == 1
assert len(obj.data.materials) == 1
assert len(obj.data.polygons) == 6
for axis, (low, high) in enumerate(((-0.5, 0.5), (-0.5, 0.5), (0, 1))):
    values = [v.co[axis] for v in obj.data.vertices]
    assert abs(min(values) - low) < 1e-6 and abs(max(values) - high) < 1e-6
center = Vector((0, 0, 0.5))
for face in obj.data.polygons:
    assert face.normal.dot(face.center - center) > 0
print('BLENDER_SOURCE PASS: meters; unit transforms; bottom-center pivot; outward normals; UV; one material')
