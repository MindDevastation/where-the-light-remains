#!/usr/bin/env python3
"""Open the isolated T019 graybox review on the developer's native display."""
import argparse
from pathlib import Path
import os
import subprocess
import tempfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--godot', required=True, type=Path)
parser.add_argument('--view', choices=['active_low', 'completed_low', 'active_medium', 'all_completed_low'], default='active_low')
parser.add_argument('--screenshot', type=Path)
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
cmd = [str(args.godot.resolve()), '--path', str(root/'game'), 'res://tests/archive_route_review.tscn',
       '--', '--view='+args.view]
if args.screenshot:
    output=args.screenshot.resolve()
    if output.exists(): raise SystemExit('Preserve the existing screenshot; choose another filename')
    cmd += ['--output='+str(output)]
with tempfile.TemporaryDirectory(prefix='wlr-route-native-') as data:
    result=subprocess.run(cmd, env=dict(os.environ, XDG_DATA_HOME=data))
raise SystemExit(result.returncode)
