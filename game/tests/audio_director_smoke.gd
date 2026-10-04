extends Node
## Generated PCM through real mixer; no shipping music, microphone or speakers.

var _checks := 0
var _failures: Array[String] = []
var _captures: Dictionary = {}
var _metrics: Array[Dictionary] = []
var _extra_players: Array[AudioStreamPlayer] = []


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().create_timer(25.0, true).timeout.connect(func() -> void:
        push_error("AUDIO_DIRECTOR FAIL: bounded mixer timeout")
        get_tree().quit(1)
    )
    _run.call_deferred()


func _check(condition: bool, message: String) -> void:
    _checks += 1
    if not condition:
        _failures.append(message)
        push_error("AUDIO_DIRECTOR FAIL: " + message)


func _tone(seconds: float, frequency: float = 440.0) -> AudioStreamWAV:
    var rate := 8000
    var samples := int(seconds * rate)
    var bytes := PackedByteArray()
    bytes.resize(samples * 2)
    for sample in samples:
        bytes.encode_s16(sample * 2, int(32767.0 * .1 * sin(TAU * frequency * sample / rate)))
    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = rate
    stream.data = bytes
    return stream


func _measure(name: String) -> Dictionary:
    await get_tree().create_timer(.12, true).timeout
    for capture: AudioEffectCapture in _captures.values():
        capture.clear_buffer()
    await get_tree().create_timer(.16, true).timeout
    var peaks := {}
    for bus in _captures:
        var capture: AudioEffectCapture = _captures[bus]
        var frames := capture.get_buffer(capture.get_frames_available())
        var peak := 0.0
        for frame in frames:
            peak = maxf(peak, maxf(absf(frame.x), absf(frame.y)))
        peaks[bus] = peak
    _metrics.append({"name": name, "peaks": peaks})
    return peaks


func _playing_count() -> int:
    var count := 0
    for player in AudioDirector.playback_snapshot()["players"]:
        if player["playing"]:
            count += 1
    return count


