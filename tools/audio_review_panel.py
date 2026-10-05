#!/usr/bin/env python3
"""Package two sealed S00 auditions for offline listening and cut proposals."""
import argparse
import base64
import json
import os
from pathlib import Path

import audio_audition as audition

ROOT = audition.ROOT
FAMILIES = ('s00-opening-audition-1', 's00-alternate-opening-audition-2')
LABELS = ('Sparse Awakening vol.2', 'Sparse Awakening')
TEMPLATE = ROOT / 'tools/audio_review_panel.html'
SCRIPT = ROOT / 'tools/audio_review_panel.js'


def catalog():
    # The sealed excerpts suffice; rebuilding/hydrating all twelve masters is
    # unnecessary. Their identities are checked against the unchanged recipe.
    manifest = json.loads(audition.audio.MANIFEST.read_text())
    entries = {e['cue_id']: e for e in manifest['entries']}
    inputs = [audition.audio.MANIFEST, TEMPLATE, SCRIPT, Path(__file__).resolve()]
    candidates = []
    for family, label in zip(FAMILIES, LABELS):
        folder = audition.REVIEW / family
        paths = [folder / name for name in ('results.json', 'proposal.json', 'audition_checks.json', 'audition.ogg')]
        if not all(path.is_file() for path in paths):
            raise ValueError('Incomplete or unaccepted audition evidence: ' + family)
        result, proposal, checks = [json.loads(p.read_text()) for p in paths[:3]]
        if result.get('status') != 'PASS' or result.get('acceptance') != audition.ACCEPTANCE or \
                result.get('command_count') != 4 or not result.get('finished_at') or checks.get('status') != 'PASS':
            raise ValueError('Incomplete or unaccepted audition evidence: ' + family)
        entry = entries[proposal['source_cue_id']]
        if entry['stage'] != 'S00' or entry['interval_seconds'] is not None or \
                entry['interval_status'] != 'BLOCKED_FIRST_NOTE_AND_MOTIF_SELECTION':
            raise ValueError('Review panel requires an unselected S00 source')
        if proposal.get('status') != 'PENDING_LISTENING_SELECTION' or \
                proposal.get('note_identity') is not None or proposal.get('four_note_motif') is not None or \
                proposal.get('shipping_binding') is not False or proposal.get('manifest_modified') is not False or \
                proposal['source_path'] != entry['source_path'] or proposal['source_sha256'] != entry['source_sha256']:
            raise ValueError('Audition/manifest identity or selection mismatch')
        for path in paths[:2] + [paths[3], audition.audio.MANIFEST]:
            relative = path.relative_to(ROOT).as_posix()
            if audition.audio.digest(path) != checks['source_hashes'].get(relative):
                raise ValueError('Sealed audition bytes changed: ' + relative)
        media = paths[3].read_bytes()
        if not media.startswith(b'OggS') or audition.audio.digest(paths[3]) != proposal['audition_sha256'] or \
                proposal['source_interval_seconds'] != [0, 8] or \
                proposal['probe']['streams'] != [{'codec_name': 'vorbis', 'sample_rate': '48000', 'channels': 2}]:
            raise ValueError('Unexpected audition media/window')
        candidates.append(dict(proposal, label=label, media_data_url='data:audio/ogg;base64,' + base64.b64encode(media).decode()))
        inputs.extend(paths)
    return {'schema_version': 1, 'acceptance': 'LISTENING_PROPOSALS_ONLY', 'candidates': candidates}, inputs


def build(output):
    data, paths = catalog()
    hashes = {p.relative_to(ROOT).as_posix(): audition.audio.digest(p) for p in paths}
    payload = json.dumps(data, ensure_ascii=False).replace('<', '\\u003c')
    page = TEMPLATE.read_text().replace('<!--REVIEW_DATA-->', payload).replace('<!--REVIEW_SCRIPT-->', SCRIPT.read_text())
    output = audition.destination(output)
    output.mkdir(parents=True, exist_ok=False)
    target = output / 'listen.html'
    # Consume short writes and read back the complete self-contained page.
    encoded = page.encode('utf-8')
    with target.open('xb') as stream:
        remaining = memoryview(encoded)
        while remaining:
            written = stream.write(remaining)
            if not isinstance(written, int) or not 0 < written <= len(remaining):
                raise OSError('Review page write made no valid progress')
            remaining = remaining[written:]
        stream.flush()
        os.fsync(stream.fileno())
    if target.read_bytes() != encoded or any(audition.audio.digest(ROOT / p) != expected for p, expected in hashes.items()):
        raise RuntimeError('Review page read-back/input mismatch')
    hashes[target.relative_to(ROOT).as_posix()] = audition.audio.digest(target)
    record = {'status': 'PASS', 'utc': audition.audio.stamp(), 'acceptance': data['acceptance'],
              'source_hashes': hashes, 'candidate_count': 2, 'page': target.relative_to(ROOT).as_posix(),
              'scope': 'Self-contained offline comparison of existing sealed 0–8 s excerpts only. No listening, note/motif, seed, scene-mix or shipping acceptance.',
              'manifest_modified': False, 'shipping_binding': False}
    audition.write_receipt(output / 'results.json', record)
    print(json.dumps({k: record[k] for k in ('status', 'acceptance', 'page', 'candidate_count')}))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    build(parser.parse_args().output)
