extends Node
## Actual finite PCM playback and public semantic/lease API; no shipping assets.

var _checks := 0
var _failures: Array[String] = []
var _started: Array[StringName] = []
var _profiles: Array[StringName] = []


func _ready() -> void:
    get_tree().create_timer(25.0, true).timeout.connect(func() -> void:
        push_error("AUDIO_PLAYLIST FAIL: bounded playback timeout")
        get_tree().quit(1)
    )
    _run.call_deferred()


func _check(condition: bool, message: String) -> void:
    _checks += 1
    if not condition:
        _failures.append(message)
        push_error("AUDIO_PLAYLIST FAIL: " + message)


func _cue(id: StringName, seconds: float, title: String = "", vocal: bool = false) -> MusicCue:
    var data := PackedByteArray()
    var count := int(seconds * 8000)
    data.resize(count * 2)
    for index in count:
        data.encode_s16(index * 2, int(3276.0 * sin(TAU * 440.0 * index / 8000.0)))
    var wav := AudioStreamWAV.new()
    wav.format = AudioStreamWAV.FORMAT_16_BITS
    wav.mix_rate = 8000
    wav.data = data
    var cue := MusicCue.new()
    cue.cue_id = id
    cue.stream = wav
    cue.source_title = title
    cue.vocal = vocal
    return cue


func _register(profile: MusicStage) -> void:
    var error := AudioDirector.register_stage(profile)
    _check(error == OK, "Register fixture " + String(profile.stage_id))
    if error == OK:
        _profiles.append(profile.stage_id)


func _stop() -> void:
    AudioDirector.set_music_state(&"unbound_fixture_state", 0.0)


func _playing() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for player in AudioDirector.playback_snapshot()["players"]:
        if player["playing"]:
            result.append(player)
    return result


func _active_id() -> StringName:
    var highest := -1.0
    var id: StringName = &""
    for player in _playing():
        if player["gain"] > highest:
            highest = player["gain"]
            id = player["cue"]
    return id


