#!/usr/bin/env python3
"""Original periodic MAT-005 source; never regenerates an accepted family."""
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
    broad, pores, grain = noise(5, 221), noise(30, 222), noise(155, 223)
    tone = .008*broad + .010*pores + .006*grain
    color = np.array([.19, .225, .265]) + tone[:, :, None]
    roughness = .875 + .037*pores + .018*grain
    height = .00012*pores + .00003*grain
    arrays = {'albedo':color, 'normal':normals(height),
              'orm':np.stack((np.ones_like(roughness), roughness, np.zeros_like(roughness)), axis=2)}
    manifest = {'source':'tools/generate_cool_dark_stone_maps.py', 'helper':'tools/generate_material_maps.py',
        'resolution':SIZE, 'provenance':'Original seeded periodic dielectric stone data; no external/concept pixels.',
        'packing':'R=1 reserved AO; G=roughness; B=0 metallic; +Y tangent normals',
        'roughness_range':[float(roughness.min()), float(roughness.max())], 'maps':[]}
    for role, array in arrays.items():
        pixels = np.rint(np.clip(array, 0, 1)*255).astype(np.uint8)
        encoded = io.BytesIO(); Image.fromarray(pixels).save(encoded, format='PNG', optimize=True)
        payload = encoded.getvalue(); path = output/('t_cool_dark_stone_'+role+'.png')
        temp = path.with_suffix('.png.tmp')
        with temp.open('wb') as stream:
            stream.write(payload); stream.flush(); os.fsync(stream.fileno())
        temp.replace(path)
        values = pixels.astype(float)
        wrap = float((np.abs(values[:, 0]-values[:, -1]).mean()+np.abs(values[0]-values[-1]).mean())/2)
        adjacent = float((np.abs(np.diff(values, axis=0)).mean()+np.abs(np.diff(values, axis=1)).mean())/2)
        if wrap > max(2, adjacent*2.5): raise RuntimeError('Tile discontinuity: '+role)
        manifest['maps'].append({'role':role, 'file':path.name, 'sha256':hashlib.sha256(payload).hexdigest(),
            'bytes':len(payload), 'wrap_mean_8bit':round(wrap, 4), 'adjacent_mean_8bit':round(adjacent, 4),
            'mean_rgb_8bit':[float(x) for x in values.mean(axis=(0, 1))]})
    (output/'cool_dark_stone_manifest.json').write_text(json.dumps(manifest, indent=2)+'\n')
    print('COOL_DARK_STONE_MAPS PASS:', len(manifest['maps']), 'original periodic maps')


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=Path(__file__).resolve().parents[1]/'game/art/textures/material_library')
    generate(parser.parse_args().output)
