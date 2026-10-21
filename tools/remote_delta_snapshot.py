"""Small recovery archive relative to an independently verified remote HEAD.

Requires the recorded remote baseline; this is not an offline repository backup.
Retains staged/unstaged patches and changed materialized files including LFS.
"""
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import tarfile
import tempfile

from session_snapshot import CREDENTIAL, PRIVATE_NAMES, copy_checked, identity, stamp, worktrees, write_json


def git(repo, *args, timeout=55):
    env = dict(os.environ, GIT_LFS_SKIP_SMUDGE='1', GIT_TERMINAL_PROMPT='0', GIT_NO_LAZY_FETCH='1')
    result = subprocess.run(['git', '-C', str(repo), *args], env=env, capture_output=True, timeout=timeout)
    if result.returncode:
        raise RuntimeError('Remote delta git operation failed: ' + args[0])
    return result.stdout


def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def media_directory(repo):
    lines = git(repo, 'lfs', 'env').decode().splitlines()
    return Path(next(line.split('=',1)[1] for line in lines if line.startswith('LocalMediaDir=')))


def snapshot(repo, output):
    repo, output = repo.resolve(), output.resolve()
    started = stamp()
    if worktrees(repo) != [repo]:
        raise RuntimeError('Remote delta currently supports one source worktree')
    if output == repo or repo in output.parents:
        raise RuntimeError('Snapshot output must be outside the source worktree')
    baseline = identity(repo)
    branch = baseline['branch']
    if branch in {'main', 'master', 'HEAD'} or not re.fullmatch(r'(?:feature|work|epic)/[a-z0-9_/.-]+', branch):
        raise RuntimeError('A dedicated working branch is required')
    remote = git(repo, 'remote', 'get-url', 'origin').decode().strip()
    if CREDENTIAL.search(remote.encode()) or re.search(r'https?://[^/]*@', remote):
        raise RuntimeError('Credential-bearing remote URL refused')
    ref = 'refs/heads/' + branch
    def verify_remote():
        found = git(repo, 'ls-remote', 'origin', ref).decode().split()
        if found != [baseline['head'], ref]:
            raise RuntimeError('Current HEAD must exactly match the remote working branch before delta collection')
    verify_remote()
    output.mkdir(parents=True, exist_ok=True)
    changed = set(git(repo, 'diff', '--no-renames', '--name-only', '-z', 'HEAD').split(b'\0'))
    changed.update(git(repo, 'diff', '--cached', '--no-renames', '--name-only', '-z').split(b'\0'))
    changed.update(git(repo, 'diff', '--no-renames', '--name-only', '-z').split(b'\0'))
    changed.update(git(repo, 'ls-files', '--others', '--exclude-standard', '-z').split(b'\0'))
    changed.discard(b'')
    with tempfile.TemporaryDirectory(prefix='.delta-', dir=output) as temporary:
        stage = Path(temporary)
        files = stage / 'worktrees/0/files'
        files.mkdir(parents=True)
        deleted, paths = [], []
        staged_lfs = []
        for raw in sorted(changed):
            name = Path(os.fsdecode(raw))
            if name.is_absolute() or '..' in name.parts or '.git' in name.parts:
                raise RuntimeError('Unsafe changed path')
            if any(part in PRIVATE_NAMES or part.startswith('.env.') for part in name.parts):
                raise RuntimeError('Credential path refused')
            paths.append(name.as_posix())
            source = repo / name
            if not source.exists() and not source.is_symlink():
                deleted.append(name.as_posix())
            else:
                copy_checked(source, files / name)
            # The worktree can differ from the staged LFS version. Preserve that
            # version's actual payload as well as its index pointer/patch.
            index = subprocess.run(['git','-C',str(repo),'show',':'+name.as_posix()],
                                   capture_output=True, timeout=55)
            pointer = re.fullmatch(rb'version https://git-lfs.github.com/spec/v1\noid sha256:([0-9a-f]{64})\nsize ([0-9]+)\n',index.stdout) if index.returncode == 0 else None
            if pointer:
                oid, size = pointer[1].decode(), int(pointer[2])
                cached = media_directory(repo) / oid[:2] / oid[2:4] / oid
                if cached.is_file():
                    if cached.stat().st_size != size:
                        raise RuntimeError('Staged LFS payload size mismatch')
                    target = stage / 'lfs_objects' / oid
                    if not target.exists():
                        copy_checked(cached, target, oid)
                    staged_lfs.append({'path':name.as_posix(),'oid':oid,'bytes':size,'retained':True})
                else:
                    head = subprocess.run(['git','-C',str(repo),'show','HEAD:'+name.as_posix()],
                                          capture_output=True, timeout=55)
                    if head.returncode or head.stdout != index.stdout:
                        raise RuntimeError('Unpublished staged LFS payload missing from local cache')
                    staged_lfs.append({'path':name.as_posix(),'oid':oid,'bytes':size,'retained':False,
                                       'scope':'Unchanged remote baseline object; hydration required'})
        for name, args in [
            ('staged.patch', ('diff', '--cached', '--binary', '--no-renames', '--no-ext-diff')),
            ('unstaged.patch', ('diff', '--binary', '--no-renames', '--no-ext-diff')),
            ('status.porcelain', ('status', '--porcelain=v1', '-z')),
        ]:
            raw = git(repo, *args)
            if CREDENTIAL.search(raw):
                raise RuntimeError('Credential pattern in recovery metadata')
            (stage / 'worktrees/0' / name).write_bytes(raw)
        for path in files.rglob('*'):
            if path.is_file():
                original = repo / path.relative_to(files)
                if original.is_symlink() or digest(original) != digest(path):
                    raise RuntimeError('Changed payload identity changed during collection')
        if identity(repo) != baseline:
            raise RuntimeError('Source Git state changed during collection')
        verify_remote()
        write_json(stage / 'state.json', {
            'started_utc': started, 'history': {'mode': 'remote_delta', 'complete': False},
            'remote': remote, 'remote_ref': ref, 'remote_verified_sha': baseline['head'],
            'staged_lfs': staged_lfs,
            'worktrees': [dict(baseline, id=0, changed_paths=paths, absent_files=deleted)],
            'scope': 'Changed files and staged/unstaged state only. Recovery requires the exact remote baseline and its existing LFS objects; no complete/offline backup claim.'
        })
        manifest = {p.relative_to(stage).as_posix(): {'bytes': p.stat().st_size, 'sha256': digest(p)}
                    for p in stage.rglob('*') if p.is_file()}
        write_json(stage / 'manifest.json', manifest)
        target = output / ('wlr-remote-delta-' + stamp().replace(':', '').replace('+', '_') + '.tar.gz')
        partial = target.with_suffix(target.suffix + '.partial')
        try:
            with tarfile.open(partial, 'w:gz') as archive:
                for path in sorted(stage.iterdir()):
                    archive.add(path, arcname=path.name)
            verify(partial)
            partial.replace(target)
            target.with_name(target.name + '.sha256').write_text(digest(target) + '  ' + target.name + '\n')
        finally:
            partial.unlink(missing_ok=True)
        return target


