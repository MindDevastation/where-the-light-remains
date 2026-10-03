extends Node

var _world_slot: Node3D
var _transition_in_progress := false
var _stage_definitions: Dictionary = {}
var _preload_in_progress := false


func register_stage(definition: StageDefinition) -> Error:
    if _transition_in_progress or _preload_in_progress:
        return ERR_BUSY
    if definition == null:
        return ERR_INVALID_DATA
    var validated := definition.copy_validated()
    if validated == null:
        return ERR_INVALID_DATA
    if _stage_definitions.has(validated.stage_id):
        return ERR_ALREADY_EXISTS
    _stage_definitions[validated.stage_id] = validated
    return OK


func unregister_stage(stage_id: StringName) -> Error:
    if _transition_in_progress or _preload_in_progress:
        return ERR_BUSY
    return OK if _stage_definitions.erase(stage_id) else ERR_DOES_NOT_EXIST


func stage_definition(stage_id: StringName) -> StageDefinition:
    var definition: StageDefinition = _stage_definitions.get(stage_id)
    return definition.copy_validated() if definition != null else null


func preload_stage(stage_id: StringName) -> Dictionary:
    var failure := {"error": ERR_INVALID_DATA, "scene": null}
    if _transition_in_progress or _preload_in_progress:
        failure["error"] = ERR_BUSY
        return failure
    var definition := stage_definition(stage_id)
    if definition == null:
        return failure
    _preload_in_progress = true
    var error := ResourceLoader.load_threaded_request(definition.scene_path, "PackedScene", false, ResourceLoader.CACHE_MODE_REUSE)
    if error != OK:
        _preload_in_progress = false
        failure["error"] = error
        return failure
    var deadline := Time.get_ticks_msec() + 15000
    while true:
        var status := ResourceLoader.load_threaded_get_status(definition.scene_path)
        if status == ResourceLoader.THREAD_LOAD_LOADED:
            var scene := ResourceLoader.load_threaded_get(definition.scene_path) as PackedScene
            _preload_in_progress = false
            return {"error": OK if scene != null else ERR_INVALID_DATA, "scene": scene}
        if status != ResourceLoader.THREAD_LOAD_IN_PROGRESS or Time.get_ticks_msec() >= deadline:
            _preload_in_progress = false
            failure["error"] = ERR_TIMEOUT if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS else ERR_CANT_OPEN
            return failure
        await get_tree().process_frame
    return failure

func bind_world_slot(slot: Node3D) -> void:
    _world_slot = slot

func request_world_scene(scene: PackedScene, stage_id: StringName) -> void:
    if _transition_in_progress or _world_slot == null:
        return
    _transition_in_progress = true
    InputManager.set_mode(InputManager.Mode.DISABLED)
    for child in _world_slot.get_children():
        child.queue_free()
    var instance := scene.instantiate()
    _world_slot.add_child(instance)
    GameState.current_stage_id = stage_id
    AudioDirector.set_stage_audio(stage_id)
    EventBus.stage_changed.emit(stage_id)
    InputManager.set_mode(InputManager.Mode.GAMEPLAY)
    _transition_in_progress = false
