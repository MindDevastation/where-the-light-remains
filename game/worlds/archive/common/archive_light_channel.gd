class_name ArchiveLightChannel
extends Node3D
## An emissive route and local pulse; independent of volumetrics and glow.

signal pulse_finished

enum Status {DORMANT, ACTIVE, COMPLETED}

@export var mesh_path := NodePath("Mesh")
@export var initial_state: Status = Status.DORMANT
@export var active_material: Material
@export var completed_material: Material
@export_range(0.05, 3.0, 0.05) var pulse_duration := 0.7

var status: Status:
    get: return _status
var pulse_running: bool:
    get: return _animation != null and _animation.is_running()

var _status: Status = Status.DORMANT
var _mesh_id := 0
var _revision := 0
var _animation: Tween
var _pulse: Variant


func _ready() -> void:
    set_process(false)
    if bindings_valid():
        _mesh_id = get_node(mesh_path).get_instance_id()
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


func bindings_valid() -> bool:
    if mesh_path.is_empty() or mesh_path.is_absolute() or not is_finite(pulse_duration) or pulse_duration <= 0.0:
        return false
    var visual := get_node_or_null(mesh_path) as MeshInstance3D
    return _owned_node(visual) and visual.mesh != null and \
            (_mesh_id == 0 or visual.get_instance_id() == _mesh_id) and visual.mesh.get_aabb().size.z > 0.0


func apply_state(next: Status, animated: bool = false) -> Error:
    if int(next) not in [Status.DORMANT, Status.ACTIVE, Status.COMPLETED]:
        return ERR_INVALID_PARAMETER
    if not is_inside_tree() or not bindings_valid():
        _stop_pulse()
        return ERR_UNCONFIGURED
    var changed := next != _status
    _stop_pulse()
    _status = next
    visible = next != Status.DORMANT
    var visual := get_node(mesh_path) as MeshInstance3D
    var material := completed_material if next == Status.COMPLETED and completed_material != null else active_material
    if material != null:
        visual.material_override = material
    if changed and animated and next != Status.DORMANT:
        return pulse()
    return OK


func pulse() -> Error:
    if not is_inside_tree() or not bindings_valid():
        _stop_pulse()
        return ERR_UNCONFIGURED
    if _status == Status.DORMANT:
        return ERR_UNAVAILABLE
    _stop_pulse()
    var visual := get_node(mesh_path) as MeshInstance3D
    var bounds := visual.mesh.get_aabb()
    var center := bounds.get_center()
    var marker := MeshInstance3D.new()
    marker.name = "RoutePulse"
    var sphere := SphereMesh.new()
    sphere.radius = 0.09
    sphere.height = 0.18
    sphere.radial_segments = 12
    sphere.rings = 6
    marker.mesh = sphere
    marker.material_override = visual.material_override
    marker.position = visual.transform * Vector3(center.x, bounds.end.y + 0.09, bounds.end.z)
    add_child(marker)
    _pulse = marker
    var destination := visual.transform * Vector3(center.x, bounds.end.y + 0.09, bounds.position.z)
    var revision := _revision
    _animation = create_tween()
    _animation.tween_property(marker, "position", destination, pulse_duration)
    _animation.tween_callback(func() -> void:
        if revision != _revision or not bindings_valid() or not _owned_node(marker):
            _stop_pulse()
            return
        marker.queue_free()
        _pulse = null
        _animation = null
        set_process(false)
        pulse_finished.emit()
    )
    set_process(true)
    return OK


func _process(_delta: float) -> void:
    if not bindings_valid() or not _owned_node(_pulse):
        _stop_pulse()


func _stop_pulse() -> void:
    _revision += 1
    if _animation != null:
        _animation.kill()
    _animation = null
    if _owned_node(_pulse):
        _pulse.queue_free()
    _pulse = null
    set_process(false)


func _exit_tree() -> void:
    _stop_pulse()
