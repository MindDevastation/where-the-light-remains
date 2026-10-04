#!/usr/bin/env python3
"""Prepare and verify connector checkpoints when shell Git push lacks credentials.

API publication is performed by the authenticated GitHub connector. This helper
never handles credentials and never rewrites/deletes refs. Each request must use
force=false and the exact parent/tree returned by prepare.
"""
import argparse
import base64
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import tarfile

BRANCH = 'feature/04-archive-gameplay/checkpoints-2026-10-04'
REPO_URL = 'https://github.com/MindDevastation/where-the-light-remains.git'
PRIVATE = {'.env', '.netrc', '.git-credentials', 'export_credentials.cfg', '.godot', '.import', '__pycache__'}
TOKEN = re.compile(rb'(?:github_pat_|gh[pousr]_)[A-Za-z0-9_]{20,}')


def stamp():
    return dt.datetime.now(dt.timezone.utc).isoformat()


def git(*args):
    return subprocess.check_output(['git', *args], env=dict(os.environ, GIT_TERMINAL_PROMPT='0'), timeout=55)


def identity():
    branch = git('branch', '--show-current').decode().strip()
    if branch != BRANCH or git('remote', 'get-url', 'origin').decode().strip() != REPO_URL:
        raise RuntimeError('Unexpected branch/origin')
    return git('rev-parse', 'HEAD').decode().strip()


def prepare(args):
    parent = identity()
    # Both index and worktree changes are inspected before staging explicit paths.
    review = {k: git(*v).decode() for k, v in {
        'status': ('status', '--short', '--branch'),
        'diff': ('diff', '--no-ext-diff', '--stat'),
        'staged_diff': ('diff', '--cached', '--no-ext-diff', '--stat'),
    }.items()}
    paths = set(git('diff', '--name-only', '-z').split(b'\0') +
                git('diff', '--cached', '--name-only', '-z').split(b'\0') +
                git('ls-files', '--others', '--exclude-standard', '-z').split(b'\0')) - {b''}
    if not paths:
        raise RuntimeError('No checkpoint delta')
    paths = sorted(os.fsdecode(p) for p in paths)
    for name in paths:
        p = Path(name)
        if p.is_absolute() or '..' in p.parts or not name.startswith(('game/', 'tools/', 'docs/')):
            raise RuntimeError('Explicit review required: ' + name)
        if any(part in PRIVATE or part.startswith('.env.') for part in p.parts) or not p.is_file() or p.is_symlink():
            raise RuntimeError('Unsafe or deleted checkpoint path: ' + name)
        data = p.read_bytes()
        if len(data) > 8 * 1024**2 or TOKEN.search(data):
            raise RuntimeError('Oversized or credential-like checkpoint file: ' + name)
    if args.validation:
        v = json.loads(args.validation.read_text())
        if v.get('status') != 'PASS' or not v.get('source_hashes'):
            raise RuntimeError('Stable receipt lacks PASS/source hashes')
        for path, expected in v['source_hashes'].items():
            if hashlib.sha256(Path(path).read_bytes()).hexdigest() != expected:
                raise RuntimeError('Source changed after validation: ' + path)
        review['validation'] = str(args.validation)
    git('add', '--', *paths)
    git('diff', '--cached', '--check')
    tree = git('write-tree').decode().strip()
    entries = []
    for name in paths:
        mode = git('ls-files', '-s', '--', name).decode().split()[0]
        data = git('show', ':' + name)
        entry = {'path': name, 'mode': mode, 'type': 'blob'}
        try:
            entry['content'] = data.decode('utf-8')
        except UnicodeDecodeError:
            entry['base64'] = base64.b64encode(data).decode()
        entries.append(entry)
    # A small local delta snapshot complements the remote parent, excluding
    # immutable audio/concept masters, object packs and import/toolchain caches.
    archive = args.output.with_suffix('.tar.gz')
    with tarfile.open(archive, 'w:gz') as package:
        for name in paths:
            package.add(name, arcname=name)
    v = {'parent': parent, 'base_tree': git('rev-parse', 'HEAD^{tree}').decode().strip(),
         'tree': tree, 'branch': BRANCH, 'created_at': stamp(), 'entries': entries,
         'review': review, 'delta_snapshot': str(archive),
         'delta_snapshot_sha256': hashlib.sha256(archive.read_bytes()).hexdigest(),
         'snapshot_scope': 'Changed source/evidence plus parent commit; not a full object/toolchain backup.'}
    args.output.write_text(json.dumps(v, ensure_ascii=False))
    print(json.dumps({k: v[k] for k in ('parent', 'tree', 'branch', 'created_at', 'delta_snapshot_sha256')}))
    print(json.dumps({'paths': paths, 'review': review}, ensure_ascii=False))


def accept(args):
    v = json.loads(args.payload.read_text())
    if not re.fullmatch('[0-9a-f]{40}', args.sha):
        raise RuntimeError('Invalid commit SHA')
    if identity() != v['parent'] or git('write-tree').decode().strip() != v['tree'] or git('diff', '--name-only').strip():
        raise RuntimeError('Local source/index/parent changed during publication')
    git('fetch', '--filter=blob:none', 'origin', BRANCH)
    remote = git('ls-remote', 'origin', 'refs/heads/' + BRANCH).decode().split()
    if remote != [args.sha, 'refs/heads/' + BRANCH]:
        raise RuntimeError('Remote SHA mismatch')
    if git('rev-parse', args.sha + '^').decode().strip() != v['parent'] or git('rev-parse', args.sha + '^{tree}').decode().strip() != v['tree']:
        raise RuntimeError('Remote commit parent/tree mismatch')
    git('update-ref', 'refs/heads/' + BRANCH, args.sha, v['parent'])
    if git('status', '--porcelain').strip():
        raise RuntimeError('Accepted remote source did not leave a clean checkout')
    receipt = {'status': 'REMOTE_PASS', 'utc': stamp(), 'checkpoint_commit': args.sha,
               'parent': v['parent'], 'tree': v['tree'], 'branch': BRANCH,
               'force': False, 'transport': 'Authenticated GitHub Git-data connector',
               'delta_snapshot_sha256': v['delta_snapshot_sha256'],
               'paths': [e['path'] for e in v['entries']],
               'verification': 'Independent git fetch and ls-remote; exact parent/index tree; guarded local fast-forward; clean checkout.'}
    log = Path('docs/production/evidence/checkpoints/gitdata_publications.jsonl')
    with log.open('a') as stream:
        stream.write(json.dumps(receipt, ensure_ascii=False) + '\n')
    print(json.dumps(receipt, ensure_ascii=False))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='op', required=True)
    p = sub.add_parser('prepare')
    p.add_argument('--output', type=Path, required=True)
    p.add_argument('--validation', type=Path)
    p = sub.add_parser('accept')
    p.add_argument('--payload', type=Path, required=True)
    p.add_argument('--sha', required=True)
    args = parser.parse_args()
    {'prepare': prepare, 'accept': accept}[args.op](args)
