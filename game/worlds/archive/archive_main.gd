class_name ArchiveMain
extends WorldScene
## Persistent Archive world. Quiet load projection precedes player activation.


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
    return error
