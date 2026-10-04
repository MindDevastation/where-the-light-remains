class_name ArchiveGate
extends Node3D
## Local presentation only. The world owns progression, audio and save IO.

signal opening_started
signal presentation_finished(status: Status)

enum Status {DORMANT, UNLOCKED, OPEN, COMPLETED}

@export var barrier_path := NodePath("Barrier")
@export var label_path := NodePath("Label")
@export var initial_state: Status = Status.DORMANT
@export_range(0.0, 3.0, 0.05) var opening_duration := 0.45
@export_range(0.1, 10.0, 0.1) var opening_height := 3.3

var status: Status:
    get: return _status
var animation_running: bool:
    get: return _animation != null and _animation.is_running()

var _status: Status = Status.DORMANT
var _binding_ids: Array[int] = []
var _revision := 0
var _animation: Tween
var _ghost: Variant


func _ready() -> void:
    set_process(false)
    if bindings_valid():
        for node in _bindings():
            _binding_ids.append(node.get_instance_id())
        apply_state(initial_state)


func _owned_node(value: Variant) -> bool:
    if not is_instance_valid(value) or not value is Node or is_queued_for_deletion():
        return false
    var current: Node = value
    while current != self:
        if current == null or current.is_queued_for_deletion():
            return false
        current = current.get_parent()
    return true


func _bindings() -> Array:
    var body := get_node_or_null(barrier_path) as StaticBody3D
    return [body, body.get_node_or_null("CollisionShape3D") if body != null else null,
            body.get_node_or_null("Mesh") if body != null else null]


func bindings_valid() -> bool:
    if barrier_path.is_empty() or barrier_path.is_absolute() or not is_finite(opening_duration) or \
            opening_duration < 0.0 or not is_finite(opening_height) or opening_height <= 0.0:
        return false
    var bound := _bindings()
    if not _owned_node(bound[0]) or not _owned_node(bound[1]) or not _owned_node(bound[2]):
        return false
    if not bound[1] is CollisionShape3D or bound[1].shape == null or \
            not bound[2] is MeshInstance3D or bound[2].mesh == null:
        return false
    if not _binding_ids.is_empty():
        for i in bound.size():
            if bound[i].get_instance_id() != _binding_ids[i]:
                return false
    return true


func apply_state(next: Status, animated: bool = false) -> Error:
    if int(next) not in [Status.DORMANT, Status.UNLOCKED, Status.OPEN, Status.COMPLETED]:
        return ERR_INVALID_PARAMETER
    if not is_inside_tree() or not bindings_valid():
        _stop_animation()
        return ERR_UNCONFIGURED
    var was_open := _status in [Status.OPEN, Status.COMPLETED]
    _stop_animation()
    _status = next
    var opened := next in [Status.OPEN, Status.COMPLETED]
    var bound := _bindings()
    var body: StaticBody3D = bound[0]
    var shape: CollisionShape3D = bound[1]
    var visual: MeshInstance3D = bound[2]
    # Deferred to the safe physics boundary, including trigger callbacks.
    shape.set_deferred("disabled", opened)
    body.visible = not opened
    var label := get_node_or_null(label_path) as Label3D
    if _owned_node(label):
        label.modulate = Color(0.34, 0.42, 0.50) if next == Status.DORMANT else Color(1.0, 0.80, 0.38)
    if not animated or not opened or was_open or opening_duration <= 0.0:
        return OK
    # The short visual animation cannot keep a logically open passage blocked.
    var ghost := MeshInstance3D.new()
    ghost.name = "OpeningVisual"
    ghost.mesh = visual.mesh
    ghost.material_override = visual.material_override
    ghost.transform = body.transform * visual.transform
    add_child(ghost)
    _ghost = ghost
    var revision := _revision
    _animation = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
    _animation.tween_property(ghost, "position:y", ghost.position.y + opening_height, opening_duration)
    _animation.tween_callback(func() -> void:
        if revision != _revision or not bindings_valid() or not _owned_node(ghost):
            _stop_animation()
            return
        ghost.queue_free()
        _ghost = null
        _animation = null
        set_process(false)
        presentation_finished.emit(_status)
    )
    set_process(true)
    # Last operation: a receiver may change state/remove this node synchronously.
    opening_started.emit()
    return OK


func _process(_delta: float) -> void:
    if not bindings_valid() or not _owned_node(_ghost):
        _stop_animation()


func _stop_animation() -> void:
    _revision += 1
    if _animation != null:
        _animation.kill()
    _animation = null
    if _owned_node(_ghost):
        _ghost.queue_free()
    _ghost = null
    set_process(false)


func _exit_tree() -> void:
    _stop_animation()
