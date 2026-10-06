extends Node
## CLI-only instrumented actual GameRoot room; never claims target-device acceptance.

var _output := ""
var _quality := "low"
var _samples := 180
var _warmup := 45

func _ready() -> void:
    get_tree().create_timer(240.0,true).timeout.connect(func() -> void:
        push_error("ARCHIVE_ROOM_PROFILE timeout")
        get_tree().quit(1)
    )
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--profile-output="):
            _output = arg.trim_prefix("--profile-output=")
        elif arg.begins_with("--quality="):
            _quality = arg.trim_prefix("--quality=")
        elif arg.begins_with("--samples="):
            _samples = int(arg.trim_prefix("--samples="))
        elif arg.begins_with("--warmup="):
            _warmup = int(arg.trim_prefix("--warmup="))
    _run.call_deferred()

func _warm_projection() -> Dictionary:
    var state := ArchiveProgress.fresh()
    state["awakened"] = true
    state["unlocked"][0] = true
    state["light_restored"] = true
    state["star_collected"] = true
    state["hearth_collected"] = true
    state["completed"][0] = true
    state["unlocked"][1] = true
    return state

func _run() -> void:
    if _output.is_empty() or _quality not in ["low","medium"] or _samples<60 or _samples>600 or _warmup<15 or _warmup>180:
        push_error("Invalid bounded room profile output/quality/sample count")
        get_tree().quit(1)
        return
    SettingsManager.graphics_preset = "Low" if _quality == "low" else "Medium"
    SettingsManager.resolution = Vector2i(1920,1080)
    SettingsManager.fullscreen = false
    SettingsManager.apply_runtime(true)
    Engine.max_fps = 0
    DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
    var game := preload("res://core/game_root/game_root.tscn").instantiate()
    add_child(game)
    var definition := StageDefinition.new()
    definition.stage_id = ArchiveProgress.WING_ONE
    definition.scene_path = "res://worlds/archive/archive_main.tscn"
    definition.presentation = StageDefinition.Presentation.IN_PLACE
    if SceneRouter.register_stage(definition) != OK:
        push_error("Room profile registration failed")
        get_tree().quit(1)
        return
    var saved := SaveGame.new()
    saved.stage_id = ArchiveProgress.WING_ONE
    saved.checkpoint_id = &"archive_awakened"
    saved.milestones = {"archive_awakened":true,"wing_01_unlocked":true}
    ArchiveProgress.write_projection(saved)
    if await SceneRouter.request_resume_stage(saved) != OK:
        push_error("Actual room profile resume failed")
        get_tree().quit(1)
        return
    var before := GameState.capture_save().to_dict()
    var dirty: bool = SaveManager.get("_dirty")
    var world := game.get_node("WorldSlot").get_child(0) as ArchiveMain
    var player := game.get_node("PlayerContainer/Player") as FirstPersonPlayer
    player.set_physics_process(false)
    var viewport := get_viewport()
    var rid := viewport.get_viewport_rid()
    RenderingServer.viewport_set_measure_render_time(rid,true)
    var cases := [
        {"name":"cold_hero","position":Vector3(1.8,.02,-20.4),"target":Vector3(0,.02,-23.5),"pitch":.04},
        {"name":"cold_roof","position":Vector3(-1,.02,-20),"target":Vector3(0,.02,-21),"pitch":1.02},
        {"name":"warm_hero","position":Vector3(1.8,.02,-20.4),"target":Vector3(0,.02,-23.5),"pitch":.04,"warm":true}
    ]
    var records: Array[Dictionary] = []
    for item: Dictionary in cases:
        if item.get("warm",false) and world.apply_stage_state(ArchiveProgress.WING_ONE,_warm_projection()) != OK:
            push_error("Room profile quiet warm projection failed")
            get_tree().quit(1)
            return
        player.spawn_at(Transform3D(Basis.IDENTITY,item["position"]))
        player.look_at(item["target"])
        player.head.rotation.x = item["pitch"]
        player.camera.make_current()
        var warmup_started := Time.get_ticks_usec()
        var warmup_frames := 0
        while warmup_frames<_warmup or Time.get_ticks_usec()-warmup_started<1200000:
            await get_tree().process_frame
            warmup_frames += 1
        var frames: Array[Dictionary] = []
        var previous := Time.get_ticks_usec()
        for frame in _samples:
            await get_tree().process_frame
            var tick := Time.get_ticks_usec()
            frames.append({"frame":frame,"wall_ms":float(tick-previous)/1000.0,
                "main_process_ms":Performance.get_monitor(Performance.TIME_PROCESS)*1000.0,
                "physics_process_ms":Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000.0,
                "render_setup_cpu_ms":RenderingServer.get_frame_setup_time_cpu(),
                "viewport_render_cpu_ms":RenderingServer.viewport_get_measured_render_time_cpu(rid),
                "viewport_renderer_gpu_ms":RenderingServer.viewport_get_measured_render_time_gpu(rid),
                "draw_calls":int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
                "rendered_primitives":int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
                "texture_bytes":int(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)),
                "render_buffer_bytes":int(Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED)),
                "renderer_video_bytes":int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)),
                "engine_static_bytes":int(Performance.get_monitor(Performance.MEMORY_STATIC))})
            previous = tick
        await RenderingServer.frame_post_draw
        var picture := viewport.get_texture().get_image()
        var filename: String = item["name"]+"_"+_quality+"_1080p.png"
        if picture.save_png(_output.path_join(filename)) != OK:
            push_error("Room profile capture failed")
            get_tree().quit(1)
            return
        var case_record := {"name":item["name"],"capture":filename,"capture_size":[picture.get_width(),picture.get_height()],
            "warmup_frames":warmup_frames,"minimum_warmup_frames":_warmup,"minimum_warmup_seconds":1.2,"samples":frames}
        records.append(case_record)
        var case_file := FileAccess.open(_output.path_join("case_"+item["name"]+"_"+_quality+".json"),FileAccess.WRITE)
        if case_file == null:
            push_error("Could not preserve completed profile case")
            get_tree().quit(1)
            return
        case_file.store_string(JSON.stringify(case_record,"  "))
        case_file.close()
        print("ARCHIVE_ROOM_PROFILE CASE: ",item["name"],"; ",_samples," measured frames")
    var shadow_lights := 0
    var lights := world.find_children("*","Light3D",true,false)
    for light: Light3D in lights:
        if light.shadow_enabled and light.is_visible_in_tree():
            shadow_lights += 1
    var environment: Environment = world.get_node("Environment").environment
    var file := FileAccess.open(_output.path_join("profile_"+_quality+".json"),FileAccess.WRITE)
    file.store_string(JSON.stringify({"status":"MEASURED","quality":_quality,"records":records,
        "scope":"Instrumented actual shipping scene; renderer timings describe the identified device only, not target acceptance.",
        "engine":Engine.get_version_info()["string"],"display":DisplayServer.get_name(),
        "renderer":RenderingServer.get_current_rendering_method(),"device":RenderingServer.get_video_adapter_name(),
        "vendor":RenderingServer.get_video_adapter_vendor(),"api":RenderingServer.get_video_adapter_api_version(),
        "window_size":[get_window().size.x,get_window().size.y],"render_scale":viewport.scaling_3d_scale,
        "vsync":DisplayServer.window_get_vsync_mode(),"max_fps":Engine.max_fps,
        "light_count":lights.size(),"visible_shadow_lights":shadow_lights,"glow":environment.glow_enabled,
        "volumetrics":environment.volumetric_fog_enabled,"ssr":environment.ssr_enabled,
        "timing_note":"Wall intervals include CPU/software or physical GPU/presentation wait and instrumentation. Main/physics/render setup/viewport CPU/GPU are separate monitors; do not sum overlapping monitors into a fabricated frame time. Zero renderer GPU timing may mean unavailable."},"  "))
    file.close()
    RenderingServer.viewport_set_measure_render_time(rid,false)
    if GameState.capture_save().to_dict() != before or SaveManager.get("_dirty") != dirty:
        push_error("Room profile changed progression/dirty state")
        get_tree().quit(1)
        return
    game.queue_free()
    await get_tree().process_frame
    SceneRouter.unregister_stage(ArchiveProgress.WING_ONE)
    print("ARCHIVE_ROOM_PROFILE MEASURED: ",_quality,"; three actual 1080p cases; not target-device acceptance")
    get_tree().quit(0)
