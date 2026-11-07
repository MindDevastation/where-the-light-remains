extends Node
## Shipping player camera and lights; real local steps, quiet awakened projection.

var _output := ""
var _quality := "low"

func _ready() -> void:
    get_tree().create_timer(65.0,true).timeout.connect(func() -> void:
        push_error("ARCHIVE_CORE_REVIEW timeout")
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
        push_error("Missing core review output/quality")
        get_tree().quit(1)
        return
    SettingsManager.graphics_preset = "Low" if _quality=="low" else "Medium"
    SettingsManager.apply_runtime(false)
    var game := preload("res://core/game_root/game_root.tscn").instantiate()
    add_child(game)
    var definition := StageDefinition.new()
    definition.stage_id = ArchiveProgress.INTRO
    definition.scene_path = "res://worlds/archive/archive_main.tscn"
    definition.presentation = StageDefinition.Presentation.IN_PLACE
    if SceneRouter.register_stage(definition)!=OK:
        push_error("Controls review registration failed")
        get_tree().quit(1)
        return
    var saved := SaveGame.new()
    saved.stage_id = ArchiveProgress.INTRO
    saved.checkpoint_id = &"prologue_completed"
    saved.milestones = {"prologue_completed":true}
    ArchiveProgress.write_projection(saved)
    if await SceneRouter.request_resume_stage(saved)!=OK:
        push_error("Controls shipping resume failed")
        get_tree().quit(1)
        return
    var before := GameState.capture_save().to_dict()
    var dirty: bool = SaveManager.get("_dirty")
    var world := game.get_node("WorldSlot").get_child(0) as ArchiveMain
    var player := game.get_node("PlayerContainer/Player") as FirstPersonPlayer
    var hub := world.get_node("Hub/Onboarding") as ArchiveOnboarding
    player.set_physics_process(false)
    var cover := hub.get_node("Panel/Visual/Cover") as Node3D
    var handle := hub.get_node("Lever/Visual/Handle") as Node3D
    var views := [
        {"name":"core_hub_sleeping","position":Vector3(0,.004,3.8),"target":Vector3(0,.004,0),"pitch":-.16},
        {"name":"core_base_oblique","position":Vector3(1.7,.004,2.9),"target":Vector3(0,.004,0),"pitch":-.20},
        {"name":"core_panel_closed","position":Vector3(-.65,.004,1.9),"target":Vector3(-.65,.004,.9),"pitch":-.36},
        {"name":"core_panel_open","position":Vector3(-.65,.004,1.9),"target":Vector3(-.65,.004,.9),"pitch":-.36,"open":true},
        {"name":"core_panel_oblique","position":Vector3(-1.1,.004,1.8),"target":Vector3(-.65,.004,.9),"pitch":-.36},
        {"name":"core_lever_ready","position":Vector3(.95,.004,1.45),"target":Vector3(.95,.004,.45),"pitch":-.445,"install":true},
        {"name":"core_lever_pulled","position":Vector3(.95,.004,1.45),"target":Vector3(.95,.004,.45),"pitch":-.445,"awake":true},
        {"name":"core_hub_awakened","position":Vector3(0,.004,3.8),"target":Vector3(0,.004,0),"pitch":-.16}
    ]
    var captures: Array[Dictionary] = []
    for view: Dictionary in views:
        if view.get("open",false) and hub.advance(ArchiveOnboarding.Step.PANEL)!=OK:
            push_error("Actual panel step failed")
            get_tree().quit(1)
            return
        if view.get("install",false):
            if hub.advance(ArchiveOnboarding.Step.TAKE_LENS)!=OK or hub.advance(ArchiveOnboarding.Step.INSTALL_LENS)!=OK:
                push_error("Actual existing lens steps failed")
                get_tree().quit(1)
                return
        if view.get("awake",false):
            var projection := ArchiveProgress.fresh()
            projection["awakened"] = true
            projection["unlocked"][0] = true
            if world.apply_stage_state(ArchiveProgress.WING_ONE,projection)!=OK:
                push_error("Quiet awakened review projection failed")
                get_tree().quit(1)
                return
        player.spawn_at(Transform3D(Basis.IDENTITY,view["position"]))
        player.look_at(view["target"])
        player.head.rotation.x = view["pitch"]
        player.camera.make_current()
        for frame in 12:
            await get_tree().process_frame
        await RenderingServer.frame_post_draw
        var image := get_viewport().get_texture().get_image()
        var filename: String = view["name"]+"_"+_quality+".png"
        if image.save_png(_output.path_join(filename))!=OK:
            push_error("Could not capture core view")
            get_tree().quit(1)
            return
        captures.append({"name":view["name"],"file":filename,"size":[image.get_width(),image.get_height()],
            "cover_degrees":rad_to_deg(cover.rotation.y),"lever_degrees":rad_to_deg(handle.rotation.x),
            "phase":hub.phase,"loose_visible":hub.get_node("Lens/Visual").visible,
            "installed_visible":hub.get_node("InstalledLens").visible,
            "draw_calls":int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))})
    if GameState.capture_save().to_dict()!=before or SaveManager.get("_dirty")!=dirty:
        push_error("Controls review mutated progression/dirty state")
        get_tree().quit(1)
        return
    var environment: Environment = world.get_node("Environment").environment
    var file := FileAccess.open(_output.path_join("captures_"+_quality+".json"),FileAccess.WRITE)
    file.store_string(JSON.stringify({"status":"CAPTURED_FOR_REVIEW","scope":"core","quality":_quality,
        "captures":captures,"renderer":RenderingServer.get_current_rendering_method(),
        "device":RenderingServer.get_video_adapter_name(),"glow":environment.glow_enabled,
        "volumetrics":environment.volumetric_fog_enabled},"  "))
    file.close()
    game.queue_free()
    await get_tree().process_frame
    SceneRouter.unregister_stage(ArchiveProgress.INTRO)
    print("ARCHIVE_CORE_REVIEW CAPTURED: %s; eight actual player views; original lighting and quiet awake projection" % _quality)
    get_tree().quit(0)
