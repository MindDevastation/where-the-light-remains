extends Node

var _world_slot: Node3D
var _transition_in_progress := false
var _stage_definitions: Dictionary = {}
var _preload_in_progress := false
var _preload_path := ""
var _preload_cancelled := false
var _preload_abandoned := false
var _player: FirstPersonPlayer
var _fade: FadeOverlay
var _binding_revision := 0
var _route: Dictionary = {}
var fade_duration := .25


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
    if _preload_abandoned:
        _drain_preload()
    if _transition_in_progress and not _route.is_empty() and not _route_owned():
        cancel_transition()


func register_stage(definition: StageDefinition) -> Error:
    if _transition_in_progress or _preload_in_progress:
        return ERR_BUSY
    if definition == null:
        return ERR_INVALID_DATA
    var validated := definition.copy_validated()
    if validated == null:
        return ERR_INVALID_DATA
    if _stage_definitions.has(validated.stage_id):
        return ERR_ALREADY_EXISTS
    _stage_definitions[validated.stage_id] = validated
    return OK


func unregister_stage(stage_id: StringName) -> Error:
    if _transition_in_progress or _preload_in_progress:
        return ERR_BUSY
    return OK if _stage_definitions.erase(stage_id) else ERR_DOES_NOT_EXIST


func stage_definition(stage_id: StringName) -> StageDefinition:
    var definition: StageDefinition = _stage_definitions.get(stage_id)
    return definition.copy_validated() if definition != null else null


func preload_stage(stage_id: StringName) -> Dictionary:
    var failure := {"error": ERR_INVALID_DATA, "scene": null}
    if _transition_in_progress or _preload_in_progress:
        failure["error"] = ERR_BUSY
        return failure
    var definition := stage_definition(stage_id)
    if definition == null:
        return failure
    return await _preload_definition(definition)


func _preload_definition(definition: StageDefinition) -> Dictionary:
    var failure := {"error": ERR_INVALID_DATA, "scene": null}
    _preload_in_progress = true
    _preload_cancelled = false
    _preload_abandoned = false
    var error := _thread_request(definition.scene_path)
    if error != OK:
        _clear_preload()
        failure["error"] = error
        return failure
    _preload_path = definition.scene_path
    var deadline := Time.get_ticks_msec() + _preload_timeout_msec()
    while true:
        # Godot has no public threaded-load cancellation API. Release the
        # caller promptly, retain ownership and collect the terminal result
        # from _process without ever blocking on an in-progress request.
        if _preload_cancelled or (not _route.is_empty() and not _route_owned()):
            _preload_abandoned = true
            _drain_preload()
            failure["error"] = ERR_SKIP
            return failure
        var status := _thread_status(_preload_path)
        if status == ResourceLoader.THREAD_LOAD_LOADED:
            var scene := _thread_get(_preload_path) as PackedScene
            _clear_preload()
            return {"error": OK if scene != null else ERR_INVALID_DATA, "scene": scene}
        if status != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
            _drain_preload()
            failure["error"] = ERR_CANT_OPEN
            return failure
        if Time.get_ticks_msec() >= deadline:
            _preload_abandoned = true
            failure["error"] = ERR_TIMEOUT
            return failure
        await get_tree().process_frame
    return failure


func _drain_preload() -> void:
    if _preload_path.is_empty():
        return
    var status := _thread_status(_preload_path)
    if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
        return
    if status in [ResourceLoader.THREAD_LOAD_LOADED, ResourceLoader.THREAD_LOAD_FAILED]:
        # FAILED also owns a user load token in the verified 4.7.2 engine.
        _thread_get(_preload_path)
    _clear_preload()


func _clear_preload() -> void:
    _preload_path = ""
    _preload_in_progress = false
    _preload_cancelled = false
    _preload_abandoned = false


func _thread_request(path: String) -> Error:
    return ResourceLoader.load_threaded_request(path, "PackedScene", false, ResourceLoader.CACHE_MODE_REUSE)


func _thread_status(path: String) -> ResourceLoader.ThreadLoadStatus:
    return ResourceLoader.load_threaded_get_status(path)


func _thread_get(path: String) -> Resource:
    return ResourceLoader.load_threaded_get(path)


func _preload_timeout_msec() -> int:
    return 15000


func bind_world_slot(slot: Node3D, player: FirstPersonPlayer = null, fade: FadeOverlay = null) -> void:
    if slot != _world_slot or (player != null and player != _player) or (fade != null and fade != _fade):
        _binding_revision += 1
        cancel_transition()
    _world_slot = slot
    if player != null:
        _player = player
    if fade != null:
        _fade = fade


