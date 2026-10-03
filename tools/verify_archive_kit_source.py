"""Reopen and independently inspect the actual saved/retrieved kit source.

blender --background <source.blend> --python-exit-code 1 \
    --python tools/verify_archive_kit_source.py
"""
from pathlib import Path
import json
import math

import bpy
import bmesh
from mathutils import Vector
from mathutils.bvhtree import BVHTree

root = Path(__file__).resolve().parents[1]
contract = json.loads((root / 'docs/production/modular_archive_kit_v1.json').read_text())
scene = bpy.context.scene
assert scene.unit_settings.system == 'METRIC' and scene.unit_settings.scale_length == 1
meshes = [obj for obj in scene.objects if obj.type == 'MESH']
assert len(meshes) == 5
assert {obj.name for obj in meshes} == {m['stem'] for m in contract['modules']}
assert all(obj.type in ('MESH', 'EMPTY') for obj in scene.objects)
for module in contract['modules']:
    obj = scene.objects[module['stem']]
    assert obj.users_collection[0].name == module['id']
    assert obj.location.length < 1e-6
    assert Vector(obj.rotation_euler).length < 1e-6
    assert (obj.scale - Vector((1, 1, 1))).length < 1e-6
    assert not obj.modifiers and not obj.animation_data
    lo, hi = module['bounds_min'], module['bounds_max']
    expected = [(lo[0], hi[0]), (-hi[2], -lo[2]), (lo[1], hi[1])]
    for axis, (low, high) in enumerate(expected):
        coordinates = [v.co[axis] for v in obj.data.vertices]
        assert abs(min(coordinates) - low) < 1e-6 and abs(max(coordinates) - high) < 1e-6, module['id']
    names = ['m_observatory_stone' if family == 'stone' else 'm_aged_brass' for family in module['materials']]
    assert [m.name for m in obj.data.materials] == names
    assert all(m.use_backface_culling for m in obj.data.materials)
    assert len(obj.data.uv_layers) == 1
    obj.data.calc_loop_triangles()
    assert len(obj.data.loop_triangles) <= module['triangle_ceiling']
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    assert all(e.is_manifold and len(e.link_faces) == 2 for e in bm.edges)
    assert all(v.link_faces for v in bm.verts)
    assert all(f.calc_area() > 1e-10 for f in bm.faces)
    assert bm.calc_volume(signed=True) > 0
    bm.free()
    obj.data.calc_tangents(uvmap='UVMap')
    # Source collections may be hidden for editing. Inspect actual stored
    # triangles directly; no dependency on viewport/evaluated visibility.
    actual_bvh = BVHTree.FromPolygons([v.co for v in obj.data.vertices],
                                     [list(face.vertices) for face in obj.data.polygons], all_triangles=True)
    uv = obj.data.uv_layers.active.data
    for triangle in obj.data.loop_triangles:
        a, b, c = [uv[i].uv for i in triangle.loops]
        uv_area = abs((b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x)) / 2
        assert abs(uv_area / triangle.area - 1) < .001, (module['id'], uv_area, triangle.area)
    for loop in obj.data.loops:
        assert abs(loop.normal.length - 1) < 1e-5 and abs(loop.tangent.length - 1) < 1e-5
        assert abs(loop.normal.dot(loop.tangent)) < 1e-5
    print('BLENDER_KIT_MODULE PASS:', module['id'], 'triangles=', len(obj.data.loop_triangles),
          'surfaces=', len(names), 'closed positive volume; metric UVs; unit normals/tangents; pivot/transforms/bounds')
    if module['id'] == 'arch_4m':
        # Actual mesh rays, not just matching generator metadata.
        for x in (-.75, 0, .75):
            for height in (.1, 1, 1.8, 1.9):
                assert actual_bvh.ray_cast(Vector((x, 1, height)), Vector((0, -1, 0)), 2)[0] is None
        for x, height in ((-1.6, 1), (1.6, 1), (0, 3.8)):
            assert actual_bvh.ray_cast(Vector((x, 1, height)), Vector((0, -1, 0)), 2)[0] is not None
        opening = module['opening']
        half = opening['width_m'] / 2
        rise = opening['apex_y_m'] - opening['spring_y_m']
        center = (rise**2-half**2)/(2*half)
        radius = half+center
        for i in range(opening['segments_per_half'] + 1):
            theta = math.pi+(math.acos(-center/radius)-math.pi)*i/opening['segments_per_half']
            x = center+radius*math.cos(theta)
            y = opening['spring_y_m']+radius*math.sin(theta)
            for side in (-1, 1):
                assert any((v.co-Vector((side*x, .145, y))).length < 1e-5 for v in obj.data.vertices)
        print('BLENDER_KIT_APERTURE PASS: real passage/blocker rays; all 32 contract crown segments present')
    if module['id'] == 'pier_4m':
        shaft = [v.co for v in obj.data.vertices if abs(v.co.z - .54) < 1e-5]
        assert max(v.x for v in shaft)-min(v.x for v in shaft) >= module['shaft_min_width_m']
        assert max(v.y for v in shaft)-min(v.y for v in shaft) >= module['shaft_min_width_m']
        for height in (.05, .1, .3, .5, 1, 2, 3, 3.5, 3.8, 4.06):
            for plan_y in (-.2, .2):
                point, normal, face, distance = actual_bvh.ray_cast(Vector((1, plan_y, height)), Vector((-1, 0, 0)), 2)
                assert point is not None and point.x > .2, 'Pier fails to cover actual 0.4m corner overlap'
        print('BLENDER_KIT_JUNCTION_COVER PASS: actual shaft/base/cap mesh covers wall overlap at 20 section rays')
print('BLENDER_ARCHIVE_KIT PASS: reopened five original modules; actual topology, aperture, UV density, normals, pivots and envelopes')
