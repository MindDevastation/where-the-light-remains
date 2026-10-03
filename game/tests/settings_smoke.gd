extends Node
## CLI-only persistence/runtime/modal fixture; production files are never written.

var _failures: Array[String] = []
var _path := ""
var _original: Dictionary
var _files_before: Dictionary
var _menu: SettingsMenu
var _startup_window_size := Vector2i.ZERO


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().create_timer(50.0).timeout.connect(func() -> void:
        push_error("SETTINGS FAIL: timeout")
        get_tree().quit(1)
    )
    _run.call_deferred()


func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
        push_error("SETTINGS FAIL: " + message)


func _frames() -> void:
    await get_tree().process_frame
    await get_tree().process_frame


func _production_files() -> Dictionary:
    var hashes := {}
    for path in [SettingsManager.SETTINGS_PATH, SaveManager.SAVE_PATH, SaveManager.BACKUP_PATH]:
        hashes[path] = FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "absent"
    return hashes


func _config(values: Dictionary, version: Variant = 1) -> void:
    var file := ConfigFile.new()
    file.set_value("metadata", "version", version)
    for key in values:
        file.set_value("settings", key, values[key])
    _check(file.save(_path) == OK, "Fixture configuration write")


func _run() -> void:
    print("SETTINGS runtime: ", Engine.get_version_info()["string"], "; display=", DisplayServer.get_name())
    await _frames()
    _original = SettingsManager.snapshot()
    _startup_window_size = get_window().size
    _files_before = _production_files()
    _path = "user://settings_smoke_%d.cfg" % Time.get_ticks_usec()
    _check(SettingsManager.load_settings(_path) == ERR_FILE_NOT_FOUND, "Missing-file result")
    _check(SettingsManager.snapshot() == _original and not FileAccess.file_exists(_path), "Missing-file preservation")
    var clamped: Dictionary = SettingsManager.validate({"fov": 300, "mouse_sensitivity": -5, "music_volume": 8})
    _check(clamped["fov"] == 110.0 and clamped["mouse_sensitivity"] == 0.1 and clamped["music_volume"] == 1.0, "Finite values not clamped")
    for invalid in [{"music_volume": true}, {"fov": NAN}, {"invert_y": 1}, {"resolution": Vector2(1280, 720)}, {"resolution": Vector2i(42, 42)}, {"graphics_preset": "Ultra"}]:
        _check(SettingsManager.validate(invalid).is_empty(), "Invalid value accepted: " + str(invalid))
    var chosen: Dictionary = SettingsManager.DEFAULTS.duplicate()
    chosen.merge({"master_volume": .4, "music_volume": .3, "sfx_volume": 0.0, "mouse_sensitivity": .8, "fov": 90.0, "invert_y": true}, true)
    _check(SettingsManager.apply_settings(chosen, _path) == OK, "Initial atomic write")
    _check(SettingsManager.snapshot() == chosen, "Applied snapshot")
    var first_hash := FileAccess.get_sha256(_path)
    chosen["fov"] = 91.0
    _check(SettingsManager.apply_settings(chosen, _path) == OK, "Atomic replacement of existing file")
    _check(FileAccess.get_sha256(_path) != first_hash, "Replacement did not change file")
    SettingsManager._assign(SettingsManager.DEFAULTS)
    _check(SettingsManager.load_settings(_path) == OK and SettingsManager.snapshot() == chosen, "Typed ConfigFile round trip")
    for pair in [["Master", .4], ["Music", .3], ["SFX", 0.0]]:
        var index := AudioServer.get_bus_index(pair[0])
        _check(absf(AudioServer.get_bus_volume_linear(index) - maxf(pair[1], .000001)) < .0001, "Actual bus gain")
        _check(AudioServer.is_bus_mute(index) == is_zero_approx(pair[1]), "Actual zero-volume mute")
    for version in [2, "1", true]:
        _config(chosen, version)
        _reject_file("version")
    _config({"fov": "ninety"})
    _reject_file("type")
    _config({"fov": 96.0})
    _check(SettingsManager.load_settings(_path) == OK and SettingsManager.fov == 96.0 and SettingsManager.music_volume == .8, "Missing fields do not use stale values")
    var file := FileAccess.open(_path, FileAccess.WRITE)
    file.store_string("x".repeat(SettingsManager.MAX_FILE_BYTES + 1))
    file.close()
    _reject_file("oversize")
    # ConfigFile logs ERROR for expected malformed input. Keep this negative
    # case in headless coverage; the graphical runner rejects every ERROR.
    if DisplayServer.get_name() == "headless":
        file = FileAccess.open(_path, FileAccess.WRITE)
        file.store_string("[settings\nfov=oops")
        file.close()
        print("SETTINGS expected parser diagnostic follows (malformed isolated fixture)")
        _reject_file("malformed")
    var before := SettingsManager.snapshot()
    _check(SettingsManager.apply_settings(chosen, _path + "/absent/settings.cfg") != OK, "Unwritable path accepted")
    _check(SettingsManager.snapshot() == before, "Write failure changed live state")
    var directory := _path + "-directory"
    _check(DirAccess.make_dir_absolute(ProjectSettings.globalize_path(directory)) == OK, "Rename failure fixture")
    _check(SettingsManager.apply_settings(chosen, directory) != OK, "Directory replaced by configuration")
    _check(SettingsManager.snapshot() == before and DirAccess.dir_exists_absolute(directory), "Rename failure did not preserve destination/live values")
    DirAccess.remove_absolute(directory)
    print("SETTINGS checked: missing, typed round-trip/replacement, clamps, invalid types/nonfinite/resolution/preset, versions, missing fields, oversize, write/rename failure; malformed parser case=headless only")
    await _graphics()
    if DisplayServer.get_name() != "headless":
        SettingsManager.fullscreen = true
        SettingsManager.apply_runtime()
        await _frames()
        _check(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN, "Native fullscreen mode")
        _check(is_equal_approx(get_tree().root.scaling_3d_scale, minf(1.0, 720.0 / get_window().size.y)), "Fullscreen render-height target")
        SettingsManager.fullscreen = false
        SettingsManager.resolution = _startup_window_size
        SettingsManager.apply_runtime()
        await _frames()
        _check(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED and get_window().size == _startup_window_size, "Native windowed resolution")
        print("SETTINGS checked: actual fullscreen/windowed, render-height target; startup CLI size=", _startup_window_size)
    await _ui()
    SettingsManager._assign(_original)
    SettingsManager.apply_runtime(false)
    InputManager.set_paused(false)
    InputManager.set_mode(InputManager.Mode.UI)
    _check(_production_files() == _files_before, "Fixture changed production settings/save files")
    DirAccess.remove_absolute(ProjectSettings.globalize_path(_path))
    for name in DirAccess.get_files_at("user://"):
        _check(not name.begins_with(_path.get_file() + ".tmp-"), "Temporary file leaked")
    if _failures.is_empty():
        print("SETTINGS PASS: validated atomic preferences, actual audio/graphics, Russian modal draft/apply/cancel and file integrity")
    get_tree().quit(0 if _failures.is_empty() else 1)


