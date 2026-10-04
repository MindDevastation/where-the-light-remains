extends Node3D
## New T019 behavior only. No accepted environment/gameplay preflight rerun.

const GATE := preload("res://worlds/archive/common/archive_gate.tscn")
const CHANNEL := preload("res://worlds/archive/common/archive_light_channel.tscn")
const PLAYER := preload("res://core/player/player.tscn")

var _failures: Array[String] = []
var _checks := 0
var _counts := {"starts": 0, "finishes": 0, "pulses": 0, "checkpoints": 0}
var _gates: Array[ArchiveGate] = []
var _channels: Array[ArchiveLightChannel] = []
var _player: FirstPersonPlayer


func _check(condition: bool, message: String) -> void:
    _checks += 1
    if not condition:
        _failures.append(message)
        push_error("ARCHIVE_ROUTE FAIL: " + message)


func _ready() -> void:
    get_tree().create_timer(100.0, true, false, true).timeout.connect(func() -> void:
        push_error("ARCHIVE_ROUTE FAIL: watchdog")
        get_tree().quit(1)
    )
    _run.call_deferred()


func _frames(count: int = 2) -> void:
    for i in count:
        await get_tree().physics_frame


func _file_hash(path: String) -> String:
    if not FileAccess.file_exists(path):
        return "absent"
    return FileAccess.get_sha256(path)


func _files() -> Dictionary:
    return {"primary": _file_hash(SaveManager.SAVE_PATH), "backup": _file_hash(SaveManager.BACKUP_PATH),
            "settings": _file_hash(SettingsManager.SETTINGS_PATH)}


func _attach_floor() -> void:
    var body := StaticBody3D.new()
    body.name = "Floor"
    body.position = Vector3(0, -0.5, 0)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(30, 1, 30)
    collision.shape = shape
    body.add_child(collision)
    add_child(body)


func _wire_gate(gate: ArchiveGate) -> void:
    gate.opening_started.connect(func() -> void: _counts["starts"] += 1)
    gate.presentation_finished.connect(func(_status: ArchiveGate.Status) -> void: _counts["finishes"] += 1)


func _walk(gate: ArchiveGate, expect_open: bool) -> void:
    var direction := -gate.global_basis.z
    _player.spawn_at(Transform3D(gate.global_basis, gate.global_position - direction * 2.8 + Vector3(0, 0.02, 0)))
    await _frames()
    var stayed_grounded := true
    for step in 24:
        await get_tree().physics_frame
        _player.velocity = direction * 2.6
        _player.velocity.y = -1.0
        _player.move_and_slide()
        stayed_grounded = stayed_grounded and _player.global_position.y > -0.02
    var distance := (_player.global_position - gate.global_position).dot(direction)
    _check(distance > 1.8 if expect_open else (distance < -0.43 and distance > -0.65),
            "actual capsule %s: state=%d distance=%.5f" % [gate.name, gate.status, distance])
    _check(stayed_grounded and _player.is_on_floor(), "supported floor across " + str(gate.name))
    _player.velocity = Vector3.ZERO
    print("ROUTE_PHYSICS: ", gate.name, " state=", gate.status, " forward_distance=", distance,
            " grounded=", stayed_grounded)


func _state_and_physics() -> void:
    _attach_floor()
    _player = PLAYER.instantiate() as FirstPersonPlayer
    add_child(_player)
    _player.set_active(false)
    for i in 5:
        var gate := GATE.instantiate() as ArchiveGate
        gate.name = "Gate%d" % (i + 1)
        gate.position.x = (i - 2) * 5.0
        _check(gate.bindings_valid(), "detached valid prefab %d" % i)
        _wire_gate(gate)
        add_child(gate)
        _gates.append(gate)
        var channel := CHANNEL.instantiate() as ArchiveLightChannel
        channel.position = gate.position + Vector3(0, 0, 3)
        _check(channel.bindings_valid(), "detached valid channel %d" % i)
        channel.pulse_finished.connect(func() -> void: _counts["pulses"] += 1)
        add_child(channel)
        _channels.append(channel)
    var shared_mesh: Mesh = _gates[0].get_node("Barrier/Mesh").mesh
    for gate in _gates:
        _check(gate.get_node("Barrier/Mesh").mesh == shared_mesh, "five instances share mesh resource")
    for state in [ArchiveGate.Status.DORMANT, ArchiveGate.Status.UNLOCKED, ArchiveGate.Status.OPEN, ArchiveGate.Status.COMPLETED]:
        for gate in _gates:
            _check(gate.apply_state(state) == OK, "instant four-state assignment")
        await _frames()
        for gate in _gates:
            var opened: bool = state in [ArchiveGate.Status.OPEN, ArchiveGate.Status.COMPLETED]
            _check(gate.get_node("Barrier/CollisionShape3D").disabled == opened and
                    gate.get_node("Barrier").visible == not opened, "collision and visibility agree")
            await _walk(gate, opened)
    # Rotated passage uses the exact same local prefab and unchanged capsule.
    var gate := _gates[2]
    gate.rotation.y = PI / 4.0
    _check(gate.apply_state(ArchiveGate.Status.DORMANT) == OK, "rotated close")
    await _frames()
    await _walk(gate, false)
    _check(gate.apply_state(ArchiveGate.Status.OPEN, true) == OK, "rotated animated open")
    await _frames()
    await _walk(gate, true)
    _check(_counts["starts"] == 1 and _counts["finishes"] == 1, "only actual live opening signals")
    print("ROUTE_CASE PASS: all five gates and four states, real capsule/floor, rotated route")


