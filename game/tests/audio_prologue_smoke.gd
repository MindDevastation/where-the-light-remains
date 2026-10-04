extends Node
## Synthetic PCM verifies event/lifetime contracts, never musical acceptance.

var _checks := 0
var _failures: Array[String] = []
var _capture: AudioEffectCapture
var _game: Node
var _prologue: ArchivePrologue
var _sparks: Array[Error] = []
var _started: Array[StringName] = []


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().create_timer(30.0, true).timeout.connect(func() -> void:
        push_error("AUDIO_PROLOGUE FAIL: bounded event/mixer timeout")
        get_tree().quit(1)
    )
    _run.call_deferred()


func _check(condition: bool, message: String) -> void:
    _checks += 1
    if not condition:
        _failures.append(message)
        push_error("AUDIO_PROLOGUE FAIL: " + message)


func _cue(id: StringName, seconds: float) -> MusicCue:
    var data := PackedByteArray()
    data.resize(int(seconds * 8000) * 2)
    for index in data.size() / 2:
        data.encode_s16(index * 2, int(3276.0 * sin(TAU * 440.0 * index / 8000.0)))
    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = 8000
    stream.data = data
    var cue := MusicCue.new()
    cue.cue_id = id
    cue.stream = stream
    cue.source_title = "Synthetic finite PCM fixture, not an Archive motif"
    return cue


func _playing() -> int:
    var count := 0
    for player in AudioDirector.playback_snapshot()["players"]:
        if player["playing"]: count += 1
    return count


func _sample(label: String) -> float:
    await get_tree().create_timer(.08, true).timeout
    _capture.clear_buffer()
    await get_tree().create_timer(.16, true).timeout
    var frames := _capture.get_buffer(_capture.get_frames_available())
    var energy := 0.0
    for frame in frames:
        energy += frame.length_squared()
    var rms := sqrt(energy / maxf(frames.size() * 2.0, 1.0))
    _check(frames.size() > 1000, "Captured actual mixer frames: " + label)
    print("AUDIO_PROLOGUE PCM: ", JSON.stringify({"label": label, "frames": frames.size(), "rms": rms}))
    return rms


func _enter(saved: SaveGame) -> void:
    _game = preload("res://core/game_root/game_root.tscn").instantiate()
    add_child(_game)
    var error := await SceneRouter.request_resume_stage(saved)
    _check(error == OK, "Real registered Archive checkpoint enters")
    if error != OK:
        get_tree().quit(1)
        return
    _prologue = _game.get_node("WorldSlot").get_child(0).get_node("Prologue") as ArchivePrologue
    _prologue.spark_ignited.connect(func(result: Error) -> void: _sparks.append(result))


func _remove() -> void:
    _game.queue_free()
    await get_tree().process_frame
    _game = null
    _prologue = null


func _wait_spark() -> void:
    while not _prologue.spark.visible:
        await get_tree().process_frame
    await get_tree().process_frame


