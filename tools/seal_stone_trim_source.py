#!/usr/bin/env python3
"""Seal exact TRIM-002 source and measured handoff; no shipping acceptance."""
import datetime as dt
import hashlib,json,re,subprocess
from pathlib import Path

def main():
 root=Path(__file__).resolve().parents[1]
 def sha(path):return hashlib.sha256((root/path).read_bytes()).hexdigest()
 def git(*args):return subprocess.check_output(['git',*args],cwd=root)
 seals=[json.loads((root/f'docs/production/evidence/archive_reconstruction/{name}-source-seal-20261007/results.json').read_text()) for name in ['cool-stone','linen','leaf-atlas']]
 for seal in seals:
  for p,v in seal['source_hashes'].items():assert sha(p)==v,('Earlier source changed',p)
  for p,v in seal['existing_tracked_game_hashes'].items():
   if p!='game/README.md':assert sha(p)==v,('Earlier runtime changed',p)
 prior=seals[-1]['prior_art_hashes'];modes=seals[-1]['prior_art_verification_modes']
 for p,v in prior.items():
  if modes[p].startswith('Committed pointer/OID'):
   m=re.fullmatch(rb'version https://git-lfs.github.com/spec/v1\noid sha256:([0-9a-f]{64})\nsize ([0-9]+)\n',(root/p).read_bytes());assert m and m[1].decode()==v,p
  else:assert sha(p)==v,p
 baseline='2f9326f3d7e27522ba667e877e90ef22a2d5ae99'
 protected={};documentation=[]
 for p in git('ls-tree','-r','--name-only',baseline,'--','game').decode().splitlines():
  old=hashlib.sha256(git('show',baseline+':'+p)).hexdigest();new=sha(p)
  if p=='game/README.md':
   assert old!=new;documentation.append({'path':p,'before_sha256':old,'after_sha256':new,'reason':'Explicit user request:replace scaffold README with current playable scope'})
  else:assert old==new,('Existing runtime changed',p);protected[p]=new
 pointers={}
 for p in protected:
  if p.endswith('.glb'):
   m=re.fullmatch(rb'version https://git-lfs.github.com/spec/v1\noid sha256:([0-9a-f]{64})\nsize ([0-9]+)\n',(root/p).read_bytes());assert m,p;pointers[p]={'oid_sha256':m[1].decode(),'size':int(m[2])}
 assert len(pointers)==47 and len(prior)==193
 folder=Path('docs/production/evidence/archive_reconstruction/stone-trim-native-3');native=json.loads((root/folder/'results.json').read_text());assert native['status']=='PASS'
 source=dict(native['source_hashes'])
 for p,v in source.items():assert sha(p)==v,p
 count=sum(c['assertions'] for c in native['captures']);assert count==128
 images=sorted(str(p.relative_to(root)) for p in (root/folder).glob('*.png'));assert len(images)==8
 corefolder=Path('docs/production/evidence/archive_reconstruction/core-orbits-brief-20261007');core=json.loads((root/corefolder/'results.json').read_text());assert core['status']=='PASS_METRIC_BRIEF_ONLY'
 for p,v in core['source_hashes'].items():assert sha(p)==v,p;source[p]=v
 for p,v in core['evidence_hashes'].items():assert sha(corefolder/p)==v,p;source[str(corefolder/p)]=v
 current=json.loads((root/'docs/production/VS1_ART_RECONCILIATION_CURRENT.json').read_text());before=json.loads(git('show',baseline+':docs/production/VS1_ART_RECONCILIATION_CURRENT.json'))
 delta=[(a['id'],a['status'],b['status']) for a,b in zip(before['mandatory_rows'],current['mandatory_rows']) if a!=b]
 assert delta==[('TRIM-002','MISSING','PARTIAL')];assert len(current['mandatory_rows'])==current['canonical_row_count']==185
 assert sum(r['required_for_vs1'] for r in current['mandatory_rows'])==77
 assert current['vs1_counts']=={'ACCEPTED':26,'PARTIAL':44,'MISSING':7}
 for p in ['tools/seal_stone_trim_source.py','docs/production/STONE_TRIM_SOURCE_READINESS.md','docs/production/STONE_TRIM_FIRST_INTEGRATION.md','docs/production/CORE_ORBITS_PRODUCTION_BRIEF.md','docs/production/review/stone_trim.html',str(folder/'results.json'),str(corefolder/'results.json'),'docs/production/VS1_ART_RECONCILIATION_CURRENT.json']:
  source[p]=sha(p)
 result={'status':'PASS','utc':dt.datetime.now(dt.timezone.utc).isoformat(),'scope':'TRIM-002 unbound original source and measured first-carrier/three-orbit handoff only','source_hashes':source,'protected_baseline':baseline,'existing_runtime_game_hashes':protected,'existing_runtime_game_files_preserved':len(protected),'intentional_documentation_changes':documentation,'prior_art_identities_preserved':len(prior),'earlier_three_family_source_hashes_still_current':True,'runtime_lfs_pointer_identities':pointers,'runtime_lfs_pointer_identities_preserved':47,'runtime_lfs_payloads_freshly_materialized_or_tested':0,'new_lfs_payloads':0,'shipping_assignments_added':0,'fresh_assertion_executions':128,'native_images_individually_viewed':images,'excluded_diagnostics':['stone-trim-native-1 failed authored-relief check;source corrected without weakening threshold','stone-trim-native-2 superseded by actual vertex/UV measurement;128 executions excluded'],'prior_material_execution_total_historical':300,'prior_material_native_views_historical':24,'core_brief':'PASS_METRIC_BRIEF_ONLY;actual native Euler basis/continuous yaw lower bounds;no E-ray/style/geometry acceptance','core_metric_drawing_individually_viewed':str(corefolder/'core_orbits_metric.png'),'inventory_rows_changed':delta,'canonical_rows':185,'vs1_rows':77,'vs1_counts':current['vs1_counts'],'arch011_requirement_changed':False,'last_integrated_production_stable':'5184c48031b5e710b7fdf2b698bccf3091784374','gate_vs1':'OPEN','s03':'BLOCKED'}
 output=root/'docs/production/evidence/archive_reconstruction/stone-trim-source-seal-20261007';output.mkdir(exist_ok=True);(output/'results.json').write_text(json.dumps(result,indent=2)+'\n')
 print(json.dumps({k:result[k] for k in ['status','existing_runtime_game_files_preserved','prior_art_identities_preserved','runtime_lfs_pointer_identities_preserved','fresh_assertion_executions','vs1_counts']}))
if __name__=='__main__':main()
