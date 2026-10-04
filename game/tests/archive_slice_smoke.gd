extends Node
## Real S02 model grips/E events, milestone IO failure/retry and quiet disk reload.

var _failures: Array[String] = []
var _checks := 0
var _fragments: Array[StringName] = []
var _checkpoints: Array[StringName] = []


func _ready() -> void:
    get_tree().create_timer(35.0, true).timeout.connect(func() -> void:
        push_error("ARCHIVE_SLICE FAIL: timeout")
        get_tree().quit(1)
    )
    _run.call_deferred()


func _check(condition: bool, message: String) -> void:
    _checks += 1
    if not condition:
        _failures.append(message)
        push_error("ARCHIVE_SLICE FAIL: " + message)


func _press() -> void:
    var event := InputEventAction.new()
    event.action = &"interact"
    event.pressed = true
    Input.parse_input_event(event)
    await get_tree().physics_frame
    await get_tree().physics_frame
    event = InputEventAction.new()
    event.action = &"interact"
    event.pressed = false
    Input.parse_input_event(event)
    await get_tree().physics_frame


func _use(player: FirstPersonPlayer, target: InteractionTarget) -> void:
    var grip := target.get_parent() as Node3D
    var distance := 1.5
    player.spawn_at(Transform3D(Basis.IDENTITY, grip.global_position + Vector3(0, .004 - grip.global_position.y, distance)))
    player.look_at(Vector3(grip.global_position.x, player.global_position.y, grip.global_position.z))
    player.head.rotation.x = -atan2(player.camera.global_position.y - grip.global_position.y, distance)
    await get_tree().physics_frame
    await get_tree().physics_frame
    _check(player.call("_pick_target") == target, "Real ray reaches model grip: " + str(target.get_path()))
    await _press()