def verify(archive):
    with tempfile.TemporaryDirectory(prefix='delta-verify-') as temporary:
        root = Path(temporary)
        with tarfile.open(archive) as reader:
            members = reader.getmembers()
            if any(not (m.isfile() or m.isdir()) or Path(m.name).is_absolute() or '..' in Path(m.name).parts for m in members):
                raise RuntimeError('Unsafe delta archive member')
            reader.extractall(root, filter='data')
        manifest = json.loads((root / 'manifest.json').read_text())
        actual = {p.relative_to(root).as_posix() for p in root.rglob('*') if p.is_file()}
        if actual != set(manifest) | {'manifest.json'}:
            raise RuntimeError('Delta manifest coverage mismatch')
        for name, entry in manifest.items():
            path = root / name
            if path.stat().st_size != entry['bytes'] or digest(path) != entry['sha256']:
                raise RuntimeError('Delta payload checksum mismatch')
        state = json.loads((root / 'state.json').read_text())
        if state['history'] != {'mode': 'remote_delta', 'complete': False} or len(state['worktrees']) != 1:
            raise RuntimeError('Unexpected delta recovery scope')
        if not re.fullmatch('[0-9a-f]{40}', state['remote_verified_sha']) or state['remote_verified_sha'] != state['worktrees'][0]['head']:
            raise RuntimeError('Invalid recovery baseline')
        return state


