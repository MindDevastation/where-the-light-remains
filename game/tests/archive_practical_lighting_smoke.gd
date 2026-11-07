extends Node
## Actual scene mounts, quality invariants, quiet restore and canceled sequence.

var _checks := 0
var _failures: Array[String] = []

func _check(condition: bool, message: String) -> void:
    _checks += 1
    if not condition:
        _failures.append(message)
        push_error("ARCHIVE_PRACTICAL_LIGHTING FAIL: " + message)

func _ready() -> void:
    get_tree().create_timer(25.0,true).timeout.connect(func() -> void:
        push_error("ARCHIVE_PRACTICAL_LIGHTING timeout")
        get_tree().quit(1)
    )
    _run.call_deferred()

func _run() -> void:
    var before := GameState.capture_save().to_dict()
    var dirty: bool = SaveManager.get("_dirty")
    var preset: String = SettingsManager.graphics_preset
    var world := preload("res://worlds/archive/archive_main.tscn").instantiate() as ArchiveMain
    add_child(world)
    world.set_process(false)
    world.get_node("Prologue").set_process(false)
    await get_tree().physics_frame
    var space := world.get_world_3d().direct_space_state
    var shared: Mesh
    for name: String in ["Wall0L","Wall0R","Wall2R","Wall3L"]:
        var wall := world.get_node("Hub/"+name) as StaticBody3D
        var fixture := wall.get_node("HubPractical") as Node3D
        var mesh := fixture.get_node("Art").find_children("*","MeshInstance3D",true,false)[0] as MeshInstance3D
        if shared == null:
            shared = mesh.mesh
        _check(mesh.mesh==shared and fixture.scale==Vector3.ONE, "Accepted shared geometry/unit mount "+name)
        _check(fixture.global_position.y+mesh.mesh.get_aabb().position.y>2.5, "Fixture clears shipping head "+name)
        _check(fixture.find_children("*","CollisionObject3D",true,false).is_empty(), "No new player obstruction "+name)
        var ray := PhysicsRayQueryParameters3D.create(fixture.to_global(Vector3(0,0,.2)),fixture.to_global(Vector3(0,0,-.1)),1)
        var hit := space.intersect_ray(ray)
        _check(not hit.is_empty() and hit["collider"]==wall and (hit["position"] as Vector3).distance_to(fixture.global_position)<.001, "Existing wall collision face supports mount "+name)
        var light := fixture.get_node("Practical") as OmniLight3D
        _check(not light.shadow_enabled and is_equal_approx(light.omni_range,3), "No extra shadow pass/local falloff "+name)
        _check(light.global_position.z+light.omni_range<9.275 and light.global_position.z-light.omni_range>-15, "Sphere excludes exterior entry and S02 room "+name)
    var core := world.get_node("Hub/CoreLight") as OmniLight3D
    _check(core.global_position.z+core.omni_range<9.275 and core.global_position.z-core.omni_range>-15, "Core sphere excludes exterior and S02")
    _check(world.apply_stage_state(ArchiveProgress.PROLOGUE,ArchiveProgress.fresh())==OK, "Quiet S00 projection")
    for name: String in ["Wall0L","Wall0R","Wall2R","Wall3L"]:
        _check(not world.get_node("Hub/"+name+"/HubPractical").is_visible_in_tree(), "S00 has no interior warm light leak "+name)
    _check(world.get_node("Hub/Wall3R/EntryPractical").is_visible_in_tree(), "Original sole S00 warm practical remains visible")
    for quality: String in ["Low","Medium"]:
        SettingsManager.graphics_preset=quality
        SettingsManager.apply_runtime(false)
        SettingsManager.apply_scene_graphics()
        for awake: bool in [false,true]:
            var state := ArchiveProgress.fresh()
            state["awakened"]=awake
            state["unlocked"][0]=awake
            _check(world.apply_stage_state(ArchiveProgress.WING_ONE if awake else ArchiveProgress.INTRO,state)==OK, "Quiet projection "+quality+str(awake))
            _check(world.get_node("Hub/Wall0L/HubPractical").is_visible_in_tree(), "Hub practicals restore immediately after S00 "+quality+str(awake))
            _check(core.visible and is_equal_approx(core.light_energy,1.8 if awake else .30), "State lighting survives quality "+quality+str(awake))
            _check(not core.shadow_enabled and world.get("_awakening_elapsed")<0 and world.get("_lighting_tween")==null, "Quiet restore has no animation/shadow "+quality+str(awake))
            _check(world.get_node("Routes/Wing01/Channel").visible==awake and not world.get_node("Routes/Wing02/Channel").visible, "Only canonical eligible route gets its clue "+quality+str(awake))
    _check(world.apply_stage_state(ArchiveProgress.INTRO,ArchiveProgress.fresh())==OK, "Fresh reset before cancel")
    InputManager.set_mode(InputManager.Mode.GAMEPLAY)
    world._on_activation_requested()
    world._process(4.5)
    _check(core.light_energy>.30 and core.light_energy<1.8, "Real existing sequence clock produces intermediate light")
    _check(GameState.capture_save().to_dict()==before and SaveManager.get("_dirty")==dirty, "Cosmetic sequence does not publish progress")
    InputManager.set_mode(InputManager.Mode.UI)
    world._process(.01)
    _check(is_equal_approx(core.light_energy,.30) and core.light_color.is_equal_approx(Color(.43,.65,1)), "Later input owner cancels light back to dormant state")
    _check(world.get("_awakening_elapsed")<0 and not world.get_node("Routes/Wing01/Channel").visible, "Canceled sequence restores route with core")
    var state := ArchiveProgress.fresh()
    state["awakened"]=true
    state["unlocked"][0]=true
    state["light_restored"]=true
    state["star_collected"]=true
    state["hearth_collected"]=true
    state["completed"][0]=true
    state["unlocked"][1]=true
    _check(world.apply_stage_state(ArchiveProgress.WING_ONE,state)==OK, "Quiet Hearth projection")
    _check(world.get_node("Wing01/Room/RoomLight").light_color.is_equal_approx(Color(1,.68,.36)) and world.get_node("Wing01/Room/Hearth/Flame").visible, "Existing room warm state survives reduced global fill")
    _check(core.light_color.is_equal_approx(Color(1,.68,.36)) and GameState.capture_save().to_dict()==before and SaveManager.get("_dirty")==dirty, "Quiet completed projection is read-only")
    world.queue_free()
    await get_tree().process_frame
    SettingsManager.graphics_preset=preset
    SettingsManager.apply_runtime(false)
    if _failures.is_empty():
        print("ARCHIVE_PRACTICAL_LIGHTING PASS: %d assertions; actual mounts, Low/Medium state clues, quiet/canceled projection and unchanged progression" % _checks)
    get_tree().quit(0 if _failures.is_empty() else 1)
