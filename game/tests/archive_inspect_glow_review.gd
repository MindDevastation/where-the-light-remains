extends Node
## Real ray selection; fixed shipping geometry/camera, paired wash only.
var _output := ""
var _quality := "low"

func _ready() -> void:
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--review-output="):
            _output=arg.trim_prefix("--review-output=")
        elif arg.begins_with("--quality="):
            _quality=arg.trim_prefix("--quality=")
    _run.call_deferred()

func _run() -> void:
    if _output.is_empty() or _quality not in ["low","medium"]:
        get_tree().quit(1)
        return
    SettingsManager.graphics_preset="Low" if _quality=="low" else "Medium"
    SettingsManager.effects=false
    SettingsManager.apply_runtime(false)
    var game:=preload("res://core/game_root/game_root.tscn").instantiate()
    add_child(game)
    var definition:=StageDefinition.new()
    definition.stage_id=ArchiveProgress.PROLOGUE
    definition.scene_path="res://worlds/archive/archive_main.tscn"
    definition.presentation=StageDefinition.Presentation.FADE
    definition.player_active=false
    definition.input_mode=InputManager.Mode.CINEMATIC
    if SceneRouter.register_stage(definition)!=OK:
        get_tree().quit(1)
        return
    var saved:=SaveGame.new()
    ArchiveProgress.write_projection(saved)
    if await SceneRouter.request_resume_stage(saved)!=OK:
        get_tree().quit(1)
        return
    var before:=GameState.capture_save().to_dict()
    var dirty: bool=SaveManager.get("_dirty")
    var world:=game.get_node("WorldSlot").get_child(0) as ArchiveMain
    var player:=game.get_node("PlayerContainer/Player") as FirstPersonPlayer
    var glow:=world.get_node("InspectGlow") as ArchiveInspectGlow
    world.set_process(false)
    world.get_node("Prologue").set_process(false)
    var captures: Array[Dictionary]=[]
    var views: Array[Dictionary]=[
        {"name":"panel","stage":ArchiveProgress.INTRO,"target":"Hub/Onboarding/Panel/InteractionTarget"},
        {"name":"outer","stage":ArchiveProgress.WING_ONE,"target":"Wing01/Room/Rings/Carrier/Outer/Grip/InteractionTarget"}
    ]
    for view: Dictionary in views:
        var state:=ArchiveProgress.fresh()
        if view["stage"]==ArchiveProgress.WING_ONE:
            state["awakened"]=true;state["unlocked"][0]=true
        if world.apply_stage_state(view["stage"],state)!=OK:
            get_tree().quit(1)
            return
        var target:=world.get_node(view["target"]) as InteractionTarget
        var point: Vector3=target.get_parent().global_position
        InputManager.set_mode(InputManager.Mode.GAMEPLAY)
        player.set_active(true)
        player.spawn_at(Transform3D(Basis.IDENTITY,Vector3(point.x,.004,point.z+1.2)))
        player.head.look_at(point)
        for frame in 12:
            await get_tree().physics_frame
        if player.focused_target!=target or glow.active_visual_count()==0:
            push_error("Native inspect review did not acquire actual target ray")
            get_tree().quit(1)
            return
        player.set_physics_process(false)
        glow.set_process(false)
        for enabled: bool in [true,false]:
            if not enabled: glow._clear()
            for frame in 3: await get_tree().process_frame
            await RenderingServer.frame_post_draw
            var image:=get_viewport().get_texture().get_image()
            var name: String=view["name"]+("_on_" if enabled else "_off_")+_quality+".png"
            if image.save_png(_output.path_join(name))!=OK:
                get_tree().quit(1)
                return
            captures.append({"file":name,"view":view["name"],"enabled":enabled,
                "actual_ray_target":str(player.focused_target.get_path()),"active_overlay_meshes":glow.active_visual_count(),
                "decorative_effects":SettingsManager.effects,"size":[image.get_width(),image.get_height()],
                "draw_calls":int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))})
        glow.set_process(true)
    if before!=GameState.capture_save().to_dict() or dirty!=SaveManager.get("_dirty"):
        push_error("Inspect native review mutated progression")
        get_tree().quit(1)
        return
    var f:=FileAccess.open(_output.path_join("captures_"+_quality+".json"),FileAccess.WRITE)
    f.store_string(JSON.stringify({"scope":"inspect_glow","status":"CAPTURED_FOR_REVIEW","quality":_quality,
        "renderer":RenderingServer.get_current_rendering_method(),"device":RenderingServer.get_video_adapter_name(),"captures":captures},"  "))
    f.close()
    game.queue_free()
    await get_tree().process_frame
    SceneRouter.unregister_stage(ArchiveProgress.PROLOGUE)
    print("ARCHIVE_INSPECT_GLOW_REVIEW CAPTURED: %s; four actual-ray native paired frames; original materials and readonly saves" % _quality)
    get_tree().quit(0)
