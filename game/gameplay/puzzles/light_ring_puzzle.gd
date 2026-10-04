class_name LightRingPuzzle
extends Node3D
## Three discrete rings. Solution is an authored scene parameter, not save data.

signal state_changed(connected_segments: int)
signal solved

@export var solution := Vector3i(1, 2, 3)
@export var ring_paths: Array[NodePath] = []
@export var segment_paths: Array[NodePath] = []
var _positions := Vector3i.ZERO
var _locked := false

var positions: Vector3i:
    get: return _positions
var locked: bool:
    get: return _locked


func parameters_valid() -> bool:
    for index in 3:
        if solution[index] not in range(4):
            return false
    return true


func connected_segments() -> int:
    for index in 3:
        if _positions[index] != solution[index]:
            return index
    return 3


func rotate_ring(index: int) -> Error:
    if not parameters_valid() or index < 0 or index >= 3:
        return ERR_INVALID_PARAMETER
    if _locked:
        return ERR_UNAUTHORIZED
    _positions[index] = (_positions[index] + 1) % 4
    _refresh()
    state_changed.emit(connected_segments())
    if connected_segments() == 3:
        _locked = true
        solved.emit()
    return OK


func reset_local() -> Error:
    if _locked:
        return ERR_UNAUTHORIZED
    _positions = Vector3i.ZERO
    _refresh()
    state_changed.emit(connected_segments())
    return OK


func restore_completed(completed: bool) -> Error:
    if not parameters_valid():
        return ERR_INVALID_PARAMETER
    _locked = completed
    _positions = solution if completed else Vector3i.ZERO
    _refresh()
    return OK


func _refresh() -> void:
    for index in ring_paths.size():
        var ring := get_node_or_null(ring_paths[index]) as Node3D
        if ring != null and index < 3:
            ring.rotation.z = _positions[index] * PI / 2
    for index in segment_paths.size():
        var segment := get_node_or_null(segment_paths[index]) as Node3D
        if segment != null:
            segment.visible = index <= connected_segments()
