extends Node
## Owns score players and semantic mix. SettingsManager owns parent preferences.

signal cue_started(cue_id: StringName)
signal cue_finished(cue_id: StringName)

const MUSIC_BUSES: Array[StringName] = [&"Music_Main", &"Music_Stems"]
var current_stage: StringName = &""
var current_state: StringName = &"silence"
var _stages: Dictionary[StringName, MusicStage] = {}
var _players: Array[AudioStreamPlayer] = []
var _cues: Array[MusicCue] = [null, null]
var _gains: Array[float] = [0.0, 0.0]
var _active := -1
var _fade: Dictionary = {}
var _queued: Dictionary = {}
var _bag: Array[MusicCue] = []
var _last_cue: StringName = &""
var _unique_pending := true
var _automatic := false
var _exhausted := false
var _requested_state: StringName = &"silence"
var _pending_stage: Dictionary = {}
var _revision := 0
var _token := 0
var _silence: Dictionary[int, int] = {}
var _ducks: Dictionary[int, float] = {}
var _prior_mutes: Dictionary = {}
var _prior_gains: Dictionary = {}
var _resume_requested := false
var _silence_latched := false
var _state_silence := 0
var _final_wide_shot := false
var _exit_preparing := false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _rng.randomize()
    for index in 2:
        var player := AudioStreamPlayer.new()
        player.name = "MusicA" if index == 0 else "MusicB"
        player.bus = &"Music_Main"
        player.max_polyphony = 1
        player.volume_linear = 0.0
        player.process_mode = Node.PROCESS_MODE_ALWAYS
        add_child(player)
        player.finished.connect(_on_finished.bind(index))
        _players.append(player)


func register_stage(definition: MusicStage) -> Error:
    if definition == null: return ERR_INVALID_DATA
    if not _pending_stage.is_empty(): return ERR_BUSY
    var validated := definition.copy_validated()
    if validated == null: return ERR_INVALID_DATA
    if _stages.has(validated.stage_id): return ERR_ALREADY_EXISTS
    if _stages.size() >= 64: return ERR_OUT_OF_MEMORY
    _stages[validated.stage_id] = validated
    return OK


func unregister_stage(stage_id: StringName) -> Error:
    if not _pending_stage.is_empty() or (stage_id == current_stage and (_automatic or _active >= 0)): return ERR_BUSY
    return OK if _stages.erase(stage_id) else ERR_DOES_NOT_EXIST


func stage_profile(stage_id: StringName) -> MusicStage:
    var profile := _stages.get(stage_id) as MusicStage
    return profile.copy_validated() if profile != null else null


func begin_stage_audio(stage_id: StringName) -> int:
    if _exit_preparing or MusicStage.group_for_stage(stage_id).is_empty() or not _pending_stage.is_empty(): return 0
    _token += 1
    _revision += 1
    _pending_stage = {"token": _token, "previous_stage": current_stage, "previous_state": current_state, "stage": stage_id}
    current_stage = stage_id
    var profile := _stages.get(stage_id) as MusicStage
    current_state = profile.initial_state if profile != null else &"exploration"
    if not _silence.is_empty() or _silence_latched: current_state = &"silence"
    return _token


func owns_stage_audio(token: int) -> bool:
    return token > 0 and _pending_stage.get("token", 0) == token


func cancel_stage_audio(token: int) -> bool:
    if not owns_stage_audio(token): return false
    current_stage = _pending_stage["previous_stage"]
    current_state = &"silence" if not _silence.is_empty() else _pending_stage["previous_state"]
    _pending_stage.clear()
    return true


func commit_stage_audio(token: int) -> Error:
    if not owns_stage_audio(token): return ERR_SKIP
    var stage: StringName = _pending_stage["stage"]
    _pending_stage.clear()
    _accept_stage(stage)
    return OK


func set_stage_audio(stage_id: StringName) -> Error:
    if MusicStage.group_for_stage(stage_id).is_empty(): return ERR_INVALID_DATA
    _supersede_pending()
    _revision += 1
    _accept_stage(stage_id)
    return OK


func _accept_stage(stage_id: StringName) -> void:
    _final_wide_shot = false
    current_stage = stage_id
    _bag.clear()
    _last_cue = &""
    _unique_pending = true
    _exhausted = false
    var profile := _stages.get(stage_id) as MusicStage
    _dispatch_state(profile.initial_state if profile != null else &"exploration", profile.stage_crossfade_seconds if profile != null else 2.0)


