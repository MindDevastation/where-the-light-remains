extends Node
## Real App failed/stay/retry exit with owned PCM and isolated physical save IO.

var _checks := 0
var _failures: Array[String] = []
var _exit_failures := 0


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().create_timer(15.0, true).timeout.connect(func() -> void:
        push_error("AUDIO_EXIT FAIL: bounded exit timeout")
        get_tree().quit(1)
    )
    _run.call_deferred()


func _check(condition: bool, message: String) -> void:
    _checks += 1
    if not condition:
        _failures.append(message)
        push_error("AUDIO_EXIT FAIL: " + message)


func _position() -> float:
    for player in AudioDirector.playback_snapshot()["players"]:
        if player["playing"] and player["cue"] == &"exit_fixture":
            return player["position"]
    return -1.0


func _wait_failure(count: int) -> void:
    var deadline := Time.get_ticks_msec() + 1500
    while _exit_failures < count and Time.get_ticks_msec() < deadline:
        await get_tree().process_frame
    _check(_exit_failures == count, "Actual App reports its physical failed flush")


func _run() -> void:
    var isolated_root := ""
    var native := false
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with("--save-exit-root="):
            isolated_root = argument.trim_prefix("--save-exit-root=").simplify_path()
        if argument == "--native-close":
            native = true
    if isolated_root.is_empty() or not OS.get_user_data_dir().simplify_path().begins_with(isolated_root + "/") or FileAccess.file_exists(SaveManager.SAVE_PATH) or FileAccess.file_exists(SaveManager.BACKUP_PATH):
        push_error("AUDIO_EXIT FAIL: fresh isolated user directory required before any write")
        get_tree().quit(1)
        return
    var game := preload("res://core/game_root/game_root.tscn").instantiate()
    add_child(game)
    var dialog: ExitFailureDialog = game.get_node("UILayer/ExitFailureDialog")
    App.exit_failed.connect(func(_error: Error) -> void: _exit_failures += 1)
    var bytes := PackedByteArray()
    bytes.resize(16000 * 16)
    for sample in 8000 * 16:
        bytes.encode_s16(sample * 2, int(3276.0 * sin(TAU * 440.0 * sample / 8000.0)))
    var wav := AudioStreamWAV.new()
    wav.format = AudioStreamWAV.FORMAT_16_BITS
    wav.mix_rate = 8000
    wav.data = bytes
    var cue := MusicCue.new()
    cue.cue_id = &"exit_fixture"
    cue.stream = wav
    var profile := MusicStage.new()
    profile.stage_id = &"s01_exit_fixture"
    profile.scripted_only = true
    profile.initial_state = &"fixture_idle"
    profile.authored_states[&"fixture_tone"] = cue
    _check(AudioDirector.register_stage(profile) == OK, "Register isolated exit PCM profile")
    AudioDirector.set_stage_audio(profile.stage_id)
    _check(AudioDirector.set_music_state(&"fixture_tone", 0.0) == OK, "Start real owned score before exit")
    var deadline := Time.get_ticks_msec() + 1000
    while _position() <= .02 and Time.get_ticks_msec() < deadline:
        await get_tree().create_timer(.04, true).timeout
    _check(_position() > .02, "Actual owned playback advances")
    GameState.reset_for_new_game()
    GameState.current_stage_id = profile.stage_id
    SaveManager.mark_dirty()
    var logical := GameState.capture_save().to_dict()
    _check(DirAccess.make_dir_absolute(ProjectSettings.globalize_path(SaveManager.SAVE_PATH)) == OK, "Create an actual test-owned directory IO obstacle")
    var position := _position()
    if native:
        _check(DisplayServer.get_name() == "X11", "Native-close fixture has an actual X11 window")
        var driver := ProjectSettings.globalize_path("res://../tools/x11_close_driver.py")
        var window := DisplayServer.window_get_native_handle(DisplayServer.WINDOW_HANDLE)
        var output: Array = []
        _check(OS.execute("/usr/bin/python3", [driver, "--window", str(window)], output, true) == 0, "Actual bounded WM_DELETE_WINDOW delivery")
        for item in output:
            print(String(item).strip_edges())
    else:
        App.request_safe_exit()
    await _wait_failure(1)
    _check(dialog.visible and get_tree().paused and not App.get("_exit_pending") and SaveManager.get("_dirty"), "Failed exit keeps the real Russian Stay/Retry guard and dirty state")
    _check(GameState.capture_save().to_dict() == logical and DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(SaveManager.SAVE_PATH)) and not FileAccess.file_exists(SaveManager.BACKUP_PATH), "Failed exit preserves logical state and actual obstacle/files")
    dialog.stay_button.pressed.emit()
    await get_tree().create_timer(.15, true).timeout
    _check(not dialog.visible and not get_tree().paused and _position() >= position + .04, "Stay resumes the game with the same advancing score and no restart")
    App.request_safe_exit()
    await _wait_failure(2)
    _check(dialog.visible and _position() >= position, "A second failed exit still preserves the original cue")
    _check(DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveManager.SAVE_PATH)) == OK, "Remove only the fixture's own empty directory obstacle")
    dialog.retry_button.pressed.emit()
    var loaded := SaveManager.read_save()
    _check(App.get("_exit_pending") and not SaveManager.get("_dirty") and loaded["error"] == OK and loaded["data"].to_dict() == logical, "Actual Retry commits exact dirty state before successful App quit")
    _check(AudioDirector.set_music_state(&"fixture_tone", 0.0) == ERR_BUSY and AudioDirector.begin_stage_audio(profile.stage_id) == 0 and _position() < 0.0, "Successful exit blocks late audio intents and stops owned playback before the bounded drain")
    if _failures.is_empty():
        print("AUDIO_EXIT PASS: ", _checks, " assertions; actual failed/stay/retry App exit preserves score until successful save; native=", native)
    else:
        get_tree().quit(1)