func _run() -> void:
    var original := GameState.capture_save()
    var hashes := [FileAccess.get_sha256(SaveManager.SAVE_PATH), FileAccess.get_sha256(SaveManager.BACKUP_PATH)]
    AudioDirector.cue_started.connect(func(id: StringName) -> void: _started.append(id))
    var a := _cue(&"queue_a", 12.0)
    var b := _cue(&"queue_b", 12.0)
    var c := _cue(&"queue_c", 12.0)
    var queue := MusicStage.new()
    queue.stage_id = &"s02_queue_fixture"
    queue.scripted_only = true
    queue.initial_state = &"fixture_idle"
    queue.authored_states = {&"fixture_a": a, &"fixture_b": b, &"fixture_c": c}
    _register(queue)
    AudioDirector.set_stage_audio(queue.stage_id)
    _check(AudioDirector.set_music_state(&"fixture_a", 0.0) == OK, "Immediate authored cue starts")
    var warmup_deadline := Time.get_ticks_msec() + 1000
    while Time.get_ticks_msec() < warmup_deadline and (_playing().is_empty() or _playing()[0]["position"] <= .02):
        await get_tree().create_timer(.04).timeout
    print("AUDIO_PLAYLIST initial playback: ", JSON.stringify(AudioDirector.playback_snapshot()))
    _check(_playing().size() == 1 and _active_id() == a.cue_id and _playing()[0]["position"] > .02, "Actual PCM playback advances")
    _check(AudioDirector.set_music_state(&"fixture_b", .25) == OK, "Start bounded crossfade")
    await get_tree().create_timer(.06).timeout
    var overlap := _playing()
    _check(overlap.size() == 2 and overlap[0]["gain"] > 0.0 and overlap[0]["gain"] < 1.0 and overlap[1]["gain"] > 0.0 and overlap[1]["gain"] < 1.0, "Exactly two actual players overlap with bounded intermediate gains")
    AudioDirector.set_music_state(&"fixture_c", .2)
    AudioDirector.set_music_state(&"fixture_a", .2)
    _check(_playing().size() == 2 and AudioDirector.playback_snapshot()["queued"], "Latest pending request queues without a third player")
    await get_tree().create_timer(.6).timeout
    _check(_playing().size() == 1 and _active_id() == a.cue_id and is_equal_approx(_playing()[0]["gain"], 1.0) and not _started.has(c.cue_id), "Only latest queued intent starts; discarded cue never plays")
    AudioDirector.set_music_state(&"fixture_b", .25)
    await get_tree().process_frame
    AudioDirector.set_music_state(&"fixture_c", .2)
    var silence := AudioDirector.force_silence()
    _check(_playing().is_empty() and not AudioDirector.playback_snapshot()["queued"], "Silence cancels active fade and pending request")
    AudioDirector.release_silence(silence)
    await get_tree().create_timer(.35).timeout
    _check(_playing().is_empty(), "No queued cue survives released silence")
    AudioDirector.set_music_state(&"fixture_a", 0.0)
    var lease := MusicStage.new()
    lease.stage_id = &"s01_lease_fixture"
    lease.scripted_only = true
    lease.initial_state = &"fixture_b"
    lease.authored_states[&"fixture_b"] = b
    _register(lease)
    await get_tree().create_timer(.12).timeout
    var before: float = _playing()[0]["position"]
    var token := AudioDirector.begin_stage_audio(lease.stage_id)
    _check(token > 0 and AudioDirector.owns_stage_audio(token) and _active_id() == a.cue_id, "Stage lease prepares intent while retaining outgoing actual stream")
    await get_tree().create_timer(.15).timeout
    _check(_playing()[0]["position"] > before + .04, "Outgoing cue continues through the pending lease")
    _check(AudioDirector.cancel_stage_audio(token) and AudioDirector.current_stage == queue.stage_id and _active_id() == a.cue_id and _playing()[0]["position"] > before, "Cancel restores metadata without restarting or rewinding playback")
    token = AudioDirector.begin_stage_audio(lease.stage_id)
    silence = AudioDirector.force_silence()
    _check(not AudioDirector.owns_stage_audio(token) and not AudioDirector.cancel_stage_audio(token) and AudioDirector.playback_snapshot()["silence_locks"] == 1, "Newer silence supersedes a lease and survives stale cancellation")
    AudioDirector.release_silence(silence)
    AudioDirector.set_music_state(&"fixture_a", 0.0)
    token = AudioDirector.begin_stage_audio(lease.stage_id)
    _check(AudioDirector.commit_stage_audio(token) == OK and not AudioDirector.owns_stage_audio(token) and AudioDirector.current_stage == lease.stage_id and _playing().size() <= 2, "Accepted lease commits the target profile once with only two players")
    _stop()

    var unique := _cue(&"bag_unique", .4)
    var shared := _cue(&"bag_shared", .4)
    var excluded := _cue(&"bag_excluded", .4)
    var bag := MusicStage.new()
    bag.stage_id = &"s03_bag_fixture"
    bag.unique_cue = unique
    bag.shared_pool.assign([shared, excluded])
    bag.playlist_exclusions.assign([excluded.cue_id])
    _register(bag)
    _started.clear()
    AudioDirector.set_stage_audio(bag.stage_id)
    await get_tree().create_timer(1.6).timeout
    _check(_started.size() >= 4 and _started[0] == unique.cue_id, "Finite playlist starts unique first and actually rotates")
    for index in _started.size():
        _check(_started[index] in [unique.cue_id, shared.cue_id], "Excluded cue never enters actual playlist")
        if index > 0:
            _check(_started[index] != _started[index - 1], "Actual shuffle rotation has no immediate repeats")
    print("AUDIO_PLAYLIST selected: ", _started)
    _stop()
    var single := MusicStage.new()
    single.stage_id = &"s04_single_fixture"
    single.unique_cue = unique
    single.shared_pool_enabled = false
    _register(single)
    _started.clear()
    AudioDirector.set_stage_audio(single.stage_id)
    await get_tree().create_timer(.7).timeout
    _check(_started == [unique.cue_id] and _playing().is_empty(), "One eligible finite cue exhausts without immediate repeat or endless rebuild")
    var prologue := MusicStage.new()
    prologue.stage_id = &"s00_policy_fixture"
    prologue.unique_cue = unique
    prologue.shared_pool.assign([shared])
    prologue.authored_states[&"fixture_spark"] = shared
    _register(prologue)
    AudioDirector.set_stage_audio(prologue.stage_id)
    await get_tree().create_timer(.1).timeout
    _check(_playing().is_empty() and not AudioDirector.playback_snapshot()["automatic"] and AudioDirector.stage_profile(prologue.stage_id).scripted_only, "Canonical S00 policy disallows automatic shared/unique score")
    _check(AudioDirector.set_music_state(&"fixture_spark", 0.0) == OK and _playing().size() == 1, "Explicit authored S00 semantic cue can play")
    _stop()

    var reflection := MusicStage.new()
    reflection.stage_id = &"s07_policy_fixture"
    reflection.initial_state = &"reflection"
    reflection.authored_states[&"reflection"] = _cue(&"reflection_excluded", 1.0, "Wooden Hall Puzzle v2")
    _register(reflection)
    AudioDirector.set_stage_audio(reflection.stage_id)
    _check(AudioDirector.set_music_state(&"reflection", 0.0) == ERR_UNAUTHORIZED and _playing().is_empty(), "S07 reflection rejects the forbidden active-puzzle source title")
    _stop()
    var voice := _cue(&"vocal_fixture", 2.0, "", true)
    var early := MusicStage.new()
    early.stage_id = &"s14_voice_fixture"
    early.authored_states[&"fixture_voice"] = voice
    _check(AudioDirector.register_stage(early) == ERR_INVALID_DATA, "Vocal registration is rejected before S15")
    var finale := MusicStage.new()
    finale.stage_id = &"s15_voice_fixture"
    finale.initial_state = &"fixture_idle"
    finale.authored_states[&"fixture_voice"] = voice
    _register(finale)
    AudioDirector.set_stage_audio(finale.stage_id)
    GameState.game_completed = false
    _check(AudioDirector.set_music_state(&"fixture_voice", 0.0) == ERR_UNAUTHORIZED, "S15 voice cannot bypass completion and final wide shot")
    AudioDirector.set_final_wide_shot_reached(true)
    _check(AudioDirector.set_music_state(&"fixture_voice", 0.0) == ERR_UNAUTHORIZED, "Wide shot alone never authorizes vocals")
    GameState.game_completed = true
    _check(AudioDirector.set_music_state(&"fixture_voice", 0.0) == OK and _playing().size() == 1, "Both explicit gates authorize the actual vocal fixture")
    AudioDirector.set_final_wide_shot_reached(false)
    _check(_playing().is_empty(), "Revoked authored wide shot immediately stops vocals")
    AudioDirector.set_final_wide_shot_reached(true)
    AudioDirector.set_music_state(&"fixture_voice", 0.0)
    GameState.game_completed = false
    await get_tree().process_frame
    await get_tree().process_frame
    _check(_playing().is_empty(), "Revoked logical completion stops existing vocals on the actual process tick")
    _stop()
    for id in _profiles:
        _check(AudioDirector.unregister_stage(id) == OK, "Release fixture profile " + String(id))
    # Stop/stream replacement reaches the audio thread asynchronously. Drain
    # the fixture's last rapid vocal revocations before engine teardown.
    await get_tree().create_timer(.2, true).timeout
    GameState.apply_save(original)
    _check(not SaveManager.get("_dirty") and [FileAccess.get_sha256(SaveManager.SAVE_PATH), FileAccess.get_sha256(SaveManager.BACKUP_PATH)] == hashes, "Playback testing preserves actual protected saves")
    if _failures.is_empty():
        print("AUDIO_PLAYLIST PASS: ", _checks, " assertions; actual finite playback, unique/no-repeat bag, bounded latest crossfade, leases and canonical semantic/vocal guards")
    get_tree().quit(0 if _failures.is_empty() else 1)