func _supersede_pending() -> void:
    if not _pending_stage.is_empty(): cancel_stage_audio(_pending_stage["token"])


func set_music_state(state_id: StringName, fade_seconds: float = 2.0) -> Error:
    if not SaveGame.identifier(state_id) or not _valid_fade(fade_seconds): return ERR_INVALID_DATA
    _supersede_pending()
    _revision += 1
    return _dispatch_state(state_id, fade_seconds)


func _dispatch_state(state_id: StringName, fade_seconds: float) -> Error:
    if _exit_preparing: return ERR_BUSY
    _resume_requested = false
    _silence_latched = false
    if _state_silence > 0:
        _silence.erase(_state_silence)
        _state_silence = 0
    _finish_silence()
    _requested_state = state_id
    if state_id in [&"silence", &"egg_pickup_silence"]:
        _state_silence = force_silence()
        return OK if _state_silence > 0 else ERR_UNAVAILABLE
    if not _silence.is_empty():
        _resume_requested = true
        current_state = &"silence"
        return OK
    current_state = state_id
    return _apply_intent(fade_seconds)


func _apply_intent(fade_seconds: float) -> Error:
    _automatic = false
    if not _mix_available():
        _stop_music()
        return ERR_UNAVAILABLE
    var profile := _stages.get(current_stage) as MusicStage
    if profile == null:
        _stop_music()
        return ERR_UNCONFIGURED
    if _requested_state in [&"silence", &"egg_pickup_silence"]:
        _stop_music()
        return OK
    _automatic = _requested_state == &"exploration" and not profile.scripted_only
    var cue := _next_playlist_cue() if _automatic else profile.authored_states.get(_requested_state) as MusicCue
    if cue == null:
        _stop_music()
        return OK if _requested_state == &"exploration" else ERR_UNAVAILABLE
    if not _cue_allowed(cue):
        _stop_music()
        _automatic = false
        return ERR_UNAUTHORIZED
    _request_cue(cue, fade_seconds)
    return OK


func _cue_allowed(cue: MusicCue) -> bool:
    if current_stage.begins_with("s07_") and _requested_state == &"reflection" and cue.source_title == "Wooden Hall Puzzle v2": return false
    return not cue.vocal or (current_stage.begins_with("s15_") and _final_wide_shot and GameState.game_completed)


func set_final_wide_shot_reached(value: bool) -> Error:
    if not current_stage.begins_with("s15_"): return ERR_UNAVAILABLE
    _final_wide_shot = value
    if not value and _active >= 0 and _cues[_active] != null and _cues[_active].vocal: _stop_music()
    return OK


func _next_playlist_cue(rebuilt: bool = false) -> MusicCue:
    var profile := _stages.get(current_stage) as MusicStage
    if profile == null or profile.scripted_only or _exhausted: return null
    if _unique_pending:
        _unique_pending = false
        if profile.unique_cue != null and not profile.playlist_exclusions.has(profile.unique_cue.cue_id):
            return profile.unique_cue
    if _bag.is_empty():
        if profile.shared_pool_enabled:
            for cue in profile.shared_pool:
                if not profile.playlist_exclusions.has(cue.cue_id) and _cue_allowed(cue): _bag.append(cue)
        if profile.unique_cue != null and not profile.playlist_exclusions.has(profile.unique_cue.cue_id) and _cue_allowed(profile.unique_cue):
            for repeat in profile.unique_rotation_weight: _bag.append(profile.unique_cue)
        for index in range(_bag.size() - 1, 0, -1):
            var other := _rng.randi_range(0, index)
            var cue := _bag[index]
            _bag[index] = _bag[other]
            _bag[other] = cue
    for index in range(_bag.size() - 1, -1, -1):
        if _bag[index].cue_id != _last_cue:
            var cue := _bag[index]
            _bag.remove_at(index)
            return cue
    # Discard leftover repeat tickets and rebuild once. A single eligible
    # identity then exhausts instead of rotating into an immediate repeat.
    _bag.clear()
    if not rebuilt: return _next_playlist_cue(true)
    _exhausted = true
    return null


func _request_cue(cue: MusicCue, seconds: float) -> void:
    if not _fade.is_empty():
        _queued = {"cue": cue, "seconds": seconds, "revision": _revision}
        return
    _start_cue(cue, seconds)


