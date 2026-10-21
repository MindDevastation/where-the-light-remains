#!/usr/bin/env python3
"""Keep exact same-session Low PASS and retry only pre-engine Medium display failure."""
import argparse,datetime as dt,hashlib,json,os,subprocess
from pathlib import Path
from validate_owner_gallery import write_exact

def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def stamp():return dt.datetime.now(dt.timezone.utc).isoformat()
def main(a):
 root=Path(__file__).resolve().parents[1];previous=a.previous.resolve();output=a.output.resolve();private=a.private_workspace.resolve();game=private/'source/game'
 assert output.is_relative_to(root/'docs/production/evidence/archive_reconstruction') and not output.exists()
 old=json.loads((previous/'results.json').read_text());assert old['status']=='FAIL'
 assert next(r for r in old['records'] if r['name']=='low')['passed']
 assert 'Xvfb TCP readiness timeout' in (previous/'medium.log').read_text() and 'Godot Engine' not in (previous/'medium.log').read_text()
 for p,h in old['source_hashes'].items():assert sha(root/p)==h,('Root input changed',p)
 for x in old['runtime_lfs_payloads']:
  p=private/'source'/x['path'];assert p.stat().st_size==x['bytes'] and sha(p)==x['oid_sha256'],p
 normalized_imports={}
 for p,h in old['source_hashes'].items():
  if not p.startswith('game/') or p.endswith('.glb'):continue
  copied=private/'source'/p
  if p.endswith('.import'):
   normalized_imports[p]=sha(copied)
  else:assert sha(copied)==h,('Native input changed',p)
 low=json.loads((previous/'captures_low.json').read_text());assert len(low['captures'])==8
 assert low['renderer']=='forward_plus' and not low['glow'] and not low['volumetrics']
 output.mkdir();result={'status':'RUNNING','started_at':stamp(),'source_hashes':dict(old['source_hashes']),
  'runtime_lfs_payloads':old['runtime_lfs_payloads'],'scope':old['scope'],
  'low_same_session_pass_reused_from':previous.relative_to(root).as_posix(),'low_replayed':False,
  'cache_free_import_this_attempt':False,'prior_fresh_cache_free_import':'owner-gallery-native-20261008-4/clean-import.log',
  'runtime_import_cache_reused':str(game/'.godot'),'editor_normalized_import_sidecar_hashes':normalized_imports,
  'new_lfs_payloads':0,'shipping_changes':0,'inventory_delta':[],'accepted_suites_replayed':False,
  'current_resume_new_native_frames':0,'same_session_reused_low_native_frames':8,'fresh_gameplay_assertion_executions':0,
  'records':[],'captures':[]}
 result['source_hashes']['tools/resume_owner_gallery.py']=sha(Path(__file__).resolve())
 receipt=output/'results.json'
 def save():write_exact(receipt,(json.dumps(result,indent=2)+'\n').encode(),hashlib.sha256((json.dumps(result,indent=2)+'\n').encode()).hexdigest())
 for name in ['low.log','captures_low.json']+[x['file'] for x in low['captures']]:
  p=previous/name;assert sha(p)==old['evidence_hashes'][name],name
  write_exact(output/name,p.read_bytes(),sha(p))
 result['captures']=[x for x in old['captures'] if x['quality']=='low'];assert len(result['captures'])==8
 result['records'].append(next(r for r in old['records'] if r['name']=='low')|{'reused_same_session_pass':True})
 save()
 try:
  slots=private/'userdata/godot/app_userdata/Where the Light Remains'
  before={p.name:sha(p) for p in slots.iterdir() if p.is_file()}
  assert before==next(r for r in old['records'] if r['name']=='low')['slots_after']
  env=dict(os.environ,XDG_DATA_HOME=str(private/'userdata'),GODOT_SILENCE_ROOT_WARNING='1',PYTHONDONTWRITEBYTECODE='1')
  command=['python','-B',str(root/'tools/run_graphical.py'),'--graphics-prefix',str(a.graphics_prefix.resolve()),'--godot',str(a.godot.resolve()),'--timeout','170','--expect','ARCHIVE_OWNER_GALLERY_REVIEW CAPTURED','--','--path',str(game),'--resolution','1280x720','res://tests/archive_owner_gallery_review.tscn','--','--review-output='+str(output),'--quality=medium']
  process=subprocess.run(command,env=env,cwd=root,capture_output=True,timeout=190);raw=process.stdout+process.stderr
  log=output/'medium.log';write_exact(log,raw,hashlib.sha256(raw).hexdigest())
  after={p.name:sha(p) for p in slots.iterdir() if p.is_file()}
  passed=process.returncode==0 and before==after and b'ARCHIVE_OWNER_GALLERY_REVIEW CAPTURED' in raw and not any(x in raw for x in [b'ERROR:',b'WARNING:',b'Parse Error',b'SCRIPT ERROR'])
  result['records'].append({'name':'medium','exit_code':process.returncode,'passed':passed,'log_sha256':sha(log),'slots_before':before,'slots_after':after});save()
  if not passed:raise RuntimeError('Resumed Medium capture failed')
  medium=json.loads((output/'captures_medium.json').read_text());assert len(medium['captures'])==8 and medium['renderer']=='forward_plus'
  for item in medium['captures']:
   assert item['size']==[1280,720] and item['settings_preset']=='Medium'
   assert item['outer_material']=='res://art/materials/m_polished_brass.tres' and item['inner_material']==item['outer_material']
   result['captures'].append(item|{'quality':'medium','sha256':sha(output/item['file'])})
  for p,h in result['source_hashes'].items():assert sha(root/p)==h,('Source changed',p)
  result.update(status='PASS_CAPTURE_ONLY',fresh_native_frames=16,current_resume_new_native_frames=8,visual_review='PENDING individual inspection',owned_private_copy_and_store_removed=False,diagnostic_workspace_retained=str(private),finished_at=stamp())
 except Exception as e:result.update(status='FAIL',failure=str(e),finished_at=stamp());raise
 finally:
  result['evidence_hashes']={p.name:sha(p) for p in output.iterdir() if p.is_file() and p!=receipt};save()
 print(json.dumps({'status':result['status'],'same_session_final_native_frames':len(result['captures']),'Low_replayed':False}))
if __name__=='__main__':
 p=argparse.ArgumentParser(description=__doc__)
 for name in ['previous','output','private-workspace','godot','graphics-prefix']:p.add_argument('--'+name,type=Path,required=True)
 main(p.parse_args())
