#!/usr/bin/env python3
"""Bounded exact-source shipping local approach views through the documented TCP/Xvfb runner."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

import audio_audition as receipts


def validate(args):
    root = Path(__file__).resolve().parents[1]
    output = args.output.resolve()
    if not output.is_relative_to(root / 'docs/production/evidence/archive_reconstruction') or output.exists():
        raise ValueError('A new approach review evidence family is required')
    paths = sorted(p.relative_to(root).as_posix() for p in (root / 'game').rglob('*') if p.is_file()
                   and not any(part in {'.godot', '__pycache__'} for part in p.parts))
    paths += ['tools/validate_approach_presentation.py', 'tools/run_graphical.py',
              'tools/audio_audition.py', 'tools/audio_slice.py', 'tools/linux_graphics_packages.json']
    hashes = {p: receipts.audio.digest(root / p) for p in paths}
    output.mkdir(parents=True, exist_ok=False)
    result = {'status': 'RUNNING', 'started_at': receipts.audio.stamp(), 'source_hashes': hashes, 'records': [],
              'scope': args.scope + ' actual player views on Low/Medium using software lavapipe; not target GPU/full art/VS1 acceptance.'}
    receipt = output / 'results.json'
    receipts.write_receipt(receipt, result)
    try:
        with tempfile.TemporaryDirectory(prefix='wlr-approach-visual-') as private:
            clean = Path(private)
            for name in paths:
                target = clean / name
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(root / name, target)
                if receipts.audio.digest(target) != hashes[name]:
                    raise RuntimeError('Private source copy mismatch')
            data = clean / 'userdata'
            slots = data / 'godot/app_userdata/Where the Light Remains'
            slots.mkdir(parents=True)
            fixture = {'save_version': 1, 'stage_id': 's01_saved_fixture', 'checkpoint_id': 'protected',
                       'collected_fragments': [], 'world_states': {}, 'milestones': {},
                       'achievement_ids': [], 'game_completed': False}
            for name in ['savegame.json', 'savegame.backup.json']:
                (slots / name).write_text(json.dumps(fixture) + '\n')
            before = {p.name: receipts.audio.digest(p) for p in slots.iterdir()}
            env = dict(os.environ, GODOT_SILENCE_ROOT_WARNING='1', XDG_DATA_HOME=str(data))

            def run(name, command, timeout, marker=''):
                process = subprocess.run(command, cwd=clean, env=env, stdout=subprocess.PIPE,
                                         stderr=subprocess.STDOUT, timeout=timeout)
                log = output / (name + '.log')
                log.write_bytes(process.stdout)
                after = {p.name: receipts.audio.digest(p) for p in slots.iterdir() if p.is_file()}
                passed = process.returncode == 0 and before == after and (not marker or marker.encode() in process.stdout) and \
                    not any(word in process.stdout for word in (b'ERROR:', b'SCRIPT ERROR', b'Parse Error', b'WARNING:'))
                result['records'].append({'name': name, 'command': command, 'exit_code': process.returncode,
                                          'passed': passed, 'slots_before': before, 'slots_after': after,
                                          'log_sha256': receipts.audio.digest(log)})
                receipts.write_receipt(receipt, result)
                print(json.dumps({'name': name, 'passed': passed}), flush=True)
                if not passed:
                    raise RuntimeError('Controls review failed: ' + name)
            godot = str(args.godot.resolve())
            marker = 'ARCHIVE_' + args.scope.upper() + '_REVIEW CAPTURED'
            scene_scope = 'approach'
            scene = 'res://tests/archive_' + scene_scope + '_review.tscn'
            expected_captures = 6
            run('clean_import', [godot, '--headless', '--path', 'game', '--editor', '--import'], 90)
            for quality in ['low', 'medium']:
                run(quality, ['python3', '-B', str(clean / 'tools/run_graphical.py'),
                             '--graphics-prefix', str(args.graphics_prefix.resolve()), '--godot', godot,
                             '--timeout', '80', '--expect', marker, '--',
                             '--path', 'game', '--resolution', '960x540', scene,
                             '--', '--review-output=' + str(output), '--quality=' + quality], 105,
                    marker)
                captures = json.loads((output / ('captures_' + quality + '.json')).read_text())
                if captures['scope'] != args.scope or captures['renderer'] != 'forward_plus' or len(captures['captures']) != expected_captures or \
                        quality == 'low' and (captures['glow'] or captures['volumetrics']):
                    raise RuntimeError('Wrong renderer/capture count/Low effects')
            if any(receipts.audio.digest(root / name) != expected for name, expected in hashes.items()):
                raise RuntimeError('Current source changed during native review')
        result.update(status='PASS', private_copy_removed=True)
    except Exception as error:
        result.update(status='FAIL', failure=str(error))
        raise
    finally:
        for path in output.iterdir():
            if path.is_file() and path != receipt:
                result['source_hashes'][path.relative_to(root).as_posix()] = receipts.audio.digest(path)
        result['finished_at'] = receipts.audio.stamp()
        receipts.write_receipt(receipt, result)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', type=Path, required=True)
    parser.add_argument('--graphics-prefix', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--scope', choices=['approach'], default='approach')
    validate(parser.parse_args())
