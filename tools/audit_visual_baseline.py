#!/usr/bin/env python3
"""Verify reviewed concept payloads, legacy retention and preserved runtime contracts.

Does not assign semantic slots, create images or certify art/performance quality.
Run from any directory. Standard library + Pillow for full PNG decoding.
"""
from pathlib import Path
import hashlib
import json
from PIL import Image

root = Path(__file__).resolve().parents[1]
production = root / 'docs/production'
review = json.loads((production / 'visual_rebaseline_v2.json').read_text())
pack = json.loads((production / 'evidence/visual_rebaseline_v2/concept_inventory.json').read_text())
additional = json.loads((production / 'additional_concepts_review.json').read_text())


def checked_path(path):
    p = (root / path).resolve()
    if not p.is_relative_to(root):
        raise RuntimeError('Path outside repository: ' + path)
    return p


def git_blob(payload):
    return hashlib.sha1(b'blob ' + str(len(payload)).encode() + b'\0' + payload).hexdigest()


for entry in pack['images']:
    p = checked_path(entry['path'])
    payload = p.read_bytes()
    assert len(payload) == entry['bytes'], p
    assert hashlib.sha256(payload).hexdigest() == entry['sha256'], p
    assert git_blob(payload) == entry['git_blob'], p
    with Image.open(p) as image:
        image.load()
        assert image.format == 'PNG', p
for entry in review['old_to_new']:
    p = checked_path(entry['retained_at'])
    assert git_blob(p.read_bytes()) == entry['old_blob'], p
for entry in review['preserved_contracts']:
    p = checked_path(entry['path'])
    assert hashlib.sha256(p.read_bytes()).hexdigest() == entry['sha256'], p
missing = []
for slot in review['slots']:
    for angle in 'abc':
        if angle not in slot['angles']:
            missing.append(slot['slot'] + '_v2_angle_' + angle + '.png')
        else:
            assert checked_path(slot['angles'][angle]).is_file()
for slot in review['nonstandard_zone_sets']:
    assert set(slot['angles']) == set('abc')
    for path in slot['angles'].values():
        assert checked_path(path).is_file()
canonical_hashes = {entry['path']: entry['sha256'] for entry in pack['images']}
for candidate in additional:
    assert candidate['sha256'] == canonical_hashes[candidate['file']]
    assert candidate['decision'] in ('PROMOTE_CANONICAL', 'SUPPORTING_REFERENCE', 'REJECT', 'UNMATCHED')
    if candidate['decision'] == 'UNMATCHED':
        assert candidate['matched_slot'] is None
    if candidate['matched_slot']:
        assert candidate['matched_slot'] in pack['slots']
for n, angle in zip((2, 3, 4), 'abc'):
    candidate = next(x for x in additional if x['file'].endswith(f'/{n}.png'))
    canonical = candidate['matched_slot'] + '_v2_angle_' + angle + '.png'
    assert candidate['sha256'] == canonical_hashes[canonical]
assert len(missing) == 1 and missing[0].endswith('/Secrets-Achievements screen_v2_angle_c.png')
print(f'CONCEPT_INTEGRITY PASS: {len(pack["images"])} incoming PNGs decoded/hash-verified; {len(review["old_to_new"])} old payloads retained')
print(f'RUNTIME_CONTRACTS PASS: {len(review["preserved_contracts"])} unchanged source/configuration fingerprints')
print(f'ADDITIONAL_REVIEW: {len(additional)} inspected; ' + ', '.join(f'{status}={sum(x["decision"] == status for x in additional)}' for status in ('PROMOTE_CANONICAL', 'SUPPORTING_REFERENCE', 'REJECT', 'UNMATCHED')))
print('REFERENCE_COMPLETENESS PARTIAL: missing ' + missing[0] + '; dependent acceptance only')
print('SCOPE: integrity/contracts, not semantic/visual acceptance or target-GPU profiling')
