#!/usr/bin/env python3
"""Bounded, source-preserving measurement/export of unbound audio review cues.

No motif identification, stem separation, looping or shipping acceptance is
inferred. S00 cannot export until its explicit first-note interval is selected.
"""
import argparse
import datetime as dt
import hashlib
import json
import math
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import wave

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / 'docs/production/audio/slice_edit_manifest.json'
REVIEW = ROOT / 'docs/production/evidence/audio_director'


def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def stamp():
    return dt.datetime.now(dt.timezone.utc).isoformat()


def command(args, output, timeout=45):
    started = stamp()
    timed_out = False
    try:
        result = subprocess.run(args, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT, timeout=timeout, check=False)
    except subprocess.TimeoutExpired as error:
        timed_out = True
        # subprocess.run already kills/reaps this exact child. Preserve its output.
        result = subprocess.CompletedProcess(args, -1, error.stdout or b'')
    output.write_bytes(result.stdout)
    with (output.parent / 'commands.jsonl').open('a') as record:
        record.write(json.dumps({'command': args, 'started_at': started, 'finished_at': stamp(),
                                'timeout_seconds': timeout, 'exit_code': result.returncode,
                                'timed_out': timed_out,
                                'stdout_file': output.name, 'stdout_sha256': digest(output)}) + '\n')
    if result.returncode:
        raise RuntimeError(f'Command failed ({result.returncode}): {args[0]}; see {output}')
    return result.stdout.decode('utf-8', errors='replace')


def load_manifest():
    manifest = json.loads(MANIFEST.read_text())
    if manifest['schema_version'] != 1 or manifest['status'] != 'REVIEW_ONLY_UNBOUND':
        raise ValueError('Unexpected manifest scope/version')
    ids, paths = set(), set()
    inventory = json.loads((ROOT / manifest['inventory']).read_text())
    sealed = {s['path']: s for s in inventory['sources']}
    ceiling = manifest['candidate_true_peak_ceiling_dbtp']
    if not isinstance(ceiling, (int, float)) or not math.isfinite(ceiling) or not -12 <= ceiling <= -1:
        raise ValueError('Review safety ceiling must be finite and at/below -1 dBTP')
    for entry in manifest['entries']:
        name, path = entry['cue_id'], entry['source_path']
        if not re.fullmatch(r'mus_s0[012]_[a-z0-9_]+_v\d{2}', name) or name in ids or path in paths:
            raise ValueError('Invalid/duplicate canonical cue identity')
        ids.add(name)
        paths.add(path)
        p = Path(path)
        if p.is_absolute() or '..' in p.parts or path not in sealed:
            raise ValueError('Source not in sealed slice inventory')
        if (ROOT / p).is_symlink() or (ROOT / p).resolve().parent != (ROOT / p.parent).resolve():
            raise ValueError('Source symlinks are forbidden')
        if entry['source_sha256'] != sealed[path]['sha256'] or digest(ROOT / p) != entry['source_sha256']:
            raise ValueError('Source master SHA mismatch: ' + path)
        if entry['stage'] != sealed[path]['stage'] or name[4:7].upper() != entry['stage']:
            raise ValueError('Source/stage identity mismatch')
        if entry['source_duration_seconds'] != float(sealed[path]['probe']['format']['duration']):
            raise ValueError('Source duration differs from sealed inventory')
        if entry['compression'] != {'codec': 'libvorbis', 'quality': 5, 'sample_rate': 48000, 'channels': 2}:
            raise ValueError('Unsupported review encoding recipe')
        if entry['playback'] != 'finite' or entry['loop_points'] is not None:
            raise ValueError('This exporter implements finite review edits only')
    if paths != set(sealed):
        raise ValueError('Manifest must preserve the complete twelve-input mapping')
    return manifest


def interval(entry):
    bounds = entry['interval_seconds']
    if bounds is None:
        raise ValueError('First-note/motif selection is pending; full S00 takes cannot export')
    start, end = bounds
    values = (start, end, entry['fade_in_seconds'], entry['fade_out_seconds'])
    if any(not isinstance(v, (int, float)) or not math.isfinite(v) for v in values):
        raise ValueError('Non-finite interval/fade')
    if start < 0 or end > entry['source_duration_seconds'] or end - start <= .3:
        raise ValueError('Invalid source interval')
    if min(values[2:]) < 0 or sum(values[2:]) > end - start:
        raise ValueError('Invalid overlapping edge fades')
    if entry['stage'] == 'S00' and entry['interval_status'] != 'SELECTED_FIRST_NOTE_REVIEW_CANDIDATE':
        raise ValueError('S00 requires explicit selected-first-note status')
    return start, end


def measure(path, log):
    text = command(['ffmpeg', '-hide_banner', '-nostats', '-nostdin', '-i', str(path),
                    '-map', '0:a:0', '-af', 'ebur128=peak=true:framelog=verbose', '-f', 'null', '-'], log)
    summary = text.rsplit('Summary:', 1)[-1]
    patterns = {'integrated_lufs': r'I:\s+(-?\d+(?:\.\d+)?) LUFS',
                'lra_lu': r'LRA:\s+(-?\d+(?:\.\d+)?) LU',
                'true_peak_dbtp': r'Peak:\s+(-?\d+(?:\.\d+)?) dBFS'}
    result = {}
    for name, pattern in patterns.items():
        found = re.search(pattern, summary)
        if found is None:
            raise ValueError('Missing/invalid loudness summary: ' + name)
        result[name] = float(found[1])
    return result


