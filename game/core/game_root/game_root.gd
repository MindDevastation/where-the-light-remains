extends Node

@onready var world_slot: Node3D = $WorldSlot

func _ready() -> void:
    SceneRouter.bind_world_slot(world_slot)
    EventBus.stage_changed.emit(GameState.current_stage_id)
