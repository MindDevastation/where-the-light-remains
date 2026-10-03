class_name ExitFailureDialog
extends Control

var retry_button: Button
var stay_button: Button
var _message: Label
var _previous_mode := InputManager.Mode.UI
var _owned_pause := false


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    var dim := ColorRect.new()
    dim.color = Color(0.015, 0.022, 0.035, .85)
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(dim)
    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(center)
    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(560, 0)
    var style := StyleBoxFlat.new()
    style.bg_color = Color("172335")
    style.border_color = Color("b5a47d")
    style.set_border_width_all(1)
    style.set_content_margin_all(28)
    panel.add_theme_stylebox_override("panel", style)
    panel.add_theme_font_size_override("font_size", 24)
    center.add_child(panel)
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 18)
    panel.add_child(column)
    _message = Label.new()
    _message.text = "Не удалось сохранить игру.\nИгра остаётся открытой."
    _message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    column.add_child(_message)
    retry_button = Button.new()
    retry_button.text = "Повторить"
    retry_button.custom_minimum_size.y = 48
    column.add_child(retry_button)
    retry_button.pressed.connect(App.request_safe_exit)
    stay_button = Button.new()
    stay_button.text = "Остаться"
    stay_button.custom_minimum_size.y = 48
    column.add_child(stay_button)
    stay_button.pressed.connect(close)
    hide()


func open(_error: Error) -> void:
    if not visible:
        _previous_mode = InputManager.mode
        _owned_pause = not get_tree().paused
        show()
        if _owned_pause:
            InputManager.set_paused(true)
        InputManager.set_mode(InputManager.Mode.UI)
    stay_button.grab_focus()


func close() -> void:
    if not visible:
        return
    hide()
    if InputManager.mode == InputManager.Mode.UI:
        InputManager.set_mode(_previous_mode)
    if _owned_pause:
        _owned_pause = false
        InputManager.set_paused(false)


func _input(event: InputEvent) -> void:
    if visible and event is InputEventKey:
        if event.is_action_pressed(&"pause"):
            close()
        # Block underlying pause/settings key handlers; GUI receives other keys.
        if event.is_action(&"pause"):
            get_viewport().set_input_as_handled()


func _exit_tree() -> void:
    if visible:
        hide()
        if _owned_pause:
            _owned_pause = false
            InputManager.set_paused(false)
