extends Node
## Bounded real player views of approved corridor art; no progression writes.

var _output := ""
var _quality := "low"


func _ready() -> void:
    get_tree().create_timer(40.0, true).timeout.connect(func() -> void:
        push_error("ARCHIVE_CORRIDOR_REVIEW timeout")
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
        push_error("Missing corridor review output/quality")
        get_tree().quit(1)
        return
    SettingsManager.graphics_preset = "Low" if _quality == "low" else "Medium"
    SettingsManager.apply_runtime(false)
    var game := preload("res://core/game_root/game_root.tscn").instantiate()
    add_child(game)
    # This test entry bypasses Boot, which owns shipping stage registration.
    var definition := StageDefinition.new()
    definition.stage_id = ArchiveProgress.WING_ONE
    definition.scene_path = "res://worlds/archive/archive_main.tscn"
    definition.presentation = StageDefinition.Presentation.IN_PLACE
    if SceneRouter.register_stage(definition) != OK:
        push_error("Corridor test registration failed")
        get_tree().quit(1)
        return
    var saved := SaveGame.new()
    saved.stage_id = ArchiveProgress.WING_ONE
    saved.checkpoint_id = &"archive_awakened"
    saved.milestones = {"archive_awakened": true, "wing_01_unlocked": true}
    ArchiveProgress.write_projection(saved)
    var route_error := await SceneRouter.request_resume_stage(saved)
    if route_error != OK:
        push_error("Corridor review route failed: " + error_string(route_error))
        get_tree().quit(1)
        return
    var before := GameState.capture_save().to_dict()
    var dirty: bool = SaveManager.get("_dirty")
    var world := game.get_node("WorldSlot").get_child(0) as ArchiveMain
    var player := game.get_node("PlayerContainer/Player") as FirstPersonPlayer
    player.set_physics_process(false)
    var views := [
        {"name": "entrance", "position": Vector3(0, .02, -8.6), "target": Vector3(0, .02, -15)},
        {"name": "seam", "position": Vector3(.3, .02, -10.7), "target": Vector3(-1.7, .02, -12.2)},
        {"name": "return", "position": Vector3(0, .02, -16.8), "target": Vector3(0, .02, -11)}
    ]
    var captures: Array[Dictionary] = []
    for view: Dictionary in views:
        player.spawn_at(Transform3D(Basis.IDENTITY, view["position"]))
        player.look_at(view["target"])
        player.head.rotation.x = 0
        player.camera.make_current()
        for frame in 12:
            await get_tree().process_frame
        await RenderingServer.frame_post_draw
        var image := get_viewport().get_texture().get_image()
        var filename: String = view["name"] + "_" + _quality + ".png"
        if image.save_png(_output.path_join(filename)) != OK:
            push_error("Could not capture corridor view")
            get_tree().quit(1)
            return
        captures.append({"name": view["name"], "file": filename, "size": [image.get_width(), image.get_height()],
            "camera_position": [player.camera.global_position.x, player.camera.global_position.y, player.camera.global_position.z]})
    if GameState.capture_save().to_dict() != before or SaveManager.get("_dirty") != dirty:
        push_error("Corridor review mutated progression/dirty state")
        get_tree().quit(1)
        return
    var file := FileAccess.open(_output.path_join("captures_" + _quality + ".json"), FileAccess.WRITE)
    file.store_string(JSON.stringify({"status": "CAPTURED_FOR_REVIEW", "quality": _quality, "captures": captures,
        "renderer": RenderingServer.get_current_rendering_method(), "device": RenderingServer.get_video_adapter_name(),
        "ambient_source": world.get_node("Environment").environment.ambient_light_source,
        "sky_present": world.get_node("Environment").environment.sky != null,
        "glow": world.get_node("Environment").environment.glow_enabled,
        "volumetrics": world.get_node("Environment").environment.volumetric_fog_enabled}, "  "))
    file.close()
    game.queue_free()
    await get_tree().process_frame
    SceneRouter.unregister_stage(ArchiveProgress.WING_ONE)
    print("ARCHIVE_CORRIDOR_REVIEW CAPTURED: ", _quality, "; 3 actual player views")
    get_tree().quit(0)
