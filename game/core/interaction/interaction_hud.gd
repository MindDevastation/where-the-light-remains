class_name InteractionHUD
extends Control
## Minimal reticle/prompt; visual polish is a separate UI art task.

@export var player_path: NodePath
@onready var _player: FirstPersonPlayer = get_node(player_path)
@onready var _prompt: Label = $Prompt


func _ready() -> void:
    _player.focus_changed.connect(_on_focus_changed)
    _player.active_changed.connect(_on_active_changed)
    InputManager.mode_changed.connect(_on_mode_changed)
    InputManager.availability_changed.connect(_refresh)
    _refresh()


func _on_focus_changed(_target: InteractionTarget) -> void:
    _refresh()


func _on_active_changed(_active: bool) -> void:
    _refresh()


func _on_mode_changed(_mode: InputManager.Mode) -> void:
    _refresh()


func _refresh() -> void:
    if not is_instance_valid(_player):
        hide()
        _prompt.text = ""
        _prompt.hide()
        return
    visible = _player.active and InputManager.can_interact()
    var target := _player.focused_target
    _prompt.text = "E · " + target.prompt if is_instance_valid(target) else ""
    _prompt.visible = not _prompt.text.is_empty()
