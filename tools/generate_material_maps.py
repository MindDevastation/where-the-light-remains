#!/usr/bin/env python3
"""Author original periodic material maps; no concept pixels or external textures.

Python 3.11+, NumPy, Pillow. Run from any directory; output defaults to the
repository's game/art/textures/material_library. Seeds and dimensions are fixed.
RGB ORM packing: R=ambient occlusion (1), G=roughness, B=metallic.
Normal maps use tangent-space +Y; derivatives wrap at the tile boundary.
"""
import argparse
import hashlib
import io
import json
import os
from pathlib import Path
import numpy as np
from PIL import Image

SIZE = 1024


def noise(cutoff, seed):
    rng = np.random.default_rng(seed)
    frequencies = np.fft.fftfreq(SIZE) * SIZE
    radius2 = frequencies[:, None] ** 2 + frequencies[None, :] ** 2
    spectrum = np.fft.fft2(rng.standard_normal((SIZE, SIZE)))
    field = np.fft.ifft2(spectrum * np.exp(-radius2 / (2 * cutoff ** 2))).real
    return np.tanh(field / (field.std() * 1.7))


def normals(height):
    dx = (np.roll(height, -1, axis=1) - np.roll(height, 1, axis=1)) * SIZE * 0.5
    dy = (np.roll(height, -1, axis=0) - np.roll(height, 1, axis=0)) * SIZE * 0.5
    normal = np.stack((-dx, dy, np.ones_like(height)), axis=2)
    normal /= np.linalg.norm(normal, axis=2, keepdims=True)
    return normal * 0.5 + 0.5


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=Path(__file__).resolve().parents[1] / 'game/art/textures/material_library')
    out = parser.parse_args().output
    out.mkdir(parents=True, exist_ok=True)
    manifest = {'resolution': SIZE, 'source': 'tools/generate_material_maps.py', 'provenance': 'Original analytic/seeded periodic maps; no third-party pixels.', 'maps': []}

    def save(name, array):
        pixels = np.rint(np.clip(array, 0, 1) * 255).astype(np.uint8)
        path = out / (name + '.png')
        encoded = io.BytesIO()
        Image.fromarray(pixels).save(encoded, format='PNG', optimize=True)
        payload = encoded.getvalue()
        temporary = path.with_suffix('.png.tmp')
        with temporary.open('wb') as stream:
            stream.write(payload)
            stream.flush()
            os.fsync(stream.fileno())
        temporary.replace(path)
        # A periodic sampled field need not duplicate its last/first pixel.
        # Compare wrap differences to ordinary adjacent differences instead.
        values = pixels.astype(float)
        wrap = float((np.abs(values[:, 0] - values[:, -1]).mean() + np.abs(values[0] - values[-1]).mean()) / 2)
        adjacent = float((np.abs(np.diff(values, axis=0)).mean() + np.abs(np.diff(values, axis=1)).mean()) / 2)
        if wrap > max(2.0, adjacent * 2.5):
            raise RuntimeError('Tile-boundary discontinuity: ' + name)
        manifest['maps'].append({'file': path.name, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest(), 'bytes': path.stat().st_size, 'wrap_mean_8bit': round(wrap, 4), 'adjacent_mean_8bit': round(adjacent, 4)})

    def surface(family, color, roughness, metallic, height):
        save('t_' + family + '_albedo', color)
        save('t_' + family + '_normal', normals(height))
        save('t_' + family + '_orm', np.stack((np.ones_like(roughness), roughness, np.broadcast_to(metallic, roughness.shape)), axis=2))

    broad, medium, fine = noise(4, 41), noise(24, 42), noise(180, 43)
    veins = np.exp(-np.square((noise(8, 44) + 0.2 * medium) * 28))
    tone = 0.035 * broad + 0.02 * medium + 0.011 * fine - 0.025 * veins
    color = np.array([0.73, 0.69, 0.61]) + tone[:, :, None]
    surface('observatory_stone', color, 0.78 + 0.07 * medium + 0.025 * fine, 0.0, 0.0004 * medium + 0.00016 * fine - 0.00013 * veins)

    u, v = np.meshgrid(np.arange(SIZE) / SIZE, np.arange(SIZE) / SIZE)
    patches, detail = noise(5, 51), noise(90, 52)
    # Smooth coverage avoids hard camouflage-like thresholds in the metal.
    patina = np.square(patches * 0.5 + 0.5) * 0.65
    brush = np.sin(2 * np.pi * (u * 170 + 0.3 * noise(5, 53)))
    color = np.array([0.59, 0.43, 0.22]) + (detail * 0.018 + brush * 0.005)[:, :, None]
    color -= patina[:, :, None] * np.array([0.21, 0.15, 0.065])
    surface('aged_brass', color, 0.32 + 0.15 * patina + 0.035 * detail, 0.96 - 0.18 * patina, 0.0001 * patches + 0.000035 * detail + 0.000018 * brush)

    warp = 0.2 * noise(3, 61) + 0.035 * noise(14, 62) + 0.08 * np.sin(2 * np.pi * v)
    rings = np.sin(2 * np.pi * (u * 24 + warp * 5))
    pores = np.maximum(np.sin(2 * np.pi * (u * 160 + warp * 12)), 0) ** 14
    dark_grain = np.maximum(rings, 0) ** 10
    color = np.array([0.24, 0.133, 0.074]) + (0.025 * noise(8, 63) + rings * 0.019)[:, :, None]
    color -= dark_grain[:, :, None] * np.array([0.064, 0.042, 0.024])
    color -= pores[:, :, None] * np.array([0.026, 0.015, 0.009])
    surface('dark_walnut', color, 0.25 + 0.045 * dark_grain + 0.025 * noise(12, 64), 0.0, 0.00022 * rings - 0.0001 * dark_grain - 0.000035 * pores)

    frost, grain = noise(18, 71), noise(180, 72)
    save('t_memory_glass_normal', normals(0.00011 * frost + 0.000045 * grain))
    rough = 0.64 + 0.09 * frost + 0.025 * grain
    save('t_memory_glass_roughness', np.repeat(rough[:, :, None], 3, axis=2))
    (out / 'texture_manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print('MATERIAL_MAPS PASS:', len(manifest['maps']), 'original 1024px periodic maps;', sum(m['bytes'] for m in manifest['maps']), 'PNG bytes')


if __name__ == '__main__':
    main()
