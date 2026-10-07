#!/usr/bin/env python3
"""Original metric2K stone trim profiles; no accepted map/reference pixels read."""
import argparse
import hashlib
import io
import json
import os
from pathlib import Path
import numpy as np
from PIL import Image


def generate(output):
    root=Path(__file__).resolve().parents[1]
    contract_path=root/'docs/production/stone_trim_regions.json'
    contract=json.loads(contract_path.read_text());size=contract['resolution'];density=contract['texel_density_px_per_m']
    output.mkdir(parents=True,exist_ok=True)
    maps={name:np.zeros((size,size,3),dtype=np.float64) for name in ['albedo','normal','orm']}
    u=(np.arange(size)+.5)/size
    # Original continuous periodic grain; controls remain editable in this recipe.
    stone_grain=.6*np.sin(2*np.pi*(u*137+.13*np.sin(2*np.pi*u*3)))+.4*np.sin(2*np.pi*u*251)
    records=[]
    for index,region in enumerate(contract['regions']):
        start,end=region['active_rows'];height=end-start
        v=(np.arange(height)+.5)/height;vv=v[:,None];uu=u[None,:]
        width=height/density
        def groove(center,radius,depth):return -depth*np.exp(-((vv-center)/radius)**2)
        edge=np.sin(np.pi*vv)**2
        relief=np.zeros((height,size));relief+=.00004*np.sin(2*np.pi*(uu*67+vv*29))*edge
        line_stain=np.zeros_like(relief)
        if index==0:
            # Twin chisel channels in the existing six-centimetre fillet.
            relief+=groove(.24,.075,.0015)+groove(.76,.075,.0015)
            line_stain+=.025*(np.exp(-((vv-.24)/.075)**2)+np.exp(-((vv-.76)/.075)**2))
        elif index==1:
            # Edge rails, rounded carved bead row; ordinary craft, no symbols.
            bead_u=np.cos(2*np.pi*uu*16)
            relief+=groove(.14,.025,.003)+groove(.86,.025,.003)
            relief+=.0035*np.exp(-((vv-.5)/.19)**2)*np.maximum(bead_u,0)**2
            line_stain+=.02*(np.exp(-((vv-.14)/.025)**2)+np.exp(-((vv-.86)/.025)**2))
        elif index==2:
            # Eight0.25m plinth blocks per2m; four-millimetre carved joints.
            joint=np.exp(-((np.sin(np.pi*uu*8))/.075)**2)
            relief-=.004*joint*edge
            relief+=groove(.17,.035,.0018)+groove(.83,.035,.0018)
            line_stain+=.036*joint*edge
        elif index==3:
            # Broad framed border panels; .5m courses, restrained linear insets.
            joint=np.exp(-((np.sin(np.pi*uu*4))/.055)**2)
            relief-=.004*joint*edge
            relief+=groove(.16,.024,.0024)+groove(.84,.024,.0024)
            relief+=.0018*(np.cos(2*np.pi*vv)+1)*.5*edge
            line_stain+=.03*joint*edge
        else:
            # Floor-edge return: bevel-like rounded stone profile and two joints.
            relief+=.003*np.sin(np.pi*vv)**2
            relief+=groove(.18,.02,.002)+groove(.82,.02,.002)
            joint=np.exp(-((np.sin(np.pi*uu*2))/.035)**2)
            relief-=.003*joint*edge;line_stain+=.022*joint*edge
        grain=.0035*stone_grain[None,:]+.0025*np.sin(2*np.pi*(uu*83+vv*43))
        color=np.array([.67,.625,.535])+grain[:,:,None]-line_stain[:,:,None]
        rough=.835+.018*np.sin(2*np.pi*(uu*71+vv*37))+.03*np.clip(-relief/.004,0,1)
        dx=(np.roll(relief,-1,axis=1)-np.roll(relief,1,axis=1))*density*.5
        dy=np.gradient(relief,1/density,axis=0)
        normals=np.stack((-dx,dy,np.ones_like(relief)),axis=2);normals/=np.linalg.norm(normals,axis=2,keepdims=True)
        arrays={'albedo':color,'normal':normals*.5+.5,'orm':np.stack((np.ones_like(rough),rough,np.zeros_like(rough)),axis=2)}
        allocated_start,allocated_end=region['allocated_rows']
        for name,array in arrays.items():
            maps[name][allocated_start:allocated_end]=np.pad(array,((start-allocated_start,allocated_end-end),(0,0),(0,0)),mode='edge')
        records.append(dict(region,relief_range_m=[float(relief.min()),float(relief.max())],roughness_range=[float(rough.min()),float(rough.max())],authored_profile=['twin_chisel_channels','rails_and_rounded_beads','plinth_block_joints','framed_border_courses','rounded_floor_return'][index],physical_u_repeat_m=2.0))
    manifest={'version':1,'inventory':'TRIM-002','source':'tools/generate_stone_trim_maps.py','contract':'docs/production/stone_trim_regions.json','contract_sha256':hashlib.sha256(contract_path.read_bytes()).hexdigest(),'resolution':size,'texel_density_px_per_m':density,'u_period_m':2.0,'provenance':'Original editable metric relief/profile and periodic fields; no third-party/reference pixels or accepted source overwritten.','packing':contract['packing'],'regions':records,'maps':[]}
    for name,array in maps.items():
        pixels=np.rint(np.clip(array,0,1)*255).astype(np.uint8);encoded=io.BytesIO();Image.fromarray(pixels).save(encoded,format='PNG',optimize=True)
        data=encoded.getvalue();path=output/f't_stone_ornament_trim_{name}.png';temp=path.with_suffix('.png.tmp')
        with temp.open('wb') as stream:stream.write(data);stream.flush();os.fsync(stream.fileno())
        temp.replace(path)
        values=pixels.astype(float);wrap=float(np.abs(values[:,0]-values[:,-1]).mean());adjacent=float(np.abs(np.diff(values,axis=1)).mean())
        if wrap>max(2,adjacent*2.5):raise RuntimeError('Nonperiodic lengthwise seam: '+name)
        manifest['maps'].append({'role':name,'file':path.name,'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest(),'u_wrap_mean_8bit':wrap,'u_adjacent_mean_8bit':adjacent})
    (output/'stone_trim_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print('STONE_TRIM_MAPS PASS:3 original2048 metric trim maps;5 carved regions')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--output',type=Path,default=Path(__file__).resolve().parents[1]/'game/art/textures/trims')
    generate(p.parse_args().output)
