#!/usr/bin/env python3
"""Measure a constrained three-orbit proposal; author/import no production mesh."""
import argparse
import datetime as dt
import hashlib
import json
import math
import os
from pathlib import Path
import subprocess
import tempfile
import numpy as np


def main(args):
    root=Path(__file__).resolve().parents[1];out=args.output.resolve()
    if out.exists() or not out.is_relative_to(root/'docs/production/evidence/archive_reconstruction'):raise ValueError('New bounded evidence folder required')
    contract_path=root/'docs/production/core_orbits_production_brief.json';c=json.loads(contract_path.read_text())
    audit_path=root/'docs/production/evidence/archive_reconstruction/core-hero-audit-20261007/interfaces.json';audit=json.loads(audit_path.read_text())
    def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
    for path,value in c['inputs'].items():
        if sha(root/path)!=value:raise RuntimeError('Proposal authority changed: '+path)
    out.mkdir(parents=True)
    rotations=[o['euler_degrees'] for o in c['orbits']]
    # Clear variable names avoid dependence on string-length bookkeeping.
    source='extends SceneTree\nfunc _initialize():\n'
    for i,degrees in enumerate(rotations):
        source+=f'    var b{i}:=Basis.from_euler(Vector3('+','.join(str(n) for n in degrees)+')*PI/180)\n'
        source+=f'    print(JSON.stringify({{"columns":[[b{i}.x.x,b{i}.x.y,b{i}.x.z],[b{i}.y.x,b{i}.y.y,b{i}.y.z],[b{i}.z.x,b{i}.z.y,b{i}.z.z]]}}))\n'
    source+='    quit()\n'
    with tempfile.TemporaryDirectory(prefix='wlr-core-brief-') as folder:
        private=Path(folder);(private/'project.godot').write_text('config_version=5\n[application]\nconfig/name="WLR Private Metric Probe"\n');(private/'basis.gd').write_text(source)
        env=dict(os.environ,XDG_DATA_HOME=str(private/'userdata'),GODOT_SILENCE_ROOT_WARNING='1',PYTHONDONTWRITEBYTECODE='1')
        p=subprocess.run([str(args.godot.resolve()),'--headless','--path',str(private),'--script','res://basis.gd'],env=env,capture_output=True,timeout=30)
        raw=p.stdout+p.stderr;(out/'basis.log').write_bytes(raw);(out/'basis_probe.gd.txt').write_text(source)
        if p.returncode or any(word in raw for word in [b'ERROR:',b'WARNING:',b'SCRIPT ERROR']):raise RuntimeError('Native metric basis probe failed')
        bases=[np.array(json.loads(line)['columns']).T for line in p.stdout.decode().splitlines() if line.startswith('{')]
        if len(bases)!=3:raise RuntimeError('Three native bases required')
    pivot=np.array(c['pivot_world_m']);n=c['arc_samples'];tube=c['tube_support_radius_m']
    lo=np.min([r['world_vertex_bounds']['min'] for r in audit['rings']],axis=0);hi=np.max([r['world_vertex_bounds']['max'] for r in audit['rings']],axis=0)
    shapes=[];measurements=[];clearance={r['path'].split('/')[-1]:math.inf for r in audit['controls']}
    for orbit,basis in zip(c['orbits'],bases):
        radius=orbit['radius_m'];theta=np.arange(n)*2*np.pi/n
        vertices=np.stack((radius*np.cos(theta),np.zeros(n),radius*np.sin(theta)),axis=1)@basis.T+pivot
        minimum=vertices.min(axis=0)-tube-radius*math.pi/n;maximum=vertices.max(axis=0)+tube+radius*math.pi/n
        if not np.all(minimum>=lo) or not np.all(maximum<=hi):raise RuntimeError('Orbit exceeds accepted envelope')
        radial=np.linalg.norm(vertices[:,[0,2]],axis=1)
        gaps={}
        for target in audit['controls']:
            centre=np.array(target['position']);half=np.array(target['target_box'])*.5
            rmin=np.linalg.norm(np.maximum(np.abs(centre[[0,2]])-half[[0,2]],0));rmax=np.linalg.norm(np.abs(centre[[0,2]])+half[[0,2]])
            dr=np.maximum(np.maximum(rmin-radial,radial-rmax),0);dy=np.maximum(np.abs(vertices[:,1]-centre[1])-half[1],0)
            value=float(np.sqrt(dr*dr+dy*dy).min())-tube-radius*math.pi/n
            name=target['path'].split('/')[-1];gaps[name]=value;clearance[name]=min(clearance[name],value)
            if value<c['control_clearance_floor_m']:raise RuntimeError('Continuous yaw bound too close to '+name)
        # The maximum-Y centreline point defines an upper bridge anchor.
        anchor=vertices[np.argmax(vertices[:,1])]
        measurements.append({'id':orbit['id'],'native_basis_columns':basis.T.tolist(),'conservative_world_bounds':{'min':minimum.tolist(),'max':maximum.tolist()},'continuous_yaw_control_clearance_lower_bound_m':gaps,'upper_bridge_anchor_world_m':anchor.tolist()})
        shapes.append(vertices)
    if c['mounts']['base_collar_outer_radius_m']>.2 or c['mounts']['spindle_world_y_m'][0]<1.39:raise RuntimeError('Accepted axle interface changed')
    # Conservative collar/spindle and upper-bridge clearances use cylinder/slab bounds.
    mount_gaps={}
    for target in audit['controls']:
        center=np.array(target['position']);half=np.array(target['target_box'])*.5
        radial_min=float(np.linalg.norm(np.maximum(np.abs(center[[0,2]])-half[[0,2]],0)))
        gap=min(radial_min-.19,c['mounts']['upper_bridge_min_world_y_m']-(center[1]+half[1]))
        mount_gaps[target['path'].split('/')[-1]]=float(gap)
        if gap<.10:raise RuntimeError('Mount control bound too close')
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    from matplotlib.patches import Rectangle
    fig,axes=plt.subplots(1,3,figsize=(13,5),layout='constrained');colours=['#af883e','#657488','#d4b06d']
    for ax,dimensions,title in zip(axes,[(0,1),(0,2),(2,1)],['Спереди X/Y','Сверху X/Z','Сбоку Z/Y']):
        a,b=dimensions;ax.set_aspect('equal');ax.set_title(title);ax.add_patch(Rectangle((lo[a],lo[b]),hi[a]-lo[a],hi[b]-lo[b],fill=False,linestyle='--',edgecolor='#546679'))
        for vertices,colour,orbit in zip(shapes,colours,c['orbits']):ax.plot(vertices[:,a],vertices[:,b],color=colour,linewidth=2,label=orbit['id'])
        for target in audit['controls']:
            center=np.array(target['position']);half=np.array(target['target_box'])*.5;ax.add_patch(Rectangle((center[a]-half[a],center[b]-half[b]),2*half[a],2*half[b],fill=False,edgecolor='#ab5262'));ax.text(center[a],center[b],target['path'].split('/')[-1],fontsize=7)
        ax.scatter(pivot[a],pivot[b],color='#17212b',s=15);ax.set_xlabel('м');ax.set_ylabel('м');ax.autoscale_view();ax.grid(alpha=.15)
    fig.suptitle('Три орбиты: измеренный brief, не production-модель / dashed: принятый envelope',fontsize=12)
    fig.savefig(out/'core_orbits_metric.png',dpi=140);fig.savefig(out/'core_orbits_metric.svg');plt.close(fig)
    sources={str(p.relative_to(root)):sha(p) for p in [contract_path,Path(__file__),audit_path]}
    result={'status':'PASS_METRIC_BRIEF_ONLY','utc':dt.datetime.now(dt.timezone.utc).isoformat(),'source_hashes':sources,'native_basis_probe':'Private headless Godot actual Basis.from_euler default YXZ;no game/autoload/save loaded','accepted_envelope_world_m':{'min':lo.tolist(),'max':hi.tolist()},'measurements':measurements,'continuous_yaw_clearance_lower_bound_m':clearance,'mount_clearance_lower_bound_m':mount_gaps,'bound_method':'Full-yaw target AABB annular enclosure;8192 arc samples minus radius*pi/N Lipschitz allowance and20mm section support. Upper bridges conservatively stay above1.78m;centre collar radius<=.19m.','rendered_geometry':'Metric line projections only;not production mesh/native shipping frames','new_binary_families':0,'shipping_changes':0,'inventory_acceptance_added':0,'excluded_scope':'No actual E-ray occlusion, GLB/material/tangent/Blender/LFS/style/performance acceptance','owned_private_fixture_removed':True}
    result['evidence_hashes']={p.name:sha(p) for p in out.iterdir() if p.is_file()};(out/'results.json').write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps({'status':result['status'],'clearance_lower_bounds_m':clearance,'mount_clearance_lower_bounds_m':mount_gaps,'new_binary_families':0}))


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--godot',type=Path,required=True);p.add_argument('--output',type=Path,required=True);main(p.parse_args())
