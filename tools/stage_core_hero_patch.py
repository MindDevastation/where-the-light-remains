#!/usr/bin/env python3
"""Apply a guarded text-only integration to the owned private copy, not the repo."""
import argparse
import difflib
import hashlib
import json
from pathlib import Path

from validate_owner_gallery import sha, write_exact


def stage(workspace):
    root = Path(__file__).resolve().parents[1]
    clean = workspace.resolve() / 'source'
    assert clean.is_relative_to(root.parent) and not clean.is_relative_to(root)
    inputs = json.loads((workspace / 'inputs.json').read_text())
    replacements = {
        'game/worlds/archive/archive_main.tscn': [
            ('[gd_scene load_steps=103 format=3]', '[gd_scene load_steps=104 format=3]'),
            ('[ext_resource type="Script" path="res://art/vfx/archive_inspect_glow.gd" id="InspectGlow"]',
             '[ext_resource type="PackedScene" path="res://art/scenes/hero_props/archive_core_upper.tscn" id="CoreHeroUpper"]\n\n[ext_resource type="Script" path="res://art/vfx/archive_inspect_glow.gd" id="InspectGlow"]'),
            ('[node name="OuterRing" type="MeshInstance3D" parent="Hub/Astrolabe"]\n',
             '[node name="CoreHeroUpper" parent="Hub/Astrolabe" instance=ExtResource("CoreHeroUpper")]\n\n[node name="OuterRing" type="MeshInstance3D" parent="Hub/Astrolabe"]\nvisible = false\n'),
            ('[node name="InnerRing" type="MeshInstance3D" parent="Hub/Astrolabe"]\n',
             '[node name="InnerRing" type="MeshInstance3D" parent="Hub/Astrolabe"]\nvisible = false\n')],
        'game/worlds/archive/archive_main.gd': [
            ('    # Shadow-free interior practicals must not light the exterior through walls.\n',
             '    var core_visual := get_node_or_null("Hub/Astrolabe/CoreHeroUpper") as ArchiveCoreHeroVisual\n    if core_visual != null:\n        core_visual.project_energy(amount)\n    # Shadow-free interior practicals must not light the exterior through walls.\n')]
    }
    patch = ''
    changes = []
    for name, pairs in replacements.items():
        assert sha(root / name) == inputs['source_hashes'][name]
        assert sha(clean / name) == inputs['source_hashes'][name], 'Use a fresh unpatched copy'
        before = (clean / name).read_text()
        after = before
        for old, new in pairs:
            assert after.count(old) == 1, ('Ambiguous baseline', name, old)
            after = after.replace(old, new, 1)
        data = after.encode()
        write_exact(clean / name, data, hashlib.sha256(data).hexdigest())
        patch += ''.join(difflib.unified_diff(before.splitlines(True), after.splitlines(True),
                                            fromfile='a/' + name, tofile='b/' + name, n=0))
        changes.append({'path': name, 'before_sha256': inputs['source_hashes'][name], 'after_sha256': sha(clean / name)})
    files = {'archive_core_visual.gd': 'game/art/scenes/hero_props/archive_core_visual.gd',
             'archive_core_upper.tscn': 'game/art/scenes/hero_props/archive_core_upper.tscn'}
    for source, target in files.items():
        data = (root / 'tools/core_hero_integration' / source).read_bytes()
        write_exact(clean / target, data, hashlib.sha256(data).hexdigest())
        changes.append({'path': target, 'after_sha256': sha(clean / target), 'new_text_source': True})
    (workspace / 'integration.patch').write_text(patch)
    (workspace / 'stage.json').write_text(json.dumps({'status': 'STAGED_NOT_PUBLISHED', 'changed': changes,
        'ring_mount_triangles': 5048, 'delivered_energy_glass_triangles': 3840,
        'expected_visible_triangles': 8888, 'rings_mounts_ceiling': 6000,
        'scope': 'Original GLB references and text-only projection hook. Hidden full-body/richer ring parts remain in the original referenced GLB, not converted or exported. Exact source files and GLBs remain unchanged.'}, indent=2) + '\n')
    print('CORE_HERO_STAGE_PATCH READY: two text changes, two new text resources, zero repository runtime writes')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--workspace', type=Path, required=True)
    stage(parser.parse_args().workspace)
