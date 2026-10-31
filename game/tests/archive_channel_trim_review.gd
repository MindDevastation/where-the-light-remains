extends Node
## Current shipping world and lights; quiet state projections, not E/route replay.

var _output := ""
var _quality := "low"

func _ready() -> void:
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--review-output="): _output = arg.trim_prefix("--review-output=")
        if arg.begins_with("--quality="): _quality = arg.trim_prefix("--quality=")
    get_tree().create_timer(120.0, true).timeout.connect(func() -> void:
        push_error("ARCHIVE_CHANNEL_TRIM_REVIEW timeout")
        get_tree().quit(1))
    _run.call_deferred()


func _run() -> void:
    assert(not _output.is_empty() and _quality in ["low", "medium"])
    SettingsManager.graphics_preset = "Low" if _quality == "low" else "Medium"
    SettingsManager.apply_runtime(false)
    var resource := load("res://worlds/archive/archive_main.tscn") as PackedScene
    assert(resource != null)
    var game := preload("res://core/game_root/game_root.tscn").instantiate()
    add_child(game)
    var definition := StageDefinition.new()
    definition.stage_id = ArchiveProgress.PROLOGUE
    definition.scene_path = "res://worlds/archive/archive_main.tscn"
    definition.presentation = StageDefinition.Presentation.FADE
    definition.player_active = false
    definition.input_mode = InputManager.Mode.CINEMATIC
    assert(SceneRouter.register_stage(definition) == OK)
    var saved := SaveGame.new()
    ArchiveProgress.write_projection(saved)
    assert(await SceneRouter.request_resume_stage(saved) == OK)
    var before := GameState.capture_save().to_dict()
    var dirty: bool = SaveManager.get("_dirty")
    var world := game.get_node("WorldSlot").get_child(0) as ArchiveMain
    var player := game.get_node("PlayerContainer/Player") as FirstPersonPlayer
    world.get_node("Prologue").set_process(false)
    player.set_physics_process(false)
    world.set_process(false)
    var detail := Camera3D.new()
    world.add_child(detail)
    var captures: Array[Dictionary] = []
    for view: String in ["dormant", "active", "completed", "detail"]:
        var state := ArchiveProgress.fresh()
        var stage := ArchiveProgress.INTRO
        if view != "dormant":
            state["awakened"] = true
            state["unlocked"][0] = true
            stage = ArchiveProgress.WING_ONE
        if view in ["completed", "detail"]:
            state["light_restored"] = true
            state["star_collected"] = true
            state["hearth_collected"] = true
            state["completed"][0] = true
            state["unlocked"][1] = true
        assert(world.apply_stage_state(stage, state) == OK)
        player.spawn_at(Transform3D(Basis.IDENTITY, Vector3(1.0, 0.004, 1.5)))
        player.look_at(Vector3(0, 0.004, -4.0))
        player.head.look_at(Vector3(0, 0.03, -4.0))
        player.camera.make_current()
        if view == "detail":
            detail.position = Vector3(0.27, 0.36, -4.6)
            detail.look_at(Vector3(0, 0.025, -4.8))
            detail.make_current()
        var channels := []
        for index in 5:
            var channel := world.get_node("Routes/Wing%02d/Channel" % (index + 1)) as ArchiveLightChannel
            var visual := channel.get_node("Mesh") as MeshInstance3D
            assert(visual.mesh is ArrayMesh and channel.get_node("Mesh/Rails") is MeshInstance3D)
            assert(channel.position.is_equal_approx(Vector3(0, 0, -4.6)) and channel.scale.is_equal_approx(Vector3(1, 1, 1.38)))
            assert(not channel.pulse_running)
            channels.append({"route": index + 1, "status": channel.status, "visible": channel.visible,
                "core_mesh": visual.mesh.resource_path, "rails_mesh": channel.get_node("Mesh/Rails").mesh.resource_path,
                "triangles": 180, "transform": str(channel.transform)})
        for frame in 3: await get_tree().process_frame
        await RenderingServer.frame_post_draw
        var image := get_viewport().get_texture().get_image()
        var filename := "channel_" + view + "_" + _quality + ".png"
        assert(image.save_png(_output.path_join(filename)) == OK)
        captures.append({"file": filename, "view": view, "size": [image.get_width(), image.get_height()],
            "supplemental_detail_camera": view == "detail", "quiet_projection": true, "channels": channels,
            "camera": str(get_viewport().get_camera_3d().global_transform),
            "light_count": world.find_children("*", "Light3D", true, false).size()})
    assert(GameState.capture_save().to_dict() == before and SaveManager.get("_dirty") == dirty)
    var environment: Environment = world.get_node("Environment").environment
    assert(_quality != "low" or not environment.glow_enabled and not environment.volumetric_fog_enabled)
    var file := FileAccess.open(_output.path_join("captures_" + _quality + ".json"), FileAccess.WRITE)
    file.store_string(JSON.stringify({"quality": _quality, "captures": captures,
        "renderer": RenderingServer.get_current_rendering_method(), "device": RenderingServer.get_video_adapter_name(),
        "glow": environment.glow_enabled, "volumetrics": environment.volumetric_fog_enabled,
        "render_scale": get_viewport().scaling_3d_scale,
        "scope": "Three current player-camera quiet projections plus one supplemental channel close-up; unchanged shipping lights. No real input/awakening/save reload or target GPU acceptance."}, "  ") + "\n")
    file.close()
    game.queue_free()
    await get_tree().process_frame
    SceneRouter.unregister_stage(ArchiveProgress.PROLOGUE)
    print("ARCHIVE_CHANNEL_TRIM_REVIEW CAPTURED: ", _quality, "; four bounded native views")
    get_tree().quit(0)