func unbind_world_slot(slot: Node3D) -> void:
    if slot == _world_slot:
        _binding_revision += 1
        cancel_transition()
        _world_slot = null
        _player = null
        _fade = null


func cancel_transition() -> void:
    if _preload_in_progress:
        _preload_cancelled = true
    if _route.is_empty():
        return
    _route["cancelled"] = true
    var fade: Variant = _route["fade"]
    if is_instance_valid(fade) and fade.busy:
        fade.cancel()


func _route_owned() -> bool:
    if _route.is_empty() or _route["cancelled"] or _route["binding"] != _binding_revision:
        return false
    if InputManager.mode != InputManager.Mode.DISABLED or InputManager.mode_revision != _route["input_revision"]:
        return false
    for node in [_route["slot"], _route["player"], _route["fade"]]:
        if not is_instance_valid(node) or not node.is_inside_tree():
            return false
    return true


func request_registered_stage(stage_id: StringName, saved: SaveGame = null, checkpoint_before: bool = false) -> Error:
    # Runtime prototype. Full rollback/physics/lifetime acceptance remains open.
    if _transition_in_progress or _preload_in_progress or get_tree().paused:
        return ERR_BUSY
    if not is_instance_valid(_world_slot) or not is_instance_valid(_player) or not is_instance_valid(_fade):
        return ERR_UNCONFIGURED
    if not _world_slot.is_inside_tree() or not _player.is_inside_tree() or not _fade.is_inside_tree():
        return ERR_UNCONFIGURED
    if _fade.busy or _world_slot.get_child_count() > 1 or not is_finite(fade_duration) or fade_duration < 0:
        return ERR_BUSY
    var definition := stage_definition(stage_id)
    var original := GameState.capture_save()
    if definition == null or original == null:
        return ERR_INVALID_DATA
    var target := original.copy_validated() if saved == null else saved.copy_validated()
    if target == null:
        return ERR_INVALID_DATA
    if saved == null:
        target.stage_id = stage_id
        target.checkpoint_id = &""
    if target.stage_id != stage_id or target.copy_validated() == null:
        return ERR_INVALID_DATA
    _route = {"slot": _world_slot, "player": _player, "fade": _fade,
        "binding": _binding_revision, "cancelled": false, "state": original,
        "old_worlds": _world_slot.get_children(), "candidate": null,
        "committed": false, "detached": false, "mode": InputManager.mode,
        "player_active": _player.active, "player_transform": _player.global_transform,
        "head_rotation": _player.head.rotation, "audio_stage": AudioDirector.current_stage,
        "audio_state": AudioDirector.current_state}
    _transition_in_progress = true
    InputManager.set_mode(InputManager.Mode.DISABLED)
    _route["input_revision"] = InputManager.mode_revision
    _player.set_active(false)
    if checkpoint_before:
        var checkpoint_error := _flush_checkpoint()
        if checkpoint_error != OK:
            return _complete_route(checkpoint_error)
    var preloaded := await _preload_definition(definition)
    if not _route_owned():
        return _complete_route(ERR_SKIP)
    if preloaded["error"] != OK:
        return _complete_route(preloaded["error"])
    var node: Node = preloaded["scene"].instantiate()
    var candidate := node as WorldScene
    if candidate == null:
        node.free()
        return _complete_route(ERR_INVALID_DATA)
    _route["candidate"] = candidate
    var prepared := candidate.prepare_state(target)
    if prepared["error"] != OK:
        return _complete_route(prepared["error"])
    var spawn: Transform3D = _world_slot.global_transform * prepared["spawn"]
    if not WorldScene.valid_spawn_transform(spawn):
        return _complete_route(ERR_INVALID_DATA)
    if not await _fade.fade_to(1.0, fade_duration) or not _route_owned():
        return _complete_route(ERR_SKIP)
    _route["process_modes"] = {}
    _route["collision_disable_modes"] = {}
    _freeze_candidate(candidate)
    candidate.hide()
    for old in _route["old_worlds"]:
        _world_slot.remove_child(old)
    _route["detached"] = true
    _world_slot.add_child(candidate)
    _freeze_candidate(candidate)
    await get_tree().physics_frame
    await get_tree().physics_frame
    if not _route_owned():
        return _complete_route(ERR_SKIP)
    if definition.player_active and not _spawn_clear(spawn):
        return _complete_route(ERR_INVALID_DATA)
    var apply_error := candidate.apply_logical_state(prepared["state"])
    if apply_error != OK:
        return _complete_route(apply_error)
    if GameState.apply_save(target) != OK:
        return _complete_route(ERR_INVALID_DATA)
    _route["committed"] = true
    _player.spawn_at(spawn)
    AudioDirector.set_stage_audio(stage_id)
    candidate.show()
    if not await _fade.fade_to(0.0, fade_duration) or not _route_owned():
        return _complete_route(ERR_SKIP)
    for child in _route["process_modes"]:
        if is_instance_valid(child) and (child == candidate or candidate.is_ancestor_of(child)):
            child.process_mode = _route["process_modes"][child]
    for collider_node in _route["collision_disable_modes"]:
        if is_instance_valid(collider_node) and candidate.is_ancestor_of(collider_node):
            collider_node.disable_mode = _route["collision_disable_modes"][collider_node]
    _player.set_active(definition.player_active)
    if saved == null:
        SaveManager.mark_dirty()
    var error := _complete_route(OK, definition.input_mode)
    EventBus.stage_changed.emit(stage_id)
    return error


