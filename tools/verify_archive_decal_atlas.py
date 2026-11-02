#!/usr/bin/env python3
"""Verify actual atlas pixels, exact crops, guards and same-runtime reproduction."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile

import numpy as np
from PIL import Image


def verify(directory):
    root = Path(__file__).resolve().parents[1]
    manifest = json.loads((directory / 'archive_decal_manifest.json').read_text())
    recipe = root / manifest['recipe']
    assert hashlib.sha256(recipe.read_bytes()).hexdigest() == manifest['recipe_sha256']
    master = np.array(Image.open(directory / 't_archive_decal_atlas.png').convert('RGBA'))
    checks = 1
    for item in manifest['textures']:
        path = directory / item['file']
        pixels = np.array(Image.open(path).convert('RGBA'))
        assert pixels.shape[1::-1] == tuple(item['size']) and pixels.shape[2] == 4
        assert path.stat().st_size == item['bytes'] and hashlib.sha256(path.read_bytes()).hexdigest() == item['sha256']
        assert hashlib.sha256(pixels.tobytes()).hexdigest() == item['decoded_rgba_sha256']
        assert np.all(pixels[:, :, :3] == 255), 'Coverage data is not an albedo photograph'
        checks += 4
        if item['kind'] == 'atlas':
            continue
        x, y, width, height = manifest['packing'][item['kind']]
        assert np.array_equal(pixels, master[y:y+height, x:x+width])
        a = pixels[:, :, 3]
        assert max(a[:32].max(), a[-32:].max(), a[:, :32].max(), a[:, -32:].max()) == 0
        assert 32 < int(a.max()) <= 255 and .001 < float(a.mean() / 255) < .35
        assert len(np.unique(a)) > 32, 'Feathered coverage must have intermediate alpha'
        checks += 4
    with tempfile.TemporaryDirectory(prefix='archive-decal-reproduce-') as temporary:
        target = Path(temporary) / 'new'
        subprocess.run([sys.executable, '-B', str(recipe), '--output', str(target)], check=True)
        for path in directory.glob('*.png'):
            assert path.read_bytes() == (target / path.name).read_bytes(), path.name
            checks += 1
        assert (directory / 'archive_decal_manifest.json').read_bytes() == (target / 'archive_decal_manifest.json').read_bytes()
        checks += 1
    print('ARCHIVE_DECAL_PIXELS PASS: %d assertions; exact source crops and reproducible bytes' % checks)
    return checks


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--directory', type=Path, required=True)
    verify(parser.parse_args().directory)