def envelope(path):
    # WAV samples, not musical onsets/notes: one-second stereo energy windows.
    with wave.open(str(path), 'rb') as source:
        if source.getsampwidth() != 2 or source.getnchannels() != 2 or source.getframerate() != 48000:
            raise ValueError('Unexpected source PCM format')
        frames = source.getnframes()
        values, clipped, peak = [], 0, 0.0
        while raw := source.readframes(48000):
            samples = np.frombuffer(raw, dtype='<i2').astype(np.float64) / 32768.0
            peak = max(peak, float(np.max(np.abs(samples))))
            clipped += int(np.count_nonzero(np.abs(samples) >= 32767 / 32768.0))
            rms = float(np.sqrt(np.mean(samples * samples)))
            values.append(round(20 * math.log10(max(rms, 1e-12)), 3))
    return {'duration_seconds': frames / 48000, 'sample_peak_dbfs': 20 * math.log10(max(peak, 1e-12)),
            'full_scale_sample_count': clipped, 'one_second_rms_dbfs': values,
            'scope': 'PCM energy envelope only; does not identify pitch, motif, vocals or loop boundaries.'}


def verify_family(output, manifest):
    """Seal one new export against its recipe, commands, guards and source bytes."""
    verification = output / 'verification.json'
    if verification.exists():
        raise FileExistsError('Existing immutable verification receipt')
    if list(output.glob('*.attempt*.ogg')):
        raise ValueError('Unaccepted intermediate media remains in review evidence')
    result = json.loads((output / 'results.json').read_text())
    if result['status'] != 'PASS' or result['operation'] != 'export' or \
            result['acceptance'] != 'TECHNICAL_REVIEW_ONLY_UNBOUND' or len(result['records']) != 1:
        raise ValueError('One technically passed review export is required')
    if result['tool_sha256'] != digest(Path(__file__)) or result['manifest_sha256'] != digest(MANIFEST):
        raise ValueError('Source recipe changed after export')
    record = result['records'][0]
    entry = next(e for e in manifest['entries'] if e['cue_id'] == record['cue_id'])
    media = ROOT / record['derivative_path']
    if media.is_symlink() or media.resolve().parent != output or media.name != entry['cue_id'] + '.ogg' or \
            digest(media) != record['derivative_sha256']:
        raise ValueError('Derivative path/SHA mismatch')
    if record['source_sha256'] != entry['source_sha256'] or record['source_path'] != entry['source_path'] or \
            record['shipping_binding'] or record['loop'] or record['stems'] or \
            record['decoded_loudness']['true_peak_dbtp'] > manifest['candidate_true_peak_ceiling_dbtp']:
        raise ValueError('Export acceptance/source/finite/peak scope mismatch')
    start, end = interval(entry)
    if record['interval_seconds'] != [start, end] or abs(float(record['probe']['format']['duration']) - (end - start)) > .02:
        raise ValueError('Export interval/duration mismatch')
    logs = [json.loads(line) for line in (output / 'commands.jsonl').read_text().splitlines()]
    if len(logs) < 5:
        raise ValueError('Incomplete FFmpeg/probe command evidence')
    for command_record in logs:
        name = command_record['stdout_file']
        if Path(name).name != name or command_record['exit_code'] or command_record['timed_out'] or \
                digest(output / name) != command_record['stdout_sha256']:
            raise ValueError('Command log/status/SHA mismatch')
    guards = output / 'guard_tests.log'
    text = guards.read_text()
    match = re.search(r'Ran (\d+) tests', text)
    if match is None or int(match[1]) < 8 or '\nOK\n' not in text or 'FAILED' in text:
        raise ValueError('Export guard tests did not pass')
    paths = ['tools/audio_slice.py', 'tools/test_audio_slice.py', MANIFEST.relative_to(ROOT).as_posix(),
             record['source_path'], record['derivative_path']]
    receipt = {'status': 'PASS', 'guard_count': int(match[1]), 'utc': stamp(),
               'scope': 'One finite unbound review export; exact recipe/command/media/source bytes and safety guards. No musical or shipping acceptance.',
               'guard_log_sha256': digest(guards),
               'source_hashes': {path: digest(ROOT / path) for path in paths}}
    verification.write_text(json.dumps(receipt, indent=2) + '\n')
    print(json.dumps({'cue_id': entry['cue_id'], 'status': 'PASS', 'guard_count': receipt['guard_count']}))


