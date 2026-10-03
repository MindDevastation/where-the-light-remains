class_name FirstPersonPlayer
extends CharacterBody3D

signal focus_changed(target: InteractionTarget)
signal active_changed(active: bool)

@export_range(0.1, 6.0, 0.1) var walk_speed := 2.6
@export_range(0.1, 4.0, 0.1) var interaction_reach := 2.5
@export_flags_3d_physics var interaction_mask := 3

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D

var active: bool:
    get: return _active
var focused_target: InteractionTarget
var _active := false
var _interaction_pending := false


func _ready() -> void:
    InputManager.mode_changed.connect(_on_mode_changed)
    InputManager.availability_changed.connect(_on_control_changed)
    EventBus.settings_changed.connect(_apply_settings)
    _apply_settings()
    set_active(false)


func set_active(value: bool) -> void:
    _active = value
    _interaction_pending = false
    velocity = Vector3.ZERO
    set_physics_process(value)
    if value:
        camera.make_current()
    elif camera.is_current():
        camera.clear_current(false)
    _set_focus(null)
    active_changed.emit(value)


func spawn_at(feet_transform: Transform3D) -> void:
    global_transform = feet_transform
    head.rotation = Vector3.ZERO
    velocity = Vector3.ZERO
    _interaction_pending = false
    _set_focus(null)
    reset_physics_interpolation()


func _physics_process(delta: float) -> void:
    var movement := InputManager.get_movement_vector()
    var direction := global_basis * Vector3(movement.x, 0, movement.y)
    direction.y = 0.0
    # Spawn transform must be upright with unit scale; preserve analog length.
    velocity.x = direction.x * walk_speed
    velocity.z = direction.z * walk_speed
    if not is_on_floor():
        velocity += get_gravity() * delta
    elif velocity.y < 0:
        velocity.y = 0.0
    move_and_slide()
    var target: InteractionTarget = _pick_target() if InputManager.can_interact() else null
    _set_focus(target)
    if _interaction_pending:
        _interaction_pending = false
        if is_instance_valid(target) and InputManager.can_interact():
            target.interact(self)
            # The callback may consume/free its component synchronously.
            if not is_instance_valid(target) or not target.is_available_to(self):
                _set_focus(null)


func _unhandled_input(event: InputEvent) -> void:
    if not _active:
        return
    if event is InputEventMouseMotion and InputManager.can_look():
        var motion: Vector2 = event.screen_relative
        var sensitivity: float = SettingsManager.mouse_sensitivity * 0.004
        rotate_y(-motion.x * sensitivity)
        var sign_y := 1.0 if SettingsManager.invert_y else -1.0
        head.rotation.x = clampf(head.rotation.x + motion.y * sensitivity * sign_y, deg_to_rad(-85), deg_to_rad(85))
    elif event.is_action_pressed(&"interact") and InputManager.can_interact():
        _interaction_pending = true
        get_viewport().set_input_as_handled()


func _pick_target() -> InteractionTarget:
    var from := camera.global_position
    var to := from - camera.global_basis.z * interaction_reach
    var query := PhysicsRayQueryParameters3D.create(from, to, interaction_mask, [get_rid()])
    query.collide_with_areas = true
    query.hit_from_inside = true
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    if hit.is_empty():
        return null
    var collider: Node = hit["collider"]
    if collider.is_queued_for_deletion():
        return null
    var target := collider.get_node_or_null("InteractionTarget") as InteractionTarget
    return target if is_instance_valid(target) and target.is_available_to(self) else null


func _set_focus(target: InteractionTarget) -> void:
    if focused_target == target:
        return
    focused_target = target
    focus_changed.emit(target)


func _on_mode_changed(_mode: InputManager.Mode) -> void:
    _on_control_changed()


func _on_control_changed() -> void:
    _interaction_pending = false
    if not InputManager.can_move():
        velocity.x = 0.0
        velocity.z = 0.0
    if not InputManager.can_interact():
        _set_focus(null)


func _apply_settings() -> void:
    camera.fov = SettingsManager.fov