func _flush_checkpoint() -> Error:
    return SaveManager.flush_if_dirty()


func _freeze_candidate(candidate: WorldScene) -> void:
    var pending: Array = [candidate]
    while not pending.is_empty():
        var child: Variant = pending.pop_back()
        if not is_instance_valid(child):
            continue
        if not _route["process_modes"].has(child) or child.process_mode != Node.PROCESS_MODE_DISABLED:
            _route["process_modes"][child] = child.process_mode
        if child is CollisionObject3D:
            if not _route["collision_disable_modes"].has(child):
                _route["collision_disable_modes"][child] = child.disable_mode
            child.disable_mode = CollisionObject3D.DISABLE_MODE_MAKE_STATIC if child is RigidBody3D else CollisionObject3D.DISABLE_MODE_KEEP_ACTIVE
        child.process_mode = Node.PROCESS_MODE_DISABLED
        pending.append_array(child.get_children())


func _spawn_clear(spawn: Transform3D) -> bool:
    var collider: CollisionShape3D = _player.get_node("CollisionShape3D")
    if collider.shape == null:
        return false
    var query := PhysicsShapeQueryParameters3D.new()
    query.shape = collider.shape
    query.transform = spawn * collider.transform
    query.collision_mask = _player.collision_mask
    query.exclude = [_player.get_rid()]
    var space := _player.get_world_3d().direct_space_state
    var overlaps := space.intersect_shape(query, 1)
    if not overlaps.is_empty():
        return false
    var ground := PhysicsRayQueryParameters3D.create(spawn.origin + Vector3.UP * .02, spawn.origin - Vector3.UP * _player.floor_snap_length, _player.collision_mask, [_player.get_rid()])
    ground.hit_from_inside = true
    var hit := space.intersect_ray(ground)
    return not hit.is_empty() and hit["normal"].dot(Vector3.UP) >= cos(_player.floor_max_angle)


func _complete_route(error: Error, final_mode: InputManager.Mode = InputManager.Mode.UI) -> Error:
    var route := _route
    if route.is_empty():
        _transition_in_progress = false
        return error
    # Keep potentially freed references as Variants until is_instance_valid;
    # typed assignment itself raises before the lifetime guard can run.
    var slot: Variant = route["slot"]
    var player: Variant = route["player"]
    var fade: Variant = route["fade"]
    var candidate: Variant = route["candidate"]
    if error != OK:
        if is_instance_valid(candidate):
            if candidate.get_parent() != null:
                candidate.get_parent().remove_child(candidate)
            candidate.queue_free()
        for old in route["old_worlds"]:
            if is_instance_valid(old) and old.get_parent() == null:
                if is_instance_valid(slot) and slot.is_inside_tree():
                    slot.add_child(old)
                else:
                    old.queue_free()
        if route["committed"]:
            GameState.apply_save(route["state"])
            AudioDirector.current_stage = route["audio_stage"]
            AudioDirector.current_state = route["audio_state"]
        if is_instance_valid(player) and player.is_inside_tree():
            player.spawn_at(route["player_transform"])
            player.head.rotation = route["head_rotation"]
            player.set_active(route["player_active"])
        final_mode = route["mode"] if is_instance_valid(slot) and slot.is_inside_tree() else InputManager.Mode.UI
    else:
        for old in route["old_worlds"]:
            if is_instance_valid(old):
                old.queue_free()
    if is_instance_valid(fade):
        fade.clear()
    _route = {}
    _transition_in_progress = false
    if InputManager.mode == InputManager.Mode.DISABLED and InputManager.mode_revision == route["input_revision"]:
        InputManager.set_mode(final_mode)
    return error

func request_world_scene(scene: PackedScene, stage_id: StringName) -> Error:
    var definition := stage_definition(stage_id)
    if scene == null or definition == null or scene.resource_path != definition.scene_path:
        return ERR_INVALID_DATA
    return await request_registered_stage(stage_id)
