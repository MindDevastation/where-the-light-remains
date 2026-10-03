extends Node
## Engineering shared hub, not authored S14/S15 content or camera choreography.
var _failures: Array[String] = []
var _events := 0

func _ready() -> void:
    get_tree().create_timer(15.0, true).timeout.connect(func() -> void:
        push_error("ROUTER_SEAMLESS FAIL: timeout")
        get_tree().quit(1)
    )
    _run.call_deferred()

func _check(value: bool, message: String) -> void:
    if not value:
        _failures.append(message)
        push_error("ROUTER_SEAMLESS FAIL: " + message)

func _run() -> void:
    var original := GameState.capture_save()
    var dirty: bool = SaveManager.get("_dirty")
    var duration: float = SceneRouter.fade_duration
    var audio := [AudioDirector.current_stage, AudioDirector.current_state]
    var game := preload("res://core/game_root/game_root.tscn").instantiate()
    add_child(game)
    var slot: Node3D = game.get_node("WorldSlot")
    var player: FirstPersonPlayer = game.get_node("PlayerContainer/Player")
    var fade: FadeOverlay = game.get_node("TransitionLayer/FadeOverlay")
    var environment := WorldEnvironment.new()
    environment.environment = Environment.new()
    environment.environment.background_mode = Environment.BG_COLOR
    environment.environment.background_color = Color(.08, .13, .2)
    environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.environment.ambient_light_color = Color.WHITE
    environment.environment.ambient_light_energy = .8
    game.add_child(environment)
    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-50, -30, 0)
    game.add_child(light)
    for id in [&"s14_fixture", &"s15_fixture"]:
        var definition := StageDefinition.new()
        definition.stage_id = id
        definition.scene_path = "res://tests/fixtures/route_world_shared.tscn"
        definition.input_mode = InputManager.Mode.LIMITED_LOOK
        # Default FADE deliberately tests the mandatory S14→15 override.
        _check(SceneRouter.register_stage(definition) == OK, "Shared stage registration")
    SceneRouter.fade_duration = .04
    var initial := SaveGame.new()
    initial.stage_id = &"s14_fixture"
    initial.world_states = {"s14_fixture": {"counter": 1}, "s15_fixture": {"counter": 2}}
    _check(await SceneRouter.request_registered_stage(&"s14_fixture", initial) == OK, "Shared S14 world entry")
    var world := slot.get_child(0)
    for tick in 3:
        await get_tree().physics_frame
    player.head.rotation.x = .25
    player.rotate_y(.3)
    var feet := player.global_transform
    var look := player.head.rotation
    var camera := get_viewport().get_camera_3d()
    var instance := world.get_instance_id()
    var fade_revision := fade.request_revision
    var before_image: Image
    if DisplayServer.get_name() != "headless":
        await RenderingServer.frame_post_draw
        before_image = get_viewport().get_texture().get_image()
    var frame := Engine.get_process_frames()
    EventBus.stage_changed.connect(func(_id: StringName) -> void: _events += 1)
    SaveManager.set("_dirty", false)
    _check(await SceneRouter.request_registered_stage(&"s15_fixture") == OK, "Mandatory seamless S14 to S15")
    _check(Engine.get_process_frames() == frame and fade.request_revision == fade_revision and not fade.visible and not fade.busy, "No loading frame, fade request or black overlay")
    _check(slot.get_child_count() == 1 and slot.get_child(0).get_instance_id() == instance and world.stage_id == &"s15_fixture" and world.applied_counter == 2, "Same world instance applies S15 logical namespace")
    _check(player.active and player.global_transform.is_equal_approx(feet) and player.head.rotation.is_equal_approx(look) and get_viewport().get_camera_3d() == camera and InputManager.mode == InputManager.Mode.LIMITED_LOOK, "Exact player/camera continuity and authored mode")
    _check(_events == 1 and SaveManager.get("_dirty") and GameState.current_stage_id == &"s15_fixture", "Single accepted event and dirty logical stage")
    await get_tree().process_frame
    _check(is_instance_valid(world) and not world.is_queued_for_deletion() and world.get_parent() == slot, "Accepted shared instance survives the next frame")
    if before_image != null:
        await RenderingServer.frame_post_draw
        var after_image := get_viewport().get_texture().get_image()
        _check(after_image.get_data() == before_image.get_data(), "Actual Forward+ framebuffer unchanged across seamless engineering stage update")
        for argument in OS.get_cmdline_user_args():
            if argument.begins_with("--seamless-output="):
                var output := argument.trim_prefix("--seamless-output=")
                _check(before_image.save_png(output + "_before.png") == OK and after_image.save_png(output + "_after.png") == OK, "Seamless screenshots")
    var before := GameState.capture_save().to_dict()
    _check(SceneRouter.unregister_stage(&"s15_fixture") == OK, "Replace fixture definition")
    var invalid := StageDefinition.new()
    invalid.stage_id = &"s15_fixture"
    invalid.scene_path = "res://tests/fixtures/route_world_b.tscn"
    _check(SceneRouter.register_stage(invalid) == OK, "Unsupported shared path fixture")
    world.stage_id = &"s14_fixture"
    GameState.current_stage_id = &"s14_fixture"
    var revision := InputManager.mode_revision
    _check(await SceneRouter.request_registered_stage(&"s15_fixture") == ERR_UNAVAILABLE and fade.request_revision == fade_revision and InputManager.mode_revision == revision and slot.get_child(0) == world and GameState.current_stage_id == &"s14_fixture", "Missing shared contract rejected before lock/fade/replacement")
    GameState.apply_save(SaveGame.decode(before)["data"])
    game.queue_free()
    await get_tree().process_frame
    for id in [&"s14_fixture", &"s15_fixture"]:
        _check(SceneRouter.unregister_stage(id) == OK, "Shared registry cleanup")
    GameState.apply_save(original)
    SaveManager.set("_dirty", dirty)
    AudioDirector.current_stage = audio[0]
    AudioDirector.current_state = audio[1]
    SceneRouter.fade_duration = duration
    InputManager.set_mode(InputManager.Mode.UI)
    if _failures.is_empty():
        print("ROUTER_SEAMLESS PASS: mandatory S14→15 same-instance/namespace update, exact feet/look/camera continuity, no loading frame/fade/black; missing contract rejected; engineering fixture only")
    get_tree().quit(0 if _failures.is_empty() else 1)
