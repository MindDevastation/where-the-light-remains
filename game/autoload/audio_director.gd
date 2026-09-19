extends Node

var current_stage: StringName = &""
var current_state: StringName = &"silence"

func set_stage_audio(stage_id: StringName) -> void:
    current_stage = stage_id
    current_state = &"exploration"

func set_music_state(state_id: StringName) -> void:
    current_state = state_id

func force_silence(_seconds: float = 0.0) -> void:
    current_state = &"silence"

# Playlist selection, dual-player crossfade, snapshots, ducking and authored
# silence locks are implemented from MUSIC_RUNTIME_POLICY during the audio milestone.