def restore(archive, destination):
    """Recover only into a new folder; remote may have advanced after collection."""
    state = verify(archive)
    destination = destination.resolve()
    if destination.exists():
        raise RuntimeError('Recovery requires a new destination')
    with tempfile.TemporaryDirectory(prefix='delta-restore-') as temporary:
        root = Path(temporary)
        with tarfile.open(archive) as reader:
            reader.extractall(root, filter='data')
        destination.parent.mkdir(parents=True, exist_ok=True)
        git(destination.parent, 'init', '-q', str(destination))
        git(destination, 'remote', 'add', 'origin', state['remote'])
        sha = state['remote_verified_sha']
        git(destination, 'fetch', '--depth=1', '--filter=blob:none', 'origin', sha, timeout=300)
        git(destination, 'checkout', '-q', '-b', state['worktrees'][0]['branch'], sha, timeout=300)
        # Keep index-version objects in the new checkout's own LFS store, even
        # if the captured working file contains a different unstaged version.
        git(destination, 'config', '--local', 'lfs.storage', str(destination / '.git/lfs'))
        media = media_directory(destination)
        for entry in state.get('staged_lfs',[]):
            if entry['retained']:
                oid = entry['oid']
                if not re.fullmatch('[0-9a-f]{64}',oid):
                    raise RuntimeError('Invalid staged LFS identity')
                target = media / oid[:2] / oid[2:4] / oid
                if not target.exists():
                    copy_checked(root / 'lfs_objects' / oid,target,oid)
        for name, index in [('staged.patch', True), ('unstaged.patch', False)]:
            patch = root / 'worktrees/0' / name
            if patch.stat().st_size:
                args = ['apply'] + (['--index'] if index else []) + [str(patch)]
                git(destination, *args)
        files = root / 'worktrees/0/files'
        for path in files.rglob('*'):
            if path.is_file():
                target = destination / path.relative_to(files)
                if not target.parent.resolve().is_relative_to(destination):
                    raise RuntimeError('Recovered parent path escapes the destination')
                target.parent.mkdir(parents=True, exist_ok=True)
                if target.exists() or target.is_symlink():
                    target.unlink()
                copy_checked(path, target)
        if git(destination, 'status', '--porcelain=v1', '-z') != (root / 'worktrees/0/status.porcelain').read_bytes():
            raise RuntimeError('Recovered staged/unstaged state mismatch')
    return state


if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    operations = parser.add_mutually_exclusive_group(required=True)
    operations.add_argument('--create', type=Path, metavar='OUTPUT_FOLDER')
    operations.add_argument('--verify', type=Path, metavar='ARCHIVE')
    operations.add_argument('--restore', type=Path, metavar='ARCHIVE')
    parser.add_argument('--repo', type=Path, default=Path.cwd())
    parser.add_argument('--destination', type=Path)
    args = parser.parse_args()
    if args.create:
        print(json.dumps({'status':'PASS','archive':str(snapshot(args.repo,args.create))}))
    elif args.verify:
        print(json.dumps({'status':'PASS','baseline':verify(args.verify)['remote_verified_sha']}))
    else:
        if not args.destination:
            parser.error('--restore requires --destination pointing to a new folder')
        print(json.dumps({'status':'PASS','baseline':restore(args.restore,args.destination)['remote_verified_sha']}))
