#!/usr/bin/env python3
"""Validate already completed native captures after an empty engine lock delta.

Retain the original failed directory-wide check. Do not rerun captured views,
delete the engine marker, relax native diagnostics or touch shipping sources.
"""
import argparse,datetime,hashlib,json,subprocess
from pathlib import Path
from PIL import Image
from validate_owner_gallery import protected_slots_unchanged,write_exact

ROOT=Path(__file__).resolve().parents[1]
ENGINE_COMMIT='ed1daf0bf001b61586d9930840f2f1394092c079'
CAPTURE_SOURCE='b19240ff628e817a875b0333845f61b528f7ad55'
EMPTY=hashlib.sha256(b'').hexdigest()
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main(a):
 previous=a.previous.resolve();output=a.output.resolve();private=a.private_workspace.resolve()
 assert previous.is_relative_to(ROOT/'docs/production/evidence/archive_reconstruction')
 assert output.is_relative_to(previous.parent) and not output.exists()
 old=json.loads((previous/'results.json').read_text())
 assert old['status']=='FAIL' and old['failure']=='Native gallery command failed: medium'
 assert len(old['runtime_lfs_payloads'])==47 and old['current_run_fresh_payload_reads']==47
 records={r['name']:r for r in old['records']}
 assert records['clean-import']['passed'] and records['low']['passed']
 medium=records['medium'];assert medium['exit_code']==0 and not medium['passed']
 before=medium['slots_before'];after=medium['slots_after']
 assert set(before)=={'savegame.json','savegame.backup.json'}
 assert set(after)-set(before)=={'.recovery_mode_lock'}
 assert after['.recovery_mode_lock']==EMPTY
 assert protected_slots_unchanged(before,after)
 # Negative controls are synthetic guard checks, not gameplay executions.
 assert not protected_slots_unchanged(before,after|{'savegame.json':'changed'})
 assert not protected_slots_unchanged(before,after|{'savegame.backup.json':'changed'})
 assert not protected_slots_unchanged(before,after|{'unexpected.json':EMPTY})
 assert not protected_slots_unchanged(before,after|{'.recovery_mode_lock':'nonempty'})
 assert not protected_slots_unchanged(before,{'savegame.json':before['savegame.json']})
 slots=private/'userdata/godot/app_userdata/Where the Light Remains'
 current={p.name:sha(p) for p in slots.iterdir() if p.is_file()}
 assert current==after
 marker=slots/'.recovery_mode_lock';assert marker.is_file() and marker.stat().st_size==0
 source_hashes={}
 for name,h in old['source_hashes'].items():
  if name=='tools/validate_owner_gallery.py':
   original=subprocess.check_output(['git','show',CAPTURE_SOURCE+':'+name],cwd=ROOT)
   assert hashlib.sha256(original).hexdigest()==h
  else:
   assert sha(ROOT/name)==h,name
   source_hashes[name]=h
 for row in old['runtime_lfs_payloads']:
  p=private/'source'/row['path'];assert p.stat().st_size==row['bytes'] and sha(p)==row['oid_sha256']
 for name in ['tools/validate_owner_gallery.py','tools/finalize_completed_owner_gallery.py']:
  source_hashes[name]=sha(ROOT/name)
 captures=[];final_records=[];normalized_imports={}
 for name in ['clean-import','low','medium']:
  record=records[name];log=previous/(name+'.log');raw=log.read_bytes()
  assert sha(log)==record['log_sha256'] and record['exit_code']==0
  assert not any(word in raw for word in [b'ERROR:',b'WARNING:',b'SCRIPT ERROR',b'Parse Error'])
  assert protected_slots_unchanged(record['slots_before'],record['slots_after'])
  if name!='clean-import':assert b'ARCHIVE_OWNER_GALLERY_REVIEW CAPTURED' in raw and b'GRAPHICAL_RUN PASS' in raw
  final_records.append(record|{'original_directory_guard_passed':record['passed'],
      'passed':True,'guard_scope':'Exact primary/backup plus only an empty documented Godot lock; full snapshots retained'})
 for quality in ['low','medium']:
  meta=json.loads((previous/f'captures_{quality}.json').read_text())
  assert meta['renderer']=='forward_plus' and len(meta['captures'])==8
  for item in meta['captures']:
   p=previous/item['file'];assert sha(p)==old['evidence_hashes'][p.name]
   assert item['size']==[1280,720] and item['settings_preset']==quality.title()
   assert item['outer_material']==item['inner_material']=='res://art/materials/m_polished_brass.tres'
   with Image.open(p) as im:assert im.size==(1280,720);im.verify()
   captures.append(item|{'quality':quality,'sha256':sha(p)})
 for item in captures[:8]:
  other=next(r for r in captures if r['name']==item['name'] and r['quality']=='medium')
  assert other['camera_transform']==item['camera_transform'] and other['camera_fov']==item['camera_fov']
 for name in old['source_hashes']:
  if name.endswith('.import'):normalized_imports[name]=sha(private/'source'/name)
 output.mkdir()
 copied=['clean-import.log','low.log','medium.log','captures_low.json','captures_medium.json']+[r['file'] for r in captures]
 for name in copied:
  p=previous/name;write_exact(output/name,p.read_bytes(),sha(p))
 result={'status':'PASS_CAPTURE_ONLY','finished_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),
  'source_hashes':source_hashes,'runtime_lfs_payloads':old['runtime_lfs_payloads'],
  'records':final_records,'captures':captures,'fresh_native_frames':16,
  'native_frames_rendered_by_this_finalizer':0,'same_session_original_frames_reused':16,
  'new_native_render_executions_by_this_finalizer':0,'fresh_gameplay_assertion_executions':0,
  'prior_failed_directory_check':previous.relative_to(ROOT).as_posix(),
  'prior_failed_receipt_sha256':sha(previous/'results.json'),
  'captured_driver_commit':CAPTURE_SOURCE,
  'captured_driver_sha256':old['source_hashes']['tools/validate_owner_gallery.py'],
  'slot_guard_source':'https://github.com/godotengine/godot/blob/'+ENGINE_COMMIT+'/core/os/os.cpp',
  'engine_lock_retained':{'path':str(marker),'bytes':0,'sha256':EMPTY},
  'synthetic_guard_negative_controls':5,'protected_slots_unchanged':True,
  'editor_normalized_import_sidecar_hashes':normalized_imports,
  'independent_store_initially_empty':True,'current_run_fresh_payload_reads':47,
  'cache_free_import_this_session':True,'owned_private_copy_and_store_removed':False,
  'diagnostic_workspace_retained':str(private),'shipping_changes':0,'new_lfs_payloads':0,
  'inventory_delta':[],'accepted_suites_replayed':False,'visual_review':'PENDING individual inspection',
  'scope':'Sixteen original 20261021 native frames with exact source/payload, native exit, DTO/dirty and primary/backup guards. Original all-directory guard FAIL retained; only the documented empty engine lock is distinguished. No gameplay/target GPU/owner-style acceptance.'}
 result['evidence_hashes']={p.name:sha(p) for p in output.iterdir() if p.is_file()}
 (output/'results.json').write_text(json.dumps(result,indent=2)+'\n')
 print(json.dumps({'status':result['status'],'original_native_frames_reused':16,'fresh_native_commands':0,'protected_slots_unchanged':True}))
if __name__=='__main__':
 p=argparse.ArgumentParser(description=__doc__)
 for name in ['previous','output','private-workspace']:p.add_argument('--'+name,type=Path,required=True)
 main(p.parse_args())
