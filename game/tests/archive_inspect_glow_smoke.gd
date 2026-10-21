extends Node
var _checks := 0
var _failures: Array[String] = []

func check(value: bool, label: String) -> void:
    _checks += 1
    if not value:
        _failures.append(label)
        push_error(label)

func _ready() -> void:
    _run.call_deferred()

func aim(player: FirstPersonPlayer, target: InteractionTarget, distance := 1.2) -> void:
    var point: Vector3 = target.get_parent().global_position
    player.spawn_at(Transform3D(Basis.IDENTITY,Vector3(point.x,.004,point.z+distance)))
    player.head.look_at(point)
    await get_tree().physics_frame
    await get_tree().physics_frame

func _run() -> void:
    var before := GameState.capture_save().to_dict()
    var dirty: bool = SaveManager.get("_dirty")
    var effects: bool = SettingsManager.effects
    var quality: String = SettingsManager.graphics_preset
    var game := preload("res://core/game_root/game_root.tscn").instantiate()
    add_child(game)
    var world := preload("res://worlds/archive/archive_main.tscn").instantiate() as ArchiveMain
    game.get_node("WorldSlot").add_child(world)
    world.get_node("Prologue").set_process(false)
    world.set_process(false)
    check(world.apply_stage_state(ArchiveProgress.INTRO,ArchiveProgress.fresh()) == OK,"Quiet intro projection")
    var player := game.get_node("PlayerContainer/Player") as FirstPersonPlayer
    var glow := world.get_node("InspectGlow") as ArchiveInspectGlow
    check(glow.bindings_valid() and glow.target_paths.size()==8,"Eight exact actual target/visual bindings")
    check(glow.get("_player")==player,"Bound to actual GameRoot player")
    InputManager.set_mode(InputManager.Mode.GAMEPLAY)
    player.set_active(true)
    var panel := world.get_node("Hub/Onboarding/Panel/InteractionTarget") as InteractionTarget
    for preset: String in ["Low","Medium"]:
        SettingsManager.graphics_preset=preset
        SettingsManager.effects=false
        EventBus.settings_changed.emit()
        await aim(player,panel)
        check(player.focused_target==panel and glow.active_visual_count()>0,"Actual ray enables inspect wash even with decorative effects off")
        var meshes := glow._meshes(world.get_node("Hub/Onboarding/Panel/Visual/Cover"))
        var material_before := meshes[0].get_active_material(0)
        check(meshes[0].material_overlay==glow.wash_material,"Existing geometry receives separate overlay")
        var authored_overlay := StandardMaterial3D.new()
        player.spawn_at(Transform3D(Basis.IDENTITY,Vector3(0,.004,5)))
        check(glow.active_visual_count()==0 and meshes[0].material_overlay==null,"Quiet spawn restores overlay immediately")
        meshes[0].material_overlay=authored_overlay
        await aim(player,panel)
        check(meshes[0].material_overlay==authored_overlay,"Existing overlay is never overwritten")
        player.spawn_at(Transform3D(Basis.IDENTITY,Vector3(0,.004,5)))
        meshes[0].material_overlay=null
        await aim(player,panel)
        InputManager.set_paused(true)
        check(player.focused_target==null and glow.active_visual_count()==0,"Pause clears real ray and wash")
        InputManager.set_paused(false)
        await aim(player,panel)
        panel.enabled=false
        await get_tree().physics_frame
        await get_tree().process_frame
        check(glow.active_visual_count()==0,"Consumed/disabled target cannot remain highlighted")
        panel.enabled=true
        await aim(player,panel,4.0)
        check(player.focused_target==null and glow.active_visual_count()==0,"Reach remains2.5m")
        check(meshes[0].get_active_material(0)==material_before,"Original base material identity preserved")
    var state:=ArchiveProgress.fresh()
    state["awakened"]=true;state["unlocked"][0]=true
    check(world.apply_stage_state(ArchiveProgress.WING_ONE,state)==OK,"Quiet Wing I projection")
    var outer:=world.get_node("Wing01/Room/Rings/Carrier/Outer/Grip/InteractionTarget") as InteractionTarget
    await aim(player,outer)
    check(player.focused_target==outer and glow.active_visual_count()>0,"Actual imported ring grip ray drives existing ring overlay")
    var blocker := StaticBody3D.new()
    var blocker_shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size=Vector3(.8,.8,.2)
    blocker_shape.shape=box
    blocker.add_child(blocker_shape)
    world.add_child(blocker)
    blocker.global_position=player.camera.global_position.lerp(outer.get_parent().global_position,.5)
    await get_tree().physics_frame
    await get_tree().physics_frame
    check(player.focused_target==null and glow.active_visual_count()==0,"Actual solid occlusion clears ray and wash")
    blocker.queue_free()
    await get_tree().physics_frame
    await get_tree().physics_frame
    check(player.focused_target==outer and glow.active_visual_count()>0,"Ray feedback recovers after occluder removal")
    InputManager.set_mode(InputManager.Mode.UI)
    check(glow.active_visual_count()==0,"UI mode clears feedback")
    check(GameState.capture_save().to_dict()==before and SaveManager.get("_dirty")==dirty,"Read-only logical save/dirty state")
    game.queue_free()
    await get_tree().process_frame
    check(not is_instance_valid(glow),"Unload frees listener and restores owned overlays")
    SettingsManager.effects=effects;SettingsManager.graphics_preset=quality
    print("ARCHIVE_INSPECT_GLOW PASS: %d assertions; actual player ray, original meshes/materials, Low/effects/pause/lifetime/read-only state" % _checks)
    get_tree().quit(0 if _failures.is_empty() else 1)
