class_name ArchiveMain
extends WorldScene
## Persistent Archive world. Quiet load projection precedes player activation.

signal checkpoint_finished(checkpoint: StringName, error: Error)
@export_range(5.0, 8.0, 0.1) var awakening_duration := 7.0
@export var playable_wings := PackedInt32Array([0])
var _awakening_elapsed := -1.0
var _busy := false
var _sequence_mode_revision := -1
var _previous_mode := InputManager.Mode.GAMEPLAY
var _pending_checkpoint: StringName = &""
var _sequence_paused := false
var _channels_flashed := false
var _other_channels_dimmed := false
var _pending_fragment: StringName = &""
var _lighting_tween: Tween
var _return_pulsed := false


func _ready() -> void:
    InputManager.pause_changed.connect(_on_pause_changed)
    var onboarding := get_node_or_null("Hub/Onboarding") as ArchiveOnboarding
    if onboarding != null:
        onboarding.activation_requested.connect(_on_activation_requested)
        for index in onboarding.target_paths.size():
            var target := onboarding.get_node_or_null(onboarding.target_paths[index]) as InteractionTarget
            if target != null:
                target.interacted.connect(_on_hub_step.bind(index))
        onboarding.restore_awakened(false)
    for index in 5:
        var area := get_node_or_null("Routes/Wing%02d/Approach" % (index + 1)) as Area3D
        if area != null:
            area.body_entered.connect(_on_gate_approach.bind(index))
    var rings := get_node_or_null("Wing01/Room/Rings") as LightRingPuzzle
    var focus := get_node_or_null("Wing01/Room/Focus") as LightFocusPuzzle
    if rings != null:
        rings.solved.connect(_on_star_solved)
        for index in rings.interaction_paths.size():
            var target := rings.get_node_or_null(rings.interaction_paths[index]) as InteractionTarget
            if target != null:
                target.interacted.connect(_on_ring_interacted.bind(index))
    if focus != null:
        focus.solved.connect(_on_hearth_solved)
        var target := focus.get_node_or_null(focus.interaction_path) as InteractionTarget
        if target != null:
            target.interacted.connect(_on_focus_interacted)
    var notice := get_node_or_null("FragmentLayer/CheckpointNotice") as CheckpointNotice
    if notice != null:
        notice.retry_requested.connect(retry_checkpoint)
    var return_area := get_node_or_null("Hub/Wing01Return") as Area3D
    if return_area != null:
        return_area.body_entered.connect(_on_wing_return)


func _on_hub_step(actor: Node3D, index: int) -> void:
    if _busy or not actor is FirstPersonPlayer or not actor.active or not InputManager.can_interact() or stage_id != ArchiveProgress.INTRO:
        return
    var onboarding := get_node("Hub/Onboarding") as ArchiveOnboarding
    onboarding.advance(index as ArchiveOnboarding.Step)


func _on_gate_approach(actor: Node3D, index: int) -> void:
    # Logical next-wing indication must not expose an unbuilt passage/drop.
    if index not in playable_wings or not actor is FirstPersonPlayer or not actor.active or not InputManager.can_interact():
        return
    var controller := get_node("StageController") as ArchiveStageController
    if controller.capture_presentation()["unlocked"][index]:
        controller.open_wing(index)


func _on_wing_return(actor: Node3D) -> void:
    if not _return_pulsed and _actor_can_interact(actor) and GameState.milestones.get("wing_01_completed", false):
        _return_pulsed = true
        var channel := get_node("Routes/Wing01/Channel") as ArchiveLightChannel
        channel.pulse(false)


func _on_activation_requested() -> void:
    if _busy or stage_id != ArchiveProgress.INTRO:
        return
    _busy = true
    _awakening_elapsed = 0.0
    _channels_flashed = false
    _other_channels_dimmed = false
    _previous_mode = InputManager.mode
    InputManager.set_mode(InputManager.Mode.LIMITED_LOOK)
    _sequence_mode_revision = InputManager.mode_revision


func _on_pause_changed(paused: bool) -> void:
    if _awakening_elapsed < 0.0:
        return
    if paused:
        _sequence_paused = InputManager.mode == InputManager.Mode.LIMITED_LOOK and InputManager.mode_revision == _sequence_mode_revision
    elif _sequence_paused and InputManager.mode == InputManager.Mode.LIMITED_LOOK:
        _sequence_mode_revision = InputManager.mode_revision
        _sequence_paused = false


