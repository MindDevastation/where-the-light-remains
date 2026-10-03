extends Node

var current_stage_id: StringName = &"s00_prologue"
var collected_fragments: Dictionary = {}
var game_completed := false
var checkpoint_id: StringName = &""
var world_states: Dictionary = {}
var milestones: Dictionary = {}
var achievement_ids: Array[StringName] = []

func reset_for_new_game() -> void:
    current_stage_id = &"s00_prologue"
    collected_fragments.clear()
    game_completed = false
    checkpoint_id = &""
    world_states.clear()
    milestones.clear()
    achievement_ids.clear()


func capture_save() -> SaveGame:
    if collected_fragments.size() > SaveGame.FOUND_ORDER.size():
        return null
    var saved := SaveGame.new()
    saved.stage_id = current_stage_id
    saved.checkpoint_id = checkpoint_id
    saved.game_completed = game_completed
    for id in collected_fragments:
        if typeof(collected_fragments[id]) != TYPE_BOOL or not collected_fragments[id] or typeof(id) not in [TYPE_STRING, TYPE_STRING_NAME]:
            return null
        saved.collected_fragments.append(StringName(id))
    # Validation precedes recursive copying, including cyclic/hostile input.
    saved.world_states = world_states
    saved.milestones = milestones
    saved.achievement_ids = achievement_ids.duplicate()
    return saved.copy_validated()


func apply_save(saved: SaveGame) -> Error:
    if saved == null:
        return ERR_INVALID_DATA
    var validated := saved.copy_validated()
    if validated == null:
        return ERR_INVALID_DATA
    # Complete validation/copy precedes mutation. No routing/audio/file side effects.
    var fragments := {}
    for id in validated.collected_fragments:
        fragments[id] = true
    current_stage_id = validated.stage_id
    checkpoint_id = validated.checkpoint_id
    collected_fragments = fragments
    world_states = validated.world_states
    milestones = validated.milestones
    achievement_ids = validated.achievement_ids
    game_completed = validated.game_completed
    return OK
