extends Node
## Real GameRoot/player, partial controls and quiet complete render projections.

var _output := ""
var _quality := "low"

func _ready() -> void:
    get_tree().create_timer(65.0,true).timeout.connect(func() -> void:
        push_error("ARCHIVE_BOOKCASE_REVIEW timeout")
        get_tree().quit(1)
    )
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--review-output="):
            _output = arg.trim_prefix("--review-output=")
        elif arg.begins_with("--quality="):
            _quality = arg.trim_prefix("--quality=")
    _run.call_deferred()

func _projection(star: bool, hearth: bool) -> Dictionary:
    var state := ArchiveProgress.fresh()
    state["awakened"] = true
    state["unlocked"][0] = true
    state["light_restored"] = star
    state["star_collected"] = star
    state["hearth_collected"] = hearth
    if hearth:
        state["completed"][0] = true
        state["unlocked"][1] = true
    return state

func _run() -> void:
    if _output.is_empty() or _quality not in ["low","medium"]:
        push_error("Missing bookcase review output/quality")
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
        push_error("Bookcase review registration failed")
        get_tree().quit(1)
        return
    var saved := SaveGame.new()
    saved.stage_id = ArchiveProgress.WING_ONE
    saved.checkpoint_id = &"archive_awakened"
    saved.milestones = {"archive_awakened":true,"wing_01_unlocked":true}
    ArchiveProgress.write_projection(saved)
    if await SceneRouter.request_resume_stage(saved) != OK:
        push_error("Bookcase shipping resume failed")
        get_tree().quit(1)
        return
    var before := GameState.capture_save().to_dict()
    var dirty: bool = SaveManager.get("_dirty")
    var world := game.get_node("WorldSlot").get_child(0) as ArchiveMain
    var player := game.get_node("PlayerContainer/Player") as FirstPersonPlayer
    player.set_physics_process(false)
    var views := [
        {"name":"bookcase_entrance","position":Vector3(0,.02,-16),"target":Vector3(0,.02,-23),"pitch":.20},
        {"name":"bookcase_left","position":Vector3(-3.1,.02,-17),"target":Vector3(-4.8,.02,-17),"pitch":-.12},
        {"name":"bookcase_right","position":Vector3(3.1,.02,-25),"target":Vector3(4.8,.02,-25),"pitch":-.12},
        {"name":"bookcase_hero","position":Vector3(1.8,.02,-20.4),"target":Vector3(0,.02,-23.5),"pitch":.04},
        {"name":"bookcase_reverse","position":Vector3(0,.02,-25),"target":Vector3(0,.02,-19),"pitch":.20},
        {"name":"bookcase_star","position":Vector3(1.5,.02,-24.5),"target":Vector3(0,.02,-25.3),"pitch":.04,"star":true},
        {"name":"bookcase_warm","position":Vector3(1.8,.02,-20.4),"target":Vector3(0,.02,-23.5),"pitch":.04,"warm":true},
        {"name":"bookcase_hearth","position":Vector3(-2.8,.02,-21.8),"target":Vector3(-2.8,.02,-24),"pitch":-.33}
    ]
    var captures: Array[Dictionary] = []
    for view: Dictionary in views:
        if view.get("partial",false):
            if world.get_node("Wing01/Room/Rings").rotate_ring(0) != OK:
                push_error("Partial real ring control failed")
                get_tree().quit(1)
                return
        if view.get("star",false) or view.get("warm",false):
            if world.apply_stage_state(ArchiveProgress.WING_ONE,_projection(true,view.get("warm",false))) != OK:
                push_error("Quiet Star/Hearth projection failed")
                get_tree().quit(1)
                return
        if view.get("focus",false):
            if world.get_node("Wing01/Room/Focus").cycle() != OK:
                push_error("Real first focus adjustment failed")
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
        if image.save_png(_output.path_join(filename)) != OK:
            push_error("Could not capture bookcase view")
            get_tree().quit(1)
            return
        var segments: Array[bool] = []
        for i in 4:
            segments.append(world.get_node("Wing01/Room/BeamSegments/Segment"+str(i)).visible)
        var star := world.get_node("Wing01/Room/Star") as Sprite3D
        captures.append({"name":view["name"],"file":filename,"size":[image.get_width(),image.get_height()],
            "segments":segments,"star_visible":star.visible,"star_alpha":star.modulate.a,
            "focus_x":world.get_node("Wing01/Room/Focus/Beam").scale.x,
            "hearth_visible":world.get_node("Wing01/Room/Hearth/Flame").visible,
            "draw_calls":int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
            "texture_bytes":int(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED))})
    if GameState.capture_save().to_dict() != before or SaveManager.get("_dirty") != dirty:
        push_error("Bookcase review mutated progression/dirty state")
        get_tree().quit(1)
        return
    var environment: Environment = world.get_node("Environment").environment
    var file := FileAccess.open(_output.path_join("captures_"+_quality+".json"),FileAccess.WRITE)
    file.store_string(JSON.stringify({"status":"CAPTURED_FOR_REVIEW","scope":"bookcase","quality":_quality,
        "captures":captures,"renderer":RenderingServer.get_current_rendering_method(),
        "device":RenderingServer.get_video_adapter_name(),"glow":environment.glow_enabled,
        "volumetrics":environment.volumetric_fog_enabled},"  "))
    file.close()
    game.queue_free()
    await get_tree().process_frame
    SceneRouter.unregister_stage(ArchiveProgress.WING_ONE)
    print("ARCHIVE_BOOKCASE_REVIEW CAPTURED: %s; eight actual player views; original shared bookcases and quiet cold/warm projections" % _quality)
    get_tree().quit(0)
