#!/usr/bin/env python3
"""Exact-source MAT-002 native material pairs and isolated PBR specimens."""
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
        raise ValueError('A new polished brass evidence folder is required')
    paths = sorted(p.relative_to(root).as_posix() for folder in ['game', 'tools'] for p in (root/folder).rglob('*')
                   if p.is_file() and not any(part in {'.godot', '__pycache__'} for part in p.parts))
    hashes = {p: receipts.audio.digest(root/p) for p in paths}
    output.mkdir(parents=True)
    result = {'status':'RUNNING', 'scope':'Software Forward+ readonly native shipping pairs and isolated specimens; visual judgment separate; not target GPU/full hero/VS1',
              'source_hashes':hashes, 'started_at':receipts.audio.stamp(), 'records':[], 'pairs':[]}
    receipt = output/'results.json'
    receipts.write_receipt(receipt, result)
    try:
        with tempfile.TemporaryDirectory(prefix='wlr-polished-native-') as private:
            clean = Path(private)
            for name in paths:
                dest = clean/name; dest.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(root/name, dest)
                if receipts.audio.digest(dest) != hashes[name]:
                    raise RuntimeError('Clean source copy mismatch')
            data = clean/'userdata'
            slots = data/'godot/app_userdata/Where the Light Remains'; slots.mkdir(parents=True)
            for name in ['savegame.json', 'savegame.backup.json']:
                (slots/name).write_text('{"protected_fixture":true}\n')
            before = {p.name:receipts.audio.digest(p) for p in slots.iterdir()}
            env = dict(os.environ, GODOT_SILENCE_ROOT_WARNING='1', XDG_DATA_HOME=str(data), PYTHONDONTWRITEBYTECODE='1')
            def run(name, command, timeout, marker=''):
                p = subprocess.run(command, cwd=clean, env=env, stdout=subprocess.PIPE,
                                   stderr=subprocess.STDOUT, timeout=timeout)
                log = output/(name+'.log'); log.write_bytes(p.stdout)
                after = {p.name:receipts.audio.digest(p) for p in slots.iterdir() if p.is_file()}
                ok = p.returncode==0 and before==after and (not marker or marker.encode() in p.stdout) and \
                     not any(x in p.stdout for x in [b'ERROR:', b'SCRIPT ERROR', b'Parse Error', b'WARNING:'])
                result['records'].append({'name':name, 'command':command, 'passed':ok, 'exit_code':p.returncode,
                    'slots_before':before, 'slots_after':after, 'log_sha256':receipts.audio.digest(log)})
                receipts.write_receipt(receipt,result); print(json.dumps({'name':name,'passed':ok}),flush=True)
                if not ok: raise RuntimeError('Native validation failed: '+name)
            maps = clean/'regenerated'
            run('fresh_map_regeneration', ['python3', '-B', str(clean/'tools/generate_polished_brass_maps.py'), '--output', str(maps)], 30, 'POLISHED_BRASS_MAPS PASS')
            for path in maps.iterdir():
                if receipts.audio.digest(path) != hashes['game/art/textures/material_library/'+path.name]:
                    raise RuntimeError('Nondeterministic fresh map generation: '+path.name)
            result['fresh_map_files_identical'] = 4
            godot = str(args.godot.resolve())
            run('clean_import', [godot,'--headless','--path','game','--editor','--import'],120)
            run('startup', [godot,'--headless','--path','game','--quit-after','8'],30)
            for quality in ['low','medium']:
                run(quality, ['python3','-B',str(clean/'tools/run_graphical.py'), '--graphics-prefix',str(args.graphics_prefix.resolve()),
                    '--godot',godot,'--timeout','160','--expect','ARCHIVE_POLISHED_BRASS_REVIEW CAPTURED','--','--path','game',
                    '--resolution','960x540','res://tests/archive_polished_brass_review.tscn','--',
                    '--review-output='+str(output),'--quality='+quality],180,'ARCHIVE_POLISHED_BRASS_REVIEW CAPTURED')
                captures = json.loads((output/('captures_'+quality+'.json')).read_text())
                if captures['renderer']!='forward_plus' or len(captures['captures'])!=(8 if quality=='low' else 12):
                    raise RuntimeError('Wrong native renderer/capture count')
                for view in ['sleeping','oblique','panel','awakened']:
                    pair = [next(x for x in captures['captures'] if x.get('view')==view and x['polished']==on) for on in [True,False]]
                    for key in ['camera_transform','outer_transform','inner_transform','actual_ray_target','active_overlays']:
                        if pair[0][key]!=pair[1][key]: raise RuntimeError('Pair changed '+key)
                    if any(not x['shipping_lights'] or x['decorative_effects'] for x in pair):
                        raise RuntimeError('Unexpected shipping lighting/effects')
                    a = np.asarray(Image.open(output/pair[0]['file']).convert('RGB')).astype(np.int16)
                    b = np.asarray(Image.open(output/pair[1]['file']).convert('RGB')).astype(np.int16)
                    delta = np.max(np.abs(a-b),axis=2); changed = int(np.count_nonzero(delta))
                    result['pairs'].append({'view':view,'quality':quality,'changed_pixels':changed,
                        'max_channel_delta':int(delta.max()), 'meaning':'Same-frame material difference proves actual rendering; art inspection separate.'})
                    if not changed: raise RuntimeError('No rendered polished material change')
            if any(receipts.audio.digest(root/p)!=h for p,h in hashes.items()):
                raise RuntimeError('Source changed during review')
        result.update(status='PASS',private_copy_removed=True)
    except Exception as e:
        result.update(status='FAIL',failure=str(e));raise
    finally:
        for path in output.iterdir():
            if path.is_file() and path!=receipt:
                result['source_hashes'][path.relative_to(root).as_posix()]=receipts.audio.digest(path)
        result['finished_at']=receipts.audio.stamp();receipts.write_receipt(receipt,result)


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--godot',type=Path,required=True);p.add_argument('--graphics-prefix',type=Path,required=True)
    p.add_argument('--output',type=Path,required=True)
    validate(p.parse_args())