func _animation_and_restore() -> void:
    var gate := _gates[0]
    gate.opening_duration = 3.0
    var starts: int = _counts["starts"]
    var finishes: int = _counts["finishes"]
    _check(gate.apply_state(ArchiveGate.Status.DORMANT) == OK, "close before animation")
    _check(gate.apply_state(ArchiveGate.Status.OPEN, true) == OK and gate.animation_running, "owned opening begins")
    _check(gate.apply_state(ArchiveGate.Status.COMPLETED) == OK and not gate.animation_running,
            "instant completion cancels opening")
    await _frames(30)
    _check(_counts["starts"] == starts + 1 and _counts["finishes"] == finishes,
            "cancelled opening never emits later completion")
    _check(gate.get_node_or_null("OpeningVisual") == null, "cancelled visual removed")
    _check(gate.apply_state(ArchiveGate.Status.OPEN, true) == OK and not gate.animation_running,
            "same open domain never replays opening")
    _check(_counts["starts"] == starts + 1, "restore/open did not replay audio hook")
    var restored := GATE.instantiate() as ArchiveGate
    restored.initial_state = ArchiveGate.Status.COMPLETED
    restored.position.z = -8
    _wire_gate(restored)
    add_child(restored)
    await _frames()
    _check(restored.status == ArchiveGate.Status.COMPLETED and not restored.animation_running and
            restored.get_node("Barrier/CollisionShape3D").disabled, "new instance starts restored open")
    _check(_counts["starts"] == starts + 1 and _counts["finishes"] == finishes,
            "new restored instance emits no opening events")
    restored.queue_free()
    var channel := _channels[0]
    channel.pulse_duration = 3.0
    var pulses: int = _counts["pulses"]
    _check(channel.pulse() == ERR_UNAVAILABLE, "dormant route rejects pulse")
    _check(channel.apply_state(ArchiveLightChannel.Status.ACTIVE, true) == OK and channel.pulse_running,
            "changed active route pulses")
    _check(channel.apply_state(ArchiveLightChannel.Status.COMPLETED) == OK and not channel.pulse_running,
            "instant route restore cancels pending pulse")
    await _frames(30)
    _check(_counts["pulses"] == pulses and channel.get_node_or_null("RoutePulse") == null,
            "cancelled route has no late event/marker")
    _check(channel.visible and channel.get_node("Mesh").material_override == channel.completed_material,
            "completed warm route stays visible")
    _check(channel.apply_state(ArchiveLightChannel.Status.COMPLETED, true) == OK and not channel.pulse_running,
            "same completed state never pulses")
    channel.pulse_duration = 0.5
    _check(channel.pulse() == OK, "explicit completion pulse API")
    await _frames(8)
    _check(_counts["pulses"] == pulses + 1 and not channel.pulse_running, "explicit pulse completes once")
    print("ROUTE_CASE PASS: instant reload, interrupted opening/pulse and no duplicate signals")


