#!/usr/bin/env python3
"""Retrieve a committed art family into an empty independent LFS store and use it.

Supporting game/code is copied from verified current local identities. Only the
manifest's payloads are independently downloaded; no fully hydrated clone claim.
"""
import argparse
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

from session_snapshot import CREDENTIAL


def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream,'sha256').hexdigest()


def stamp():
    return dt.datetime.now(dt.timezone.utc).isoformat()


def safe(raw):
    return CREDENTIAL.sub(b'[REDACTED]',raw).decode(errors='replace')


def write_payload(path,data,expected):
    path.parent.mkdir(parents=True,exist_ok=True)
    fd=os.open(path,os.O_WRONLY|os.O_CREAT|os.O_TRUNC,0o644)
    count=0
    try:
        while count<len(data):
            written=os.write(fd,memoryview(data)[count:count+65536])
            if written<=0:
                raise RuntimeError('No payload write progress')
            count+=written
        os.fsync(fd)
    finally:
        os.close(fd)
    if path.stat().st_size!=len(data) or digest(path)!=expected:
        raise RuntimeError('Retrieved payload readback mismatch')


def validate(args):
    root=Path(__file__).resolve().parents[1]
    output=args.output.resolve()
    if not output.is_relative_to(root/'docs/production/evidence/archive_reconstruction') or output.exists():
        raise ValueError('A new art evidence family is required')
    if not args.branch.startswith(('feature/','work/','epic/')) or not re.fullmatch(r'[a-z0-9_/.-]+',args.branch):
        raise ValueError('A dedicated working branch is required')
    for name in [args.verifier,args.contract]:
        if Path(name).is_absolute() or '..' in Path(name).parts or not (root/name).is_file():
            raise ValueError('Unsafe/missing supporting source path')
    if not re.fullmatch(r'[a-z0-9_]+_smoke',args.test):
        raise ValueError('A named smoke test is required')
    manifest=args.manifest.resolve()
    if not manifest.is_relative_to(root):
        raise ValueError('Manifest must be inside this repository')
    payloads=json.loads(manifest.read_text())['payloads']
    names=set()
    for p in payloads:
        name=p['path']
        if Path(name).is_absolute() or '..' in Path(name).parts or Path(name).suffix not in {'.blend','.glb','.fbx'} or name in names:
            raise ValueError('Invalid/duplicate payload path')
        names.add(name)
        if (root/name).is_symlink() or (root/name).stat().st_size!=p['bytes'] or digest(root/name)!=p['sha256']:
            raise ValueError('Manifest/current payload mismatch')
    blends=[p['path'] for p in payloads if p['path'].endswith('.blend')]
    if len(blends)!=1:
        raise ValueError('Exactly one editable source is required')
    paths=sorted(p.relative_to(root).as_posix() for folder in ['game','tools'] for p in (root/folder).rglob('*')
        if p.is_file() and not p.is_symlink() and not any(part in {'.godot','__pycache__'} for part in p.parts))
    paths=sorted(set(paths+[args.contract,args.verifier,manifest.relative_to(root).as_posix()]+list(names)))
    hashes={p:digest(root/p) for p in paths}
    output.mkdir(parents=True,exist_ok=False)
    result={'status':'RUNNING','started_at':stamp(),'source_hashes':hashes,'commands':[],
        'scope':'Only manifest art payloads independently retrieved; exact local supporting game/code copied cache-free. Reopened source, imported assets, actual smoke and startup; no native/target-GPU acceptance.'}
    receipt=output/'results.json'
    def save():
        receipt.write_text(json.dumps(result,indent=2)+'\n')
    save()
    try:
        with tempfile.TemporaryDirectory(prefix='wlr-lfs-family-') as private:
            scratch=Path(private)
            clone=scratch/'clone'
            store=scratch/'independent-lfs'
            clean=scratch/'source'
            env=dict(os.environ,GIT_TERMINAL_PROMPT='0',GODOT_SILENCE_ROOT_WARNING='1')
            env.pop('GIT_LFS_SKIP_SMUDGE',None)
            def run(name,command,cwd=scratch,input_data=None,marker='',timeout=90,binary=False):
                process=subprocess.run(command,cwd=cwd,env=env,input=input_data,capture_output=True,timeout=timeout)
                record={'name':name,'command':command,'exit_code':process.returncode,'stderr':safe(process.stderr),'utc':stamp()}
                if binary:
                    record.update(stdout_bytes=len(process.stdout),stdout_sha256=hashlib.sha256(process.stdout).hexdigest())
                else:
                    raw=process.stdout+process.stderr
                    log=output/(name+'.log')
                    log.write_bytes(CREDENTIAL.sub(b'[REDACTED]',raw))
                    record['log_sha256']=digest(log)
                result['commands'].append(record)
                save()
                if process.returncode or marker and marker.encode() not in process.stdout:
                    raise RuntimeError('Command failed: '+name)
                if name in {'clean-import','capsule','normal-startup'} and any(w in process.stdout+process.stderr for w in [b'ERROR:',b'SCRIPT ERROR',b'Parse Error',b'WARNING:']):
                    raise RuntimeError('Godot diagnostic: '+name)
                return process.stdout
            run('clone',['git','clone','--no-checkout','--depth','1','--filter=blob:none','--single-branch','--branch',args.branch,
                'https://github.com/MindDevastation/where-the-light-remains.git',str(clone)])
            assert not (clone/'.git/objects/info/alternates').exists(), 'Unexpected object alternates'
            run('lfs-storage',['git','config','--local','lfs.storage',str(store)],clone)
            lfs_env=run('lfs-env',['git','lfs','env'],clone).decode()
            media=next(Path(line.split('=',1)[1]) for line in lfs_env.splitlines() if line.startswith('LocalMediaDir='))
            assert media.resolve()==(store/'objects').resolve() and not any(p.is_file() for p in media.rglob('*'))
            result.update(initial_media_store_empty=True,no_object_alternates=True,independent_media_directory=str(media))
            commit=run('remote-tip',['git','rev-parse','HEAD'],clone).decode().strip()
            result['retrieved_commit']=commit
            for name in paths:
                if name in names:
                    continue
                target=clean/name
                target.parent.mkdir(parents=True,exist_ok=True)
                shutil.copyfile(root/name,target)
                assert digest(target)==hashes[name]
            result['objects']=[]
            for i,p in enumerate(payloads):
                expected=f"version https://git-lfs.github.com/spec/v1\noid sha256:{p['sha256']}\nsize {p['bytes']}\n".encode()
                pointer=run('pointer-'+str(i),['git','show',commit+':'+p['path']],clone,binary=True)
                assert pointer==expected, 'Committed pointer mismatch'
                raw=run('download-'+str(i),['git','lfs','smudge','--',p['path']],clone,input_data=pointer,binary=True)
                assert len(raw)==p['bytes'] and hashlib.sha256(raw).hexdigest()==p['sha256'], 'Downloaded payload mismatch'
                write_payload(clean/p['path'],raw,p['sha256'])
                result['objects'].append(dict(p,committed_pointer=pointer.decode(),retrieved=True))
                save()
            assert not (clean/'game/.godot').exists(), 'Reused import cache'
            run('retrieved-source-reopen',[str(args.blender.resolve()),'--background',str(clean/blends[0]),'--python-exit-code','1',
                '--python',str(clean/args.verifier)],clean,marker=args.blender_marker,timeout=60)
            slots=scratch/'userdata/godot/app_userdata/Where the Light Remains'
            slots.mkdir(parents=True)
            fixture={'save_version':1,'stage_id':'s01_saved_fixture','checkpoint_id':'protected','collected_fragments':[],
                'world_states':{},'milestones':{},'achievement_ids':[],'game_completed':False}
            protected=['savegame.json','savegame.backup.json']
            for name in protected:
                (slots/name).write_text(json.dumps(fixture)+'\n')
            before={name:digest(slots/name) for name in protected}
            env['XDG_DATA_HOME']=str(scratch/'userdata')
            godot=str(args.godot.resolve())
            run('clean-import',[godot,'--headless','--path','game','--editor','--import'],clean)
            run('capsule',[godot,'--headless','--path','game','res://tests/'+args.test+'.tscn'],clean,
                marker=args.test.removesuffix('_smoke').upper()+' PASS',timeout=60)
            run('normal-startup',[godot,'--headless','--path','game','--quit-after','8'],clean,timeout=30)
            after={name:digest(slots/name) for name in protected}
            assert before==after, 'Protected physical save changed'
            result.update(slots_before=before,slots_after=after,other_private_entries=[{'name':p.name,'type':'directory' if p.is_dir() else 'file'}
                for p in slots.iterdir() if p.name not in protected])
            assert all(digest(root/name)==expected for name,expected in hashes.items()), 'Current source changed during retrieval'
        result.update(status='PASS',private_copy_removed=True)
    except Exception as error:
        result.update(status='FAIL',failure=str(error))
        raise
    finally:
        for p in output.iterdir():
            if p.is_file() and p!=receipt:
                result['source_hashes'][p.relative_to(root).as_posix()]=digest(p)
        result['finished_at']=stamp()
        save()
    print('LFS_ASSET_FAMILY PASS:',len(payloads),'independently retrieved and used')


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    for name in ['manifest','output','godot','blender']:
        parser.add_argument('--'+name,type=Path,required=True)
    for name in ['branch','verifier','contract','test','blender-marker']:
        parser.add_argument('--'+name,required=True)
    validate(parser.parse_args())
