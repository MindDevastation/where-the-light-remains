"""Restore missing HEAD Git blobs without changing refs or working files.

Requires authenticated gh and public raw GitHub access. Downloaded files must
match immutable tree metadata (Git blob SHA-1 and size) before object insertion.
This repairs ordinary Git objects; it does not retrieve LFS payloads.
"""
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from urllib.parse import quote
from urllib.request import urlopen
import argparse
import hashlib
import json
import os
import shutil
import subprocess
import tempfile
import time

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--repo', type=Path, required=True)
parser.add_argument('--scratch', type=Path, required=True)
parser.add_argument('--jobs', type=int, default=4, choices=range(1, 9))
args = parser.parse_args()
repo = args.repo.resolve()
args.scratch.mkdir(parents=True, exist_ok=True)
env = os.environ.copy()
env['GIT_NO_LAZY_FETCH'] = '1'
env['GIT_TERMINAL_PROMPT'] = '0'


def git(*arguments, **kwargs):
    return subprocess.check_output(['git', *arguments], cwd=repo, env=env,
                                   text=True, **kwargs).strip()


head = git('rev-parse', 'HEAD')
tree = git('rev-parse', 'HEAD^{tree}')
refs = git('show-ref')
origin = git('remote', 'get-url', 'origin')
expected_repo = 'MindDevastation/where-the-light-remains'
if origin.rstrip('/').removesuffix('.git') != 'https://github.com/' + expected_repo:
    raise RuntimeError('Unexpected origin; no repair performed')
metadata = json.loads(subprocess.check_output(
    ['gh', 'api', f'repos/{expected_repo}/git/trees/{tree}?recursive=1'],
    env=env, text=True, timeout=60))
if metadata['sha'] != tree or metadata['truncated']:
    raise RuntimeError('Incomplete or mismatched immutable tree metadata')
blobs = {item['sha']: item for item in metadata['tree'] if item['type'] == 'blob'}
oids = list(blobs)
state = git('cat-file', '--batch-check=%(objectname) %(objecttype) %(objectsize)',
            input='\n'.join(oids) + '\n')
missing = [blobs[line.split()[0]] for line in state.splitlines() if line.endswith(' missing')]
total = sum(item['size'] for item in missing)
reserve = total * 1.25 + 2 * 1024**3
object_dir = Path(git('rev-parse', '--path-format=absolute', '--git-path', 'objects'))
if min(shutil.disk_usage(object_dir).free, shutil.disk_usage(args.scratch).free) < reserve:
    raise RuntimeError('Insufficient disk space for verified object hydration')
print(f'HEAD: {head}; missing blobs: {len(missing)}; bytes: {total}', flush=True)


def restore(item):
    url = f'https://raw.githubusercontent.com/{expected_repo}/{head}/' + quote(item['path'], safe='/')
    digest = hashlib.sha1(f'blob {item["size"]}\0'.encode())
    count = 0
    started = time.monotonic()
    with tempfile.TemporaryDirectory(prefix='git-blob-', dir=args.scratch) as directory:
        target = Path(directory) / 'payload'
        with urlopen(url, timeout=45) as response, target.open('wb') as output:
            if response.status != 200:
                raise RuntimeError(f'HTTP {response.status}: {item["path"]}')
            while block := response.read(1024 * 1024):
                count += len(block)
                if count > item['size'] or time.monotonic() - started > 180:
                    raise RuntimeError(f'Size/time bound exceeded: {item["path"]}')
                digest.update(block)
                output.write(block)
            output.flush()
            os.fsync(output.fileno())
        if count != item['size'] or digest.hexdigest() != item['sha']:
            raise RuntimeError(f'Git blob size/hash mismatch: {item["path"]}')
        if git('hash-object', '-w', '--no-filters', str(target)) != item['sha']:
            raise RuntimeError(f'Object-store hash mismatch: {item["path"]}')
    return item


with ThreadPoolExecutor(max_workers=args.jobs) as pool:
    futures = [pool.submit(restore, item) for item in missing]
    try:
        for index, future in enumerate(as_completed(futures), 1):
            item = future.result()
            print(f'Restored {index}/{len(missing)}: {item["sha"]} ({item["size"]} bytes)', flush=True)
    except Exception:
        for future in futures:
            future.cancel()
        raise
after = git('cat-file', '--batch-check=%(objectname) %(objecttype) %(objectsize)',
            input='\n'.join(oids) + '\n')
if any(line.endswith(' missing') for line in after.splitlines()):
    raise RuntimeError('Missing HEAD objects remain')
if git('rev-parse', 'HEAD') != head or git('show-ref') != refs:
    raise RuntimeError('Refs changed during validation; recheck required')
print(f'HYDRATION PASS: all {len(oids)} HEAD blobs available; refs unchanged', flush=True)
