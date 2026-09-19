extends Node

enum Mode { GAMEPLAY, UI, CINEMATIC, LIMITED_LOOK, DISABLED }
var mode: Mode = Mode.GAMEPLAY

func set_mode(new_mode: Mode) -> void:
    mode = new_mode
    match mode:
        Mode.GAMEPLAY, Mode.LIMITED_LOOK:
            Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
        _:
            Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