func _run() -> void:
    var original := GameState.capture_save()
    var dirty: bool = SaveManager.get("_dirty")
    var duration := SceneRouter.fade_duration
    EventBus.fragment_collected.connect(func(id: StringName) -> void: _fragments.append(id))
    EventBus.checkpoint_reached.connect(func(id: StringName) -> void: _checkpoints.append(id))
    var game := preload("res://core/game_root/game_root.tscn").instantiate()
    add_child(game)
    var slot: Node3D = game.get_node("WorldSlot")
    var player: FirstPersonPlayer = game.get_node("PlayerContainer/Player")
    var definition := StageDefinition.new()
    definition.stage_id = ArchiveProgress.WING_ONE
    definition.scene_path = "res://worlds/archive/archive_main.tscn"
    # This fixture enters/loads the world normally, rather than invoking S01 progression.
    definition.presentation = StageDefinition.Presentation.FADE
    _check(SceneRouter.register_stage(definition) == OK, "Register normal saved-world entry")
    var initial := SaveGame.new()
    initial.stage_id = ArchiveProgress.WING_ONE
    initial.checkpoint_id = &"archive_awakened"
    initial.milestones = {"archive_awakened": true, "wing_01_unlocked": true}
    _check(ArchiveProgress.write_projection(initial) == OK, "Project canonical first-wing entry")
    SceneRouter.fade_duration = .02
    _check(await SceneRouter.request_registered_stage(ArchiveProgress.WING_ONE, initial) == OK, "Enter materialized Archive with safe spawn")
    var world := slot.get_child(0) as ArchiveMain
    var rings := world.get_node("Wing01/Room/Rings") as LightRingPuzzle
    var focus := world.get_node("Wing01/Room/Focus") as LightFocusPuzzle
    var presenter := world.get_node("FragmentLayer/FragmentPresenter") as FragmentPresenter
    var notice := world.get_node("FragmentLayer/CheckpointNotice") as CheckpointNotice
    _check(world.slice_bindings_valid(), "All carrier/beam/presenter/notice bindings valid")
    _check(not presenter.visible and not notice.visible and player.active, "Quiet first entry activates gameplay without modal")
    var before := GameState.capture_save().to_dict()
    _check(world.collect_fragment(&"star") == ERR_UNAUTHORIZED, "No Star acquisition without solved rings")
    _check(world.collect_fragment(&"hearth") == ERR_INVALID_DATA and world.collect_fragment(&"echo") == ERR_INVALID_DATA, "No skipped or foreign fragment")
    _check(GameState.capture_save().to_dict() == before and _fragments.is_empty(), "Rejected acquisition leaves state/events unchanged")
    _check(not focus.available and focus.cycle() == ERR_UNAUTHORIZED, "Focus remains unavailable before Star")
    _check(not world.get_node("Wing01/Room/BeamSegments/Segment3").visible, "Incomplete optical connection has no final beam")
    # A real directory obstruction exercises IO failure without relying on mocked errors.
    var primary := ProjectSettings.globalize_path(SaveManager.SAVE_PATH)
    _check(not FileAccess.file_exists(SaveManager.SAVE_PATH) and DirAccess.make_dir_absolute(primary) == OK, "Test-owned primary slot blocked by a directory")
    for index in 3:
        for click in index + 1:
            var target := rings.get_node(rings.interaction_paths[index]) as InteractionTarget
            await _use(player, target)
    _check(rings.locked and rings.connected_segments() == 3, "Real ring controls establish the full connection")
    _check(GameState.capture_save().collected_fragments == [&"star"] and GameState.milestones.get("fragment_star_collected", false), "Star logical milestone acquired despite IO obstacle")
    _check(SaveManager.get("_dirty") and world.get("_pending_checkpoint") == &"star_collected", "Failed IO preserves dirty state and exact retry checkpoint")
    _check(not presenter.visible and notice.visible and InputManager.mode == InputManager.Mode.UI, "Retry notice precedes unsaved fragment presentation")
    _check(_fragments == [&"star"] and _checkpoints.is_empty(), "Logical pickup emitted once; failed disk write is not a checkpoint event")
    _check(world.collect_fragment(&"star") == ERR_BUSY and world.collect_fragment(&"hearth") == ERR_BUSY, "Pending save blocks duplicate and subsequent acquisition")
    _check(world.retry_checkpoint() != OK and notice.visible and _fragments.size() == 1, "Failed retry retains notice and does not replay pickup")
    _check(DirAccess.remove_absolute(primary) == OK, "Remove only test-owned empty obstruction")
    notice.retry_button.pressed.emit()
    _check(not notice.visible and presenter.visible and not SaveManager.get("_dirty"), "Usable Retry button writes checkpoint before fragment modal")
    var star_save: SaveGame = SaveManager.read_save()["data"]
    _check(star_save != null and star_save.checkpoint_id == &"star_collected" and star_save.collected_fragments == [&"star"], "Actual primary contains Star state")
    _check(_checkpoints == [&"star_collected"] and world.get("_pending_fragment") == &"", "Success checkpoint/presentation happen exactly once")
    _check(presenter.title_label.text == "Звезда" and presenter.couplet_label.text == "\n".join(presenter.fragment(&"star").couplet), "Canonical resource title/couplet displayed without order metadata")
    _check(not InputManager.can_interact() and not InputManager.can_move(), "Fragment modal gates player input")
    var pose := focus.position_index
    await _press()
    _check(focus.position_index == pose and _fragments.size() == 1, "E spam cannot advance the focus behind a fragment modal")
    InputManager.set_mode(InputManager.Mode.LIMITED_LOOK)
    presenter.dismiss()
    _check(InputManager.mode == InputManager.Mode.LIMITED_LOOK, "Dismiss preserves a later input owner")
    InputManager.set_mode(InputManager.Mode.GAMEPLAY)
    _check(presenter.present_fragment(&"star") == ERR_ALREADY_EXISTS, "Collected fragment cannot replay its modal")
    _check(await SceneRouter.request_registered_stage(ArchiveProgress.WING_ONE, star_save) == OK, "Reload actual Star checkpoint")
    world = slot.get_child(0) as ArchiveMain
    rings = world.get_node("Wing01/Room/Rings") as LightRingPuzzle
    focus = world.get_node("Wing01/Room/Focus") as LightFocusPuzzle
    presenter = world.get_node("FragmentLayer/FragmentPresenter") as FragmentPresenter
    _check(rings.locked and focus.available and not focus.locked and focus.position_index == 0, "Star reload restores solved rings and fresh available focus")
    _check(not presenter.visible and _fragments.size() == 1 and _checkpoints.size() == 1, "Quiet reload emits no acquisition or checkpoint and shows no modal")
    _check(player.global_position.distance_to(world.get_node("Spawns/Star").global_position) < .03, "Reload uses the safe Star mapping")
    _check(world.collect_fragment(&"hearth") == ERR_UNAUTHORIZED, "No Hearth without completed focus")
    var focus_target := focus.get_node(focus.interaction_path) as InteractionTarget
    await _use(player, focus_target)
    _check(not focus.locked and focus.position_index == 1, "First real focus step is reversible unsolved state")
    await _use(player, focus_target)
    _check(focus.locked and GameState.capture_save().collected_fragments == [&"star", &"hearth"], "Authored focus target acquires Hearth in required order")
    _check(presenter.visible and presenter.title_label.text == "Очаг" and _fragments == [&"star", &"hearth"], "Exactly one Hearth presentation/event")
    _check(GameState.milestones.get("wing_01_completed", false) and GameState.milestones.get("wing_02_unlocked", false), "Wing I completion unlocks only next wing")
    var hearth_save: SaveGame = SaveManager.read_save()["data"]
    _check(hearth_save != null and hearth_save.checkpoint_id == &"hearth_collected" and hearth_save.collected_fragments.size() == 2, "Actual Hearth checkpoint written")
    var backup: SaveGame = SaveManager.call("_read_file", SaveManager.BACKUP_PATH)["data"]
    _check(backup != null and backup.checkpoint_id == &"star_collected", "Physical backup retains previous valid Star checkpoint")
    presenter.continue_button.pressed.emit()
    _check(InputManager.mode == InputManager.Mode.GAMEPLAY and not presenter.visible, "Continue returns to gameplay")
    _check(await SceneRouter.request_registered_stage(ArchiveProgress.WING_ONE, hearth_save) == OK, "Reload actual Hearth checkpoint")
    world = slot.get_child(0) as ArchiveMain
    focus = world.get_node("Wing01/Room/Focus") as LightFocusPuzzle
    presenter = world.get_node("FragmentLayer/FragmentPresenter") as FragmentPresenter
    _check(focus.locked and focus.position_index == focus.solution and not presenter.visible, "Completed focus reload is quiet and locked")
    _check(world.get_node("Wing01/Room/Hearth/Flame").visible and world.get_node("Wing01/Room/RoomLight").light_color.is_equal_approx(Color(1.0, .68, .36)), "Warm room is restored immediately without replaying tween")
    _check(world.get_node("Routes/Wing01/Gate").status == ArchiveGate.Status.COMPLETED and world.get_node("Routes/Wing02/Channel").status == ArchiveLightChannel.Status.ACTIVE, "Completed return passage and next route indication")
    _check(_fragments.size() == 2 and _checkpoints == [&"star_collected", &"hearth_collected"] and not SaveManager.get("_dirty"), "Reload creates no duplicate events or writes")
    _check(player.global_position.distance_to(world.get_node("Spawns/Hearth").global_position) < .03, "Safe Hearth checkpoint mapping")
    game.queue_free()
    await get_tree().process_frame
    SceneRouter.unregister_stage(ArchiveProgress.WING_ONE)
    SceneRouter.fade_duration = duration
    GameState.apply_save(original)
    SaveManager.set("_dirty", dirty)
    InputManager.set_mode(InputManager.Mode.UI)
    if _failures.is_empty():
        print("ARCHIVE_SLICE PASS: ", _checks, " assertions; actual model/E controls, solved-only acquisition, physical IO retry, primary/backup and quiet reload")
    get_tree().quit(0 if _failures.is_empty() else 1)
