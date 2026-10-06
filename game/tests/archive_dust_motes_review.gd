extends Node
## Paired native on/off frames with fixed shipping camera and paused world.
var _output := ""
var _quality := "low"

func _ready() -> void:
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--review-output="):
            _output = arg.trim_prefix("--review-output=")
        elif arg.begins_with("--quality="):
            _quality = arg.trim_prefix("--quality=")
    _run.call_deferred()

func _run() -> void:
    if _output.is_empty() or _quality not in ["low", "medium"]:
        get_tree().quit(1)
        return
    SettingsManager.graphics_preset = "Low" if _quality == "low" else "Medium"
    SettingsManager.effects = true
    SettingsManager.apply_runtime(false)
    var game := preload("res://core/game_root/game_root.tscn").instantiate()
    add_child(game)
    var definition := StageDefinition.new()
    definition.stage_id = ArchiveProgress.PROLOGUE
    definition.scene_path = "res://worlds/archive/archive_main.tscn"
    definition.presentation = StageDefinition.Presentation.FADE
    definition.player_active = false
    definition.input_mode = InputManager.Mode.CINEMATIC
    if SceneRouter.register_stage(definition) != OK:
        get_tree().quit(1)
        return
    var saved := SaveGame.new()
    ArchiveProgress.write_projection(saved)
    if await SceneRouter.request_resume_stage(saved) != OK:
        get_tree().quit(1)
        return
    var before := GameState.capture_save().to_dict()
    var dirty: bool = SaveManager.get("_dirty")
    var world := game.get_node("WorldSlot").get_child(0) as ArchiveMain
    var player := game.get_node("PlayerContainer/Player") as FirstPersonPlayer
    world.set_process(false)
    player.set_physics_process(false)
    world.get_node("Prologue").set_process(false)
    var clouds := [world.get_node("Hub/DustMotes"), world.get_node("Wing01/Room/DustMotes")]
    var views := [
        {"name":"s00_closed", "stage":ArchiveProgress.PROLOGUE,"position":Vector3(0,.004,15),"target":Vector3(0,.004,0)},
        {"name":"s01_asleep", "stage":ArchiveProgress.INTRO,"position":Vector3(3,.004,5),"target":Vector3(3,.004,-2)},
        {"name":"s01_awakened", "stage":ArchiveProgress.WING_ONE,"position":Vector3(3,.004,5),"target":Vector3(3,.004,-2)},
        {"name":"s02_cold", "stage":ArchiveProgress.WING_ONE,"position":Vector3(1.8,.004,-18),"target":Vector3(1.8,.004,-24)},
        {"name":"s02_warm", "stage":ArchiveProgress.WING_ONE,"warm":true,"position":Vector3(1.8,.004,-18),"target":Vector3(1.8,.004,-24)}
    ]
    var captures: Array[Dictionary] = []
    for view: Dictionary in views:
        var state := ArchiveProgress.fresh()
        if view["stage"] == ArchiveProgress.WING_ONE:
            state["awakened"] = true
            state["unlocked"][0] = true
        if view.get("warm",false):
            state["light_restored"] = true
            state["star_collected"] = true
            state["hearth_collected"] = true
            state["completed"][0] = true
            state["unlocked"][1] = true
        if world.apply_stage_state(view["stage"],state) != OK:
            get_tree().quit(1)
            return
        player.spawn_at(Transform3D(Basis.IDENTITY, view["position"]))
        player.look_at(view["target"])
        player.camera.make_current()
        for cloud: ArchiveDustMotes in clouds:
            cloud._sync()
        for frame in 24:
            await get_tree().process_frame
        # All accepted presentation and GPU particle clocks freeze for the pair.
        InputManager.set_paused(true)
        for frame in 3:
            await get_tree().process_frame
        var active: bool = view["stage"] != ArchiveProgress.PROLOGUE
        for enabled: bool in [true,false]:
            for cloud: ArchiveDustMotes in clouds:
                cloud.visible = active and enabled
            for frame in 3:
                await get_tree().process_frame
            await RenderingServer.frame_post_draw
            var image := get_viewport().get_texture().get_image()
            var filename: String = view["name"] + ("_on_" if enabled else "_off_") + _quality + ".png"
            if image.save_png(_output.path_join(filename)) != OK:
                get_tree().quit(1)
                return
            captures.append({"file":filename,"view":view["name"],"enabled":enabled,"stage":str(view["stage"]),
                "size":[image.get_width(),image.get_height()],"amount_per_volume":clouds[0].particles.amount,
                "draw_calls":int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
                "light_count":world.find_children("*","Light3D",true,false).size(),"gpu_speed":clouds[0].particles.speed_scale})
        InputManager.set_paused(false)
        for cloud: ArchiveDustMotes in clouds:
            cloud._sync()
    if before != GameState.capture_save().to_dict() or dirty != SaveManager.get("_dirty"):
        push_error("Dust native review wrote progression")
        get_tree().quit(1)
        return
    var f := FileAccess.open(_output.path_join("captures_"+_quality+".json"),FileAccess.WRITE)
    f.store_string(JSON.stringify({"scope":"dust_motes","status":"CAPTURED_FOR_REVIEW","quality":_quality,
        "renderer":RenderingServer.get_current_rendering_method(),"device":RenderingServer.get_video_adapter_name(),
        "captures":captures},"  "))
    f.close()
    game.queue_free()
    await get_tree().process_frame
    SceneRouter.unregister_stage(ArchiveProgress.PROLOGUE)
    print("ARCHIVE_DUST_MOTES_REVIEW CAPTURED: %s; ten paused native on/off views; readonly state" % _quality)
    get_tree().quit(0)