func _run() -> void:
    print("AUDIO_DIRECTOR runtime: ", Engine.get_version_info()["string"], "; display=", DisplayServer.get_name(), "; audio=", AudioServer.get_driver_name())
    var original_layout := AudioServer.generate_bus_layout()
    var original_settings := SettingsManager.snapshot()
    var logical := GameState.capture_save().to_dict()
    var hashes := [FileAccess.get_sha256(SaveManager.SAVE_PATH), FileAccess.get_sha256(SaveManager.BACKUP_PATH)]
    SettingsManager.master_volume = .75
    SettingsManager.music_volume = .4
    SettingsManager.sfx_volume = .6
    SettingsManager.apply_runtime(false)
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"Music_Main"), -1.0)
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"Music_Stems"), -2.0)
    for bus in [&"Music", &"SFX", &"Ambience", &"UI"]:
        var capture := AudioEffectCapture.new()
        capture.buffer_length = .5
        AudioServer.add_bus_effect(AudioServer.get_bus_index(bus), capture)
        _captures[bus] = capture
    var cue := MusicCue.new()
    cue.cue_id = &"mixer_fixture"
    cue.stream = _tone(18.0)
    var profile := MusicStage.new()
    profile.stage_id = &"s01_mixer_fixture"
    profile.scripted_only = true
    profile.initial_state = &"fixture_tone"
    profile.authored_states[&"fixture_tone"] = cue
    _check(AudioDirector.register_stage(profile) == OK, "Register isolated authored mixer fixture")
    _check(AudioDirector.set_stage_audio(profile.stage_id) == OK, "Select existing authored cue through public stage API")
    await get_tree().create_timer(2.1, true).timeout
    _check(_playing_count() == 1 and AudioDirector.playback_snapshot()["players"].size() == 2, "Exactly two owned players and one stable real cue")
    var baseline := await _measure("baseline")
    _check(baseline[&"Music"] > .02, "Music_Main produces audible PCM at the Music parent")
    var duck_a := AudioDirector.acquire_duck(-4.0)
    var duck_b := AudioDirector.acquire_duck(-6.0)
    _check(duck_a > 0 and duck_b > 0 and duck_a != duck_b, "Independent bounded duck tokens")
    var ducked := await _measure("nested_duck")
    _check(absf(ducked[&"Music"] / baseline[&"Music"] - db_to_linear(-6.0)) < .04, "Real score signal uses the stronger nested duck")
    _check(is_equal_approx(AudioServer.get_bus_volume_linear(AudioServer.get_bus_index(&"Music")), .4) and is_equal_approx(AudioServer.get_bus_volume_linear(AudioServer.get_bus_index(&"SFX")), .6), "Ducking preserves actual parent preference gains")
    _check(AudioDirector.release_duck(duck_b) == OK, "Release only stronger duck")
    var single := await _measure("single_duck")
    _check(absf(single[&"Music"] / baseline[&"Music"] - db_to_linear(-4.0)) < .04, "Remaining duck still changes actual PCM")
    _check(AudioDirector.release_duck(duck_a) == OK and AudioDirector.release_duck(duck_a) == ERR_DOES_NOT_EXIST, "Duck release is token-owned and cannot release twice")
    _check(is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"Music_Main")), -1.0) and is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"Music_Stems")), -2.0), "Last duck restores both exact child gains")
    for bus in [&"Music_Stems", &"SFX_Critical", &"Ambience", &"UI"]:
        var player := AudioStreamPlayer.new()
        player.bus = bus
        var stream := _tone(1.0, 640.0)
        stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
        stream.loop_end = 8000
        player.stream = stream
        player.process_mode = Node.PROCESS_MODE_ALWAYS
        add_child(player)
        player.play()
        _extra_players.append(player)
    var silence_a := AudioDirector.force_silence()
    var silence_b := AudioDirector.force_silence(.9)
    _check(silence_a > 0 and silence_b > 0 and silence_a != silence_b, "Independent indefinite and monotonic timed silence tokens")
    _check(AudioDirector.release_silence(silence_b) == ERR_BUSY, "Cannot shorten an unexpired silence deadline")
    _check(_playing_count() == 0 and not AudioDirector.playback_snapshot()["queued"], "Silence immediately stops owned current/pending score")
    var silent := await _measure("nested_silence")
    _check(silent[&"Music"] < .00001, "Actual Music_Main and externally playing Stems output reach zero")
    for bus in [&"SFX", &"Ambience", &"UI"]:
        _check(silent[bus] > .02, "Full score silence retains independent PCM: " + String(bus))
    _check(AudioDirector.release_silence(silence_a) == OK, "Release one silence owner")
    _check(AudioDirector.playback_snapshot()["silence_locks"] == 1, "Remaining timed silence owner survives")
    get_tree().paused = true
    await get_tree().create_timer(1.0, true).timeout
    get_tree().paused = false
    _check(AudioDirector.playback_snapshot()["silence_locks"] == 0 and AudioDirector.playback_snapshot()["silence_latched"], "Timed silence expires while paused and keeps deliberate silence latched")
    _check(_playing_count() == 0 and AudioServer.is_bus_mute(AudioServer.get_bus_index(&"Music_Stems")), "Expiry alone never resumes score or an external stem")
    var expired := await _measure("expired_without_new_intent")
    _check(expired[&"Music"] < .00001, "No second swell after silence expires")
    _extra_players[0].stop()
    _check(AudioDirector.set_music_state(&"fixture_tone", 0.0) == OK, "Only explicit semantic intent resumes authored cue")
    var resumed := await _measure("explicit_resume")
    _check(resumed[&"Music"] > .02 and not AudioServer.is_bus_mute(AudioServer.get_bus_index(&"Music_Main")) and not AudioServer.is_bus_mute(AudioServer.get_bus_index(&"Music_Stems")), "Explicit intent restores actual child mutes and playback")
    AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Music_Stems"), true)
    var prior_muted := AudioDirector.force_silence()
    AudioDirector.release_silence(prior_muted)
    AudioDirector.set_music_state(&"fixture_tone", 0.0)
    _check(AudioServer.is_bus_mute(AudioServer.get_bus_index(&"Music_Stems")), "Silence restoration respects a pre-existing child mute")
    _check(AudioDirector.acquire_duck(NAN) == 0 and AudioDirector.force_silence(-1.0) == 0, "Invalid requests cannot create locks")
    AudioDirector.set_music_state(&"unbound_fixture_state", 0.0)
    _check(_playing_count() == 0 and AudioDirector.unregister_stage(profile.stage_id) == OK, "Unbound semantic state stops score and fixture registry releases")
    for player in _extra_players:
        player.stop()
        player.queue_free()
    await get_tree().create_timer(.1, true).timeout
    AudioServer.set_bus_layout(original_layout)
    for key in original_settings:
        SettingsManager.set(key, original_settings[key])
    SettingsManager.apply_runtime(false)
    _check(GameState.capture_save().to_dict() == logical and not SaveManager.get("_dirty") and [FileAccess.get_sha256(SaveManager.SAVE_PATH), FileAccess.get_sha256(SaveManager.BACKUP_PATH)] == hashes, "Mixer testing preserves logical state and both actual save files")
    for metric in _metrics:
        print("AUDIO_DIRECTOR PCM: ", JSON.stringify(metric))
    if _failures.is_empty():
        print("AUDIO_DIRECTOR PASS: ", _checks, " assertions; actual PCM ducking, independent branches, nested timed silence, no automatic replay and exact preferences")
    get_tree().quit(0 if _failures.is_empty() else 1)
