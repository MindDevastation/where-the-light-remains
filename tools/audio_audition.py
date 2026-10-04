#!/usr/bin/env python3
"""Bounded S00 listening excerpts; never select a seed or modify its manifest.

An excerpt is an audition proposal, not a passed musical edit. Normal seed
export retains its explicit first-note selection guard in audio_slice.py.
"""
import argparse
import json
import math
from pathlib import Path
import shutil
import tempfile

import audio_slice as audio

ROOT = audio.ROOT
REVIEW = audio.REVIEW
ACCEPTANCE = 'AUDITION_ONLY_NOT_A_SELECTED_SEED'


def parameters(entry, start, end, fade_in, fade_out):
    if entry['stage'] != 'S00':
        raise ValueError('This audition tool is limited to the two S00 sources')
    values = [start, end, fade_in, fade_out]
    if any(not isinstance(v, (int, float)) or not math.isfinite(v) for v in values):
        raise ValueError('Non-finite audition interval/fade')
    # Twenty seconds is a tooling review budget, not an authored seed duration.
    if start < 0 or end > entry['source_duration_seconds'] or not .3 < end - start <= 20:
        raise ValueError('Audition window must be inside the master and between .3 and 20 seconds')
    if min(fade_in, fade_out) < 0 or fade_in + fade_out > end - start:
        raise ValueError('Invalid overlapping audition edge fades')


def destination(path):
    path = path.resolve()
    if path == REVIEW.resolve() or not path.is_relative_to(REVIEW.resolve()):
        raise ValueError('Audition output must be a new evidence family outside shipping game/assets')
    if path.exists():
        raise FileExistsError('Existing evidence must never be overwritten')
    return path


