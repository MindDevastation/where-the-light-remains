#!/usr/bin/env python3
"""Exact-source isolated MAT-005 import/specimens; does not load gameplay."""
import argparse
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


def digest(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()


def validate(args):
    root=Path(__file__).resolve().parents[1];output=args.output.resolve()
    if output.exists() or not output.is_relative_to(root/'docs/production/evidence/archive_reconstruction'):
        raise ValueError('New bounded evidence folder required')
    paths=['game/tests/cool_dark_stone_review.gd','tools/generate_cool_dark_stone_maps.py',
        'tools/generate_material_maps.py','tools/validate_cool_dark_stone.py','tools/run_graphical.py',
        'tools/linux_graphics_packages.json','game/autoload/settings_manager.gd',
        'docs/production/COOL_DARK_STONE.md']
    for family in ['cool_dark_stone','observatory_stone']:
        paths.append('game/art/materials/m_'+family+'.tres')
        for role in ['albedo','normal','orm']:
            name='game/art/textures/material_library/t_'+family+'_'+role+'.png'
            paths.extend([name,name+'.import'])
    paths.append('game/art/textures/material_library/cool_dark_stone_manifest.json')
    hashes={p:digest(root/p) for p in paths}
    output.mkdir(parents=True)
    result={'status':'RUNNING','started_at':dt.datetime.now(dt.timezone.utc).isoformat(),
        'scope':'Unbound isolated material specimens; no gameplay, shipping assignment, fresh old-art/GLB test, target GPU or full VS1 acceptance',
        'source_hashes':hashes,'records':[],'captures':[]}
    receipt=output/'results.json'
    def write():receipt.write_text(json.dumps(result,indent=2)+'\n')
    write()
    try:
        # Existing runtime source changes are not allowed in this unbound scope.
        changed=subprocess.check_output(['git','diff','--name-only','HEAD','--','game'],cwd=root,text=True).splitlines()
        if changed:raise RuntimeError('Existing shipping files changed: '+str(changed))
        with tempfile.TemporaryDirectory(prefix='wlr-cool-stone-') as private:
            clean=Path(private)
            for p in paths:
                target=clean/p;target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(root/p,target)
                if digest(target)!=hashes[p]:raise RuntimeError('Private copy mismatch')
            project='config_version=5\n[application]\nconfig/name="Where the Light Remains"\n[display]\nwindow/size/viewport_width=960\nwindow/size/viewport_height=540\n[rendering]\nrenderer/rendering_method="forward_plus"\ntextures/default_filters/use_nearest_mipmap_filter=false\n'
            (clean/'game/project.godot').write_text(project)
            result['private_fixture_project_sha256']=hashlib.sha256(project.encode()).hexdigest()
            data=clean/'userdata';slots=data/'godot/app_userdata/Where the Light Remains';slots.mkdir(parents=True)
            for name in ['savegame.json','savegame.backup.json']:(slots/name).write_text('{"protected_fixture":true}\n')
            before={p.name:digest(p) for p in slots.iterdir()}
            env=dict(os.environ,XDG_DATA_HOME=str(data),GODOT_SILENCE_ROOT_WARNING='1',PYTHONDONTWRITEBYTECODE='1')
            def run(name,command,timeout,marker=''):
                p=subprocess.run(command,cwd=clean,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=timeout)
                log=output/(name+'.log');log.write_bytes(p.stdout)
                after={p.name:digest(p) for p in slots.iterdir() if p.is_file()}
                ok=p.returncode==0 and before==after and (not marker or marker.encode() in p.stdout) and not any(x in p.stdout for x in [b'ERROR:',b'SCRIPT ERROR',b'Parse Error',b'WARNING:'])
                result['records'].append({'name':name,'command':command,'passed':ok,'exit_code':p.returncode,
                    'slots_before':before,'slots_after':after,'log_sha256':digest(log)})
                write();print(json.dumps({'name':name,'passed':ok}),flush=True)
                if not ok:raise RuntimeError('Isolated validation failed: '+name)
            maps=clean/'regenerated'
            run('fresh_map_regeneration',['python3','-B',str(clean/'tools/generate_cool_dark_stone_maps.py'),'--output',str(maps)],30,'COOL_DARK_STONE_MAPS PASS')
            for p in maps.iterdir():
                if digest(p)!=hashes['game/art/textures/material_library/'+p.name]:raise RuntimeError('Nondeterministic map: '+p.name)
            result['fresh_regeneration_files_identical']=4
            godot=str(args.godot.resolve())
            run('isolated_clean_import',[godot,'--headless','--path','game','--editor','--import'],90)
            for quality in ['low','medium']:
                run(quality,['python3','-B',str(clean/'tools/run_graphical.py'),'--graphics-prefix',str(args.graphics_prefix.resolve()),
                    '--godot',godot,'--timeout','100','--expect','COOL_DARK_STONE_REVIEW PASS','--','--path','game',
                    '--resolution','960x540','--script','res://tests/cool_dark_stone_review.gd','--',
                    '--review-output='+str(output),'--quality='+quality],120,'COOL_DARK_STONE_REVIEW PASS')
                capture=json.loads((output/('captures_'+quality+'.json')).read_text())
                if capture['renderer']!='forward_plus' or len(capture['captures'])!=4:raise RuntimeError('Wrong renderer/captures')
                for item in capture['captures']:
                    if item['shipping_assignment'] or item['render_scale']!=(.75 if quality=='low' else 1.0):raise RuntimeError('Wrong specimen profile')
                result['captures'].append(capture)
            if any(digest(root/p)!=h for p,h in hashes.items()):raise RuntimeError('Source changed during review')
        result.update(status='PASS',private_copy_removed=True,shipping_assignments_added=0,new_lfs_payloads=0)
    except Exception as e:
        result.update(status='FAIL',failure=str(e));raise
    finally:
        for p in output.iterdir():
            if p.is_file() and p!=receipt:result['source_hashes'][p.relative_to(root).as_posix()]=digest(p)
        result['finished_at']=dt.datetime.now(dt.timezone.utc).isoformat();write()


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--godot',type=Path,required=True);p.add_argument('--graphics-prefix',type=Path,required=True)
    p.add_argument('--output',type=Path,required=True)
    validate(p.parse_args())