func _process(delta: float) -> void:
    if not _pending_fragment.is_empty() and _pending_checkpoint.is_empty() and InputManager.can_interact() and not _busy:
        _present_pending_fragment()
    if _awakening_elapsed < 0.0:
        return
    if InputManager.mode != InputManager.Mode.LIMITED_LOOK or InputManager.mode_revision != _sequence_mode_revision:
        _cancel_awakening()
        return
    _awakening_elapsed += delta
    var mechanism := get_node_or_null("Hub/Astrolabe") as Node3D
    if mechanism != null and _awakening_elapsed >= 2.0:
        mechanism.rotation.y += delta * 0.35
    if _awakening_elapsed >= 4.0 and not _channels_flashed:
        _channels_flashed = true
        for index in 5:
            var channel := get_node("Routes/Wing%02d/Channel" % (index + 1)) as ArchiveLightChannel
            channel.apply_state(ArchiveLightChannel.Status.ACTIVE, true)
    if _awakening_elapsed >= 5.0 and not _other_channels_dimmed:
        _other_channels_dimmed = true
        for index in range(1, 5):
            var channel := get_node("Routes/Wing%02d/Channel" % (index + 1)) as ArchiveLightChannel
            channel.apply_state(ArchiveLightChannel.Status.DORMANT)
    if _awakening_elapsed >= awakening_duration:
        _awakening_elapsed = -1.0
        _commit_awakening()


func _commit_awakening() -> Error:
    if GameState.current_stage_id != ArchiveProgress.INTRO or not _busy:
        return ERR_UNAUTHORIZED
    var target := GameState.capture_save()
    if target == null:
        _cancel_awakening()
        return ERR_INVALID_DATA
    target.stage_id = ArchiveProgress.WING_ONE
    target.checkpoint_id = &"archive_awakened"
    target.milestones.merge({"archive_awakened": true, "wing_01_unlocked": true}, true)
    var error := ArchiveProgress.write_projection(target)
    if error == OK:
        error = await SceneRouter.request_progression_stage(ArchiveProgress.WING_ONE, target)
    if error != OK:
        _cancel_awakening()
        return error
    _awakening_elapsed = -1.0
    _sequence_mode_revision = -1
    _busy = false
    return _flush_checkpoint(&"archive_awakened")


func _cancel_awakening() -> void:
    _awakening_elapsed = -1.0
    _busy = false
    if InputManager.mode == InputManager.Mode.LIMITED_LOOK and InputManager.mode_revision == _sequence_mode_revision:
        InputManager.set_mode(_previous_mode)
    _sequence_mode_revision = -1
    var onboarding := get_node_or_null("Hub/Onboarding") as ArchiveOnboarding
    if onboarding != null:
        onboarding.retry_activation()
    var controller := get_node_or_null("StageController") as ArchiveStageController
    if controller != null and controller.is_inside_tree():
        controller.apply_state(controller.capture_presentation())


func _flush_checkpoint(checkpoint: StringName) -> Error:
    SaveManager.mark_dirty()
    var error := SaveManager.flush_if_dirty()
    _pending_checkpoint = checkpoint if error != OK else &""
    var notice := get_node_or_null("FragmentLayer/CheckpointNotice") as CheckpointNotice
    if notice != null:
        if error == OK:
            notice.close()
        else:
            notice.open()
    checkpoint_finished.emit(checkpoint, error)
    if error == OK:
        EventBus.checkpoint_reached.emit(checkpoint)
    return error


func retry_checkpoint() -> Error:
    var error := OK if _pending_checkpoint.is_empty() else _flush_checkpoint(_pending_checkpoint)
    if error == OK and not _pending_fragment.is_empty():
        _present_pending_fragment()
    return error


func _exit_tree() -> void:
    if _lighting_tween != null:
        _lighting_tween.kill()
    if _awakening_elapsed >= 0.0:
        _cancel_awakening()


func prepare_state(saved: SaveGame) -> Dictionary:
    var failure := {"error": ERR_INVALID_DATA, "state": {}, "spawn": Transform3D.IDENTITY}
    var copy := saved.copy_validated() if saved != null else null
    var projected := ArchiveProgress.from_save(copy)
    if projected["error"] != OK or copy == null:
        return failure
    copy.world_states[copy.stage_id] = projected["state"]
    return super.prepare_state(copy)


