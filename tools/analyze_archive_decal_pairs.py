#!/usr/bin/env python3
"""Check native on/off differences against projected decal volumes, without editing images."""
import argparse
import itertools
import json
from pathlib import Path
import re

import numpy as np
from PIL import Image


def analyze(directory, output):
    contract = json.loads((Path(__file__).resolve().parents[1] / 'docs/production/archive_decal_atlas_v1.json').read_text())
    placements = {p['kind']: p for p in contract['provisional_placements']}
    origin = np.array([-2.8, .65, -24])
    results = []
    for preset in ['low', 'medium']:
        receipt = json.loads((directory / ('captures_' + preset + '.json')).read_text())
        for view, fov, kinds in [('hearth_close', 55, ['dust', 'soot']), ('hearth_soot', 45, ['soot']),
                                  ('hearth_dust', 50, ['dust']), ('hearth_approach', 55, ['dust', 'soot'])]:
            on = next(c for c in receipt['captures'] if c['view'] == view and c['enabled'])
            off = next(c for c in receipt['captures'] if c['view'] == view and not c['enabled'])
            assert on['camera'] == off['camera'] and on['size'] == off['size']
            values = np.array([float(x) for x in re.findall(r'-?\d+(?:\.\d+)?', on['camera'])]).reshape(4, 3)
            basis = np.column_stack(values[:3])
            width, height = on['size']
            allowed = np.zeros((height, width), dtype=bool)
            rectangles = []
            for kind in kinds:
                centre = origin + np.array(placements[kind]['position'])
                half = np.array(placements[kind]['size']) / 2
                corners = np.array([centre + half * signs for signs in itertools.product([-1, 1], repeat=3)])
                camera = (corners - values[3]) @ basis
                depth = -camera[:, 2]
                assert np.all(depth > 0)
                focal = 1 / np.tan(np.deg2rad(fov / 2))
                xs = (.5 + camera[:, 0] / depth * focal * height / width / 2) * width
                ys = (.5 - camera[:, 1] / depth * focal / 2) * height
                # Two pixels reserve covers rounded camera metadata and raster edges.
                x0, x1 = max(0, int(np.floor(xs.min())) - 2), min(width, int(np.ceil(xs.max())) + 3)
                y0, y1 = max(0, int(np.floor(ys.min())) - 2), min(height, int(np.ceil(ys.max())) + 3)
                allowed[y0:y1, x0:x1] = True
                rectangles.append({'kind': kind, 'rect_xyxy': [x0, y0, x1, y1]})
            a = np.array(Image.open(directory / on['file']).convert('RGB')).astype(np.int16)
            b = np.array(Image.open(directory / off['file']).convert('RGB')).astype(np.int16)
            delta = np.abs(a - b).max(axis=2)
            changed = delta > 0
            outside = int(np.count_nonzero(changed & ~allowed))
            assert outside == 0, ('Rendered change outside projected decal volumes', preset, view, outside)
            results.append({'preset': preset, 'view': view, 'changed_pixels': int(np.count_nonzero(changed)),
                            'pixels_outside_projected_volume_bounds': outside,
                            'maximum_channel_delta_8bit': int(delta.max()), 'projected_volume_bounds': rectangles})
    record = {'status': 'PASS', 'scope': 'Eight existing Hearth pairs only. Conservative screen AABBs of fixed original decal volumes with two-pixel raster/metadata reserve. No image edits, new render or gameplay action.',
              'pairs': results}
    output.write_text(json.dumps(record, indent=2) + '\n')
    print('ARCHIVE_DECAL_SCOPE PASS: eight native pairs; zero changed pixels outside projected volume bounds')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--directory', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    analyze(args.directory, args.output)
