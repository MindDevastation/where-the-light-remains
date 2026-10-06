extends Node
## Reconstructed S01 + narrow progression transaction; real rays, events and IO.

var _failures: Array[String] = []
var _checks := 0


func _ready() -> void:
    get_tree().create_timer(35.0, true).timeout.connect(func() -> void:
        push_error("ARCHIVE_PROGRESSION FAIL: timeout")
        get_tree().quit(1)
    )
    _run.call_deferred()


func _check(condition: bool, message: String) -> void:
    _checks += 1
    if not condition:
        _failures.append(message)
        push_error("ARCHIVE_PROGRESSION FAIL: " + message)


func _press_interact() -> void:
    var press := InputEventAction.new()
    press.action = &"interact"
    press.pressed = true
    Input.parse_input_event(press)
    await get_tree().physics_frame
    await get_tree().physics_frame
    press = InputEventAction.new()
    press.action = &"interact"
    press.pressed = false
    Input.parse_input_event(press)
    await get_tree().physics_frame


func _run() -> void:
    var original := GameState.capture_save()
    var dirty: bool = SaveManager.get("_dirty")
    var duration := SceneRouter.fade_duration
    var rings := LightRingPuzzle.new()
    var exact := 0
    for a in 4:
        for b in 4:
            for c in 4:
                rings.set("_positions", Vector3i(a, b, c))
                var prefix := 0
                for index in 3:
                    if Vector3i(a, b, c)[index] != Vector3i(1, 2, 3)[index]:
                        break
                    prefix += 1
                _check(rings.connected_segments() == prefix, "Each of 64 ring combinations has deterministic contiguous prefix")
                if prefix == 3:
                    exact += 1
    _check(exact == 1, "Exactly one full connection in the 64-state space")
    rings.restore_completed(false)
    for index in 3:
        for click in index + 1:
            _check(rings.rotate_ring(index) == OK, "Discrete ring step")
    _check(rings.locked and rings.rotate_ring(0) == ERR_UNAUTHORIZED and rings.reset_local() == ERR_UNAUTHORIZED, "Accepted fragment cannot be reset by ring input")
    rings.free()
    var focus := LightFocusPuzzle.new()
    _check(focus.cycle() == ERR_UNAUTHORIZED, "Focus unavailable before Star")
    _check(focus.restore_state(true, false) == OK and focus.position_index == 0, "Focus restored at first unsolved stop")
    _check(focus.cycle() == OK and not focus.locked and focus.cycle() == OK and focus.locked, "Five-stop focus locks only at authored target")
    _check(focus.cycle() == ERR_UNAUTHORIZED and focus.restore_state(false, true) == ERR_INVALID_PARAMETER, "Completed focus cannot replay or precede Star")
    focus.free()
    var game := preload("res://core/game_root/game_root.tscn").instantiate()
    add_child(game)
    var slot: Node3D = game.get_node("WorldSlot")
    var player: FirstPersonPlayer = game.get_node("PlayerContainer/Player")
    var fade: FadeOverlay = game.get_node("TransitionLayer/FadeOverlay")
    for id in ArchiveProgress.STAGES:
        var definition := StageDefinition.new()
        definition.stage_id = id
        definition.scene_path = "res://worlds/archive/archive_main.tscn"
        definition.presentation = StageDefinition.Presentation.IN_PLACE if id == ArchiveProgress.WING_ONE else StageDefinition.Presentation.FADE
        _check(SceneRouter.register_stage(definition) == OK, "Register reconstructed Archive stage")
    var initial := SaveGame.new()
    initial.stage_id = ArchiveProgress.INTRO
    ArchiveProgress.write_projection(initial)
    SceneRouter.fade_duration = .02
    _check(await SceneRouter.request_registered_stage(ArchiveProgress.INTRO, initial) == OK, "Actual Archive entry with safe physical spawn")
    var world := slot.get_child(0) as ArchiveMain
    var core_light := world.get_node("Hub/CoreLight") as OmniLight3D
    _check(is_equal_approx(core_light.light_energy,.30), "Fresh core is asleep before player activates it")
    var id := world.get_instance_id()
    var feet := player.global_transform
    var look := player.head.rotation
    var before := GameState.capture_save().to_dict()
    var invalid := initial.copy_validated()
    invalid.stage_id = ArchiveProgress.WING_ONE
    _check(await SceneRouter.request_progression_stage(ArchiveProgress.WING_ONE, invalid) == ERR_INVALID_DATA, "Invalid progression target rejected without publishing milestones")
    _check(GameState.capture_save().to_dict() == before and slot.get_child(0).get_instance_id() == id and player.global_transform.is_equal_approx(feet), "Invalid target preserves original state/world/player")
    var target := initial.copy_validated()
    target.stage_id = ArchiveProgress.WING_ONE
    target.milestones = {"archive_awakened": true, "wing_01_unlocked": true}
    target.checkpoint_id = &"archive_awakened"
    ArchiveProgress.write_projection(target)
    _check(await SceneRouter.request_registered_stage(ArchiveProgress.WING_ONE, target) == ERR_UNAVAILABLE, "Existing load API still rejects IN_PLACE saved DTO")
    _check(await SceneRouter.request_progression_stage(ArchiveProgress.INTRO, initial) == ERR_UNAVAILABLE, "Progression API cannot replace a normal world")
    var interrupt := func(active: bool) -> void:
        if not active:
            InputManager.set_mode(InputManager.Mode.UI)
    player.active_changed.connect(interrupt, CONNECT_ONE_SHOT)
    _check(await SceneRouter.request_progression_stage(ArchiveProgress.WING_ONE, target) == ERR_SKIP, "Later input owner cancels prepared progression before commit")
    _check(GameState.capture_save().to_dict() == before and world.stage_id == ArchiveProgress.INTRO and world.get_instance_id() == id and player.active and InputManager.mode == InputManager.Mode.UI, "Canceled progression restores original world/player and preserves later input owner")
    InputManager.set_mode(InputManager.Mode.GAMEPLAY)
    var route_frames := [-1, -1]
    player.active_changed.connect(func(active: bool) -> void:
        if not active:
            route_frames[0] = Engine.get_process_frames()
    )
    EventBus.stage_changed.connect(func(stage: StringName) -> void:
        if stage == ArchiveProgress.WING_ONE:
            route_frames[1] = Engine.get_process_frames()
    )
    var onboarding := world.get_node("Hub/Onboarding") as ArchiveOnboarding
    var cover := onboarding.get_node("Panel/Visual/Cover") as Node3D
    var handle := onboarding.get_node("Lever/Visual/Handle") as Node3D
    _check(cover.rotation == Vector3.ZERO and handle.rotation == Vector3.ZERO, "Fresh S01 fitting poses")
    _check(onboarding.advance(ArchiveOnboarding.Step.INSTALL_LENS) == ERR_UNAUTHORIZED, "No out-of-order installation")
    for index in 4:
        var component := onboarding.get_node(onboarding.target_paths[index]) as InteractionTarget
        var area := component.get_parent() as Node3D
        player.spawn_at(Transform3D(Basis.IDENTITY, area.global_position + Vector3(0, -area.global_position.y + .004, 1.8)))
        player.look_at(Vector3(area.global_position.x, player.global_position.y, area.global_position.z))
        player.head.rotation.x = -atan2(player.camera.global_position.y - area.global_position.y, 1.8)
        await get_tree().physics_frame
        await get_tree().physics_frame
        _check(player.call("_pick_target") == component, "Actual interaction ray reaches the authored S01 target")
        await _press_interact()
        _check(int(onboarding.phase) == index + 1, "Real E advances exactly one onboarding step")
        _check(absf(cover.rotation.y-deg_to_rad(-18))<.00001 and absf(handle.rotation.x-(deg_to_rad(25) if index==3 else 0.0))<.00001, "Actual E projects cover/lever cosmetic poses")
        await _press_interact()
        _check(int(onboarding.phase) == index + 1, "Consumed target or sequence cannot repeat by E spam")
    _check(InputManager.mode == InputManager.Mode.LIMITED_LOOK and not InputManager.can_interact(), "Awakening restricts interaction while retaining look")
    var elapsed: float = world.get("_awakening_elapsed")
    var paused_energy := core_light.light_energy
    var pause := game.get_node("UILayer/PauseMenu") as PauseMenu
    _check(pause.open(), "Pause supported during awakening")
    await get_tree().process_frame
    await get_tree().process_frame
    _check(is_equal_approx(world.get("_awakening_elapsed"), elapsed), "Pause freezes awakening duration")
    _check(is_equal_approx(core_light.light_energy,paused_energy), "Actual pause freezes core illumination with the sequence clock")
    pause.resume()
    feet = player.global_transform
    look = player.head.rotation
    var fade_revision := fade.request_revision
    var deadline := Time.get_ticks_msec() + 10000
    while GameState.current_stage_id != ArchiveProgress.WING_ONE and Time.get_ticks_msec() < deadline:
        await get_tree().process_frame
    _check(GameState.current_stage_id == ArchiveProgress.WING_ONE and onboarding.phase == ArchiveOnboarding.Phase.AWAKENED, "Actual seven-second awakening commits the next stage")
    _check(is_equal_approx(core_light.light_energy,1.8) and core_light.light_color.is_equal_approx(Color(1,.68,.36)), "Committed awakening warms the same-world core light")
    _check(slot.get_child_count() == 1 and world.get_instance_id() == id and slot.get_child(0) == world, "ArchiveMain remains the same instance")
    _check(route_frames[0] == route_frames[1] and route_frames[0] > 0, "Actual progression commits without yielding a loading frame")
    _check(player.global_transform.origin.distance_to(feet.origin) < .02 and player.head.rotation == look and fade.request_revision == fade_revision, "No teleport, camera reset or fade at awakening")
    var saved := SaveManager.read_save()
    _check(saved["error"] == OK and saved["data"].stage_id == ArchiveProgress.WING_ONE and saved["data"].checkpoint_id == &"archive_awakened", "Actual disk checkpoint written before first-wing entry")
    _check(saved["data"].milestones.get("archive_awakened", false) and saved["data"].milestones.get("wing_01_unlocked", false) and not SaveManager.get("_dirty"), "Checkpoint flags and dirty acknowledgement")
    _check(world.get_node("Routes/Wing01/Channel").visible and not world.get_node("Routes/Wing02/Channel").visible, "Only Wing I route lit after awakening")
    player.spawn_at(Transform3D(Basis.IDENTITY, Vector3(0, .004, -7)))
    for frame in 5:
        await get_tree().physics_frame
    _check(world.get_node("Routes/Wing01/Gate").status == ArchiveGate.Status.OPEN, "Physical approach opens eligible gate")
    _check(await SceneRouter.request_resume_stage(saved["data"]) == OK, "Actual saved awakening checkpoint resumes")
    var restored := slot.get_child(0) as ArchiveMain
    var restored_hub := restored.get_node("Hub/Onboarding") as ArchiveOnboarding
    var restored_light := restored.get_node("Hub/CoreLight") as OmniLight3D
    _check(is_equal_approx(restored_light.light_energy,1.8) and restored_light.light_color.is_equal_approx(Color(1,.68,.36)), "Physical reload restores awakened illumination immediately")
    _check(restored_hub.phase == ArchiveOnboarding.Phase.AWAKENED and restored.get("_awakening_elapsed") < 0.0 and
        absf((restored_hub.get_node("Panel/Visual/Cover") as Node3D).rotation.y-deg_to_rad(-18))<.00001 and
        absf((restored_hub.get_node("Lever/Visual/Handle") as Node3D).rotation.x-deg_to_rad(25))<.00001,
        "Quiet physical reload restores art poses without replaying awakening")
    var after_resume := SaveManager.read_save()
    _check(after_resume["error"] == OK and after_resume["data"].to_dict() == saved["data"].to_dict(), "Art restoration leaves physical checkpoint unchanged")
    game.queue_free()
    await get_tree().process_frame
    # Drain deferred destruction after the physical world reload/unload.
    await get_tree().process_frame
    for stage in ArchiveProgress.STAGES:
        SceneRouter.unregister_stage(stage)
    SceneRouter.fade_duration = duration
    GameState.apply_save(original)
    SaveManager.set("_dirty", dirty)
    InputManager.set_mode(InputManager.Mode.UI)
    if _failures.is_empty():
        print("ARCHIVE_PROGRESSION PASS: ", _checks, " assertions; real S01 E rays, lens chain, pauseable awakening, same-world transactional progression and physical checkpoint")
    get_tree().quit(0 if _failures.is_empty() else 1)
