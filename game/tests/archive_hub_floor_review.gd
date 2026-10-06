extends Node
## Shipping player camera and lights; real local steps, quiet awakened projection.

var _output := ""
var _quality := "low"

func _ready() -> void:
    get_tree().create_timer(65.0,true).timeout.connect(func() -> void:
        push_error("ARCHIVE_HUB_FLOOR_REVIEW timeout")
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
        {"name":"hub_floor_s00_closed","time":0.0},
        {"name":"hub_floor_s00_opening","time":2.5},
        {"name":"hub_floor_s00_entry","time":7.9},
        {"name":"hub_floor_s01_asleep","time":8.0,"quiet":true,"target":Vector3(0,.004,0)},
        {"name":"hub_floor_s01_detail","time":8.0,"quiet":true,"position":Vector3(3,.004,5),"target":Vector3(0,.004,0),"pitch":-.60,"detail":true},
        {"name":"hub_floor_corridor_join","time":8.0,"quiet":true,"awakened":true,"open_wing":true,"position":Vector3(0,.004,-6),"target":Vector3(0,.004,-10),"pitch":-.60,"detail":true},
        {"name":"hub_floor_s01_awakened","time":8.0,"quiet":true,"awakened":true,"target":Vector3(0,.004,0)},
        {"name":"hub_floor_completed_hub","time":8.0,"quiet":true,"completed":true,"target":Vector3(0,.004,0)}
    ]
    var captures: Array[Dictionary] = []
    for view: Dictionary in views:
        prologue.camera.position = Vector3(0,1.624,15)
        prologue.camera.rotation = Vector3.ZERO
        prologue._apply_timeline_pose(view["time"])
        # Read-only pose fixture: shipping smoke covers real spark event/audio.
        prologue.spark.visible = view["time"]>=1.0
        prologue.camera.make_current()
        if view.get("quiet",false):
            var projection := ArchiveProgress.fresh()
            var stage := ArchiveProgress.INTRO
            if view.get("awakened",false) or view.get("completed",false):
                projection["awakened"] = true
                projection["unlocked"][0] = true
                stage = ArchiveProgress.WING_ONE
            if view.get("completed",false):
                projection["light_restored"] = true
                projection["star_collected"] = true
                projection["hearth_collected"] = true
                projection["completed"][0] = true
                projection["unlocked"][1] = true
                stage = ArchiveProgress.WING_ONE
            if world.apply_stage_state(stage,projection)!=OK:
                push_error("Quiet roof review projection failed")
                get_tree().quit(1)
                return
            if view.get("open_wing",false):
                world.get_node("StageController").open_wing(0,false)
            player.spawn_at(Transform3D(Basis.IDENTITY,view.get("position",Vector3(0,.004,6))))
            player.look_at(view.get("target",Vector3(0,.004,0)))
            player.head.rotation.x = view.get("pitch",0.0)
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
    file.store_string(JSON.stringify({"status":"CAPTURED_FOR_REVIEW","scope":"hub_floor","quality":_quality,
        "captures":captures,"renderer":RenderingServer.get_current_rendering_method(),
        "device":RenderingServer.get_video_adapter_name(),"glow":environment.glow_enabled,
        "volumetrics":environment.volumetric_fog_enabled},"  "))
    file.close()
    game.queue_free()
    await get_tree().process_frame
    SceneRouter.unregister_stage(ArchiveProgress.PROLOGUE)
    print("ARCHIVE_HUB_FLOOR_REVIEW CAPTURED: %s; eight native floor/corridor/exterior views; original rail, quiet asleep/awakened/return states" % _quality)
    get_tree().quit(0)