func _start_cue(cue: MusicCue, seconds: float) -> void:
    if not _silence.is_empty() or not _cue_allowed(cue) or _players.size() != 2 or not _mix_available(): return
    var outgoing := _active
    var incoming := 0 if outgoing != 0 else 1
    var duration := minf(seconds, cue.stream.get_length() * 0.5)
    if outgoing >= 0 and _cues[outgoing] != null and _players[outgoing].playing and not _cues[outgoing].is_looping():
        duration = minf(duration, maxf(0.0, _cues[outgoing].stream.get_length() - _players[outgoing].get_playback_position()))
    _players[incoming].stop()
    _players[incoming].stream = cue.stream
    _cues[incoming] = cue
    _gains[incoming] = 0.0 if duration > 0.0 else 1.0
    _players[incoming].volume_linear = _gains[incoming] * db_to_linear(cue.gain_db)
    _players[incoming].play()
    _last_cue = cue.cue_id
    _active = incoming
    if duration <= 0.0:
        if outgoing >= 0: _stop_player(outgoing)
    else:
        _fade = {"outgoing": outgoing, "incoming": incoming, "duration": duration, "elapsed": 0.0, "out_gain": _gains[outgoing] if outgoing >= 0 else 0.0}
    _emit_started.call_deferred(cue.cue_id, _revision, current_stage)


func _emit_started(id: StringName, revision: int, stage: StringName) -> void:
    if revision == _revision and stage == current_stage and _silence.is_empty(): cue_started.emit(id)


func _on_finished(index: int) -> void:
    if _cues[index] != null and not _players[index].playing:
        _emit_finished.call_deferred(_cues[index].cue_id, _revision, current_stage)


func _emit_finished(id: StringName, revision: int, stage: StringName) -> void:
    if revision == _revision and stage == current_stage and _silence.is_empty() and _pending_stage.is_empty(): cue_finished.emit(id)


func _process(delta: float) -> void:
    if _exit_preparing: return
    _expire_silence()
    _finish_silence()
    if _pending_stage.is_empty() and _active >= 0 and _cues[_active] != null and _cues[_active].vocal and not _cue_allowed(_cues[_active]):
        _stop_music()
    if not _fade.is_empty():
        _fade["elapsed"] += delta
        var weight := minf(1.0, _fade["elapsed"] / _fade["duration"])
        var incoming: int = _fade["incoming"]
        var outgoing: int = _fade["outgoing"]
        _gains[incoming] = weight
        if outgoing >= 0: _gains[outgoing] = _fade["out_gain"] * (1.0 - weight)
        for index in 2:
            if _cues[index] != null: _players[index].volume_linear = _gains[index] * db_to_linear(_cues[index].gain_db)
        if weight >= 1.0:
            if outgoing >= 0: _stop_player(outgoing)
            _fade.clear()
    if not _pending_stage.is_empty() or not _silence.is_empty(): return
    if _fade.is_empty() and not _queued.is_empty():
        var request := _queued
        _queued = {}
        if request["revision"] == _revision: _start_cue(request["cue"], request["seconds"])
        return
    if not _automatic or not _fade.is_empty() or _exhausted: return
    var profile := _stages.get(current_stage) as MusicStage
    if profile == null: return
    var remaining := 0.0
    if _active >= 0 and _players[_active].playing and _cues[_active] != null:
        remaining = _cues[_active].stream.get_length() - _players[_active].get_playback_position()
    if remaining <= profile.playlist_crossfade_seconds:
        var cue := _next_playlist_cue()
        if cue != null: _start_cue(cue, minf(profile.playlist_crossfade_seconds, maxf(remaining, 0.0)))


func force_silence(seconds: float = 0.0) -> int:
    if not is_finite(seconds) or seconds < 0.0 or seconds > 3600.0 or _silence.size() >= 64 or not _mix_available(): return 0
    _supersede_pending()
    _revision += 1
    _token += 1
    if _prior_mutes.is_empty():
        for bus in MUSIC_BUSES:
            var index := AudioServer.get_bus_index(bus)
            _prior_mutes[bus] = AudioServer.is_bus_mute(index)
    _silence[_token] = Time.get_ticks_msec() + ceili(seconds * 1000.0) if seconds > 0.0 else 0
    for bus in MUSIC_BUSES:
        AudioServer.set_bus_mute(AudioServer.get_bus_index(bus), true)
    _resume_requested = false
    _silence_latched = true
    _automatic = false
    _stop_music()
    current_state = &"silence"
    return _token


