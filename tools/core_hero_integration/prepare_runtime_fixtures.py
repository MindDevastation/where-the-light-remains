"""Guarded extension of the existing actual input/clock/save progression fixture."""
from pathlib import Path
import hashlib
import json


def prepare(root, workspace):
    clean = workspace / 'source'
    old = root / 'game/tests/archive_progression_smoke.gd'
    inputs = json.loads((workspace / 'inputs.json').read_text())
    assert hashlib.sha256(old.read_bytes()).hexdigest() == inputs['source_hashes'][old.relative_to(root).as_posix()]
    text = old.read_text()
    pairs = [
        ('    var id := world.get_instance_id()\n',
         '    var core_visual = world.get_node("Hub/Astrolabe/CoreHeroUpper")\n    var energy: MeshInstance3D = core_visual.get_node("VisualCore/ArchiveCentralMechanism/CoreAssembly/CoreEnergy")\n    var source_energy: StandardMaterial3D = energy.mesh.surface_get_material(0)\n    var source_peak := source_energy.emission_energy_multiplier\n    _check(is_zero_approx(core_visual.warmth) and is_zero_approx(energy.get_active_material(0).emission_energy_multiplier), "Recovered core begins asleep in the actual scene")\n    var id := world.get_instance_id()\n'),
        ('    var paused_energy := core_light.light_energy\n',
         '    var paused_energy := core_light.light_energy\n    var paused_core: float = core_visual.warmth\n'),
        ('    pause.resume()\n',
         '    _check(is_equal_approx(core_visual.warmth, paused_core), "Pause freezes the recovered core with the existing clock")\n    pause.resume()\n'),
        ('    var deadline := Time.get_ticks_msec() + 10000\n',
         '    var deadline := Time.get_ticks_msec() + 10000\n    var partial_core_seen := false\n'),
        ('        await get_tree().process_frame\n    _check(GameState.current_stage_id == ArchiveProgress.WING_ONE',
         '        await get_tree().process_frame\n        partial_core_seen = partial_core_seen or (core_visual.warmth > 0.1 and core_visual.warmth < 0.9)\n    _check(partial_core_seen, "Actual awakening projects intermediate core intensity")\n    _check(is_equal_approx(core_visual.warmth, 1.0) and is_equal_approx(energy.get_active_material(0).emission_energy_multiplier, source_peak), "Actual stage commit leaves the recovered core warm")\n    _check(is_equal_approx(source_energy.emission_energy_multiplier, source_peak), "Actual awakening preserves the imported shared material")\n    _check(GameState.current_stage_id == ArchiveProgress.WING_ONE'),
        ('    var restored_hub := restored.get_node("Hub/Onboarding") as ArchiveOnboarding\n',
         '    var restored_hub := restored.get_node("Hub/Onboarding") as ArchiveOnboarding\n    var restored_core = restored.get_node("Hub/Astrolabe/CoreHeroUpper")\n    _check(is_equal_approx(restored_core.warmth, 1.0), "Physical saved checkpoint restores core intensity without replay")\n'),
    ]
    for before, after in pairs:
        assert text.count(before) == 1, ('Ambiguous existing progression fixture', before)
        text = text.replace(before, after, 1)
    target = clean / 'game/tests/core_hero_progression.gd'
    target.write_text(text)
    (target.with_suffix('.tscn')).write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://tests/core_hero_progression.gd" id="Probe"]\n[node name="CoreHeroProgression" type="Node"]\nscript = ExtResource("Probe")\n')
    source = root / 'tools/core_hero_integration/scene_probe.gd'
    (clean / 'game/tests/core_hero_scene.gd').write_bytes(source.read_bytes())
    (clean / 'game/tests/core_hero_scene.tscn').write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://tests/core_hero_scene.gd" id="Probe"]\n[node name="CoreHeroScene" type="Node"]\nscript = ExtResource("Probe")\n')
    return {'original_progression_sha256': hashlib.sha256(old.read_bytes()).hexdigest(),
            'extended_progression_sha256': hashlib.sha256(text.encode()).hexdigest(),
            'additional_core_checks': 6}
