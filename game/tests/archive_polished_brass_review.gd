extends Node
## Same-frame shipping material pairs; isolated specimens are explicitly separate.
var _output := ""
var _quality := "low"
var _captures: Array[Dictionary] = []

func _ready() -> void:
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--review-output="): _output=arg.trim_prefix("--review-output=")
        elif arg.begins_with("--quality="): _quality=arg.trim_prefix("--quality=")
    _run.call_deferred()

func _capture(name: String, metadata: Dictionary) -> void:
    for frame in 6: await get_tree().process_frame
    await RenderingServer.frame_post_draw
    var image:=get_viewport().get_texture().get_image()
    var file:=name+"_"+_quality+".png"
    if image.save_png(_output.path_join(file))!=OK:
        push_error("Could not save polished brass review")
        get_tree().quit(1)
        return
    metadata.merge({"file":file,"size":[image.get_width(),image.get_height()],
        "draw_calls":int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))})
    _captures.append(metadata)

func _label(canvas: CanvasLayer, text: String, y: float) -> void:
    var label:=Label.new()
    label.text=text;label.position=Vector2(0,y);label.size=Vector2(960,45)
    label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size",24)
    canvas.add_child(label)

func _specimens(polished: StandardMaterial3D) -> void:
    var stage:=Node3D.new();add_child(stage)
    var world:=WorldEnvironment.new();stage.add_child(world)
    var environment:=Environment.new();world.environment=environment
    environment.background_mode=Environment.BG_COLOR;environment.background_color=Color("141b24")
    environment.ambient_light_source=Environment.AMBIENT_SOURCE_SKY
    environment.ambient_light_energy=.55;environment.reflected_light_source=Environment.REFLECTION_SOURCE_SKY
    environment.tonemap_mode=Environment.TONE_MAPPER_ACES
    var sky:=Sky.new();var sky_material:=ProceduralSkyMaterial.new()
    sky_material.sky_top_color=Color("374456");sky_material.sky_horizon_color=Color("b8c1ce")
    sky_material.ground_bottom_color=Color("25232b");sky_material.ground_horizon_color=Color("8a8583")
    sky.sky_material=sky_material;environment.sky=sky
    var key:=DirectionalLight3D.new();key.rotation_degrees=Vector3(-22,-30,0);key.light_energy=1.25;stage.add_child(key)
    var fill:=DirectionalLight3D.new();fill.rotation_degrees=Vector3(15,50,0);fill.light_color=Color("a6c6ed");fill.light_energy=.3;stage.add_child(fill)
    var camera:=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=7.2;camera.position=Vector3(0,0,12);stage.add_child(camera);camera.current=true
    var canvas:=CanvasLayer.new();add_child(canvas)
    _label(canvas,"MAT-002 · ИЗОЛИРОВАННЫЕ ОБРАЗЦЫ",25)
    _label(canvas,"Полированная латунь                      Состаренная латунь",445)
    var materials: Array[StandardMaterial3D]=[polished,load("res://art/materials/m_aged_brass.tres")]
    var specimens: Array[MeshInstance3D]=[]
    for i in 2:
        var specimen:=MeshInstance3D.new();var sphere:=SphereMesh.new()
        sphere.radius=1.0;sphere.height=2.0;sphere.radial_segments=64;sphere.rings=32
        specimen.mesh=sphere;specimen.position=Vector3(-1.7 if i==0 else 1.7,0,0)
        specimen.material_override=materials[i];stage.add_child(specimen);specimens.append(specimen)
    for lighting: String in ["neutral","warm","cool","tiles"]:
        key.light_color=Color("ffb878") if lighting=="warm" else (Color("9abfff") if lighting=="cool" else Color("fff4df"))
        if lighting=="tiles":
            for i in 2:
                var quad:=QuadMesh.new();quad.size=Vector2(2.5,2.5)
                var arrays:=quad.get_mesh_arrays();var uv: PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV]
                for vertex in uv.size(): uv[vertex]*=4.0
                arrays[Mesh.ARRAY_TEX_UV]=uv
                var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
                specimens[i].mesh=mesh
        for frame in 20: await get_tree().process_frame
        await _capture("specimen_"+lighting,{"scope":"isolated_specimen","lighting":lighting,
            "tiles":4 if lighting=="tiles" else 1,"shipping_lights":false,"material_paths":[materials[0].resource_path,materials[1].resource_path]})
    canvas.queue_free();stage.queue_free();await get_tree().process_frame

