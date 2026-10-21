#!/usr/bin/env python3
"""Validate new measured mount routes and reconstructed native target access only."""
import argparse,datetime as dt,hashlib,json,os,subprocess,tempfile
from pathlib import Path

def main(args):
 root=Path(__file__).resolve().parents[1];out=args.output.resolve()
 if out.exists() or not out.is_relative_to(root/'docs/production/evidence/archive_reconstruction'):raise ValueError('New bounded evidence folder required')
 def sha(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()
 cp=root/'docs/production/core_orbits_mount_revision2.json';c=json.loads(cp.read_text())
 sources={p:sha(root/p) for p in c['inputs']}
 for p,v in c['inputs'].items():
  if sources[p]!=v:raise RuntimeError('Authority changed: '+p)
 for p in ['docs/production/core_orbits_mount_revision2.json','tools/probe_core_mount_access.gd','tools/validate_core_mount_access.py']:sources[p]=sha(root/p)
 # Protect the exact prior trim source seal without replaying its accepted suite.
 old=json.loads((root/'docs/production/evidence/archive_reconstruction/stone-trim-source-seal-20261007/results.json').read_text())
 for p,v in old['source_hashes'].items():
  if sha(root/p)!=v:raise RuntimeError('Prior trim/source proof changed: '+p)
 player=(root/'game/core/player/player.gd').read_text();scene=(root/'game/core/player/player.tscn').read_text()
 for statement in ['var interaction_reach := 2.5','var interaction_mask := 3','query.collide_with_areas = true','query.hit_from_inside = true']:
  if statement not in player:raise RuntimeError('Actual player query contract changed')
 for statement in ['radius = 0.35','position = Vector3(0, 1.62, 0)']:
  if statement not in scene:raise RuntimeError('Actual player dimensions changed')
 out.mkdir(parents=True)
 with tempfile.TemporaryDirectory(prefix='wlr-mount-access-') as folder:
  private=Path(folder);(private/'project.godot').write_text('config_version=5\n[application]\nconfig/name="WLR Private Mount Access Probe"\n[physics]\n3d/physics_engine="GodotPhysics3D"\n')
  copies={'contract.json':cp,'interfaces.json':root/'docs/production/evidence/archive_reconstruction/core-hero-audit-20261007/interfaces.json','metric.json':root/'docs/production/evidence/archive_reconstruction/core-orbits-brief-20261007/results.json','probe.gd':root/'tools/probe_core_mount_access.gd','interaction_target.gd':root/'game/core/interaction/interaction_target.gd'}
  for name,path in copies.items():(private/name).write_bytes(path.read_bytes())
  env=dict(os.environ,XDG_DATA_HOME=str(private/'userdata'),GODOT_SILENCE_ROOT_WARNING='1',PYTHONDONTWRITEBYTECODE='1',WLR_PROBE_RESULT=str(out/'native.json'))
  command=[str(args.godot.resolve()),'--headless','--path',str(private),'--script','res://probe.gd']
  p=subprocess.run(command,env=env,capture_output=True,timeout=60)
  raw=p.stdout+p.stderr;(out/'native.log').write_bytes(raw)
  native=json.loads((out/'native.json').read_text()) if (out/'native.json').exists() else {'status':'NOT_REACHED'}
  errors=any(word in raw for word in [b'ERROR:',b'WARNING:',b'SCRIPT ERROR'])
  result={'status':'PASS_BRIEF_ONLY' if not p.returncode and not errors and native['status']=='PASS_RECONSTRUCTED_ACCESS_AND_MOUNT_BRIEF' else 'FAIL','utc':dt.datetime.now(dt.timezone.utc).isoformat(),'source_hashes':sources,'native_status':native['status'],'native_assertions':native.get('assertions',0),'commands':[{'argv':['Godot4.7.2','--headless','--path','OWNED_PRIVATE_FIXTURE','--script','res://probe.gd'],'exit_code':p.returncode,'warning_or_error':errors}],'prior_trim_source_seal_current':True,'prior_native_tests_replayed':False,'owned_private_fixture_removed':True,'shipping_changes':0,'new_lfs_payloads':0,'inventory_delta':[],'scope':'Measured v2 mount envelope and20 reconstructed native target queries;no actual E/gameplay/Blender/GLB/style/performance acceptance','evidence_hashes':{path.name:sha(path) for path in out.iterdir() if path.is_file()}}
  (out/'results.json').write_text(json.dumps(result,indent=2)+'\n')
 for p,v in sources.items():
  if sha(root/p)!=v:raise RuntimeError('Source changed during probe')
 print(json.dumps({k:result[k] for k in ['status','native_assertions','native_status']}))
 if result['status']!='PASS_BRIEF_ONLY':raise SystemExit(1)

if __name__=='__main__':
 parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--godot',type=Path,required=True);parser.add_argument('--output',type=Path,required=True);main(parser.parse_args())
