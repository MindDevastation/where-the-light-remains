extends Node
## Actual approved fragment modal and captured PCM; no new narrative or assets.

var _checks := 0
var _failures: Array[String] = []
var _capture := AudioEffectCapture.new()


func _ready() -> void:
    get_tree().create_timer(20.0, true).timeout.connect(func() -> void:
        push_error("FRAGMENT_AUDIO FAIL: bounded modal/mixer timeout")
        get_tree().quit(1)
    )
    _run.call_deferred()


func _check(condition: bool, message: String) -> void:
    _checks += 1
    if not condition:
        _failures.append(message)
        push_error("FRAGMENT_AUDIO FAIL: " + message)


func _peak() -> float:
    await get_tree().create_timer(.1, true).timeout
    _capture.clear_buffer()
    await get_tree().create_timer(.16, true).timeout
    var peak := 0.0
    for frame in _capture.get_buffer(_capture.get_frames_available()):
        peak = maxf(peak, maxf(absf(frame.x), absf(frame.y)))
    return peak


func _presenter() -> FragmentPresenter:
    var world := preload("res://worlds/archive/archive_main.tscn").instantiate()
    var presenter := preload("res://gameplay/collectibles/fragment_presenter.tscn").instantiate() as FragmentPresenter
    presenter.fragments.assign(world.get_node("FragmentLayer/FragmentPresenter").fragments)
    world.free()
    add_child(presenter)
    return presenter


func _run() -> void:
    var hashes := [FileAccess.get_sha256(SaveManager.SAVE_PATH), FileAccess.get_sha256(SaveManager.BACKUP_PATH)]
    var logical := GameState.capture_save().to_dict()
    var layout := AudioServer.generate_bus_layout()
    _capture.buffer_length = .5
    AudioServer.add_bus_effect(AudioServer.get_bus_index(&"Music"), _capture)
    var bytes := PackedByteArray()
    bytes.resize(16000 * 12)
    for sample in 8000 * 12:
        bytes.encode_s16(sample * 2, int(3276.0 * sin(TAU * 440.0 * sample / 8000.0)))
    var wav := AudioStreamWAV.new()
    wav.format = AudioStreamWAV.FORMAT_16_BITS
    wav.mix_rate = 8000
    wav.data = bytes
    var cue := MusicCue.new()
    cue.cue_id = &"fragment_fixture"
    cue.stream = wav
    var profile := MusicStage.new()
    profile.stage_id = &"s01_fragment_fixture"
    profile.scripted_only = true
    profile.initial_state = &"fixture_idle"
    profile.authored_states[&"fixture_tone"] = cue
    _check(AudioDirector.register_stage(profile) == OK, "Register isolated real score fixture")
    AudioDirector.set_stage_audio(profile.stage_id)
    AudioDirector.set_music_state(&"fixture_tone", 0.0)
    var baseline := await _peak()
    _check(baseline > .04, "Actual mixer baseline has nonzero PCM")
    var presenter := _presenter()
    InputManager.set_mode(InputManager.Mode.GAMEPLAY)
    _check(presenter.present_fragment(&"star") == OK and presenter.visible and presenter.title_label.text == "Звезда", "Present actual approved Cyrillic Star data")
    var quiet := await _peak()
    _check(absf(quiet / baseline - db_to_linear(-4.0)) < .04 and AudioDirector.playback_snapshot()["duck_locks"] == 1, "Visible fragment owns exactly one -4 dB duck in actual PCM")
    _check(presenter.present_fragment(&"star") == ERR_ALREADY_EXISTS and presenter.present_fragment(&"hearth") == ERR_BUSY and AudioDirector.playback_snapshot()["duck_locks"] == 1, "Duplicate/busy calls never acquire another duck")
    presenter.continue_button.pressed.emit()
    var restored := await _peak()
    _check(not presenter.visible and AudioDirector.playback_snapshot()["duck_locks"] == 0 and absf(restored / baseline - 1.0) < .04, "Actual Continue restores full score without changing cue")
    var external := AudioDirector.acquire_duck(-6.0)
    _check(presenter.present_fragment(&"hearth") == OK, "Present second approved fragment under another owner")
    InputManager.set_mode(InputManager.Mode.LIMITED_LOOK)
    presenter.dismiss()
    _check(AudioDirector.playback_snapshot()["duck_locks"] == 1 and InputManager.mode == InputManager.Mode.LIMITED_LOOK, "Dismiss releases only its score token and preserves later input/duck owners")
    AudioDirector.release_duck(external)
    InputManager.set_mode(InputManager.Mode.GAMEPLAY)
    presenter.restore_collected([&"star", &"hearth"])
    _check(not presenter.visible and presenter.present_fragment(&"star") == ERR_ALREADY_EXISTS and AudioDirector.playback_snapshot()["duck_locks"] == 0, "Quiet restore never ducks or replays a fragment")
    presenter.queue_free()
    await get_tree().process_frame
    presenter = _presenter()
    _check(presenter.present_fragment(&"star") == OK, "Fresh presenter acquires a new independent lease")
    presenter.hide()
    presenter.queue_free()
    await get_tree().process_frame
    _check(AudioDirector.playback_snapshot()["duck_locks"] == 0 and InputManager.mode == InputManager.Mode.GAMEPLAY, "Freeing an externally hidden modal releases its score and input ownership")
    AudioDirector.set_music_state(&"unbound_fixture_state", 0.0)
    _check(AudioDirector.unregister_stage(profile.stage_id) == OK, "Release music fixture registry")
    await get_tree().create_timer(.2, true).timeout
    AudioServer.set_bus_layout(layout)
    InputManager.set_mode(InputManager.Mode.UI)
    _check(GameState.capture_save().to_dict() == logical and not SaveManager.get("_dirty") and [FileAccess.get_sha256(SaveManager.SAVE_PATH), FileAccess.get_sha256(SaveManager.BACKUP_PATH)] == hashes, "Actual modal/mixer paths preserve logical progress and protected saves")
    print("FRAGMENT_AUDIO PCM: baseline=", baseline, "; modal=", quiet, "; closed=", restored)
    if _failures.is_empty():
        print("FRAGMENT_AUDIO PASS: ", _checks, " assertions; actual text duck, Continue/free/quiet restore and independent ownership")
    get_tree().quit(0 if _failures.is_empty() else 1)
