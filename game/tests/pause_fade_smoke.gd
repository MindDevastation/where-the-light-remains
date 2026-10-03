extends Node
## CLI-only production controller/modal/fade fixture; no story or save writes.

var _failures: Array[String] = []
var _game: Node
var _player: FirstPersonPlayer
var _pause: PauseMenu
var _settings: SettingsMenu
var _fade: FadeOverlay
var _fade_results: Array[bool] = []
var _settings_before: Dictionary
var _file_hashes: Dictionary
var _buses_before: Array
var _path := ""


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().create_timer(60.0).timeout.connect(func() -> void:
        push_error("PAUSE_FADE FAIL: timeout")
        get_tree().quit(1)
    )
    _run.call_deferred()


func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
        push_error("PAUSE_FADE FAIL: " + message)


func _frames(count: int = 2) -> void:
    for i in count:
        await get_tree().process_frame


func _key(code: Key, pressed: bool, echo: bool = false) -> void:
    var event := InputEventKey.new()
    event.keycode = code
    event.physical_keycode = code
    event.pressed = pressed
    event.echo = echo
    Input.parse_input_event(event)
    Input.flush_buffered_events()


func _motion(delta: Vector2) -> void:
    var event := InputEventMouseMotion.new()
    event.screen_relative = delta
    event.relative = delta
    Input.parse_input_event(event)
    Input.flush_buffered_events()


func _click(button: Button) -> void:
    var point := button.get_global_rect().get_center()
    var motion := InputEventMouseMotion.new()
    motion.position = point
    Input.parse_input_event(motion)
    for pressed in [true, false]:
        var event := InputEventMouseButton.new()
        event.button_index = MOUSE_BUTTON_LEFT
        event.position = point
        event.pressed = pressed
        Input.parse_input_event(event)
        Input.flush_buffered_events()


func _files() -> Dictionary:
    var result := {}
    for path in [SettingsManager.SETTINGS_PATH, SaveManager.SAVE_PATH, SaveManager.BACKUP_PATH]:
        result[path] = FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "absent"
    return result


func _buses() -> Array:
    var result := []
    for index in AudioServer.bus_count:
        result.append([AudioServer.get_bus_name(index), AudioServer.get_bus_volume_db(index), AudioServer.is_bus_mute(index), AudioServer.is_bus_solo(index)])
    return result


