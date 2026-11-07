#!/usr/bin/env python3
"""Original periodic MAT-002 maps; extends, never regenerates, accepted families."""
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
    output.mkdir(parents=True,exist_ok=True)
    u,v=np.meshgrid(np.arange(SIZE)/SIZE,np.arange(SIZE)/SIZE)
    polish,grain=noise(6,211),noise(150,212)
    brush=np.cos(2*np.pi*(u*180+.08*np.sin(2*np.pi*v)))
    scratches=np.maximum(brush,0)**20
    color=np.array([.70,.53,.28])+(polish*.008+grain*.006-scratches*.008)[:,:,None]
    roughness=.235+.016*polish+.008*grain+.025*scratches
    metallic=np.ones_like(roughness)*.98
    height=.000013*grain-.000010*scratches
    arrays={'albedo':color,'normal':normals(height),
        'orm':np.stack((np.ones_like(roughness),roughness,metallic),axis=2)}
    manifest={'source':'tools/generate_polished_brass_maps.py','helper':'tools/generate_material_maps.py',
        'resolution':SIZE,'provenance':'Original analytic/seeded periodic maps; no concept pixels or third-party textures.',
        'packing':'R=1 reserved AO; G=roughness; B=metallic; +Y tangent normal',
        'roughness_range':[float(roughness.min()),float(roughness.max())],
        'metallic':.98,'maps':[]}
    for role,array in arrays.items():
        pixels=np.rint(np.clip(array,0,1)*255).astype(np.uint8)
        encoded=io.BytesIO();Image.fromarray(pixels).save(encoded,format='PNG',optimize=True)
        payload=encoded.getvalue();path=output/('t_polished_brass_'+role+'.png')
        temp=path.with_suffix('.png.tmp')
        with temp.open('wb') as stream:
            stream.write(payload);stream.flush();os.fsync(stream.fileno())
        temp.replace(path)
        values=pixels.astype(float)
        wrap=float((np.abs(values[:,0]-values[:,-1]).mean()+np.abs(values[0]-values[-1]).mean())/2)
        adjacent=float((np.abs(np.diff(values,axis=0)).mean()+np.abs(np.diff(values,axis=1)).mean())/2)
        if wrap>max(2,adjacent*2.5):raise RuntimeError('Tile discontinuity: '+role)
        manifest['maps'].append({'role':role,'file':path.name,'sha256':hashlib.sha256(payload).hexdigest(),
            'bytes':len(payload),'wrap_mean_8bit':round(wrap,4),'adjacent_mean_8bit':round(adjacent,4),
            'mean_rgb_8bit':[float(x) for x in values.mean(axis=(0,1))]})
    (output/'polished_brass_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print('POLISHED_BRASS_MAPS PASS:',len(manifest['maps']),'original periodic maps')


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output',type=Path,default=Path(__file__).resolve().parents[1]/'game/art/textures/material_library')
    generate(parser.parse_args().output)
