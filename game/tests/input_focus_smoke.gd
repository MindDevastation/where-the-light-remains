extends Node
## CLI-only state-machine and optional native X11 focus checks.

var _failures: Array[String] = []
var _motion_count := 0
var _driver_pid := -1
var _mailbox := ""
var _serial := 0


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().create_timer(40.0).timeout.connect(func() -> void:
        push_error("INPUT_FOCUS FAIL: timeout")
        _finish(1)
    )
    _run.call_deferred()


func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
        push_error("INPUT_FOCUS FAIL: " + message)


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and InputManager.can_look():
        _motion_count += 1


func _key(key: Key, pressed: bool, echo: bool = false) -> void:
    var event := InputEventKey.new()
    event.physical_keycode = key
    event.keycode = key
    event.pressed = pressed
    event.echo = echo
    Input.parse_input_event(event)
    Input.flush_buffered_events()


func _motion() -> void:
    var event := InputEventMouseMotion.new()
    event.relative = Vector2(35, -12)
    event.position = Vector2(16, 16)
    Input.parse_input_event(event)
    Input.flush_buffered_events()


func _state(expected_move: bool, expected_look: bool, label: String) -> void:
    _check(InputManager.can_move() == expected_move, label + ": move gate")
    _check(InputManager.can_interact() == expected_move, label + ": interaction gate")
    _check(InputManager.can_look() == expected_look, label + ": look gate")
    if DisplayServer.get_name() != "headless":
        _check(Input.mouse_mode == (Input.MOUSE_MODE_CAPTURED if expected_look else Input.MOUSE_MODE_VISIBLE), label + ": native mouse mode")


func _run() -> void:
    print("INPUT_FOCUS runtime: ", Engine.get_version_info()["string"], "; display=", DisplayServer.get_name())
    _check(InputManager.mode == InputManager.Mode.UI, "Startup must leave a visible UI cursor")
    _check(InputManager.process_mode == Node.PROCESS_MODE_ALWAYS, "Pause owner must process while paused")
    # Deterministic combinations use real Window signals, explicitly synthetic.
    for focused in [true, false]:
        for paused in [false, true]:
            for mode in [InputManager.Mode.GAMEPLAY, InputManager.Mode.UI, InputManager.Mode.CINEMATIC, InputManager.Mode.LIMITED_LOOK, InputManager.Mode.DISABLED]:
                if focused:
                    get_window().focus_entered.emit()
                else:
                    get_window().focus_exited.emit()
                InputManager.set_paused(paused)
                InputManager.set_mode(mode)
                var allowed: bool = focused and not paused
                _state(allowed and mode == InputManager.Mode.GAMEPLAY,
                    allowed and mode in [InputManager.Mode.GAMEPLAY, InputManager.Mode.LIMITED_LOOK],
                    "mode=%d focus=%s pause=%s" % [mode, focused, paused])
                _check(InputManager.mode == mode, "Focus/pause overwrote requested mode")
    print("INPUT_FOCUS checked: 20 requested-mode/focus/pause combinations (synthetic Window signals)")

    InputManager.set_paused(false)
    get_window().focus_entered.emit()
    InputManager.set_mode(InputManager.Mode.GAMEPLAY)
    _key(KEY_W, true)
    _check(InputManager.get_movement_vector() == Vector2.UP, "W must move forward")
    _key(KEY_D, true)
    _check(InputManager.get_movement_vector().is_equal_approx(Vector2(1, -1).normalized()), "Diagonal normalization")
    InputManager.set_paused(true)
    _check(not Input.is_action_pressed(&"move_forward"), "Pause must release held gameplay actions")
    _state(false, false, "paused")
    InputManager.set_paused(false)
    _key(KEY_W, true, true)
    _key(KEY_D, true, true)
    _check(InputManager.get_movement_vector() == Vector2.ZERO, "Echo resurrected movement after pause")
    _key(KEY_W, false)
    _key(KEY_D, false)
    _key(KEY_W, true)
    _check(InputManager.get_movement_vector() == Vector2.UP, "Fresh key press did not rearm movement")
    _key(KEY_W, false)
    InputManager.set_mode(InputManager.Mode.UI)
    _key(KEY_D, true)
    InputManager.set_mode(InputManager.Mode.GAMEPLAY)
    _key(KEY_D, true, true)
    _check(InputManager.get_movement_vector() == Vector2.ZERO, "Key held in UI leaked into gameplay")
    _key(KEY_D, false)
    _key(KEY_D, true)
    _check(InputManager.get_movement_vector() == Vector2.RIGHT, "UI hold did not rearm after release")
    _key(KEY_D, false)
    # Built-in navigation and shared pause/skip raw state remain intact.
    _key(KEY_ESCAPE, true)
    _check(Input.is_action_pressed(&"pause") and Input.is_action_pressed(&"skip_sequence"), "Shared Esc source changed")
    _key(KEY_ESCAPE, false)
    _key(KEY_ENTER, true)
    _check(Input.is_action_pressed(&"ui_accept"), "Built-in UI navigation changed")
    _key(KEY_ENTER, false)
    get_tree().paused = true
    _check(not InputManager.can_move(), "Direct tree pause did not immediately close gameplay gate")
    await get_tree().process_frame
    await get_tree().process_frame
    _state(false, false, "legacy tree pause")
    get_tree().paused = false
    await get_tree().process_frame
    await get_tree().process_frame
    _state(true, true, "legacy tree resume")
    _motion_count = 0
    InputManager.set_mode(InputManager.Mode.UI)
    InputManager.set_mode(InputManager.Mode.GAMEPLAY)
    _motion()
    _check(_motion_count == 0, "Recapture motion reached player")
    _motion()
    _check(_motion_count == 1, "Normal look motion was swallowed")
    InputManager.set_mode(InputManager.Mode.DISABLED)
    _motion()
    _check(_motion_count == 1, "Disabled motion reached player")
    InputManager.set_mode(InputManager.Mode.UI)
    var ui := Control.new()
    ui.size = Vector2(80, 80)
    add_child(ui)
    var gui_events := [0]
    ui.gui_input.connect(func(event: InputEvent) -> void:
        if event is InputEventMouseMotion:
            gui_events[0] += 1
    )
    _motion()
    _check(gui_events[0] > 0, "UI pointer motion was intercepted by capture owner")
    ui.free()
    print("INPUT_FOCUS checked: normalized movement, held/echo suppression, UI/escape baseline, direct pause, first-motion guard")

    for argument in OS.get_cmdline_user_args():
        if argument.begins_with("--native-driver="):
            await _native_focus(argument.trim_prefix("--native-driver="))
    InputManager.set_paused(false)
    InputManager.set_mode(InputManager.Mode.UI)
    if _failures.is_empty():
        print("INPUT_FOCUS PASS: mode/focus/pause/capture and input boundary checks")
        _finish(0)
    else:
        _finish(1)


