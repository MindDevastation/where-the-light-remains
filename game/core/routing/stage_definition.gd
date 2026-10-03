class_name StageDefinition
extends Resource
## Authored registry entry. SaveGame never supplies resource paths.

@export var stage_id: StringName = &""
@export_file("*.tscn") var scene_path := ""
@export var player_active := true
@export var input_mode: InputManager.Mode = InputManager.Mode.GAMEPLAY


func copy_validated() -> StageDefinition:
    var probe := SaveGame.new()
    probe.stage_id = stage_id
    if probe.copy_validated() == null or not scene_path.begins_with("res://") or not scene_path.ends_with(".tscn") or scene_path.contains(".."):
        return null
    if input_mode not in [InputManager.Mode.GAMEPLAY, InputManager.Mode.LIMITED_LOOK, InputManager.Mode.CINEMATIC, InputManager.Mode.UI]:
        return null
    if not player_active and input_mode in [InputManager.Mode.GAMEPLAY, InputManager.Mode.LIMITED_LOOK]:
        return null
    if not ResourceLoader.exists(scene_path, "PackedScene"):
        return null
    var definition := StageDefinition.new()
    definition.stage_id = stage_id
    definition.scene_path = scene_path
    definition.player_active = player_active
    definition.input_mode = input_mode
    return definition
