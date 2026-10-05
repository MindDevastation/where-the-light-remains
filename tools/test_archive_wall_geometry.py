"""Numeric authoring-input regression; does not import Blender or export assets."""
import ast
from collections import Counter
import hashlib
import json
import math
from pathlib import Path
import unittest


SOURCE = Path(__file__).resolve().with_name('create_archive_kit.py')
# Full vertex/face/material-slot oracles measured before this edit at remote
# 11ebf59b913e9425ea24e2f2d7a4ae0523bee785. They preserve the accepted sample.
LEGACY_SHA256 = {
    2: '7226004bc06ad4fbcf31ca9c15dd7f536a0b4b9ae9e7c6348086eca57bee8b58',
    4: 'cf0a6e9cb3afd2cfcff31f35a059d0bdcf77e066d9439a2e5e46e5102ed558f5',
}


def load_wall():
    tree = ast.parse(SOURCE.read_text())
    definitions = [node for node in tree.body
                   if isinstance(node, (ast.ClassDef, ast.FunctionDef))
                   and node.name in {'Geometry', 'rectangle', 'wall'}]
    namespace = {}
    exec(compile(ast.Module(body=definitions, type_ignores=[]), str(SOURCE), 'exec'), namespace)
    return namespace['wall']


class WallGeometryTests(unittest.TestCase):
    def setUp(self):
        self.wall = load_wall()

    def test_existing_two_and_four_meter_geometry_is_identical(self):
        for width, expected in LEGACY_SHA256.items():
            with self.subTest(width=width):
                shape = self.wall(width)
                raw = json.dumps({'vertices': shape.vertices, 'faces': shape.faces,
                                  'slots': shape.slots}, sort_keys=True,
                                 separators=(',', ':')).encode()
                self.assertEqual(hashlib.sha256(raw).hexdigest(), expected)

    def test_three_meter_bounds_closed_connected_shell_and_budget(self):
        shape = self.wall(3)
        # Geometry.point converts Godot X/Y/Z to Blender X/-Z/Y.
        for axis, bounds in enumerate(((-1.5, 1.5), (-.2, .2), (0, 4))):
            values = [p[axis] for p in shape.vertices]
            self.assertEqual((min(values), max(values)), bounds)
        edges = Counter(tuple(sorted((face[i], face[(i + 1) % len(face)])))
                        for face in shape.faces for i in range(len(face)))
        self.assertTrue(edges)
        self.assertTrue(all(count == 2 for count in edges.values()))
        self.assertEqual(len(shape.vertices) - len(edges) + len(shape.faces), 2)
        neighbors = {i: set() for i in range(len(shape.vertices))}
        for a, b in edges:
            neighbors[a].add(b)
            neighbors[b].add(a)
        pending, visited = [0], set()
        while pending:
            index = pending.pop()
            if index not in visited:
                visited.add(index)
                pending.extend(neighbors[index] - visited)
        self.assertEqual(len(visited), len(shape.vertices))
        self.assertLessEqual(sum(len(face) - 2 for face in shape.faces), 1800)
        self.assertEqual(set(shape.slots), {0})

    def test_three_meter_faces_have_nonzero_area(self):
        shape = self.wall(3)
        for face in shape.faces:
            a, b, c = (shape.vertices[i] for i in face[:3])
            u, v = [b[i] - a[i] for i in range(3)], [c[i] - a[i] for i in range(3)]
            cross = (u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2],
                     u[0] * v[1] - u[1] * v[0])
            self.assertGreater(math.sqrt(sum(x * x for x in cross)), 1e-8)

    def test_unsupported_spans_fail_before_building_geometry(self):
        for width in (0, 1, -2, 5, 2.5, float('nan'), float('inf'), None, '3', True):
            with self.subTest(width=width):
                with self.assertRaises(ValueError):
                    self.wall(width)


if __name__ == '__main__':
    unittest.main()