func _run() -> void:
    if _output.is_empty() or _quality not in ["low","medium"]:
        get_tree().quit(1);return
    SettingsManager.graphics_preset="Low" if _quality=="low" else "Medium"
    SettingsManager.effects=false;SettingsManager.apply_runtime(false)
    var game:=preload("res://core/game_root/game_root.tscn").instantiate();add_child(game)
    var definition:=StageDefinition.new();definition.stage_id=ArchiveProgress.INTRO
    definition.scene_path="res://worlds/archive/archive_main.tscn";definition.presentation=StageDefinition.Presentation.IN_PLACE
    if SceneRouter.register_stage(definition)!=OK: get_tree().quit(1);return
    var saved:=SaveGame.new();saved.stage_id=ArchiveProgress.INTRO;saved.checkpoint_id=&"prologue_completed"
    saved.milestones={"prologue_completed":true};ArchiveProgress.write_projection(saved)
    if await SceneRouter.request_resume_stage(saved)!=OK: get_tree().quit(1);return
    var before:=GameState.capture_save().to_dict();var dirty: bool=SaveManager.get("_dirty")
    var world:=game.get_node("WorldSlot").get_child(0) as ArchiveMain
    var player:=game.get_node("PlayerContainer/Player") as FirstPersonPlayer
    var glow:=world.get_node("InspectGlow") as ArchiveInspectGlow
    var outer:=world.get_node("Hub/Astrolabe/OuterRing") as MeshInstance3D
    var inner:=world.get_node("Hub/Astrolabe/InnerRing") as MeshInstance3D
    var polished:=outer.material_override as StandardMaterial3D
    var previous: Material=(world.get_node("Hub/Finale/Table") as MeshInstance3D).material_override
    world.set_process(false);world.get_node("Prologue").set_process(false)
    var views: Array[Dictionary]=[
        {"name":"sleeping","position":Vector3(0,.004,3.8),"target":Vector3(0,1.65,0)},
        {"name":"oblique","position":Vector3(1.7,.004,2.9),"target":Vector3(0,1.6,0)},
        {"name":"panel","position":Vector3(-.65,.004,2.1),"target":Vector3(-.65,1.25,.9)},
        {"name":"awakened","position":Vector3(0,.004,3.8),"target":Vector3(0,1.65,0),"awake":true}
    ]
    for view: Dictionary in views:
        if view.get("awake",false):
            var state:=ArchiveProgress.fresh();state["awakened"]=true;state["unlocked"][0]=true
            if world.apply_stage_state(ArchiveProgress.WING_ONE,state)!=OK: get_tree().quit(1);return
        InputManager.set_mode(InputManager.Mode.GAMEPLAY);player.set_active(true)
        player.spawn_at(Transform3D(Basis.IDENTITY,view["position"]))
        player.head.look_at(view["target"]);player.camera.make_current()
        for frame in 12: await get_tree().physics_frame
        if view["name"]=="panel" and player.focused_target!=world.get_node("Hub/Onboarding/Panel/InteractionTarget"):
            push_error("Polished brass review missed actual onboarding ray")
            get_tree().quit(1);return
        player.set_physics_process(false);glow.set_process(false)
        for enabled: bool in [true,false]:
            outer.material_override=polished if enabled else previous;inner.material_override=outer.material_override
            await _capture(view["name"]+("_polished" if enabled else "_previous"),{"scope":"shipping_pair",
                "view":view["name"],"polished":enabled,"shipping_lights":true,"decorative_effects":SettingsManager.effects,
                "camera_transform":str(player.camera.global_transform),"outer_transform":str(outer.global_transform),
                "inner_transform":str(inner.global_transform),"material":outer.material_override.resource_path,
                "actual_ray_target":str(player.focused_target.get_path()) if player.focused_target!=null else "",
                "active_overlays":glow.active_visual_count()})
        outer.material_override=polished;inner.material_override=polished;glow.set_process(true)
    game.queue_free();await get_tree().process_frame
    SceneRouter.unregister_stage(ArchiveProgress.INTRO)
    if _quality=="medium": await _specimens(polished)
    if before!=GameState.capture_save().to_dict() or dirty!=SaveManager.get("_dirty"):
        push_error("Polished brass native review mutated progression");get_tree().quit(1);return
    var file:=FileAccess.open(_output.path_join("captures_"+_quality+".json"),FileAccess.WRITE)
    file.store_string(JSON.stringify({"status":"CAPTURED_FOR_REVIEW","scope":"polished_brass","quality":_quality,
        "renderer":RenderingServer.get_current_rendering_method(),"device":RenderingServer.get_video_adapter_name(),"captures":_captures},"  "));file.close()
    print("ARCHIVE_POLISHED_BRASS_REVIEW CAPTURED: ",_quality,"; ",_captures.size()," actual native frames; readonly DTO/dirty")
    get_tree().quit(0)
