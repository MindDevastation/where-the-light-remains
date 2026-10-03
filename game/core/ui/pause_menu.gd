class_name PauseMenu
extends Control

signal exit_requested

@export var player_path: NodePath
@export var settings_path: NodePath
@onready var _player: FirstPersonPlayer = get_node(player_path)
@onready var _settings: SettingsMenu = get_node(settings_path)
var resume_button: Button
var settings_button: Button
var exit_button: Button
var _panel: PanelContainer
var _previous_mode := InputManager.Mode.GAMEPLAY


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    var dim := ColorRect.new()
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    dim.color = Color(0.015, 0.022, 0.035, .72)
    add_child(dim)
    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(center)
    _panel = PanelContainer.new()
    _panel.custom_minimum_size = Vector2(420, 0)
    var style := StyleBoxFlat.new()
    style.bg_color = Color("172335")
    style.border_color = Color("b5a47d")
    style.set_border_width_all(1)
    style.set_content_margin_all(28)
    _panel.add_theme_stylebox_override("panel", style)
    _panel.add_theme_font_size_override("font_size", 24)
    center.add_child(_panel)
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 18)
    _panel.add_child(column)
    var title := Label.new()
    title.text = "Пауза"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 32)
    column.add_child(title)
    resume_button = _button(column, "Продолжить")
    resume_button.pressed.connect(resume)
    settings_button = _button(column, "Настройки")
    settings_button.pressed.connect(func() -> void:
        _panel.hide()
        _settings.open()
    )
    exit_button = _button(column, "Выйти из игры")
    exit_button.pressed.connect(func() -> void: exit_requested.emit())
    _settings.closed.connect(func() -> void:
        if visible:
            _panel.show()
            settings_button.grab_focus()
    )
    InputManager.mode_changed.connect(_on_mode_changed)
    InputManager.pause_changed.connect(_on_pause_changed)
    hide()


func _button(parent: Node, text: String) -> Button:
    var button := Button.new()
    button.text = text
    button.custom_minimum_size.y = 46
    parent.add_child(button)
    return button


func open() -> bool:
    if visible or not is_instance_valid(_player) or not _player.active or get_tree().paused or not InputManager.can_look():
        return false
    if InputManager.mode not in [InputManager.Mode.GAMEPLAY, InputManager.Mode.LIMITED_LOOK]:
        return false
    _previous_mode = InputManager.mode
    show()
    _panel.show()
    InputManager.set_paused(true)
    InputManager.set_mode(InputManager.Mode.UI)
    resume_button.grab_focus()
    return true


func resume() -> void:
    _dismiss(true, true)


func _dismiss(restore_mode: bool, release_pause: bool) -> void:
    if not visible:
        return
    hide()
    if is_instance_valid(_settings):
        _settings.close()
    if restore_mode and InputManager.mode == InputManager.Mode.UI:
        InputManager.set_mode(_previous_mode)
    if release_pause:
        InputManager.set_paused(false)


func _on_mode_changed(mode: InputManager.Mode) -> void:
    if visible and mode != InputManager.Mode.UI:
        _dismiss(false, true)


func _on_pause_changed(paused: bool) -> void:
    if visible and not paused:
        _dismiss(true, false)


func _unhandled_key_input(event: InputEvent) -> void:
    if _settings.visible or not event is InputEventKey or not event.is_action_pressed(&"pause"):
        return
    if visible:
        resume()
        get_viewport().set_input_as_handled()
    elif open():
        get_viewport().set_input_as_handled()


func _exit_tree() -> void:
    # Do not strand simulation if an owned pause scene is removed by a caller.
    if visible:
        _dismiss(false, true)
