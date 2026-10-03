extends Node
## Initial runtime prototype checks. Full physics/checkpoint/lifetime QA is open.
var _failures: Array[String] = []
var _done := false
var _last_error: Error = FAILED


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().create_timer(30.0, true).timeout.connect(func() -> void:
        push_error("ROUTER_PIPELINE FAIL: timeout")
        get_tree().quit(1)
    )
    _run.call_deferred()


func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
        push_error("ROUTER_PIPELINE FAIL: " + message)


func _launch(id: StringName) -> void:
    _done = false
    _last_error = await SceneRouter.request_registered_stage(id)
    _done = true


func _wait_route() -> void:
    while not _done:
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
    var duration: float = SceneRouter.fade_duration
    SceneRouter.fade_duration = .04
    for spec in [[&"s01_fixture", "res://tests/fixtures/route_world_a.tscn"], [&"s02_fixture", "res://tests/fixtures/route_world_b.tscn"], [&"s03_fixture", "res://tests/fixtures/route_world_failed.tscn"], [&"s04_fixture", "res://tests/fixtures/route_world_blocked.tscn"]]:
        var definition := StageDefinition.new()
        definition.stage_id = spec[0]
        definition.scene_path = spec[1]
        _check(SceneRouter.register_stage(definition) == OK, "Fixture registration")
    var game := preload("res://core/game_root/game_root.tscn").instantiate()
    add_child(game)
    var slot: Node3D = game.get_node("WorldSlot")
    var player: FirstPersonPlayer = game.get_node("PlayerContainer/Player")
    await get_tree().process_frame
    _launch(&"s01_fixture")
    _check(await SceneRouter.request_registered_stage(&"s02_fixture") == ERR_BUSY, "Overlapping route rejected")
    _check(SceneRouter.unregister_stage(&"s01_fixture") == ERR_BUSY, "Registry stable during route")
    await _wait_route()
    _check(_last_error == OK and slot.get_child_count() == 1 and GameState.current_stage_id == &"s01_fixture" and player.active and InputManager.mode == InputManager.Mode.GAMEPLAY, "First world/state/player/fade/input commit")
    if _last_error != OK or slot.get_child_count() != 1:
        get_tree().quit(1)
        return
    var first := slot.get_child(0)
    var target := SaveGame.new()
    target.stage_id = &"s02_fixture"
    target.checkpoint_id = &"unknown_checkpoint"
    _check(await SceneRouter.request_registered_stage(&"s02_fixture", target) == ERR_INVALID_DATA and slot.get_child(0) == first and GameState.current_stage_id == &"s01_fixture", "Invalid checkpoint preserves original world")
    target.checkpoint_id = &"fixture_checkpoint"
    target.world_states = {"s02_fixture": {"counter": 2}}
    _check(await SceneRouter.request_registered_stage(&"s02_fixture", target) == OK, "Validated saved-state route")
    var second := slot.get_child(0)
    _check(second.applied_counter == 2 and GameState.capture_save().to_dict() == target.to_dict() and player.global_position.is_equal_approx(Vector3(1, .004, 1.5)), "Exact domain/state/feet spawn commit")
    var before := GameState.capture_save().to_dict()
    _check(await SceneRouter.request_registered_stage(&"s03_fixture") == FAILED and slot.get_child(0) == second and GameState.capture_save().to_dict() == before and player.active, "Apply failure restores old world/state/player")
    _check(await SceneRouter.request_registered_stage(&"s04_fixture") == ERR_INVALID_DATA and slot.get_child(0) == second and GameState.capture_save().to_dict() == before, "Actual capsule overlap rejects blocked spawn and restores previous world")
    _launch(&"s01_fixture")
    InputManager.set_mode(InputManager.Mode.DISABLED)
    await _wait_route()
    _check(_last_error == ERR_SKIP and slot.get_child(0) == second and InputManager.mode == InputManager.Mode.DISABLED, "Later identical DISABLED request survives cancellation")
    InputManager.set_mode(InputManager.Mode.GAMEPLAY)
    _launch(&"s01_fixture")
    game.queue_free()
    await _wait_route()
    _check(_last_error == ERR_SKIP and not SceneRouter.get("_transition_in_progress") and InputManager.mode == InputManager.Mode.UI, "Removed root cancels route and releases capture to empty UI")
    GameState.apply_save(original)
    SaveManager.set("_dirty", dirty)
    AudioDirector.current_stage = audio[0]
    AudioDirector.current_state = audio[1]
    SceneRouter.fade_duration = duration
    for id in [&"s01_fixture", &"s02_fixture", &"s03_fixture", &"s04_fixture"]:
        _check(SceneRouter.unregister_stage(id) == OK, "Fixture unregister")
    _check(_files() == hashes, "No production save/settings writes")
    if _failures.is_empty():
        print("ROUTER_PIPELINE PASS: initial preload/replace/state/spawn/fade, overlap, checkpoint/apply rejection, same-mode cancellation and removed root; full physical/checkpoint/rollback acceptance pending")
    get_tree().quit(0 if _failures.is_empty() else 1)
