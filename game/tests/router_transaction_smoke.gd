extends Node
## Actual isolated checkpoint files, authored modes and physics rollback.

class FixtureWriter extends "res://autoload/save_manager.gd":
    var directory: String
    var fail_prepare := false

    func _primary_path() -> String:
        return directory + "/save.json"

    func _backup_path() -> String:
        return directory + "/backup.json"

    func _prepare_file(path: String, bytes: PackedByteArray) -> Dictionary:
        return {"error": ERR_FILE_CANT_WRITE, "path": ""} if fail_prepare else super._prepare_file(path, bytes)

class FixtureRouter extends "res://autoload/scene_router.gd":
    var writer: FixtureWriter
    var order: Array[String] = []
    var checkpoint_locked := false

    func _flush_checkpoint() -> Error:
        order.append("checkpoint")
        checkpoint_locked = InputManager.mode == InputManager.Mode.DISABLED and not _player.active and _world_slot.get_child(0).process_mode == Node.PROCESS_MODE_DISABLED
        return writer.flush_if_dirty()

    func _thread_request(path: String) -> Error:
        order.append("preload")
        return super._thread_request(path)

var _failures: Array[String] = []
var _done := false
var _error: Error = FAILED
var _events := 0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().create_timer(30.0, true).timeout.connect(func() -> void:
        push_error("ROUTER_TRANSACTION FAIL: timeout")
        get_tree().quit(1)
    )
    _run.call_deferred()

func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
        push_error("ROUTER_TRANSACTION FAIL: " + message)

func _launch(router: Node, id: StringName) -> void:
    _done = false
    _error = await router.request_registered_stage(id)
    _done = true

func _wait_route() -> void:
    while not _done:
        await get_tree().process_frame

func _wait_committed(router: Node) -> void:
    while not _done and not router.get("_route").get("committed", false):
        await get_tree().process_frame

func _files() -> Array:
    var hashes := []
    for path in [SaveManager.SAVE_PATH, SaveManager.BACKUP_PATH, SettingsManager.SETTINGS_PATH]:
        hashes.append(FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "absent")
    return hashes

