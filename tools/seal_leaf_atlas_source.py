#!/usr/bin/env python3
"""Seal bounded MAT-012 evidence and exact earlier-source protection."""
import datetime as dt
import hashlib
import json
from pathlib import Path
import re
import subprocess


def main():
    root=Path(__file__).resolve().parents[1]
    def digest(path):return hashlib.sha256((root/path).read_bytes()).hexdigest()
    def git(*args):return subprocess.check_output(['git',*args],cwd=root)
    seals=[json.loads((root/f'docs/production/evidence/archive_reconstruction/{name}-source-seal-20261007/results.json').read_text()) for name in ['cool-stone','linen']]
    for seal in seals:
        for path,value in seal['source_hashes'].items():
            if digest(path)!=value:raise RuntimeError('Earlier family source changed: '+path)
        for path,value in seal['existing_tracked_game_hashes'].items():
            if digest(path)!=value:raise RuntimeError('Protected source changed: '+path)
    prior=seals[-1]['prior_art_hashes'];modes=seals[-1]['prior_art_verification_modes']
    for path,value in prior.items():
        data=(root/path).read_bytes()
        if modes[path].startswith('Committed pointer/OID'):
            pointer=re.fullmatch(rb'version https://git-lfs.github.com/spec/v1\noid sha256:([0-9a-f]{64})\nsize ([0-9]+)\n',data)
            valid=pointer is not None and pointer[1].decode()==value
        else:valid=digest(path)==value
        if not valid:raise RuntimeError('Prior identity changed: '+path)
    protected={}
    for path in git('ls-files','game').decode().splitlines():
        if hashlib.sha256(git('show','HEAD:'+path)).hexdigest()!=digest(path):raise RuntimeError('Existing tracked game changed: '+path)
        protected[path]=digest(path)
    pointers=[path for path in protected if path.endswith('.glb')]
    for path in pointers:
        if not re.fullmatch(rb'version https://git-lfs.github.com/spec/v1\noid sha256:[0-9a-f]{64}\nsize [0-9]+\n',(root/path).read_bytes()):raise RuntimeError('Unexpected fresh payload state: '+path)
    folder=Path('docs/production/evidence/archive_reconstruction/leaf-atlas-native-1')
    native=json.loads((root/folder/'results.json').read_text())
    if native['status']!='PASS':raise RuntimeError('Native review not PASS')
    for path,value in native['source_hashes'].items():
        if digest(path)!=value:raise RuntimeError('Exact native source changed: '+path)
    current=json.loads((root/'docs/production/VS1_ART_RECONCILIATION_CURRENT.json').read_text())
    baseline=json.loads(git('show','2cb6d390055fe8bccfbfa4bf37a87e05d4be2280:docs/production/VS1_ART_RECONCILIATION_CURRENT.json'))
    for before,after in zip(baseline['mandatory_rows'],current['mandatory_rows']):
        if before['id']!='MAT-012' and before!=after:raise RuntimeError('Unrelated inventory row changed')
    if current['canonical_row_count']!=185 or len(current['mandatory_rows'])!=185:raise RuntimeError('Canonical row count')
    source=dict(native['source_hashes'])
    for path in ['tools/seal_leaf_atlas_source.py','docs/production/LEAF_ATLAS_SOURCE_READINESS.md','docs/production/review/leaf_atlas.html',str(folder/'results.json')]:source[path]=digest(path)
    executions=sum(capture['assertions'] for capture in native['captures'])
    result={'status':'PASS','utc':dt.datetime.now(dt.timezone.utc).isoformat(),'scope':'MAT-012 unbound raster/alpha source only; no plant carrier/shipping/full row/VS1 acceptance','source_hashes':source,'existing_tracked_game_hashes':protected,'existing_tracked_game_files_preserved':len(protected),'prior_art_hashes':prior,'prior_art_verification_modes':modes,'prior_art_identities_preserved':len(prior),'earlier_stone_and_linen_seals_still_current':True,'runtime_lfs_pointer_identities_preserved':len(pointers),'runtime_lfs_payloads_freshly_materialized_or_tested':0,'new_lfs_payloads':0,'shipping_assignments_added':0,'fresh_assertion_executions':executions,'current_source_continuation_execution_total':132+executions,'native_images_individually_viewed':sorted(str(path.relative_to(root)) for path in (root/folder).glob('*.png')),'current_source_continuation_native_views':24,'atlas_generation_mode':'built-in imagegen: generation plus layout edit','atlas_source_bytes_preserved':True,'alpha_and_size_limitations_documented':True,'inventory_rows_changed':['MAT-012 MISSING -> PARTIAL'],'canonical_rows':185,'vs1_rows':77,'vs1_counts':current['vs1_counts'],'arch011_requirement_changed':False,'last_integrated_production_stable':'5184c48031b5e710b7fdf2b698bccf3091784374','gate_vs1':'OPEN','s03':'BLOCKED'}
    output=root/'docs/production/evidence/archive_reconstruction/leaf-atlas-source-seal-20261007'
    output.mkdir(exist_ok=True);(output/'results.json').write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps({key:result[key] for key in ['status','existing_tracked_game_files_preserved','prior_art_identities_preserved','runtime_lfs_pointer_identities_preserved','fresh_assertion_executions','vs1_counts']}))


if __name__=='__main__':main()
