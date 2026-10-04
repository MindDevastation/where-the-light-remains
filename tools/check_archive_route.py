#!/usr/bin/env python3
"""Validate new local T019 behavior on a source-identical clean sparse copy."""
import argparse
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


def now():
    return dt.datetime.now(dt.timezone.utc).isoformat()


def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def write_complete(path, data):
    with path.open('wb', buffering=0) as file:
        pending = memoryview(data)
        while pending:
            n = file.write(pending)
            if not n:
                raise RuntimeError('No complete-log write progress')
            pending = pending[n:]
        os.fsync(file.fileno())
    if path.stat().st_size != len(data) or digest(path) != hashlib.sha256(data).hexdigest():
        raise RuntimeError('Completed log changed while being written')


def slot_hashes(root):
    return {name: digest(root / name) if (root / name).is_file() else 'absent'
            for name in ('savegame.json', 'savegame.backup.json', 'settings.cfg')}


def pixel_review(png, metadata):
    from PIL import Image
    data = json.loads(metadata.read_text())
    expected = {'active_low': [1, 0, 0, 0, 0], 'active_medium': [1, 0, 0, 0, 0],
                'completed_low': [2, 1, 0, 0, 0], 'all_completed_low': [2, 2, 2, 2, 2]}[data['view']]
    if data['view'].endswith('low') and any(data[k] for k in ('effects', 'glow', 'volumetrics')):
        raise RuntimeError('Low fallback enabled a forbidden effect')
    samples = []
    with Image.open(png) as image:
        image.load()
        if image.size != (1920, 1080):
            raise RuntimeError('Unexpected framebuffer size')
        image = image.convert('RGB')
        for route, state in zip(data['samples'], expected):
            if route['status'] != state:
                raise RuntimeError('Unexpected active/completed route')
            count = 0
            for x, y in route['positions']:
                colors = [image.getpixel((round(x)+dx, round(y)+dy)) for dx in (-1, 0, 1) for dy in (-1, 0, 1)]
                blue = any(b > r+30 and g > r+25 and b > 110 for r, g, b in colors)
                warm = any(r > b+35 and g > b+20 and r > 140 for r, g, b in colors)
                if (blue if state == 1 else warm if state == 2 else (blue or warm)):
                    count += 1
            passed = count >= 15 if state else count == 0
            samples.append({'route': route['index'], 'state': state, 'visible_samples': count,
                            'total_samples': len(route['positions']), 'passed': passed})
            if not passed:
                raise RuntimeError('Route pixel readability failed: ' + json.dumps(samples[-1]))
    return {'view': data['view'], 'framebuffer': [1920, 1080], 'render_scale': data['render_scale'],
            'glow': data['glow'], 'volumetrics': data['volumetrics'], 'samples': samples, 'passed': True}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', required=True, type=Path)
    parser.add_argument('--graphics-prefix', required=True, type=Path)
    parser.add_argument('--output', required=True, type=Path)
    args = parser.parse_args()
    source = Path(__file__).resolve().parents[1]
    out = args.output.resolve()
    if out.exists() and any(out.iterdir()):
        raise RuntimeError('Preserve existing acceptance evidence; choose a fresh output directory')
    out.mkdir(parents=True, exist_ok=True)
    git_env = dict(os.environ, GIT_NO_LAZY_FETCH='1', GIT_LFS_SKIP_SMUDGE='1')
    sha = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=source, env=git_env).decode().strip()
    tracked = subprocess.check_output(['git', 'ls-files', '-z', '--', 'game', 'tools'], cwd=source, env=git_env)
    paths = [os.fsdecode(p) for p in tracked.split(b'\0') if p and (source / os.fsdecode(p)).is_file()]
    before = {p: digest(source / p) for p in paths}
    result = {'status': 'RUNNING', 'started_at': now(), 'source_commit': sha,
              'source_files': len(paths), 'source_hashes': before, 'records': [], 'pixel_reviews': []}
    private = tempfile.TemporaryDirectory(prefix='wlr-route-clean-', ignore_cleanup_errors=True)
    scratch = Path(private.name)
    clean = scratch / 'source'
    try:
        for p in paths:
            target = clean / p
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(source / p, target)
        if any(digest(clean / p) != value for p, value in before.items()) or (clean / 'game/.godot').exists():
            raise RuntimeError('Clean source copy mismatch/cache reuse')

        def run(name, command, marker, timeout=125):
            data = scratch / ('userdata-' + name)
            slots = data / 'godot/app_userdata/Where the Light Remains'
            slots.mkdir(parents=True)
            for filename, checkpoint in [('savegame.json', 'immutable_primary'), ('savegame.backup.json', 'immutable_backup')]:
                saved = {'save_version': 1, 'stage_id': 's01_route_fixture', 'checkpoint_id': checkpoint,
                         'collected_fragments': [], 'world_states': {}, 'milestones': {},
                         'achievement_ids': [], 'game_completed': False}
                (slots / filename).write_text(json.dumps(saved, ensure_ascii=False, indent=2)+'\n')
            protected = slot_hashes(slots)
            env = dict(os.environ, GODOT_SILENCE_ROOT_WARNING='1', XDG_DATA_HOME=str(data))
            record = {'name': name, 'command': command, 'started_at': now()}
            process = subprocess.Popen(command, cwd=clean, env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            timed_out = False
            try:
                raw, _ = process.communicate(timeout=timeout)
            except subprocess.TimeoutExpired:
                timed_out = True
                process.terminate()
                try: raw, _ = process.communicate(timeout=7)
                except subprocess.TimeoutExpired:
                    process.kill()
                    raw, _ = process.communicate()
            log = out / (name + '.complete.log')
            write_complete(log, raw)
            passed = process.returncode == 0 and not timed_out and (not marker or marker.encode() in raw) and \
                     not any(x in raw for x in (b'ERROR:', b'SCRIPT ERROR', b'Parse Error', b'WARNING:')) and \
                     slot_hashes(slots) == protected
            record.update(exit_code=process.returncode, timeout=timed_out, finished_at=now(),
                          stdout_bytes=len(raw), stdout_sha256=digest(log), passed=passed,
                          protected_before=protected, protected_after=slot_hashes(slots))
            (out / (name+'.receipt.json')).write_text(json.dumps(record, indent=2)+'\n')
            result['records'].append(record)
            print(json.dumps({'name': name, 'passed': passed, 'exit_code': process.returncode,
                              'log_bytes': len(raw)}), flush=True)
            if not passed:
                raise RuntimeError('New T019 validation failed: '+name)

        godot = str(args.godot.resolve())
        run('clean_import', [godot, '--headless', '--path', 'game', '--editor', '--import'], '')
        run('headless_route', [godot, '--headless', '--audio-driver', 'Dummy', '--path', 'game',
                              'res://tests/archive_route_smoke.tscn'], 'ARCHIVE_ROUTE PASS:')
        prefix = args.graphics_prefix.resolve()
        link = Path('/usr/bin/xkbcomp')
        expected = prefix / 'usr/bin/xkbcomp'
        if not link.exists():
            if link.is_symlink(): link.unlink()
            link.symlink_to(expected)
        graphics = ['python3', str(clean/'tools/run_graphical.py'), '--graphics-prefix', str(prefix),
                    '--godot', godot, '--timeout', '100', '--expect']
        run('graphics_route', graphics + ['ARCHIVE_ROUTE PASS:', '--', '--path', 'game',
                                         'res://tests/archive_route_smoke.tscn'], 'GRAPHICAL_RUN PASS:', 145)
        for view in ('active_low', 'completed_low', 'active_medium', 'all_completed_low'):
            png, meta = out/(view+'.png'), out/(view+'.json')
            run('review_'+view, graphics + ['ROUTE_REVIEW PASS:', '--', '--path', 'game',
                'res://tests/archive_route_review.tscn', '--', '--view='+view,
                '--output='+str(png), '--metadata='+str(meta)], 'GRAPHICAL_RUN PASS:', 145)
            result['pixel_reviews'].append(pixel_review(png, meta))
        result['status'] = 'PASS'
    except Exception as error:
        result.update(status='FAIL', failure=type(error).__name__+': '+str(error))
    finally:
        result['source_unchanged'] = all((source/p).is_file() and digest(source/p) == h for p, h in before.items())
        result['clean_copy_unchanged'] = all((clean/p).is_file() and digest(clean/p) == h for p, h in before.items())
        if not result['source_unchanged'] or not result['clean_copy_unchanged']:
            result.update(status='FAIL', failure='Materialized source changed during acceptance')
        private.cleanup()
        result['cleanup_succeeded'] = not scratch.exists()
        result['finished_at'] = now()
        (out/'clean_results.json').write_text(json.dumps(result, indent=2)+'\n')
        print(json.dumps({k: result[k] for k in ('status', 'source_commit', 'source_files',
              'source_unchanged', 'clean_copy_unchanged', 'cleanup_succeeded', 'finished_at')}), flush=True)
    raise SystemExit(0 if result['status'] == 'PASS' else 1)


if __name__ == '__main__':
    main()
