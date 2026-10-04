class_name LightFocusPuzzle
extends Node3D
## Five authored stops; no optical physics and no serialized decorative pose.

signal state_changed(strength: float)
signal solved

@export_range(0, 4, 1) var solution := 2
@export var wheel_path: NodePath
@export var beam_path: NodePath
@export var interaction_path: NodePath
var _position := 0
var _available := false
var _locked := false

var position_index: int:
    get: return _position
var available: bool:
    get: return _available
var locked: bool:
    get: return _locked


func strength() -> float:
    return 1.0 - float(absi(_position - solution)) / 5.0


func cycle() -> Error:
    if solution not in range(5):
        return ERR_INVALID_PARAMETER
    if not _available or _locked:
        return ERR_UNAUTHORIZED
    _position = (_position + 1) % 5
    _refresh()
    state_changed.emit(strength())
    if _position == solution:
        _locked = true
        solved.emit()
    return OK


func restore_state(enabled: bool, completed: bool) -> Error:
    if solution not in range(5) or completed and not enabled:
        return ERR_INVALID_PARAMETER
    _available = enabled
    _locked = completed
    _position = solution if completed else 0
    _refresh()
    return OK


func _refresh() -> void:
    var wheel := get_node_or_null(wheel_path) as Node3D
    if wheel != null:
        wheel.rotation.z = _position * TAU / 5
    var beam := get_node_or_null(beam_path) as Node3D
    if beam != null:
        beam.visible = _available
        beam.scale.x = lerpf(1.8, 0.35, strength())