func _run() -> void:
    print("PAUSE_FADE runtime: ", Engine.get_version_info()["string"], "; display=", DisplayServer.get_name())
    if DisplayServer.get_name() == "headless":
        get_tree().root.size = Vector2i(1280, 720)
    _settings_before = SettingsManager.snapshot()
    _file_hashes = _files()
    _buses_before = _buses()
    var stage_before := GameState.current_stage_id
    var audio_before := AudioDirector.current_state
    SettingsManager._assign(SettingsManager.DEFAULTS)
    SettingsManager.apply_runtime(false)
    _game = (load("res://core/game_root/game_root.tscn") as PackedScene).instantiate()
    add_child(_game)
    _player = _game.get_node("PlayerContainer/Player")
    _pause = _game.get_node("UILayer/PauseMenu")
    _settings = _game.get_node("UILayer/SettingsMenu")
    _fade = _game.get_node("TransitionLayer/FadeOverlay")
    _path = "user://pause_settings_smoke_%d.cfg" % Time.get_ticks_usec()
    _settings.storage_path = _path
    await _frames()
    _check(not _pause.visible and not _fade.visible and not _player.active, "Startup exposed shell UI or player")
    _key(KEY_ESCAPE, true)
    _check(not _pause.visible and InputManager.mode == InputManager.Mode.UI, "Empty shell paused")
    _check(Input.is_action_pressed(&"skip_sequence"), "Empty shell consumed raw sequence source")
    _key(KEY_ESCAPE, false)
    var world := (load("res://tests/fixtures/archive_kit_sample.tscn") as PackedScene).instantiate()
    _game.get_node("WorldSlot").add_child(world)
    _player.spawn_at(Transform3D(Basis.IDENTITY, Vector3(0, .004, 0)))
    _player.set_active(true)
    for mode in [InputManager.Mode.CINEMATIC, InputManager.Mode.DISABLED, InputManager.Mode.UI]:
        InputManager.set_mode(mode)
        _key(KEY_ESCAPE, true)
        _check(not _pause.visible and InputManager.mode == mode and not get_tree().paused, "Unsupported mode consumed pause Esc")
        _key(KEY_ESCAPE, false)
    InputManager.set_mode(InputManager.Mode.GAMEPLAY)
    get_window().focus_exited.emit()
    _check(not _pause.open(), "Unfocused pause opened")
    get_window().focus_entered.emit()
    await _frames()
    _key(KEY_W, true)
    await get_tree().create_timer(.2).timeout
    _check(_player.global_position.z < -.3, "Controller did not walk before pause")
    _key(KEY_ESCAPE, true)
    _check(_pause.visible and get_tree().paused and InputManager.mode == InputManager.Mode.UI, "Fresh Esc did not pause")
    _key(KEY_ESCAPE, false)
    var position := _player.global_position
    await get_tree().create_timer(.15).timeout
    _check(_player.global_position == position and absf(_player.velocity.z) < .001, "Paused controller advanced")
    _check(_buses() == _buses_before, "Pause mutated audio state")
    _key(KEY_ESCAPE, true, true)
    _check(_pause.visible and get_tree().paused, "Echo resumed pause")
    _key(KEY_ESCAPE, false)
    await _review("--pause-review=")
    await _frames()
    _click(_pause.settings_button)
    await _frames()
    _check(_settings.visible and _pause.visible and get_tree().paused, "Paused settings did not open")
    _key(KEY_ESCAPE, true)
    _key(KEY_ESCAPE, false)
    _check(not _settings.visible and _pause.visible and get_tree().paused and InputManager.mode == InputManager.Mode.UI, "Settings Esc escaped parent pause")
    _click(_pause.settings_button)
    await _frames()
    _settings.fields["fov"].get_line_edit().grab_focus()
    _settings.fields["fov"].get_line_edit().text = "96"
    _click(_settings.apply_button)
    await _frames()
    print("PAUSE settings return: modal=", _settings.visible, "; pause=", _pause.visible, "; tree_paused=", get_tree().paused, "; settings_fov=", SettingsManager.fov, "; camera_fov=", _player.camera.fov, "; message=", _settings.error_label.text)
    _check(not _settings.visible and _pause.visible and get_tree().paused and _player.camera.fov == 96.0, "Settings Apply failed paused camera/return")
    _click(_pause.resume_button)
    await _frames()
    _check(not _pause.visible and not get_tree().paused and InputManager.mode == InputManager.Mode.GAMEPLAY, "Mouse resume failed")
    _key(KEY_W, true, true)
    _check(InputManager.get_movement_vector() == Vector2.ZERO, "Held W echo leaked after resume")
    var yaw := _player.rotation.y
    _motion(Vector2(999, 999))
    _check(_player.rotation.y == yaw, "Resume recapture warped view")
    _motion(Vector2(20, 0))
    _check(absf(_player.rotation.y - yaw + .04) < .001, "Fresh look did not resume")
    _key(KEY_W, false)
    InputManager.set_mode(InputManager.Mode.LIMITED_LOOK)
    _key(KEY_ESCAPE, true)
    _key(KEY_ESCAPE, false)
    _check(_pause.visible, "LIMITED_LOOK pause did not open")
    _key(KEY_ESCAPE, true)
    _key(KEY_ESCAPE, false)
    _check(not _pause.visible and InputManager.mode == InputManager.Mode.LIMITED_LOOK, "Esc resume lost LIMITED_LOOK")
    InputManager.set_mode(InputManager.Mode.GAMEPLAY)
    _check(_pause.open(), "Transition test pause")
    _click(_pause.settings_button)
    InputManager.set_mode(InputManager.Mode.DISABLED)
    _check(not _pause.visible and not _settings.visible and not get_tree().paused and InputManager.mode == InputManager.Mode.DISABLED, "Later transition lock was overwritten/stranded")
    InputManager.set_mode(InputManager.Mode.GAMEPLAY)
    _check(_pause.open(), "External release test pause")
    InputManager.set_paused(false)
    _check(not _pause.visible and InputManager.mode == InputManager.Mode.GAMEPLAY, "External resume stranded UI")
    print("PAUSE checked: inactive/unsupported/focus gates, physical controller stop, echo, settings Esc/Apply nesting, mouse/Esc resume, held W/recapture, LIMITED_LOOK and external lock/release")
    await _fade_checks()
    _player.set_active(false)
    InputManager.set_mode(InputManager.Mode.UI)
    _check(GameState.current_stage_id == stage_before and AudioDirector.current_state == audio_before, "Shell changed semantic game/audio state")
    _check(_files() == _file_hashes, "Shell changed production settings/save files")
    DirAccess.remove_absolute(ProjectSettings.globalize_path(_path))
    SettingsManager._assign(_settings_before)
    SettingsManager.apply_runtime(false)
    _check(_buses() == _buses_before, "Preferences/audio not restored")
    if not _failures.is_empty():
        get_tree().quit(1)
        return
    _player.set_active(true)
    InputManager.set_mode(InputManager.Mode.GAMEPLAY)
    _check(_pause.open(), "Exit path pause")
    _pause.exit_requested.connect(func() -> void:
        print("PAUSE_FADE PASS: controller pause/resume, nested Russian settings, locks, awaited fade/cancel/input blocking and App safe-exit dispatch")
    )
    await _frames()
    _click(_pause.exit_button)


