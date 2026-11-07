#!/usr/bin/env python3
"""Original periodic flax weave; preserves accepted shared woven-textile maps."""
import argparse
import hashlib
import io
import json
import os
from pathlib import Path
import numpy as np
from PIL import Image
from generate_material_maps import SIZE, noise, normals


def generate(output):
    output.mkdir(parents=True, exist_ok=True)
    u,v=np.meshgrid(np.arange(SIZE)/SIZE,np.arange(SIZE)/SIZE)
    warp_variation,weft_variation,grain=noise(9,231),noise(11,232),noise(150,233)
    warp=.5+.5*np.cos(2*np.pi*(u*64+.06*warp_variation))
    weft=.5+.5*np.cos(2*np.pi*(v*64+.06*weft_variation))
    crossing=.5+.5*np.sin(2*np.pi*u*32)*np.sin(2*np.pi*v*32)
    weave=warp**3*crossing+weft**3*(1-crossing)
    slub=.4*warp_variation+.4*weft_variation
    tone=.025*(weave-.35)+.012*slub+.005*grain
    color=np.array([.72,.69,.60])+tone[:,:,None]
    roughness=.89+.025*(weave-.35)+.014*grain
    height=.000060*weave+.000020*slub+.000009*grain
    arrays={'albedo':color,'normal':normals(height),
            'orm':np.stack((np.ones_like(roughness),roughness,np.zeros_like(roughness)),axis=2)}
    manifest={'source':'tools/generate_linen_maps.py','helper':'tools/generate_material_maps.py',
        'resolution':SIZE,'provenance':'Original analytic crossing/seeded uneven-thread flax weave; no copied textile/concept pixels.',
        'packing':'R=1 reserved AO; G=roughness; B=0 metallic; +Y tangent normals',
        'roughness_range':[float(roughness.min()),float(roughness.max())],'maps':[]}
    for role,array in arrays.items():
        pixels=np.rint(np.clip(array,0,1)*255).astype(np.uint8)
        encoded=io.BytesIO();Image.fromarray(pixels).save(encoded,format='PNG',optimize=True)
        payload=encoded.getvalue();path=output/('t_linen_'+role+'.png');temp=path.with_suffix('.png.tmp')
        with temp.open('wb') as stream:
            stream.write(payload);stream.flush();os.fsync(stream.fileno())
        temp.replace(path);values=pixels.astype(float)
        wrap=float((np.abs(values[:,0]-values[:,-1]).mean()+np.abs(values[0]-values[-1]).mean())/2)
        adjacent=float((np.abs(np.diff(values,axis=0)).mean()+np.abs(np.diff(values,axis=1)).mean())/2)
        if wrap>max(2,adjacent*2.5):raise RuntimeError('Tile discontinuity: '+role)
        manifest['maps'].append({'role':role,'file':path.name,'sha256':hashlib.sha256(payload).hexdigest(),
            'bytes':len(payload),'wrap_mean_8bit':round(wrap,4),'adjacent_mean_8bit':round(adjacent,4),
            'mean_rgb_8bit':[float(x) for x in values.mean(axis=(0,1))]})
    (output/'linen_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print('LINEN_MAPS PASS:',len(manifest['maps']),'distinct original periodic weave maps')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--output',type=Path,default=Path(__file__).resolve().parents[1]/'game/art/textures/material_library')
    generate(p.parse_args().output)
