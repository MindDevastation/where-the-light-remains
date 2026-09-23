#!/usr/bin/env python3
"""Restore verified Ubuntu 24.04 x86_64 graphics packages into a local prefix.

Requires Python 3.11+, dpkg/dpkg-deb and compatible Ubuntu system libraries.
Uses a lock derived from signed snapshot metadata; executes no maintainer scripts.
"""
import argparse
import hashlib
import json
from pathlib import Path
import platform
import shutil
import subprocess
import time
from urllib.request import urlopen


def verify(path, package):
    with path.open('rb') as stream:
        digest = hashlib.file_digest(stream, 'sha256').hexdigest()
    if path.stat().st_size != int(package['Size']) or digest != package['SHA256']:
        raise RuntimeError('Package size/checksum mismatch: ' + str(path))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--prefix', required=True, type=Path)
    args = parser.parse_args()
    if platform.system() != 'Linux' or platform.machine() != 'x86_64':
        parser.error('Requires Linux x86_64 with Ubuntu 24.04-compatible libraries')
    for name in ('dpkg-query', 'dpkg-deb'):
        if not shutil.which(name):
            parser.error('Missing base utility: ' + name)
    lock = json.loads(Path(__file__).with_name('linux_graphics_packages.json').read_text())
    prefix = args.prefix.resolve()
    prefix.mkdir(parents=True, exist_ok=True)
    if shutil.disk_usage(prefix).free < sum(int(p['Size']) for p in lock['packages']) * 8 + 256 * 1024**2:
        raise RuntimeError('Insufficient disk space for local graphics extraction')
    cache = prefix / 'archives'
    cache.mkdir(exist_ok=True)
    for package in lock['packages']:
        if package.get('prefer_system'):
            installed = subprocess.run(['dpkg-query', '-W', '-f=${Status} ${Version}', package['Package']], capture_output=True, text=True)
            if installed.returncode == 0 and installed.stdout == 'install ok installed ' + package['Version']:
                print(package['Package'] + ' ' + package['Version'] + ': verified system package', flush=True)
                continue
        archive = cache / Path(package['Filename']).name
        if not archive.exists():
            partial = archive.with_suffix(archive.suffix + '.part')
            failures = []
            for mirror in lock['mirrors']:
                try:
                    started = time.monotonic()
                    with urlopen(mirror + package['Filename'], timeout=30) as response, partial.open('wb') as output:
                        while block := response.read(1024 * 1024):
                            output.write(block)
                            if output.tell() > int(package['Size']) or time.monotonic() - started > 120:
                                raise RuntimeError('Download size/time bound exceeded')
                    verify(partial, package)
                    break
                except Exception as error:
                    failures.append(mirror + ': ' + str(error))
                    print('Trying next verified source after: ' + failures[-1], flush=True)
            else:
                raise RuntimeError('Package restoration failed: ' + '; '.join(failures))
            partial.replace(archive)
        verify(archive, package)
        subprocess.run(['dpkg-deb', '-x', str(archive), str(prefix)], check=True)
        print(package['Package'] + ' ' + package['Version'] + ': checksum/extraction PASS', flush=True)
    icds = list((prefix / 'usr/share/vulkan/icd.d').glob('*lvp*.json'))
    if len(icds) != 1:
        raise RuntimeError('Expected exactly one lavapipe ICD')
    data = json.loads(icds[0].read_text())
    library = prefix / 'usr/lib/x86_64-linux-gnu' / Path(data['ICD']['library_path']).name
    if not library.is_file():
        raise RuntimeError('Missing extracted lavapipe library: ' + str(library))
    data['ICD']['library_path'] = str(library)
    icds[0].write_text(json.dumps(data) + '\n')
    target = prefix / 'usr/bin/xkbcomp'
    link = Path('/usr/bin/xkbcomp')
    if not link.exists() and not link.is_symlink():
        link.symlink_to(target)
    if not link.is_file():
        raise RuntimeError('Xvfb hard-coded xkbcomp path is unavailable: ' + str(link))
    print('GRAPHICS_SETUP PASS: local packages; lavapipe ICD; xkbcomp=' + str(link.resolve()))


if __name__ == '__main__':
    main()
