"""Restore the validated Linux x86_64 tools into an explicit local prefix.

Requires Python 3.12+, curl, Git and Git LFS. Does not configure authentication.
"""
from pathlib import Path
import argparse
import hashlib
import os
import platform
import shutil
import subprocess
import sys
import tarfile
import zipfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--prefix', required=True, type=Path)
args = parser.parse_args()
if platform.system() != 'Linux' or platform.machine() != 'x86_64' or sys.version_info < (3, 12):
    parser.error('Requires Linux x86_64 and Python 3.12+')
for tool in ('curl', 'git', 'git-lfs'):
    if not shutil.which(tool):
        parser.error(f'Required base utility is missing: {tool}')
prefix = args.prefix.resolve()
prefix.mkdir(parents=True, exist_ok=True)
(prefix / 'bin').mkdir(exist_ok=True)

packages = [
    ('godot',
     'https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip',
     'cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4',
     'godot-4.7.2', 'Godot_v4.7.2-stable_linux.x86_64'),
    ('blender',
     'https://download.blender.org/release/Blender4.5/blender-4.5.14-linux-x64.tar.xz',
     '9ba871ff2ecd36526b77432745980b7e6664ecd0c7ca11c48849073dcfe06da3',
     '.', 'blender-4.5.14-linux-x64/blender'),
    ('gh',
     'https://github.com/cli/cli/releases/download/v2.101.0/gh_2.101.0_linux_amd64.tar.gz',
     '9bca2d1c16825f109907a23307628a2f0698fbf99662b73a5cf0b020293072b8',
     '.', 'gh_2.101.0_linux_amd64/bin/gh'),
]
for name, url, expected, folder, binary in packages:
    archive = prefix / url.rsplit('/', 1)[1]
    if not archive.exists():
        partial = archive.with_name(archive.name + '.part')
        subprocess.run(['curl', '--location', '--fail', '--silent', '--show-error',
                        '--connect-timeout', '15', '--max-time', '300',
                        '--output', str(partial), url], check=True)
        with partial.open('rb') as stream:
            if hashlib.file_digest(stream, 'sha256').hexdigest() != expected:
                raise RuntimeError(f'{name}: downloaded archive checksum mismatch')
        partial.rename(archive)
    with archive.open('rb') as stream:
        if hashlib.file_digest(stream, 'sha256').hexdigest() != expected:
            raise RuntimeError(f'{name}: cached archive checksum mismatch')
    destination = prefix / folder
    destination.mkdir(parents=True, exist_ok=True)
    if archive.suffix == '.zip':
        with zipfile.ZipFile(archive) as package:
            for member in package.namelist():
                if not (destination / member).resolve().is_relative_to(destination.resolve()):
                    raise RuntimeError('Unsafe archive member')
            package.extractall(destination)
    else:
        with tarfile.open(archive, mode='r|*') as package:
            for member in package:
                safe = tarfile.data_filter(member, str(destination))
                if not safe.isfile():
                    package.extract(safe, destination, filter='data')
                    continue
                target = destination / safe.name
                target.parent.mkdir(parents=True, exist_ok=True)
                temporary = target.with_name(target.name + '.install-part')
                with package.extractfile(member) as source, temporary.open('wb') as output:
                    shutil.copyfileobj(source, output)
                    output.flush()
                    os.fsync(output.fileno())
                if temporary.stat().st_size != member.size:
                    raise RuntimeError(f'Incomplete extracted file: {member.name}')
                temporary.chmod(safe.mode)
                os.replace(temporary, target)
    executable = destination / binary
    executable.chmod(0o755)
    link = prefix / 'bin' / name
    if link.is_symlink() and link.resolve() == executable.resolve():
        pass
    elif link.exists() or link.is_symlink():
        raise RuntimeError(f'Refusing to replace an unrelated entry: {link}')
    else:
        link.symlink_to(executable)
    subprocess.run([str(executable), '--version'], check=True, timeout=30)
    print(f'{name}: verified and installed at {executable}', flush=True)
subprocess.run(['git', 'lfs', 'version'], check=True)
print(f'Add this directory to PATH for the current shell: {prefix / "bin"}')