func _reject_file(label: String) -> void:
    var before := SettingsManager.snapshot()
    var hash_before := FileAccess.get_sha256(_path)
    _check(SettingsManager.load_settings(_path) != OK, "Invalid " + label + " file accepted")
    _check(SettingsManager.snapshot() == before and FileAccess.get_sha256(_path) == hash_before, label + " failure changed values/file")


func _graphics() -> void:
    var world := WorldEnvironment.new()
    var authored := Environment.new()
    authored.glow_enabled = true
    authored.ssao_enabled = false
    authored.fog_enabled = true
    world.environment = authored
    var light := OmniLight3D.new()
    light.shadow_enabled = true
    var no_shadow := DirectionalLight3D.new()
    no_shadow.shadow_enabled = false
    add_child(world)
    add_child(light)
    add_child(no_shadow)
    SettingsManager.shadows = false
    SettingsManager.effects = false
    SettingsManager.graphics_preset = "Low"
    SettingsManager.apply_runtime(false)
    await _frames()
    _check(world.environment != authored and authored.glow_enabled and not world.environment.glow_enabled, "Effects changed author resource or failed gate")
    _check(world.environment.fog_enabled, "Ordinary fog lost")
    _check(not light.shadow_enabled and not no_shadow.shadow_enabled, "Shadow gate")
    _check(is_equal_approx(get_tree().root.scaling_3d_scale, .75) and get_tree().root.positional_shadow_atlas_size == 0, "Low/shadows-off profile")
    SettingsManager.shadows = true
    SettingsManager.effects = true
    SettingsManager.graphics_preset = "High"
    SettingsManager.apply_runtime(false)
    _check(world.environment.glow_enabled and not world.environment.ssao_enabled, "Effects restore ignored authored disabled flag")
    _check(light.shadow_enabled and not no_shadow.shadow_enabled, "Shadow restore enabled author-disabled light")
    _check(get_tree().root.msaa_3d == Viewport.MSAA_2X and get_tree().root.positional_shadow_atlas_size == 4096, "High profile")
    SettingsManager.effects = false
    var replacement := Environment.new()
    replacement.ssr_enabled = true
    world.environment = replacement
    SettingsManager.apply_scene_graphics()
    _check(replacement.ssr_enabled and not world.environment.ssr_enabled, "Environment replacement isolation")
    world.free()
    light.free()
    no_shadow.free()
    var later := WorldEnvironment.new()
    later.environment = authored
    add_child(later)
    await _frames()
    _check(not later.environment.glow_enabled and authored.glow_enabled, "Later world did not receive current preferences")
    later.free()
    SettingsManager._assign(SettingsManager.DEFAULTS)
    SettingsManager.apply_runtime(false)
    print("SETTINGS checked: authored environment/light isolation and restoration, Low/High profiles, replacement and later world")


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


