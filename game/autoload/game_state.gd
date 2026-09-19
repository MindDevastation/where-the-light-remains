extends Node

var current_stage_id: StringName = &"s00_prologue"
var collected_fragments: Dictionary = {}
var game_completed := false

func reset_for_new_game() -> void:
    current_stage_id = &"s00_prologue"
    collected_fragments.clear()
    game_completed = false
