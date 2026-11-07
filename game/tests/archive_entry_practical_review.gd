extends Node
## Shipping player camera and lights; real local steps, quiet awakened projection.

var _output := ""
var _quality := "low"

func _ready() -> void:
    get_tree().create_timer(65.0,true).timeout.connect(func() -> void:
        push_error("ARCHIVE_ENTRY_REVIEW timeout")
        get_tree().quit(1)
    )
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--review-output="):
            _output = arg.trim_prefix("--review-output=")
        elif arg.begins_with("--quality="):
            _quality = arg.trim_prefix("--quality=")
    _run.call_deferred()

func _run() -> void:
    if _output.is_empty() or _quality not in ["low","medium"]:
        push_error("Missing lock review output/quality")
        get_tree().quit(1)
        return
    SettingsManager.graphics_preset = "Low" if _quality=="low" else "Medium"
    SettingsManager.apply_runtime(false)
    var game := preload("res://core/game_root/game_root.tscn").instantiate()
    add_child(game)
    var definition := StageDefinition.new()
    definition.stage_id = ArchiveProgress.PROLOGUE
    definition.scene_path = "res://worlds/archive/archive_main.tscn"
    definition.presentation = StageDefinition.Presentation.FADE
    definition.player_active = false
    definition.input_mode = InputManager.Mode.CINEMATIC
    if SceneRouter.register_stage(definition)!=OK:
        push_error("Controls review registration failed")
        get_tree().quit(1)
        return
    var saved := SaveGame.new()
    ArchiveProgress.write_projection(saved)
    if await SceneRouter.request_resume_stage(saved)!=OK:
        push_error("Controls shipping resume failed")
        get_tree().quit(1)
        return
    var before := GameState.capture_save().to_dict()
    var dirty: bool = SaveManager.get("_dirty")
    var world := game.get_node("WorldSlot").get_child(0) as ArchiveMain
    var player := game.get_node("PlayerContainer/Player") as FirstPersonPlayer
    var prologue := world.get_node("Prologue") as ArchivePrologue
    prologue.set_process(false)
    player.set_physics_process(false)
    var views := [
        {"name":"entry_rail_closed","time":0.0},
        {"name":"entry_detail_engaged","time":1.2,"detail":true},
        {"name":"entry_practical_detail","time":1.2,"practical":true},
        {"name":"entry_rail_opening","time":2.5},
        {"name":"entry_rail_open","time":3.8},
        {"name":"entry_quiet_s01_reverse","time":8.0,"quiet":true}
    ]
    var captures: Array[Dictionary] = []
    for view: Dictionary in views:
        prologue.camera.position = Vector3(0,1.624,15)
        prologue.camera.rotation = Vector3.ZERO
        prologue._apply_timeline_pose(view["time"])
        # Read-only pose fixture: shipping smoke covers real spark event/audio.
        prologue.spark.visible = view["time"]>=1.0
        prologue.camera.make_current()
        if view.get("detail",false):
            prologue.camera.position = Vector3(0,1.624,10.4)
        if view.get("practical",false):
            prologue.camera.position = Vector3(2.8,2.75,10.2)
            prologue.camera.look_at(world.get_node("Hub/Wall3R/EntryPractical").global_position)
        if view.get("quiet",false):
            if world.apply_stage_state(ArchiveProgress.INTRO,ArchiveProgress.fresh())!=OK:
                push_error("Quiet S01 review projection failed")
                get_tree().quit(1)
                return
            player.spawn_at(Transform3D(Basis.IDENTITY,Vector3(0,.004,6)))
            player.look_at(Vector3(0,.004,9.4))
            player.head.rotation.x = 0
            player.camera.make_current()
        for frame in 12:
            await get_tree().process_frame
        await RenderingServer.frame_post_draw
        var image := get_viewport().get_texture().get_image()
        var filename: String = view["name"]+"_"+_quality+".png"
        if image.save_png(_output.path_join(filename))!=OK:
            push_error("Could not capture lock view")
            get_tree().quit(1)
            return
        captures.append({"name":view["name"],"file":filename,"size":[image.get_width(),image.get_height()],
            "sample_seconds":view["time"],"supplemental_detail":view.get("detail",false),
            "bolt_local_x":prologue.lock_bolt.position.x,"left_door_x":prologue.left_door.position.x,
            "right_door_x":prologue.right_door.position.x,
            "draw_calls":int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))})
    if GameState.capture_save().to_dict()!=before or SaveManager.get("_dirty")!=dirty:
        push_error("Controls review mutated progression/dirty state")
        get_tree().quit(1)
        return
    var environment: Environment = world.get_node("Environment").environment
    var file := FileAccess.open(_output.path_join("captures_"+_quality+".json"),FileAccess.WRITE)
    file.store_string(JSON.stringify({"status":"CAPTURED_FOR_REVIEW","scope":"entry","quality":_quality,
        "captures":captures,"renderer":RenderingServer.get_current_rendering_method(),
        "device":RenderingServer.get_video_adapter_name(),"glow":environment.glow_enabled,
        "volumetrics":environment.volumetric_fog_enabled},"  "))
    file.close()
    game.queue_free()
    await get_tree().process_frame
    SceneRouter.unregister_stage(ArchiveProgress.PROLOGUE)
    print("ARCHIVE_ENTRY_REVIEW CAPTURED: %s; six shipping/light views; one reused warm practical; quiet S01 pose" % _quality)
    get_tree().quit(0)