func _ui() -> void:
    if DisplayServer.get_name() == "headless":
        get_tree().root.size = Vector2i(1280, 720)
    var game := (load("res://core/game_root/game_root.tscn") as PackedScene).instantiate()
    add_child(game)
    _menu = game.get_node("UILayer/SettingsMenu")
    _menu.storage_path = _path
    _check(not _menu.visible and InputManager.mode == InputManager.Mode.UI, "Inactive modal changed startup")
    InputManager.set_mode(InputManager.Mode.GAMEPLAY)
    _menu.open()
    await _frames()
    _check(_menu.visible and InputManager.mode == InputManager.Mode.UI and not InputManager.can_move(), "Open does not gate player")
    var before := SettingsManager.snapshot()
    _menu.fields["fov"].value = 101.0
    _click(_menu.cancel_button)
    await _frames()
    _check(not _menu.visible and SettingsManager.snapshot() == before and InputManager.mode == InputManager.Mode.GAMEPLAY, "Actual mouse Cancel failed preservation/restore")
    _menu.open()
    _menu.fields["fov"].value = 102.0
    _menu.fields["fov"].get_line_edit().text = "99"
    _menu.defaults_button.pressed.emit()
    _check(_menu.draft() == SettingsManager.DEFAULTS and SettingsManager.snapshot() == before, "Defaults applied before Apply")
    _menu.fields["fov"].value = 103.0
    _menu.storage_path = _path + "/not/a/real/directory.cfg"
    _menu.apply_button.pressed.emit()
    _check(_menu.visible and _menu.error_label.text.contains("Не удалось") and SettingsManager.snapshot() == before, "Failed Apply state/message")
    _menu.storage_path = _path
    # A typed SpinBox value must commit on the real Apply click's focus change.
    var line: LineEdit = _menu.fields["fov"].get_line_edit()
    line.grab_focus()
    line.text = "97"
    _click(_menu.apply_button)
    await _frames()
    _check(not _menu.visible and SettingsManager.fov == 97.0 and InputManager.mode == InputManager.Mode.GAMEPLAY, "Actual Apply did not commit text/persist/close/restore")
    _menu.open()
    var escape := InputEventKey.new()
    escape.keycode = KEY_ESCAPE
    escape.pressed = true
    Input.parse_input_event(escape)
    Input.flush_buffered_events()
    _check(not _menu.visible and InputManager.mode == InputManager.Mode.GAMEPLAY, "Esc Cancel did not close/restore")
    var escape_release := escape.duplicate() as InputEventKey
    escape_release.pressed = false
    Input.parse_input_event(escape_release)
    Input.flush_buffered_events()
    InputManager.set_paused(true)
    _menu.open()
    _check(InputManager.mode == InputManager.Mode.UI and get_tree().paused, "Paused modal state")
    InputManager.set_mode(InputManager.Mode.DISABLED)
    _menu.close()
    _check(InputManager.mode == InputManager.Mode.DISABLED, "Close overrode a later input lock")
    InputManager.set_paused(false)
    InputManager.set_mode(InputManager.Mode.UI)
    _menu.open()
    if DisplayServer.get_name() != "headless":
        get_window().size = _startup_window_size
    await _frames()
    var font := _menu.error_label.get_theme_font("font")
    for character in "АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя":
        _check(font.has_char(character.unicode_at(0)), "Missing Russian glyph: " + character)
    var panel: Control = _menu.get("_panel")
    print("SETTINGS modal geometry: viewport=", _menu.size, "; panel=", panel.get_rect(), "; cancel=", _menu.cancel_button.get_global_rect())
    _check(Rect2(Vector2.ZERO, _menu.size).encloses(panel.get_rect()), "Panel outside viewport")
    _check(panel.get_global_rect().encloses(_menu.apply_button.get_global_rect()), "Actions outside panel")
    if DisplayServer.get_name() != "headless":
        await RenderingServer.frame_post_draw
        var image := get_viewport().get_texture().get_image()
        var output := ""
        for arg in OS.get_cmdline_user_args():
            if arg.begins_with("--settings-review="):
                output = arg.trim_prefix("--settings-review=")
        if not output.is_empty():
            _check(image.save_png(output) == OK, "Screenshot write")
        print("SETTINGS graphical modal: ", image.get_size(), "; panel=", panel.get_global_rect())
    _menu.close()
    game.free()
    await _frames()
    print("SETTINGS checked: real mouse Cancel, draft defaults, error Apply, persisted Apply, paused modal, later input lock, Russian glyphs and bounds")