func release_silence(token: int) -> Error:
    if not _silence.has(token): return ERR_DOES_NOT_EXIST
    if _silence[token] > Time.get_ticks_msec(): return ERR_BUSY
    _silence.erase(token)
    _finish_silence()
    return OK


func _expire_silence() -> void:
    for token in _silence.keys():
        if _silence[token] > 0 and Time.get_ticks_msec() >= _silence[token]: _silence.erase(token)


func _finish_silence() -> void:
    if not _silence.is_empty() or (_silence_latched and not _resume_requested) or (not _pending_stage.is_empty() and _silence_latched): return
    for bus in _prior_mutes:
        var index := AudioServer.get_bus_index(bus)
        if index >= 0: AudioServer.set_bus_mute(index, _prior_mutes[bus])
    _prior_mutes.clear()
    if _resume_requested and _pending_stage.is_empty():
        _resume_requested = false
        _silence_latched = false
        current_state = _requested_state
        _apply_intent(2.0)


func acquire_duck(gain_db: float = -4.0) -> int:
    if not is_finite(gain_db) or gain_db < -24.0 or gain_db > 0.0 or _ducks.size() >= 64 or not _mix_available(): return 0
    _token += 1
    if _ducks.is_empty():
        for bus in MUSIC_BUSES:
            var index := AudioServer.get_bus_index(bus)
            _prior_gains[bus] = AudioServer.get_bus_volume_db(index)
    _ducks[_token] = gain_db
    _apply_ducks()
    return _token


func release_duck(token: int) -> Error:
    if not _ducks.erase(token): return ERR_DOES_NOT_EXIST
    _apply_ducks()
    return OK


func _apply_ducks() -> void:
    var reduction := 0.0
    for value in _ducks.values(): reduction = minf(reduction, value)
    for bus in _prior_gains:
        var index := AudioServer.get_bus_index(bus)
        if index >= 0: AudioServer.set_bus_volume_db(index, _prior_gains[bus] + reduction)
    if _ducks.is_empty(): _prior_gains.clear()


func _stop_player(index: int) -> void:
    _players[index].stop()
    _players[index].stream = null
    _cues[index] = null
    _gains[index] = 0.0
    _players[index].volume_linear = 0.0


func _stop_music() -> void:
    _fade.clear()
    _queued.clear()
    for index in _players.size(): _stop_player(index)
    _active = -1


func prepare_safe_exit() -> void:
    # App calls only after a successful flush. Failed/stayed exits leave
    # playback and every existing owner untouched. Stop commands reach the
    # audio thread asynchronously, so drain before engine ObjectDB teardown.
    _exit_preparing = true
    _supersede_pending()
    _revision += 1
    _automatic = false
    _resume_requested = false
    _silence_latched = true
    _stop_music()
    for bus in MUSIC_BUSES:
        var index := AudioServer.get_bus_index(bus)
        if index >= 0:
            AudioServer.set_bus_mute(index, true)
    await get_tree().create_timer(.2, true).timeout


func playback_snapshot() -> Dictionary:
    var players: Array[Dictionary] = []
    for index in _players.size():
        players.append({"cue": _cues[index].cue_id if _cues[index] != null else &"", "playing": _players[index].playing, "gain": _gains[index], "position": _players[index].get_playback_position()})
    return {"stage": current_stage, "state": current_state, "group": MusicStage.group_for_stage(current_stage), "players": players, "silence_locks": _silence.size(), "silence_latched": _silence_latched, "duck_locks": _ducks.size(), "pending_stage": not _pending_stage.is_empty(), "automatic": _automatic, "revision": _revision, "queued": not _queued.is_empty()}


func _valid_fade(seconds: float) -> bool:
    return is_finite(seconds) and seconds >= 0.0 and seconds <= 7.0


func _mix_available() -> bool:
    for bus in MUSIC_BUSES:
        var index := AudioServer.get_bus_index(bus)
        if index < 0 or AudioServer.get_bus_send(index) != &"Music": return false
    return AudioServer.get_bus_index(&"Music") >= 0
