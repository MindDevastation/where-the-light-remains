#!/usr/bin/env python3
"""Original scalar-coverage decal data. Reads no existing artwork pixels."""
import argparse
import hashlib
import io
import json
from pathlib import Path

import numpy as np
from PIL import Image, __version__ as pillow_version


def generate(output):
    root = Path(__file__).resolve().parents[1]
    contract_path = root / 'docs/production/archive_decal_atlas_v1.json'
    contract = json.loads(contract_path.read_text())
    output.mkdir(parents=True, exist_ok=True)
    if any(output.iterdir()):
        raise ValueError('Use a new empty output directory; no existing art is overwritten')
    size = 1024
    y, x = np.mgrid[:size, :size].astype(np.float64)
    x = (x + .5) / size
    y = (y + .5) / size
    rng = np.random.default_rng(20261102)

    def grain(frequency, layers=5):
        result = np.zeros_like(x)
        for octave in range(layers):
            phase = rng.uniform(0, 2 * np.pi, 2)
            result += (np.sin(x * frequency * 2**octave + phase[0]) *
                       np.cos(y * frequency * 1.17 * 2**octave + phase[1])) / 2**octave
        return np.clip(.5 + result / 3.875, 0, 1)

    border = np.minimum.reduce([x, y, 1 - x, 1 - y])
    guard = np.clip((border * size - 32) / 32, 0, 1)
    guard = guard * guard * (3 - 2 * guard)
    scratches = np.zeros_like(x)
    for _index in range(26):
        a = rng.uniform(.16, .84, 2)
        angle = rng.uniform(-.9, .9)
        length = rng.uniform(.055, .23)
        direction = np.array([np.cos(angle), np.sin(angle)])
        u = (x - a[0]) * direction[0] + (y - a[1]) * direction[1]
        v = -(x - a[0]) * direction[1] + (y - a[1]) * direction[0]
        width = rng.uniform(.0009, .0022)
        taper = np.clip(1 - (u / length)**8, 0, 1)
        line = np.exp(-(v / width)**2) * taper
        broken = np.clip(.45 + .75 * np.sin(u * rng.uniform(90, 220) + rng.uniform(0, 6)), 0, 1)
        scratches = np.maximum(scratches, line * broken * rng.uniform(.5, .95))
    scratches *= .55 + .45 * grain(71)
    edge_path = .5 + .009 * np.sin(y * 49) + .004 * np.sin(y * 173)
    edge = np.exp(-((x - edge_path) / (.012 + .009 * grain(58)))**2)
    edge *= np.clip(.28 + 1.2 * grain(38), 0, 1) * np.clip(1 - ((y - .5) / .41)**8, 0, 1)
    dust = np.exp(-((x - .46) / .34)**4 - ((y - .55) / .25)**4)
    dust *= (.16 + .62 * grain(18)) * (.7 + .3 * grain(133))
    soot = np.exp(-((x - .53) / .27)**2 - ((y - .47) / .23)**2)
    soot *= (.45 + .55 * grain(29)) * (.8 + .2 * grain(191))
    masks = {'scratches': scratches, 'edge_wear': edge, 'dust': dust, 'soot': soot}
    master = np.full((2048, 2048, 4), 255, dtype=np.uint8)
    master[:, :, 3] = 0
    tiles = {}
    for name, values in masks.items():
        alpha = np.rint(np.clip(values * guard, 0, 1) * 255).astype(np.uint8)
        tile = np.full((size, size, 4), 255, dtype=np.uint8)
        tile[:, :, 3] = alpha
        px, py, width, height = contract['regions'][name]
        assert width == height == size
        master[py:py+height, px:px+width] = tile
        tiles[name] = tile

    records = []
    for name, pixels in [('atlas', master), *tiles.items()]:
        filename = 't_archive_decal_' + name + '.png'
        encoded = io.BytesIO()
        Image.fromarray(pixels).save(encoded, format='PNG', optimize=True)
        data = encoded.getvalue()
        (output / filename).write_bytes(data)
        alpha = pixels[:, :, 3]
        records.append({'kind': name, 'file': filename, 'size': list(pixels.shape[1::-1]),
                        'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest(),
                        'decoded_rgba_sha256': hashlib.sha256(pixels.tobytes()).hexdigest(),
                        'alpha_max': int(alpha.max()), 'mean_alpha': float(alpha.mean() / 255),
                        'nonzero_fraction': float(np.count_nonzero(alpha) / alpha.size)})
    manifest = {'version': 1, 'inventory': 'DECAL-001', 'seed': 20261102,
                'recipe': 'tools/generate_archive_decal_atlas.py',
                'recipe_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                'dependencies': {'numpy': np.__version__, 'Pillow': pillow_version},
                'provenance': 'Original deterministic analytic strokes and scalar fields; no input image, photograph, existing atlas or accepted artwork read.',
                'packing': contract['regions'], 'transparent_guard_px': 32,
                'interpretation': 'RGBA8; white RGB and scalar alpha. Four runtime files are exact master crops, not four independently authored atlases.',
                'textures': records}
    (output / 'archive_decal_manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print('ARCHIVE_DECAL_GENERATE PASS: one2048 master and four exact1024 coverage crops')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', required=True, type=Path)
    generate(parser.parse_args().output)
