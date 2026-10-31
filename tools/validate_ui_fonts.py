#!/usr/bin/env python3
"""Current-source Cyrillic font glyph/layout and isolated native pack review."""
import argparse
import concurrent.futures
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess

from validate_owner_gallery import protected_slots_unchanged, sha, stamp, write_exact


def main(args):
    root = Path(__file__).resolve().parents[1]
    output = args.output.resolve()
    private = args.private_workspace.resolve()
    if output.exists() or not output.is_relative_to(root / 'docs/production/evidence/ui_fonts'):
        raise ValueError('New evidence directory required')
    if private.exists() or not private.is_relative_to(root.parent) or private.is_relative_to(root):
        raise ValueError('New owned sibling scratch directory required')
    files = sorted(p.relative_to(root).as_posix() for p in (root / 'game').rglob('*') if p.is_file()
                   and not any(part in {'.godot', '__pycache__'} for part in p.parts))
    helpers = ['tools/validate_ui_fonts.py', 'tools/validate_owner_gallery.py', 'tools/run_graphical.py',
               'tools/create_archive_ui_font.gd', 'tools/build_ui_font_corpus.py',
               'tools/pack_ui_font_probe.gd', 'tools/read_ui_font_pack.gd']
    hashes = {name: sha(root / name) for name in files + helpers}
    output.mkdir(parents=True)
    private.mkdir()
    receipt = output / 'results.json'
    result = {'status': 'RUNNING', 'started_at': stamp(), 'source_hashes': hashes,
              'runtime_lfs_payloads': [], 'records': [], 'captures': [],
              'scope': 'Current UI font native glyph/binding/layout at three supported resolutions plus isolated font pack readback. Software Vulkan; no gameplay/input/route/save-reload/style/target GPU acceptance.',
              'new_lfs_uploads': 0, 'unrelated_accepted_suites_replayed': False}

    def save():
        receipt.write_text(json.dumps(result, indent=2) + '\n')

    save()
    try:
        clean = private / 'source'
        reader = private / 'lfs-reader'
        store = private / 'existing-lfs'
        env = dict(os.environ, GIT_TERMINAL_PROMPT='0', GIT_ASKPASS='/bin/false',
                   GODOT_SILENCE_ROOT_WARNING='1', PYTHONDONTWRITEBYTECODE='1')
        env.pop('GH_TOKEN', None)
        env.pop('GITHUB_TOKEN', None)
        subprocess.run(['git', 'init', '-q', '-b', 'lfs-read-scratch', str(reader)], env=env, check=True)
        subprocess.run(['git', 'remote', 'add', 'origin', 'https://github.com/MindDevastation/where-the-light-remains.git'], cwd=reader, env=env, check=True)
        subprocess.run(['git', '-c', 'user.name=Archive Review', '-c', 'user.email=review@example.invalid',
                        'commit', '-q', '--allow-empty', '-m', 'Temporary existing payload read namespace'], cwd=reader, env=env, check=True)
        pointers = []
        for name in files:
            data = (root / name).read_bytes()
            if name.endswith('.glb'):
                match = re.fullmatch(rb'version https://git-lfs.github.com/spec/v1\noid sha256:([0-9a-f]{64})\nsize ([0-9]+)\n', data)
                if not match or subprocess.check_output(['git', 'show', 'HEAD:' + name], cwd=root) != data:
                    raise RuntimeError('Unexpected existing GLB pointer: ' + name)
                pointers.append({'path': name, 'oid_sha256': match[1].decode(), 'bytes': int(match[2]), 'pointer': data})
            else:
                write_exact(clean / name, data, hashes[name])

        def retrieve(item):
            command = ['git', '-c', 'lfs.storage=' + str(store), '-c', 'lfs.dialtimeout=8',
                       '-c', 'lfs.tlstimeout=8', '-c', 'lfs.activitytimeout=8', '-c', 'lfs.transfer.maxretries=0',
                       'lfs', 'smudge', '--', item['path']]
            cached = args.payload_cache / item['path'] if args.payload_cache else None
            if cached and cached.is_file() and cached.stat().st_size == item['bytes'] and sha(cached) == item['oid_sha256']:
                data = cached.read_bytes()
                fresh = False
            else:
                process = subprocess.run(command, cwd=reader, input=item['pointer'], env=env, capture_output=True, timeout=45)
                if process.returncode:
                    raise RuntimeError('Existing payload read failed: ' + item['path'])
                data = process.stdout
                fresh = True
            if len(data) != item['bytes'] or hashlib.sha256(data).hexdigest() != item['oid_sha256']:
                raise RuntimeError('Existing payload identity mismatch: ' + item['path'])
            write_exact(clean / item['path'], data, item['oid_sha256'])
            return {key: value for key, value in item.items() if key != 'pointer'} | {'fresh_independent_read': fresh}

        with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
            for row in pool.map(retrieve, pointers):
                result['runtime_lfs_payloads'].append(row)
                save()
        print(json.dumps({'existing_payloads_verified': len(pointers)}), flush=True)
        slots = private / 'userdata/godot/app_userdata/Where the Light Remains'
        slots.mkdir(parents=True)
        for name in ['savegame.json', 'savegame.backup.json']:
            (slots / name).write_text('{"protected_fixture":true}\n')
        before = {p.name: sha(p) for p in slots.iterdir()}
        env['XDG_DATA_HOME'] = str(private / 'userdata')

        def run(name, command, timeout, marker=''):
            process = subprocess.run(command, cwd=clean, env=env, capture_output=True, timeout=timeout)
            raw = process.stdout + process.stderr
            log = output / (name + '.log')
            log.write_bytes(raw)
            after = {p.name: sha(p) for p in slots.iterdir() if p.is_file()}
            passed = process.returncode == 0 and protected_slots_unchanged(before, after) and \
                (not marker or marker.encode() in raw) and not any(word in raw for word in
                    [b'ERROR:', b'WARNING:', b'SCRIPT ERROR', b'Parse Error'])
            result['records'].append({'name': name, 'passed': passed, 'exit_code': process.returncode,
                                      'slots_before': before, 'slots_after': after, 'log_sha256': sha(log)})
            save()
            print(json.dumps({'command': name, 'passed': passed}), flush=True)
            if not passed:
                raise RuntimeError('UI font validation failed: ' + name)

        godot = str(args.godot.resolve())
        run('clean-import', [godot, '--headless', '--path', str(clean / 'game'), '--editor', '--import'], 180)
        pack = private / 'font-probe.pck'
        reader_project = private / 'pack-reader'
        reader_project.mkdir()
        (reader_project / 'project.godot').write_text('config_version=5\n[application]\nconfig/name="Font Pack Reader"\n')
        run('font-pack', [godot, '--headless', '--path', str(clean / 'game'), '--script',
                         str(root / 'tools/pack_ui_font_probe.gd'), '--', str(pack)], 30, 'UI_FONT_PACK PASS')
        run('font-pack-readback', [godot, '--headless', '--path', str(reader_project), '--script',
                                  str(root / 'tools/read_ui_font_pack.gd'), '--', str(pack),
                                  str(output / 'pack-readback.json')], 30, 'UI_FONT_PACK_READBACK PASS')
        result['font_pack_sha256'] = sha(pack)
        result['font_pack_bytes'] = pack.stat().st_size
        for size in ['1280x720', '1600x900', '1920x1080']:
            run(size, ['python', '-B', str(root / 'tools/run_graphical.py'), '--graphics-prefix',
                       str(args.graphics_prefix.resolve()), '--godot', godot, '--timeout', '120',
                       '--expect', 'UI_FONT_REVIEW CAPTURED', '--', '--path', str(clean / 'game'),
                       '--resolution', size, 'res://tests/ui_font_review.tscn', '--',
                       '--review-output=' + str(output)], 145, 'UI_FONT_REVIEW CAPTURED')
            capture = json.loads((output / ('captures_' + size + '.json')).read_text())
            assert capture['status'] == 'PASS_CAPTURE_ONLY' and capture['renderer'] == 'forward_plus' and len(capture['captures']) == 12
            for item in capture['captures']:
                assert item['size'] == [int(x) for x in size.split('x')]
                result['captures'].append(item | {'sha256': sha(output / item['file'])})
            save()
        for name, expected in hashes.items():
            assert sha(root / name) == expected, ('Source changed during validation', name)
        shutil.rmtree(private)
        result.update(status='PASS_CAPTURE_ONLY', private_copy_removed=True,
                      visual_review='PENDING individual inspection', finished_at=stamp())
    except Exception as error:
        result.update(status='FAIL', failure=str(error), diagnostic_workspace_retained=str(private), finished_at=stamp())
        raise
    finally:
        result['evidence_hashes'] = {p.name: sha(p) for p in output.iterdir() if p.is_file() and p != receipt}
        save()


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', type=Path, required=True)
    parser.add_argument('--graphics-prefix', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--private-workspace', type=Path, required=True)
    parser.add_argument('--payload-cache', type=Path, help='Verified payloads from an owned failed attempt; separately labelled')
    main(parser.parse_args())
