extends Node
## Exact player views of existing cold/warm room projections; no save writes.

var _output := ""
var _quality := "low"

func _ready() -> void:
    get_tree().create_timer(40.0, true).timeout.connect(func() -> void:
        push_error("ARCHIVE_ROOM_REVIEW timeout")
        get_tree().quit(1)
    )
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--review-output="):
            _output = arg.trim_prefix("--review-output=")
        elif arg.begins_with("--quality="):
            _quality = arg.trim_prefix("--quality=")
    _run.call_deferred()

func _run() -> void:
    if _output.is_empty() or _quality not in ["low", "medium"]:
        push_error("Missing room review output/quality")
        get_tree().quit(1)
        return
    SettingsManager.graphics_preset = "Low" if _quality == "low" else "Medium"
    SettingsManager.apply_runtime(false)
    var game := preload("res://core/game_root/game_root.tscn").instantiate()
    add_child(game)
    var definition := StageDefinition.new()
    definition.stage_id = ArchiveProgress.WING_ONE
    definition.scene_path = "res://worlds/archive/archive_main.tscn"
    definition.presentation = StageDefinition.Presentation.IN_PLACE
    if SceneRouter.register_stage(definition) != OK:
        push_error("Room test registration failed")
        get_tree().quit(1)
        return
    var saved := SaveGame.new()
    saved.stage_id = ArchiveProgress.WING_ONE
    saved.checkpoint_id = &"archive_awakened"
    saved.milestones = {"archive_awakened": true, "wing_01_unlocked": true}
    ArchiveProgress.write_projection(saved)
    if await SceneRouter.request_resume_stage(saved) != OK:
        push_error("Room review resume failed")
        get_tree().quit(1)
        return
    var before := GameState.capture_save().to_dict()
    var dirty: bool = SaveManager.get("_dirty")
    var world := game.get_node("WorldSlot").get_child(0) as ArchiveMain
    var player := game.get_node("PlayerContainer/Player") as FirstPersonPlayer
    player.set_physics_process(false)
    var views := [
        {"name": "room_cold", "position": Vector3(1.8, .02, -20), "target": Vector3(0, .02, -23.5)},
        {"name": "room_corner", "position": Vector3(3.2, .02, -23.7), "target": Vector3(4.9, .02, -26.5)},
        {"name": "room_warm", "position": Vector3(1.8, .02, -20), "target": Vector3(0, .02, -23.5), "warm": true}
    ]
    var captures: Array[Dictionary] = []
    for view: Dictionary in views:
        if view.get("warm", false):
            # Local quiet presentation only; real persisted puzzle progression has its own regression.
            var completed := ArchiveProgress.fresh()
            completed["awakened"] = true
            completed["unlocked"][0] = true
            completed["unlocked"][1] = true
            completed["completed"][0] = true
            completed["light_restored"] = true
            completed["star_collected"] = true
            completed["hearth_collected"] = true
            if world.apply_stage_state(ArchiveProgress.WING_ONE, completed) != OK:
                push_error("Existing warm projection rejected")
                get_tree().quit(1)
                return
        player.spawn_at(Transform3D(Basis.IDENTITY, view["position"]))
        player.look_at(view["target"])
        player.head.rotation.x = .04 if view["name"] != "room_corner" else 0.0
        player.camera.make_current()
        for frame in 12:
            await get_tree().process_frame
        await RenderingServer.frame_post_draw
        var image := get_viewport().get_texture().get_image()
        var filename: String = view["name"] + "_" + _quality + ".png"
        if image.save_png(_output.path_join(filename)) != OK:
            push_error("Could not capture room view")
            get_tree().quit(1)
            return
        var color: Color = world.get_node("Wing01/Room/RoomLight").light_color
        captures.append({"name": view["name"], "file": filename, "size": [image.get_width(), image.get_height()],
            "light_color": [color.r, color.g, color.b], "hearth_visible": world.get_node("Wing01/Room/Hearth/Flame").visible})
    if GameState.capture_save().to_dict() != before or SaveManager.get("_dirty") != dirty:
        push_error("Room presentation review mutated progression/dirty state")
        get_tree().quit(1)
        return
    var environment: Environment = world.get_node("Environment").environment
    var file := FileAccess.open(_output.path_join("captures_" + _quality + ".json"), FileAccess.WRITE)
    file.store_string(JSON.stringify({"status": "CAPTURED_FOR_REVIEW", "scope": "room", "quality": _quality, "captures": captures,
        "renderer": RenderingServer.get_current_rendering_method(), "device": RenderingServer.get_video_adapter_name(),
        "glow": environment.glow_enabled, "volumetrics": environment.volumetric_fog_enabled}, "  "))
    file.close()
    game.queue_free()
    await get_tree().process_frame
    SceneRouter.unregister_stage(ArchiveProgress.WING_ONE)
    print("ARCHIVE_ROOM_REVIEW CAPTURED: ", _quality, "; 3 actual player views; quiet local cold/warm projections")
    get_tree().quit(0)
