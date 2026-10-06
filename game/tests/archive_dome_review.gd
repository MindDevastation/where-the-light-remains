extends Node
## Read-only actual player views of the isolated upper structure.

var _output := ""
var _quality := "low"
var _shipping_roof := false

func _ready() -> void:
    get_tree().create_timer(40.0,true).timeout.connect(func() -> void:
        push_error("ARCHIVE_DOME_REVIEW timeout")
        get_tree().quit(1)
    )
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--review-output="):
            _output = arg.trim_prefix("--review-output=")
        elif arg.begins_with("--quality="):
            _quality = arg.trim_prefix("--quality=")
        elif arg == "--shipping-roof":
            _shipping_roof = true
    _run.call_deferred()

func _run() -> void:
    if _output.is_empty() or _quality not in ["low","medium"]:
        push_error("Missing dome review output/quality")
        get_tree().quit(1)
        return
    SettingsManager.graphics_preset = "Low" if _quality == "low" else "Medium"
    SettingsManager.apply_runtime(false)
    var game := preload("res://core/game_root/game_root.tscn").instantiate()
    add_child(game)
    var definition := StageDefinition.new()
    definition.stage_id = ArchiveProgress.WING_ONE
    definition.scene_path = "res://worlds/archive/archive_main.tscn" if _shipping_roof else "res://tests/fixtures/archive_dome_sample.tscn"
    definition.presentation = StageDefinition.Presentation.IN_PLACE
    if SceneRouter.register_stage(definition) != OK:
        push_error("Dome test registration failed")
        get_tree().quit(1)
        return
    var saved := SaveGame.new()
    saved.stage_id = ArchiveProgress.WING_ONE
    saved.checkpoint_id = &"archive_awakened"
    saved.milestones = {"archive_awakened":true,"wing_01_unlocked":true}
    ArchiveProgress.write_projection(saved)
    if await SceneRouter.request_resume_stage(saved) != OK:
        push_error("Dome fixture resume failed")
        get_tree().quit(1)
        return
    var before := GameState.capture_save().to_dict()
    var dirty: bool = SaveManager.get("_dirty")
    var world := game.get_node("WorldSlot").get_child(0) as ArchiveMain
    var player := game.get_node("PlayerContainer/Player") as FirstPersonPlayer
    player.set_physics_process(false)
    var views := [
        {"name":"dome_lookup","position":Vector3(0,.02,-19),"target":Vector3(0,.02,-21),"pitch":1.16},
        {"name":"dome_entrance","position":Vector3(0,.02,-17),"target":Vector3(0,.02,-24),"pitch":.6},
        {"name":"dome_corner","position":Vector3(3.8,.02,-24.6),"target":Vector3(5,.02,-27),"pitch":.92},
        {"name":"dome_reverse","position":Vector3(-2.8,.02,-24),"target":Vector3(0,.02,-15),"pitch":.55},
        {"name":"dome_hero","position":Vector3(0,.02,-18.6),"target":Vector3(0,.02,-22),"pitch":.03},
        {"name":"dome_hearth","position":Vector3(-2.8,.02,-21),"target":Vector3(-2.8,.02,-23.3),"pitch":-.25}
    ]
    var captures: Array[Dictionary] = []
    for view: Dictionary in views:
        player.spawn_at(Transform3D(Basis.IDENTITY,view["position"]))
        player.look_at(view["target"])
        player.head.rotation.x = view["pitch"]
        player.camera.make_current()
        for frame in 12:
            await get_tree().process_frame
        await RenderingServer.frame_post_draw
        var image := get_viewport().get_texture().get_image()
        var name: String = view["name"].replace("dome_","roof_") if _shipping_roof else view["name"]
        var filename: String = name+"_"+_quality+".png"
        if image.save_png(_output.path_join(filename)) != OK:
            push_error("Could not capture ceiling view")
            get_tree().quit(1)
            return
        captures.append({"name":name,"file":filename,"size":[image.get_width(),image.get_height()],
            "draw_calls":int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
            "texture_bytes":int(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED))})
    if GameState.capture_save().to_dict() != before or SaveManager.get("_dirty") != dirty:
        push_error("Dome review mutated progression/dirty state")
        get_tree().quit(1)
        return
    var environment: Environment = world.get_node("Environment").environment
    var file := FileAccess.open(_output.path_join("captures_"+_quality+".json"),FileAccess.WRITE)
    file.store_string(JSON.stringify({"status":"CAPTURED_FOR_REVIEW","scope":"roof" if _shipping_roof else "dome","quality":_quality,
        "captures":captures,"renderer":RenderingServer.get_current_rendering_method(),
        "device":RenderingServer.get_video_adapter_name(),"glow":environment.glow_enabled,
        "volumetrics":environment.volumetric_fog_enabled},"  "))
    file.close()
    game.queue_free()
    await get_tree().process_frame
    SceneRouter.unregister_stage(ArchiveProgress.WING_ONE)
    print(("ARCHIVE_ROOF_REVIEW" if _shipping_roof else "ARCHIVE_DOME_REVIEW") + " CAPTURED: %s; six actual player views; %s" % [_quality,"shipping roof" if _shipping_roof else "isolated dome coverage candidate"])
    get_tree().quit(0)