func _run() -> void:
    if DisplayServer.get_name() == "headless":
        get_tree().root.size = Vector2i(1280, 720)
    var original := GameState.capture_save()
    var hashes := _files()
    var dirty: bool = SaveManager.get("_dirty")
    var audio := [AudioDirector.current_stage, AudioDirector.current_state]
    var writer := FixtureWriter.new()
    writer.directory = "user://router_checkpoint_" + str(OS.get_process_id()) + "_" + str(Time.get_ticks_usec())
    _check(DirAccess.make_dir_absolute(ProjectSettings.globalize_path(writer.directory)) == OK, "Isolated checkpoint directory")
    _check(writer.write_save(original) == OK, "Seed valid primary and backup")
    var initial_hash := FileAccess.get_sha256(writer._primary_path())
    var game := preload("res://core/game_root/game_root.tscn").instantiate()
    add_child(game)
    var slot: Node3D = game.get_node("WorldSlot")
    var player: FirstPersonPlayer = game.get_node("PlayerContainer/Player")
    var fade: FadeOverlay = game.get_node("TransitionLayer/FadeOverlay")
    var router := FixtureRouter.new()
    router.writer = writer
    add_child(router)
    router.bind_world_slot(slot, player, fade)
    router.fade_duration = .06
    for spec in [[&"s01_fixture", "route_world_a"], [&"s02_fixture", "route_world_b"], [&"s05_fixture", "route_world_modes"], [&"s06_fixture", "route_world_no_floor"], [&"s07_fixture", "route_world_slope"], [&"s08_fixture", "route_world_nested"]]:
        var definition := StageDefinition.new()
        definition.stage_id = spec[0]
        definition.scene_path = "res://tests/fixtures/" + spec[1] + ".tscn"
        _check(router.register_stage(definition) == OK, "Fixture stage registration")
    EventBus.stage_changed.connect(func(_id: StringName) -> void: _events += 1)
    _check(await router.request_registered_stage(&"s01_fixture") == OK, "Initial world")
    if slot.get_child_count() != 1:
        get_tree().quit(1)
        return
    var first := slot.get_child(0)
    var before := GameState.capture_save().to_dict()
    var events := _events
    writer.mark_dirty()
    writer.fail_prepare = true
    router.order.clear()
    SaveManager.set("_dirty", false)
    _check(await router.request_registered_stage(&"s02_fixture", null, true) == ERR_FILE_CANT_WRITE, "Checkpoint failure propagated")
    _check(router.checkpoint_locked and router.order == ["checkpoint"] and slot.get_child(0) == first and player.active and first.process_mode == Node.PROCESS_MODE_INHERIT, "Checkpoint failure precedes preload and restores callbacks/player")
    _check(GameState.capture_save().to_dict() == before and writer.get("_dirty") and not SaveManager.get("_dirty") and _events == events and FileAccess.get_sha256(writer._primary_path()) == initial_hash and FileAccess.get_sha256(writer._backup_path()) == initial_hash, "Failed checkpoint preserves files, dirty and event/state")
    writer.fail_prepare = false
    router.order.clear()
    _check(await router.request_registered_stage(&"s02_fixture", null, true) == OK, "Real successful checkpoint transition")
    _check(router.checkpoint_locked and router.order == ["checkpoint", "preload"] and not writer.get("_dirty") and writer.read_save()["data"].to_dict() == before and FileAccess.get_sha256(writer._backup_path()) == initial_hash, "Old logical state checkpointed before preload; backup/dirty ordering")
    _check(SaveManager.get("_dirty") and _events == events + 1, "Accepted normal transition dirties once and emits one stage event")
    var second := slot.get_child(0)
    before = GameState.capture_save().to_dict()
    events = _events
    SaveManager.set("_dirty", false)
    router.fade_duration = .2
    _launch(router, &"s05_fixture")
    await _wait_committed(router)
    var candidate: Variant = slot.get_child(0)
    _check(not _done and candidate != second and not player.active and candidate.get_node("Callback").process_ticks == 0, "Candidate callbacks frozen through fade-out")
    var rigid: RigidBody3D = candidate.get_node("Rigid")
    for frame in 3:
        await get_tree().physics_frame
    _check(is_equal_approx(rigid.position.y, 2.0) and rigid.disable_mode == CollisionObject3D.DISABLE_MODE_MAKE_STATIC, "Rigid body physically static during preparation")
    router.cancel_transition()
    await _wait_route()
    _check(_error == ERR_SKIP and slot.get_child(0) == second and GameState.capture_save().to_dict() == before and not SaveManager.get("_dirty") and _events == events and AudioDirector.current_stage == &"s02_fixture", "Post-commit cancellation rolls back state/audio/dirty/event")
    for frame in 10:
        await get_tree().physics_frame
    _check(player.active and player.global_position.y >= -.01 and player.is_on_floor(), "Rollback physics settles before active player resumes")

    _check(await router.request_registered_stage(&"s05_fixture") == OK, "Authored disabled overlap colliders remain absent")
    var modes := slot.get_child(0)
    _check(modes.get_node("Callback").process_mode == Node.PROCESS_MODE_ALWAYS and modes.get_node("Callback/InheritedCallback").process_mode == Node.PROCESS_MODE_INHERIT and modes.get_node("DisabledBlocker").process_mode == Node.PROCESS_MODE_DISABLED and modes.get_node("DisabledBlocker").disable_mode == CollisionObject3D.DISABLE_MODE_REMOVE and modes.get_node("DisabledGroup/InheritedBlocker").disable_mode == CollisionObject3D.DISABLE_MODE_REMOVE and modes.get_node("Rigid").disable_mode == CollisionObject3D.DISABLE_MODE_REMOVE, "Exact child/collider authored modes restored")
    for frame in 10:
        await get_tree().physics_frame
    _check(modes.get_node("Callback").physics_ticks > 0 and modes.get_node("Callback/InheritedCallback").physics_ticks > 0 and modes.get_node("Rigid").position.y < 2.0, "Callbacks and rigid-body simulation resume only after acceptance")
    var ticks: int = modes.get_node("Callback").process_ticks
    _launch(router, &"s02_fixture")
    for frame in 3:
        await get_tree().process_frame
    _check(modes.get_node("Callback").process_ticks == ticks, "Old ALWAYS callbacks frozen during transition")
    router.cancel_transition()
    await _wait_route()
    _check(_error == ERR_SKIP and modes.get_node("Callback").process_mode == Node.PROCESS_MODE_ALWAYS, "Early cancellation restores old explicit process mode")
    for id in [&"s06_fixture", &"s07_fixture"]:
        _check(await router.request_registered_stage(id) == ERR_INVALID_DATA and slot.get_child(0) == modes, "Absent/steep support rejected with original world intact")
    slot.position = Vector3(10, 0, -4)
    slot.rotation.y = PI / 2
    _check(await router.request_registered_stage(&"s08_fixture") == OK, "Nested and transformed world/slot physical spawn")
    var expected := slot.global_transform * Transform3D(Basis.IDENTITY, Vector3(3.5, .004, 3))
    _check(player.global_transform.is_equal_approx(expected), "Exact composed nested feet transform")
    router.unbind_world_slot(slot)
    game.queue_free()
    router.queue_free()
    await get_tree().process_frame
    for filename in DirAccess.get_files_at(writer.directory):
        _check(not filename.contains(".tmp_"), "No checkpoint temp leaks")
        _check(DirAccess.remove_absolute(ProjectSettings.globalize_path(writer.directory + "/" + filename)) == OK, "Checkpoint file cleanup")
    _check(DirAccess.remove_absolute(ProjectSettings.globalize_path(writer.directory)) == OK, "Checkpoint directory cleanup")
    writer.free()
    GameState.apply_save(original)
    SaveManager.set("_dirty", dirty)
    AudioDirector.current_stage = audio[0]
    AudioDirector.current_state = audio[1]
    InputManager.set_mode(InputManager.Mode.UI)
    _check(_files() == hashes, "Production save/settings files preserved")
    if _failures.is_empty():
        print("ROUTER_TRANSACTION PASS: real checkpoint failure/success and backup/dirty order; post-commit audio/state/event rollback; physics settling; disabled/inherited colliders; callbacks/rigid-body modes; absent/steep support; nested/slot spawn")
    get_tree().quit(0 if _failures.is_empty() else 1)
