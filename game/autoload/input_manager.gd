extends Node
## Sole owner of input mode, tree pause and mouse capture.
## Requested mode survives pause/focus changes; neither can unlock DISABLED.

signal mode_changed(new_mode: Mode)
signal availability_changed
signal pause_changed(paused: bool)

enum Mode { GAMEPLAY, UI, CINEMATIC, LIMITED_LOOK, DISABLED }
const GAMEPLAY_ACTIONS: Array[StringName] = [
    &"move_forward", &"move_backward", &"move_left", &"move_right", &"interact", &"hint",
]

var mode: Mode:
    get: return _mode

var _mode: Mode = Mode.UI
var _focused := true
var _was_paused := false
var _available := false
var _discard_motion := true
var _suppressed_actions: Dictionary = {}


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    # Headless tests have no native focus. Graphical runs use the actual window.
    _focused = DisplayServer.get_name() == "headless" or get_window().has_focus()
    get_window().focus_entered.connect(_on_focus_entered)
    get_window().focus_exited.connect(_on_focus_exited)
    _refresh()


func set_mode(new_mode: Mode) -> void:
    if new_mode == _mode:
        _refresh()
        return
    _release_gameplay_actions()
    _mode = new_mode
    _discard_motion = true
    _refresh()
    mode_changed.emit(_mode)


func set_paused(paused: bool) -> void:
    get_tree().paused = paused
    _refresh()


func can_move() -> bool:
    return _mode == Mode.GAMEPLAY and _has_control()


func can_look() -> bool:
    return _mode in [Mode.GAMEPLAY, Mode.LIMITED_LOOK] and _has_control()


func can_interact() -> bool:
    return can_move()


func get_movement_vector() -> Vector2:
    if not can_move():
        return Vector2.ZERO
    # Input.get_vector's circular deadzone/normalized diagonals, with a fresh
    # press required after a key was held across UI, pause or focus loss.
    var vector := Vector2(
        _strength(&"move_right") - _strength(&"move_left"),
        _strength(&"move_backward") - _strength(&"move_forward")
    )
    var deadzone := 0.0
    for action in [&"move_right", &"move_left", &"move_backward", &"move_forward"]:
        deadzone += InputMap.action_get_deadzone(action) * 0.25
    var length := vector.length()
    if length <= deadzone:
        return Vector2.ZERO
    if length > 1.0:
        return vector.normalized()
    return vector.normalized() * ((length - deadzone) / (1.0 - deadzone))


func _strength(action: StringName) -> float:
    return 0.0 if _suppressed_actions.has(action) else Input.get_action_raw_strength(action)


func _has_control() -> bool:
    return _focused and is_inside_tree() and not get_tree().paused


func _process(_delta: float) -> void:
    # Also cover legacy/debug consumers changing SceneTree.paused directly.
    if get_tree().paused != _was_paused:
        _refresh()


func _input(event: InputEvent) -> void:
    if event is InputEventKey:
        for action in GAMEPLAY_ACTIONS:
            if event.is_action_released(action):
                _suppressed_actions.erase(action)
            elif event.is_action_pressed(action, true):
                if not can_move():
                    _suppressed_actions[action] = true
                elif not event.is_echo():
                    _suppressed_actions.erase(action)
    if event is InputEventMouseMotion and can_look() and _discard_motion:
        _discard_motion = false
        # Consume the first recapture/warp motion before the player's
        # _unhandled_input callback. UI pointer events keep their normal route.
        get_viewport().set_input_as_handled()


func _on_focus_entered() -> void:
    _focused = true
    _refresh()


func _on_focus_exited() -> void:
    _focused = false
    _refresh()


func _release_gameplay_actions() -> void:
    for action in GAMEPLAY_ACTIONS:
        if Input.is_action_pressed(action):
            _suppressed_actions[action] = true
        Input.action_release(action)


func _refresh() -> void:
    var paused := get_tree().paused
    var available := can_look()
    if paused != _was_paused or available != _available:
        _release_gameplay_actions()
        _discard_motion = true
    var mouse_mode := Input.MOUSE_MODE_CAPTURED if available else Input.MOUSE_MODE_VISIBLE
    if Input.mouse_mode != mouse_mode:
        Input.mouse_mode = mouse_mode
    var changed := available != _available or paused != _was_paused
    var pause_changed_now := paused != _was_paused
    _available = available
    _was_paused = paused
    if pause_changed_now:
        pause_changed.emit(paused)
    if changed:
        availability_changed.emit()