func _start_fade(overlay: FadeOverlay, alpha: float, duration: float) -> void:
    var result: bool = await overlay.fade_to(alpha, duration)
    _fade_results.append(result)


func _fade_checks() -> void:
    InputManager.set_mode(InputManager.Mode.GAMEPLAY)
    _check(_pause.open(), "Fade fixture pause")
    var requested_mode := InputManager.mode
    _check(await _fade.fade_to(1.0, 0.0), "Immediate blackout")
    _fade.set_loading(true)
    await _frames()
    _click(_pause.resume_button)
    _key(KEY_ESCAPE, true)
    _key(KEY_ESCAPE, false)
    _check(_pause.visible and get_tree().paused and InputManager.mode == requested_mode, "Opaque fade did not block pointer/key or changed input owner")
    await _review("--loading-review=")
    _fade.set_loading(false)
    _start_fade(_fade, 0.0, .25)
    await get_tree().create_timer(.06).timeout
    _check(_fade.busy and _fade.shade.color.a > 0.0 and _fade.shade.color.a < 1.0, "Fade did not animate while paused")
    _check(not await _fade.fade_to(1.0, .1), "Overlapping fade accepted")
    await get_tree().create_timer(.3).timeout
    _check(_fade_results == [true] and not _fade.visible and not _fade.busy, "Awaited fade did not complete")
    _start_fade(_fade, 1.0, .5)
    await get_tree().create_timer(.03).timeout
    _fade.clear()
    _check(_fade_results == [true, false] and not _fade.visible and not _fade.busy, "Clear stranded cancelled awaiter")
    _check(not await _fade.fade_to(NAN) and not await _fade.fade_to(.5, -1.0), "Invalid fade arguments accepted")
    var disposable := (load("res://core/transitions/fade_overlay.tscn") as PackedScene).instantiate() as FadeOverlay
    _game.get_node("TransitionLayer").add_child(disposable)
    _start_fade(disposable, 1.0, .5)
    disposable.free()
    _check(_fade_results == [true, false, false], "Free stranded cancelled awaiter")
    _check(InputManager.mode == requested_mode and get_tree().paused, "Fade mutated requested mode/pause")
    _pause.resume()
    print("FADE checked: pause-independent animation, awaited completion, overlap/invalid rejection, clear/free cancellation and actual GUI/key blocking")


func _review(prefix: String) -> void:
    var font := _pause.resume_button.get_theme_font("font")
    for character in "ПаузаПродолжитьНастройкиВыйти из игрыЗагрузка…":
        _check(font.has_char(character.unicode_at(0)), "Missing shell glyph")
    if DisplayServer.get_name() == "headless":
        return
    await RenderingServer.frame_post_draw
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with(prefix):
            var image := get_viewport().get_texture().get_image()
            _check(image.save_png(argument.trim_prefix(prefix)) == OK, "Shell screenshot write")
            print("PAUSE_FADE graphical: ", prefix, image.get_size())