func _lifetime_and_bindings() -> void:
    var gate := GATE.instantiate() as ArchiveGate
    gate.position = Vector3(0, 0, -10)
    gate.opening_duration = 3.0
    _wire_gate(gate)
    add_child(gate)
    var finishes: int = _counts["finishes"]
    _check(gate.apply_state(ArchiveGate.Status.OPEN, true) == OK, "detach fixture begins")
    remove_child(gate)
    _check(not gate.animation_running and gate.apply_state(ArchiveGate.Status.OPEN) == ERR_UNCONFIGURED,
            "detached node cancels/rejects application")
    gate.free()
    await _frames(30)
    _check(_counts["finishes"] == finishes, "detached tween has no callback")
    gate = GATE.instantiate() as ArchiveGate
    gate.position.z = -10
    gate.opening_duration = 3.0
    _wire_gate(gate)
    add_child(gate)
    _check(gate.apply_state(ArchiveGate.Status.OPEN, true) == OK, "reparent fixture begins")
    var foreign := Node3D.new()
    add_child(foreign)
    var ghost: MeshInstance3D = gate.get_node("OpeningVisual")
    ghost.reparent(foreign, true)
    var pose := ghost.global_transform
    await _frames(2)
    _check(is_instance_valid(ghost) and ghost.get_parent() == foreign and not ghost.is_queued_for_deletion() and
            ghost.global_transform.is_equal_approx(pose) and not gate.animation_running,
            "foreign visual is not moved or deleted")
    gate.queue_free()
    await _frames()
    _check(is_instance_valid(ghost) and ghost.get_parent() == foreign, "detaching owner preserves foreign visual")
    foreign.queue_free()
    var channel := CHANNEL.instantiate() as ArchiveLightChannel
    channel.pulse_duration = 3.0
    add_child(channel)
    _check(channel.apply_state(ArchiveLightChannel.Status.ACTIVE, true) == OK, "foreign pulse fixture begins")
    foreign = Node3D.new()
    add_child(foreign)
    var marker: MeshInstance3D = channel.get_node("RoutePulse")
    marker.reparent(foreign, true)
    pose = marker.global_transform
    await _frames(2)
    _check(is_instance_valid(marker) and marker.global_transform.is_equal_approx(pose) and
            not marker.is_queued_for_deletion() and not channel.pulse_running, "foreign pulse is preserved")
    channel.queue_free()
    foreign.queue_free()
    await _frames()
    gate = GATE.instantiate() as ArchiveGate
    var shape: Node = gate.get_node("Barrier/CollisionShape3D")
    shape.free()
    _check(not gate.bindings_valid(), "missing shape fails detached preparation")
    add_child(gate)
    _check(gate.apply_state(ArchiveGate.Status.OPEN) == ERR_UNCONFIGURED, "missing shape rejects progression visual")
    gate.queue_free()
    gate = GATE.instantiate() as ArchiveGate
    add_child(gate)
    shape = gate.get_node("Barrier/CollisionShape3D")
    shape.queue_free()
    _check(not gate.bindings_valid() and gate.apply_state(ArchiveGate.Status.OPEN) == ERR_UNCONFIGURED,
            "queued shape rejected before deletion")
    gate.queue_free()
    await _frames()
    gate = GATE.instantiate() as ArchiveGate
    add_child(gate)
    var old: CollisionShape3D = gate.get_node("Barrier/CollisionShape3D")
    gate.get_node("Barrier").remove_child(old)
    var replacement := CollisionShape3D.new()
    replacement.name = "CollisionShape3D"
    replacement.shape = old.shape
    gate.get_node("Barrier").add_child(replacement)
    old.free()
    _check(not gate.bindings_valid() and gate.apply_state(ArchiveGate.Status.OPEN) == ERR_UNCONFIGURED,
            "same-path replacement is a different binding")
    _check(gate.call("apply_state", 99) == ERR_INVALID_PARAMETER, "invalid gate enum is rejected")
    gate.queue_free()
    channel = CHANNEL.instantiate() as ArchiveLightChannel
    add_child(channel)
    var visual: MeshInstance3D = channel.get_node("Mesh")
    channel.remove_child(visual)
    var mesh_copy := MeshInstance3D.new()
    mesh_copy.name = "Mesh"
    mesh_copy.mesh = visual.mesh
    channel.add_child(mesh_copy)
    visual.free()
    _check(not channel.bindings_valid() and channel.apply_state(ArchiveLightChannel.Status.ACTIVE) == ERR_UNCONFIGURED,
            "channel replacement binding rejected")
    _check(channel.call("apply_state", 99) == ERR_INVALID_PARAMETER, "invalid channel enum rejected")
    channel.queue_free()
    await _frames()
    print("ROUTE_CASE PASS: detach/reparent lifetime, missing/queued/replaced bindings, invalid states")


