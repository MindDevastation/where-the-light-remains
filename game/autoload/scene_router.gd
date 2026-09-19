extends Node

var _world_slot: Node3D
var _transition_in_progress := false

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
