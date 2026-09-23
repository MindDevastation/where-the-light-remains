#!/usr/bin/env python3
"""Run Godot through authenticated Xvfb TCP, without requiring AF_UNIX.

Restore the local graphics prefix first (see MATERIAL_PREFLIGHT.md).
Authorization stays enabled. No game renderer settings are modified.
"""
import argparse
import os
from pathlib import Path
import secrets
import shlex
import signal
import socket
import struct
import subprocess
import sys
import tempfile
import time


def stop(process):
    if process is not None and process.poll() is None:
        os.killpg(process.pid, signal.SIGTERM)
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait()


def auth_status(port, cookie):
    name = b'MIT-MAGIC-COOKIE-1' if cookie else b''
    header = struct.pack('<BBHHHHH', ord('l'), 0, 11, 0, len(name), len(cookie), 0)
    packet = header + name + bytes((-len(name)) % 4) + cookie + bytes((-len(cookie)) % 4)
    with socket.create_connection(('127.0.0.1', port), timeout=2) as client:
        client.sendall(packet)
        reply = client.recv(8)
        if not reply:
            raise RuntimeError('X11 server closed setup connection')
        return reply[0]


def free_display():
    for number in range(100, 200):
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as probe:
                probe.bind(('127.0.0.1', 6000 + number))
            return number
        except OSError:
            continue
    raise RuntimeError('No available TCP display in range 100..199')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--graphics-prefix', required=True, type=Path)
    parser.add_argument('--godot', required=True, type=Path)
    parser.add_argument('--timeout', type=float, default=120)
    parser.add_argument('--expect', help='Required Godot success marker')
    parser.add_argument('godot_args', nargs=argparse.REMAINDER)
    args = parser.parse_args()
    prefix = args.graphics_prefix.resolve()
    godot_args = args.godot_args
    if godot_args[:1] == ['--']:
        godot_args = godot_args[1:]
    xvfb = prefix / 'usr/bin/Xvfb'
    icds = list((prefix / 'usr/share/vulkan/icd.d').glob('*lvp*.json'))
    if not xvfb.is_file() or not args.godot.is_file() or len(icds) != 1:
        raise RuntimeError('Missing Xvfb/Godot or ambiguous/missing lavapipe ICD')
    if not Path('/usr/bin/xkbcomp').is_file():
        raise RuntimeError('Restore the documented /usr/bin/xkbcomp symlink to the local prefix')
    display = free_display()
    cookie = secrets.token_bytes(16)
    server = game = None
    with tempfile.TemporaryDirectory(prefix='wlr-x11-') as directory:
        private = Path(directory)
        authority = private / 'Xauthority'
        records = b''
        # Xlib canonicalizes loopback to the local hostname on some systems.
        for family, address in [(0, socket.inet_aton('127.0.0.1')), (256, socket.gethostname().encode())]:
            fields = [address, str(display).encode(), b'MIT-MAGIC-COOKIE-1', cookie]
            records += struct.pack('>H', family) + b''.join(struct.pack('>H', len(x)) + x for x in fields)
        authority.write_bytes(records)
        authority.chmod(0o600)
        env = os.environ.copy()
        env.update(DISPLAY=f'127.0.0.1:{display}', XAUTHORITY=str(authority), XDG_RUNTIME_DIR=directory)
        env['LD_LIBRARY_PATH'] = str(prefix / 'usr/lib/x86_64-linux-gnu') + (':' + env['LD_LIBRARY_PATH'] if env.get('LD_LIBRARY_PATH') else '')
        env['PATH'] = str(prefix / 'usr/bin') + ':' + env['PATH']
        env['VK_ICD_FILENAMES'] = str(icds[0])
        env.setdefault('LP_NUM_THREADS', '4')
        command = [str(xvfb), f':{display}', '-screen', '0', '1920x1080x24', '-listen', 'tcp', '-nolisten', 'unix', '-nolisten', 'local', '-noreset', '-auth', str(authority)]
        print('$ ' + shlex.join(command), flush=True)
        print('DISPLAY=' + env['DISPLAY'] + '; VK_ICD_FILENAMES=' + env['VK_ICD_FILENAMES'], flush=True)
        with (private / 'xvfb.log').open('w+') as server_log, (private / 'godot.log').open('w+') as game_log:
            try:
                server = subprocess.Popen(command, env=env, stdout=server_log, stderr=subprocess.STDOUT, start_new_session=True)
                deadline = time.monotonic() + 15
                while True:
                    if server.poll() is not None:
                        raise RuntimeError(f'Xvfb exited early: {server.returncode}')
                    try:
                        accepted = auth_status(6000 + display, cookie)
                        break
                    except (OSError, RuntimeError):
                        if time.monotonic() >= deadline:
                            raise RuntimeError('Xvfb TCP readiness timeout')
                        time.sleep(0.1)
                if accepted != 1 or auth_status(6000 + display, b'') != 0:
                    raise RuntimeError('X11 authorization check failed')
                print('X11_TCP_AUTH PASS: valid cookie accepted; unauthenticated client rejected', flush=True)
                atom_code = "import ctypes; x=ctypes.CDLL('libX11.so.6'); x.XOpenDisplay.restype=ctypes.c_void_p; x.XInternAtom.argtypes=[ctypes.c_void_p,ctypes.c_char_p,ctypes.c_int]; x.XCloseDisplay.argtypes=[ctypes.c_void_p]; d=x.XOpenDisplay(None); assert d; assert x.XInternAtom(d,b'WM_DELETE_WINDOW',0); x.XCloseDisplay(d)"
                subprocess.run([sys.executable, '-c', atom_code], env=env, check=True, timeout=10)
                command = [str(args.godot.resolve()), '--display-driver', 'x11', '--rendering-driver', 'vulkan', '--rendering-method', 'forward_plus', '--audio-driver', 'Dummy'] + godot_args
                print('$ ' + shlex.join(command), flush=True)
                game = subprocess.Popen(command, env=env, stdout=game_log, stderr=subprocess.STDOUT, start_new_session=True)
                try:
                    code = game.wait(timeout=args.timeout)
                except subprocess.TimeoutExpired:
                    raise RuntimeError(f'Godot timeout after {args.timeout}s')
                game_log.seek(0)
                output = game_log.read()
                if code != 0 or any(marker in output for marker in ('ERROR:', 'SCRIPT ERROR', 'Parse Error')):
                    raise RuntimeError(f'Godot failed: exit={code}; see captured output')
                if args.expect and args.expect not in output:
                    raise RuntimeError('Godot success marker missing: ' + args.expect)
                if 'Forward+' not in output:
                    raise RuntimeError('Graphical Forward+ device header missing')
                print(f'GRAPHICAL_RUN PASS: exit={code}', flush=True)
            finally:
                stop(game)
                stop(server)
                for name, log in [('Godot stdout/stderr', game_log), ('Xvfb stdout/stderr', server_log)]:
                    log.seek(0)
                    print('\n' + name + ':\n' + log.read(), flush=True)


if __name__ == '__main__':
    main()
