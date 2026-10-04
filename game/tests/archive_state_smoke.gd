extends Node
## Targeted reconstruction test: actual Archive scene/state, not old preflights.

var _failures: Array[String] = []
var _checks := 0


func _ready() -> void:
    get_tree().create_timer(25.0, true).timeout.connect(func() -> void:
        push_error("ARCHIVE_STATE FAIL: timeout")
        get_tree().quit(1)
    )
    _run.call_deferred()


func _check(condition: bool, message: String) -> void:
    _checks += 1
    if not condition:
        _failures.append(message)
        push_error("ARCHIVE_STATE FAIL: " + message)


func _saved(count: int) -> SaveGame:
    var saved := SaveGame.new()
    saved.stage_id = ArchiveProgress.INTRO if count < 0 else ArchiveProgress.WING_ONE
    if count >= 0:
        saved.milestones = {"archive_awakened": true, "wing_01_unlocked": true}
    if count >= 1:
        saved.collected_fragments.append(&"star")
        saved.milestones.merge({"wing_01_light_restored": true, "fragment_star_collected": true})
    if count >= 2:
        saved.collected_fragments.append(&"hearth")
        saved.milestones.merge({"wing_01_completed": true, "fragment_hearth_collected": true, "wing_02_unlocked": true})
    return saved


func _run() -> void:
    var global_before := GameState.capture_save().to_dict()
    var dirty: bool = SaveManager.get("_dirty")
    var world := preload("res://worlds/archive/archive_main.tscn").instantiate() as ArchiveMain
    var controller := world.get_node("StageController") as ArchiveStageController
    for count in [-1, 0, 1, 2]:
        var saved := _saved(count)
        var prepared := world.prepare_state(saved)
        _check(prepared["error"] == OK, "Offline actual scene preparation at milestone " + str(count))
        _check(saved.world_states.is_empty(), "Preparation does not mutate supplied SaveGame")
        _check(ArchiveProgress.write_projection(saved) == OK and ArchiveProgress.from_save(saved)["error"] == OK, "Projection round trip at milestone " + str(count))
    var bad := _saved(1)
    bad.milestones["wing_01_light_restored"] = false
    _check(world.prepare_state(bad)["error"] == ERR_INVALID_DATA, "Contradictory light/fragment flags rejected")
    bad = _saved(2)
    bad.milestones["wing_02_unlocked"] = false
    _check(world.prepare_state(bad)["error"] == ERR_INVALID_DATA, "Completed Wing I requires next route")
    bad = _saved(0)
    bad.checkpoint_id = &"missing_archive_checkpoint"
    _check(world.prepare_state(bad)["error"] == ERR_INVALID_DATA, "Unknown checkpoint rejected by actual scene")
    bad = _saved(0)
    bad.stage_id = ArchiveProgress.INTRO
    _check(world.prepare_state(bad)["error"] == ERR_INVALID_DATA, "Dormant stage cannot contain awakened state")
    bad = _saved(1)
    ArchiveProgress.write_projection(bad)
    bad.world_states[ArchiveProgress.WING_ONE]["star_collected"] = false
    _check(world.prepare_state(bad)["error"] == ERR_INVALID_DATA, "Stale owned namespace rejected")
    add_child(world)
    await get_tree().physics_frame
    _check(controller.bindings_valid(), "Five actual gate/channel pairs and finale are bound")
    for count in [-1, 0, 1, 2]:
        var saved := _saved(count)
        var prepared := world.prepare_state(saved)
        _check(world.apply_stage_state(saved.stage_id, prepared["state"]) == OK, "Instant actual world restore at milestone " + str(count))
        await get_tree().physics_frame
        for index in 5:
            var gate := world.get_node("Routes/Wing%02d/Gate" % (index + 1)) as ArchiveGate
            var channel := world.get_node("Routes/Wing%02d/Channel" % (index + 1)) as ArchiveLightChannel
            var expected := ArchiveGate.Status.COMPLETED if index == 0 and count >= 2 else ArchiveGate.Status.UNLOCKED if index == 0 and count >= 0 or index == 1 and count >= 2 else ArchiveGate.Status.DORMANT
            _check(gate.status == expected, "Gate state matches milestone and wing")
            _check(not gate.animation_running and not channel.pulse_running, "Reload is quiet without opening/return animation")
            _check(channel.visible == (expected != ArchiveGate.Status.DORMANT), "Only unlocked/completed route is visible")
        _check(not world.get_node("Hub/Finale").visible, "Finale remains unavailable before all memories")
    _check(controller.open_wing(1, false) == OK and controller.open_wing(2) == ERR_UNAUTHORIZED, "Only eligible next entrance can open")
    var before := controller.capture_presentation()
    var invalid := before.duplicate(true)
    invalid["awakened"] = 1
    _check(controller.apply_state(invalid) == ERR_INVALID_DATA and controller.capture_presentation() == before, "Invalid state has no presentation mutation")
    var paths := controller.gates.duplicate()
    controller.gates[4] = controller.gates[0]
    _check(controller.apply_state(before) == ERR_UNCONFIGURED and controller.capture_presentation() == before, "Duplicate bindings refused before mutation")
    controller.gates.assign(paths)
    var future := before.duplicate(true)
    future["completed"] = [true, true, false, false, false]
    future["memories"] = [true, false, false]
    future["unlocked"] = [true, true, true, false, false]
    _check(controller.apply_state(future) == OK, "Memory I completion restores structural Wing III availability")
    future["completed"] = [true, true, true, true, true]
    future["unlocked"] = [true, true, true, true, true]
    future["memories"] = [true, true, false]
    _check(controller.apply_state(future) == OK and not world.get_node("Hub/Finale").visible, "All wings alone do not unlock finale")
    future["memories"][2] = true
    future["finale_ready"] = true
    _check(controller.apply_state(future) == OK and world.get_node("Hub/Finale").visible, "All wings and memories restore finale placeholder")
    world.queue_free()
    await get_tree().process_frame
    _check(GameState.capture_save().to_dict() == global_before and SaveManager.get("_dirty") == dirty, "Pure restore leaves live progression and dirty state unchanged")
    if _failures.is_empty():
        print("ARCHIVE_STATE PASS: ", _checks, " assertions; actual ArchiveMain, quiet five-route milestone restoration and invalid-save/binding rejection")
    get_tree().quit(0 if _failures.is_empty() else 1)
