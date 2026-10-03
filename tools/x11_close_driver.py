"""Send one native WM_DELETE_WINDOW request on the isolated authenticated X11 display.

CLI engineering fixture only. The graphical runner initializes the protocol atom
before Godot starts and preserves the Xvfb server with -noreset.
"""
import argparse
import ctypes as c


class ClientData(c.Union):
    _fields_ = [('b', c.c_char * 20), ('s', c.c_short * 10), ('l', c.c_long * 5)]


class ClientMessage(c.Structure):
    _fields_ = [('type', c.c_int), ('serial', c.c_ulong), ('send_event', c.c_int),
                ('display', c.c_void_p), ('window', c.c_ulong), ('message_type', c.c_ulong),
                ('format', c.c_int), ('data', ClientData)]


class Event(c.Union):
    _fields_ = [('client', ClientMessage), ('padding', c.c_long * 24)]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--window', type=int, required=True)
    args = parser.parse_args()
    x = c.CDLL('libX11.so.6')
    x.XOpenDisplay.argtypes = [c.c_char_p]
    x.XOpenDisplay.restype = c.c_void_p
    x.XInternAtom.argtypes = [c.c_void_p, c.c_char_p, c.c_int]
    x.XInternAtom.restype = c.c_ulong
    x.XSendEvent.argtypes = [c.c_void_p, c.c_ulong, c.c_int, c.c_long, c.POINTER(Event)]
    x.XSendEvent.restype = c.c_int
    x.XSync.argtypes = [c.c_void_p, c.c_int]
    x.XCloseDisplay.argtypes = [c.c_void_p]
    display = x.XOpenDisplay(None)
    if not display:
        raise RuntimeError('Authenticated X11 display unavailable')
    try:
        protocols = x.XInternAtom(display, b'WM_PROTOCOLS', 1)
        delete = x.XInternAtom(display, b'WM_DELETE_WINDOW', 1)
        if not protocols or not delete:
            raise RuntimeError('Required window-manager protocol atoms unavailable')
        event = Event()
        event.client.type = 33
        event.client.display = display
        event.client.window = args.window
        event.client.message_type = protocols
        event.client.format = 32
        event.client.data.l[0] = delete
        if not x.XSendEvent(display, args.window, 0, 0, c.byref(event)):
            raise RuntimeError('X11 close request rejected')
        x.XSync(display, 0)
        print('X11_NATIVE_CLOSE request sent')
    finally:
        x.XCloseDisplay(display)


if __name__ == '__main__':
    main()
