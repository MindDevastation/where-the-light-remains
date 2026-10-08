#!/usr/bin/env python3
"""Seal corrected measured mount handoff without shipping/art acceptance."""
import datetime as dt,hashlib,json,subprocess
from collections import Counter
from pathlib import Path

def main():
 root=Path(__file__).resolve().parents[1]
 def sha(p):return hashlib.sha256((root/p).read_bytes()).hexdigest()
 def git(*args):return subprocess.check_output(['git',*args],cwd=root)
 folder=Path('docs/production/evidence/archive_reconstruction/core-mount-access-20261008-final')
 result=json.loads((root/folder/'results.json').read_text());native=json.loads((root/folder/'native.json').read_text())
 assert result['status']=='PASS_BRIEF_ONLY' and result['native_assertions']==135
 assert native['status']=='PASS_RECONSTRUCTED_ACCESS_AND_MOUNT_BRIEF' and len(native['access_queries'])==20
 source=dict(result['source_hashes'])
 for p,v in source.items():assert sha(p)==v,p
 for p,v in result['evidence_hashes'].items():assert sha(folder/p)==v,p
 old=json.loads((root/'docs/production/evidence/archive_reconstruction/stone-trim-source-seal-20261007/results.json').read_text())
 for p,v in old['source_hashes'].items():assert sha(p)==v,('Prior trim seal',p)
 baseline='27b376400a11f1114f4cba75886069a16c694be1';protected={}
 for p in git('ls-tree','-r','--name-only',baseline,'--','game').decode().splitlines():
  expected=hashlib.sha256(git('show',baseline+':'+p)).hexdigest();assert sha(p)==expected,('Runtime changed',p);protected[p]=expected
 inventory='docs/production/VS1_ART_RECONCILIATION_CURRENT.json'
 assert git('show',baseline+':'+inventory)==(root/inventory).read_bytes()
 current=json.loads((root/inventory).read_text());counts=dict(Counter(r['status'] for r in current['mandatory_rows'] if r['required_for_vs1']))
 assert counts=={'ACCEPTED':26,'PARTIAL':44,'MISSING':7} and len(current['mandatory_rows'])==185
 for p in [str(folder/'results.json'),str(folder/'native.json'),str(folder/'native.log'),str(folder/'mount_revision2_metric.png'),str(folder/'mount_revision2_metric.svg'),'tools/render_core_mount_metric.py','tools/seal_core_mount_brief.py','docs/production/CORE_ORBITS_MOUNT_REVISION2.md']:
  source[p]=sha(p)
 seal={'status':'PASS_BRIEF_ONLY','utc':dt.datetime.now(dt.timezone.utc).isoformat(),'source_hashes':source,'baseline':baseline,'existing_game_hashes':protected,'existing_game_files_preserved':len(protected),'prior_trim_source_seal_still_exact':True,'earlier_accepted_suites_replayed':False,'final_native_assertion_executions':135,'reconstructed_native_target_queries':20,'superseded_attempt2_assertions_excluded':132,'graphical_native_frames_added':0,'inspected_metric_diagram':str(folder/'mount_revision2_metric.png'),'old_bridge_support_envelope_intersection_reproduced':True,'revised_minimum_nonconnected_bridge_gap_m':min(r['revised_support_gap_lower_bound_m'] for r in native['bridge_orbit_comparisons']),'selected_native_ray_continuous_yaw_enclosure_gap_m':min(r['continuous_yaw_visual_ray_clearance_lower_bound_m'] for r in native['access_queries']),'scope':'Corrected measured proposal and reconstructed native shape/ray/component queries only;not actual E/FirstPersonPlayer/ArchiveMain/state/save/Blender/GLB/LFS/style/performance acceptance','inventory_rows_changed':[],'canonical_rows':185,'vs1_counts':counts,'shipping_changes':0,'new_lfs_payloads':0,'last_trim_source_stable':'ce45badde40e94ef0ca13e84d50dbb0b465545fb','last_integrated_runtime_stable':'5184c48031b5e710b7fdf2b698bccf3091784374','arch011_owner_choice':'PENDING A/B','gate_vs1':'OPEN','s03':'BLOCKED'}
 output=root/'docs/production/evidence/archive_reconstruction/core-mount-brief-seal-20261008';output.mkdir(exist_ok=True);(output/'results.json').write_text(json.dumps(seal,indent=2)+'\n')
 print(json.dumps({k:seal[k] for k in ['status','existing_game_files_preserved','final_native_assertion_executions','reconstructed_native_target_queries','vs1_counts']}))
if __name__=='__main__':main()
