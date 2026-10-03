"""Verify real route-time App exit/IO-error recovery in fresh user-data roots."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--project', required=True, type=Path)
    parser.add_argument('--godot', required=True, type=Path)
    parser.add_argument('--scratch', required=True, type=Path)
    parser.add_argument('--failure', action='store_true')
    parser.add_argument('--native', action='store_true')
    parser.add_argument('--graphics-prefix', type=Path)
    args = parser.parse_args()
    args.scratch.mkdir(parents=True, exist_ok=True)
    directory = Path(tempfile.mkdtemp(prefix='router-exit-', dir=args.scratch)).resolve()
    env = os.environ.copy()
    env['XDG_DATA_HOME'] = str(directory)
    godot_args = ['--path', str(args.project.resolve()), '--audio-driver', 'Dummy',
                  'res://tests/router_exit_smoke.tscn', '--', '--save-exit-root=' + str(directory)]
    if args.failure:
        godot_args.append('--exit-failure')
    if args.native:
        if args.graphics_prefix is None or not args.failure:
            parser.error('--native requires --graphics-prefix and --failure')
        command = [sys.executable, str(Path(__file__).with_name('run_graphical.py')),
                   '--graphics-prefix', str(args.graphics_prefix.resolve()),
                   '--godot', str(args.godot.resolve()), '--timeout', '25',
                   '--expect', 'ROUTER_EXIT PASS', '--'] + godot_args + ['--native-close']
    else:
        command = [str(args.godot.resolve()), '--headless'] + godot_args
    result = subprocess.run(command, env=env, text=True, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, timeout=45)
    print(result.stdout, flush=True)
    if result.returncode or 'ROUTER_EXIT PASS' not in result.stdout or any(
            marker in result.stdout for marker in ('ERROR:', 'SCRIPT ERROR', 'Parse Error')):
        raise RuntimeError('Route-time exit process failed')
    files = list(directory.rglob('savegame.json'))
    if len(files) != 1 or not files[0].is_file():
        raise RuntimeError('Expected exactly one committed original save')
    primary = files[0]
    backup = primary.with_name('savegame.backup.json')
    data = json.loads(primary.read_text())
    if (primary.read_bytes() != backup.read_bytes() or data['stage_id'] != 's01_fixture'
            or data['world_states'] != {'s01_fixture': {'counter': 1}}):
        raise RuntimeError('Unaccepted target persisted or original backup mismatch')
    if list(directory.rglob('*.tmp_*')) or list(directory.rglob('settings.cfg')):
        raise RuntimeError('Unexpected temporary/settings file')
    print('ROUTER_EXIT_FILES PASS: native=' + str(args.native) + '; failure=' + str(args.failure)
          + '; sha256=' + hashlib.sha256(primary.read_bytes()).hexdigest())


if __name__ == '__main__':
    main()