func _run() -> void:
    var original := GameState.capture_save()
    var dirty: bool = SaveManager.get("_dirty")
    var hashes := [FileAccess.get_sha256(SaveManager.SAVE_PATH), FileAccess.get_sha256(SaveManager.BACKUP_PATH)]
    var settings := SettingsManager.snapshot()
    var layout := AudioServer.generate_bus_layout()
    var fade := SceneRouter.fade_duration
    SettingsManager.master_volume = 1.0
    SettingsManager.music_volume = 1.0
    SettingsManager.apply_runtime(false)
    _capture = AudioEffectCapture.new()
    _capture.buffer_length = 1.0
    AudioServer.add_bus_effect(AudioServer.get_bus_index(&"Music"), _capture)
    AudioDirector.cue_started.connect(func(id: StringName) -> void: _started.append(id))
    var seed := _cue(&"synthetic_spark_seed", 1.2)
    var newer := _cue(&"synthetic_newer_intent", 4.0)
    var profile := MusicStage.new()
    profile.stage_id = ArchiveProgress.PROLOGUE
    profile.initial_state = ArchivePrologue.SPARK_MUSIC_STATE
    profile.unique_cue = newer
    profile.shared_pool.assign([seed])
    profile.authored_states = {ArchivePrologue.SPARK_MUSIC_STATE: seed, &"newer_fixture": newer}
    _check(AudioDirector.register_stage(profile) == OK, "Only test PCM profile is registered; no shipping media binding")
    for id in [ArchiveProgress.PROLOGUE, ArchiveProgress.INTRO]:
        var definition := StageDefinition.new()
        definition.stage_id = id
        definition.scene_path = "res://worlds/archive/archive_main.tscn"
        definition.presentation = StageDefinition.Presentation.FADE
        definition.player_active = id != ArchiveProgress.PROLOGUE
        definition.input_mode = InputManager.Mode.CINEMATIC if id == ArchiveProgress.PROLOGUE else InputManager.Mode.GAMEPLAY
        _check(SceneRouter.register_stage(definition) == OK, "Register actual Archive world route")
    SceneRouter.fade_duration = .01
    var initial := SaveGame.new()
    _check(ArchiveProgress.write_projection(initial) == OK, "Fresh actual S00 projection")
    await _enter(initial)
    _check(not _prologue.spark.visible and _sparks.is_empty() and _playing() == 0, "S00 starts scoreless despite a bound initial cue")
    _check(await _sample("before_spark") < .00001, "Actual pre-spark mixer is silent")
    InputManager.set_paused(true)
    var paused_at := _prologue.elapsed
    _check(await _sample("paused_before_spark") < .00001, "Pause cannot advance to an early note")
    _check(is_equal_approx(_prologue.elapsed, paused_at) and _sparks.is_empty(), "Actual paused timeline emits no spark event")
    InputManager.set_paused(false)
    await _wait_spark()
    _check(_sparks == [OK] and _started == [seed.cue_id] and _playing() == 1, "Visible spark starts exactly one Director-owned finite cue")
    _check(_prologue.elapsed >= 1.0 and _prologue.elapsed < 1.1 and not AudioDirector.playback_snapshot()["automatic"], "Score request occurs at the actual spark, without playlist rotation")
    _check(await _sample("spark_seed") > .02, "Actual seed PCM reaches the Music mixer")
    await get_tree().create_timer(1.3, true).timeout
    _check(_playing() == 0 and _started == [seed.cue_id], "Finite seed ends without repeating or entering the shared pool")
    _check(await _sample("finite_tail") < .00001, "Actual finite tail settles to silence")
    await _remove()
    _check(_playing() == 0, "Removing the completed finite fixture leaves no global playback")

    await _enter(initial)
    var lock := AudioDirector.force_silence()
    _check(lock > 0, "Independent silence owner acquired before the spark")
    await _wait_spark()
    _check(_sparks == [OK, OK] and _playing() == 0 and AudioDirector.playback_snapshot()["silence_locks"] == 1, "Actual spark respects the independent silence owner")
    _check(await _sample("locked_spark") < .00001, "Owned silence suppresses actual seed PCM")
    await _remove()
    _check(AudioDirector.playback_snapshot()["silence_locks"] == 1, "Scene removal never releases another owner's silence")
    _check(AudioDirector.release_silence(lock) == OK, "Independent owner can release its own token")
    _check(await _sample("removed_then_released") < .00001 and _playing() == 0 and _started == [seed.cue_id], "A removed spark request cannot begin later when external silence releases")

    await _enter(initial)
    await _wait_spark()
    _check(AudioDirector.set_music_state(&"newer_fixture", 0.0) == OK, "A newer semantic owner replaces the seed")
    await _remove()
    _check(_playing() == 1 and AudioDirector.current_state == &"newer_fixture", "Old scene teardown cannot stop newer score ownership")
    _check(await _sample("newer_owner_after_remove") > .02, "Newer owner's actual PCM survives old scene removal")
    var revision: int = AudioDirector.playback_snapshot()["revision"]
    var lease := AudioDirector.begin_stage_audio(ArchiveProgress.INTRO)
    _check(lease > 0 and not AudioDirector.cancel_music_state(ArchiveProgress.PROLOGUE, &"newer_fixture", revision) and AudioDirector.owns_stage_audio(lease), "Stale scene cancellation cannot supersede a pending route lease")
    _check(AudioDirector.cancel_stage_audio(lease), "Only the real lease owner cancels its pending route")
    AudioDirector.set_music_state(&"unbound_fixture", 0.0)

    var completed := initial.copy_validated()
    completed.stage_id = ArchiveProgress.INTRO
    completed.checkpoint_id = &"prologue_completed"
    completed.milestones["prologue_completed"] = true
    _check(ArchiveProgress.write_projection(completed) == OK, "Confirmed completed-prologue save projection")
    var event_count := _sparks.size()
    await _enter(completed)
    _check(await _sample("completed_restore") < .00001 and _playing() == 0 and _sparks.size() == event_count, "Quiet completed checkpoint never replays a seed event or PCM")
    await _remove()
    _check(AudioDirector.unregister_stage(profile.stage_id) == OK, "Synthetic profile released")
    for id in [ArchiveProgress.PROLOGUE, ArchiveProgress.INTRO]:
        SceneRouter.unregister_stage(id)
    SceneRouter.fade_duration = fade
    await get_tree().create_timer(.2, true).timeout
    AudioServer.set_bus_layout(layout)
    for key in settings:
        SettingsManager.set(key, settings[key])
    SettingsManager.apply_runtime(false)
    GameState.apply_save(original)
    SaveManager.set("_dirty", dirty)
    InputManager.set_mode(InputManager.Mode.UI)
    _check([FileAccess.get_sha256(SaveManager.SAVE_PATH), FileAccess.get_sha256(SaveManager.BACKUP_PATH)] == hashes, "Every actual route/mixer test preserves both physical save slots")
    if _failures.is_empty():
        print("AUDIO_PROLOGUE PASS: ", _checks, " assertions; actual spark, paused silence, finite PCM, owned teardown, newer intent/lease and quiet restore; no musical acceptance")
    get_tree().quit(0 if _failures.is_empty() else 1)
