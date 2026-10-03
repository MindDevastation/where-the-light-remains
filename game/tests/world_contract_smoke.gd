extends Node
## CLI-only engineering IDs/markers; no authored world or puzzle parameters.

class FixtureWorld extends WorldScene:
    var applied := -1

    func validate_logical_state(state: Dictionary) -> Error:
        return OK if state.size() == 1 and state.has("counter") and typeof(state["counter"]) == TYPE_INT and state["counter"] in range(4) else ERR_INVALID_DATA

    func apply_logical_state(state: Dictionary) -> Error:
        var error := validate_logical_state(state)
        if error == OK:
            applied = state["counter"]
        return error

var _failures: Array[String] = []


func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
        push_error("WORLD_CONTRACT FAIL: " + message)


func _ready() -> void:
    get_tree().create_timer(20.0, true).timeout.connect(func() -> void:
        push_error("WORLD_CONTRACT FAIL: timeout")
        get_tree().quit(1)
    )
    _run.call_deferred()


func _run() -> void:
    var original := GameState.capture_save().to_dict()
    var dirty: bool = SaveManager.get("_dirty")
    var mode := InputManager.mode
    var world := WorldScene.new()
    world.stage_id = &"s01_fixture"
    var group := Node3D.new()
    group.name = "Spawns"
    group.position = Vector3(1, 0, 2)
    world.add_child(group)
    var marker := Marker3D.new()
    marker.name = "Entry"
    marker.position = Vector3(0, .004, -1)
    marker.rotation.y = PI / 2
    group.add_child(marker)
    world.default_spawn = NodePath("Spawns/Entry")
    world.checkpoint_spawns = {&"fixture_checkpoint": NodePath("Spawns/Entry")}
    var saved := SaveGame.new()
    saved.stage_id = world.stage_id
    var result := world.prepare_state(saved)
    _check(result["error"] == OK and result["spawn"].origin.is_equal_approx(Vector3(1, .004, 1)), "Offline nested marker feet transform")
    saved.checkpoint_id = &"fixture_checkpoint"
    _check(world.prepare_state(saved)["error"] == OK, "Explicit checkpoint registry")
    saved.checkpoint_id = &"unknown_checkpoint"
    _check(world.prepare_state(saved)["error"] == ERR_INVALID_DATA, "Unknown checkpoint rejected")
    saved.checkpoint_id = &""
    saved.stage_id = &"s02_fixture"
    _check(world.prepare_state(saved)["error"] == ERR_INVALID_DATA, "Wrong full stage rejected")
    saved.stage_id = world.stage_id
    saved.world_states = {"s01_fixture": {"counter": 1}}
    _check(world.prepare_state(saved)["error"] == ERR_UNAVAILABLE, "Base world rejects unimplemented domain state")
    saved.world_states.clear()
    world.checkpoint_spawns[&"bad_checkpoint"] = NodePath("Absent")
    _check(world.prepare_state(saved)["error"] == ERR_INVALID_DATA, "Unused invalid checkpoint rejected")
    world.checkpoint_spawns.erase(&"bad_checkpoint")
    var bad_marker := Marker3D.new()
    bad_marker.name = "TiltedUnused"
    bad_marker.rotation.x = .1
    world.add_child(bad_marker)
    world.checkpoint_spawns[&"unused_checkpoint"] = NodePath("TiltedUnused")
    _check(world.prepare_state(saved)["error"] == ERR_INVALID_DATA, "Unused checkpoint transform validated too")
    world.checkpoint_spawns.erase(&"unused_checkpoint")
    for bad in [Transform3D(Basis.from_scale(Vector3(2, 1, 1)), Vector3.ZERO), Transform3D(Basis(Vector3.RIGHT, .1), Vector3.ZERO), Transform3D(Basis.from_scale(Vector3(-1, 1, 1)), Vector3.ZERO), Transform3D(Basis.IDENTITY, Vector3(NAN, 0, 0))]:
        _check(not WorldScene.valid_spawn_transform(bad), "Nonfinite/scale/tilt/mirror spawn rejected")
    _check(WorldScene.valid_spawn_transform(Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO)), "Yaw-only spawn accepted")
    var controller := FixtureWorld.new()
    controller.stage_id = world.stage_id
    var spawn := Marker3D.new()
    spawn.name = "Entry"
    controller.add_child(spawn)
    controller.default_spawn = NodePath("Entry")
    saved.world_states = {"s01_fixture": {"counter": 2}, "s02_fixture": {"other": true}}
    var prepared := controller.prepare_state(saved)
    _check(prepared["error"] == OK and controller.applied == -1, "Preparation validates current namespace without applying")
    prepared["state"]["counter"] = 3
    _check(saved.world_states["s01_fixture"]["counter"] == 2, "Prepared state isolated")
    _check(controller.apply_logical_state(prepared["state"]) == OK and controller.applied == 3, "Validated domain controller applies only its namespace")
    saved.world_states["s01_fixture"]["counter"] = 99
    _check(controller.prepare_state(saved)["error"] == ERR_INVALID_DATA and controller.applied == 3, "Invalid domain state preserves controller")
    var definition := StageDefinition.new()
    definition.stage_id = &"s01_fixture"
    definition.scene_path = "res://tests/fixtures/archive_kit_sample.tscn"
    var copied := definition.copy_validated()
    _check(copied != null and copied != definition, "Existing PackedScene definition copied")
    if copied == null:
        world.free()
        controller.free()
        get_tree().quit(1)
        return
    copied.stage_id = &"s02_fixture"
    _check(definition.stage_id == &"s01_fixture", "Registry definition isolated")
    for path in ["user://savegame.json", "res://../outside.tscn", "res://absent.tscn", "res://project.godot"]:
        definition.scene_path = path
        _check(definition.copy_validated() == null, "Invalid registry scene path")
    definition.scene_path = "res://tests/fixtures/archive_kit_sample.tscn"
    definition.player_active = false
    _check(definition.copy_validated() == null, "Inactive gameplay definition rejected")
    definition.input_mode = InputManager.Mode.CINEMATIC
    _check(definition.copy_validated() != null, "Explicit cinematic definition accepted")
    definition.input_mode = InputManager.Mode.DISABLED
    _check(definition.copy_validated() == null, "Permanent disabled target rejected")
    definition.player_active = true
    definition.input_mode = InputManager.Mode.GAMEPLAY
    _check(SceneRouter.register_stage(null) == ERR_INVALID_DATA, "Null stage rejected")
    _check(SceneRouter.register_stage(definition) == OK and SceneRouter.register_stage(definition) == ERR_ALREADY_EXISTS, "Registry inserts validated copy, rejects duplicates")
    definition.scene_path = "res://absent.tscn"
    var registered := SceneRouter.stage_definition(&"s01_fixture")
    _check(registered != null and registered.scene_path == "res://tests/fixtures/archive_kit_sample.tscn", "Registry copy isolated from author mutation")
    registered.scene_path = "res://absent.tscn"
    _check(SceneRouter.stage_definition(&"s01_fixture").scene_path == "res://tests/fixtures/archive_kit_sample.tscn", "Retrieved definition isolated too")
    var missing := await SceneRouter.preload_stage(&"s03_unknown")
    _check(missing["error"] == ERR_INVALID_DATA and missing["scene"] == null, "Unregistered preload rejected")
    var loaded := await SceneRouter.preload_stage(&"s01_fixture")
    _check(loaded["error"] == OK and loaded["scene"] is PackedScene, "Actual threaded registered scene preload")
    _check(SceneRouter.unregister_stage(&"s01_fixture") == OK and SceneRouter.unregister_stage(&"s01_fixture") == ERR_DOES_NOT_EXIST, "Explicit registry cleanup")
    var revision := InputManager.mode_revision
    InputManager.set_mode(mode)
    _check(InputManager.mode_revision == revision + 1 and InputManager.mode == mode, "Identical mode request advances ownership revision without changing mode")
    world.free()
    controller.free()
    _check(GameState.capture_save().to_dict() == original and SaveManager.get("_dirty") == dirty and InputManager.mode == mode, "Preparation has no global state/dirty/input effects")
    if _failures.is_empty():
        print("WORLD_CONTRACT PASS: isolated registered definitions and actual threaded preload, full stage/checkpoint/domain validation, offline upright spawn and state; no production routing or save IO")
    get_tree().quit(0 if _failures.is_empty() else 1)
