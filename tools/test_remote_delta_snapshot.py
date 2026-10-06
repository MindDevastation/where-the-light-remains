"""Recover actual staged/unstaged/binary/LFS state from a small remote delta."""
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time

from remote_delta_snapshot import git, snapshot, restore, verify
from durable_checkpoint import Coordinator


def main():
    with tempfile.TemporaryDirectory(prefix='wlr-delta-fixture-') as temporary:
        root = Path(temporary)
        source, remote = root / 'source', root / 'remote.git'
        source.mkdir()
        git(root, 'init', '--bare', '-q', str(remote))
        git(source, 'init', '-q', '-b', 'feature/delta-test')
        git(source, 'config', 'user.name', 'Delta fixture')
        git(source, 'config', 'user.email', 'delta@example.invalid')
        git(source, 'config', 'core.hooksPath', '/dev/null')
        git(source, 'remote', 'add', 'origin', str(remote))
        # Large unchanged baseline must not enter the delta archive.
        (source / 'unchanged.bin').write_bytes(os.urandom(2*1024*1024))
        (source / '.gitattributes').write_text('*.blend filter=lfs diff=lfs merge=lfs -text\n')
        (source / 'edited.txt').write_text('baseline\n')
        (source / 'reverted.txt').write_text('baseline\n')
        (source / 'deleted.txt').write_text('delete me\n')
        (source / 'renamed.txt').write_text('rename me\n')
        (source / 'asset.blend').write_bytes(b'baseline binary\0'*256)
        git(source, 'add', '.')
        git(source, 'commit', '-qm', 'baseline')
        git(source, 'push', '-q', 'origin', 'HEAD')
        baseline = git(source, 'rev-parse', 'HEAD')
        (source / 'edited.txt').write_text('staged\n')
        (source / 'reverted.txt').write_text('staged transient\n')
        (source / 'asset.blend').write_bytes(b'staged binary\0'*256)
        git(source, 'add', 'edited.txt', 'reverted.txt', 'asset.blend')
        (source / 'edited.txt').write_text('unstaged\n')
        (source / 'reverted.txt').write_text('baseline\n')
        (source / 'asset.blend').write_bytes(b'unstaged binary\0'*256)
        (source / 'deleted.txt').unlink()
        git(source, 'mv', 'renamed.txt', 'moved.txt')
        (source / 'untracked.bin').write_bytes(b'untracked bytes\0'*256)
        (source / 'new folder').mkdir()
        (source / 'new folder/space name.txt').write_text('spaces survive\n')
        expected_status = git(source, 'status', '--porcelain=v1', '-z')
        expected_index = git(source, 'ls-files', '--stage', '-z')
        expected_files = {p.relative_to(source).as_posix():hashlib.sha256(p.read_bytes()).hexdigest()
                          for p in source.rglob('*') if p.is_file() and '.git' not in p.parts}
        started = time.monotonic()
        archive = snapshot(source, root / 'snapshots')
        state = verify(archive)
        assert state['remote_verified_sha'] == baseline.decode().strip()
        assert archive.stat().st_size < 100_000 and time.monotonic()-started < 20
        assert 'reverted.txt' in state['worktrees'][0]['changed_paths']
        # Advance the remote after collection. Recovery must pin the old SHA.
        git(source, 'add', '.')
        git(source, 'commit', '-qm', 'later state')
        git(source, 'push', '-q', 'origin', 'HEAD')
        recovered = root / 'recovered'
        restore(archive, recovered)
        assert git(recovered, 'rev-parse', 'HEAD') == baseline
        assert git(recovered, 'status', '--porcelain=v1', '-z') == expected_status
        assert git(recovered, 'ls-files', '--stage', '-z') == expected_index
        actual_files = {p.relative_to(recovered).as_posix():hashlib.sha256(p.read_bytes()).hexdigest()
                        for p in recovered.rglob('*') if p.is_file() and '.git' not in p.parts}
        assert actual_files == expected_files
        print('PASS: exact old remote baseline, staged/unstaged edits, deletion, rename, spaces, binary and materialized LFS roundtrip; archive',archive.stat().st_size,'bytes',flush=True)
        # Refuse overwriting an existing recovery and unpublished local HEAD.
        try:
            restore(archive, recovered)
        except RuntimeError:
            pass
        else:
            raise AssertionError('Existing destination accepted')
        (source / 'edited.txt').write_text('unpublished head\n')
        git(source, 'add', '.')
        git(source, 'commit', '-qm', 'unpublished')
        try:
            snapshot(source, root / 'snapshots')
        except RuntimeError as error:
            assert 'exactly match' in str(error)
        else:
            raise AssertionError('Unpublished baseline accepted')
        git(source, 'push', '-q', 'origin', 'HEAD')
        (source / 'foreign-link').symlink_to(root / 'foreign')
        (root / 'foreign').write_text('foreign\n')
        try:
            snapshot(source, root / 'snapshots')
        except RuntimeError as error:
            assert 'symlink' in str(error)
        else:
            raise AssertionError('Symlink accepted')
        (source / 'foreign-link').unlink()
        (source / 'secret.txt').write_bytes(b'github_pat_' + b'X'*80)
        try:
            snapshot(source, root / 'snapshots')
        except RuntimeError as error:
            assert 'credential' in str(error)
        else:
            raise AssertionError('Credential accepted')
        (source / 'secret.txt').unlink()
        print('PASS: stale/unpublished baseline, symlink, credentials and existing recovery refused',flush=True)
        # Exercise coordinator publication with this actual optional mode.
        (source / 'game').mkdir()
        (source / 'game/change.txt').write_text('coordinator fixture\n')
        loop = Coordinator(source, root / 'coordinator-snapshots', 'feature/delta-test',
                           'delta coordinator fixture', fixture=True, snapshot_mode='remote-delta')
        result = loop.checkpoint()
        assert result['status'] == 'REMOTE_PASS'
        assert git(source, 'ls-remote', 'origin', 'refs/heads/feature/delta-test').decode().split()[0] == result['remote_sha']
        assert not git(source, 'status', '--porcelain=v1').strip()
        print('PASS: delta coordinator snapshot, actual commit/push and independently resolved receipt SHA',flush=True)


if __name__ == '__main__':
    main()
