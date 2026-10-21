#!/usr/bin/env python3
"""Hash-bound native paired particle reviews via the accepted graphical runner."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
from PIL import Image
import numpy as np
import audio_audition as receipts

def validate(args):
    root = Path(__file__).resolve().parents[1]
    output = args.output.resolve()
    if not output.is_relative_to(root/'docs/production/evidence/archive_reconstruction') or output.exists():
        raise ValueError('A new dust review evidence folder is required')
    paths = sorted(p.relative_to(root).as_posix() for folder in ['game','tools'] for p in (root/folder).rglob('*')
        if p.is_file() and not any(part in {'.godot','__pycache__'} for part in p.parts))
    hashes = {p: receipts.audio.digest(root/p) for p in paths}
    output.mkdir(parents=True)
    result = {'status':'RUNNING','scope':'Software Forward+ particles and readonly native views; visual judgment separate; not target GPU/full style/VS1',
        'source_hashes':hashes,'started_at':receipts.audio.stamp(),'records':[],'pairs':[]}
    receipt = output/'results.json'
    receipts.write_receipt(receipt,result)
    try:
        with tempfile.TemporaryDirectory(prefix='wlr-dust-native-') as private:
            clean = Path(private)
            for name in paths:
                dest=clean/name;dest.parent.mkdir(parents=True,exist_ok=True)
                shutil.copyfile(root/name,dest)
                if receipts.audio.digest(dest)!=hashes[name]: raise RuntimeError('Clean copy mismatch')
            data=clean/'userdata'
            slots=data/'godot/app_userdata/Where the Light Remains';slots.mkdir(parents=True)
            for name in ['savegame.json','savegame.backup.json']: (slots/name).write_text('{"protected_fixture":true}\n')
            before={p.name:receipts.audio.digest(p) for p in slots.iterdir()}
            env=dict(os.environ,GODOT_SILENCE_ROOT_WARNING='1',XDG_DATA_HOME=str(data),PYTHONDONTWRITEBYTECODE='1')
            def run(name,command,timeout,marker=''):
                p=subprocess.run(command,cwd=clean,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=timeout)
                log=output/(name+'.log');log.write_bytes(p.stdout)
                after={p.name:receipts.audio.digest(p) for p in slots.iterdir() if p.is_file()}
                ok=p.returncode==0 and before==after and (not marker or marker.encode() in p.stdout) and not any(x in p.stdout for x in [b'ERROR:',b'SCRIPT ERROR',b'Parse Error',b'WARNING:'])
                result['records'].append({'name':name,'command':command,'passed':ok,'exit_code':p.returncode,
                    'slots_before':before,'slots_after':after,'log_sha256':receipts.audio.digest(log)})
                receipts.write_receipt(receipt,result);print(json.dumps({'name':name,'passed':ok}),flush=True)
                if not ok: raise RuntimeError('Native validation failed: '+name)
            godot=str(args.godot.resolve())
            run('clean_import',[godot,'--headless','--path','game','--editor','--import'],120)
            run('startup',[godot,'--headless','--path','game','--quit-after','90'],60)
            for quality in ['low','medium']:
                run(quality,['python3','-B',str(clean/'tools/run_graphical.py'),'--graphics-prefix',str(args.graphics_prefix.resolve()),
                    '--godot',godot,'--timeout','160','--expect','ARCHIVE_DUST_MOTES_REVIEW CAPTURED','--','--path','game',
                    '--resolution','960x540','res://tests/archive_dust_motes_review.tscn','--','--review-output='+str(output),'--quality='+quality],180,'ARCHIVE_DUST_MOTES_REVIEW CAPTURED')
                captures=json.loads((output/('captures_'+quality+'.json')).read_text())
                if captures['renderer']!='forward_plus' or len(captures['captures'])!=10: raise RuntimeError('Wrong native renderer/capture count')
                for view in ['s00_closed','s01_asleep','s01_awakened','s02_cold','s02_warm']:
                    a=np.asarray(Image.open(output/(view+'_on_'+quality+'.png')).convert('RGB')).astype(np.int16)
                    b=np.asarray(Image.open(output/(view+'_off_'+quality+'.png')).convert('RGB')).astype(np.int16)
                    delta=np.max(np.abs(a-b),axis=2)
                    changed=int(np.count_nonzero(delta))
                    record={'view':view,'quality':quality,'changed_pixels':changed,'max_channel_delta':int(delta.max()),
                        'meaning':'Paused on/off image difference proves actual rendering only; individual art inspection separate.'}
                    result['pairs'].append(record)
                    if view=='s00_closed' and changed: raise RuntimeError('S00 leaked decoration or pair moved')
                    if view!='s00_closed' and not changed: raise RuntimeError('No native particle pixels in '+view+'/'+quality)
                    if changed > a.shape[0]*a.shape[1]*.005: raise RuntimeError('Decoration obscures more than0.5% of view')
            if any(receipts.audio.digest(root/p)!=h for p,h in hashes.items()): raise RuntimeError('Source changed during review')
        result.update(status='PASS',private_copy_removed=True)
    except Exception as e:
        result.update(status='FAIL',failure=str(e));raise
    finally:
        for p in output.iterdir():
            if p.is_file() and p!=receipt: result['source_hashes'][p.relative_to(root).as_posix()]=receipts.audio.digest(p)
        result['finished_at']=receipts.audio.stamp();receipts.write_receipt(receipt,result)

if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--godot',type=Path,required=True);p.add_argument('--graphics-prefix',type=Path,required=True)
    p.add_argument('--output',type=Path,required=True)
    validate(p.parse_args())