def execute(args):
    manifest = audio.load_manifest()
    entries = [e for e in manifest['entries'] if e['cue_id'] == args.cue]
    if len(entries) != 1:
        raise ValueError('One known S00 source is required')
    entry = entries[0]
    parameters(entry, args.start, args.end, args.fade_in, args.fade_out)
    output = destination(args.output)
    source = ROOT / entry['source_path']
    # Seal all original inputs and the unmodified shipping-selection recipe.
    paths = ['tools/audio_audition.py', 'tools/audio_slice.py', 'tools/test_audio_audition.py',
             audio.MANIFEST.relative_to(ROOT).as_posix()] + [e['source_path'] for e in manifest['entries']]
    hashes = {p: audio.digest(ROOT / p) for p in paths}
    output.mkdir(parents=True, exist_ok=False)
    (output / '.gitattributes').write_text('*.log whitespace=-blank-at-eof,-blank-at-eol\n')
    result = {'status': 'RUNNING', 'operation': 'audition', 'acceptance': ACCEPTANCE,
              'started_at': audio.stamp(), 'source_hashes': hashes,
              'scope': 'An explicit listening window only; not a first-note/motif/instrumental/palette/scene-mix/license acceptance.'}
    receipt = output / 'results.json'
    receipt.write_text(json.dumps(result, indent=2) + '\n')
    try:
        audio.command(['ffmpeg', '-version'], output / 'ffmpeg_version.log')
        duration, gain = args.end - args.start, 0.0
        target = output / 'audition.ogg'
        with tempfile.TemporaryDirectory(prefix='wlr-audio-audition-') as private:
            for attempt in range(3):
                trial = Path(private) / 'audition.ogg'
                if trial.exists():
                    trial.unlink()  # Only this tool-owned unaccepted temporary.
                filters = (f'volume={gain:.6f}dB,afade=t=in:d={args.fade_in:.6f},'
                           f'afade=t=out:st={duration-args.fade_out:.6f}:d={args.fade_out:.6f}')
                audio.command(['ffmpeg', '-hide_banner', '-nostats', '-nostdin', '-n',
                               '-ss', str(args.start), '-i', str(source), '-t', str(duration),
                               '-map', '0:a:0', '-map_metadata', '-1', '-af', filters,
                               '-ar', '48000', '-ac', '2', '-c:a', 'libvorbis', '-q:a', '5', str(trial)],
                              output / f'encode_{attempt}.log')
                measured = audio.measure(trial, output / f'decoded_ebur128_{attempt}.log')
                if measured['true_peak_dbtp'] <= manifest['candidate_true_peak_ceiling_dbtp']:
                    with trial.open('rb') as encoded, target.open('xb') as audition:
                        shutil.copyfileobj(encoded, audition)
                    if audio.digest(trial) != audio.digest(target):
                        raise RuntimeError('Audition copy SHA mismatch')
                    break
                gain -= measured['true_peak_dbtp'] - manifest['candidate_true_peak_ceiling_dbtp'] + .2
            else:
                raise RuntimeError('Decoded audition exceeds the engineering safety ceiling')
        probe = json.loads(audio.command(['ffprobe', '-v', 'error', '-show_entries',
                                          'stream=codec_name,sample_rate,channels:format=duration', '-of', 'json', str(target)],
                                         output / 'probe.json'))
        if probe['streams'] != [{'codec_name': 'vorbis', 'sample_rate': '48000', 'channels': 2}] or \
                abs(float(probe['format']['duration']) - duration) > .02:
            raise RuntimeError('Audition compressed format/duration mismatch')
        proposal = {'schema_version': 1, 'status': 'PENDING_LISTENING_SELECTION',
                    'source_cue_id': entry['cue_id'], 'source_path': entry['source_path'],
                    'source_sha256': entry['source_sha256'], 'source_interval_seconds': [args.start, args.end],
                    'fade_in_seconds': args.fade_in, 'fade_out_seconds': args.fade_out, 'gain_db': gain,
                    'note_identity': None, 'four_note_motif': None, 'shipping_binding': False,
                    'manifest_modified': False, 'loop': False, 'stems': False,
                    'audition_path': target.relative_to(ROOT).as_posix(), 'audition_sha256': audio.digest(target),
                    'decoded_loudness': measured, 'probe': probe,
                    'instruction': 'Listen to the original and excerpt; select actual note/cut/motif before editing the seed manifest. Do not bind this opening excerpt as a seed.'}
        proposal_path = output / 'proposal.json'
        proposal_path.write_text(json.dumps(proposal, indent=2) + '\n')
        hashes[target.relative_to(ROOT).as_posix()] = audio.digest(target)
        hashes[proposal_path.relative_to(ROOT).as_posix()] = audio.digest(proposal_path)
        for record in audio.COMMANDS.get(output, []):
            log = output / record['stdout_file']
            hashes[log.relative_to(ROOT).as_posix()] = audio.digest(log)
        if any(audio.digest(ROOT / p) != expected for p, expected in hashes.items()):
            raise RuntimeError('Source/recipe/audition bytes changed during processing')
        audio.load_manifest()  # Source masters and blocked seed recipe are unchanged.
        result.update(status='PASS', proposal=proposal_path.relative_to(ROOT).as_posix())
        print(json.dumps({'status': 'PASS', 'acceptance': ACCEPTANCE, 'source': entry['cue_id'],
                          'interval': [args.start, args.end], 'decoded_loudness': measured}), flush=True)
    except Exception as error:
        result.update(status='FAIL', failure=str(error))
        raise
    finally:
        commands = audio.COMMANDS.get(output, [])
        (output / 'commands.jsonl').write_text(''.join(json.dumps(r) + '\n' for r in commands))
        result.update(command_count=len(commands), finished_at=audio.stamp())
        receipt.write_text(json.dumps(result, indent=2) + '\n')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--cue', required=True)
    parser.add_argument('--start', type=float, required=True)
    parser.add_argument('--end', type=float, required=True)
    parser.add_argument('--fade-in', type=float, default=.02)
    parser.add_argument('--fade-out', type=float, default=.25)
    parser.add_argument('--output', type=Path, required=True)
    execute(parser.parse_args())