func validate_stage_state(id: StringName, state: Dictionary) -> Error:
    if not supports_stage(id) or not ArchiveProgress.valid(state):
        return ERR_INVALID_DATA
    if id == ArchiveProgress.INTRO and state["awakened"] or id == ArchiveProgress.WING_ONE and not state["awakened"]:
        return ERR_INVALID_DATA
    return OK


func apply_stage_state(id: StringName, state: Dictionary) -> Error:
    # Router rollback of a pristine intro has an empty owned namespace.
    var projected := ArchiveProgress.fresh() if state.is_empty() and id == ArchiveProgress.INTRO else state
    var error := validate_stage_state(id, projected)
    if error != OK:
        return error
    var controller := get_node_or_null("StageController") as ArchiveStageController
    if controller == null or not slice_bindings_valid():
        return ERR_UNCONFIGURED
    error = controller.apply_state(projected)
    if error == OK:
        stage_id = id
        var onboarding := get_node_or_null("Hub/Onboarding") as ArchiveOnboarding
        if onboarding != null:
            onboarding.restore_awakened(projected["awakened"])
        _restore_slice(projected, true)
    return error


func _actor_can_interact(actor: Node3D) -> bool:
    return actor is FirstPersonPlayer and actor.active and InputManager.can_interact() and \
        not _busy and _pending_checkpoint.is_empty() and _pending_fragment.is_empty() and stage_id == ArchiveProgress.WING_ONE


func _on_ring_interacted(actor: Node3D, index: int) -> void:
    if _actor_can_interact(actor):
        var rings := get_node("Wing01/Room/Rings") as LightRingPuzzle
        rings.rotate_ring(index)


func _on_focus_interacted(actor: Node3D) -> void:
    if _actor_can_interact(actor):
        var focus := get_node("Wing01/Room/Focus") as LightFocusPuzzle
        focus.cycle()


func _on_star_solved() -> void:
    collect_fragment(&"star")


func _on_hearth_solved() -> void:
    collect_fragment(&"hearth")


func collect_fragment(id: StringName) -> Error:
    if _busy or not _pending_checkpoint.is_empty() or not _pending_fragment.is_empty() or \
            stage_id != ArchiveProgress.WING_ONE or GameState.current_stage_id != stage_id or not InputManager.can_interact():
        return ERR_BUSY
    var original := GameState.capture_save()
    if original == null:
        return ERR_INVALID_DATA
    if original.collected_fragments.has(id):
        return ERR_ALREADY_EXISTS
    if id not in [&"star", &"hearth"] or original.collected_fragments.size() != (0 if id == &"star" else 1):
        return ERR_INVALID_DATA
    var rings := get_node_or_null("Wing01/Room/Rings") as LightRingPuzzle
    var focus := get_node_or_null("Wing01/Room/Focus") as LightFocusPuzzle
    if not slice_bindings_valid():
        return ERR_UNCONFIGURED
    if id == &"star" and (not rings.locked or rings.connected_segments() != 3) or \
            id == &"hearth" and (not focus.available or not focus.locked or focus.position_index != focus.solution):
        return ERR_UNAUTHORIZED
    var presenter := get_node_or_null("FragmentLayer/FragmentPresenter") as FragmentPresenter
    var controller := get_node("StageController") as ArchiveStageController
    if presenter == null or presenter.fragment(id) == null or not controller.bindings_valid():
        return ERR_UNCONFIGURED
    var target := original.copy_validated()
    target.collected_fragments.append(id)
    target.checkpoint_id = &"star_collected" if id == &"star" else &"hearth_collected"
    if id == &"star":
        target.milestones.merge({"wing_01_light_restored": true, "fragment_star_collected": true}, true)
    else:
        target.milestones.merge({"wing_01_completed": true, "fragment_hearth_collected": true, "wing_02_unlocked": true}, true)
    var error := ArchiveProgress.write_projection(target)
    if error != OK:
        return error
    _busy = true
    error = GameState.apply_save(target)
    if error == OK:
        error = controller.apply_state(target.world_states[stage_id], true)
    if error != OK:
        GameState.apply_save(original)
        controller.apply_state(original.world_states[stage_id])
        _busy = false
        return error
    _restore_slice(target.world_states[stage_id], false)
    _pending_fragment = id
    _busy = false
    error = _flush_checkpoint(target.checkpoint_id)
    # Acquisition is logical/idempotent even if physical IO needs retry.
    EventBus.fragment_collected.emit(id)
    if error == OK:
        error = _present_pending_fragment()
    return error


