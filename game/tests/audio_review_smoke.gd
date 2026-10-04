extends Node
## Exact source-derived OGGs exist only in the validator's private review copy.
## Technical decoder/mixer proof; this is not musical or shipping acceptance.

const IDS: Array[String] = ["mus_s01_archive_awakening_v01", "mus_s02_cold_to_warm_v01"]
const LENGTHS: Array[float] = [129.72, 127.96]
const STAGES: Array[StringName] = [&"s01_codec_review", &"s02_codec_review"]
var _checks := 0
var _failures: Array[String] = []
var _capture: AudioEffectCapture


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().create_timer(35.0, true).timeout.connect(func() -> void:
        push_error("AUDIO_REVIEW FAIL: bounded codec/mixer timeout")
        get_tree().quit(1)
    )
    _run.call_deferred()


func _check(condition: bool, message: String) -> void:
    _checks += 1
    if not condition:
        _failures.append(message)
        push_error("AUDIO_REVIEW FAIL: " + message)


func _playing_count() -> int:
    var count := 0
    for player in AudioDirector.playback_snapshot()["players"]:
        if player["playing"]: count += 1
    return count


func _sample(label: String, seek_seconds: float = -1.0) -> float:
    if seek_seconds >= 0.0:
        # Advance/repeat test positions through the Director's existing players;
        # no scene-owned player or direct play() bypass is introduced.
        for child in AudioDirector.get_children():
            if child is AudioStreamPlayer and child.playing: child.seek(seek_seconds)
    await get_tree().create_timer(.12, true).timeout
    _capture.clear_buffer()
    await get_tree().create_timer(.4, true).timeout
    var frames := _capture.get_buffer(_capture.get_frames_available())
    var energy := 0.0
    for frame in frames:
        energy += frame.length_squared()
    var rms := sqrt(energy / maxf(frames.size() * 2.0, 1.0))
    _check(frames.size() > 1000, "Actual captured mixer frames: " + label)
    print("AUDIO_REVIEW PCM: ", JSON.stringify({"label": label, "frames": frames.size(), "rms": rms}))
    return rms


func _run() -> void:
    print("AUDIO_REVIEW runtime: ", Engine.get_version_info()["string"], "; display=", DisplayServer.get_name(), "; audio=", AudioServer.get_driver_name())
    var logical := GameState.capture_save().to_dict()
    var hashes := [FileAccess.get_sha256(SaveManager.SAVE_PATH), FileAccess.get_sha256(SaveManager.BACKUP_PATH)]
    var settings := SettingsManager.snapshot()
    var layout := AudioServer.generate_bus_layout()
    for index in IDS.size():
        var path := "res://audio/review/" + IDS[index] + ".ogg"
        _check(ResourceLoader.exists(path), "Sealed private imported review resource " + IDS[index])
        if not ResourceLoader.exists(path):
            get_tree().quit(1)
            return
        var stream := load(path) as AudioStreamOggVorbis
        _check(stream != null and not stream.loop and absf(stream.get_length() - LENGTHS[index]) < .02, "Actual imported Vorbis is finite with exact duration")
        var cue := MusicCue.new()
        cue.cue_id = StringName(IDS[index])
        cue.source_title = "Archive Awakening" if index == 0 else "Cold to Warm"
        cue.stream = stream
        _check(cue.copy_validated() != null and not cue.is_looping(), "Existing cue contract accepts actual compressed review media")
        var profile := MusicStage.new()
        profile.stage_id = STAGES[index]
        profile.unique_cue = cue
        profile.shared_pool_enabled = false
        _check(AudioDirector.register_stage(profile) == OK, "Only isolated review stage profile registered")
    SettingsManager.master_volume = 1.0
    SettingsManager.music_volume = 1.0
    SettingsManager.apply_runtime(false)
    _capture = AudioEffectCapture.new()
    _capture.buffer_length = 1.0
    var bus := AudioServer.get_bus_index(&"Music")
    AudioServer.add_bus_effect(bus, _capture)
    _check(AudioDirector.set_stage_audio(STAGES[0]) == OK, "S01 real compressed cue starts through Director")
    await get_tree().create_timer(2.1, true).timeout
    _check(_playing_count() == 1, "One real Vorbis decoder active after initial transition")
    var baseline := await _sample("s01_baseline", 12.0)
    _check(baseline > .001, "Source-derived S01 reaches actual Music mixer")
    var duck := AudioDirector.acquire_duck(-4.0)
    _check(duck > 0, "Owned score duck acquired")
    var ducked := await _sample("s01_duck", 12.0)
    _check(absf(ducked / maxf(baseline, .000001) - db_to_linear(-4.0)) < .12, "Repeated real cue window reflects -4 dB duck")
    _check(AudioDirector.release_duck(duck) == OK, "Only review-owned duck released")
    var restored := await _sample("s01_restored", 12.0)
    _check(absf(restored / maxf(baseline, .000001) - 1.0) < .18, "Real compressed cue restores score gain")
    _check(AudioDirector.set_stage_audio(STAGES[1]) == OK and _playing_count() == 2, "S01 to S02 actual two-decoder crossfade")
    await get_tree().create_timer(2.1, true).timeout
    _check(_playing_count() == 1 and AudioDirector.playback_snapshot()["players"].size() == 2, "Outgoing decoder stops after bounded real crossfade")
    _check(await _sample("s02_baseline", 12.0) > .001, "Source-derived S02 reaches actual Music mixer")
    for child in AudioDirector.get_children():
        if child is AudioStreamPlayer and child.playing:
            child.seek(child.stream.get_length() - .2)
    await get_tree().create_timer(.8, true).timeout
    _check(_playing_count() == 0, "Actual Vorbis end-of-stream is finite; exhausted one-cue pool never restarts")
    _check(await _sample("finite_end") < .00001, "Actual mixer settles to silence after finite OGG end")
    var silence := AudioDirector.force_silence()
    _check(silence > 0 and AudioDirector.release_silence(silence) == OK, "Owned silence lifecycle releases without spontaneous playback")
    _check(_playing_count() == 0, "Silence release never replays the reviewed cue")
    for stage in STAGES:
        _check(AudioDirector.unregister_stage(stage) == OK, "Review profile released")
    await get_tree().create_timer(.2, true).timeout
    AudioServer.set_bus_layout(layout)
    for key in settings:
        SettingsManager.set(key, settings[key])
    SettingsManager.apply_runtime(false)
    _check(GameState.capture_save().to_dict() == logical and not SaveManager.get("_dirty") and [FileAccess.get_sha256(SaveManager.SAVE_PATH), FileAccess.get_sha256(SaveManager.BACKUP_PATH)] == hashes, "Decoder/mixer review preserves logical state and both protected physical save slots")
    if _failures.is_empty():
        print("AUDIO_REVIEW PASS: ", _checks, " assertions; exact private source-derived Vorbis import, mixer, duck, crossfade and finite end; no musical acceptance")
    get_tree().quit(0 if _failures.is_empty() else 1)
