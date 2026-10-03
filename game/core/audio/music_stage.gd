class_name MusicStage
extends Resource
## Explicit authored bindings; never populated from paths in save data.

@export var stage_id: StringName = &""
@export var unique_cue: MusicCue
@export var shared_pool: Array[MusicCue] = []
@export var shared_pool_enabled := true
@export var scripted_only := false
@export var initial_state: StringName = &"exploration"
@export var authored_states: Dictionary[StringName, MusicCue] = {}
@export var playlist_exclusions: Array[StringName] = []
@export_range(1, 4) var unique_rotation_weight := 2
@export_range(4.0, 7.0) var playlist_crossfade_seconds := 6.0
@export_range(1.0, 3.0) var stage_crossfade_seconds := 2.0


static func group_for_stage(id: StringName) -> StringName:
    var probe := SaveGame.new()
    probe.stage_id = id
    if probe.copy_validated() == null:
        return &""
    var number := int(String(id).substr(1, 2))
    if number in [0, 1, 10, 11]: return &"A"
    if number in [2, 3]: return &"B"
    if number in [4, 6]: return &"C"
    if number in [5, 7]: return &"D"
    return &"E"


func copy_validated() -> MusicStage:
    if group_for_stage(stage_id).is_empty() or not SaveGame.identifier(initial_state):
        return null
    if shared_pool.size() > 32 or authored_states.size() > 64 or playlist_exclusions.size() > 32 or unique_rotation_weight < 1 or unique_rotation_weight > 4:
        return null
    if not is_finite(playlist_crossfade_seconds) or playlist_crossfade_seconds < 4.0 or playlist_crossfade_seconds > 7.0 or not is_finite(stage_crossfade_seconds) or stage_crossfade_seconds < 1.0 or stage_crossfade_seconds > 3.0:
        return null
    var copy := MusicStage.new()
    copy.stage_id = stage_id
    copy.shared_pool_enabled = shared_pool_enabled
    copy.scripted_only = scripted_only or int(String(stage_id).substr(1, 2)) in [0, 6, 12, 13, 14, 15]
    if copy.scripted_only:
        copy.shared_pool_enabled = false
    copy.initial_state = initial_state
    copy.unique_rotation_weight = unique_rotation_weight
    copy.playlist_crossfade_seconds = playlist_crossfade_seconds
    copy.stage_crossfade_seconds = stage_crossfade_seconds
    if unique_cue != null:
        copy.unique_cue = unique_cue.copy_validated()
        if copy.unique_cue == null or (not copy.scripted_only and copy.unique_cue.is_looping()) or (copy.unique_cue.vocal and not String(stage_id).begins_with("s15_")):
            return null
    var seen := {}
    if copy.unique_cue != null: seen[copy.unique_cue.cue_id] = true
    for cue in shared_pool:
        if cue == null: return null
        var validated := cue.copy_validated()
        if validated == null or validated.is_looping() or seen.has(validated.cue_id) or (validated.vocal and not String(stage_id).begins_with("s15_")): return null
        seen[validated.cue_id] = true
        copy.shared_pool.append(validated)
    for state in authored_states:
        if not SaveGame.identifier(state) or authored_states[state] == null: return null
        var cue := authored_states[state].copy_validated()
        if cue == null or (cue.vocal and not String(stage_id).begins_with("s15_")): return null
        copy.authored_states[state] = cue
    for id in playlist_exclusions:
        if not SaveGame.identifier(id) or copy.playlist_exclusions.has(id): return null
        copy.playlist_exclusions.append(id)
    return copy
