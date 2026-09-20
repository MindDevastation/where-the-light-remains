extends SceneTree
## CLI-only tests of persisted bindings using real InputEventKey dispatch.

const LETTER_KEYS: Dictionary = {
    &"move_forward": [KEY_W, "Ц"],
    &"move_backward": [KEY_S, "Ы"],
    &"move_left": [KEY_A, "Ф"],
    &"move_right": [KEY_D, "В"],
    &"interact": [KEY_E, "У"],
    &"hint": [KEY_H, "Р"],
}
const ACTIONS: Array[StringName] = [
    &"hint", &"interact", &"move_backward", &"move_forward",
    &"move_left", &"move_right", &"pause", &"skip_sequence",
]

var _failures: Array[String] = []


func _initialize() -> void:
    _run.call_deferred()


func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
        push_error("INPUT_MAP FAIL: " + message)


func _key(physical: int, pressed: bool, logical: int = -1, label: String = "", shift: bool = false, echo: bool = false) -> InputEventKey:
    var event := InputEventKey.new()
    event.set("physical_keycode", physical)
    event.set("keycode", physical if logical < 0 else logical)
    event.set("key_label", event.keycode if label.is_empty() else label.unicode_at(0))
    event.unicode = 0 if label.is_empty() or not pressed else label.to_lower().unicode_at(0)
    event.pressed = pressed
    event.shift_pressed = shift
    event.echo = echo
    Input.parse_input_event(event)
    Input.flush_buffered_events()
    return event


func _held(expected: Array) -> void:
    for action in ACTIONS:
        _check(Input.is_action_pressed(action) == expected.has(action), "Unexpected held state: " + action)


func _movement() -> Vector2:
    return Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_backward")


func _run() -> void:
    print("INPUT_MAP runtime: ", Engine.get_version_info()["string"], "; display=", DisplayServer.get_name())
    print("INPUT_MAP source: project.godot; injected keyboard events, not OS keyboard input")
    var custom_actions: Array[StringName] = []
    for action in InputMap.get_actions():
        if not String(action).begins_with("ui_"):
            custom_actions.append(action)
    _check(custom_actions.size() == ACTIONS.size(), "Expected exactly 8 project actions; got %s" % [custom_actions])
    for action in ACTIONS:
        _check(custom_actions.has(action), "Missing project action: " + action)
    if not _failures.is_empty():
        quit(1)
        return

    for action in ACTIONS:
        _check(ProjectSettings.has_setting("input/" + action), "Binding is not persisted: " + action)
        _check(is_equal_approx(InputMap.action_get_deadzone(action), 0.2), "Unexpected deadzone: " + action)
        var events: Array[InputEvent] = InputMap.action_get_events(action)
        _check(events.size() == 1 and events[0] is InputEventKey, "Expected one keyboard binding: " + action)
    for action in [&"jump", &"sprint", &"crouch"]:
        _check(not InputMap.has_action(action), "Unapproved movement action: " + action)

    # Match letter keys by position, including Cyrillic labels/Unicode.
    for action in LETTER_KEYS:
        var physical: int = LETTER_KEYS[action][0]
        for label in [OS.get_keycode_string(physical), LETTER_KEYS[action][1]]:
            var pressed := _key(physical, true, physical, label)
            _check(pressed.is_action_pressed(action), "Key event did not match: " + action)
            _held([action])
            var released := _key(physical, false, physical, label)
            _check(released.is_action_released(action), "Release did not match: " + action)
            _held([])
    print("INPUT_MAP checked: W/S/A/D/E/H press and release with Latin and Cyrillic labels")

    # A layout may put Z at the physical W position. A logical W elsewhere
    # must not be mistaken for the physical movement key.
    _key(KEY_W, true, KEY_Z, "Z")
    _held([&"move_forward"])
    _key(KEY_W, false, KEY_Z, "Z")
    _held([])
    _key(KEY_Q, true, KEY_W, "W")
    _held([])
    _key(KEY_Q, false, KEY_W, "W")
    _held([])
    _key(KEY_E, true, KEY_E, "У", true)
    _held([&"interact"])
    _key(KEY_E, false, KEY_E, "У", false)
    _held([])
    print("INPUT_MAP checked: physical/logical mismatch and release after modifier change")

    _key(KEY_W, true)
    _check(_movement().is_equal_approx(Vector2(0, -1)), "Forward vector is incorrect")
    _key(KEY_D, true)
    var diagonal := _movement()
    _check(is_equal_approx(diagonal.length(), 1.0) and diagonal.x > 0 and diagonal.y < 0, "Diagonal is not normalized")
    _key(KEY_W, false)
    _key(KEY_D, false)
    for physical in [KEY_W, KEY_S, KEY_A, KEY_D]:
        _key(physical, true)
    _check(_movement().is_equal_approx(Vector2.ZERO), "Opposing movement keys must cancel")
    for physical in [KEY_W, KEY_S, KEY_A, KEY_D]:
        _key(physical, false)
    _held([])
    print("INPUT_MAP checked: forward direction, normalized diagonal, opposite keys and release")

    # Both actions expose the same raw Esc state. Hold timing and repeat-run
    # eligibility are responsibilities of future consumers, not InputMap.
    _key(0, true, KEY_ESCAPE)
    _held([&"pause", &"skip_sequence"])
    _check(Input.is_action_pressed(&"ui_cancel"), "Built-in ui_cancel was lost")
    var repeated := _key(0, true, KEY_ESCAPE, "", false, true)
    _check(not repeated.is_action_pressed(&"pause"), "Echo must not look like a fresh pause press")
    _check(repeated.is_action_pressed(&"pause", true), "Explicit echo matching failed")
    _held([&"pause", &"skip_sequence"])
    _key(0, false, KEY_ESCAPE)
    _held([])
    _check(not Input.is_action_pressed(&"ui_cancel"), "ui_cancel did not release")
    _key(KEY_ENTER, true)
    _check(Input.is_action_pressed(&"ui_accept"), "Built-in ui_accept was lost")
    _held([])
    _key(KEY_ENTER, false)
    print("INPUT_MAP checked: shared Esc, repeat events, ui_cancel and ui_accept")

    var motion := InputEventMouseMotion.new()
    motion.relative = Vector2(12, -4)
    Input.parse_input_event(motion)
    Input.flush_buffered_events()
    _held([])
    _check(_movement().is_equal_approx(Vector2.ZERO), "Input state leaked between checks")
    if _failures.is_empty():
        print("INPUT_MAP PASS: persisted bindings, layout-independent matching and input lifecycle")
        quit()
    else:
        quit(1)