func _native_focus(driver: String) -> void:
    _check(DisplayServer.get_name() == "X11", "Native driver requires actual X11")
    _mailbox = "user://input_focus_driver_%d.json" % Time.get_ticks_usec()
    var window := DisplayServer.window_get_native_handle(DisplayServer.WINDOW_HANDLE)
    _driver_pid = OS.create_process("/usr/bin/python3", [driver, "--window", str(window), "--mailbox", ProjectSettings.globalize_path(_mailbox)])
    _check(_driver_pid > 0, "Native X11 driver could not start")
    if _driver_pid <= 0:
        return
    # These checks wait for actual XSetInputFocus events, not signal injection.
    await _native_command("home", true)
    InputManager.set_mode(InputManager.Mode.GAMEPLAY)
    _state(true, true, "native gameplay")
    _key(KEY_W, true)
    await _native_command("away", false)
    _state(false, false, "native focus loss")
    _check(not Input.is_action_pressed(&"move_forward"), "Native focus loss left W held")
    InputManager.set_mode(InputManager.Mode.UI)
    await _native_command("home", true)
    _state(false, false, "UI selected while unfocused")
    InputManager.set_mode(InputManager.Mode.GAMEPLAY)
    InputManager.set_paused(true)
    await _native_command("away", false)
    await _native_command("home", true)
    _state(false, false, "focus regained while paused")
    InputManager.set_paused(false)
    _state(true, true, "native resume")
    await _native_command("away", false)
    InputManager.set_mode(InputManager.Mode.DISABLED)
    await _native_command("home", true)
    _state(false, false, "transition lock survived focus return")
    _key(KEY_W, false)
    print("INPUT_FOCUS native checked: real X11 focus loss/return, held W, UI choice, paused return and DISABLED lock")


func _native_command(command: String, focused: bool) -> void:
    _serial += 1
    var file := FileAccess.open(_mailbox, FileAccess.WRITE)
    file.store_string(JSON.stringify({"command": command, "serial": _serial}))
    file.close()
    for frame in 100:
        await get_tree().process_frame
        var ack: Variant = null
        if FileAccess.file_exists(_mailbox + ".ack"):
            ack = JSON.parse_string(FileAccess.get_file_as_string(_mailbox + ".ack"))
        if ack is Dictionary and ack.get("serial") == _serial and get_window().has_focus() == focused:
            await get_tree().process_frame
            return
    _check(false, "Actual X11 focus timeout: " + command)


func _finish(code: int) -> void:
    if _driver_pid > 0 and OS.is_process_running(_driver_pid):
        OS.kill(_driver_pid)
    for path in [_mailbox, _mailbox + ".ack"]:
        if not _mailbox.is_empty() and FileAccess.file_exists(path):
            DirAccess.remove_absolute(path)
    get_tree().quit(code)
