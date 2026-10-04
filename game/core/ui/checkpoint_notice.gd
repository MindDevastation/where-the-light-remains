class_name CheckpointNotice
extends Control
## A failed milestone remains dirty. Retry restores input before the fragment modal.

signal retry_requested
var retry_button: Button
var _previous_mode := InputManager.Mode.GAMEPLAY
var _mode_revision := -1


func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    var dim := ColorRect.new()
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    dim.color = Color(0.015, 0.022, 0.035, .85)
    add_child(dim)
    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(center)
    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(660, 0)
    var style := StyleBoxFlat.new()
    style.bg_color = Color("172335")
    style.border_color = Color("b5a47d")
    style.set_border_width_all(1)
    style.set_content_margin_all(28)
    panel.add_theme_stylebox_override("panel", style)
    center.add_child(panel)
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 24)
    panel.add_child(column)
    var message := Label.new()
    message.text = "Не удалось записать сохранение.\nПрогресс остается в текущей игре.\nПовторите запись перед продолжением."
    message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    message.add_theme_font_size_override("font_size", 24)
    column.add_child(message)
    retry_button = Button.new()
    retry_button.text = "Повторить сохранение"
    retry_button.custom_minimum_size.y = 48
    retry_button.add_theme_font_size_override("font_size", 24)
    column.add_child(retry_button)
    retry_button.pressed.connect(func() -> void: retry_requested.emit())
    hide()


func open() -> void:
    if visible:
        return
    _previous_mode = InputManager.mode
    InputManager.set_mode(InputManager.Mode.UI)
    _mode_revision = InputManager.mode_revision
    show()
    retry_button.grab_focus()


func close() -> void:
    if not visible:
        return
    hide()
    if InputManager.mode == InputManager.Mode.UI and InputManager.mode_revision == _mode_revision:
        InputManager.set_mode(_previous_mode)
    _mode_revision = -1


func _input(event: InputEvent) -> void:
    if visible and event.is_action(&"pause"):
        get_viewport().set_input_as_handled()


func _exit_tree() -> void:
    close()
