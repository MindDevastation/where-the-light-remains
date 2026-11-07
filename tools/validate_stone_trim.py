#!/usr/bin/env python3
"""Exact-source isolated TRIM-002 import/specimens; does not load gameplay."""
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
    paths=['game/tests/stone_trim_review.gd','tools/generate_stone_trim_maps.py',
        'tools/validate_stone_trim.py','tools/run_graphical.py','tools/linux_graphics_packages.json',
        'game/autoload/settings_manager.gd','docs/production/STONE_TRIM.md',
        'docs/production/stone_trim_regions.json','game/art/materials/m_stone_ornament_trim.tres',
        'game/art/textures/trims/stone_trim_manifest.json',
        'game/worlds/archive/archive_main.tscn','game/worlds/archive/archive_main.gd',
        'game/worlds/archive/wing01_corridor_presentation.tscn',
        'tools/create_archive_kit.py','tools/create_s01_core_pedestal.py',
        'docs/production/modular_archive_kit_v1.json','docs/production/s01_core_pedestal.json',
        'docs/production/ARCHIVE_PRACTICAL_LIGHTING.md']
    for role in ['albedo','normal','orm']:
        path='game/art/textures/trims/t_stone_ornament_trim_'+role+'.png'
        paths.extend([path,path+'.import'])
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
        with tempfile.TemporaryDirectory(prefix='wlr-stone_trim-') as private:
            clean=Path(private)
            for p in paths:
                # Scene/mechanics are read-only authority, never imported by the minimal fixture.
                prefix='authority' if p.startswith('game/worlds/') else ''
                target=clean/prefix/p;target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(root/p,target)
                if digest(target)!=hashes[p]:raise RuntimeError('Private copy mismatch')
            target=clean/'game/tests/stone_trim_regions.json'
            shutil.copyfile(clean/'docs/production/stone_trim_regions.json',target)
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
            run('fresh_map_regeneration',['python3','-B',str(clean/'tools/generate_stone_trim_maps.py'),'--output',str(maps)],90,'STONE_TRIM_MAPS PASS')
            for p in maps.iterdir():
                if digest(p)!=hashes['game/art/textures/trims/'+p.name]:raise RuntimeError('Nondeterministic map: '+p.name)
            result['fresh_regeneration_files_identical']=4
            from PIL import Image
            import numpy as np
            contract=json.loads((clean/'docs/production/stone_trim_regions.json').read_text())
            manifest=json.loads((clean/'game/art/textures/trims/stone_trim_manifest.json').read_text())
            images={role:np.asarray(Image.open(clean/('game/art/textures/trims/t_stone_ornament_trim_'+role+'.png'))) for role in ['albedo','normal','orm']}
            for values in images.values():
                if values.shape!=(2048,2048,3):raise RuntimeError('Not actual2K RGB')
            for region in contract['regions']:
                a,b=region['allocated_rows'];v0,v1=region['active_rows']
                if min(v0-a,b-v1)<64 or (v1-v0)/region['physical_width_m']!=1024:raise RuntimeError('Invalid metric region/guard')
                for values in images.values():
                    if not (np.all(values[a:v0]==values[v0]) and np.all(values[v1:b]==values[v1-1])):raise RuntimeError('Region edge guard mismatch')
                normal=images['normal'][v0:v1,::17].astype(float)/255*2-1
                if np.max(np.abs(np.linalg.norm(normal,axis=2)-1))>.015:raise RuntimeError('Invalid unit tangent normals')
                if np.ptp(normal[:,:,1])<.15:raise RuntimeError('No actual authored profile relief')
            for region in manifest['regions']:
                if min(region['relief_range_m'])<-.005 or max(region['relief_range_m'])>.005:raise RuntimeError('Relief exceeds5mm')
            orm=images['orm']
            if not (np.all(orm[:,:,0]==255) and np.all(orm[:,:,2]==0) and orm[:,:,1].min()/255>.76 and orm[:,:,1].max()/255<.92):raise RuntimeError('Invalid dielectric packed data')
            authority=(clean/'authority/game/worlds/archive/archive_main.tscn').read_text()
            for required in ['ambient_light_energy = 0.22','light_energy = 0.38','rotation_degrees = Vector3(-65, -25, 0)','light_color = Color(0.55, 0.7, 0.9, 1)','position = Vector3(0, 3.6, -22)','omni_range = 9.0']:
                if required not in authority:raise RuntimeError('Scene lighting authority changed: '+required)
            result.update(metric_regions_and_padding_verified=5,texel_density_px_per_m=1024,first_surface_width_m=.06,first_uv_v=[.0475,.0775],native_scope='Current environment/moon and selected cold RoomLight/awake CoreLight subsets; not all scene lights or shipping scenes')
            godot=str(args.godot.resolve())
            run('isolated_clean_import',[godot,'--headless','--path','game','--editor','--import'],90)
            for quality in ['low','medium']:
                run(quality,['python3','-B',str(clean/'tools/run_graphical.py'),'--graphics-prefix',str(args.graphics_prefix.resolve()),
                    '--godot',godot,'--timeout','100','--expect','STONE_TRIM_REVIEW PASS','--','--path','game',
                    '--resolution','960x540','--script','res://tests/stone_trim_review.gd','--',
                    '--review-output='+str(output),'--quality='+quality],120,'STONE_TRIM_REVIEW PASS')
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
