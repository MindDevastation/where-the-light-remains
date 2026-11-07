#!/usr/bin/env python3
"""Validate the staged original GLBs without changing repository runtime assets."""
import argparse
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess

from validate_owner_gallery import sha, stamp, protected_slots_unchanged


def main(args):
    root = Path(__file__).resolve().parents[1]
    private = args.workspace.resolve()
    clean = private / 'source'
    output = args.output.resolve()
    assert private.is_relative_to(root.parent) and not private.is_relative_to(root)
    assert not output.exists() and output.is_relative_to(root / 'docs/production/evidence/core_hero_integration')
    inputs = json.loads((private / 'inputs.json').read_text())
    stage = json.loads((private / 'stage.json').read_text())
    for name, expected in inputs['source_hashes'].items():
        assert sha(root / name) == expected, ('Repository runtime changed', name)
    for row in stage['changed']:
        assert sha(clean / row['path']) == row['after_sha256']
    for row in inputs['recovered_private_payloads'] + inputs['existing_runtime_lfs_payloads']:
        expected = row.get('sha256', row.get('oid_sha256'))
        assert sha(clean / row['path']) == expected
    for name in ['archive_core_upper.tscn', 'archive_core_visual.gd']:
        assert sha(root / 'tools/core_hero_integration' / name) == sha(clean / 'game/art/scenes/hero_props' / name)
        assert sha(private / 'capability/art/scenes/hero_props' / name) == sha(clean / 'game/art/scenes/hero_props' / name)
    assert sha(private / 'capability/probe.gd') == sha(root / 'tools/core_hero_integration/component_probe.gd')
    component = json.loads((private / 'component/component.json').read_text())
    assert component['status'] == 'PASS' and component['renderer'] == 'forward_plus'
    assert b'GRAPHICAL_RUN PASS' in (private / 'component.log').read_bytes()
    output.mkdir(parents=True)
    for name in ['component.json', 'capability.png']:
        shutil.copyfile(private / 'component' / name, output / name)
    for name in ['import.log', 'capability-import.log', 'component.log', 'component-attempt1.log', 'component-attempt2.log', 'inputs.json', 'stage.json', 'integration.patch']:
        shutil.copyfile(private / name, output / name)
    shutil.copyfile(private / 'component-attempt2/component.json', output / 'component-attempt2.json')
    spec = importlib.util.spec_from_file_location('prepare_fixtures', root / 'tools/core_hero_integration/prepare_runtime_fixtures.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    fixtures = module.prepare(root, private)
    helpers = ['tools/validate_core_hero_integration.py', 'tools/prepare_core_hero_stage.py', 'tools/stage_core_hero_patch.py',
               'tools/run_graphical.py', 'tools/validate_owner_gallery.py'] + [p.relative_to(root).as_posix()
               for p in (root / 'tools/core_hero_integration').iterdir() if p.is_file()]
    hashes = inputs['source_hashes'] | {name: sha(root / name) for name in helpers}
    receipt = output / 'results.json'
    result = {'status': 'RUNNING', 'started_at': stamp(), 'source_hashes': hashes, 'records': [],
              'component': component, 'fixtures': fixtures, 'captures': [], 'stage': stage,
              'attempt_history': ['Attempt1 found an extra native GLB import root; source paths corrected.',
                                  'Attempt2 found a re-entry material lifecycle failure; request_ready and cold reset added.',
                                  'Final component run passes 32 assertions. Failed attempts are not counted as passes.'],
              'repository_runtime_changes': 0, 'new_lfs_uploads': 0, 'inventory_delta': [],
              'scope': 'Verified private staging of exact original GLBs. Actual E/awakening/pause/disk reload plus matched Low/effects-off and Medium native poses on software Vulkan. Not shipped, target GPU, performance or final art acceptance.'}

    def save():
        receipt.write_text(json.dumps(result, indent=2) + '\n')

    save()
    env = dict(os.environ, GODOT_SILENCE_ROOT_WARNING='1', PYTHONDONTWRITEBYTECODE='1')
    godot = str(args.godot.resolve())

    def run(name, command, timeout, marker='', userdata=None, protected=False):
        local_env = env.copy()
        slots = None
        before = {}
        if userdata is not None:
            local_env['XDG_DATA_HOME'] = str(userdata)
            slots = userdata / 'godot/app_userdata/Where the Light Remains'
            if protected:
                slots.mkdir(parents=True)
                for filename in ['savegame.json', 'savegame.backup.json']:
                    (slots / filename).write_text('{"protected_fixture":true}\n')
                before = {p.name: sha(p) for p in slots.iterdir() if p.is_file()}
        try:
            process = subprocess.run(command, cwd=clean, env=local_env, capture_output=True, timeout=timeout)
            code, raw = process.returncode, process.stdout + process.stderr
        except subprocess.TimeoutExpired as error:
            code, raw = 124, (error.stdout or b'') + (error.stderr or b'') + b'\nVALIDATOR_TIMEOUT\n'
        log = output / (name + '.log')
        log.write_bytes(raw)
        after = {p.name: sha(p) for p in slots.iterdir() if p.is_file()} if slots and slots.exists() else {}
        passed = code == 0 and (not marker or marker.encode() in raw) and not any(
            word in raw for word in [b'ERROR:', b'SCRIPT ERROR', b'Parse Error', b'WARNING:'])
        if protected:
            passed = passed and protected_slots_unchanged(before, after)
        result['records'].append({'name': name, 'exit_code': code, 'passed': passed, 'log_sha256': sha(log),
                                  'slots_before': before, 'slots_after': after,
                                  'userdata_scope': 'Owned protected synthetic slots' if protected else 'Owned writable physical checkpoint fixture' if userdata else 'Editor import'})
        save()
        print(json.dumps({'name': name, 'passed': passed}), flush=True)
        assert passed, 'Native integration fixture failed: ' + name
        return raw

    try:
        run('final-text-import', [godot, '--headless', '--editor', '--path', str(clean / 'game'), '--import'], 90)
        raw = run('actual-progression', [godot, '--headless', '--audio-driver', 'Dummy', '--path', str(clean / 'game'),
                  'res://tests/core_hero_progression.tscn'], 55, 'ARCHIVE_PROGRESSION PASS', private / 'userdata-progression')
        run('affected-controls', [godot, '--headless', '--audio-driver', 'Dummy', '--path', str(clean / 'game'),
                  'res://tests/archive_hub_controls_smoke.tscn'], 45, 'ARCHIVE_HUB_CONTROLS PASS', private / 'userdata-controls', True)
        for preset in ['Low', 'Medium']:
            for variant in ['baseline', 'staged']:
                name = variant + '_' + preset.lower()
                env.update(WLR_CORE_OUTPUT=str(output), WLR_CORE_PRESET=preset, WLR_CORE_VARIANT=variant)
                run(name, ['python', '-B', str(root / 'tools/run_graphical.py'), '--graphics-prefix', str(args.graphics_prefix.resolve()),
                    '--godot', godot, '--timeout', '110', '--expect', 'CORE_HERO_SCENE PASS', '--', '--path', str(clean / 'game'),
                    '--resolution', '1280x720', 'res://tests/core_hero_scene.tscn'], 135,
                    'CORE_HERO_SCENE PASS', private / ('userdata-' + name), True)
                capture = json.loads((output / (name + '.json')).read_text())
                assert capture['status'] == 'PASS' and capture['renderer'] == 'forward_plus'
                assert len(capture['captures']) == 3
                if preset == 'Low':
                    assert not capture['effects'] and not capture['glow'] and not capture['volumetrics']
                for frame in capture['captures']:
                    assert frame['size'] == [1280, 720]
                    result['captures'].append(frame | {'sha256': sha(output / frame['file'])})
                save()
        for name, expected in hashes.items():
            assert sha(root / name) == expected, ('Source changed during native validation', name)
        for row in inputs['recovered_private_payloads']:
            assert sha(clean / row['path']) == row['sha256']
        result['status'] = 'PASS_PRIVATE_STAGING'
    except Exception as error:
        result.update(status='FAIL', failure=str(error))
        raise
    finally:
        result['finished_at'] = stamp()
        result['evidence_hashes'] = {p.name: sha(p) for p in output.iterdir() if p.is_file() and p != receipt}
        save()
    print('CORE_HERO_INTEGRATION PASS_PRIVATE_STAGING: original GLBs, actual input/clock/IO and12 original native frames')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--workspace', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--godot', type=Path, required=True)
    parser.add_argument('--graphics-prefix', type=Path, required=True)
    main(parser.parse_args())
