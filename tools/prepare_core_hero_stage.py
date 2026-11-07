#!/usr/bin/env python3
"""Restore exact inputs into an owned private game copy; publish no asset bytes."""
import argparse
import concurrent.futures
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess

from validate_owner_gallery import sha, write_exact, stamp


def main(args):
    root = Path(__file__).resolve().parents[1]
    private = args.workspace.resolve()
    delivery = args.delivery.resolve()
    assert not private.exists() and private.is_relative_to(root.parent) and not private.is_relative_to(root)
    manifest = json.loads((delivery / 'manifest.json').read_text())
    for row in manifest['files']:
        path = delivery / row['path']
        assert path.resolve().is_relative_to(delivery) and path.stat().st_size == row['bytes'] and sha(path) == row['sha256']
    private.mkdir()
    clean = private / 'source'
    env = dict(os.environ, GIT_TERMINAL_PROMPT='0', GIT_ASKPASS='/bin/false',
               GODOT_SILENCE_ROOT_WARNING='1', PYTHONDONTWRITEBYTECODE='1')
    env.pop('GH_TOKEN', None)
    env.pop('GITHUB_TOKEN', None)
    reader = private / 'lfs-reader'
    store = private / 'existing-lfs'
    subprocess.run(['git', 'init', '-q', '-b', 'lfs-read-scratch', str(reader)], env=env, check=True)
    subprocess.run(['git', 'remote', 'add', 'origin', 'https://github.com/MindDevastation/where-the-light-remains.git'], cwd=reader, env=env, check=True)
    subprocess.run(['git', '-c', 'user.name=Archive Review', '-c', 'user.email=review@example.invalid',
                    'commit', '-q', '--allow-empty', '-m', 'Owned read namespace for unchanged runtime assets'], cwd=reader, env=env, check=True)
    pointers = []
    hashes = {}
    for path in sorted((root / 'game').rglob('*')):
        if not path.is_file() or any(p in {'.godot', '__pycache__'} for p in path.parts):
            continue
        name = path.relative_to(root).as_posix()
        data = path.read_bytes()
        hashes[name] = hashlib.sha256(data).hexdigest()
        if name.endswith('.glb'):
            match = re.fullmatch(rb'version https://git-lfs.github.com/spec/v1\noid sha256:([0-9a-f]{64})\nsize ([0-9]+)\n', data)
            assert match and subprocess.check_output(['git', 'show', 'HEAD:' + name], cwd=root) == data
            pointers.append({'path': name, 'oid_sha256': match[1].decode(), 'bytes': int(match[2]), 'pointer': data})
        else:
            write_exact(clean / name, data, hashes[name])

    def retrieve(item):
        cache = args.payload_cache / item['path'] if args.payload_cache else None
        if cache and cache.is_file() and cache.stat().st_size == item['bytes'] and sha(cache) == item['oid_sha256']:
            data = cache.read_bytes()
            fresh = False
        else:
            command = ['git', '-c', 'lfs.storage=' + str(store), '-c', 'lfs.dialtimeout=8',
                       '-c', 'lfs.tlstimeout=8', '-c', 'lfs.activitytimeout=8', '-c', 'lfs.transfer.maxretries=0',
                       'lfs', 'smudge', '--', item['path']]
            process = subprocess.run(command, cwd=reader, input=item['pointer'], env=env, capture_output=True, timeout=45)
            assert process.returncode == 0, 'Existing payload read failed: ' + item['path']
            data = process.stdout
            fresh = True
        assert len(data) == item['bytes'] and hashlib.sha256(data).hexdigest() == item['oid_sha256']
        write_exact(clean / item['path'], data, item['oid_sha256'])
        return {k: v for k, v in item.items() if k != 'pointer'} | {'fresh_independent_read': fresh}

    records = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        for record in pool.map(retrieve, pointers):
            records.append(record)
    assert len(records) == 47
    recovered = []
    for name in ['game/art/meshes/hero_props/sm_s01_archive_core_hero_v1.glb',
                 'game/art/meshes/archive_kit/sm_s01_core_upper_v1.glb']:
        path = delivery / name
        write_exact(clean / name, path.read_bytes(), sha(path))
        recovered.append({'path': name, 'bytes': path.stat().st_size, 'sha256': sha(path),
                          'scope': 'Private recovered copy only; not a repository upload or LFS pointer'})
    baseline = clean / 'game/tests/fixtures/core_hero_baseline_20261107.tscn'
    write_exact(baseline, (root / 'game/worlds/archive/archive_main.tscn').read_bytes(),
                hashes['game/worlds/archive/archive_main.tscn'])
    result = {'status': 'RESTORED_PRIVATE_INPUTS_ONLY', 'utc': stamp(), 'source_hashes': hashes,
              'existing_runtime_lfs_payloads': records, 'recovered_private_payloads': recovered,
              'repo_head_at_restore': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=root).decode().strip(),
              'repository_asset_writes': 0, 'new_lfs_uploads': 0}
    (private / 'inputs.json').write_text(json.dumps(result, indent=2) + '\n')
    print('CORE_HERO_STAGE_INPUTS PASS:40 delivery identities;47 existing runtime payloads;two private recovered GLBs')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--workspace', type=Path, required=True)
    parser.add_argument('--delivery', type=Path, required=True)
    parser.add_argument('--payload-cache', type=Path)
    main(parser.parse_args())
