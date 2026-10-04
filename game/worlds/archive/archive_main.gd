class_name ArchiveMain
extends WorldScene
## Persistent Archive world. Quiet load projection precedes player activation.

signal checkpoint_finished(checkpoint: StringName, error: Error)
@export_range(5.0, 8.0, 0.1) var awakening_duration := 7.0
var _awakening_elapsed := -1.0
var _busy := false
var _sequence_mode_revision := -1
var _previous_mode := InputManager.Mode.GAMEPLAY
var _pending_checkpoint: StringName = &""
var _sequence_paused := false
var _channels_flashed := false
var _other_channels_dimmed := false


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


func _on_hub_step(actor: Node3D, index: int) -> void:
    if _busy or not actor is FirstPersonPlayer or not actor.active or not InputManager.can_interact() or stage_id != ArchiveProgress.INTRO:
        return
    var onboarding := get_node("Hub/Onboarding") as ArchiveOnboarding
    onboarding.advance(index as ArchiveOnboarding.Step)


func _on_gate_approach(actor: Node3D, index: int) -> void:
    if not actor is FirstPersonPlayer or not actor.active or not InputManager.can_interact():
        return
    var controller := get_node("StageController") as ArchiveStageController
    if controller.capture_presentation()["unlocked"][index]:
        controller.open_wing(index)


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
    checkpoint_finished.emit(checkpoint, error)
    if error == OK:
        EventBus.checkpoint_reached.emit(checkpoint)
    return error


func retry_checkpoint() -> Error:
    return OK if _pending_checkpoint.is_empty() else _flush_checkpoint(_pending_checkpoint)


func _exit_tree() -> void:
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
    if controller == null:
        return ERR_UNCONFIGURED
    error = controller.apply_state(projected)
    if error == OK:
        stage_id = id
        var onboarding := get_node_or_null("Hub/Onboarding") as ArchiveOnboarding
        if onboarding != null:
            onboarding.restore_awakened(projected["awakened"])
    return error
