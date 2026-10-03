"""Drive real focus events in the isolated authenticated Xvfb test display.

Only used by the CLI InputManager smoke harness, never by the game.
"""
import argparse
import ctypes
import json
from pathlib import Path
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--window', type=int, required=True)
    parser.add_argument('--mailbox', type=Path, required=True)
    args = parser.parse_args()
    x = ctypes.CDLL('libX11.so.6')
    display_type = ctypes.c_void_p
    window_type = ctypes.c_ulong
    x.XOpenDisplay.argtypes = [ctypes.c_char_p]
    x.XOpenDisplay.restype = display_type
    x.XDefaultRootWindow.argtypes = [display_type]
    x.XDefaultRootWindow.restype = window_type
    x.XCreateSimpleWindow.argtypes = [display_type, window_type, ctypes.c_int, ctypes.c_int,
                                    ctypes.c_uint, ctypes.c_uint, ctypes.c_uint, window_type, window_type]
    x.XCreateSimpleWindow.restype = window_type
    x.XMapWindow.argtypes = [display_type, window_type]
    x.XSetInputFocus.argtypes = [display_type, window_type, ctypes.c_int, window_type]
    x.XSync.argtypes = [display_type, ctypes.c_int]
    x.XDestroyWindow.argtypes = [display_type, window_type]
    x.XCloseDisplay.argtypes = [display_type]
    display = x.XOpenDisplay(None)
    if not display:
        raise RuntimeError('Authenticated X11 display unavailable')
    dummy = x.XCreateSimpleWindow(display, x.XDefaultRootWindow(display), 0, 0, 80, 60, 0, 0, 0)
    x.XMapWindow(display, dummy)
    x.XSync(display, 0)
    serial = 0
    deadline = time.monotonic() + 35
    try:
        while time.monotonic() < deadline:
            if args.mailbox.exists():
                try:
                    request = json.loads(args.mailbox.read_text())
                except json.JSONDecodeError:
                    request = {}
                if request.get('serial', 0) > serial:
                    if request['command'] not in ('home', 'away'):
                        raise RuntimeError('Unexpected focus operation')
                    target = args.window if request['command'] == 'home' else dummy
                    x.XSetInputFocus(display, target, 2, 0)
                    x.XSync(display, 0)
                    serial = request['serial']
                    ack = args.mailbox.with_name(args.mailbox.name + '.ack')
                    staging = ack.with_suffix('.tmp')
                    staging.write_text(json.dumps({'serial': serial, 'command': request['command']}))
                    staging.replace(ack)
            time.sleep(0.025)
    finally:
        x.XDestroyWindow(display, dummy)
        x.XCloseDisplay(display)


if __name__ == '__main__':
    main()
