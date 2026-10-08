#!/usr/bin/env python3
"""Capture current shipping geometry overview after independent existing LFS reads."""
import argparse,concurrent.futures,contextlib,datetime as dt,hashlib,json,os,re,shutil,subprocess,tempfile
from pathlib import Path

def sha(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()
def stamp():return dt.datetime.now(dt.timezone.utc).isoformat()
def write_exact(path,data,expected):
 path.parent.mkdir(parents=True,exist_ok=True);fd=os.open(path,os.O_CREAT|os.O_WRONLY|os.O_TRUNC,0o644)
 try:
  offset=0
  while offset<len(data):
   written=os.write(fd,memoryview(data)[offset:offset+65536]);assert written>0;offset+=written
  os.fsync(fd)
 finally:os.close(fd)
 assert sha(path)==expected and path.stat().st_size==len(data)

def main(args):
 root=Path(__file__).resolve().parents[1];output=args.output.resolve()
 if output.exists() or not output.is_relative_to(root/'docs/production/evidence/archive_reconstruction'):raise ValueError('New evidence folder required')
 files=sorted(p.relative_to(root).as_posix() for p in (root/'game').rglob('*') if p.is_file() and not any(part in {'.godot','__pycache__'} for part in p.parts))
 hashes={p:sha(root/p) for p in files}
 for p in ['tools/validate_owner_gallery.py','tools/run_graphical.py']:hashes[p]=sha(root/p)
 output.mkdir(parents=True)
 result={'status':'RUNNING','started_at':stamp(),'source_hashes':hashes,'runtime_lfs_payloads':[],'records':[],'captures':[],'scope':'Fresh native current geometry/material/lighting overview. Original S00 rail and quiet state projections. No full gameplay/E/route/save suite,Blender source reopen,authored3D/LFS upload or style/target-GPU acceptance','new_lfs_payloads':0,'shipping_changes':0,'inventory_delta':[],'accepted_suites_replayed':False}
 receipt=output/'results.json'
 def save():receipt.write_text(json.dumps(result,indent=2)+'\n')
 save()
 try:
  if args.private_workspace:
   assert not args.private_workspace.exists()
   assert args.private_workspace.resolve().is_relative_to(root.parent) and not args.private_workspace.resolve().is_relative_to(root)
   args.private_workspace.mkdir()
   workspace=contextlib.nullcontext(str(args.private_workspace.resolve()))
  else:workspace=tempfile.TemporaryDirectory(prefix='wlr-owner-gallery-')
  with workspace as directory:
   private=Path(directory);clean=private/'source';store=private/'independent-lfs'
   assert not store.exists()
   env=dict(os.environ,GIT_TERMINAL_PROMPT='0',GIT_ASKPASS='/bin/false',GODOT_SILENCE_ROOT_WARNING='1',PYTHONDONTWRITEBYTECODE='1')
   env.pop('GH_TOKEN',None);env.pop('GITHUB_TOKEN',None)
   # Isolate LFS metadata scans from the sparse promisor checkout.
   reader=private/'lfs-reader'
   subprocess.run(['git','init','-q','-b','lfs-read-scratch',str(reader)],env=env,check=True)
   subprocess.run(['git','remote','add','origin','https://github.com/MindDevastation/where-the-light-remains.git'],cwd=reader,env=env,check=True)
   subprocess.run(['git','-c','user.name=Archive Review','-c','user.email=review@example.invalid','commit','-q','--allow-empty','-m','Temporary existing payload read namespace'],cwd=reader,env=env,check=True)
   result['lfs_metadata_namespace']='owned minimal Git repository;same origin LFS endpoint;no sparse/promisor full-tree size scan'

   pointers=[]
   for name in files:
    data=(root/name).read_bytes()
    if name.endswith('.glb'):
     m=re.fullmatch(rb'version https://git-lfs.github.com/spec/v1\noid sha256:([0-9a-f]{64})\nsize ([0-9]+)\n',data)
     if not m:raise RuntimeError('Unexpected working GLB state: '+name)
     committed=subprocess.check_output(['git','show','HEAD:'+name],cwd=root);assert committed==data
     pointers.append({'path':name,'oid_sha256':m[1].decode(),'bytes':int(m[2]),'pointer_sha256':hashes[name],'pointer':data})
    else:write_exact(clean/name,data,hashes[name])
   def retrieve(item):
    command=['git','-c','lfs.storage='+str(store),'-c','lfs.dialtimeout=8','-c','lfs.tlstimeout=8','-c','lfs.activitytimeout=8','-c','lfs.transfer.maxretries=0','lfs','smudge','--',item['path']]
    cached=args.payload_cache/item['path'] if args.payload_cache else None
    if cached and cached.exists() and cached.stat().st_size==item['bytes'] and sha(cached)==item['oid_sha256']:
     write_exact(clean/item['path'],cached.read_bytes(),item['oid_sha256'])
     return {k:v for k,v in item.items() if k!='pointer'}|{'independently_retrieved':False,'reused_verified_payload_cache':str(args.payload_cache)}
    p=subprocess.run(command,cwd=reader,input=item['pointer'],env=env,capture_output=True,timeout=40)
    if p.returncode or len(p.stdout)!=item['bytes'] or hashlib.sha256(p.stdout).hexdigest()!=item['oid_sha256']:
     raise RuntimeError('Existing payload read failed: '+item['path']+';exit='+str(p.returncode)+';stderr='+p.stderr.decode(errors='replace'))
    write_exact(clean/item['path'],p.stdout,item['oid_sha256'])
    return {k:v for k,v in item.items() if k!='pointer'}|{'independently_retrieved':True}
   with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
    for row in pool.map(retrieve,pointers):
     result['runtime_lfs_payloads'].append(row);save();print(json.dumps({'existing_runtime_payloads_verified':len(result['runtime_lfs_payloads']),'total':len(pointers)}),flush=True)
   assert len(pointers)==47
   result['independent_store_initially_empty']=True
   result['current_run_fresh_payload_reads']=sum(x['independently_retrieved'] for x in result['runtime_lfs_payloads'])
   result['current_run_verified_cache_reuses']=47-result['current_run_fresh_payload_reads']
   data=private/'userdata';slots=data/'godot/app_userdata/Where the Light Remains';slots.mkdir(parents=True)
   for name in ['savegame.json','savegame.backup.json']:(slots/name).write_text('{"protected_fixture":true}\n')
   before={p.name:sha(p) for p in slots.iterdir()};env['XDG_DATA_HOME']=str(data)
   def run(name,command,timeout,marker=''):
    p=subprocess.run(command,cwd=clean,env=env,capture_output=True,timeout=timeout);raw=p.stdout+p.stderr;log=output/(name+'.log');log.write_bytes(raw)
    after={p.name:sha(p) for p in slots.iterdir() if p.is_file()}
    passed=not p.returncode and before==after and (not marker or marker.encode() in raw) and not any(word in raw for word in [b'ERROR:',b'WARNING:',b'SCRIPT ERROR',b'Parse Error'])
    result['records'].append({'name':name,'exit_code':p.returncode,'passed':passed,'log_sha256':sha(log),'slots_before':before,'slots_after':after});save();print(json.dumps({'command':name,'passed':passed}),flush=True)
    if not passed:raise RuntimeError('Native gallery command failed: '+name)
   godot=str(args.godot.resolve())
   run('clean-import',[godot,'--headless','--path',str(clean/'game'),'--editor','--import'],180)
   for quality in ['low','medium']:
    run(quality,['python','-B',str(root/'tools/run_graphical.py'),'--graphics-prefix',str(args.graphics_prefix.resolve()),'--godot',godot,'--timeout','170','--expect','ARCHIVE_OWNER_GALLERY_REVIEW CAPTURED','--','--path',str(clean/'game'),'--resolution','1280x720','res://tests/archive_owner_gallery_review.tscn','--','--review-output='+str(output),'--quality='+quality],190,'ARCHIVE_OWNER_GALLERY_REVIEW CAPTURED')
    capture=json.loads((output/('captures_'+quality+'.json')).read_text());assert capture['renderer']=='forward_plus' and len(capture['captures'])==8
    for item in capture['captures']:
     assert item['size']==[1280,720] and item['outer_material']=='res://art/materials/m_polished_brass.tres' and item['inner_material']==item['outer_material']
     result['captures'].append(item|{'quality':quality,'sha256':sha(output/item['file'])})
    save()
   for p,v in hashes.items():assert sha(root/p)==v,('Source changed',p)
  if args.private_workspace:shutil.rmtree(args.private_workspace)
  result.update(status='PASS_CAPTURE_ONLY',owned_private_copy_and_store_removed=True,finished_at=stamp(),fresh_native_frames=16,visual_review='PENDING individual inspection',fresh_gameplay_assertion_executions=0)
 except Exception as e:
  result.update(status='FAIL',failure=str(e),finished_at=stamp(),diagnostic_workspace_retained=str(args.private_workspace) if args.private_workspace else None);raise
 finally:
  result['evidence_hashes']={p.name:sha(p) for p in output.iterdir() if p.is_file() and p!=receipt};save()
 print(json.dumps({'status':result['status'],'fresh_native_frames':len(result['captures']),'existing_payloads_verified':len(result['runtime_lfs_payloads'])}))

if __name__=='__main__':
 parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--godot',type=Path,required=True);parser.add_argument('--graphics-prefix',type=Path,required=True);parser.add_argument('--output',type=Path,required=True);parser.add_argument('--payload-cache',type=Path,help='Verified prior owned payload cache;reuse separately labelled');parser.add_argument('--private-workspace',type=Path,help='Owned scratch directory retained only on failure for import diagnostics');main(parser.parse_args())