func _candidate_and_reentrancy() -> void:
    var candidate := Node3D.new()
    candidate.process_mode = Node.PROCESS_MODE_DISABLED
    candidate.position.z = -10
    var gate := GATE.instantiate() as ArchiveGate
    candidate.add_child(gate)
    add_child(candidate)
    await _frames()
    var from := Vector3(0, 1.0, -8)
    var to := Vector3(0, 1.0, -12)
    var query := PhysicsRayQueryParameters3D.create(from, to, 1)
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    _check(gate.bindings_valid() and not hit.is_empty() and hit["collider"] == gate.get_node("Barrier"),
            "frozen candidate retains closed collider for router queries")
    _check(gate.apply_state(ArchiveGate.Status.OPEN) == OK, "frozen candidate instant restore")
    await _frames()
    _check(get_world_3d().direct_space_state.intersect_ray(query).is_empty() and not gate.animation_running,
            "frozen restored candidate clears collider without animation")
    candidate.queue_free()
    await _frames()
    gate = GATE.instantiate() as ArchiveGate
    gate.position.z = -10
    gate.opening_duration = 3.0
    _wire_gate(gate)
    add_child(gate)
    var finishes: int = _counts["finishes"]
    gate.opening_started.connect(func() -> void: gate.apply_state(ArchiveGate.Status.DORMANT))
    _check(gate.apply_state(ArchiveGate.Status.OPEN, true) == OK and gate.status == ArchiveGate.Status.DORMANT,
            "synchronous receiver's later state wins")
    await _frames(30)
    _check(not gate.animation_running and gate.get_node_or_null("OpeningVisual") == null and
            _counts["finishes"] == finishes, "reentrant cancellation has no stale completion")
    gate.queue_free()
    var channel := CHANNEL.instantiate() as ArchiveLightChannel
    channel.pulse_duration = 0.5
    add_child(channel)
    var visual := channel.get_node("Mesh") as MeshInstance3D
    visual.transform = Transform3D(Basis(Vector3.UP, PI / 4.0).scaled(Vector3(0.7, 1.1, 0.8)), Vector3(1.2, 0.03, 0.5))
    var bounds := visual.mesh.get_aabb()
    var center := bounds.get_center()
    var start := visual.transform * Vector3(center.x, bounds.end.y + 0.09, bounds.end.z)
    var finish := visual.transform * Vector3(center.x, bounds.end.y + 0.09, bounds.position.z)
    var endpoints: Array[Vector3] = []
    channel.pulse_finished.connect(func() -> void: endpoints.append(channel.get_node("RoutePulse").position))
    _check(channel.apply_state(ArchiveLightChannel.Status.ACTIVE) == OK and channel.pulse() == OK,
            "transformed forward pulse begins")
    _check(channel.get_node("RoutePulse").position.is_equal_approx(start), "forward pulse uses authored transformed bound")
    await _frames(8)
    _check(endpoints.size() == 1 and endpoints[0].is_equal_approx(finish), "forward transformed destination exact")
    _check(channel.pulse(true) == OK and channel.get_node("RoutePulse").position.is_equal_approx(finish),
            "return impulse starts at far end")
    await _frames(8)
    _check(endpoints.size() == 2 and endpoints[1].is_equal_approx(start) and channel.status == ArchiveLightChannel.Status.ACTIVE,
            "reverse impulse ends at near bound without progression change")
    channel.queue_free()
    await _frames()
    print("ROUTE_CASE PASS: frozen candidate, reentrant state ownership, transformed forward/return pulse")


func _run() -> void:
    var original := GameState.capture_save().to_dict()
    var files := _files()
    var dirty: bool = SaveManager.get("_dirty")
    var mode := InputManager.mode
    var revision := InputManager.mode_revision
    EventBus.checkpoint_reached.connect(func(_id: StringName) -> void: _counts["checkpoints"] += 1)
    var old_scale := Engine.time_scale
    Engine.time_scale = 8.0
    await _state_and_physics()
    await _animation_and_restore()
    await _lifetime_and_bindings()
    await _candidate_and_reentrancy()
    Engine.time_scale = old_scale
    _check(GameState.capture_save().to_dict() == original and SaveManager.get("_dirty") == dirty,
            "components never change logical state or dirty ownership")
    _check(_files() == files and InputManager.mode == mode and InputManager.mode_revision == revision,
            "actual slots/settings and input ownership unchanged")
    _check(_counts["checkpoints"] == 0, "presentation never emits progression events")
    if _failures.is_empty():
        print("ARCHIVE_ROUTE PASS: ", _checks, " assertions; five prefab instances, actual capsule/floor,")
        print("instant restore, pulse, ownership/lifetime and binding rejection; globals/physical files unchanged")
    get_tree().quit(0 if _failures.is_empty() else 1)
