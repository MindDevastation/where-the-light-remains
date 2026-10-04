extends Node
## Complete source-derived pools in a private validator copy only.
## Energy windows test decoders; no notes/voices/musical acceptance inferred.

const A: Array[String] = ["mus_s01_archive_awakening_v01", "mus_s01_activation_sequence_v01", "mus_s01_archive_fragment_v01", "mus_s01_hub_motif_v01", "mus_s01_mechanism_light_v01", "mus_s01_resonant_puzzle_v01"]
const B: Array[String] = ["mus_s02_cold_to_warm_v01", "mus_s02_silent_roads_v01", "mus_s02_muted_pulse_v01", "mus_s02_quiet_exhale_v01"]
const STAGES: Array[StringName] = [&"s01_pool_review", &"s02_pool_review"]
var _checks := 0
var _failures: Array[String] = []
var _capture: AudioEffectCapture


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().create_timer(45.0, true).timeout.connect(func() -> void:
        push_error("AUDIO_POOL_REVIEW FAIL: bounded real pool timeout")
        get_tree().quit(1)
    )
    _run.call_deferred()


func _check(value: bool, message: String) -> void:
    _checks += 1
    if not value:
        _failures.append(message)
        push_error("AUDIO_POOL_REVIEW FAIL: " + message)


func _playing() -> Array[AudioStreamPlayer]:
    var players: Array[AudioStreamPlayer] = []
    for child in AudioDirector.get_children():
        if child is AudioStreamPlayer and child.playing: players.append(child)
    return players


func _cue() -> String:
    var gain := -1.0
    var name := ""
    for player in AudioDirector.playback_snapshot()["players"]:
        if player["playing"] and float(player["gain"]) > gain:
            gain = float(player["gain"])
            name = String(player["cue"])
    return name


func _pcm(id: String, position: float) -> float:
    for player in _playing(): player.seek(position)
    await get_tree().create_timer(.12, true).timeout
    _capture.clear_buffer()
    await get_tree().create_timer(.2, true).timeout
    var frames := _capture.get_buffer(_capture.get_frames_available())
    var energy := 0.0
    for frame in frames: energy += frame.length_squared()
    var rms := sqrt(energy / maxf(1.0, frames.size() * 2.0))
    _check(frames.size() > 1000 and rms > .001, "Actual source-derived Music PCM for " + id)
    print("AUDIO_POOL_REVIEW PCM: ", JSON.stringify({"cue": id, "position": position, "frames": frames.size(), "rms": rms}))
    return rms


func _run() -> void:
    var fixture := "res://audio/review/test_windows.json"
    _check(FileAccess.file_exists(fixture), "Private sealed decoder windows exist")
    if not FileAccess.file_exists(fixture):
        get_tree().quit(1)
        return
    var windows: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(fixture))
    var logical := GameState.capture_save().to_dict()
    var saved := [FileAccess.get_sha256(SaveManager.SAVE_PATH), FileAccess.get_sha256(SaveManager.BACKUP_PATH)]
    var settings := SettingsManager.snapshot()
    var layout := AudioServer.generate_bus_layout()
    var cues: Dictionary[String, MusicCue] = {}
    for id in A + B:
        var path: String = "res://audio/review/" + id + ".ogg"
        _check(ResourceLoader.exists(path) and windows.has(id), "Exact private media/window for " + id)
        if not ResourceLoader.exists(path) or not windows.has(id):
            get_tree().quit(1)
            return
        var stream := load(path) as AudioStreamOggVorbis
        _check(stream != null and not stream.loop and absf(stream.get_length() - float(windows[id]["duration"])) < .02, "Actual finite imported duration for " + id)
        var cue := MusicCue.new()
        cue.cue_id = StringName(id)
        cue.source_title = id
        cue.stream = stream
        _check(cue.copy_validated() != null, "Real compressed cue contract for " + id)
        cues[id] = cue
    SettingsManager.master_volume = 1.0
    SettingsManager.music_volume = 1.0
    SettingsManager.apply_runtime(false)
    _capture = AudioEffectCapture.new()
    _capture.buffer_length = .8
    AudioServer.add_bus_effect(AudioServer.get_bus_index(&"Music"), _capture)
    var measured := {}
    for group_index in 2:
        var ids: Array[String] = A if group_index == 0 else B
        var profile := MusicStage.new()
        profile.stage_id = STAGES[group_index]
        profile.unique_cue = cues[ids[0]]
        for id in ids.slice(1): profile.shared_pool.append(cues[id])
        _check(AudioDirector.register_stage(profile) == OK, "Complete isolated pool profile")
        _check(AudioDirector.set_stage_audio(profile.stage_id) == OK, "Real group selection through Director")
        await get_tree().create_timer(2.1, true).timeout
        _check(_cue() == ids[0] and _playing().size() == 1, "Actual unique first, one stable decoder")
        var previous := ""
        for step in ids.size() + 2:
            var id := _cue()
            _check(ids.has(id) and id != previous and _playing().size() == 1, "Finite pool has only its group and no immediate repeat")
            if not windows.has(id): break
            await _pcm(id, float(windows[id]["position"]))
            measured[id] = true
            previous = id
            # Only test seeks existing Director players to their real finite end.
            for player in _playing(): player.seek(player.stream.get_length() - .2)
            await get_tree().create_timer(.08, true).timeout
            _check(_playing().size() <= 2, "Actual source-media crossfade stays within two decoders")
            await get_tree().create_timer(.5, true).timeout
        for id in ids:
            _check(measured.has(id), "Every unique/shared source is actually decoded and mixed: " + id)
    var silence := AudioDirector.force_silence()
    _check(silence > 0 and AudioDirector.release_silence(silence) == OK and _playing().is_empty(), "Owned silence stops real complete pools without replay")
    for stage in STAGES:
        _check(AudioDirector.unregister_stage(stage) == OK, "Private review pool released")
    await get_tree().create_timer(.2, true).timeout
    AudioServer.set_bus_layout(layout)
    for key in settings: SettingsManager.set(key, settings[key])
    SettingsManager.apply_runtime(false)
    _check(measured.size() == 10 and GameState.capture_save().to_dict() == logical and not SaveManager.get("_dirty") and [FileAccess.get_sha256(SaveManager.SAVE_PATH), FileAccess.get_sha256(SaveManager.BACKUP_PATH)] == saved, "All ten real OGGs mixed; logical state and both protected saves unchanged")
    if _failures.is_empty():
        print("AUDIO_POOL_REVIEW PASS: ", _checks, " assertions; ten real source-derived OGGs, complete unique-first/no-repeat pools and bounded decoders; technical review only")
    get_tree().quit(0 if _failures.is_empty() else 1)
