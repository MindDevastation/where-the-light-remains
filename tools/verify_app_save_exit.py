"""Verify real App dirty exit in a fresh isolated Linux user-data directory."""
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
    parser.add_argument('--native', action='store_true')
    parser.add_argument('--graphics-prefix', type=Path)
    args = parser.parse_args()
    args.scratch.mkdir(parents=True, exist_ok=True)
    directory = Path(tempfile.mkdtemp(prefix='app-save-exit-', dir=args.scratch)).resolve()
    env = os.environ.copy()
    env['XDG_DATA_HOME'] = str(directory)
    godot_args = ['--path', str(args.project.resolve()), '--audio-driver', 'Dummy',
                  'res://tests/app_save_exit_smoke.tscn', '--', '--save-exit-root=' + str(directory)]
    if args.native:
        if args.graphics_prefix is None:
            parser.error('--native requires --graphics-prefix')
        command = [sys.executable, str(Path(__file__).with_name('run_graphical.py')),
                   '--graphics-prefix', str(args.graphics_prefix.resolve()),
                   '--godot', str(args.godot.resolve()), '--timeout', '20',
                   '--expect', 'APP_SAVE_EXIT requested', '--'] + godot_args + ['--native-close']
    else:
        command = [str(args.godot.resolve()), '--headless'] + godot_args
    result = subprocess.run(command, env=env, text=True, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, timeout=40)
    print(result.stdout, flush=True)
    if result.returncode or any(marker in result.stdout for marker in ('ERROR:', 'SCRIPT ERROR', 'Parse Error')):
        raise RuntimeError('App exit process failed')
    if not args.native and 'APP_SAVE_EXIT PASS' not in result.stdout:
        raise RuntimeError('Successful dirty exit marker missing')
    files = list(directory.rglob('savegame.json'))
    if len(files) != 1:
        raise RuntimeError('Expected exactly one committed save')
    primary = files[0]
    backup = primary.with_name('savegame.backup.json')
    data = json.loads(primary.read_text())
    if primary.read_bytes() != backup.read_bytes() or data['stage_id'] != 's02_warmth_light' or data['collected_fragments'] != ['star', 'hearth'] or data['world_states']['fixture']['counter'] != 9007199254740991:
        raise RuntimeError('Committed primary/backup state mismatch')
    if list(directory.rglob('*.tmp_*')) or list(directory.rglob('settings.cfg')):
        raise RuntimeError('Unexpected temporary/settings file')
    print('APP_SAVE_EXIT_FILES PASS: native=' + str(args.native) + '; sha256=' + hashlib.sha256(primary.read_bytes()).hexdigest() + '; directory=' + str(directory))


if __name__ == '__main__':
    main()