func _present_pending_fragment() -> Error:
    var presenter := get_node_or_null("FragmentLayer/FragmentPresenter") as FragmentPresenter
    if presenter == null:
        return ERR_UNCONFIGURED
    var error := presenter.present_fragment(_pending_fragment)
    if error == OK:
        _pending_fragment = &""
    return error


func _restore_slice(state: Dictionary, quiet: bool) -> void:
    var rings := get_node_or_null("Wing01/Room/Rings") as LightRingPuzzle
    var focus := get_node_or_null("Wing01/Room/Focus") as LightFocusPuzzle
    if rings != null:
        rings.restore_completed(state["light_restored"])
        for index in 3:
            var target := rings.get_node(rings.interaction_paths[index]) as InteractionTarget
            target.enabled = stage_id == ArchiveProgress.WING_ONE and not state["light_restored"]
    if focus != null:
        focus.restore_state(state["star_collected"], state["hearth_collected"])
        var target := focus.get_node(focus.interaction_path) as InteractionTarget
        target.enabled = stage_id == ArchiveProgress.WING_ONE and state["star_collected"] and not state["hearth_collected"]
    var star := get_node_or_null("Wing01/Room/Star") as Node3D
    var hearth := get_node_or_null("Wing01/Room/Hearth/Flame") as Node3D
    if star != null:
        star.visible = state["star_collected"]
    if hearth != null:
        hearth.visible = state["hearth_collected"]
    var light := get_node_or_null("Wing01/Room/RoomLight") as OmniLight3D
    if light != null:
        if _lighting_tween != null:
            _lighting_tween.kill()
        var color := Color(1.0, .68, .36) if state["hearth_collected"] else Color(.43, .65, 1.0)
        if not quiet and state["hearth_collected"]:
            _lighting_tween = create_tween()
            _lighting_tween.tween_property(light, "light_color", color, .8)
        else:
            light.light_color = color
    if quiet:
        var notice := get_node_or_null("FragmentLayer/CheckpointNotice") as CheckpointNotice
        if notice != null:
            notice.close()
        _pending_checkpoint = &""
        _pending_fragment = &""
        var presenter := get_node_or_null("FragmentLayer/FragmentPresenter") as FragmentPresenter
        if presenter != null:
            var collected: Array[StringName] = []
            if state["star_collected"]:
                collected.append(&"star")
            if state["hearth_collected"]:
                collected.append(&"hearth")
            presenter.restore_collected(collected)


func slice_bindings_valid() -> bool:
    var rings := get_node_or_null("Wing01/Room/Rings") as LightRingPuzzle
    var focus := get_node_or_null("Wing01/Room/Focus") as LightFocusPuzzle
    var presenter := get_node_or_null("FragmentLayer/FragmentPresenter") as FragmentPresenter
    if rings == null or focus == null or presenter == null or not rings.parameters_valid() or \
            rings.ring_paths.size() != 3 or rings.interaction_paths.size() != 3 or rings.segment_paths.size() != 4 or \
            focus.solution not in range(5) or presenter.fragment(&"star") == null or presenter.fragment(&"hearth") == null:
        return false
    var targets: Array[InteractionTarget] = []
    for path in rings.interaction_paths:
        var target := rings.get_node_or_null(path) as InteractionTarget
        if target == null or not is_ancestor_of(target) or target in targets:
            return false
        targets.append(target)
    var target := focus.get_node_or_null(focus.interaction_path) as InteractionTarget
    if target == null or not is_ancestor_of(target) or target in targets:
        return false
    for paths in [rings.ring_paths, rings.segment_paths]:
        for path in paths:
            if not rings.get_node_or_null(path) is Node3D:
                return false
    return focus.get_node_or_null(focus.wheel_path) is Node3D and focus.get_node_or_null(focus.beam_path) is Node3D and \
        get_node_or_null("Wing01/Room/Star") is Node3D and get_node_or_null("Wing01/Room/Hearth/Flame") is Node3D and \
        get_node_or_null("Wing01/Room/RoomLight") is OmniLight3D and get_node_or_null("FragmentLayer/CheckpointNotice") is CheckpointNotice
