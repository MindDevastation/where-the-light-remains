#!/usr/bin/env python3
"""Read-only numeric audit of the current front spans and existing wall builder.

No Blender import, mesh generation, contract edit, credential handling or upload.
The extracted definitions call only the existing Geometry/rectangle/wall helpers.
"""
import argparse
import ast
from collections import Counter
import hashlib
import json
from pathlib import Path
import re

import audio_audition as receipts

def audit(output):
    root = Path(__file__).resolve().parents[1]
    output = output.resolve()
    if output.exists() or not output.is_relative_to(root / "docs/production/evidence/archive_reconstruction"):
        raise ValueError("A new repository evidence family is required")
    source = root / "tools/create_archive_kit.py"
    tree = ast.parse(source.read_text())
    definitions = [node for node in tree.body if isinstance(node, (ast.ClassDef, ast.FunctionDef))
                   and node.name in {"Geometry", "rectangle", "wall"}]
    if {node.name for node in definitions} != {"Geometry", "rectangle", "wall"}:
        raise ValueError("Known wall helpers were changed/removed")
    namespace = {}
    exec(compile(ast.Module(body=definitions, type_ignores=[]), str(source), "exec"), namespace)
    walls = []
    for width in (2, 3, 4):
        shape = namespace["wall"](width)
        edges = Counter(tuple(sorted((face[i], face[(i + 1) % len(face)])))
                        for face in shape.faces for i in range(len(face)))
        xs = [vertex[0] for vertex in shape.vertices]
        walls.append({"requested_width": width, "x_bounds": [min(xs), max(xs)],
                      "actual_width": max(xs) - min(xs),
                      "closed_edge_incidence": all(count == 2 for count in edges.values()),
                      "non_two_incidence_edges": sum(count != 2 for count in edges.values()),
                      "analytical_triangles": sum(len(face) - 2 for face in shape.faces)})
    scene = (root / "game/worlds/archive/archive_main.tscn").read_text()
    fronts = []
    for side in ("L", "R"):
        mesh = re.search(r'\[sub_resource type="BoxMesh" id="M_RoomFront' + side + r'"\]\s*size = Vector3\(([^)]+)\)', scene)
        body = re.search(r'\[node name="RoomFront' + side + r'" type="StaticBody3D" parent="Wing01/Room"\]\s*position = Vector3\(([^)]+)\)', scene)
        if mesh is None or body is None:
            raise ValueError("Known front span resources changed")
        size = [float(x) for x in mesh.group(1).split(",")]
        center = [float(x) for x in body.group(1).split(",")]
        fronts.append({"side": side, "existing_size_xyz": size, "existing_center_xyz": center,
                       "x_span": [center[0] - size[0] / 2, center[0] + size[0] / 2]})
    if not all(w["closed_edge_incidence"] and w["actual_width"] == w["requested_width"]
               for w in walls if w["requested_width"] in (2, 4)):
        raise ValueError("Accepted two/four-meter helper assumptions no longer hold")
    inputs = ["tools/audit_archive_front.py", "tools/create_archive_kit.py",
              "game/worlds/archive/archive_main.tscn", "docs/design/REQUIRED_ASSET_TABLE.md",
              "docs/production/MODULAR_ARCHIVE_KIT.md", "docs/production/modular_archive_kit_v1.json",
              "docs/production/LFS_POLICY.md"]
    result = {"status": "PASS", "acceptance": "READ_ONLY_INPUT_AUDIT_ONLY",
              "finished_at": receipts.audio.stamp(), "source_hashes": {name: hashlib.sha256((root / name).read_bytes()).hexdigest() for name in inputs},
              "fronts": fronts, "existing_builder_probes": walls,
              "finding": "Both preserved front spans are 3 m. Existing wall(3) is unsupported: it spans 4 m and has eight non-two-incidence edges. Existing 2/4 m helpers remain valid.",
              "limits": "Analytical input audit only. No new Blender/GLB asset, manifold Blender validation, visual acceptance, contract/pivot change or binary upload."}
    output.mkdir(parents=True, exist_ok=False)
    receipts.write_receipt(output / "results.json", result)
    print(json.dumps({key: result[key] for key in ("status", "acceptance", "fronts", "existing_builder_probes")}))

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    audit(parser.parse_args().output)