def execute(args):
    manifest = load_manifest()
    output = args.output.resolve()
    if not output.is_relative_to(REVIEW.resolve()) or output == REVIEW.resolve():
        raise ValueError('Exports must be an isolated review family outside shipping game/assets')
    if args.operation == 'verify':
        return verify_family(output, manifest)
    selected = manifest['entries']
    if args.operation == 'export':
        selected = [e for e in selected if e['cue_id'] == args.cue]
        if len(selected) != 1:
            raise ValueError('Select one known canonical cue')
        interval(selected[0])  # Reject unresolved S00 before creating anything.
    output.mkdir(parents=True, exist_ok=False)
    (output / '.gitattributes').write_text('# Preserve exact FFmpeg process log whitespace.\n'
                                         '*.log whitespace=-blank-at-eof,-blank-at-eol\n')
    result = {'status': 'RUNNING', 'acceptance': 'TECHNICAL_REVIEW_ONLY_UNBOUND',
              'started_at': stamp(), 'operation': args.operation,
              'manifest_sha256': digest(MANIFEST),
              'tool_sha256': digest(Path(__file__)), 'records': []}
    receipt = output / 'results.json'
    try:
        command(['ffmpeg', '-version'], output / 'ffmpeg_version.log')
        for entry in selected:
            source = ROOT / entry['source_path']
            name = entry['cue_id']
            original = measure(source, output / (name + '.source_ebur128.log'))
            record = {'cue_id': name, 'source_path': entry['source_path'],
                      'source_sha256': entry['source_sha256'], 'source_loudness': original,
                      'source_envelope': envelope(source)}
            if args.operation == 'export':
                start, end = interval(entry)
                duration = end - start
                # No amplification, limiter, compressor or invented LUFS target.
                # A safety margin is re-measured after lossy encoding.
                gain = min(0.0, manifest['candidate_true_peak_ceiling_dbtp'] - original['true_peak_dbtp'] - 1)
                target = output / (name + '.ogg')
                # Keep unfinished encoder output outside Git. Only a measured
                # accepted derivative is copied into the new review family.
                with tempfile.TemporaryDirectory(prefix='wlr-audio-encode-') as private:
                    for attempt in range(3):
                        trial = Path(private) / f'{name}.attempt{attempt}.ogg'
                        filters = (f'volume={gain:.6f}dB,afade=t=in:d={entry["fade_in_seconds"]:.6f},'
                                   f'afade=t=out:st={duration-entry["fade_out_seconds"]:.6f}:d={entry["fade_out_seconds"]:.6f}')
                        command(['ffmpeg', '-hide_banner', '-nostats', '-nostdin', '-n', '-ss', str(start), '-i', str(source),
                                 '-t', str(duration), '-map', '0:a:0', '-map_metadata', '-1', '-af', filters,
                                 '-ar', '48000', '-ac', '2', '-c:a', 'libvorbis', '-q:a', '5', str(trial)],
                                output / f'{name}.encode{attempt}.log')
                        measured = measure(trial, output / f'{name}.decoded_ebur128_{attempt}.log')
                        if measured['true_peak_dbtp'] <= manifest['candidate_true_peak_ceiling_dbtp']:
                            with trial.open('rb') as encoded, target.open('xb') as accepted:
                                shutil.copyfileobj(encoded, accepted)
                            if digest(trial) != digest(target):
                                raise RuntimeError('Accepted derivative copy SHA mismatch')
                            break
                        gain -= measured['true_peak_dbtp'] - manifest['candidate_true_peak_ceiling_dbtp'] + .2
                    else:
                        raise RuntimeError('Decoded review cue exceeds its safety ceiling')
                probe = json.loads(command(['ffprobe', '-v', 'error', '-show_entries',
                         'stream=codec_name,sample_rate,channels:format=duration', '-of', 'json', str(target)],
                         output / (name + '.probe.json')))
                stream = probe['streams'][0]
                if stream != {'codec_name': 'vorbis', 'sample_rate': '48000', 'channels': 2} or \
                        abs(float(probe['format']['duration']) - duration) > .02:
                    raise RuntimeError('Compressed candidate format/duration mismatch')
                record.update(derivative_path=target.relative_to(ROOT).as_posix(), derivative_sha256=digest(target),
                              derivative_bytes=target.stat().st_size, gain_db=gain, filters=filters,
                              interval_seconds=[start, end], decoded_loudness=measured, probe=probe,
                              loop=False, stems=False, shipping_binding=False)
            if digest(source) != entry['source_sha256']:
                raise RuntimeError('Source changed during operation')
            result['records'].append(record)
            receipt.write_text(json.dumps(result, indent=2) + '\n')
            print(json.dumps({'cue_id': name, 'measured': True, 'exported': args.operation == 'export'}), flush=True)
        if digest(MANIFEST) != result['manifest_sha256'] or digest(Path(__file__)) != result['tool_sha256']:
            raise RuntimeError('Manifest/tool changed during operation')
        load_manifest()  # Re-check every master, including unselected sources.
        result['status'] = 'PASS'
    except Exception as error:
        result.update(status='FAIL', failure=str(error))
        raise
    finally:
        result['finished_at'] = stamp()
        receipt.write_text(json.dumps(result, indent=2) + '\n')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('operation', choices=('analyze', 'export', 'verify'))
    parser.add_argument('--cue')
    parser.add_argument('--output', type=Path, required=True)
    execute(parser.parse_args())
