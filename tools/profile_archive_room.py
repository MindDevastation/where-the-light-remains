#!/usr/bin/env python3
"""Exact-source 1080p room measurements; software results never satisfy target gates."""
import argparse
import hashlib
import json
import math
import os
from pathlib import Path
import shutil
import statistics
import subprocess
import sys
import tempfile

import verify_lfs_asset_family as checked


def save(path,value):
    data=(json.dumps(value,indent=2)+'\n').encode()
    pending=path.with_name(path.name+'.pending')
    checked.write_payload(pending,data,hashlib.sha256(data).hexdigest())
    os.replace(pending,path)
    if path.read_bytes()!=data:
        raise RuntimeError('Room profile receipt readback mismatch')


def summary(values):
    ordered=sorted(values)
    return {'min':ordered[0],'median':statistics.median(ordered),
            'p95':ordered[math.ceil(.95*len(ordered))-1],'max':ordered[-1]}


def validate(args):
    if sys.platform!='linux':
        raise ValueError('This runner requires Linux: private XDG save isolation is not verified on other hosts')
    root=Path(__file__).resolve().parents[1]
    output=args.output.resolve()
    if output.exists() or not output.is_relative_to(root/'docs/production/evidence/archive_reconstruction'):
        raise ValueError('Use a new room evidence directory')
    if not 60<=args.samples<=600:
        raise ValueError('Sample count must be between 60 and 600')
    if not 15<=args.warmup<=180:
        raise ValueError('Warm-up count must be between 15 and 180, with a 1.2-second minimum')
    paths=sorted(p.relative_to(root).as_posix() for p in (root/'game').rglob('*') if p.is_file()
        and not p.is_symlink() and not any(x in {'.godot','__pycache__'} for x in p.parts))
    paths+=['tools/profile_archive_room.py','tools/verify_lfs_asset_family.py','tools/session_snapshot.py',
        'tools/run_graphical.py','tools/linux_graphics_packages.json']
    hashes={name:checked.digest(root/name) for name in paths}
    output.mkdir(parents=True)
    result={'status':'RUNNING','started_at':checked.stamp(),'source_hashes':hashes,'commands':[],
        'scope':'Instrumented actual GameRoot 1080p room measurements on the identified renderer only.',
        'target_performance_status':'NOT_ACCEPTED','full_release_profiler_runs':0,'profiles':[]}
    receipt=output/'results.json'
    save(receipt,result)
    try:
        with tempfile.TemporaryDirectory(prefix='wlr-room-profile-') as private:
            clean=Path(private)
            for name in paths:
                target=clean/name
                target.parent.mkdir(parents=True,exist_ok=True)
                shutil.copyfile(root/name,target)
                if checked.digest(target)!=hashes[name]:
                    raise RuntimeError('Private profile copy mismatch')
            data=clean/'userdata'
            slots=data/'godot/app_userdata/Where the Light Remains'
            slots.mkdir(parents=True)
            fixture={'save_version':1,'stage_id':'s01_saved_fixture','checkpoint_id':'protected',
                'collected_fragments':[],'world_states':{},'milestones':{},'achievement_ids':[],'game_completed':False}
            for name in ['savegame.json','savegame.backup.json']:
                (slots/name).write_text(json.dumps(fixture)+'\n')
            before={p.name:checked.digest(p) for p in slots.iterdir()}
            env=dict(os.environ,GODOT_SILENCE_ROOT_WARNING='1',XDG_DATA_HOME=str(data))

            def run(name,command,timeout,marker=''):
                started=checked.stamp()
                try:
                    process=subprocess.run(command,cwd=clean,env=env,stdout=subprocess.PIPE,
                        stderr=subprocess.STDOUT,timeout=timeout)
                except subprocess.TimeoutExpired as error:
                    (output/(name+'.log')).write_bytes(error.stdout or b'')
                    raise RuntimeError('Bounded profile command timeout: '+name) from error
                log=output/(name+'.log')
                log.write_bytes(process.stdout)
                after={p.name:checked.digest(p) for p in slots.iterdir() if p.is_file()}
                passed=process.returncode==0 and before==after and (not marker or marker.encode() in process.stdout) and \
                    not any(word in process.stdout for word in [b'ERROR:',b'SCRIPT ERROR',b'Parse Error',b'WARNING:'])
                result['commands'].append({'name':name,'command':command,'started_at':started,
                    'finished_at':checked.stamp(),'exit_code':process.returncode,'passed':passed,
                    'slots_before':before,'slots_after':after,'log_sha256':checked.digest(log)})
                save(receipt,result)
                print(json.dumps({'name':name,'passed':passed}),flush=True)
                if not passed:
                    raise RuntimeError('Room profile command failed: '+name)

            godot=str(args.godot.resolve())
            run('clean_import',[godot,'--headless','--path','game','--editor','--import'],90)
            run('normal_startup',[godot,'--headless','--path','game','--quit-after','8'],30)
            for quality in ['low','medium']:
                command=[godot,'--path','game','--resolution','1920x1080',
                    'res://tests/archive_room_profile.tscn','--','--profile-output='+str(output),
                    '--quality='+quality,'--samples='+str(args.samples),'--warmup='+str(args.warmup)]
                if args.graphics_prefix:
                    command=[sys.executable,'-B',str(clean/'tools/run_graphical.py'),
                        '--graphics-prefix',str(args.graphics_prefix.resolve()),'--godot',godot,
                        '--timeout','250','--expect','ARCHIVE_ROOM_PROFILE MEASURED','--']+command[1:]
                run(quality,command,270,'ARCHIVE_ROOM_PROFILE MEASURED')
                raw=json.loads((output/('profile_'+quality+'.json')).read_text())
                if raw['status']!='MEASURED' or raw['renderer']!='forward_plus' or raw['window_size']!=[1920,1080] or \
                    raw['render_scale']!=(.75 if quality=='low' else 1) or len(raw['records'])!=3 or raw['max_fps']!=0:
                    raise RuntimeError('Wrong profile renderer/resolution/scale/case count/frame cap')
                software=any(x in raw['device'].lower() for x in ['llvmpipe','lavapipe','swiftshader','software'])
                record={'quality':quality,'device':raw['device'],'device_kind':'SOFTWARE' if software else 'DEVICE_NAME_UNVERIFIED',
                    'render_scale':raw['render_scale'],'visible_shadow_lights':raw['visible_shadow_lights'],'cases':[]}
                for case in raw['records']:
                    frames=case['samples']
                    if len(frames)!=args.samples or case['capture_size']!=[1920,1080] or case['warmup_frames']<args.warmup or \
                        [f['frame'] for f in frames]!=list(range(args.samples)):
                        raise RuntimeError('Wrong profile sample/image identity')
                    metrics=[k for k in frames[0] if k!='frame']
                    for frame in frames:
                        if set(frame)!=set(frames[0]) or any(not isinstance(frame[k],(int,float)) or \
                            not math.isfinite(frame[k]) or frame[k]<0 for k in metrics) or frame['wall_ms']<=0 or frame['draw_calls']<=0:
                            raise RuntimeError('Invalid actual frame counters')
                    record['cases'].append({'name':case['name'],'sample_count':len(frames),
                        'metrics':{k:summary([f[k] for f in frames]) for k in metrics},
                        'gpu_timing_available':any(f['viewport_renderer_gpu_ms']>0 for f in frames)})
                result['profiles'].append(record)
                save(receipt,result)
            if any(checked.digest(root/name)!=h for name,h in hashes.items()):
                raise RuntimeError('Current source changed during profiling')
        result.update(status='PASS',private_copy_removed=True)
    except Exception as error:
        result.update(status='FAIL',failure=str(error))
        raise
    finally:
        for path in output.iterdir():
            if path.is_file() and path!=receipt:
                result['source_hashes'][path.relative_to(root).as_posix()]=checked.digest(path)
        result['finished_at']=checked.stamp()
        save(receipt,result)


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot',type=Path,required=True)
    display=parser.add_mutually_exclusive_group(required=True)
    display.add_argument('--graphics-prefix',type=Path)
    display.add_argument('--native-display',action='store_true')
    parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--samples',type=int,default=180)
    parser.add_argument('--warmup',type=int,default=45)
    validate(parser.parse_args())
